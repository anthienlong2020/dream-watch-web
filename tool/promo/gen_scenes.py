"""Extra scene clips for the rough cut: plain cold digital clock (D3), Ken Burns on stills."""
import os, subprocess, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

B = '/home/claude/promo/build'
W, H, FPS = 1080, 1920, 30


def plain_clock(dur=6.5):
    """'Một chiếc đồng hồ bình thường': số điện tử xám trên nền lạnh, màu nhạt dần."""
    out = f'{B}/plain_clock'
    os.makedirs(out, exist_ok=True)
    f_big = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-Light.otf', 230) \
        if os.path.exists('/usr/share/fonts/opentype/inter/Inter-Light.otf') else \
        ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-Regular.otf', 230)
    f_small = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-Regular.otf', 54)
    rng = np.random.default_rng(1)
    base_sec = 9 * 60 + 41  # 10:09:41
    n = int(dur * FPS)
    for i in range(n):
        t = i / FPS
        k = min(1.0, t / dur)
        # nền xanh xám lạnh, tối dần
        top = np.array([38, 44, 52]) * (1 - 0.35 * k)
        bot = np.array([16, 18, 22]) * (1 - 0.35 * k)
        g = np.linspace(0, 1, H)[:, None]
        bg = (top[None, None, :] * (1 - g[..., None]) + bot[None, None, :] * g[..., None])
        bg = np.repeat(bg, W, axis=1)
        bg += rng.normal(0, 3.0, (H, W, 1))  # nhiễu hạt nhẹ
        im = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8))
        d = ImageDraw.Draw(im)
        sec = base_sec + int(t)
        txt = f'10:{sec // 60 % 60:02d}'
        ss = f'{sec % 60:02d}'
        c = int(200 - 70 * k)
        col = (c, c + 4, c + 10)
        w = d.textlength(txt, font=f_big)
        d.text(((W - w) / 2 - 40, 700), txt, font=f_big, fill=col)
        d.text(((W + w) / 2 - 20, 860), ss, font=f_small, fill=(c - 40, c - 36, c - 30))
        d.text((W / 2 - d.textlength('THỨ HAI 16/11', font=f_small) / 2, 990), 'THỨ HAI 16/11',
               font=f_small, fill=(c - 60, c - 56, c - 50))
        im.save(f'{out}/{i:05d}.jpg', quality=90)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-i', f'{out}/%05d.jpg',
                    '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p',
                    f'{B}/plain_clock.mp4'], check=True)


def kenburns(src, out, dur, z0=1.0, z1=1.15, cx0=0.5, cy0=0.5, cx1=0.5, cy1=0.5):
    """Zoom chậm (Ken Burns) từ ảnh tĩnh, ra 1080x1920."""
    im = Image.open(src).convert('RGB')
    # phủ kín khung 9:16 rồi phóng gấp đôi để zoom mượt
    s = max(W / im.width, H / im.height) * 2
    big = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
    n = int(dur * FPS)
    tmp = out + '.frames'
    os.makedirs(tmp, exist_ok=True)
    for i in range(n):
        u = i / max(1, n - 1)
        u = u * u * (3 - 2 * u)
        z = z0 + (z1 - z0) * u
        cx = cx0 + (cx1 - cx0) * u
        cy = cy0 + (cy1 - cy0) * u
        cw, ch = 2 * W / z, 2 * H / z
        x = min(max(cx * big.width - cw / 2, 0), big.width - cw)
        y = min(max(cy * big.height - ch / 2, 0), big.height - ch)
        big.crop((int(x), int(y), int(x + cw), int(y + ch))).resize((W, H), Image.BILINEAR) \
            .save(f'{tmp}/{i:05d}.jpg', quality=90)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-i', f'{tmp}/%05d.jpg',
                    '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p', out], check=True)


if __name__ == '__main__':
    what = sys.argv[1:]
    if 'plain' in what:
        plain_clock(6.5)
    if 'kb' in what:
        F = '/home/claude/promo/flow'
        # S1b sau F1: chậm rãi đi vào con hẻm
        kenburns(f'{F}/S1b.png', f'{B}/kb_S1b.mp4', 4.6, 1.0, 1.12, 0.5, 0.55, 0.5, 0.45)
        # S1a cho D5: zoom vào đồng hồ cổ phát sáng giữa sạp
        kenburns(f'{F}/S1a.png', f'{B}/kb_S1a.mp4', 9.1, 1.0, 1.6, 0.5, 0.5, 0.69, 0.47)
        # S3 cô gái: 0,6 s trước khi thành Chibi
        kenburns(f'{F}/S3_co2.png', f'{B}/kb_S3.mp4', 0.7, 1.0, 1.05)
        # ảnh kết
        kenburns('/home/claude/promo/stills/S4_anh_ket.png', f'{B}/kb_S4.mp4', 13.2, 1.0, 1.05)
    print('ok')
