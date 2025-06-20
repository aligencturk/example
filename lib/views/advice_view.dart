import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/advice_viewmodel.dart';
import '../services/logger_service.dart';
import '../utils/loading_indicator.dart';
import '../widgets/message_coach_card.dart';
import '../utils/utils.dart';
import '../models/message_coach_analysis.dart';
import 'dart:async';

class AdviceView extends StatefulWidget {
  const AdviceView({super.key});

  @override
  State<AdviceView> createState() => _AdviceViewState();
}

class _AdviceViewState extends State<AdviceView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isLoading = false;
  bool _imageMode = false;
  final List<File> _selectedImages = [];
  final _logger = LoggerService();
  Timer? _analysisTimer;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Mesaj alanındaki odak değişikliğini dinle
    _messageFocusNode.addListener(_onFocusChange);
    
    // Metin değişikliğini dinle
    _messageController.addListener(_onTextChange);
    
    // Sayfa her açıldığında verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final adviceViewModel = Provider.of<AdviceViewModel>(context, listen: false);
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Kullanıcı giriş yapmışsa analiz sayısını yükle
        if (authViewModel.currentUser != null) {
          await adviceViewModel.loadAnalysisCount(authViewModel.currentUser!.uid);
        }
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        _logger.e('Veri yükleme hatası: $e');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    _analysisTimer?.cancel();
    _textRecognizer.close();
    super.dispose();
  }

  // Metin değiştiğinde çağrılır
  void _onTextChange() {
    // Önceki zamanlayıcıyı iptal et
    _analysisTimer?.cancel();
    
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // Kullanıcı yazımı bitirdiğinde otomatik analiz için 2 saniye bekle
      _analysisTimer = Timer(const Duration(seconds: 2), () {
        _analyzeMessage();
      });
    }
  }
  
  // Odak değiştiğinde çağrılır
  void _onFocusChange() {
    // Odak mesaj alanından çıktıysa ve içerik varsa analiz yap
    if (!_messageFocusNode.hasFocus && _messageController.text.trim().isNotEmpty) {
      _analysisTimer?.cancel(); // Eğer zamanlayıcı çalışıyorsa iptal et
      _analyzeMessage();
    }
  }

 

  // Analiz yapma
  Future<void> _analyzeMessage() async {
    // Kullanıcı kimliğini al
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.uid;
    
    if (userId == null) {
      Utils.showErrorFeedback(
        context, 
        'Lütfen önce giriş yapın'
      );
      return;
    }
    
    // Mesaj içeriğini kontrol et
    if (_imageMode) {
      if (_selectedImages.isEmpty) {
        Utils.showErrorFeedback(
          context, 
          'Lütfen en az bir görsel seçin'
        );
        return;
      }
      
      // Görsel modunda OCR işlemi yapılacak
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        // OCR işlemi
        String extractedText = '';
        for (final imageFile in _selectedImages) {
          final inputImage = InputImage.fromFilePath(imageFile.path);
          final recognizedText = await _textRecognizer.processImage(inputImage);
          extractedText += '${recognizedText.text}\n';
        }
        
        extractedText = extractedText.trim();
        _logger.i('OCR Sonucu: ${extractedText.isNotEmpty ? "${extractedText.substring(0, min(50, extractedText.length))}..." : "[BOŞ]"}');

        if (extractedText.isEmpty) {
          Utils.showErrorFeedback(
            context, 
            'Görselden metin okunamadı veya metin bulunamadı. Lütfen daha net bir görsel deneyin.'
          );
          Future.microtask(() {
            setState(() {
              _isLoading = false;
            });
          });
          return;
        }
        
        // AdviceViewModel'e mesajı gönder
        final adviceViewModel = Provider.of<AdviceViewModel>(context, listen: false);
        await adviceViewModel.analyzeMesaj(extractedText, userId);
        
        Future.microtask(() {
          setState(() {
            _isLoading = false;
            _selectedImages.clear();
            _imageMode = false;
          });
        });
      } catch (e) {
        _logger.e('Görsel analiz (OCR) hatası: $e');
        Future.microtask(() {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Görsel işlenirken bir hata oluştu: $e';
          });
          Utils.showErrorFeedback(
            context, 
            'Görsel işlenirken bir hata oluştu: $e'
          );
        });
      }
    } else {
      // Metin modu
      final messageText = _messageController.text.trim();
      if (messageText.isEmpty) {
        Utils.showErrorFeedback(
          context, 
          'Lütfen bir mesaj girin'
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final adviceViewModel = Provider.of<AdviceViewModel>(context, listen: false);
        await adviceViewModel.analyzeMesaj(messageText, userId);
        
        Future.microtask(() {
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            _messageController.clear();
          }
        });
      } catch (e) {
        _logger.e('Metin analizi hatası: $e');
        Future.microtask(() {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Mesaj analiz edilirken bir hata oluştu: $e';
          });
          Utils.showErrorFeedback(
            // ignore: use_build_context_synchronously
            context, 
            'Mesaj analiz edilirken bir hata oluştu: $e'
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdviceViewModel>(
      builder: (context, viewModel, child) {
        
        // Yükleme durumunu kontrol et
        final bool isLoading = _isLoading || viewModel.isAnalyzing;
        
        return PopScope(
          canPop: !isLoading,
          onPopInvoked: (bool didPop) async {
            // Eğer yükleme durumundaysa ve henüz çıkış yapılmamışsa onay iste
            if (isLoading && !didPop) {
              final bool shouldPop = await _showExitConfirmationDialog(context);
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF9D3FFF),
              title: const Text(
                'Mesaj Koçu',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  if (isLoading) {
                    final bool shouldPop = await _showExitConfirmationDialog(context);
                    if (shouldPop && mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              actions: [
                // Mod değiştirme butonu
                IconButton(
                  icon: Icon(_imageMode ? Icons.text_fields : Icons.image),
                  onPressed: () {
                    setState(() {
                      _imageMode = !_imageMode;
                      // Mod değiştiğinde içerikleri temizle
                      if (_imageMode) {
                        _messageController.clear();
                      } else {
                        _selectedImages.clear();
                      }
                    });
                  },
                  tooltip: _imageMode ? 'Metin Moduna Geç' : 'Görsel Moduna Geç',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF121212),
            body: Consumer<AdviceViewModel>(
              builder: (context, viewModel, child) {
                
                // Yükleniyor göstergesi (View'ın kendi isLoading'i VEYA ViewModel'in isAnalyzing durumu)
                if (_isLoading || viewModel.isAnalyzing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const YuklemeAnimasyonu(
                          renk: Color(0xFF9D3FFF),
                          analizTipi: AnalizTipi.DANISMA,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mesajınız analiz ediliyor...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Ana sayfa
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol üst köşede kullanıcı selamlama bölümü
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Consumer<AuthViewModel>(
                          builder: (context, authViewModel, _) {
                            final displayName = authViewModel.currentUser?.displayName ?? 'Ziyaretçi';
                            return Text(
                              'Merhaba, $displayName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Mesaj girişi veya görsel yükleme - Ana fonksiyonu direkt olarak en üste taşıyorum
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9D3FFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF9D3FFF).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analiz yapmak için mesajını yaz veya görsel yükle',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Açıklama
                            Text(
                              'Mesaj Koçu kartı aracılığıyla analiz yapabilirsiniz.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Kalan ücretsiz analiz sayısı
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3986),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kalan ücretsiz analiz: ${MessageCoachAnalysis.ucretlizAnalizSayisi - viewModel.ucretlizAnalizSayisi}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Mesaj Koçu kartı (en sonda gösterelim)
                      const MessageCoachCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Hata Mesajı Bölümü (ViewModel'den gelen veya View'ın kendi hatası)
                      if (viewModel.errorMessage != null || _errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Hata',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  viewModel.errorMessage ?? _errorMessage ?? 'Bilinmeyen bir hata oluştu.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      viewModel.resetError();
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    },
                                    child: const Text('Tamam'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Analiz sonuçları 
                      if (viewModel.hasAnalizi && viewModel.mesajAnalizi != null)
                        _buildAnalysisResults(viewModel.mesajAnalizi!),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  // Analiz sonuçları bölümü
  Widget _buildAnalysisResults(MessageCoachAnalysis analiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9D3FFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mesaj Analiz Sonuçları',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          // 1. Mesaj Etki Yüzdeleri
          _buildAnalysisSection(
            '📊 Mesaj Etki Yüzdeleri',
            child: _buildEtkiYuzdeleri(analiz.etki),
          ),
          
          // 2. Anlık Tavsiye
          _buildAnalysisSection(
            '💬 Anlık Tavsiye',
            content: analiz.anlikTavsiye ?? 'Tavsiye bulunamadı',
          ),
          
          // 3. Yeniden Yazım Önerisi
          _buildAnalysisSection(
            '✍️ Rewrite Önerisi',
            content: analiz.yenidenYazim ?? 'Öneri bulunamadı',
          ),
          
          // 4. Karşı Taraf Yorumu
          _buildAnalysisSection(
            '🔍 Karşı Taraf Yorumu',
            content: analiz.karsiTarafYorumu ?? 'Yorum bulunamadı',
          ),
          
          // 5. Strateji Önerisi
          _buildAnalysisSection(
            '🧭 Strateji Önerisi',
            content: analiz.strateji ?? 'Strateji bulunamadı',
            showDivider: false,
          ),
          
          const SizedBox(height: 16),
          
          // Yeni Analiz Yap butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Analiz sonucunu sıfırla
                Provider.of<AdviceViewModel>(context, listen: false).resetAnalysisResult();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yeni Analiz Yap'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Analiz bölümü yapısı
  Widget _buildAnalysisSection(String title, {String? content, Widget? child, bool showDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık alanı - daire içinde ikon ve metin olarak düzenlenmiş
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9D3FFF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getSectionIcon(title),
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (content != null)
          Padding(
            padding: const EdgeInsets.only(left: 40), // İçeriği ikon ile hizalamak için padding
            child: Text(
              content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        if (child != null) 
          Padding(
            padding: const EdgeInsets.only(left: 40), // Child widget'ı ikon ile hizalamak için padding
            child: child,
          ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withOpacity(0.1)),
          ),
      ],
    );
  }
  
  // Başlık içeriğine göre uygun ikonu döndürür
  IconData _getSectionIcon(String title) {
    if (title.contains('📊')) return Icons.bar_chart;
    if (title.contains('💬')) return Icons.chat_bubble_outline;
    if (title.contains('✍️')) return Icons.edit_note;
    if (title.contains('🔍')) return Icons.search;
    if (title.contains('🧭')) return Icons.map_outlined;
    return Icons.analytics_outlined;
  }
  
  // Etki yüzdelerini gösteren widget
  Widget _buildEtkiYuzdeleri(Map<String, int> etki) {
    if (etki.isEmpty) {
      return Text(
        'Etki analizi bulunamadı',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
        ),
      );
    }
    
    // API'dan gelen "dynamicData" özel durumu - bu statik veri olmadan dinamik işlem olduğunu göstermek için
    if (etki.length == 1 && etki.containsKey('dynamicData')) {
      return Text(
        'Analiz verisi işleniyor...',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    // Etki değerlerini azalan sırada sırala
    final List<MapEntry<String, int>> siralanmisEtki = etki.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      children: siralanmisEtki.map((entry) {
        final String etiket = entry.key;
        final int deger = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    etiket.capitalizeFirst,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '%$deger',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deger / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getEtkiRengi(etiket)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Color _getEtkiRengi(String etiket) {
    // Farklı etiketler için farklı renkler
    switch (etiket.toLowerCase()) {
      case 'sempatik':
      case 'olumlu':
      case 'positive':
        return Colors.green;
      case 'kararsız':
      case 'hesitant':
      case 'neutral':
      case 'nötr':
        return Colors.orange;
      case 'endişeli':
      case 'negative':
      case 'olumsuz':
        return Colors.red;
      case 'flörtöz':
        return Colors.purple;
      case 'mesafeli':
      case 'cold':
      case 'soğuk':
        return Colors.blue;
      case 'error':
        return Colors.grey;
      case 'dynamicdata':
        return const Color(0xFF9D3FFF);
      default:
        return const Color(0xFF9D3FFF); // Uygulama ana rengi
    }
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Dışarıya dokunarak kapatılamaz
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF352269),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Çıkmak istediğinize emin misiniz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Şu anda analiz devam ediyor. Çıkarsanız analiz iptal olacak ve işlem yarıda kalacak.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Çıkma
              },
              child: Text(
                'Devam Et',
                style: TextStyle(
                  color: const Color(0xFF9D3FFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Çık
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Çık',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false; // Null durumunda false döndür
  }
}

// String için extension - capitalizeFirst metodu
extension StringExtension on String {
  String get capitalizeFirst => length > 0 
      ? '${this[0].toUpperCase()}${substring(1)}'
      : '';
}