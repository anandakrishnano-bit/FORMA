import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android Keystore-backed Secure Storage Service
///
/// CRITICAL SECURITY MANDATE:
/// The user's individual Gemini API key, authentication tokens, and encryption keys
/// are stored exclusively inside the hardware-backed Android Keystore
/// (EncryptedSharedPreferences with AES encryption). They are NEVER stored in ordinary
/// SharedPreferences, public files, or shared Firestore documents.
class SecureStorageService {
  static const String _userGeminiKey = 'user_personal_gemini_api_key';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true,
          ),
        );

  // User's own Gemini API Key
  Future<void> saveUserGeminiKey(String apiKey) async {
    await _storage.write(key: _userGeminiKey, value: apiKey.trim());
  }

  Future<void> saveUserGeminiApiKey(String apiKey) => saveUserGeminiKey(apiKey);

  Future<String?> getUserGeminiKey() async {
    return await _storage.read(key: _userGeminiKey);
  }

  Future<void> removeUserGeminiKey() async {
    await _storage.delete(key: _userGeminiKey);
  }

  // Generic Secure Operations
  Future<void> writeSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAllOnLogout() async {
    await _storage.deleteAll();
  }
}
