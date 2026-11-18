# Đồng hồ mộng mơ (dream-watch-web)

App đồng hồ hình ảnh viết bằng Flutter web. Bản chạy: https://anthienlong2020.github.io/dream-watch-web/

- Làm ở nhánh `dev`; GitHub Actions kiểm tra + build; gộp sang `main` thì tự đưa lên GitHub Pages.
- Kế hoạch & danh sách tính năng chi tiết: tài liệu `ke_hoach_dream_watch.md` trong project "A dream watch!".
- Công cụ quay video quảng bá/hướng dẫn: `tool/promo/` (xem `tool/promo/README.md`).

## Tiết kiệm pin / CPU
- Mặt Quả lắc, Mộng mơ, Cổ điển: `lib/widgets/clock_frame.dart` – vẽ 60 hình/giây khi cắm sạc, ~12 hình/giây khi chạy pin (`dwBattery` trong `web/index.html`).
- Mặt Cơ khí 3D (`web/movement/index.html`, nhúng iframe): vẽ **30 hình/giây** bình thường, 60 khi đang xoay/chạm hoặc tua nhanh, **12** khi trang cha báo chạy pin; độ nét tối đa 1,5× và tối đa ~1,2 triệu điểm ảnh/hình (`fitPixelRatio`). Không vẽ khi mặt này bị ẩn.
  - **Chế độ nhẹ** (`LOW`): tự bật khi Chrome vẽ bằng CPU (SwiftShader/llvmpipe/"Basic Render" – máy không dùng được card đồ hoạ); hoặc bật tay ở ⚙ Tùy chọn → "🪶 Chế độ nhẹ". Nhẹ = không khử răng cưa, bỏ lớp bóng clearcoat, ~0,45 triệu điểm ảnh, 15 hình/giây (30 khi tương tác). Ép bằng `localStorage.mvQuality = 'high' | 'low'` hoặc `?low` / `?high`. Script quay video (`tool/promo`) luôn đặt `high`.
  - **Khi chạy pin** (`dwBattery` của app, hoặc `navigator.getBattery` khi mở trang riêng): tự sang chế độ nhẹ (bỏ clearcoat, ~0,45 triệu điểm ảnh – `applyLite`, kiểm tra mỗi 2 giây), **không tự xoay**, hiện thẻ "🔋 Mặt Cơ khí tốn pin hơn – nên cắm sạc" 7 giây (`#batt`). Cắm sạc lại thì trở về như cũ. Không giảm xuống 1–2 hình/giây vì quả lắc phải đung đưa mượt (L chốt 18/11).
- Công tắc "Giữ màn hình luôn sáng" + "Chỉ giữ sáng khi đang cắm sạc" (Wake Lock, `dwWake`).

## Lịch sử thay đổi
- 18/11/2026: giảm tải mặt Cơ khí (30 fps, pixel ratio 1,5, 12 fps khi chạy pin).
- 18/11/2026 (2): mặt Cơ khí – chế độ nhẹ tự bật khi máy vẽ bằng CPU + nút bật tay; giới hạn số điểm ảnh khi cửa sổ lớn.
- 18/11/2026 (3): mặt Cơ khí khi chạy pin – tự chế độ nhẹ, ngừng tự xoay, nhắc cắm sạc.
- 18/11/2026 (4): sửa lỗi công tắc "Nhắc mùng 1 & Rằm" (Lịch › Ngày nhớ) bấm không đổi cho tới khi chuyển tab.
- 18/11/2026 (5): Cài đặt › Kiểu, dáng & hệ – 12 vị trí gập vào mục "Chỉnh riêng từng giờ" (mặc định đóng, có đếm số hình đã chỉnh riêng); tiếng tích tắc mặc định **tắt** cho người cài mới (ai đã chọn thì giữ nguyên).
- 17/11/2026: chế độ đỡ hao pin, công tắc giữ sáng khi sạc; hướng dẫn cài trên Safari máy Mac.
- 16/11/2026: nút "Cài app", icon mới, giữ màn hình sáng; Lịch / Ngày nhớ / Giờ thế giới; gộp Đếm giờ.
