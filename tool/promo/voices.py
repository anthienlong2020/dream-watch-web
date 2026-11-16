"""Make 5-6 s reference samples for every offline Vietnamese voice + per-group preview files."""
import subprocess, json, os, sys, wave
import numpy as np, librosa, soundfile as sf
M = '/home/claude/tts/model/'
MODELS = [('25hours', M + 'vits-piper-vi_VN-25hours_single-low/vi_VN-25hours_single-low.onnx', [None]),
          ('vais1000', M + 'vits-piper-vi_VN-vais1000-medium/vi_VN-vais1000-medium.onnx', [None]),
          ('vivos', M + 'vits-piper-vi_VN-vivos-x_low/vi_VN-vivos-x_low.onnx', list(range(65)))]
REF = 'Xin chào, mình là một giọng đọc mẫu. Chúc bạn một ngày thật vui, và mỗi đêm đều có những giấc mơ thật đẹp.'
DIGITS = 'không một hai ba bốn năm sáu bảy tám chín'.split()
def words(n):
    if n < 10: return DIGITS[n]
    t, u = divmod(n, 10)
    a = 'mười' if t == 1 else DIGITS[t] + ' mươi'
    if u == 0: return a
    b = {1: 'mốt' if t > 1 else 'một', 4: 'tư' if t > 1 else 'bốn', 5: 'lăm'}.get(u, DIGITS[u])
    return a + ' ' + b
def tts(model, spk, text, out, ls=1.0):
    cmd = ['python3', '-m', 'piper', '-m', model, '--noise-scale', '0.4', '--noise-w-scale', '0.6', '--length-scale', str(ls), '-f', out]
    if spk is not None: cmd += ['-s', str(spk)]
    subprocess.run(cmd, input=text.encode(), check=True, capture_output=True)
def dur(f):
    with wave.open(f) as w: return w.getnframes() / w.getframerate()
def clean(src, dst):
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', src, '-af',
                    'highpass=f=80,afftdn=nf=-28,loudnorm=I=-18:TP=-1.5', '-ar', '24000', '-ac', '1', dst], check=True)
rows = []
os.makedirs('tmp', exist_ok=True); os.makedirs('mau', exist_ok=True)
for name, model, spks in MODELS:
    for spk in spks:
        raw = f'tmp/{name}_{spk}.wav'
        tts(model, spk, REF, raw)
        d = dur(raw); ls = min(1.35, max(0.85, 5.6 / d))
        tts(model, spk, REF, raw, ls)
        y, sr = librosa.load(raw, sr=22050)
        f0, _, _ = librosa.pyin(y, fmin=70, fmax=450, sr=sr)
        h, p = librosa.effects.hpss(y)
        rows.append(dict(name=name, spk=spk, f0=float(np.nanmedian(f0)),
                         harm=float(10 * np.log10((h ** 2).sum() / ((p ** 2).sum() + 1e-9))), raw=raw, ls=ls, model=model))
        print(name, spk, round(rows[-1]['f0']), round(rows[-1]['harm'], 1), flush=True)
# order: women first, cleanest first
for r in rows: r['gioi'] = 'nu' if r['f0'] >= 185 else 'nam'
rows.sort(key=lambda r: (r['gioi'] != 'nu', -r['harm']))
for i, r in enumerate(rows, 1):
    q = 'sach' if r['harm'] > 4 else ('vua' if r['harm'] > -2 else 're')
    base = f'giong_{i:02d}_{r["gioi"]}_{q}'
    r['file'] = base; r['id'] = i; r['q'] = q
    clean(r['raw'], f'mau/{base}.wav')
    open(f'mau/{base}.txt', 'w').write(REF + '\n')
    tts(r['model'], r['spk'], f'Giọng số {words(i)}.', f'tmp/ann_{i}.wav', 1.0)
json.dump(rows, open('voices.json', 'w'), ensure_ascii=False, indent=1)
