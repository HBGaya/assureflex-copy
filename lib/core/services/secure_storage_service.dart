import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService I = SecureStorageService._();

  // SINGLE INSTANCE with consistent options
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  // Keys
  static const String authTokenKey = 'auth_token';
  static const String fcmTokenKey = 'fcm_token';

  // Generic methods
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // Auth token specific methods
  Future<void> saveAuthToken(String token) => write(authTokenKey, token);
  Future<String?> readAuthToken() => read(authTokenKey);
  Future<void> clearAuthToken() => delete(authTokenKey);

  // FCM token specific methods
  Future<void> saveFcmToken(String token) => write(fcmTokenKey, token);
  Future<String?> readFcmToken() => read(fcmTokenKey);
  Future<void> clearFcmToken() => delete(fcmTokenKey);
}