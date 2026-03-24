import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    if (await _service.isLoggedIn()) {
      try {
        _user = await _service.getMe();
        notifyListeners();
      } catch (_) {
        await _service.logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(email: email, password: password);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String fullName, String email, String password, String? phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(
        fullName: fullName, email: email, password: password, phoneNumber: phone);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? fullName, String? phone, String? bio, String? avatarUrl,
      String? gender, DateTime? birthday}) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _service.updateProfile(
        fullName: fullName, phoneNumber: phone, bio: bio, avatarUrl: avatarUrl,
        gender: gender, birthday: birthday);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.loginWithGoogle(idToken);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _parseError(dynamic e) {
    try {
      return e.response?.data['message'] ?? 'Có lỗi xảy ra';
    } catch (_) {
      return 'Không thể kết nối đến server';
    }
  }
}
