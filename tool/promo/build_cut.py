"""Dựng bản thô video viral: cảnh + lời đọc D0–D15 của L + âm thanh + phụ đề tiếng Việt."""
import json, os, re, subprocess, sys
import numpy as np

P = '/home/claude/promo'
B = f'{P}/build'
V = f'{P}/voice_L'
C = f'{P}/clips'
SND = '/home/claude/dream-watch-web/assets/sounds'
SR = 44100
FPS = 30

# ---------------------------------------------------------------- phụ đề
# Câu hiển thị (số viết bằng chữ số cho dễ đọc). Mỗi phần tử ≈ một cụm hiện trên màn hình.
TEXT = {
    'D0': ['Bạn đã bao giờ nhìn thấy thời gian chạy chưa?'],
    'D1': ['Thời gian là nhà vô địch đúng nghĩa:', 'nó thắng cả tiền bạc,', 'danh vọng, sắc đẹp,',
           'thậm chí cả tình yêu.'],
    'D2': ['Và nó cho bạn miễn phí', 'một lần duy nhất!'],
    'D3': ['Nhưng nhìn nó trên một chiếc đồng hồ bình thường,', 'mình chỉ thấy lạnh lẽo và chán ngắt.'],
    'D4': ['Có người từng hỏi:', 'nếu có những giấc mơ để bán,', 'những câu chuyện vui buồn để kể,',
           'rồi người bán hàng rung chuông mời mọc,', 'bạn sẽ chọn cái nào?'],
    'D5': ['Mình chọn những giấc mơ.', 'Vì chúng cho mình sức mạnh', 'để đối mặt với sự vĩnh hằng của thời gian',
           'bằng sự hữu hạn của đời người.'],
    'D6': ['Thế là mình làm ra', 'một chiếc đồng hồ không có kim.', 'Thay vào đó là 12 hình ảnh của chính bạn:',
           'con mèo nhà bạn, nụ cười của con,', 'người thương, idol, một chuyến đi,', 'một giấc mơ còn dang dở…'],
    'D7': ['Mỗi giờ,', 'một hình ảnh xoay vòng giữa mặt đồng hồ.', 'Mỗi 5 phút,',
           'hình phút nhảy bậc thang sang ô mới.'],
    'D8': ['Biến ảnh thành tượng 3D, pha lê, siêu nhân,', 'hay bọc lửa, nước, sấm sét.'],
    'D9': ['Gần 30 lễ hội tự đổi theo ngày:', 'Tết có pháo nổ tí tách,', 'Noel có tuần lộc kéo xe bay qua,',
           'Songkran bóng nước vỡ tung…'],
    'D10': ['Tiếng chuông "téng tèng teng tèng"', 'như đồng hồ quả lắc nhà ông bà,', 'kèm giọng đọc báo giờ.'],
    'D11': ['Hoặc để giọng người thương', 'gọi bạn dậy mỗi sáng.'],
    'A1': ['"6 giờ rồi, dậy thôi!"'],
    'TTS5': ['"Bây giờ là 5 giờ chiều."'],
    'D12': ['Kèm báo thức,', 'hẹn giờ, bấm giờ.'],
    'D13': ['Và một bộ máy trong suốt,', 'để bạn nhìn thấy thời gian chạy.'],
}

AUDIO_FILES = {f'D{i}': f'{V}/D{i}.mp3' for i in range(16)}
AUDIO_FILES.update({'A1': f'{P}/audio/A1_v2_giong_A_tre.mp3', 'TTS5': f'{B}/tts_5h.wav'})


