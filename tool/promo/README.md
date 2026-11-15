# Quay clip quảng cáo (video viral)

Chạy trên máy Linux có Chrome + Playwright + ffmpeg. Thư mục làm việc: `/home/claude/promo`
(frames/, clips/, stills/, flow/, audio/).

- Trang movement: `cd web && python3 -m http.server 8090`
- App (nhánh `web-build`): `git archive FETCH_HEAD | tar -x -C /home/claude/appbuild`, rồi `python3 -m http.server 8091`

| Script | Clip |
|---|---|
| `m12.py` | M1 (0–3 s Tourbillon cận cảnh) + M2 (3–7 s lùi ra, mặt số hiện dần) |
| `m7.py` | M7: chạm tang cót → thẻ giải thích → tua ×720 |
| `m3.py` | M3: Standard, 16:59:54 → 17:00 |
| `m4.py` | M4: mặt Mộng mơ, hình phút nhảy lúc :00 |
| `m4b.py` | M4b: ảnh người AI → Chibi 3D trong app → mặt đồng hồ, Chibi bọc lửa |
| `m5.py` | M5: Tết / Trung Thu / Giáng sinh / Songkran |
| `m6.py` | M6: Cài đặt → ghi âm giọng báo giờ |
| `stills.py` | S2 khung điện thoại, S4 ảnh kết + QR, S5 ảnh bìa |
| `tts_vi.py` / piper | A1 "Sáu giờ rồi, dậy thôi!" (giọng `vi_VN-vais1000-medium`) |

Bài học quan trọng:
- Phải `clock.pause_at()` sau khi tải trang; nếu không, giờ giả vẫn trôi theo giờ thật và
  bánh răng nhảy cóc giữa các khung.
- Trang movement: chụp bằng CDP `Page.captureScreenshot` có `clip.scale = 3` (nhanh).
- App Flutter: chụp bằng `page.screenshot()` (scale device). Chụp kiểu `scale='css'` hoặc CDP có scale
  làm Flutter vẽ sai kích thước.
- Flutter khi đồng hồ bị dừng đôi lúc chờ một sự kiện chuột mới vẽ: sau mỗi cú chạm, rê chuột nhẹ (`settle()`).
- Font emoji: chặn fonts.gstatic.com và trả về NotoColorEmoji.ttf có sẵn trong máy (trong `recapp.py`).
- Thêm `--use-fake-ui-for-media-stream` để màn ghi âm chạy được.
