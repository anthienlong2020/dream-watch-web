# Loạt video hướng dẫn Đồng hồ mộng mơ (Tập 2–11)

Dọc 1080×1920, 30 hình/giây. C tự quay app và tự ráp, L duyệt từng tập.

## Thư mục làm việc trên máy C: `/home/claude/hd`
- `src/giong/Voice_UserGuide/T*_*.mp3`: giọng đọc. Số trong tên file là số cũ, theo thứ tự trong tài liệu kịch bản.
- `src/HD_Flow_*.mp4`: video làm bằng Flow.
- `src/anhmau/`, `src/anh12/`: ảnh mẫu (12 ảnh cắt từ 4 ảnh AI).
- Tất cả lấy từ Drive `DongHoMongMo/4_HuongDan/1_NguyenLieu`.
- `rec/`: clip quay màn hình + file `.json` (chỗ chạm, chữ chỉ dẫn, mốc cảnh).
- `tapNN/`: từng tập đã ráp (`HDNN_..._TapNN.mp4`).
- App để quay lấy từ nhánh `web-build`, chạy bằng `python3 -m http.server 8091`.
- Trang movement chạy riêng ở cổng 8090 (`web/`).

## Công cụ
- `hrec.py`: quay app bằng Playwright, đồng hồ giả, chụp 15 hình/giây.
  - `tap()` ghi lại chỗ chạm để bộ ráp vẽ vòng vàng hiện trước 1 giây.
  - `tapt('chữ')` tìm nút theo chữ, nhờ cây "semantics" của Flutter (bật tự động).
  - Ngoài ra: `scroll()`, `drag()`, `type()`.
  - `cap()` đặt chữ chỉ dẫn; `mark()` đánh mốc chia cảnh.
  - Không xoá gì: mỗi lần quay tạo thư mục khung hình mới.
- `hbuild.py` (`Ep`): ráp từng tập.
  - `rec()`: clip trong khung điện thoại có nhãn trên, chữ dưới (58px) và vòng chạm. Cảnh tự kéo dài cho đủ lời đọc.
  - `full()`: clip Flow toàn màn hình.
  - `outro()`: QR + "Tìm hiểu thêm" + tập sau.
  - `finish()`: tích tắc chỉ 3 giây đầu, loudnorm −14.
  - Âm thanh thêm: `(file, giây, âm lượng[, độ dài])`.
- `drv.py`: trình duyệt mở sẵn để dò toạ độ.
  - Ra lệnh bằng `curl -G --data-urlencode "code=await sem()" localhost:9000/c`.
  - Lệnh có sẵn: `start/click/wheel/shot/pages/sem`.
- `recNN.py` / `buildNN.py`: kịch bản quay / ráp của từng tập (NN = số tập đăng).

## Thứ tự đăng ↔ giọng đọc
| Tập | Nội dung | Giọng |
|---|---|---|
| 2 | Giọng người thương | T5 |
| 3 | Ngày giỗ | T8 |
| 4 | Chibi 3D | T4 |
| 5 | 12 tấm ảnh | T3 |
| 6 | 3 đồng hồ | T2 |
| 7 | Báo thức | T7 |
| 8 | Giờ thế giới | T9 |
| 9 | Chuông | T6 |
| 10 | Lễ hội | T10 |
| 11 | Cơ khí | T11 |

## Bài học
- Dropdown của Flutter: menu đặt mục đang chọn ngay chỗ nút, nên toạ độ các mục thay đổi theo lựa chọn hiện tại. Nên tìm mục theo chữ.
- Chip ngày (T2…CN) rộng ra khi có dấu ✓. Bấm theo chữ, không bấm theo toạ độ cố định.
- Nút nằm sát thanh dưới: `find()` mặc định bỏ các nút có y > 570 để khỏi bấm nhầm tab.
- Chữ trên hình dùng font Inter, không có emoji, nên không đưa emoji vào chữ chỉ dẫn.
- Đồng hồ giả lùi trước 120 giây, vì máy bận thì tải trang lâu hơn.
- Câu "Sáu giờ rồi, dậy thôi con!" / "Mười giờ rồi…" / "Bây giờ là năm giờ chiều" là giọng piper (`vi_VN-vais1000-medium`). L gửi giọng thật thì thay vào.
