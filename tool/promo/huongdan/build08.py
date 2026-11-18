import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(8, 'HD08_GioTheGioi_Tap8', 'Giờ thế giới, đếm ngược Tết')
d = json.load(open(f'{ROOT}/rec/t08_steps.json')); m = d['marks']
FLOW = f'{ROOT}/src/HD_Flow_MeGoiCon.mp4'
e.bg(FLOW, 3)
e.full(FLOW, 0, 6.0, caption='Bên Mỹ giờ này mấy giờ?', title='Giờ thế giới, đếm ngược Tết', voice='T9_1', vdelay=0.5, ambient=0.3)
e.rec('t08_steps', chip='Lịch › Thế giới', t1=m['s3'], voice='T9_2')
e.rec('t08_steps', chip='Lịch › Thế giới', t0=m['s3'], t1=m['s4'], voice='T9_3')
e.rec('t08_steps', chip='Lịch › Thế giới', t0=m['s4'], t1=m['s5'], voice='T9_4')
e.rec('t08_steps', chip='Lịch › Ngày nhớ', sub='Đếm ngược trên mặt đồng hồ', t0=m['s5'], voice='T9_5')
e.outro('Các kiểu chuông báo giờ', 'T9_6')
e.finish()
