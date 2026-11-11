import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:primo_secreto_app/models/user_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';

class AuthResult {
  UserModel user;
  String token;

  AuthResult({required this.user, required this.token});
}

class AuthService {
  final ApiClient _api = ApiClient.instance;

  String get _deviceName => "app-${Platform.operatingSystem}";

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post(
      "/login",
      body: {"email": email, "password": password, "device_name": _deviceName},
    );
    return AuthResult(user: UserModel.fromJson(data), token: data["token"]);
  }

  Future<AuthResult> register(
    String name,
    String email,
    String password,
    String confirmation,
  ) async {
    final data = await _api.post(
      "/register",
      body: {
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": confirmation,
        "device_name": _deviceName,
      },
    );
    return AuthResult(user: UserModel.fromJson(data), token: data["token"]);
  }

  Future<void> logout() async {
    await _api.post("/logout");
  }

  Future<UserModel> getUser() async {
    return UserModel.fromJson(await _api.get("/user"));
  }

  Future<void> resendVerificationEmail() async {
    await _api.post("/email/verification-notification");
  }

  Future<void> forgotPassword(String email) async {
    await _api.post("/forgot-password", body: {"email": email});
  }

  Future<UserModel> updateProfile(String name, String? lastName) async {
    final data = await _api.patch(
      "/user",
      body: {"name": name, "last_name": lastName},
    );
    return UserModel.fromJson(data);
  }

  Future<UserModel> uploadPhoto(String path) async {
    final data = await _api.postForm(
      "/user/photo",
      files: [await http.MultipartFile.fromPath("photo", path)],
    );
    return UserModel.fromJson(data);
  }

  Future<UserModel> removePhoto() async {
    return UserModel.fromJson(await _api.delete("/user/photo"));
  }

  Future<void> changePassword(
    String? currentPassword,
    String password,
    String confirmation,
  ) async {
    await _api.put(
      "/user/password",
      body: {
        "current_password": ?currentPassword,
        "password": password,
        "password_confirmation": confirmation,
      },
    );
  }

  Future<UserModel> unlinkGoogle(String currentPassword) async {
    final data = await _api.delete(
      "/user/google",
      body: {"current_password": currentPassword},
    );
    return UserModel.fromJson(data);
  }
}
