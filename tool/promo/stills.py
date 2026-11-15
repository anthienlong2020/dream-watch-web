"""S2 phone frame, S4 end card, S5 cover. python stills.py [s2|s4|s5] ..."""
import sys, json, qrcode
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = '/home/claude/promo/stills'
GF = '/usr/share/fonts/truetype/google-fonts/'
LINK = 'https://anthienlong2020.github.io/dream-watch-web/'
W, H = 1080, 1920
GOLD = (233, 196, 106)
CREAM = (255, 246, 228)


INTER = {'Poppins-Bold.ttf': '/usr/share/fonts/opentype/inter/Inter-Bold.otf',
         'Poppins-Medium.ttf': '/usr/share/fonts/opentype/inter/Inter-Medium.otf'}


def font(name, size, wght=None):
    f = ImageFont.truetype(INTER.get(name, GF + name), size)
    if wght:
        try:
            f.set_variation_by_axes([wght])
        except Exception:
            pass
    return f


def bg_gradient():
    """Same palette as the movement page: violet glow at top, near-black edges."""
    im = Image.new('RGB', (W, H))
    px = im.load()
    for y in range(H):
        for x in range(0, W):
            dx, dy = (x - W * 0.5) / W, (y - H * 0.35) / H * 0.9
            d = min(1.0, (dx * dx + dy * dy) ** 0.5 * 1.6)
            if d < 0.6:
                k = d / 0.6; c0, c1 = (43, 36, 64), (18, 15, 28)
            else:
                k = (d - 0.6) / 0.4; c0, c1 = (18, 15, 28), (7, 6, 11)
            px[x, y] = tuple(int(a + (b - a) * k) for a, b in zip(c0, c1))
    return im


