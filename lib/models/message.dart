import 'package:cloud_firestore/cloud_firestore.dart';
import 'analysis_result_model.dart';

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp ?? Timestamp.now(),
      'sentAt': Timestamp.fromDate(sentAt),
      'sentByUser': sentByUser,
      'isAnalyzed': isAnalyzed,
      'imageUrl': imageUrl ?? '',
      'imagePath': imagePath ?? '',
      'analysisResult': analysisResult?.toMap(),
      'userId': userId,
      'errorMessage': errorMessage,
      'isAnalyzing': isAnalyzing,
    };
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
    
    // Timestamp veya sentAt'ten DateTime oluştur
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
          ? AnalysisResult.fromMap(map['analysisResult'])
          : null,
      userId: map['userId'] ?? '',
      errorMessage: map['errorMessage'],
      isAnalyzing: map['isAnalyzing'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, sentAt: $sentAt, isAnalyzed: $isAnalyzed)';
  }
} 