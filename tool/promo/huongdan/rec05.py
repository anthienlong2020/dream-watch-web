import asyncio, sys, datetime as dt
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
IMGS = [f'/home/claude/hd/src/anh12/{i}.jpg' for i in range(1, 13)]

async def main():
    r = Rec('t05_steps'); await r.open(start='2026-11-18T10:57:40+07:00', effectsOn=True)
    async def on_fc(fc):
        await fc.set_files(r.files)
    r.pg.on('filechooser', on_fc)
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.0)
    r.cap('Kéo xuống phần "Chủ đề hình ảnh"'); await r.scroll(990, 2.6)
    x, y = await r.find('Chuẩn (Standard)')
    r.cap('Chọn "Ảnh của tôi"'); await r.tap(180, y - 25, post=1.2); await r.tapt('Ảnh của tôi', post=1.5)
    r.mark('s3')
    gx, gy = await r.find('Chọn nhiều ảnh')
    r.files = IMGS[0]
    r.cap('12 ô = 12 giờ. Chạm một ô, chọn ảnh'); await r.tap(51, gy - 119, post=1.2); await r.tapt('Chọn ảnh', post=2.5)
    r.files = IMGS[1:]
    r.cap('Hoặc bấm "Chọn nhiều ảnh" để điền nhanh'); await r.tapt('Chọn nhiều ảnh', post=3.0)
    r.mark('s4')
    await r.scroll(440, 1.6)
    d0x, d0y = await r.find('3D thổi phồng')
    r.cap('Chọn kiểu cho cả bộ: ảnh phẳng'); await r.tap(226, d0y, post=1.0); await r.tapt('Standard (phẳng)', post=1.2)
    await r.scroll(130, 0.8)
    r.cap('Hoặc từng ô một kiểu riêng: Chibi 3D'); await r.tap(226, d0y + 224 - 130, post=1.0); await r.tapt('Chibi 3D', post=1.4)
    r.mark('s5')
    now = await r.pg.evaluate('Date.now()')
    target = dt.datetime.fromisoformat('2026-11-18T10:59:53+07:00').timestamp() * 1000
    if target > now: await r.idle((target - now) / 1000)
    r.cap('Về mặt đồng hồ'); await r.tap(45, 607, post=1.0)
    r.cap('Ảnh của giờ đó xoay chậm giữa mặt đồng hồ'); await r.wait(9.0)
    r.mark('s6')
    r.cap('Lưu cả bộ ảnh thành 1 file'); await r.tap(315, 607, post=1.0)
    await r.scroll(-3000, 2.0)
    await r.scroll(330, 1.0)
    r.cap('Bấm "Lưu thành file" để gửi tặng người thân'); await r.tapt('Lưu thành file', post=2.0)
    await r.tapt('Lưu', post=2.5)
    await r.shot('/tmp/end05.png')
    await r.close()

asyncio.run(main())
