import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec

async def intro(name, start):
    r = Rec(name); await r.open(start=start, hourVoice='ghi', hourRecs=['chung', '6', '22'])
    r.start(); await r.wait(9.5); await r.close()

async def steps():
    r = Rec('t02_steps'); await r.open(start='2026-11-18T10:09:50+07:00')
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt'); await r.tap(315, 607, post=1.0)
    r.cap('Kéo xuống phần Âm báo mỗi giờ'); await r.scroll(2970, 3.5)
    r.cap('Đọc giờ: chọn "Tự ghi"'); await r.tapt('Tự ghi', post=1.6)
    r.mark('s3')
    await r.scroll(250, 1.0)
    x, y = await r.find('Ghi âm')
    r.cap('Bấm micro ở "Câu chung" rồi nói'); await r.tap(x, y, post=3.0)
    r.cap('Bấm nút đỏ để dừng'); await r.tapt('Dừng ghi', post=1.2)
    r.cap('Bấm "Nghe lại"'); await r.tapt('Nghe lại', post=2.0)
    r.mark('s4')
    r.cap('Mở "Câu riêng từng giờ"'); await r.tapt('Câu riêng từng giờ', post=1.2)
    await r.scroll(200, 1.0)
    hx, hy = await r.find('Câu riêng từng giờ')
    y6 = hy + 44 + 6 * 40
    r.cap('6 giờ sáng: gọi dậy'); await r.tap(320, y6, post=2.2); await r.tapt('Dừng ghi', post=1.2)
    await r.scroll(600, 1.8)
    r.cap('10 giờ tối: nhắc đi ngủ'); await r.tap(320, y6 + 16 * 40 - 600, post=2.2); await r.tapt('Dừng ghi', post=1.2)
    await r.shot('/tmp/end02.png')
    await r.wait(1.0)
    await r.close()

if __name__ == '__main__':
    w = sys.argv[1]
    if w == 'intro': asyncio.run(intro('t02_intro', '2026-11-18T05:59:51.8+07:00'))
    if w == 'end': asyncio.run(intro('t02_end', '2026-11-18T21:59:51.8+07:00'))
    if w == 'steps': asyncio.run(steps())
