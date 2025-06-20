import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analysis_result_model.dart';
import '../services/encryption_service.dart';

enum AnalysisSource {
  text,
  image,
  normal,
  // İleride gerekirse başka kaynaklar eklenebilir (örn: consultation)
}

class Message {
  final String id;
  final String content;
  final DateTime sentAt;
  final Timestamp? timestamp;
  final bool sentByUser;
  final bool isAnalyzed;
  final String? imageUrl;
  final String? imagePath;
  final AnalysisResult? analysisResult;
  final String userId;
  final String? errorMessage;
  final bool isAnalyzing;
  final AnalysisSource? analysisSource;

  Message({
    required this.id,
    required this.content,
    required this.sentAt,
    this.timestamp,
    required this.sentByUser,
    this.isAnalyzed = false,
    this.imageUrl,
    this.imagePath,
    this.analysisResult,
    required this.userId,
    this.errorMessage,
    this.isAnalyzing = false,
    this.analysisSource,
  });

  Message copyWith({
    String? id,
    String? content,
    DateTime? sentAt,
    Timestamp? timestamp,
    bool? sentByUser,
    bool? isAnalyzed,
    String? imageUrl,
    String? imagePath,
    AnalysisResult? analysisResult,
    String? userId,
    String? errorMessage,
    bool? isAnalyzing,
    AnalysisSource? analysisSource,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      timestamp: timestamp ?? this.timestamp,
      sentByUser: sentByUser ?? this.sentByUser,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      analysisResult: analysisResult ?? this.analysisResult,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisSource: analysisSource ?? this.analysisSource,
    );
  }

  Map<String, dynamic> toMap() {
    String? analysisSourceStr = analysisSource?.name;
    
    final map = <String, dynamic>{
      'content': content,
      'timestamp': timestamp ?? Timestamp.now(),
      'sentAt': Timestamp.fromDate(sentAt),
      'sentByUser': sentByUser,
      'isAnalyzed': isAnalyzed,
      'userId': userId,
      'isAnalyzing': isAnalyzing,
    };
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    
    if (imagePath != null && imagePath!.isNotEmpty) {
      map['imagePath'] = imagePath;
    }
    
    if (analysisResult != null) {
      try {
        final analysisMap = analysisResult!.toMap();
        if (analysisMap.isNotEmpty) {
          map['analysisResult'] = analysisMap;
        }
      } catch (e) {
        print("HATA: analysisResult.toMap() çağrısında hata: $e");
      }
    }
    
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      map['errorMessage'] = errorMessage!;
    }
    
    if (analysisSourceStr != null && analysisSourceStr.isNotEmpty) {
      map['analysisSource'] = analysisSourceStr;
    }
    
    print("Message.toMap() çıktısı - ID: $id");
    map.forEach((key, value) {
      print(" - $key: ${value.runtimeType} = $value");
    });
    
    return map;
  }

  factory Message.fromMap(Map<String, dynamic> map, {String? docId}) {
    String messageId = '';
    
    if (docId != null && docId.isNotEmpty) {
      messageId = docId;
    } else if (map['id'] != null && map['id'].toString().isNotEmpty) {
      messageId = map['id'];
    }
    
    if (messageId.isEmpty) {
      print('UYARI: Message.fromMap - Boş ID oluşturuldu. DocID: $docId, Map ID: ${map['id']}');
    }
    
    DateTime convertToDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    
    final timestamp = map['timestamp'] as Timestamp?;
    final sentAtData = map['sentAt'];
    final sentAt = sentAtData != null ? convertToDateTime(sentAtData) :
                   timestamp != null ? timestamp.toDate() :
                   DateTime.now();

    AnalysisSource? source;
    if (map['analysisSource'] is String) {
      try {
        source = AnalysisSource.values.byName(map['analysisSource']);
      } catch (e) {
        print('UYARI: Message.fromMap - Geçersiz AnalysisSource değeri: ${map['analysisSource']}');
        source = null;
      }
    }

    return Message(
      id: messageId,
      content: map['content'] ?? '',
      sentAt: sentAt,
      timestamp: timestamp ?? (sentAtData != null ? Timestamp.fromDate(sentAt) : null),
      sentByUser: map['sentByUser'] ?? true,
      isAnalyzed: map['isAnalyzed'] ?? false,
      imageUrl: map['imageUrl'],
      imagePath: map['imagePath'],
      analysisResult: map['analysisResult'] != null
          ? _decryptAndParseAnalysisResult(map['analysisResult'])
          : null,
      userId: map['userId'] ?? '',
      errorMessage: map['errorMessage'],
      isAnalyzing: map['isAnalyzing'] ?? false,
      analysisSource: source,
    );
  }

  // Şifreli analiz sonucunu çözme ve parse etme
  static AnalysisResult? _decryptAndParseAnalysisResult(dynamic analysisData) {
    try {
      if (analysisData is String) {
        // Şifreli string ise çöz
        final decryptedData = EncryptionService().decryptJson(analysisData);
        return AnalysisResult.fromMap(decryptedData);
      } else if (analysisData is Map<String, dynamic>) {
        // Şifrelenmemiş Map ise doğrudan parse et (geriye dönük uyumluluk)
        return AnalysisResult.fromMap(analysisData);
      }
      return null;
    } catch (e) {
      print('Analiz sonucu çözülürken hata: $e');
      return null;
    }
  }

  @override
  String toString() {
    return 'Message(id: $id, content: ${content.substring(0, min(content.length, 20))}..., sentAt: $sentAt, isAnalyzed: $isAnalyzed, analysisSource: $analysisSource)';
  }
} 