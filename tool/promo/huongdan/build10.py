import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(10, 'HD10_LeHoi_Tap10', 'Đồng hồ thay áo theo lễ')
m = json.load(open(f'{ROOT}/rec/t10_steps.json'))['marks']
e.bg(f'{ROOT}/rec/t10_fest.mp4', 5)
e.rec('t10_fest', title='Đồng hồ thay áo theo lễ', voice='T10_1', vdelay=0.4)
CH = 'Cài đặt › Theme mùa & lễ hội'
e.rec('t10_steps', chip=CH, t1=m['s3'], voice='T10_2')
e.rec('t10_steps', chip=CH, sub='Xem trước một lễ', t0=m['s3'], t1=m['s4'], voice='T10_3')
e.rec('t10_steps', chip='Giáng sinh', t0=m['s4'], voice='T10_4')
e.outro('Bên trong đồng hồ cơ khí', 'T10_5')
e.finish()
