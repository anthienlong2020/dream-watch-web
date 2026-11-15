"""Tạo tiếng tích – tắc của quả lắc (gỗ + bánh răng), ngắn và nhẹ.
Chạy: python3 tool/gen_tick.py → assets/sounds/tick.mp3, tock.mp3
"""
import os
import subprocess
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def click(f1, f2, seed):
    rng = np.random.default_rng(seed)
    t = np.arange(int(SR * 0.12)) / SR
    env = np.exp(-t / 0.012)
    body = 0.6 * np.sin(2 * np.pi * f1 * t) * np.exp(-t / 0.02) + 0.35 * np.sin(2 * np.pi * f2 * t) * np.exp(-t / 0.01)
    noise = rng.normal(0, 1, len(t)) * np.exp(-t / 0.002) * 0.5
    x = body * env + noise
    return x / np.max(np.abs(x)) * 0.7


def save(name, x):
    wav = f'/tmp/{name}.wav'
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-b:a', '64k', os.path.join(OUT, name + '.mp3')], check=True)


if __name__ == '__main__':
    save('tick', click(2100, 3400, 1))
    save('tock', click(1500, 2600, 2))
