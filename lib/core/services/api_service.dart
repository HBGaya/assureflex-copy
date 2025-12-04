// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import '../constants/env.dart';

String _extractErrorMessage(dynamic body) {
  if (body is Map<String, dynamic>) {
    // Prefer "message"
    final msg = body['message']?.toString();
    if (msg != null && msg.isNotEmpty) return msg;

    // Or first validation error
    final errs = body['errors'];
    if (errs is Map && errs.isNotEmpty) {
      final firstKey = errs.keys.first;
      final firstVal = errs[firstKey];
      if (firstVal is List && firstVal.isNotEmpty) return firstVal.first.toString();
      if (firstVal is String) return firstVal;
    }
  }
  return 'Something went wrong';
}

class ApiService {
  ApiService._();
  static final ApiService I = ApiService._();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(
    InterceptorsWrapper(
        onError: (e, h) {
          final body = e.response?.data;
          String msg = 'Something went wrong';
          if (body is Map) {
            msg = body['message']?.toString() ?? msg;
            final errs = body['errors'];
            if ((msg.isEmpty || msg == 'Invalid credentials') && errs is Map && errs.isNotEmpty) {
              final first = errs.values.first;
              if (first is List && first.isNotEmpty) msg = first.first.toString();
              if (first is String) msg = first;
            }
          }
          h.reject(DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: msg,      // <-- keep only the clean string
            type: e.type,
          ));
        }
    ),
  );
}
