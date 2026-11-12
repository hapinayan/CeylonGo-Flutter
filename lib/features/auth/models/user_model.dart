/// CeylonGo User Model
/// Strictly conforms to Section 4 of Specification v1.0
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'traveler',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName, 'email': email, 'role': role};
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
