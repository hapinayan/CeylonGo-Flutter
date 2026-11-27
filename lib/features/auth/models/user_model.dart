/// CeylonGo User Model
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? country;
  final String? avatarUrl;
  final bool emailVerified;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.country,
    this.avatarUrl,
    this.emailVerified = false,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'traveler',
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      emailVerified: json['email_verified'] == true,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (country != null) 'country': country,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'email_verified': emailVerified,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? country,
    String? avatarUrl,
    bool? emailVerified,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
