"""Biểu tượng app: nền đêm tím, vòng đồng hồ vàng với 12 chấm màu (12 hình ảnh), trăng khuyết giữa."""
import math
from PIL import Image, ImageDraw, ImageFilter
OUT = '/home/claude/dream-watch-web/web'
S = 1024

def draw(maskable):
    im = Image.new('RGBA', (S, S))
    px = im.load()
    for y in range(S):
        for x in range(S):
            d = math.hypot(x - S * 0.5, y - S * 0.42) / (S * 0.75)
            d = min(1, d)
            c0, c1 = (70, 52, 120), (14, 11, 26)
            px[x, y] = tuple(int(a + (b - a) * d) for a, b in zip(c0, c1)) + (255,)
    if not maskable:  # bo góc kiểu icon
        m = Image.new('L', (S, S), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
        im.putalpha(m)
    k = 0.78 if maskable else 1.0  # maskable: giữ nội dung trong vùng an toàn
    cx = cy = S / 2
    R = S * 0.36 * k
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse([cx - R, cy - R, cx + R, cy + R], outline=(255, 200, 90, 160), width=int(S * 0.05 * k))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(S * 0.02)))
    d = ImageDraw.Draw(im)
    d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=(240, 196, 98, 255), width=int(S * 0.028 * k))
    cols = [(255, 120, 120), (255, 180, 80), (255, 230, 90), (150, 230, 110), (90, 210, 200), (100, 170, 255),
            (170, 130, 255), (240, 120, 220), (255, 150, 150), (255, 210, 120), (130, 220, 170), (140, 190, 255)]
    for i in range(12):
        a = math.radians(i * 30 - 90)
        r = S * 0.052 * k
        x, y = cx + R * math.cos(a), cy + R * math.sin(a)
        dd = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(dd).ellipse([x - r * 1.7, y - r * 1.7, x + r * 1.7, y + r * 1.7], fill=cols[i] + (110,))
        im.alpha_composite(dd.filter(ImageFilter.GaussianBlur(r * 0.6)))
        d.ellipse([x - r, y - r, x + r, y + r], fill=cols[i] + (255,), outline=(255, 245, 225, 255), width=int(S * 0.008))
    # trăng khuyết
    mr = S * 0.17 * k
    moon = Image.new('L', (S, S), 0)
    md = ImageDraw.Draw(moon)
    md.ellipse([cx - mr, cy - mr, cx + mr, cy + mr], fill=255)
    off = mr * 0.55
    md.ellipse([cx - mr + off, cy - mr - off * 0.35, cx + mr + off, cy + mr - off * 0.35], fill=0)
    mg = Image.new('RGBA', (S, S), (255, 214, 110, 0)); mg.putalpha(moon.filter(ImageFilter.GaussianBlur(S * 0.02)).point(lambda v: int(v * 0.7)))
    im.alpha_composite(mg)
    mc = Image.new('RGBA', (S, S), (255, 224, 140, 255)); mc.putalpha(moon)
    im.alpha_composite(mc)
    # sao lấp lánh
    for (sx, sy, sr) in [(0.6, 0.38, 0.03), (0.58, 0.6, 0.018), (0.66, 0.5, 0.014)]:
        x, y, r = cx + (sx - 0.5) * S * k, cy + (sy - 0.5) * S * k, sr * S * k
        d.polygon([(x, y - r * 2), (x + r * 0.5, y - r * 0.5), (x + r * 2, y), (x + r * 0.5, y + r * 0.5),
                   (x, y + r * 2), (x - r * 0.5, y + r * 0.5), (x - r * 2, y), (x - r * 0.5, y - r * 0.5)],
                  fill=(255, 250, 230, 255))
    return im

a, m = draw(False), draw(True)
for n in (192, 512):
    a.resize((n, n), Image.LANCZOS).save(f'{OUT}/icons/Icon-{n}.png')
    m.resize((n, n), Image.LANCZOS).save(f'{OUT}/icons/Icon-maskable-{n}.png')
m.convert('RGB').resize((180, 180), Image.LANCZOS).save(f'{OUT}/icons/apple-touch-icon.png')  # iOS tự bo góc
a.resize((64, 64), Image.LANCZOS).save(f'{OUT}/favicon.png')
print('ok')
