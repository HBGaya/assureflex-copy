import 'secure_storage_service.dart';

class AuthStorage {
  static Future<void> save(String token) =>
      SecureStorageService.I.saveAuthToken(token);

  static Future<String?> read() =>
      SecureStorageService.I.readAuthToken();

  static Future<void> clear() =>
      SecureStorageService.I.clearAuthToken();
}