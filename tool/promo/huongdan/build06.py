import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(6, 'HD06_BaDongHo_Tap6', '3 chiếc đồng hồ trong 1 app')
d = json.load(open(f'{ROOT}/rec/t06_steps.json')); m = d['marks']
e.bg(f'{ROOT}/rec/t06_faces.mp4', 8)
e.rec('t06_faces', title='3 chiếc đồng hồ trong 1 app', voice='T2_1', vdelay=0.4)
e.rec('t06_steps', chip='Bản Standard (mặc định)', t1=m['s3'], caps=[(0, 'Standard: nhẹ máy, có chuông Big Ben')], voice='T2_2')
e.rec('t06_steps', chip='Cài đặt › Phiên bản', t0=m['s3'], t1=m['s4'], voice='T2_3')
e.rec('t06_steps', chip='Bản Pro: 3 mặt đồng hồ', t0=m['s4'], t1=m['s5'], voice='T2_4')
e.rec('t06_steps', chip='Cài đặt › Phiên bản', t0=m['s5'], voice='T2_5')
e.outro('Báo thức, hẹn giờ, bấm giờ', 'T2_6')
e.finish()
