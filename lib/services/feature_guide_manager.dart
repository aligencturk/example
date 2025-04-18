import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/feature_guide_overlay.dart';

/// Ana sayfa rehberi için durumları yöneten servis
class FeatureGuideManager {
  // SharedPreferences anahtarı
  static const String _keyHomeTutorial = 'hasSeenHomeTutorial';
  
  /// Ana sayfa rehberinin daha önce görülüp görülmediğini kontrol eder
  static Future<bool> hasSeenGuide() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHomeTutorial) ?? false;
    } catch (e) {
      debugPrint('Rehber durumu kontrol hatası: $e');
      return false;
    }
  }
  
  /// Ana sayfa rehberinin görüldüğünü işaretler
  static Future<bool> markGuideSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyHomeTutorial, true);
    } catch (e) {
      debugPrint('Rehber durumu kaydetme hatası: $e');
      return false;
    }
  }
  
  /// Ana sayfa rehberinin görülme durumunu sıfırlar
  static Future<bool> resetGuideStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyHomeTutorial, false);
    } catch (e) {
      debugPrint('Rehber durumu sıfırlama hatası: $e');
      return false;
    }
  }
  
  /// Ana sayfa rehberi adımlarını oluşturur
  static List<GuideStep> createHomeGuideSteps({
    required Rect analyzeButtonArea,
    required Rect relationshipScoreCardArea,
    required Rect categoryAnalysisArea,
    required Rect relationshipEvaluationButtonArea,
  }) {
    return [
      GuideStep(
        title: 'Analiz Başlatma',
        description: 'Buradan yeni bir ilişki analizi başlatabilirsin.',
        targetArea: analyzeButtonArea,
        highlightShape: HighlightShape.circle,
        tooltipPosition: TooltipPosition.right,
        borderWidth: 3.0,
        padding: 8.0,
      ),
      GuideStep(
        title: 'İlişki Puanı',
        description: 'Burada ilişkinin genel skorunu görebilirsin.',
        targetArea: relationshipScoreCardArea,
        highlightShape: HighlightShape.roundedRect,
        tooltipPosition: TooltipPosition.bottom,
        borderWidth: 2.5,
        padding: 10.0,
      ),
      GuideStep(
        title: 'Kategori Analizleri',
        description: 'İlişkindeki farklı boyutların puanları burada ayrı ayrı gösterilir.',
        targetArea: categoryAnalysisArea,
        highlightShape: HighlightShape.roundedRect,
        tooltipPosition: TooltipPosition.right,
        borderWidth: 2.5,
        padding: 8.0,
      ),
      GuideStep(
        title: 'İlişki Değerlendirmesi',
        description: 'İlişki değerlendirmesini bu butondan başlatabilirsin.',
        targetArea: relationshipEvaluationButtonArea,
        highlightShape: HighlightShape.oval,
        tooltipPosition: TooltipPosition.left,
        borderWidth: 3.0,
        padding: 8.0,
      ),
    ];
  }
  
  /// Ana sayfa rehberini gösterir
  static void showGuide({
    required BuildContext context,
    required List<GuideStep> steps,
    required VoidCallback onCompleted,
  }) {
    // Overlay entry değişkeni
    late OverlayEntry overlayEntry;
    
    // Overlay entry oluştur
    overlayEntry = OverlayEntry(
      builder: (context) => FeatureGuideOverlay(
        steps: steps,
        onCompleted: () {
          // Overlay'i kaldır
          overlayEntry.remove();
          
          // Rehberi gördü olarak işaretle
          markGuideSeen();
          
          // Tamamlandı geri çağırımını çalıştır
          onCompleted();
        },
        onClose: () {
          // Overlay'i kaldır
          overlayEntry.remove();
          
          // Rehberi gördü olarak işaretle
          markGuideSeen();
          
          // Tamamlandı geri çağırımını çalıştır
          onCompleted();
        },
      ),
    );
    
    // Overlay'i ekle
    Overlay.of(context).insert(overlayEntry);
  }
} 