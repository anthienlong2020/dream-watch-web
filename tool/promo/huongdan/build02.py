import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
TTS = '/home/claude/tts/out'
e = Ep(2, 'HD02_GiongNguoiThuong_Tap2', 'Giọng người thương báo giờ')
m = json.load(open(f'{ROOT}/rec/t02_steps.json'))['marks']
e.bg(f'{ROOT}/rec/t02_intro.mp4', 6)
e.rec('t02_intro', title='Giọng người thương báo giờ', caps=[(0, 'Giọng mẹ gọi dậy mỗi sáng')], voice='T5_1', vdelay=0.3,
      sounds=[(f'{SND}/strike_big.mp3', 5.0, 0.7), (f'{TTS}/me6.wav', 6.3, 1.0)])
CH = 'Cài đặt › Âm báo mỗi giờ'
e.rec('t02_steps', chip=CH, t1=m['s3'], voice='T5_2')
e.rec('t02_steps', chip=CH, sub='Câu chung cho mọi giờ', t0=m['s3'], t1=m['s4'], voice='T5_3')
e.rec('t02_steps', chip=CH, sub='Câu riêng từng giờ', t0=m['s4'], voice='T5_4')
e.rec('t02_end', chip='Đến giờ', caps=[(0, 'Đồng hồ nói bằng chính giọng đã ghi')], voice='T5_5', vdelay=0.3,
      sounds=[(f'{SND}/strike_big.mp3', 5.0, 0.7), (f'{TTS}/me22.wav', 6.3, 1.0)])
e.outro('Ngày giỗ, sinh nhật âm lịch', 'T5_6')
e.finish()
