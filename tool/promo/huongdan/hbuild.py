"""Bộ ráp chung cho loạt video hướng dẫn Đồng hồ mộng mơ (dọc 1080x1920, 30 fps).
Phát triển từ build_tap01.py: clip màn hình đặt trong khung bo góc + nền mờ, nhãn trên, chữ chỉ dẫn to (58px)
phía dưới, vòng tròn vàng hiện ~1 giây trước chỗ chạm, thẻ mở đầu/kết để lâu, tích tắc chỉ 3 giây đầu.

Mỗi cảnh = Seg(video, dur, sounds=[(file, giây, âm lượng)]). Cảnh tự kéo dài (giữ khung cuối) cho đủ lời đọc.
"""
import os, subprocess, json
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import qrcode

ROOT = '/home/claude/hd'
VOICE = f'{ROOT}/src/giong/Voice_UserGuide'
SND = '/home/claude/dream-watch-web/assets/sounds'
ICON = '/home/claude/dream-watch-web/web/icons/Icon-512.png'
W, H, FPS = 1080, 1920, 30
APP_LINK = 'https://anthienlong2020.github.io/dream-watch-web/'
F = '/usr/share/fonts/opentype/inter/Inter-'
EMOJI = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf'
PH = (200, 250, 680)            # khung điện thoại: x, y, rộng
GOLD, CREAM, LILAC, INK = (240, 200, 120, 255), (255, 240, 210, 255), (210, 200, 240, 255), (20, 16, 40, 225)


def font(w, s): return ImageFont.truetype(f'{F}{w}.otf', s)


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: print(r.stderr[-3000:]); raise SystemExit(1)


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f],
                                capture_output=True, text=True).stdout)


def vdur(name): return dur(f'{VOICE}/{name}.mp3')


class Seg:
    def __init__(self, video, sounds=()):
        self.video, self.sounds = video, list(sounds)
        self.dur = dur(video)


# ---------- chữ ----------
def wrap(d, text, f, maxw):
    out = []
    for para in text.split('\n'):
        words, cur = para.split(), ''
        for w in words:
            t = (cur + ' ' + w).strip()
            if d.textlength(t, font=f) <= maxw: cur = t
            else: out.append(cur); cur = w
        out.append(cur)
    return out