def phone(screen_w, screen_h, bezel=None, radius=None):
    """Transparent PNG of a phone; returns (image, screen box)."""
    bezel = bezel or max(14, screen_w // 30)
    radius = radius or screen_w // 9
    pw, ph = screen_w + bezel * 2, screen_h + bezel * 2
    ss = 2
    im = Image.new('RGBA', (pw * ss, ph * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, pw * ss - 1, ph * ss - 1], radius=(radius + bezel) * ss, fill=(22, 22, 26, 255),
                        outline=(120, 110, 95, 255), width=3 * ss)
    d.rounded_rectangle([bezel * ss, bezel * ss, (pw - bezel) * ss - 1, (ph - bezel) * ss - 1], radius=radius * ss,
                        fill=(0, 0, 0, 0))
    # camera pill
    cw = screen_w // 4
    d.rounded_rectangle([(pw // 2 - cw // 2) * ss, (bezel + 14) * ss, (pw // 2 + cw // 2) * ss, (bezel + 14 + screen_w // 22) * ss],
                        radius=screen_w * ss, fill=(10, 10, 12, 255))
    im = im.resize((pw, ph), Image.LANCZOS)
    return im, (bezel, bezel, bezel + screen_w, bezel + screen_h), radius


def put_screen(phone_im, box, radius, shot):
    shot = shot.convert('RGBA').resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
    mask = Image.new('L', shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.size[0] - 1, shot.size[1] - 1], radius=radius, fill=255)
    base = Image.new('RGBA', phone_im.size, (0, 0, 0, 0))
    base.paste(shot, box[:2], mask)
    base.alpha_composite(phone_im)
    return base


def shadowed(canvas, layer, xy, blur=30, alpha=160):
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    a = layer.split()[3].point(lambda v: alpha if v > 0 else 0)
    blk = Image.new('RGBA', layer.size, (0, 0, 0, 255)); blk.putalpha(a)
    sh.paste(blk, (xy[0], xy[1] + 18), blk)
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(layer, xy)


def ctext(d, y, text, f, fill, stroke=0, sfill=(0, 0, 0)):
    w = d.textlength(text, font=f)
    d.text(((W - w) / 2, y), text, font=f, fill=fill, stroke_width=stroke, stroke_fill=sfill)


def s2():
    """Empty phone frame for 1080x1920 recordings, sized to sit inside the safe zone."""
    sw, sh = 702, 1248  # 9:16
    im, box, r = phone(sw, sh)
    im.save(f'{OUT}/S2_khung_dien_thoai.png')
    full = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    x, y = (W - im.width) // 2, 260
    full.alpha_composite(im, (x, y))
    full.save(f'{OUT}/S2_khung_dien_thoai_1080x1920.png')
    json.dump({'screen': [x + box[0], y + box[1], x + box[2], y + box[3]], 'radius': r},
              open(f'{OUT}/S2_screen_box.json', 'w'))
    print('S2 ok', box)


def s4(shot_path):
    c = bg_gradient().convert('RGBA')
    d = ImageDraw.Draw(c)
    title = font('Lora-Variable.ttf', 92, 700)
    ctext(d, 262, 'Chiếc đồng hồ', title, CREAM)
    ctext(d, 368, 'mộng mơ', title, GOLD)
    # phone with an app screenshot (left)
    im, box, r = phone(330, 587)
    ph = put_screen(im, box, r, Image.open(shot_path))
    shadowed(c, ph, (95, 520))
    # QR (right)
    q = qrcode.QRCode(border=2, box_size=10, error_correction=qrcode.constants.ERROR_CORRECT_M)
    q.add_data(LINK); q.make(fit=True)
    qi = q.make_image(fill_color=(20, 16, 30), back_color=(255, 250, 240)).convert('RGBA').resize((400, 400), Image.NEAREST)
    card = Image.new('RGBA', (440, 440), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([0, 0, 439, 439], radius=28, fill=(255, 250, 240, 255))
    card.alpha_composite(qi, (20, 20))
    shadowed(c, card, (560, 560))
    f2 = font('Poppins-Medium.ttf', 38)
    t = 'Quét để mở ngay'
    d.text((560 + (440 - d.textlength(t, font=f2)) / 2, 1020), t, font=f2, fill=CREAM)
    # slogan + link
    ctext(d, 1170, 'Miễn phí · Không cần cài · Mở link là dùng', font('Poppins-Bold.ttf', 44), CREAM)
    ctext(d, 1245, 'anthienlong2020.github.io/dream-watch-web', font('Poppins-Medium.ttf', 40), GOLD)
    fq = font('Lora-Italic-Variable.ttf', 48, 500)
    ctext(d, 1345, 'Bạn muốn đưa giấc mơ nào', fq, CREAM)
    ctext(d, 1410, 'lên chiếc đồng hồ? Bình luận nhé!', fq, CREAM)
    c.convert('RGB').save(f'{OUT}/S4_anh_ket.png')
    print('S4 ok')


def s5(frame_path):
    c = Image.open(frame_path).convert('RGBA').resize((W, H), Image.LANCZOS)
    # darken top and bottom so the text reads
    g = Image.new('L', (1, H))
    for y in range(H):
        top = max(0, 1 - y / 760); bot = max(0, (y - 1250) / 670)
        g.putpixel((0, y), int(225 * max(top, bot) ** 1.2))
    shade = Image.new('RGBA', (W, H), (8, 6, 14, 255)); shade.putalpha(g.resize((W, H)))
    c.alpha_composite(shade)
    d = ImageDraw.Draw(c)
    big = font('Lora-Variable.ttf', 150, 700)
    ctext(d, 270, 'Thời gian', big, CREAM, 3, (20, 14, 6))
    ctext(d, 440, 'trong suốt', big, GOLD, 3, (20, 14, 6))
    ctext(d, 1340, 'Chiếc đồng hồ mộng mơ', font('Poppins-Bold.ttf', 58), CREAM, 2, (10, 8, 16))
    ctext(d, 1425, 'Miễn phí · Mở link là dùng', font('Poppins-Medium.ttf', 44), GOLD, 2, (10, 8, 16))
    c.convert('RGB').save(f'{OUT}/S5_anh_bia.png')
    print('S5 ok')


if __name__ == '__main__':
    import os; os.makedirs(OUT, exist_ok=True)
    cmd = sys.argv[1]
    {'s2': lambda: s2(), 's4': lambda: s4(sys.argv[2]), 's5': lambda: s5(sys.argv[2])}[cmd]()
