import asyncio, sys, json
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec
TET = {'id': 1, 'name': 'Tết Nguyên Đán', 'kind': 'le', 'lunar': True, 'day': 1, 'month': 1, 'remindBefore': -1, 'remindHour': 8, 'onClock': False}

async def main():
    r = Rec('t08_steps'); await r.open(extra={'flutter.specialDays': json.dumps(json.dumps([TET]))})
    r.start(); await r.wait(0.5)
    r.cap('Vào tab Lịch › Thế giới'); await r.tap(225, 607, post=1.0); await r.tap(264, 28, post=2.5)
    r.cap('Bấm "Thêm thành phố"'); await r.tap(259, 532, post=1.2)
    r.cap('Chọn nơi người thân đang sống'); await r.scroll(1850, 3.0, y=450)
    await r.tapt('Houston', post=2.0)
    r.mark('s3')
    await r.scroll(700, 1.5)
    r.cap('Ngày hay đêm, nhanh chậm mấy giờ – tự tính, không cần mạng')
    await r.wait(1.0)
    r.taps.append([round(r.t, 3), 300, 395])   # chỉ vào dòng Houston
    await r.wait(4.0)
    r.mark('s4')
    r.cap('Vuốt sang trái để bỏ thành phố'); await r.drag(320, 130, 30, 130, sec=0.8, post=1.8)
    r.mark('s5')
    r.cap('Đếm ngược tới Tết: mở Ngày nhớ'); await r.tap(180, 28, post=1.0)
    r.cap('Chạm "Tết Nguyên Đán"'); await r.tap(180, 180, post=1.2)
    r.cap('Bật "Đếm ngược trên mặt đồng hồ"'); await r.tap(296, 552, post=1.0)
    r.cap('Bấm "Lưu"'); await r.tap(308, 608, post=1.2)
    r.cap('Con số hiện ngay dưới mặt đồng hồ'); await r.tap(45, 607, post=1.0)
    r.taps.append([round(r.t + 1.0, 3), 180, 548])
    await r.wait(5.0)
    await r.close()
asyncio.run(main())
