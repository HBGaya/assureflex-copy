import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../../core/constants/api_endpoints.dart';

class ClaimRepository {
  final _dio = ApiService.I.dio;

  Future<Response> submit(Map<String, dynamic> formMap) async {
    final token = await AuthStorage.read();
    final data = FormData.fromMap(formMap);
    return await _dio.post(
      ApiEndpoints.claimForm,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token', 'Accept':'application/json'}),
    );
  }
}