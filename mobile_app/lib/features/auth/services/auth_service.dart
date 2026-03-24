import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user_model.dart';

class AuthService {
  final _api = ApiClient();

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
    });
    await _api.setToken(res.data['token']);
    return UserModel.fromJson(res.data['user']);
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _api.setToken(res.data['token']);
    return UserModel.fromJson(res.data['user']);
  }

  Future<UserModel> getMe() async {
    final res = await _api.dio.get('/auth/me');
    return UserModel.fromJson(res.data);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? birthday,
  }) async {
    final res = await _api.dio.put('/auth/profile', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
    });
    return UserModel.fromJson(res.data);
  }

  Future<void> deleteAccount() async {
    await _api.dio.delete('/auth/me');
    await _api.clearToken();
  }

  Future<void> logout() => _api.clearToken();

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  Future<UserModel> loginWithGoogle(String idToken) async {
    final res = await _api.dio.post('/auth/google', data: {'idToken': idToken});
    await _api.setToken(res.data['token']);
    return UserModel.fromJson(res.data['user']);
  }

  Future<void> sendOtp(String email) async {
    await _api.dio.post('/auth/send-otp', data: {'email': email});
  }

  Future<void> verifyOtp(String email, String code) async {
    await _api.dio.post('/auth/verify-otp', data: {'email': email, 'code': code});
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _api.dio.post('/auth/reset-password', data: {
      'email': email,
      'newPassword': newPassword,
    });
  }
}
