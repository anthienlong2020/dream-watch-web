import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(3, 'HD03_NgayGio_Tap3', 'Ngày giỗ, sinh nhật âm lịch')
m = json.load(open(f'{ROOT}/rec/t03_steps.json'))['marks']
FLOW = f'{ROOT}/src/HD_Flow_BanThoNgayGio.mp4'
e.bg(FLOW, 3)
e.full(FLOW, 0, 6.0, caption='Nhớ giùm bạn ngày giỗ', title='Ngày giỗ, sinh nhật âm lịch', voice='T8_1', vdelay=0.5, ambient=0.3)
e.rec('t03_intro', chip='Đến ngày, app tự nhắc', t0=3.6, t1=10.0, caps=[(3.6, ''), (5.2, 'Giỗ ông nội: còn 3 ngày')],
      sounds=[(f'{SND}/chime.wav', 1.4, 0.6)])
e.rec('t03_steps', chip='Tab Lịch', t1=m['s3'], voice='T8_2')
e.rec('t03_steps', chip='Lịch › Ngày nhớ › Thêm ngày', t0=m['s3'], t1=m['s4'], voice='T8_3')
e.rec('t03_steps', chip='Lịch › Ngày nhớ › Thêm ngày', t0=m['s4'], t1=m['s5'], voice='T8_4')
e.rec('t03_steps', chip='Nhắc mùng 1 & Rằm', t0=m['s5'], t1=m['s6'], voice='T8_5')
e.rec('t03_steps', chip='Tab Lịch', t0=m['s6'], voice='T8_6')
e.outro('Biến ảnh thành Chibi 3D', 'T8_7')
e.finish()
