import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Türkçe karakter girişi için yardımcı servis
class InputService {
  /// TextField için TextInputFormatter oluşturur
  static List<TextInputFormatter> getTurkishTextFormatters() {
    // Basitleştirilmiş yaklaşım - kısıtlama olmadan
    return [];
  }
  
  /// TextField'a Türkçe karakter desteği ekleyen dekorasyon
  static InputDecoration getTurkishInputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      helperText: helperText,
      errorText: errorText,
      helperStyle: const TextStyle(fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  /// Klavye girişini aktif etmek için method
  static void activateSystemKeyboard(BuildContext context) {
    // Aktif TextField'a odaklandığında sistem klavyesini etkinleştir
    TextInput.finishAutofillContext(shouldSave: true);
  }
  
  /// Şifre alanı için özel dekorasyon
  static InputDecoration getPasswordInputDecoration({
    required String labelText,
    required bool isObscure,
    required VoidCallback toggleObscure,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF9D3FFF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
      suffixIcon: IconButton(
        icon: Icon(
          isObscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.white70,
        ),
        onPressed: toggleObscure,
      ),
      errorText: errorText,
    );
  }
}

/// Tüm metinlerde Türkçe karakter kontrolü
extension StringExtension on String {
  String get fixTurkishChars {
    return replaceAll('i', 'i')
        .replaceAll('ı', 'ı')
        .replaceAll('ğ', 'ğ')
        .replaceAll('ü', 'ü')
        .replaceAll('ş', 'ş')
        .replaceAll('ö', 'ö')
        .replaceAll('ç', 'ç')
        .replaceAll('İ', 'İ')
        .replaceAll('I', 'I')
        .replaceAll('Ğ', 'Ğ')
        .replaceAll('Ü', 'Ü')
        .replaceAll('Ş', 'Ş')
        .replaceAll('Ö', 'Ö')
        .replaceAll('Ç', 'Ç');
  }
} 