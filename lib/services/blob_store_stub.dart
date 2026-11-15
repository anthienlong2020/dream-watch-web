// Bản chưa có kho riêng (test / app cài sau này): giữ trong bộ nhớ.
final Map<String, String> _mem = {};

Future<void> blobPut(String key, String value) async => _mem[key] = value;
Future<String?> blobGet(String key) async => _mem[key];
Future<void> blobDelete(String key) async => _mem.remove(key);
