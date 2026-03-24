import 'package:google_sign_in/google_sign_in.dart';

final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

/// Google Sign-In cho mobile — trả về ID token
Future<String> googleSignInWeb() async {
  final account = await _googleSignIn.signIn();
  if (account == null) throw Exception('Người dùng hủy đăng nhập');
  final auth = await account.authentication;
  final idToken = auth.idToken;
  if (idToken == null) throw Exception('Không lấy được ID token');
  return idToken;
}
