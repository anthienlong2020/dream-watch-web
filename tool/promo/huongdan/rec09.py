import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec

async def intro():
    r = Rec('t09_intro'); await r.open(edition='standard', start='2026-11-18T16:59:56+07:00', tickOn=False)
    r.start(); await r.wait(10); await r.close()

async def steps():
    r = Rec('t09_steps'); await r.open(faceStyle='pendulum', tickOn=False)
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.0)
    r.cap('Kéo xuống phần Âm báo mỗi giờ'); await r.scroll(2970, 3.2)
    r.mark('s2')
    r.cap('Chuông Big Ben (Westminster)'); await r.tap(180, 360, post=0.9); await r.tap(184, 360, post=0.2); r.mark('bb'); await r.wait(4.0)
    r.cap('Chuông đánh giờ: Coong coong'); await r.tap(243, 416, post=0.9); await r.tap(247, 464, post=0.2); r.mark('cao'); await r.wait(3.5)
    r.cap('…hay Chuẩn: boong boong'); await r.tap(243, 416, post=0.9); await r.tap(247, 368, post=0.2); r.mark('big'); await r.wait(3.5)
    r.mark('s3')
    r.cap('Đọc giờ: giọng nam hoặc nữ'); await r.tap(184, 474, post=1.2); await r.tap(241, 474, post=0.3); r.mark('nu'); await r.wait(2.8)
    r.mark('s4')
    await r.scroll(760, 2.0)
    x, y = await r.find('Tiếng tích tắc')
    r.cap('Bật tiếng tích tắc của quả lắc'); await r.tap(305, y, post=0.3); r.mark('tick'); await r.wait(2.0)
    r.cap('Về đồng hồ: quả lắc đung đưa'); await r.tap(45, 607, post=0.3); await r.wait(4.0)
    await r.close()

asyncio.run({'intro': intro, 'steps': steps}[sys.argv[1]]())
