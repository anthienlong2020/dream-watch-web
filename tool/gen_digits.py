"""Tạo 12 con số 1–12 (nền trong suốt) kiểu đồng hồ cổ cho bản Standard.
Số chữ có chân (Lora Bold, giấy phép SIL OFL), vàng nguyên khối, viền đồng sẫm mảnh, bóng đổ –
hợp với mặt đồng thau và vỏ gỗ của đồng hồ quả lắc.
Chạy: python3 tool/gen_digits.py → assets/themes/so/1.png … 12.png
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = '/usr/share/fonts/truetype/google-fonts/Lora-Variable.ttf'
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'themes', 'so')
SIZE = 256


def font(size):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_axes([700])
    except Exception:
        pass
    return f


def make(n):
    text = str(n)
    fs = 210 if n < 10 else 160
    f = font(fs)
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bbox = d.textbbox((0, 0), text, font=f, stroke_width=8)
    x = (SIZE - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = (SIZE - (bbox[3] - bbox[1])) / 2 - bbox[1]
    # bóng đổ mềm
    sh = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((x + 5, y + 7), text, font=f, fill=(20, 10, 0, 170), stroke_width=8, stroke_fill=(20, 10, 0, 170))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(5)))
    # viền đồng sẫm mảnh để số nổi rõ trên mặt đồng thau
    d.text((x, y), text, font=f, fill=(0, 0, 0, 0), stroke_width=7, stroke_fill=(92, 62, 18, 255))
    # thân số: đồng sẫm chuyển sắc (sáng trên, tối dưới)
    mask = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).text((x, y), text, font=f, fill=255)
    grad = Image.new('RGBA', (SIZE, SIZE))
    gd = ImageDraw.Draw(grad)
    top, bot = (255, 236, 160), (196, 140, 40)  # vàng nguyên khối: sáng trên, đậm dưới
    for yy in range(SIZE):
        t = min(1, max(0, (yy - y) / (fs * 0.9)))
        c = tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3))
        gd.line([(0, yy), (SIZE, yy)], fill=c + (255,))
    img.paste(grad, (0, 0), mask)
    # ánh kim mảnh ở mép trên-trái của nét
    hl = mask.filter(ImageFilter.GaussianBlur(1))
    shift = Image.new('L', (SIZE, SIZE), 0)
    shift.paste(mask, (2, 2))
    edge = Image.eval(Image.composite(Image.new('L', (SIZE, SIZE), 0), hl, shift), lambda v: int(v * 0.8))
    img.paste(Image.new('RGBA', (SIZE, SIZE), (255, 252, 225, 255)), (0, 0), edge)
    img.save(os.path.join(OUT, f'{n}.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for n in range(1, 13):
        make(n)
    print('ok')
