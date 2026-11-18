import asyncio, sys, json
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
TET = {'id': 1, 'name': 'Tết Nguyên Đán', 'kind': 'le', 'lunar': True, 'day': 1, 'month': 1, 'remindBefore': -1, 'remindHour': 8, 'onClock': True}
GIO = {'id': 2, 'name': 'Giỗ ông nội', 'kind': 'gio', 'lunar': True, 'day': 13, 'month': 10, 'year': 2016, 'remindBefore': 3, 'remindHour': 7, 'onClock': False}

async def intro():
    r = Rec('t03_intro'); await r.open(start='2026-11-18T06:59:51.8+07:00', extra={'flutter.specialDays': json.dumps(json.dumps([TET, GIO]))})
    r.start(); await r.wait(11); await r.close()

async def steps():
    r = Rec('t03_steps'); await r.open(extra={'flutter.specialDays': json.dumps(json.dumps([TET]))})
    r.start(); await r.wait(0.5)
    r.cap('Vào tab Lịch'); await r.tap(225, 607, post=2.5)
    r.cap('Chạm một ngày để xem ngày âm, can chi, ngày lễ'); await r.tap(277, 369, post=1.0)
    await r.scroll(330, 2.0); await r.wait(2.5)
    r.mark('s3')
    await r.scroll(-330, 1.0)
    r.cap('Mở mục "Ngày nhớ"'); await r.tap(180, 28, post=1.2)
    r.cap('Bấm "Thêm ngày"'); await r.tap(275, 532, post=1.2)
    r.cap('Chọn loại: Ngày giỗ'); await r.tap(212, 207, post=0.8)
    r.cap('Gõ tên'); await r.tap(180, 297, post=0.5); await r.type('Giỗ ông nội', 0.13); await r.wait(0.6)
    r.cap('Chọn Âm lịch, rồi ngày và tháng'); await r.tap(98, 350, post=0.6)
    await r.tap(74, 398, post=0.9); await r.tap(78, 64, post=0.8)
    await r.tap(176, 398, post=0.9); await r.tap(180, 560, post=0.8)
    r.mark('s4')
    r.cap('Gõ năm mất (nếu nhớ)'); await r.tap(275, 398, post=0.4); await r.type('2015', 0.2); await r.wait(0.8)
    r.cap('Nhắc trước 3 ngày'); await r.tap(113, 496, post=0.9); await r.tap(117, 512, post=0.8)
    r.cap('Chọn giờ nhắc: 7 giờ sáng'); await r.tap(229, 496, post=0.9); await r.tap(233, 224, post=0.8)
    r.cap('Bấm "Lưu"'); await r.tap(308, 608, post=1.2)
    r.cap('App tự tính: giỗ lần thứ 11, còn bao nhiêu ngày'); await r.wait(2.8)
    r.mark('s5')
    r.cap('Bật "Nhắc mùng 1 & Rằm"'); await r.tap(290, 100, post=1.5)
    r.cap('Nhắc cả hôm trước'); await r.tap(284, 156, post=1.8)
    r.mark('s6')
    r.cap('Ngày giỗ hiện cả trên lịch'); await r.tap(96, 28, post=1.2)
    await r.tap(330, 80, post=0.9); await r.tap(330, 80, post=1.2)
    await r.tap(326, 253, post=1.0)
    await r.scroll(330, 2.0); await r.wait(3.0)
    await r.close()

if __name__ == '__main__':
    asyncio.run({'intro': intro, 'steps': steps}[sys.argv[1]]())
