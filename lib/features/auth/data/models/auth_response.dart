import '../../domain/entities/user.dart';

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final AuthUser user;

  const AuthResponse(
      {required this.accessToken, required this.tokenType, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken']?.toString() ?? '',
        tokenType: json['tokenType']?.toString() ?? 'Bearer',
        user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      );
}
