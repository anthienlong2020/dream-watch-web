"""Tạo 12 ảnh con số 1–12 (nền trong suốt) cho bản Standard – đồng hồ quả lắc.
Chạy: python3 tool/gen_digits.py → assets/themes/so/1.png … 12.png
Font Poppins Bold (giấy phép SIL OFL, dùng tự do).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf'
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'themes', 'so')
COLORS = ['#E53935', '#FB8C00', '#FDD835', '#43A047', '#00ACC1', '#1E88E5',
          '#5E35B1', '#D81B60', '#6D4C41', '#00897B', '#F4511E', '#8E24AA']
SIZE = 256


def hex2rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def make(n):
    text = str(n)
    fs = 200 if n < 10 else 150
    font = ImageFont.truetype(FONT, fs)
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bbox = d.textbbox((0, 0), text, font=font, stroke_width=14)
    x = (SIZE - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = (SIZE - (bbox[3] - bbox[1])) / 2 - bbox[1]
    # bóng đổ mềm
    sh = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((x + 6, y + 9), text, font=font, fill=(0, 0, 0, 120), stroke_width=14, stroke_fill=(0, 0, 0, 120))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(6)))
    # viền trắng dày + thân màu
    d.text((x, y), text, font=font, fill=hex2rgb(COLORS[n - 1]), stroke_width=14, stroke_fill=(255, 255, 255))
    # ánh sáng phía trên (gradient trắng mờ phủ nửa trên thân số)
    mask = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).text((x, y), text, font=font, fill=255)
    hl = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    hd = ImageDraw.Draw(hl)
    for yy in range(SIZE):
        a = max(0, int(110 * (1 - (yy - y) / (fs * 0.6)))) if yy > y else 110
        hd.line([(0, yy), (SIZE, yy)], fill=(255, 255, 255, min(a, 110)))
    hl.putalpha(Image.composite(hl.getchannel('A'), Image.new('L', (SIZE, SIZE), 0), mask))
    img.alpha_composite(hl)
    img.save(os.path.join(OUT, f'{n}.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for n in range(1, 13):
        make(n)
    print('ok')
