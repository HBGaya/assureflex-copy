import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/response_guard.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final _dio = ApiService.I.dio;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final token = await NotificationService.I.readToken() ?? '';
    final platform = NotificationService.I.platform;
    Map form = {
      'email': email,
      'password': password,
      if (token.isNotEmpty) 'device_token': token,
      'platform': platform, // harmless if server ignores; keep if required
    };
    print(form);
    final res = await _dio.post(ApiEndpoints.login, data: form);

    final body = (res.data as Map).cast<String, dynamic>();
    ResponseGuard.unwrap(body);
    final auth = AuthResponse.fromWrapped(body);

    if (auth.token.isEmpty) throw Exception('Missing token in response');
    await AuthStorage.save(auth.token);
    return auth;
  }

  Future<bool> logout() async {
    // final token = await NotificationService.I.readToken() ?? '';
    // final platform = NotificationService.I.platform;
    try{
      print(ApiEndpoints.logout);
      final token = await AuthStorage.read();
      await _dio.post(ApiEndpoints.logout,options: Options(headers: {'Authorization': 'Bearer $token', 'Accept':'application/json'}));
      // final body = (res.data as Map).cast<String, dynamic>();
      // ResponseGuard.unwrap(body);
      // final auth = AuthResponse.fromWrapped(body);

      // if (auth.token.isEmpty) throw Exception('Missing token in response');
    }catch(e){
      print('Something went wrong\n$e');
    }finally{
      await AuthStorage.clear();
      return true;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    final token = await NotificationService.I.readToken() ?? '';
    final platform = NotificationService.I.platform;

    final res = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (token.isNotEmpty) 'device_token': token,
      'platform': platform, // if your server expects it on register too
    });

    final body = (res.data as Map).cast<String, dynamic>();
    ResponseGuard.unwrap(body); // throws clean message on errors
  }

  Future<void> forgotPassword(String email) async {
    final res = await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    ResponseGuard.unwrap((res.data as Map).cast<String, dynamic>());
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final res = await _dio.post(ApiEndpoints.verifyOtp, data: {'email': email, 'otp': otp});
    ResponseGuard.unwrap((res.data as Map).cast<String, dynamic>());
  }

  Future<void> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await _dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    });
    ResponseGuard.unwrap((res.data as Map).cast<String, dynamic>());
  }
}
