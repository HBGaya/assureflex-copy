import 'user.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  // NEW: parse from the top-level server wrapper
  factory AuthResponse.fromWrapped(Map<String, dynamic> body) {
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final userMap = (data['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AuthResponse(
      token: (data['token'] ?? '').toString(),
      user: User.fromJson(userMap),
    );
  }
}
