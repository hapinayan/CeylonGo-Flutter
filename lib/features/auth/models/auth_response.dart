import 'user_model.dart';

/// CeylonGo Registration Response
/// Section 4.1: POST /api/v1/auth/register 201 Created
class RegisterResponse {
  final String message;
  final UserModel user;

  const RegisterResponse({required this.message, required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('user') || json['user'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid registration response: missing user object.',
      );
    }

    return RegisterResponse(
      message:
          json['message'] as String? ??
          'Account created successfully. Please sign in.',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'user': user.toJson()};
  }
}

/// CeylonGo Login Response
/// Section 4.2: POST /api/v1/auth/login 200 OK
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'] as String?;
    if (token == null || token.trim().isEmpty) {
      throw const FormatException(
        'Invalid login response: missing or empty access_token.',
      );
    }

    final tokenType = json['token_type'] as String? ?? '';
    if (tokenType.toLowerCase() != 'bearer') {
      throw FormatException(
        'Invalid token_type: expected "bearer", received "$tokenType".',
      );
    }

    if (!json.containsKey('user') || json['user'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid login response: missing user object.',
      );
    }

    return LoginResponse(
      accessToken: token,
      tokenType: tokenType,
      expiresIn: json['expires_in'] as int? ?? 3600,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}
