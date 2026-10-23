/// Vai trò tài khoản (SRS 2). Buyer/Seller là chế độ của cùng một USER.
enum AuthRole { user, staff, admin }

/// Người đang đăng nhập — đủ để router và khung app quyết định hiển thị gì.
/// Hồ sơ đầy đủ lấy qua feature account.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.hasShop,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final AuthRole role;
  final bool hasShop;
  final String? avatarUrl;

  bool get isStaffOrAdmin => role != AuthRole.user;

  AuthUser copyWith({String? fullName, bool? hasShop, String? avatarUrl}) =>
      AuthUser(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        hasShop: hasShop ?? this.hasShop,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role.name,
    'hasShop': hasShop,
    'avatarUrl': avatarUrl,
  };

  factory AuthUser.fromJson(Map<String, Object?> json) => AuthUser(
    id: json['id']! as String,
    email: json['email']! as String,
    fullName: json['fullName']! as String,
    role: AuthRole.values.byName(json['role']! as String),
    hasShop: json['hasShop']! as bool,
    avatarUrl: json['avatarUrl'] as String?,
  );
}
