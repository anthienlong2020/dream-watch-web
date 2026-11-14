"""Tạo tiếng chuông Westminster (chuông nhà thờ / Big Ben) bằng tổng hợp âm.

Chạy: python3 tool/gen_westminster.py  → assets/sounds/west_q1..q4.mp3, strike_big.mp3
Giai điệu Westminster Quarters (1793) đã thuộc phạm vi công cộng.
"""
import os
import subprocess
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

# Chuông nhà thờ: các bồi âm đặc trưng (tỉ lệ so với nốt "prime"), biên độ, thời gian tắt (giây)
PARTIALS = [
    (0.5, 0.55, 1.00),   # hum – tiếng ù trầm ngân lâu
    (1.0, 0.80, 0.55),   # prime
    (1.183, 0.45, 0.40), # tierce – quãng ba thứ, tạo "chất" chuông
    (1.506, 0.30, 0.30), # quint
    (2.0, 0.55, 0.28),   # nominal – tiếng nghe rõ nhất lúc gõ
    (2.514, 0.22, 0.18),
    (2.662, 0.18, 0.16),
    (3.011, 0.14, 0.12),
    (4.166, 0.08, 0.08),
]


def bell(freq, dur, length_scale=1.0, bright=1.0, seed=0):
    rng = np.random.default_rng(seed)
    t = np.arange(int(SR * dur)) / SR
    out = np.zeros_like(t)
    for ratio, amp, dec in PARTIALS:
        f = freq * ratio
        if f > SR / 2.2:
            continue
        tau = dec * length_scale * 6.0 * (220 / freq) ** 0.35
        a = amp * (bright if ratio >= 2 else 1.0)
        # 2 tần số rất gần nhau → tiếng "ngân, đập" (beating) như chuông đồng thật
        d = 1 + rng.uniform(0.0008, 0.0025)
        ph = rng.uniform(0, 2 * np.pi, 2)
        out += a * np.exp(-t / tau) * (np.sin(2 * np.pi * f * t + ph[0]) + 0.6 * np.sin(2 * np.pi * f * d * t + ph[1]))
    # tiếng búa gõ ngắn lúc đầu
    n = int(SR * 0.025)
    click = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (SR * 0.004))
    out[:n] += 0.25 * bright * click
    # mở đầu thật nhanh để không bị "bụp"
    att = int(SR * 0.002)
    out[:att] *= np.linspace(0, 1, att)
    return out


# Chuông giờ: cùng "chất" với 4 chuông giai điệu (nghe êm, hài hoà) nhưng trầm hơn 1 quãng tám
# (Mi3, như chuông lớn Big Ben). Giảm tiếng ù để không giống chuông chùa; không thêm tiếng búa
# hay nén méo để khỏi chói tai.
HOUR_PARTIALS = [
    (0.5, 0.12, 0.8),
    (1.0, 0.85, 0.55),
    (1.183, 0.35, 0.40),
    (1.506, 0.30, 0.30),
    (2.0, 0.70, 0.30),
    (2.514, 0.15, 0.18),
    (3.011, 0.10, 0.12),
]


def hour_bell(freq=164.81, dur=5.0, seed=99):
    rng = np.random.default_rng(seed)
    t = np.arange(int(SR * dur)) / SR
    out = np.zeros_like(t)
    for ratio, amp, dec in HOUR_PARTIALS:
        f = freq * ratio
        tau = dec * 6.0 * (220 / freq) ** 0.35
        d = 1 + rng.uniform(0.0008, 0.0018)
        ph = rng.uniform(0, 2 * np.pi, 2)
        out += amp * np.exp(-t / tau) * (np.sin(2 * np.pi * f * t + ph[0]) + 0.6 * np.sin(2 * np.pi * f * d * t + ph[1]))
    att = int(SR * 0.004)  # mở tiếng mềm, không "tách"
    out[:att] *= np.linspace(0, 1, att)
    return out


def mix(events, total):
    buf = np.zeros(int(SR * total))
    for start, sig in events:
        i = int(SR * start)
        j = min(len(buf), i + len(sig))
        buf[i:j] += sig[: j - i]
    return buf


def save(name, buf):
    buf = buf / (np.max(np.abs(buf)) + 1e-9) * 0.9
    # tắt dần ở cuối file
    fade = int(SR * 0.8)
    buf[-fade:] *= np.linspace(1, 0, fade)
    wav = os.path.join('/tmp', name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((buf * 32767).astype('<i2').tobytes())
    mp3 = os.path.join(OUT, name + '.mp3')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-ac', '1', '-b:a', '80k', mp3], check=True)
    print(mp3, os.path.getsize(mp3))


# Nốt Westminster (giọng Mi trưởng như Big Ben): Sol#4, Fa#4, Mi4, Si3
N = {'G#': 415.30, 'F#': 369.99, 'E': 329.63, 'B': 246.94}
CHANGES = {
    1: ['G#', 'F#', 'E', 'B'],
    2: ['E', 'G#', 'F#', 'B'],
    3: ['E', 'F#', 'G#', 'E'],
    4: ['G#', 'E', 'F#', 'B'],
    5: ['B', 'F#', 'G#', 'E'],
}
QUARTERS = {1: [1], 2: [2, 3], 3: [4, 5, 1], 4: [2, 3, 4, 5]}
BEAT = 0.78       # khoảng cách giữa các nốt
HOLD = 1.0        # nốt thứ 4 ngân dài hơn
GAP = 0.85        # nghỉ giữa các câu

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for q, changes in QUARTERS.items():
        ev, t, k = [], 0.0, 0
        for c in changes:
            for i, note in enumerate(CHANGES[c]):
                ev.append((t, bell(N[note], 7.0, seed=k)))
                k += 1
                t += BEAT + (HOLD + GAP if i == 3 else 0)
        save(f'west_q{q}', mix(ev, t + 3.5))
    save('strike_big', hour_bell())
    # chuông "coong coong": cùng chất nhưng cao hơn 1 quãng tám (Mi4), ít trầm
    save('strike_cao', hour_bell(freq=329.63, dur=4.0, seed=7))
    # in độ dài từng câu để khớp lịch phát trong app
    for q, changes in QUARTERS.items():
        print(q, round(len(changes) * (4 * BEAT + HOLD + GAP) - HOLD - GAP - BEAT, 2), 's tới nốt cuối')
