import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Utility để pick ảnh — hoạt động cả web lẫn mobile
class FilePickerUtil {
  static final _picker = ImagePicker();

  /// Pick 1 ảnh từ gallery, trả về bytes + filename
  static Future<({Uint8List bytes, String name})?> pickImage() async {
    if (kIsWeb) {
      final xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      return (bytes: bytes, name: xfile.name.isNotEmpty ? xfile.name : 'image.jpg');
    } else {
      final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      return (bytes: bytes, name: xfile.name.isNotEmpty ? xfile.name : 'image.jpg');
    }
  }

  /// Pick nhiều ảnh
  static Future<List<XFile>> pickMultipleImages() async {
    return await _picker.pickMultiImage(imageQuality: 85);
  }

  /// Pick video
  static Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(source: ImageSource.gallery);
  }
}
