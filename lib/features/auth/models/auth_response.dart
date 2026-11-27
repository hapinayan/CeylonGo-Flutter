import 'user_model.dart';

/// CeylonGo Email OTP Challenge Response
/// POST /api/v1/auth/register (202 Accepted) & /api/v1/auth/resend-email-otp
class TravelerChallengeResponse {
  final String message;
  final String email;
  final String registrationId;
  final int expiresIn;
  final int resendAfter;

  const TravelerChallengeResponse({
    required this.message,
    required this.email,
    required this.registrationId,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory TravelerChallengeResponse.fromJson(Map<String, dynamic> json) {
    final regId = json['registration_id'] as String?;
    if (regId == null || regId.trim().isEmpty) {
      throw const FormatException(
        'Invalid registration challenge: missing registration_id.',
      );
    }

    return TravelerChallengeResponse(
      message: json['message'] as String? ?? 'Verification code sent.',
      email: json['email'] as String? ?? '',
      registrationId: regId,
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse('${json['expires_in']}') ?? 300,
      resendAfter: json['resend_after'] is int
          ? json['resend_after'] as int
          : int.tryParse('${json['resend_after']}') ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'email': email,
    'registration_id': registrationId,
    'expires_in': expiresIn,
    'resend_after': resendAfter,
  };
}

/// CeylonGo Registration Response
/// Supports both 202 OTP Challenge flow (current MVP) and 201 immediate user response.
class RegisterResponse {
  final String message;
  final UserModel user;
  final TravelerChallengeResponse? challenge;

  const RegisterResponse({
    required this.message,
    required this.user,
    this.challenge,
  });

  bool get requiresOtpVerification => challenge != null;

  factory RegisterResponse.fromChallenge(
    TravelerChallengeResponse challenge, {
    String fullName = '',
  }) {
    return RegisterResponse(
      message: challenge.message,
      user: UserModel(
        id: '',
        fullName: fullName,
        email: challenge.email,
        role: 'traveler',
      ),
      challenge: challenge,
    );
  }

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('registration_id')) {
      return RegisterResponse.fromChallenge(
        TravelerChallengeResponse.fromJson(json),
      );
    }

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
    return {
      'message': message,
      'user': user.toJson(),
      if (challenge != null) 'challenge': challenge!.toJson(),
    };
  }
}

/// CeylonGo Login Response
/// POST /api/v1/auth/login 200 OK
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
