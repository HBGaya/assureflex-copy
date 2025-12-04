import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _k = 'auth_token';
  static const _s = FlutterSecureStorage();

  static Future<void> save(String token) => _s.write(key: _k, value: token);
  static Future<String?> read() => _s.read(key: _k);
  static Future<void> clear() => _s.delete(key: _k);
}