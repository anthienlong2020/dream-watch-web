// Lưu file ra thiết bị: bản web dùng tải xuống của trình duyệt,
// bản cài (Android/iOS/Windows) dùng hộp thoại lưu file của hệ điều hành.
export 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart';
