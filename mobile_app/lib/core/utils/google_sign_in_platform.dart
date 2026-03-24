export 'google_sign_in_stub.dart'
    if (dart.library.html) 'google_sign_in_web.dart'
    if (dart.library.io) 'google_sign_in_mobile.dart';
