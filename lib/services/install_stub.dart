/// Ngoài web: không có chuyện "cài vào màn hình chính".
String installState() => 'unsupported';
String installPlatform() => 'desktop';
Future<String> promptInstall() async => 'unavailable';
