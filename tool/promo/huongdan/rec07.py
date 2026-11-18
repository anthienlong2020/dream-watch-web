import asyncio, sys, json
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
A1 = {'id': 1, 'hour': 6, 'minute': 0, 'label': 'Dậy thôi!', 'days': [1, 2, 3, 4, 5], 'enabled': True, 'sound': 'alarm', 'speak': False, 'hasVoice': False}

async def intro():
    r = Rec('t07_intro'); await r.open(start='2026-11-19T05:59:53.8+07:00', extra={'flutter.alarms': json.dumps(json.dumps([A1]))})
    r.start(); await r.wait(10); await r.close()

async def pick_time(r, hx, hy, mx, my):
    await r.tap(180, 153, post=1.0)
    await r.tap(hx, hy, post=0.9); await r.tap(mx, my, post=0.9)
    await r.tap(292, 528, post=1.0)

async def steps():
    r = Rec('t07_steps'); await r.open()
    r.start(); await r.wait(0.5)
    r.cap('Vào tab Đếm giờ › Báo thức'); await r.tap(135, 607, post=1.2)
    r.cap('Bấm "Thêm"'); await r.tap(292, 532, post=1.2)
    r.cap('Chạm vào giờ để chọn: 6 giờ 00'); await pick_time(r, 180, 469, 180, 269)
    r.cap('Chọn ngày lặp lại: Thứ Hai → Thứ Sáu')
    for d in ('T2', 'T3', 'T4', 'T5', 'T6'): await r.tapt(d, pre=0.6, post=0.4)
    r.cap('Đặt tên báo thức'); await r.tap(180, 351, post=0.4); await r.type('Dậy thôi!', 0.14); await r.wait(0.6)
    r.cap('Bấm "Lưu"'); await r.tap(304, 604, post=1.8)
    r.mark('s3')
    r.cap('Làm lời nhắc: uống thuốc, đón con…'); await r.tap(292, 532, post=1.2)
    await pick_time(r, 107, 369, 180, 469)
    await r.tap(180, 351, post=0.4); await r.type('Uống thuốc cho mẹ', 0.12); await r.wait(0.6)
    await r.tap(304, 604, post=2.2)
    r.mark('s4')
    r.cap('Hẹn giờ: chọn nhanh 5 phút'); await r.tap(180, 28, post=1.0); await r.tap(262, 461, post=1.0)
    r.cap('Bấm "Bắt đầu"'); await r.tapt('Bắt đầu', post=4.0)
    r.mark('s5')
    r.cap('Bấm giờ: bấm "Bắt đầu"'); await r.tap(261, 28, post=1.0); await r.tapt('Bắt đầu', post=2.0)
    r.cap('Bấm "Vòng" để ghi từng lượt'); await r.tapt('Vòng', post=1.6); await r.tapt('Vòng', post=1.6)
    await r.shot('/tmp/sw.png')
    r.mark('s6')
    r.cap('Lưu ý: bản web chỉ reo khi app đang mở'); await r.tap(99, 28, post=4.5)
    await r.close()

asyncio.run({'intro': intro, 'steps': steps}[sys.argv[1]]())
