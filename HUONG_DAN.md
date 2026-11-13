# Đồng hồ mộng mơ 2.0 (Flutter)

Viết lại từ bản Unity 2019.4. Chạy được trên Web, Android, iOS, Windows.

## Có gì mới so với bản Unity

| | Bản Unity | Bản Flutter 2.0 |
|---|---|---|
| Mặt đồng hồ 12 hình, hình giờ xoay, hình phút nhảy, hình giây chạy vòng | ✔ | ✔ (giữ nguyên ý tưởng) |
| Hình giờ hiện to ở giữa | ✔ | ✔ thở nhẹ, cứ 20 giây phóng to rồi quay đầu |
| Người dùng tự chọn ảnh | ✗ (ảnh cố định) | ✔ 12 ô, chọn từng ảnh hoặc nhiều ảnh một lúc |
| Chủ đề có sẵn | Khủng long | Khủng long, 12 con giáp, Ảnh của tôi |
| Âm báo mỗi giờ | ✗ | ✔ đánh số tiếng / giai điệu / cả hai, báo nửa giờ, giờ yên lặng |
| Báo thức | ✗ | ✔ nhiều báo thức, lặp theo thứ, báo lại 5 phút |
| Hẹn giờ (đếm ngược), Bấm giờ | ✗ | ✔ |
| Giữ màn hình sáng | ✔ | ✔ (bật/tắt được) |

Lỗi nhỏ của bản cũ đã sửa: phút 58–59 bị tính vào vị trí XI, đúng ra là XII.

## Cài đặt lần đầu (copy từng lệnh)

1. Giải nén `dream_watch.zip` vào ví dụ `D:\Flutter\dream_watch`.
2. Mở Terminal (PowerShell) tại thư mục đó rồi chạy:

```
flutter create . --project-name dream_watch --platforms=web,android,ios,windows
flutter pub get
flutter analyze
flutter test
```

Lệnh `flutter create .` chỉ tạo thêm các thư mục `web`, `android`, `windows`...
và không ghi đè code trong `lib`.

3. Chạy thử trên trình duyệt:

```
flutter run -d chrome
```

## Đưa ảnh khủng long cũ vào

Trong project Unity cũ, tìm 12 ảnh khủng long (thường ở `Assets/Sprites` hoặc `Assets/Images`).
Chép vào `assets/themes/khung_long/` và đổi tên thành `1.png` ... `12.png` theo vị trí
I ... XII trên mặt đồng hồ. Thiếu ảnh nào thì app dùng emoji thay thế.

Người dùng cũng có thể tự chọn ảnh ngay trong app: **Cài đặt → Ảnh của tôi**.

## Test trên điện thoại (qua web, giống POLOTO)

```
flutter build web --release
```

Rồi đưa nội dung thư mục `build/web` lên Render Static Site (repo riêng), giống cách làm POLOTO:

```
cd build\web
git init
git add .
git commit -m "dream watch web"
git branch -M main
git remote add origin <link repo GitHub của web>
git push -u origin main --force
```

## Giới hạn cần biết

- **Bản web**: trình duyệt bắt chạm vào màn hình một lần thì mới phát được tiếng, nên app có
  màn hình "Chạm để bắt đầu". Báo thức và báo giờ chỉ kêu khi tab đang mở. Nếu tắt màn hình
  hoặc chuyển sang app khác, điện thoại có thể cho tab "ngủ".
- **Báo thức khi đã đóng app** (Android/iOS): cần thêm thông báo hệ thống. Đây là bước sau,
  làm khi chuyển sang bản cài đặt.

## Cấu trúc code

```
lib/
  main.dart                  khung app, 4 tab, màn reo, màn "chạm để bắt đầu"
  models/clock_theme.dart    chủ đề 12 hình, tính vị trí giờ/phút
  models/alarm.dart          dữ liệu báo thức
  services/app_state.dart    toàn bộ cài đặt, nhịp đồng hồ, báo giờ, báo thức, hẹn giờ
  services/sound_service.dart phát âm thanh
  widgets/dream_clock.dart   mặt đồng hồ hình ảnh (phần "hồn" của app)
  screens/...                các màn hình: Đồng hồ, Báo thức, Đếm giờ, Cài đặt
assets/sounds/               chuông, đánh giờ, báo thức (tự tạo, không lo bản quyền)
assets/themes/khung_long/    nơi đặt 12 ảnh khủng long
```
