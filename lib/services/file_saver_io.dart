import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Lưu [bytes] thành file tên [fileName]. Trả về true nếu đã lưu.
Future<bool> saveBytesToDevice(Uint8List bytes, String fileName) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Lưu bộ cấu hình',
    fileName: fileName,
    bytes: bytes,
  );
  if (path == null) return false;
  // Trên máy tính, hộp thoại chỉ trả về đường dẫn, app tự ghi file.
  if (!(Platform.isAndroid || Platform.isIOS)) {
    await File(path).writeAsBytes(bytes);
  }
  return true;
}
