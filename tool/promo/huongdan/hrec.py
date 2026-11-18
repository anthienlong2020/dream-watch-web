"""Quay màn hình app cho video hướng dẫn (dọc, 360x640 CSS x3 = 1080x1920).
Dùng:  r = Rec('t2_s2'); await r.open(...); await r.tap(x, y); await r.wait(2); ... ; await r.close()
Ghi kèm rec/<tên>.json: thời điểm chạm (toạ độ CSS) + chữ chỉ dẫn, để bộ ráp vẽ vòng tròn vàng và chữ.
"""
import asyncio, os, json, time, subprocess, datetime as dt, sys
sys.path.insert(0, '/home/claude/dream-watch-web/tool/promo')
from playwright.async_api import async_playwright
from rec2 import ARGS
from app_common import storage as app_storage

W, H, DPR = 360, 640, 3
ROOT = '/home/claude/hd'
APP = 'http://localhost:8091/'

SEM_JS = '''(()=>{const out=[];document.querySelectorAll('flt-semantics').forEach(e=>{const r=e.getBoundingClientRect();
 let t=(e.getAttribute('aria-label')||'')+' '+([...e.childNodes].filter(n=>n.nodeType==3).map(n=>n.textContent).join(''));
 t=t.trim(); if(!t||r.width==0)return; out.push({x:r.x+r.width/2,y:r.y+r.height/2,w:r.width,h:r.height,role:e.getAttribute('role')||'',t});});return out;})()'''


