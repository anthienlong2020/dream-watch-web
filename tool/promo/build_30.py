"""Bản 30 giây: câu hỏi mở đầu → chợ giấc mơ → mặt Mộng mơ → Chibi → lễ hội → ảnh kết."""
import subprocess, sys
sys.path.insert(0, '/home/claude/promo/scripts')
import build_cut as bc

V, B, C, P, SND = bc.V, bc.B, bc.C, bc.P, bc.SND
T = f'{B}/v30'


def cut(name, pieces):
    """Cắt (và nối) các đoạn lời đọc: pieces = [(file, từ giây, đến giây)], thêm 0,15 s nghỉ giữa các đoạn."""
    import os
    os.makedirs(T, exist_ok=True)
    inputs, fc = [], []
    for i, (f, a, b) in enumerate(pieces):
        inputs += ['-ss', str(a), '-t', str(b - a), '-i', f]
        fc.append(f'[{i}:a]aresample=44100,aformat=channel_layouts=mono,afade=t=out:st={b - a - 0.06:.2f}:d=0.06,'
                  f'apad=pad_dur=0.15[a{i}]')
    fc = ';'.join(fc) + ';' + ''.join(f'[a{i}]' for i in range(len(pieces))) + \
        f'concat=n={len(pieces)}:v=0:a=1[out]'
    out = f'{T}/{name}.wav'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', *inputs, '-filter_complex', fc, '-map', '[out]', out],
                   check=True)
    bc.AUDIO_FILES[name] = out
    return out


cut('H_ban', [(f'{V}/D4.mp3', 1.40, 3.45), (f'{V}/D4.mp3', 8.38, 9.80)])
cut('H_chon', [(f'{V}/D5.mp3', 0.0, 1.55)])
cut('H_12', [(f'{V}/D6.mp3', 0.0, 6.25)])
cut('H_chibi', [(f'{V}/D8.mp3', 0.0, 5.50)])
cut('H_lehoi', [(f'{V}/D9.mp3', 0.0, 2.40)])
cut('H_ket', [(f'{V}/D14.mp3', 0.0, 3.10)])
bc.TEXT.update({
    'H_ban': ['Nếu có những giấc mơ để bán,', 'bạn sẽ chọn cái nào?'],
    'H_chon': ['Mình chọn những giấc mơ.'],
    'H_12': ['Thế là mình làm ra một chiếc đồng hồ không có kim.', 'Thay vào đó là 12 hình ảnh của chính bạn.'],
    'H_chibi': bc.TEXT['D8'],
    'H_lehoi': ['Gần 30 lễ hội tự đổi theo ngày'],
})

SCENES = [
    dict(name='a_qua_lac', dur=4.0, parts=[(f'{C}/M0.mp4', 0, 4.0)], voice=[('D0', 0.25)], hook=True, bed='tick'),
    dict(name='b_cho', dur=4.2, parts=[(f'{P}/flow/F1_cho_giac_mo.mp4', 0.8, 4.2)], voice=[('H_ban', 0.15)],
         extra=[(f'{P}/flow/F1_cho_giac_mo.mp4', 0.0, 0.45)]),
    dict(name='c_chon', dur=2.0, parts=[(f'{B}/kb_S1a.mp4', 5.0, 2.0)], voice=[('H_chon', 0.1)]),
    dict(name='d_mong_mo', dur=6.6, parts=[(f'{C}/M4L.mp4', 6.0, 6.6)], voice=[('H_12', 0.1)]),
    dict(name='e_chibi', dur=6.1, parts=[(f'{B}/kb_S3.mp4', 0, 0.5), (f'{C}/M4b.mp4', 0, 2.75),
                                         (f'{C}/M4b.mp4', 3.6, 2.85)],
         voice=[('H_chibi', 0.05)], extra=[(f'{SND}/strike.wav', 0.45, 0.25)]),
    dict(name='f_le_hoi', dur=2.8, parts=[(f'{C}/M5L_{f}.mp4', 0.3, 0.7)
                                          for f in ('tet', 'trungThu', 'giangSinh', 'songkran')],
         voice=[('H_lehoi', 0.1)]),
    dict(name='g_ket', dur=4.6, parts=[(f'{B}/kb_S4.mp4', 0, 4.6)], voice=[('H_ket', 0.2)], nosub=True,
         extra=[(f'{SND}/strike_big.mp3', 0.0, 0.35)]),
]

if __name__ == '__main__':
    bc.main(SCENES, '_30s')
