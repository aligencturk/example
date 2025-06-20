import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Uygulama yapılandırma servisi
/// .env dosyasından ve diğer kaynaklardan yapılandırma değerlerini yönetir
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  
  // Singleton yapıcı
  factory ConfigService() {
    return _instance;
  }
  
  ConfigService._internal();
  
 
  
  /// API anahtarını alır
  String? getApiKey() {
    return dotenv.env['GEMINI_API_KEY'];
  }
  
  /// AI model adını alır
  String? getAiModelName() {
    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';
  }
  
  /// Maksimum token sayısını alır
  int getMaxTokens() {
    final maxTokensStr = dotenv.env['GEMINI_MAX_TOKENS'];
    return maxTokensStr != null ? int.tryParse(maxTokensStr) ?? 1024 : 1024;
  }
  
  /// Uygulama ortamını alır (development, production)
  String getAppEnvironment() {
    return dotenv.env['APP_ENV'] ?? 'development';
  }
  
  /// Kullanıcı başına günlük maksimum mesaj sayısını alır
  int getMaxMessagesPerDay() {
    final maxMsgStr = dotenv.env['MAX_MESSAGES_PER_DAY'];
    return maxMsgStr != null ? int.tryParse(maxMsgStr) ?? 10 : 10;
  }
  
  /// Firebase proje ID'sini alır
  String? getFirebaseProjectId() {
    return dotenv.env['FIREBASE_PROJECT_ID'];
  }
  
  /// Firebase storage bucket adını alır
  String? getFirebaseStorageBucket() {
    return dotenv.env['FIREBASE_STORAGE_BUCKET'];
  }
  
  /// Debug modda mı çalıştığımızı kontrol eder
  bool isDebugMode() {
    return kDebugMode;
  }
}
