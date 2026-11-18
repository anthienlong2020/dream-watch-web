import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(9, 'HD09_ChuongBaoGio_Tap9', 'Các kiểu chuông báo giờ')
m = json.load(open(f'{ROOT}/rec/t09_steps.json'))['marks']
TTS = '/home/claude/tts/out'
e.bg(f'{ROOT}/rec/t09_intro.mp4', 3)
e.rec('t09_intro', title='Các kiểu chuông báo giờ', caps=[(0, 'Téng tèng teng tèng…')], sounds=[(f'{SND}/west_q4.mp3', 1.0, 0.8, 9.0)])
CH = 'Cài đặt › Âm báo mỗi giờ'
e.rec('t09_steps', chip=CH, t1=m['s2'], voice='T6_1')
e.rec('t09_steps', chip=CH, t0=m['s2'], t1=m['s2'] + 0.4, caps=[(m['s2'], 'Big Ben · Chuẩn · Coong coong')], voice='T6_2')
e.rec('t09_steps', chip=CH, sub='Nghe thử từng chuông', t0=m['s2'] + 0.4, t1=m['s3'],
      sounds=[(f'{SND}/west_q1.mp3', m['bb'] - m['s2'] - 0.4, 0.8, 4.2),
              (f'{SND}/strike_cao.mp3', m['cao'] - m['s2'] - 0.4, 0.8, 3.4),
              (f'{SND}/strike_big.mp3', m['big'] - m['s2'] - 0.4, 0.8, 3.4)])
e.rec('t09_steps', chip=CH, sub='Đọc giờ', t0=m['s3'], t1=m['s4'], voice='T6_3',
      sounds=[(f'{TTS}/bay5.wav', max(m['nu'] - m['s3'], 0.4 + vdur('T6_3') + 0.3), 1.0)], tail=2.2)
e.rec('t09_steps', chip=CH, sub='Tiếng tích tắc', t0=m['s4'], voice='T6_4',
      sounds=[(f'{ROOT}/src/ticks4.wav', m['tick'] - m['s4'] + 0.3, 0.35)])
e.outro('Đồng hồ thay áo theo lễ', 'T6_5')
e.finish(tick=False)
