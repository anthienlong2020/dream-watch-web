# Đồng hồ mộng mơ (dream-watch-web)

App đồng hồ hình ảnh viết bằng Flutter web. Bản chạy: https://anthienlong2020.github.io/dream-watch-web/

- Làm ở nhánh `dev`; GitHub Actions kiểm tra + build; gộp sang `main` thì tự đưa lên GitHub Pages.
- Kế hoạch & danh sách tính năng chi tiết: tài liệu `ke_hoach_dream_watch.md` trong project "A dream watch!".
- Công cụ quay video quảng bá/hướng dẫn: `tool/promo/` (xem `tool/promo/README.md`).

## Tiết kiệm pin / CPU
- Mặt Quả lắc, Mộng mơ, Cổ điển: `lib/widgets/clock_frame.dart` – vẽ 60 hình/giây khi cắm sạc, ~12 hình/giây khi chạy pin (`dwBattery` trong `web/index.html`).
- Mặt Cơ khí 3D (`web/movement/index.html`, nhúng iframe): vẽ **30 hình/giây** bình thường, 60 khi đang xoay/chạm hoặc tua nhanh, **12** khi trang cha báo chạy pin; độ nét tối đa 1,5× (`setPixelRatio`). Không vẽ khi mặt này bị ẩn.
- Công tắc "Giữ màn hình luôn sáng" + "Chỉ giữ sáng khi đang cắm sạc" (Wake Lock, `dwWake`).

## Lịch sử thay đổi
- 18/11/2026: giảm tải mặt Cơ khí (30 fps, pixel ratio 1,5, 12 fps khi chạy pin).
- 17/11/2026: chế độ đỡ hao pin, công tắc giữ sáng khi sạc; hướng dẫn cài trên Safari máy Mac.
- 16/11/2026: nút "Cài app", icon mới, giữ màn hình sáng; Lịch / Ngày nhớ / Giờ thế giới; gộp Đếm giờ.