class Rec:
    def __init__(self, name, fps=15):
        self.name, self.fps = name, fps
        self.dir = f'{ROOT}/frames/{name}_{int(time.time())}'   # thư mục mới mỗi lần quay, không xoá gì
        os.makedirs(self.dir, exist_ok=True)
        self.i, self.t, self.rec = 0, 0.0, False
        self.taps, self.caps, self.marks = [], [], {}
        self.mx, self.my, self.down = 180, 320, False

    async def open(self, edition='pro', start='2026-11-18T10:09:50+07:00', url=APP, extra=None, tapstart=True, **settings):
        self.p = await async_playwright().start()
        self.b = await self.p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
        self.ctx = await self.b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR, has_touch=True,
                                            is_mobile=True, timezone_id='Asia/Ho_Chi_Minh', locale='vi-VN')
        pg = self.pg = await self.ctx.new_page()
        emoji = open('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf', 'rb').read()

        async def fonts(route):
            if 'emoji' in route.request.url.lower():
                await route.fulfill(status=200, body=emoji, headers={'Content-Type': 'font/ttf', 'Access-Control-Allow-Origin': '*'})
            else:
                await route.abort()
        await pg.route('**/fonts.gstatic.com/**', fonts); await pg.route('**/fonts.googleapis.com/**', fonts)
        s = app_storage(edition, **settings)
        if extra: s.update(extra)
        await pg.add_init_script('(()=>{if(sessionStorage.__init)return;sessionStorage.__init=1;const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(s))
        st = dt.datetime.fromisoformat(start)
        await pg.clock.install(time=st - dt.timedelta(seconds=120))
        await pg.goto(url, wait_until='load'); await pg.wait_for_timeout(4500)
        await pg.clock.pause_at(st); await pg.clock.run_for(1500)
        if tapstart:
            await pg.mouse.click(180, 320); await self.idle(1.5)
        await pg.evaluate("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click();})()")
        await self.idle(0.5)

    # ---------- time ----------
    async def _step(self, ms):
        await self.pg.clock.run_for(ms)
        if not self.down:   # Flutter dưới đồng hồ giả đôi khi chờ sự kiện chuột mới vẽ
            await self.pg.mouse.move(self.mx + (1 if self.i % 2 else 0), self.my)

    async def frame(self):
        await self._step(int(round(1000 / self.fps)))
        if self.rec:
            await self.pg.screenshot(path=f'{self.dir}/{self.i:05d}.jpg', type='jpeg', quality=90)
            self.i += 1; self.t = self.i / self.fps

    async def idle(self, sec):          # chạy thời gian, không quay
        r, self.rec = self.rec, False
        for _ in range(int(sec * 1000 / 50)): await self._step(50)
        self.rec = r

    async def wait(self, sec):
        if not self.rec: return await self.idle(sec)
        for _ in range(max(1, int(round(sec * self.fps)))): await self.frame()

    def start(self): self.rec = True

    # ---------- actions ----------
    async def tap(self, x, y, pre=1.1, post=0.9, ring=True):
        await self.wait(pre)
        if self.rec and ring: self.taps.append([round(self.t, 3), x, y])
        self.mx, self.my = x, y
        await self.pg.mouse.click(x, y)
        self.mx, self.my = 4, 330      # đưa chuột ra mép để không hiện chú thích (tooltip) khi rê
        await self.wait(post)

    async def drag(self, x0, y0, x1, y1, sec=1.0, pre=1.0, post=0.6):
        await self.wait(pre)
        if self.rec: self.taps.append([round(self.t, 3), x0, y0])
        self.mx, self.my = x0, y0
        await self.pg.mouse.move(x0, y0); await self.pg.mouse.down(); self.down = True
        n = max(2, int(sec * (self.fps if self.rec else 20)))
        for k in range(1, n + 1):
            await self.pg.mouse.move(x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n)
            if self.rec: await self.frame()
            else: await self._step(50)
        await self.pg.mouse.up(); self.down = False; self.mx, self.my = x1, y1
        await self.wait(post)

    async def scroll(self, px, sec=1.5, x=180, y=380):
        """Cuộn nội dung lên px điểm (dương = xuống dưới trang). 1 nấc wheel 100 ≈ 11 px."""
        self.mx, self.my = x, y
        await self.pg.mouse.move(x, y)
        notches = max(1, round(abs(px) / 11)); sgn = 1 if px > 0 else -1
        frames = max(1, int(sec * (self.fps if self.rec else 20)))
        done = 0
        for k in range(1, frames + 1):
            want = round(notches * k / frames)
            for _ in range(want - done): await self.pg.mouse.wheel(0, 100 * sgn)
            done = want
            if self.rec: await self.frame()
            else: await self._step(50)
        await self.wait(0.8)

    async def type(self, text, per=0.12):
        for ch in text:
            await self.pg.keyboard.type(ch)
            await self.wait(per)

    def cap(self, text):
        self.caps.append([round(self.t, 3), text])

    def mark(self, k): self.marks[k] = round(self.t, 3)

    async def sem(self, pat=None):
        items = await self.pg.evaluate(SEM_JS)
        if pat: items = [e for e in items if pat.lower() in e['t'].lower()]
        return items

    async def find(self, pat, idx=0, maxy=570):
        it = await self.sem(pat)
        it = [e for e in it if 20 < e['y'] < maxy and e['role'] != 'tab']
        it.sort(key=lambda e: (e['t'].strip() != pat, e['w'] * e['h']))   # khớp đúng chữ, rồi phần tử nhỏ nhất
        if idx: it.sort(key=lambda e: e['y'])
        if len(it) <= idx:
            await self.shot(f'/tmp/fail_{self.name}.png')
            for e in await self.sem():
                if 0 < e['y'] < 640: print(' ', round(e['x']), round(e['y']), e['t'][:40].replace('\n', '/'))
            raise RuntimeError(f'{self.name}: không thấy "{pat}"')
        return round(it[idx]['x']), round(it[idx]['y'])

    async def tapt(self, pat, idx=0, dx=0, dy=0, maxy=570, **kw):
        x, y = await self.find(pat, idx, maxy)
        await self.tap(x + dx, y + dy, **kw)
        return x, y

    async def shot(self, path):
        await self.pg.screenshot(path='/tmp/_full.png')
        from PIL import Image
        Image.open('/tmp/_full.png').resize((360, 640)).save(path); return path

    async def close(self):
        await self.b.close(); await self.p.stop()
        if self.i:
            mp4 = f'{ROOT}/rec/{self.name}.mp4'; os.makedirs(f'{ROOT}/rec', exist_ok=True)
            subprocess.run(['ffmpeg', '-y', '-v', 'error', '-framerate', str(self.fps), '-i', f'{self.dir}/%05d.jpg',
                            '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '17', '-pix_fmt', 'yuv420p', mp4], check=True)
            json.dump(dict(dur=self.i / self.fps, taps=self.taps, caps=self.caps, marks=self.marks),
                      open(f'{ROOT}/rec/{self.name}.json', 'w'), ensure_ascii=False, indent=1)
            print('REC', self.name, f'{self.i / self.fps:.1f}s', flush=True)
