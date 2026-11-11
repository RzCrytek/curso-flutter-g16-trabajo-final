class UserModel {
  String uuid;
  String name;
  String? lastName;
  String email;
  DateTime? emailVerifiedAt;
  String? avatar;
  bool hasCustomAvatar;
  bool hasPassword;
  bool hasGoogle;

  UserModel({
    required this.uuid,
    required this.name,
    this.lastName,
    required this.email,
    this.emailVerifiedAt,
    this.avatar,
    required this.hasCustomAvatar,
    required this.hasPassword,
    required this.hasGoogle,
  });

  bool get isVerified => emailVerifiedAt != null;

  String get fullName => "$name ${lastName ?? ''}".trim();

  factory UserModel.fromJson(Map<String, dynamic> user) => UserModel(
    uuid: user["uuid"],
    name: user["name"],
    lastName: user["last_name"],
    email: user["email"],
    emailVerifiedAt: user["email_verified_at"] == null
        ? null
        : DateTime.parse(user["email_verified_at"]),
    avatar: user["avatar"],
    hasCustomAvatar: user["has_custom_avatar"] ?? false,
    hasPassword: user["has_password"] ?? false,
    hasGoogle: user["has_google"] ?? false,
  );
}
