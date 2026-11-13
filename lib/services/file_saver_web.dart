import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Bản web: tải file xuống (thường vào thư mục Downloads / Tệp của máy).
Future<bool> saveBytesToDevice(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  a.style.display = 'none';
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
  Future.delayed(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
  return true;
}
