import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthService _authService = AuthService();
  final AiService _aiService;
  
  UserModel? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  bool _isEditing = false;
  
  // BuildContext referansı
  BuildContext? _context;

  // Getters
  UserModel? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;
  bool get isPremium => _user?.isPremium ?? false;
  bool get isAuthenticated => _auth.currentUser != null;
  BuildContext? get context => _context;

  // Constructor
  ProfileViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AiService? aiService,
  }) : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _aiService = aiService ?? AiService();
      
  // Context ayarlama
  void setContext(BuildContext context) {
    _context = context;
  }

  // Kullanıcı profilini yükleme
  Future<void> loadUserProfile() async {
    if (_auth.currentUser == null) return;
    
    _setLoading(true);
    try {
      final userData = await _authService.getUserData();
      _user = userData;
      notifyListeners();
    } catch (e) {
      _setError('Profil yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Kullanıcı profilini yükleme
  Future<void> getUserProfile(String userId) async {
    _setLoading(true);
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        _userProfile = doc.data() as Map<String, dynamic>?;
        debugPrint('Kullanıcı profili yüklendi: $_userProfile');
        notifyListeners();
      } else {
        debugPrint('Kullanıcı profili bulunamadı');
        _setError('Kullanıcı profili bulunamadı');
        
        // Kullanıcı profili bulunamadıysa, Firebase Auth'taki kullanıcı bilgilerini alalım
        final user = _auth.currentUser;
        if (user != null) {
          // Temel bir profil oluşturalım
          final Map<String, dynamic> newProfile = {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'messagesAnalyzed': 0,
            'isPremium': false,
            'premiumExpiry': null, // ✅ Premium expiry alanını null olarak ekle
          };
          
          // Firestore'a kaydedelim
          await _firestore.collection('users').doc(userId).set(newProfile);
          
          _userProfile = newProfile;
          notifyListeners();
          debugPrint('Yeni kullanıcı profili oluşturuldu: $_userProfile');
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı profili yüklenirken hata: $e');
      _setError('Kullanıcı profili yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Kullanıcı profilini güncelleme
  Future<bool> updateUserProfile(
    String userId, 
    String name, 
    String bio, 
    String relationshipStatus,
  ) async {
    _isUpdating = true;
    notifyListeners();
    
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'bio': bio,
        'relationshipStatus': relationshipStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(userId).update(updateData);
      
      // Yerel kullanıcı profili verisini güncelle
      if (_userProfile != null) {
        _userProfile = {
          ..._userProfile!,
          ...updateData,
        };
      } else {
        await getUserProfile(userId);
      }
      
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profil güncellenirken hata oluştu: $e');
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // Düzenleme modunu açma/kapatma
  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  // Kullanıcı adını güncelleme
  Future<void> updateDisplayName(String displayName) async {
    if (_auth.currentUser == null || _user == null) return;
    
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'displayName': displayName,
      });
      
      // Yerel kullanıcı nesnesini güncelle
      _user = _user!.copyWith(displayName: displayName);
      
      notifyListeners();
    } catch (e) {
      _setError('İsim güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcı tercihlerini güncelleme
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_auth.currentUser == null || _user == null) return;
    
    _setLoading(true);
    try {
      // Var olan tercihlerle yenilerini birleştir
      final updatedPreferences = {
        ..._user!.preferences,
        ...preferences,
      };
      
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'preferences': updatedPreferences,
      });
      
      // Yerel kullanıcı nesnesini güncelle
      _user = _user!.copyWith(preferences: updatedPreferences);
      
      notifyListeners();
    } catch (e) {
      _setError('Tercihler güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Premium abonelik satın alma
  Future<bool> purchasePremium({required String planType}) async {
    if (_auth.currentUser == null || _user == null) return false;
    
    _setLoading(true);
    try {
      // Burada gerçek bir ödeme işlemi entegre edilecektir
      // Şimdilik sadece kullanıcı modelini güncelliyoruz
      
      DateTime expiryDate;
      switch (planType) {
        case 'monthly':
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case 'yearly':
          expiryDate = DateTime.now().add(const Duration(days: 365));
          break;
        default:
          expiryDate = DateTime.now().add(const Duration(days: 30));
      }
      
      await _authService.updatePremiumStatus(
        isPremium: true, 
        expiryDate: expiryDate,
      );
      
      // Kullanıcı profilini yeniden yükle
      await loadUserProfile();
      
      return true;
    } catch (e) {
      _setError('Premium abonelik satın alınırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Premium abonelik iptal etme
  Future<bool> cancelPremium() async {
    if (_auth.currentUser == null || _user == null) return false;
    
    _setLoading(true);
    try {
      // Burada gerçek bir abonelik iptal işlemi entegre edilecektir
      // Şimdilik sadece kullanıcı modelini güncelliyoruz
      
      await _authService.updatePremiumStatus(
        isPremium: false, 
        expiryDate: null,
      );
      
      // Kullanıcı profilini yeniden yükle
      await loadUserProfile();
      
      return true;
    } catch (e) {
      _setError('Premium abonelik iptal edilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcı verilerini silme
  Future<bool> deleteUserData() async {
    if (_auth.currentUser == null) return false;
    
    _setLoading(true);
    try {
      final userId = _auth.currentUser!.uid;
      
      // Kullanıcıya ait tüm verileri silme
      final batch = _firestore.batch();
      
      // Mesajları silme
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Analiz sonuçlarını silme
      final analysisSnapshot = await _firestore
          .collection('analysis_results')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in analysisSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Raporları silme
      final reportsSnapshot = await _firestore
          .collection('relationship_reports')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in reportsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Tavsiyeleri silme
      final adviceSnapshot = await _firestore
          .collection('advice_cards')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in adviceSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Kullanıcı belgesini silme
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Batch işlemi gerçekleştir
      await batch.commit();
      
      // Kullanıcıyı auth sisteminden sil
      await _auth.currentUser!.delete();
      
      return true;
    } catch (e) {
      _setError('Kullanıcı verileri silinirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Yükleme durumunu ayarlama
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını ayarlama
  void _setError(String error) {
    _errorMessage = error;
    debugPrint(error);
    notifyListeners();
  }

  // Hata mesajını temizleme
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Yeni bir analiz sonucu ekleyerek kullanıcı profilini günceller
  Future<bool> analizSonucuIleProfilGuncelle(Map<String, dynamic> analizVerileri) async {
    if (_auth.currentUser == null || _user == null) return false;
    
    _setLoading(true);
    try {
      // Analiz sonucu oluştur
      final Map<String, dynamic> analizSonucuMap = await _aiService.iliskiDurumuAnaliziYap(
        _auth.currentUser!.uid, 
        analizVerileri
      );
      
      // Map'i AnalizSonucu nesnesine dönüştür
      final AnalizSonucu analizSonucu = AnalizSonucu.fromMap(analizSonucuMap);
      
      // Kullanıcı modelini güncelle
      final UserModel guncelKullanici = _user!.analizSonucuEkle(analizSonucu);
      
      // Firestore'a kaydet
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'sonAnalizSonucu': analizSonucu.toMap(),
        'analizGecmisi': FieldValue.arrayUnion([analizSonucu.toMap()]),
      });
      
      // Yerel kullanıcı nesnesini güncelle
      _user = guncelKullanici;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Analiz sonucu güncellenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Kullanıcının en son analiz sonucunu yeniden değerlendirir
  /// ve kişiselleştirilmiş tavsiyeleri günceller
  Future<bool> kisiselestirilmisTavsiyeleriGuncelle() async {
    if (_auth.currentUser == null || _user == null || _user!.sonAnalizSonucu == null) {
      return false;
    }
    
    _setLoading(true);
    try {
      final sonAnalizSonucu = _user!.sonAnalizSonucu!;
      
      // Kullanıcı verilerini hazırla
      final Map<String, dynamic> kullaniciVerileri = {
        'displayName': _user!.displayName,
        'preferences': _user!.preferences,
      };
      
      // Yeni tavsiyeler oluştur
      final yeniTavsiyeler = await _aiService.kisisellestirilmisTavsiyelerOlustur(
        sonAnalizSonucu.iliskiPuani,
        sonAnalizSonucu.kategoriPuanlari,
        kullaniciVerileri
      );
      
      // Yeni analiz sonucu oluştur
      final yeniAnalizSonucu = AnalizSonucu(
        iliskiPuani: sonAnalizSonucu.iliskiPuani,
        kategoriPuanlari: sonAnalizSonucu.kategoriPuanlari,
        tarih: DateTime.now(),
        kisiselestirilmisTavsiyeler: yeniTavsiyeler,
      );
      
      // Kullanıcı modelini güncelle
      final UserModel guncelKullanici = _user!.copyWith(
        sonAnalizSonucu: yeniAnalizSonucu,
      );
      
      // Firestore'a kaydet
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'sonAnalizSonucu': yeniAnalizSonucu.toMap(),
      });
      
      // Yerel kullanıcı nesnesini güncelle
      _user = guncelKullanici;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Tavsiyeler güncellenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcıyı silmeden tüm analiz ve rapor verilerini temizler
  Future<bool> clearUserAnalysisData() async {
    debugPrint('clearUserAnalysisData çağrıldı');
    
    if (_auth.currentUser == null) {
      debugPrint('Oturum açık değil, veri temizleme işlemi yapılamıyor');
      return false;
    }
    
    _setLoading(true);
    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Kullanıcı verilerini temizlemeye başlıyor: $userId');
      
      // Batch işlemi başlat
      WriteBatch? batch;
      try {
        batch = _firestore.batch();
        debugPrint('Batch işlemi oluşturuldu');
      } catch (e) {
        debugPrint('Batch oluşturulurken hata: $e');
        _setError('Batch işlemi oluşturulamadı: $e');
        return false;
      }
      
      // Kullanıcının alt koleksiyonlarındaki mesajları temizle
      try {
        debugPrint('Mesajlar sorgulanıyor...');
        final messagesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('messages')
            .get();
        
        debugPrint('Mesaj sayısı: ${messagesSnapshot.docs.length}');
        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
      } catch (e) {
        debugPrint('Mesajlar silinirken hata: $e');
        // Hata durumunda işleme devam et
      }
      
      // İlişki raporlarını silme
      try {
        debugPrint('İlişki raporları sorgulanıyor...');
        final reportsSnapshot = await _firestore
            .collection('relationship_reports')
            .where('userId', isEqualTo: userId)
            .get();
        
        debugPrint('Rapor sayısı: ${reportsSnapshot.docs.length}');
        for (var doc in reportsSnapshot.docs) {
          batch.delete(doc.reference);
        }
      } catch (e) {
        debugPrint('Raporlar silinirken hata: $e');
        // Hata durumunda işleme devam et
      }
      
      // Tavsiyeleri silme
      try {
        debugPrint('Tavsiyeler sorgulanıyor...');
        final adviceSnapshot = await _firestore
            .collection('advice_cards')
            .where('userId', isEqualTo: userId)
            .get();
        
        debugPrint('Tavsiye sayısı: ${adviceSnapshot.docs.length}');
        for (var doc in adviceSnapshot.docs) {
          batch.delete(doc.reference);
        }
      } catch (e) {
        debugPrint('Tavsiyeler silinirken hata: $e');
        // Hata durumunda işleme devam et
      }
      
      // Batch işlemini uygula
      try {
        debugPrint('Batch işlemi uygulanıyor...');
        await batch.commit();
        debugPrint('Batch işlemi başarıyla uygulandı');
      } catch (e) {
        debugPrint('Batch işlemi sırasında hata: $e');
        // Hata durumunda kullanıcı belgesini güncellemeye devam et
      }
      
      // Analiz sonuçlarını temizle
      try {
        debugPrint('Kullanıcı belgesindeki analiz sonuçları temizleniyor...');
        await _firestore.collection('users').doc(userId).update({
          'sonAnalizSonucu': FieldValue.delete(),
          'analizGecmisi': [],
        });
        debugPrint('Kullanıcı belgesindeki analiz sonuçları temizlendi');
      } catch (e) {
        debugPrint('Kullanıcı belgesini güncellerken hata: $e');
        _setError('Kullanıcı belgesini güncellerken hata oluştu: $e');
        return false;
      }
      
      // Kullanıcı nesnesini güncelle
      if (_user != null) {
        debugPrint('Yerel kullanıcı modeli güncelleniyor...');
        _user = _user!.copyWith(
          sonAnalizSonucu: null,
          analizGecmisi: [],
        );
        debugPrint('Yerel kullanıcı modeli güncellendi');
      }
      
      notifyListeners();
      debugPrint('Tüm veriler başarıyla temizlendi');
      return true;
    } catch (e) {
      debugPrint('Analiz verileri temizlenirken beklenmeyen hata: $e');
      _setError('Analiz verileri temizlenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 