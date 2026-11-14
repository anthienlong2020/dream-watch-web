// Đọc giờ bằng giọng nói ("Bây giờ là 5 giờ chiều").
// Bản web dùng giọng đọc có sẵn của máy/trình duyệt (Web Speech), không cần mạng
// nếu máy đã có giọng tiếng Việt. Bản cài sau này sẽ dùng giọng của hệ điều hành.
export 'speech_stub.dart' if (dart.library.js_interop) 'speech_web.dart';

/// Câu đọc giờ theo kiểu nói của người Việt.
String hourSentence(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final String buoi;
  if (hour == 0) {
    buoi = 'đêm';
  } else if (hour < 11) {
    buoi = 'sáng';
  } else if (hour < 13) {
    buoi = 'trưa';
  } else if (hour < 18) {
    buoi = 'chiều';
  } else if (hour < 22) {
    buoi = 'tối';
  } else {
    buoi = 'đêm';
  }
  return 'Bây giờ là $h12 giờ $buoi';
}
