import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/analysis_result_model.dart';

class AnalysisResultBox extends StatelessWidget {
  final AnalysisResult result;
  final bool showDetailedInfo;
  final VoidCallback? onTap;

  const AnalysisResultBox({
    super.key,
    required this.result,
    this.showDetailedInfo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // İçerik Widget'ı
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Satırı
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                radius: 20,
                child: Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlişki Analizi Sonucum',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mesajlarınız analiz edildi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Özet Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Bilgi satırları
                _buildInfoRow(
                  context, 
                  'Duygu',
                  result.emotion,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context, 
                  'Niyet',
                  result.intent, 
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context, 
                  'Mesaj Tonu',
                  result.tone,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Ciddiyet:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSeverityIndicator(context, result.severity),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Konuşmada Yer Alan Kişiler:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.persons,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mesaj Yorumu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benim Düşüncem:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.aiResponse.containsKey('mesajYorumu') 
                      ? result.aiResponse['mesajYorumu']
                      : result.aiResponse['mesaj_yorumu'] ?? 'Mesaj yorumu bulunamadı',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Detaylı analiz içeriği
          if (showDetailedInfo) ...[
            const SizedBox(height: 24),
            _buildDetailedAnalysisContent(context),
          ],
          
          // Detay gösterme/gizleme butonu
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showDetailedInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showDetailedInfo ? 'Daha az göster' : 'Tavsiyeleri göster',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: content,
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms);
  }
  
  // Ciddiyet seviyesi indikatörü
  Widget _buildSeverityIndicator(BuildContext context, int severity) {
    final theme = Theme.of(context);
    
    // Renk ve etiket hesaplama
    Color color;
    String label;
    
    if (severity <= 3) {
      color = Colors.green;
      label = 'Düşük';
    } else if (severity <= 6) {
      color = Colors.orange;
      label = 'Orta';
    } else {
      color = Colors.red;
      label = 'Yüksek';
    }
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$severity/10 - $label',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              width: double.infinity,
              color: theme.colorScheme.surfaceVariant,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: severity / 10,
                child: Container(
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Bilgi satırı
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
  
  // Öneri listesi
  List<Widget> _buildSuggestionsList(BuildContext context, AnalysisResult result) {
    final theme = Theme.of(context);
    
    // Öneri listesini al
    List<String> suggestions = [];
    
    // tavsiyeler alanını kontrol et
    if (result.aiResponse.containsKey('tavsiyeler')) {
      final dynamic rawSuggestions = result.aiResponse['tavsiyeler'];
      if (rawSuggestions is List) {
        suggestions = rawSuggestions.map((item) => item.toString()).toList();
      } else if (rawSuggestions is String) {
        // String formatını işle
        try {
          // Virgülle ayrılmış bir liste olabilir
          final List<String> splitSuggestions = rawSuggestions.split(',');
          for (String suggestion in splitSuggestions) {
            if (suggestion.trim().isNotEmpty) {
              suggestions.add(suggestion.trim());
            }
          }
        } catch (e) {
          // String'i doğrudan bir öneri olarak ekle
          if (rawSuggestions.toString().trim().isNotEmpty) {
            suggestions.add(rawSuggestions.toString());
          }
        }
      }
    } 
    // Geriye dönük uyumluluk için cevapOnerileri alanını kontrol et
    else if (result.aiResponse.containsKey('cevapOnerileri')) {
      final dynamic rawSuggestions = result.aiResponse['cevapOnerileri'];
      if (rawSuggestions is List) {
        suggestions = rawSuggestions.map((item) => item.toString()).toList();
      } else if (rawSuggestions is String) {
        // String formatını işle
        try {
          // Virgülle ayrılmış bir liste olabilir
          final List<String> splitSuggestions = rawSuggestions.split(',');
          for (String suggestion in splitSuggestions) {
            if (suggestion.trim().isNotEmpty) {
              suggestions.add(suggestion.trim());
            }
          }
        } catch (e) {
          // String'i doğrudan bir öneri olarak ekle
          if (rawSuggestions.toString().trim().isNotEmpty) {
            suggestions.add(rawSuggestions.toString());
          }
        }
      }
    }
    
    // Öneri kartlarını oluştur
    return suggestions.asMap().entries.map((entry) {
      int index = entry.key;
      String suggestion = entry.value;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              radius: 16,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  // Tavsiyeler Listesi - yeni metot adı
  List<Widget> _buildTavsiyelerListesi(BuildContext context, AnalysisResult result) {
    return _buildSuggestionsList(context, result);
  }
  
  // Detaylı analiz içeriği
  Widget _buildDetailedAnalysisContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Duygu Çözümlemesi bölümü
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duygu Çözümlemesi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.emotion,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Niyet Yorumu bölümü
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Niyet Yorumu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.intent,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Tavsiyeler bölümü - Sadece tavsiyeler bölümünü göster, metin içeriğini gösterme
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tavsiyeler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildTavsiyelerListesi(context, result),
            ],
          ),
        ),
      ],
    );
  }
} 