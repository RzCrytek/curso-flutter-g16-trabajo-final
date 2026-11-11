import 'package:flutter/material.dart';
import 'package:primo_secreto_app/config/navigation.dart';
import 'package:primo_secreto_app/models/user_model.dart';
import 'package:primo_secreto_app/preferences/preferences_service.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/auth_service.dart';

enum AuthStatus { loading, offline, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService();

  AuthStatus status = AuthStatus.loading;
  UserModel? user;

  bool get isVerified => user?.isVerified ?? false;

  AuthProvider() {
    ApiClient.instance.onUnauthorized = _expireSession;
  }

  Future<void> init() async {
    final token = await _preferencesService.getToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    ApiClient.instance.token = token;
    try {
      user = await _authService.getUser();
      status = AuthStatus.authenticated;
    } on ApiException catch (_) {
      status = ApiClient.instance.token == null
          ? AuthStatus.unauthenticated
          : AuthStatus.offline;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _authService.login(email, password);
    await _startSession(result);
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String confirmation,
  ) async {
    final result = await _authService.register(
      name,
      email,
      password,
      confirmation,
    );
    await _startSession(result);
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } on ApiException catch (_) {}
    await _clearSession();
    goToRoot();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    user = await _authService.getUser();
    notifyListeners();
  }

  Future<void> resendVerificationEmail() =>
      _authService.resendVerificationEmail();

  Future<void> updateProfile(String name, String? lastName) async {
    user = await _authService.updateProfile(name, lastName);
    notifyListeners();
  }

  Future<void> uploadPhoto(String path) async {
    user = await _authService.uploadPhoto(path);
    notifyListeners();
  }

  Future<void> removePhoto() async {
    user = await _authService.removePhoto();
    notifyListeners();
  }

  Future<void> changePassword(
    String? currentPassword,
    String password,
    String confirmation,
  ) async {
    await _authService.changePassword(currentPassword, password, confirmation);
    user = await _authService.getUser();
    notifyListeners();
  }

  Future<void> unlinkGoogle(String currentPassword) async {
    user = await _authService.unlinkGoogle(currentPassword);
    notifyListeners();
  }

  Future<void> _startSession(AuthResult result) async {
    ApiClient.instance.token = result.token;
    await _preferencesService.setToken(result.token);
    user = result.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    ApiClient.instance.token = null;
    await _preferencesService.removeToken();
    user = null;
    status = AuthStatus.unauthenticated;
  }

  void _expireSession() {
    if (status == AuthStatus.unauthenticated) return;
    ApiClient.instance.token = null;
    _preferencesService.removeToken();
    user = null;
    status = AuthStatus.unauthenticated;
    goToRoot();
    notifyListeners();
  }
}
