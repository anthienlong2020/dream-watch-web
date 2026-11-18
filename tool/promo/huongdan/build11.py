import sys, json; sys.path.insert(0, '/home/claude/hd/tools')
from hbuild import *
e = Ep(11, 'HD11_CoKhi_Tap11', 'Bên trong đồng hồ cơ khí')
m = json.load(open(f'{ROOT}/rec/t11_steps.json'))['marks']
M12 = '/home/claude/promo/clips/M12.mp4'
e.bg(M12, 6)
e.full(M12, 0, 7.0, caption='Nhìn bên trong thời gian', title='Bên trong đồng hồ cơ khí', voice='T11_1', vdelay=0.4)
e.rec('t11_steps', chip='Bản Pro › mặt Cơ khí', t1=m['s3'], voice='T11_2')
e.rec('t11_parts', chip='Chạm để xem tên bộ phận', voice='T11_3')
e.rec('t11_steps', chip='Tùy chọn › Bộ thoát', t0=m['s4'], t1=m['s5'], voice='T11_4')
e.rec('t11_steps', chip='Tùy chọn', t0=m['s5'], t1=m['s6'], voice='T11_5')
e.rec('t11_steps', chip='Tua nhanh ×720', t0=m['s6'], voice='T11_6')
e.outro(None, 'T11_7', question='Bạn muốn đưa giấc mơ nào lên đồng hồ? Bình luận cho mình biết nhé!')
e.finish()
