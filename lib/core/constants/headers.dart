import 'package:dio/dio.dart';

class HeadersBuilder {
  static Options json({String? token}) => Options(
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  static Options form({String? token}) => Options(
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
}