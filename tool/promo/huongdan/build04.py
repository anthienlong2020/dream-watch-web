import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(4, 'HD04_Chibi3D_Tap4', 'Biến ảnh thành Chibi 3D')
d = json.load(open(f'{ROOT}/rec/t04_steps.json')); m = d['marks']
e.bg(f'{ROOT}/rec/t04_steps.mp4', 44)
e.rec('t04_steps', title='Biến ảnh thành Chibi 3D', t0=d['dur'] - 7.0, caps=[(0, 'Từ một tấm ảnh → Chibi 3D')], voice='T4_1', vdelay=0.4, notaps=True)
CH = 'Cài đặt › Ảnh của tôi'
e.rec('t04_steps', chip=CH, t1=m['s3'], voice='T4_2')
e.rec('t04_steps', chip='Tạo Chibi', sub='1. Khoanh khuôn mặt', t0=m['s3'], t1=m['s4'], voice='T4_3')
e.rec('t04_steps', chip='Tạo Chibi', sub='2. Trang phục', t0=m['s4'], t1=m['s5'], voice='T4_4')
e.rec('t04_steps', chip=CH, sub='Hệ: Lửa · Nước · Điện…', t0=m['s5'], t1=m['s6'], voice='T4_5')
e.rec('t04_steps', chip='Kết quả', t0=m['s6'], voice='T4_6', caps=[(m['s6'], 'Về mặt đồng hồ'), (m['s6'] + 2.0, 'Người thương thành Chibi trên đồng hồ')])
e.outro('Đưa 12 tấm ảnh vào đồng hồ', 'T4_7')
e.finish()
