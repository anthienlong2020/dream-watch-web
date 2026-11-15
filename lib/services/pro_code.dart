/// Mã mở khoá bản Pro, dạng DW-XXXX-XXXX (6 ký tự ngẫu nhiên + 2 ký tự kiểm tra).
/// Tạo mã bằng: python3 tool/gen_pro_codes.py 20
const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const String _salt = 'DreamWatch2026|';

int _fnv1a(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

String _check(String body) {
  final h = _fnv1a('$_salt$body');
  return '${_alphabet[h % 32]}${_alphabet[(h >> 5) % 32]}';
}

/// Chuẩn hoá mã người dùng gõ (bỏ dấu cách, gạch, chữ thường; chữ O → 0 không dùng).
String normalizeProCode(String raw) {
  var s = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (s.startsWith('DW')) s = s.substring(2);
  return s;
}

bool isValidProCode(String raw) {
  final s = normalizeProCode(raw);
  if (s.length != 8) return false;
  if (s.split('').any((c) => !_alphabet.contains(c))) return false;
  return _check(s.substring(0, 6)) == s.substring(6);
}
