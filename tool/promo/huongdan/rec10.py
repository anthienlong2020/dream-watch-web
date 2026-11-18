import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
FEST = [('tet', '20:09:50'), ('trungThu', '20:09:50'), ('giangSinh', '20:09:50'), ('songkran', '14:09:50')]

async def fests():
    for f, t in FEST:
        r = Rec(f't10_{f}'); await r.open(start=f'2026-11-18T{t}+07:00', seasonMode=f, showDate=False)
        r.start(); await r.wait(2.0); await r.close()

async def steps():
    r = Rec('t10_steps'); await r.open()
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.0)
    r.cap('Kéo xuống phần "Theme mùa & lễ hội"'); await r.scroll(560, 1.8)
    r.cap('Chọn "Tự động theo ngày"'); await r.tap(170, 196, post=1.0); await r.tapt('Tự động theo ngày', post=2.0)
    r.mark('s3')
    r.cap('Xem trước: chọn một lễ bất kỳ'); await r.tap(170, 196, post=1.0); await r.tapt('Valentine', post=1.2)
    r.cap('Valentine'); await r.tap(45, 607, post=3.0)
    await r.tap(315, 607, post=1.0, ring=False)
    r.cap('Thử thêm: Giáng sinh'); await r.tap(170, 196, post=1.0); await r.tapt('Giáng sinh', post=1.2)
    r.mark('s4')
    r.cap('Mỗi lễ có hình nền và hiệu ứng riêng'); await r.tap(45, 607, post=5.0)
    await r.close()

asyncio.run({'fests': fests, 'steps': steps}[sys.argv[1]]())
