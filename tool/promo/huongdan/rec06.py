import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec

async def face(name, sec, **kw):
    r = Rec(name); await r.open(start='2026-11-18T10:09:40+07:00', **kw)
    r.start(); await r.wait(sec); await r.close()

async def steps():
    r = Rec('t06_steps'); await r.open(edition='standard', start='2026-11-18T10:09:40+07:00', tickOn=False)
    r.start(); await r.wait(7.0)
    r.mark('s3')
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.2)
    await r.scroll(260, 1.2)
    r.cap('Mục Phiên bản: bấm "Bật bản Pro (miễn phí)"'); await r.tapt('Bật bản Pro (miễn phí)', post=1.6)
    r.cap('Bấm "Bật Pro"'); await r.tapt('Bật Pro', post=2.5)
    r.mark('s4')
    for seg, lab in (('Mộng mơ', 'Mộng mơ: 12 hình ảnh, không kim'), ('Quả lắc', 'Quả lắc: dùng ảnh của bạn'), ('Cơ khí', 'Cơ khí: nhìn thấy bên trong')):
        r.cap(f'Mặt đồng hồ: chọn "{seg}"'); await r.tapt(seg, post=1.0)
        r.cap(lab); await r.tap(45, 607, post=3.2 if seg != 'Cơ khí' else 4.5)
        await r.tap(315, 607, post=1.0, ring=False)
    r.mark('s5')
    r.cap('Máy yếu? Bấm "Quay về bản Standard"'); await r.tapt('Quay về bản Standard', post=2.0)
    r.cap('Quay về Standard lúc nào cũng được'); await r.tap(45, 607, post=3.5)
    await r.close()

async def main(w):
    if w == 'faces':
        await face('t06_std', 4.0, edition='standard', tickOn=False)
        await face('t06_dream', 3.0)
        await face('t06_mech', 4.0, faceStyle='mech')
    else:
        await steps()
asyncio.run(main(sys.argv[1]))
