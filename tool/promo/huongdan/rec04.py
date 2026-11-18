import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
PHOTO = '/home/claude/hd/src/anhmau/T3_be.jpg'

async def main():
    r = Rec('t04_steps'); await r.open(start='2026-11-18T13:07:30+07:00', effectsOn=True)
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.0)
    r.cap('Kéo xuống phần "Ảnh của tôi"'); await r.scroll(1140, 3.0)
    x, y = await r.find('Chọn nhiều ảnh')
    r.cap('Chạm vào một ô, ví dụ ô I'); await r.tap(51, y - 119, post=1.2)
    r.cap('Chọn "Tạo Chibi từ ảnh người"'); await r.tapt('Tạo Chibi từ ảnh người', post=1.8, maxy=630)
    r.mark('s3')
    got = {}
    async def on_fc(fc):
        await fc.set_files(PHOTO); got['ok'] = 1
    r.pg.on('filechooser', on_fc)
    r.cap('Bấm "Chọn ảnh người", chọn ảnh trong máy'); await r.tapt('Chọn ảnh người', post=2.5)
    if not got: print('FILECHOOSER?')
    r.cap('Kéo thanh phóng to cho mặt vừa vòng tròn')
    await r.drag(80, 404, 140, 404, sec=1.5, post=0.8)
    await r.drag(180, 240, 160, 300, sec=1.5, post=1.2)
    r.mark('s4')
    await r.scroll(440, 1.5)
    vx, vy = await r.find('Váy')
    r.cap('Vuốt ngang để xoay xem mọi góc'); await r.drag(110, vy - 165, 260, vy - 165, sec=1.6, post=1.0)
    r.cap('Chọn trang phục'); await r.tapt('Váy', post=1.8)
    r.mark('s5')
    r.cap('Bấm "Dùng Chibi này"'); await r.tapt('Dùng Chibi này', post=1.8, maxy=630)
    await r.scroll(360, 1.2)
    r.cap('Mở "Chỉnh riêng từng giờ"'); await r.tapt('Chỉnh riêng từng giờ', post=1.2)
    await r.scroll(150, 1.0)
    r.cap('Chọn hệ cho ô I: Lửa, Nước, Điện…'); await r.tapt('Hệ: mặc định', post=1.4)
    await r.tapt('Lửa', post=1.2)
    r.mark('s6')
    r.cap('Về mặt đồng hồ'); await r.tap(45, 607, post=1.0)
    r.cap(''); await r.wait(6.0)
    await r.close()

asyncio.run(main())