def ctext(d, y, text, f, fill=CREAM, maxw=W - 140, lh=None, x0=0, w=W):
    lines = wrap(d, text, f, maxw); lh = lh or int(f.size * 1.3)
    for i, l in enumerate(lines):
        tw = d.textlength(l, font=f); d.text((x0 + (w - tw) // 2, y + i * lh), l, font=f, fill=fill)
    return y + lh * len(lines)


def caption_png(text, path, y_center=1745):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    f = font('Bold', 58); lines = wrap(d, text, f, W - 160)
    lh = 74; h = lh * len(lines) + 44; y0 = y_center - h // 2
    wmax = max(d.textlength(l, font=f) for l in lines) + 80
    d.rounded_rectangle(((W - wmax) // 2, y0, (W + wmax) // 2, y0 + h), 34, fill=INK, outline=GOLD, width=3)
    for i, l in enumerate(lines):
        tw = d.textlength(l, font=f); d.text(((W - tw) // 2, y0 + 22 + i * lh), l, font=f, fill=CREAM)
    im.save(path)


def chip_png(text, path, sub=None):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    f = font('Bold', 46); tw = d.textlength(text, font=f)
    d.rounded_rectangle(((W - tw) // 2 - 40, 70, (W + tw) // 2 + 40, 150), 40, fill=(240, 200, 120, 240))
    d.text(((W - tw) // 2, 82), text, font=f, fill=(30, 22, 50, 255))
    if sub:
        fs = font('SemiBold', 34); sw = d.textlength(sub, font=fs)
        d.rounded_rectangle(((W - sw) // 2 - 26, 166, (W + sw) // 2 + 26, 220), 27, fill=(20, 16, 40, 210))
        d.text(((W - sw) // 2, 172), sub, font=fs, fill=(255, 230, 180, 255))
    im.save(path)


def title_png(ep, title, path):
    """Dải tiêu đề cho cảnh mở đầu (thay nhãn nhỏ): TẬP N + tên tập."""
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    f1, f2 = font('Bold', 44), font('Black', 66)
    lines = wrap(d, title, f2, W - 140)
    h = 92 + 80 * len(lines)
    d.rounded_rectangle((50, 18, W - 50, 18 + h + 10), 40, fill=(20, 16, 40, 215), outline=GOLD, width=3)
    t = f'TẬP {ep}'; tw = d.textlength(t, font=f1)
    d.rounded_rectangle(((W - tw) // 2 - 30, 34, (W + tw) // 2 + 30, 92), 29, fill=GOLD)
    d.text(((W - tw) // 2, 38), t, font=f1, fill=(30, 22, 50, 255))
    for i, l in enumerate(lines):
        tw = d.textlength(l, font=f2); d.text(((W - tw) // 2, 100 + i * 80), l, font=f2, fill=CREAM)
    im.save(path)


def ring_pngs(out):
    paths = []
    for k, r in enumerate((34, 50, 66)):
        s = 160; im = Image.new('RGBA', (s, s), (0, 0, 0, 0)); d = ImageDraw.Draw(im); c = s // 2
        d.ellipse((c - r, c - r, c + r, c + r), outline=(255, 215, 90, 255 - k * 60), width=9)
        d.ellipse((c - 14, c - 14, c + 14, c + 14), fill=(255, 215, 90, 200))
        im = im.filter(ImageFilter.GaussianBlur(0.6))
        p = f'{out}/ring{k}.png'; im.save(p); paths.append(p)
    return paths


def mask_png(w, h, rad, path):
    im = Image.new('L', (w, h), 0); ImageDraw.Draw(im).rounded_rectangle((0, 0, w - 1, h - 1), rad, fill=255); im.save(path)


class Ep:
    def __init__(self, ep, code, title):
        self.ep, self.code, self.title = ep, code, title
        self.out = f'{ROOT}/tap{ep:02d}'; os.makedirs(self.out, exist_ok=True)
        self.segs = []
        self.n = 0

    def _name(self, s):
        self.n += 1; return f'{self.n:02d}_{s}'

    # ---------- clip quay màn hình đặt trong khung điện thoại ----------
    def rec(self, rec, chip=None, sub=None, voice=None, vdelay=0.4, speed=1.0, t0=0.0, t1=None, caps=None,
            box=PH, crop=None, title=None, sounds=(), tail=0.8, blurs=(), extra_taps=(), notaps=False, minlen=0):
        """rec: tên clip trong rec/ (có .json). caps: [(t, chữ)] ghi đè chữ từ json. voice: 'T5_2' hoặc [('T5_2', giây)]."""
        src = f'{ROOT}/rec/{rec}.mp4'; meta = json.load(open(f'{ROOT}/rec/{rec}.json'))
        t1 = meta['dur'] if t1 is None else t1
        name = self._name(rec); O = self.out
        cw, ch, cx, cy = crop or (1080, 1920, 0, 0)
        bx, by, bw = box; bh = int(round(bw * ch / cw / 2)) * 2
        mask = f'{O}/{name}_mask.png'; mask_png(bw, bh, 36 if bw < 800 else 22, mask)
        top = f'{O}/{name}_top.png'
        if title: title_png(self.ep, title, top)
        else: chip_png(chip or '', top, sub)
        rings = ring_pngs(O)
        caps = caps if caps is not None else meta['caps']
        caps = [c for c in caps if c[0] < t1]
        cap_items = []
        for i, (a, txt) in enumerate(caps):
            b = caps[i + 1][0] if i + 1 < len(caps) else 1e9
            if not txt: continue
            p = f'{O}/{name}_cap{i}.png'; caption_png(txt, p)
            cap_items.append((max(0, (a - t0) / speed), (min(b, 1e9) - t0) / speed if b < 1e9 else 1e9, p))
        D = (t1 - t0) / speed
        vs = voice if isinstance(voice, list) else ([(voice, vdelay)] if voice else [])
        need = max([o + vdur(v) + tail for v, o in vs] + [D, minlen])
        ins = ['-i', src, '-loop', '1', '-i', mask, '-loop', '1', '-i', top] + sum([['-loop', '1', '-i', r] for r in rings], [])
        for _, _, p in cap_items: ins += ['-loop', '1', '-i', p]
        f = []; cur = '[0:v]'
        for k, (x, y, w, h) in enumerate(blurs):   # toạ độ CSS 360x640
            x, y, w, h = [int(v * 3) for v in (x, y, w, h)]
            f.append(f'{cur}split=2[bz{k}a][bz{k}b];[bz{k}b]crop={w}:{h}:{x}:{y},gblur=sigma=14[bz{k}c];[bz{k}a][bz{k}c]overlay={x}:{y}[bz{k}]')
            cur = f'[bz{k}]'
        pad = need - D
        f.append(f'{cur}trim={t0}:{t1},setpts=(PTS-STARTPTS)/{speed},fps={FPS},tpad=stop_mode=clone:stop_duration={pad + 0.1:.3f},split=2[c1][c2]')
        f.append(f'[c1]scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},gblur=sigma=40,eq=brightness=-0.28:saturation=0.8[bg]')
        f.append(f'[c2]crop={cw}:{ch}:{cx}:{cy},scale={bw}:{bh}:flags=lanczos,format=rgba[fg0];[1:v]scale={bw}:{bh},format=gray[m];[fg0][m]alphamerge[fg]')
        f.append(f'[bg][fg]overlay={bx}:{by}:shortest=1[v0];[v0][2:v]overlay=0:0:shortest=1[v1]')
        cur = '[v1]'; n = 1
        for j, (a, b, p) in enumerate(cap_items):
            idx = 3 + len(rings) + j
            b = need + 1 if b > 1e8 else b
            n += 1; f.append(f"{cur}[{idx}:v]overlay=0:0:shortest=1:enable='between(t,{a:.3f},{b:.3f})'[v{n}]"); cur = f'[v{n}]'
        taps = [] if notaps else [t for t in meta['taps'] if t0 <= t[0] <= t1]
        for (tt, x, y) in list(taps) + list(extra_taps):
            to = (tt - t0) / speed
            px = bx + (x * 3 - cx) / cw * bw; py = by + (y * 3 - cy) / ch * bh
            for k in range(3):
                a = to - 1.0 + k * 0.3; b = a + 0.8 if k < 2 else to + 0.5
                n += 1; f.append(f"{cur}[{3 + k}:v]overlay={px - 80:.0f}:{py - 80:.0f}:shortest=1:enable='between(t,{a:.3f},{b:.3f})'[v{n}]"); cur = f'[v{n}]'
        f.append(f'{cur}format=yuv420p[out]')
        out = f'{O}/{name}.mp4'
        run(['ffmpeg', '-y', '-v', 'error', *ins, '-filter_complex', ';'.join(f), '-map', '[out]', '-t', f'{need:.3f}', '-r', str(FPS),
             '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '19', out])
        snd = [(f'{VOICE}/{v}.mp3', o, 1.0) for v, o in vs] + list(sounds)
        s = Seg(out, snd); self.segs.append(s); print(name, f'{s.dur:.2f}s'); return s

    # ---------- clip toàn màn hình (Flow) ----------
    def full(self, src, t0, t1, caption=None, title=None, voice=None, vdelay=0.4, sounds=(), tail=0.8, speed=1.0, ambient=0.0):
        name = self._name(os.path.basename(src)[:-4]); O = self.out
        D = (t1 - t0) / speed
        vs = voice if isinstance(voice, list) else ([(voice, vdelay)] if voice else [])
        need = max([o + vdur(v) + tail for v, o in vs] + [D])
        ins = ['-i', src]; f = [f'[0:v]trim={t0}:{t1},setpts=(PTS-STARTPTS)/{speed},fps={FPS},scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},tpad=stop_mode=clone:stop_duration={need - D + 0.1:.3f}[v0]']
        cur = '[v0]'; k = 1
        if title:
            p = f'{O}/{name}_title.png'; title_png(self.ep, title, p); ins += ['-loop', '1', '-i', p]
            f.append(f'{cur}[{k}:v]overlay=0:0:shortest=1[v{k}]'); cur = f'[v{k}]'; k += 1
        if caption:
            p = f'{O}/{name}_cap.png'; caption_png(caption, p); ins += ['-loop', '1', '-i', p]
            f.append(f'{cur}[{k}:v]overlay=0:0:shortest=1[v{k}]'); cur = f'[v{k}]'; k += 1
        f.append(f'{cur}format=yuv420p[out]')
        out = f'{O}/{name}.mp4'
        run(['ffmpeg', '-y', '-v', 'error', *ins, '-filter_complex', ';'.join(f), '-map', '[out]', '-t', f'{need:.3f}', '-r', str(FPS),
             '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '19', out])
        snd = [(f'{VOICE}/{v}.mp3', o, 1.0) for v, o in vs] + list(sounds)
        if ambient:
            a = f'{O}/{name}_amb.wav'
            run(['ffmpeg', '-y', '-v', 'error', '-ss', str(t0), '-t', f'{t1 - t0:.3f}', '-i', src, '-vn', '-ac', '2', '-ar', '48000', a])
            snd.append((a, 0.0, ambient))
        s = Seg(out, snd); self.segs.append(s); print(name, f'{s.dur:.2f}s'); return s

    # ---------- thẻ chữ ----------
    def bg(self, frame_src, t=1.0):
        p = f'{self.out}/bg.png'
        run(['ffmpeg', '-y', '-v', 'error', '-ss', str(t), '-i', frame_src, '-frames:v', '1', '/tmp/bgsrc.png'])
        im = Image.open('/tmp/bgsrc.png').convert('RGB')
        s = max(W / im.width, H / im.height); im = im.resize((int(im.width * s) + 1, int(im.height * s) + 1))
        im = im.crop(((im.width - W) // 2, (im.height - H) // 2, (im.width - W) // 2 + W, (im.height - H) // 2 + H))
        im = im.filter(ImageFilter.GaussianBlur(28))
        im = Image.blend(im, Image.new('RGB', (W, H), (14, 10, 30)), 0.55); im.save(p)

    def card(self, key, D, draw, voice=None, vdelay=0.5, sounds=(), tail=1.0):
        name = self._name(key)
        im = Image.open(f'{self.out}/bg.png').convert('RGBA'); draw(im, ImageDraw.Draw(im))
        p = f'{self.out}/{name}.png'; im.convert('RGB').save(p)
        vs = voice if isinstance(voice, list) else ([(voice, vdelay)] if voice else [])
        D = max([D] + [o + vdur(v) + tail for v, o in vs])
        out = f'{self.out}/{name}.mp4'
        run(['ffmpeg', '-y', '-v', 'error', '-loop', '1', '-i', p, '-vf',
             f"zoompan=z='1+0.04*on/({D}*{FPS})':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},format=yuv420p",
             '-t', f'{D:.3f}', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '19', out])
        s = Seg(out, [(f'{VOICE}/{v}.mp3', o, 1.0) for v, o in vs] + list(sounds)); self.segs.append(s)
        print(name, f'{s.dur:.2f}s'); return s

    def outro(self, next_title, voice, question=None):
        def draw(im, d):
            qr = qrcode.QRCode(border=2, box_size=12); qr.add_data(APP_LINK); qr.make(fit=True)
            q = qr.make_image(fill_color=(25, 18, 45), back_color=(255, 248, 235)).convert('RGBA').resize((520, 520), Image.NEAREST)
            d.rounded_rectangle(((W - 580) // 2, 330, (W + 580) // 2, 910), 36, fill=(255, 248, 235, 255))
            im.alpha_composite(q, ((W - 520) // 2, 360))
            ic = Image.open(ICON).convert('RGBA').resize((110, 110)); im.alpha_composite(ic, ((W - 110) // 2, 565))
            ctext(d, 960, 'Quét mã để mở app', font('Bold', 60))
            ctext(d, 1050, 'hoặc bấm nút "Tìm hiểu thêm" trên trang', font('Medium', 42), LILAC)
            if next_title:
                nl = len(wrap(d, next_title, font('Bold', 58), W - 240))
                d.rounded_rectangle((110, 1250, W - 110, 1250 + 110 + 75 * nl), 36, fill=INK, outline=GOLD, width=3)
                ctext(d, 1290, 'TẬP SAU', font('Bold', 46), GOLD)
                ctext(d, 1360, next_title, font('Bold', 58), maxw=W - 240)
            if question:
                nl = len(wrap(d, question, font('Bold', 56), W - 260))
                d.rounded_rectangle((110, 1250, W - 110, 1250 + 80 + 73 * nl), 36, fill=INK, outline=GOLD, width=3)
                ctext(d, 1290, question, font('Bold', 56), maxw=W - 260)
        return self.card('outro', 9.0, draw, voice=voice)

    # ---------- ráp + tiếng ----------
    def finish(self, tick=True, tick_vol=0.10):
        O = self.out
        with open(f'{O}/list.txt', 'w') as fl:
            for s in self.segs: fl.write(f"file '{s.video}'\n")
        run(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', f'{O}/list.txt', '-c', 'copy', f'{O}/video.mp4'])
        total = dur(f'{O}/video.mp4')
        events, t = [], 0.0
        for s in self.segs:
            for ev in s.sounds: events.append((ev[0], t + ev[1], ev[2], ev[3] if len(ev) > 3 else None))
            t += s.dur
        ins, f = [], []
        for i, (fp, tt, vol, ln) in enumerate(events):
            ms = int(max(0, tt) * 1000)
            cut = f'atrim=0:{ln},afade=t=out:st={max(0, ln - 1.2):.2f}:d=1.2,' if ln else ''
            ins += ['-i', fp]; f.append(f'[{i}:a]aresample=48000,aformat=channel_layouts=stereo,{cut}adelay={ms}|{ms},volume={vol}[a{i}]')
        n = len(events); mix = ''.join(f'[a{i}]' for i in range(n)); k = n
        if tick:   # chỉ ~3 giây đầu rồi tắt dần (TikTok nhận nhầm nhạc bản quyền nếu để suốt)
            ins += ['-i', f'{SND}/tick.mp3', '-i', f'{SND}/tock.mp3']
            f.append(f'[{n}:a]aresample=48000,aformat=channel_layouts=stereo,apad=whole_dur=1,atrim=0:1[t1];[{n + 1}:a]aresample=48000,aformat=channel_layouts=stereo,apad=whole_dur=1,atrim=0:1[t2];'
                     f'[t1][t2]concat=n=2:v=0:a=1,aloop=loop=-1:size=96000,atrim=0:3,afade=t=out:st=2:d=1,volume={tick_vol}[bed]')
            mix += '[bed]'; k += 1
        f.append(f'{mix}amix=inputs={k}:normalize=0:duration=longest,apad=whole_dur={total:.2f},atrim=0:{total:.2f},loudnorm=I=-14:TP=-1.5[aout]')
        run(['ffmpeg', '-y', '-v', 'error', *ins, '-filter_complex', ';'.join(f), '-map', '[aout]', '-ar', '48000', '-ac', '2', f'{O}/mix.wav'])
        final = f'{O}/{self.code}.mp4'
        run(['ffmpeg', '-y', '-v', 'error', '-i', f'{O}/video.mp4', '-i', f'{O}/mix.wav', '-map', '0:v', '-map', '1:a', '-c:v', 'copy',
             '-c:a', 'aac', '-b:a', '160k', '-shortest', '-movflags', '+faststart', final])
        starts, t = [], 0
        for s in self.segs: starts.append((os.path.basename(s.video), round(t, 1))); t += s.dur
        print(json.dumps(starts, ensure_ascii=False))
        print('XONG', final, f'{dur(final):.1f}s', f'{os.path.getsize(final) / 1e6:.1f} MB', flush=True)
        return final


def contact(video, out, n=12, cols=6):
    """Ảnh xem nhanh: n khung đều nhau."""
    D = dur(video); ims = []
    for i in range(n):
        t = D * (i + 0.5) / n
        subprocess.run(['ffmpeg', '-y', '-v', 'error', '-ss', f'{t:.2f}', '-i', video, '-frames:v', '1', '/tmp/_c.png'])
        im = Image.open('/tmp/_c.png').resize((180, 320)); d = ImageDraw.Draw(im); d.text((4, 4), f'{t:.1f}', fill='yellow'); ims.append(im)
    rows = (n + cols - 1) // cols
    o = Image.new('RGB', (cols * 182, rows * 322), 'red')
    for i, im in enumerate(ims): o.paste(im, ((i % cols) * 182, (i // cols) * 322))
    o.save(out); return out
