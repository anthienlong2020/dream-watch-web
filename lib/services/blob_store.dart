// Kho lưu dữ liệu lớn (bộ ảnh) ngoài localStorage (chỉ ~5 MB).
// Bản web dùng IndexedDB của trình duyệt (chứa được hàng trăm MB).
export 'blob_store_stub.dart' if (dart.library.js_interop) 'blob_store_web.dart';