def load(path):
    """Giải mã ra mảng float32 mono 44,1 kHz."""
    raw = subprocess.run(['ffmpeg', '-loglevel', 'error', '-i', path, '-f', 'f32le', '-ac', '1', '-ar', str(SR), '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


def speech_segments(path):
    out = subprocess.run(['ffmpeg', '-i', path, '-af', 'silencedetect=noise=-40dB:d=0.25', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r'silence_start: ([0-9.]+)', out)]
    ends = [float(x) for x in re.findall(r'silence_end: ([0-9.]+)', out)]
    dur = len(load(path)) / SR
    segs, cur = [], 0.0
    for s, e in zip(starts, ends + [dur] * (len(starts) - len(ends))):
        if s - cur > 0.05:
            segs.append((cur, s))
        cur = e
    if dur - cur > 0.15:
        segs.append((cur, dur))
    return segs, dur


def syllables(t):
    return max(1, len(t.split()))


def align(phrases, segs):
    """Gán từng cụm chữ vào thời gian nói: bằng số đoạn → khớp từng đoạn; khác → chia theo số tiếng,
    rồi bám ranh giới vào chỗ ngắt hơi gần nhất."""
    if len(phrases) == len(segs):
        return [(a, b) for a, b in segs]
    speech = sum(b - a for a, b in segs)
    tot = sum(syllables(p) for p in phrases)

    def at(x):  # thời điểm khi đã nói được x giây "tiếng"
        for a, b in segs:
            if x <= b - a:
                return a + x
            x -= b - a
        return segs[-1][1]
    gaps = [(segs[i][1], segs[i + 1][0]) for i in range(len(segs) - 1)]
    bounds, acc = [segs[0][0]], 0
    for p in phrases[:-1]:
        acc += syllables(p)
        t = at(speech * acc / tot)
        for g0, g1 in gaps:
            if abs(t - g0) < 0.45 or abs(t - g1) < 0.45 or g0 <= t <= g1:
                t = (g0 + g1) / 2
                break
        bounds.append(t)
    bounds.append(segs[-1][1])
    return list(zip(bounds[:-1], bounds[1:]))


# ---------------------------------------------------------------- cảnh
# Mỗi cảnh: thời lượng, phần hình, các âm thanh (khoá, giây bắt đầu trong cảnh, âm lượng),
# phụ đề (khoá lời đọc) hoặc chú thích tự do.
def scenes():
    return [
        dict(name='00_qua_lac', dur=4.0, parts=[(f'{C}/M0.mp4', 0, 4.0)],
             voice=[('D0', 0.25)], hook=True, bed='tick'),
        dict(name='01_tourbillon', dur=7.7, parts=[(f'{C}/M12.mp4', 0, 7.0)],
             voice=[('D1', 0.0)], bed='tourb'),
        dict(name='02_tua_nhanh', dur=3.4, parts=[(f'{C}/M7.mp4', 3.4, 2.6, 3.4)], voice=[('D2', 0.0)]),
        dict(name='03_dong_ho_lanh', dur=6.5, parts=[(f'{B}/plain_clock.mp4', 0, 6.5)], voice=[('D3', 0.0)],
             bed='tick_dull'),
        dict(name='04_cho_giac_mo', dur=10.6, parts=[(f'{P}/flow/F1_cho_giac_mo.mp4', 0, 6.0),
                                                     (f'{B}/kb_S1b.mp4', 0, 4.6)],
             voice=[('D4', 0.0)], extra=[(f'{P}/flow/F1_cho_giac_mo.mp4', 0.0, 0.5)]),
        dict(name='05_chon_giac_mo', dur=9.1, parts=[(f'{B}/kb_S1a.mp4', 0, 9.1)], voice=[('D5', 0.0)]),
        dict(name='06_mong_mo', dur=14.2, parts=[(f'{C}/M4L.mp4', 0.2, 14.2)], voice=[('D6', 0.0)]),
        dict(name='07_mong_mo_nhanh', dur=7.9, parts=[(f'{C}/M4F.mp4', 0, 7.9)], voice=[('D7', 0.0)]),
        dict(name='08_chibi', dur=6.3, parts=[(f'{B}/kb_S3.mp4', 0, 0.6), (f'{C}/M4b.mp4', 0, 2.75),
                                             (f'{C}/M4b.mp4', 3.6, 2.95)],
             voice=[('D8', 0.0)], extra=[(f'{SND}/strike.wav', 0.55, 0.25)]),
        dict(name='09_le_hoi', dur=9.6, parts=[(f'{C}/M5L_{f}.mp4', 0, 2.4)
                                               for f in ('tet', 'trungThu', 'giangSinh', 'songkran')],
             voice=[('D9', 0.0)]),
        dict(name='10_standard_chuong', dur=14.6, parts=[(f'{C}/M3X.mp4', 0, 14.6)],
             voice=[('D10', 0.0), ('TTS5', 12.4)], bed='tick_std',
             extra=[(f'{B}/west_last.wav', 6.6, 0.8), (f'{SND}/strike_big.mp3', 11.7, 0.6)]),
        dict(name='11_goi_day', dur=5.8, parts=[(f'{P}/flow/F2_phong_ngu.mp4', 0, 5.8)], inset=(f'{C}/M6.mp4', 0.4),
             voice=[('D11', 0.0), ('A1', 3.9)], extra=[(f'{P}/flow/F2_phong_ngu.mp4', 0.0, 0.35)]),
        dict(name='12_dem_gio', dur=5.0, parts=[(f'{C}/M8.mp4', 0, 5.0)], voice=[('D12', 0.3)]),
        dict(name='13_lich', dur=5.4, parts=[(f'{C}/M9.mp4', 0, 5.4)], voice=[],
             captions=[(0.2, 2.0, 'Lịch âm – dương'), (2.0, 3.6, 'Ngày nhớ: sinh nhật, ngày giỗ…'),
                       (3.6, 5.3, 'Giờ thế giới')]),
        dict(name='14_co_khi', dur=5.0, parts=[(f'{C}/M7.mp4', 0, 5.0)], voice=[('D13', 0.2)], bed='tourb_fast'),
        dict(name='15_ket', dur=13.2, parts=[(f'{B}/kb_S4.mp4', 0, 13.2)], voice=[('D14', 0.3), ('D15', 4.4)],
             nosub=True, extra=[(f'{SND}/strike_big.mp3', 0.0, 0.35)]),
    ]


def run(cmd):
    subprocess.run(cmd, check=True)


def make_scene(sc, out):
    """Ghép các phần hình của cảnh thành clip 1080x1920@30, đúng thời lượng (thiếu thì giữ khung cuối)."""
    inputs, chains = [], []
    for i, part in enumerate(sc['parts']):
        f, ss, ln = part[:3]
        target = part[3] if len(part) > 3 else ln
        inputs += ['-ss', f'{ss}', '-t', f'{ln}', '-i', f]
        chains.append(f'[{i}:v]setpts=(PTS-STARTPTS)*{target / ln:.4f},fps={FPS},'
                      f'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1[v{i}]')
    n = len(sc['parts'])
    fc = ';'.join(chains) + ';' + ''.join(f'[v{i}]' for i in range(n)) + f'concat=n={n}:v=1:a=0[cat]'
    last = 'cat'
    if 'inset' in sc:
        f, t0 = sc['inset']
        inputs += ['-i', f]
        # màn hình ghi âm thu nhỏ ở góc trên phải, có viền sáng
        fc += (f';[{n}:v]setpts=PTS-STARTPTS+{t0}/TB,scale=380:-2,pad=iw+12:ih+12:6:6:color=0xF2E6C8[ins];'
               f'[cat][ins]overlay=x=W-w-40:y=280:enable=\'gte(t,{t0})\'[ov]')
        last = 'ov'
    fc += f';[{last}]tpad=stop_mode=clone:stop_duration=30,trim=duration={sc["dur"]},setpts=PTS-STARTPTS[out]'
    run(['ffmpeg', '-y', '-loglevel', 'error', *inputs, '-filter_complex', fc, '-map', '[out]', '-r', str(FPS),
         '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p', out])


def ticks(kind, dur):
    """Tiếng tích tắc nền."""
    tick, tock = load(f'{SND}/tick.mp3'), load(f'{SND}/tock.mp3')
    buf = np.zeros(int(dur * SR) + SR, np.float32)
    if kind in ('tick', 'tick_dull', 'tick_std'):
        vol = {'tick': 0.55, 'tick_dull': 0.3, 'tick_std': 0.45}[kind]
        for k in range(int(dur)):
            s = tick if k % 2 == 0 else tock
            i = int((k + 0.15) * SR)
            buf[i:i + len(s)] += s * vol
    elif kind in ('tourb', 'tourb_fast'):
        # lách tách nhanh của Tourbillon (6 nhịp/giây), nhẹ
        rate = 6 if kind == 'tourb' else 10
        for k in range(int(dur * rate)):
            s = tick if k % 2 == 0 else tock
            i = int((k / rate + 0.05) * SR)
            buf[i:i + len(s)] += s * 0.22
    return buf[:int(dur * SR)]


def ass_time(t):
    h, t = divmod(t, 3600)
    m, s = divmod(t, 60)
    return f'{int(h)}:{int(m):02d}:{s:05.2f}'


ASS_HEAD = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Sub,Inter,60,&H00FFFFFF,&H00FFFFFF,&H8C000000,&H00000000,-1,0,0,0,100,100,0,0,3,16,0,2,90,90,430,1
Style: Hook,Inter,82,&H00FFFFFF,&H00FFFFFF,&H00100A06,&H96000000,-1,0,0,0,100,100,0,0,1,6,3,8,80,80,300,1
Style: Cap,Inter,62,&H0060D6FF,&H00FFFFFF,&H8C000000,&H00000000,-1,0,0,0,100,100,0,0,3,16,0,2,90,90,430,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def main(scs=None, tag=''):
    SD = f'{B}/scenes{tag}'
    os.makedirs(SD, exist_ok=True)
    scs = scs or scenes()
    only = set(sys.argv[1:]) if not tag else set()
    t = 0.0
    total = sum(s['dur'] for s in scs)
    mix = np.zeros(int((total + 1) * SR), np.float32)
    events, srt = [], []
    for sc in scs:
        out = f'{SD}/{sc["name"]}.mp4'
        if not only or sc['name'] in only or not os.path.exists(out):
            make_scene(sc, out)
        if 'bed' in sc:
            b = ticks(sc['bed'], sc['dur'])
            mix[int(t * SR):int(t * SR) + len(b)] += b
        for f, at, vol in sc.get('extra', []):
            a = load(f) * vol
            a = a[:int((sc['dur'] - at) * SR)]
            i = int((t + at) * SR)
            mix[i:i + len(a)] += a
        for key, at in sc['voice']:
            a = load(AUDIO_FILES[key])
            i = int((t + at) * SR)
            mix[i:i + len(a)] += a * 1.0
            if sc.get('nosub'):
                continue
            segs, _ = speech_segments(AUDIO_FILES[key])
            for (a0, a1), txt in zip(align(TEXT[key], segs), TEXT[key]):
                st, en = t + at + a0, t + at + a1 + 0.15
                style = 'Hook' if sc.get('hook') else 'Sub'
                if key in ('A1', 'TTS5'):
                    txt = '{\\i1}' + txt + '{\\i0}'
                events.append((st, en, style, txt))
        for c0, c1, txt in sc.get('captions', []):
            events.append((t + c0, t + c1, 'Cap', txt))
        t += sc['dur']
    # chống chồng chéo: cụm sau bắt đầu thì cụm trước tắt
    events.sort()
    for k in range(len(events) - 1):
        if events[k][2] == events[k + 1][2] and events[k][1] > events[k + 1][0]:
            events[k] = (events[k][0], events[k + 1][0] - 0.02, events[k][2], events[k][3])
    with open(f'{B}/phu_de{tag}.ass', 'w') as f:
        f.write(ASS_HEAD)
        for st, en, style, txt in events:
            f.write(f'Dialogue: 0,{ass_time(st)},{ass_time(en)},{style},,0,0,0,,{txt}\n')
    with open(f'{P}/build/phu_de{tag}.srt', 'w') as f:
        for k, (st, en, style, txt) in enumerate(events, 1):
            def s(x):
                ms = int(round(x * 1000))
                return f'{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}'
            f.write(f'{k}\n{s(st)} --> {s(en)}\n{re.sub(r"{[^}]*}", "", txt)}\n\n')
    # âm thanh: chống vỡ tiếng, fade cuối
    peak = np.abs(mix).max()
    if peak > 0.98:
        mix *= 0.98 / peak
    fade = int(1.2 * SR)
    end = int(total * SR)
    mix = mix[:end]
    mix[-fade:] *= np.linspace(1, 0, fade)
    mix.astype(np.float32).tofile(f'{B}/mix{tag}.f32')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', f'{B}/mix{tag}.f32',
         '-af', 'loudnorm=I=-14:TP=-1.5', '-ar', str(SR), '-ac', '2', f'{B}/mix{tag}.wav'])
    with open(f'{B}/scenes{tag}.txt', 'w') as f:
        for sc in scs:
            f.write(f"file 'scenes{tag}/{sc['name']}.mp4'\n")
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', f'{B}/scenes{tag}.txt',
         '-c', 'copy', f'{B}/video_noaudio{tag}.mp4'])
    # bản không phụ đề + bản có phụ đề
    run(['ffmpeg', '-y', '-loglevel', 'error', '-i', f'{B}/video_noaudio{tag}.mp4', '-i', f'{B}/mix{tag}.wav',
         '-vf', 'fade=t=out:st=%.2f:d=1.0' % (total - 1.0), '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20',
         '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k', '-shortest', f'{P}/dong_ho_mong_mo_ban_tho{tag}_khong_phu_de.mp4'])
    run(['ffmpeg', '-y', '-loglevel', 'error', '-i', f'{P}/dong_ho_mong_mo_ban_tho{tag}_khong_phu_de.mp4',
         '-vf', f'ass={B}/phu_de{tag}.ass', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20', '-pix_fmt', 'yuv420p',
         '-c:a', 'copy', f'{P}/dong_ho_mong_mo_ban_tho{tag}.mp4'])
    print('total', round(total, 1), 's')


if __name__ == '__main__':
    main()
