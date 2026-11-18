import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(5, 'HD05_12TamAnh_Tap5', 'Đưa 12 tấm ảnh vào đồng hồ')
d = json.load(open(f'{ROOT}/rec/t05_steps.json')); m = d['marks']
e.bg(f'{ROOT}/rec/t05_steps.mp4', m['s6'] - 2)
e.rec('t05_steps', title='Đưa 12 tấm ảnh vào đồng hồ', t0=m['s5'] + 3.0, t1=m['s6'], caps=[(0, 'Đồng hồ của riêng bạn')], voice='T3_1', notaps=True)
e.rec('t05_steps', chip='Cài đặt › Chủ đề hình ảnh', t1=m['s3'], voice='T3_2')
e.rec('t05_steps', chip='Cài đặt › Ảnh của tôi', t0=m['s3'], t1=m['s4'], voice='T3_3')
e.rec('t05_steps', chip='Kiểu, dáng & hệ từng hình', t0=m['s4'], t1=m['s5'], voice='T3_4')
e.rec('t05_steps', chip='Kết quả', t0=m['s5'], t1=m['s6'], voice='T3_5')
e.rec('t05_steps', chip='Cài đặt › Bộ cấu hình của tôi', t0=m['s6'], voice='T3_6')
e.outro('Ba chiếc đồng hồ trong một app', 'T3_7')
e.finish()
