import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(7, 'HD07_BaoThucHenGio_Tap7', 'Báo thức, hẹn giờ, bấm giờ')
d = json.load(open(f'{ROOT}/rec/t07_steps.json')); m = d['marks']
e.bg(f'{ROOT}/rec/t07_intro.mp4', 6)
e.rec('t07_intro', title='Báo thức, hẹn giờ, bấm giờ', caps=[(0, '3 trong 1')], voice='T7_1', vdelay=0.3,
      sounds=[(f'{SND}/alarm.wav', 3.2, 0.3)])
e.rec('t07_steps', chip='Đếm giờ › Báo thức', t1=m['s3'], voice='T7_2')
e.rec('t07_steps', chip='Đếm giờ › Báo thức', sub='Lời nhắc', t0=m['s3'], t1=m['s4'], voice='T7_3')
e.rec('t07_steps', chip='Đếm giờ › Hẹn giờ', t0=m['s4'], t1=m['s5'], voice='T7_4')
e.rec('t07_steps', chip='Đếm giờ › Bấm giờ', t0=m['s5'], t1=m['s6'], voice='T7_5')
e.rec('t07_steps', chip='Lưu ý', t0=m['s6'], voice='T7_6')
e.outro('Giờ thế giới, đếm ngược Tết', 'T7_7')
e.finish()
