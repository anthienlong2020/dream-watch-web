"""Faster frame recorder: 1 rAF per frame, CDP screenshots. Usage: from rec2 import record."""
import asyncio, os, shutil, subprocess, json, base64, time
from playwright.async_api import async_playwright

W, H, DPR, FPS = 360, 640, 3, 30
ARGS = ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
        '--autoplay-policy=no-user-gesture-required']
RAF = "window.requestAnimationFrame=cb=>setTimeout(()=>cb(performance.now()),%d);"

TOUCH_JS = """(([x,y])=>{const d=document.createElement('div');Object.assign(d.style,{position:'fixed',left:(x-22)+'px',top:(y-22)+'px',width:'44px',height:'44px',borderRadius:'50%',
background:'rgba(255,255,255,.55)',border:'2px solid rgba(255,255,255,.95)',boxShadow:'0 0 18px rgba(255,255,255,.8)',zIndex:99999,pointerEvents:'none',transition:'all .45s ease-out'});
document.body.appendChild(d);requestAnimationFrame(()=>{d.style.transform='scale(1.6)';d.style.opacity='0'});setTimeout(()=>d.remove(),600);})"""


async def record(name, url, start_iso, seconds, script, setup=None, storage=None, warm=2.0,
                 one_raf=True, start_frame=0):
    out = f'/home/claude/promo/frames/{name}'
    if start_frame == 0:
        shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out, exist_ok=True)
    step = int(1000 / FPS)
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
        ctx = await b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR,
                                  has_touch=True, is_mobile=True)
        pg = await ctx.new_page()
        errs = []
        pg.on('pageerror', lambda e: errs.append(str(e)))
        if storage:
            await pg.add_init_script('(()=>{const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(storage))
        import datetime as _dt
        _st = _dt.datetime.fromisoformat(start_iso)
        await pg.clock.install(time=_st - _dt.timedelta(seconds=30))
        if one_raf:
            await pg.add_init_script(RAF % step)
        await pg.goto(url, wait_until='load')
        await pg.wait_for_timeout(2500)
        await pg.clock.pause_at(_st)  # from here on time only moves with run_for
        await pg.clock.run_for(int(warm * 1000))
        if setup:
            await setup(pg)
        cdp = await ctx.new_cdp_session(pg)
        n = int(seconds * FPS)
        t0 = time.time()
        for i in range(n):
            t = i / FPS
            await script(pg, t)
            await pg.clock.run_for(step + (1 if i % 3 == 0 else 0))
            if i < start_frame:
                continue
            r = await cdp.send('Page.captureScreenshot', {'format': 'jpeg', 'quality': 92, 'clip': {'x': 0, 'y': 0, 'width': W, 'height': H, 'scale': DPR}})
            with open(f'{out}/{i:05d}.jpg', 'wb') as f:
                f.write(base64.b64decode(r['data']))
            if i % 15 == 0:
                print(name, i, '/', n, f'{time.time()-t0:.0f}s', flush=True)
        if errs:
            print('PAGE ERRORS', errs[:3])
        await b.close()
    encode(name)


def encode(name):
    out = f'/home/claude/promo/frames/{name}'
    mp4 = f'/home/claude/promo/clips/{name}.mp4'
    os.makedirs(os.path.dirname(mp4), exist_ok=True)
    tmp = mp4[:-4] + '.part.mp4'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(FPS), '-i', f'{out}/%05d.jpg',
                    '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p', tmp], check=True)
    os.replace(tmp, mp4)
    print('done', mp4, flush=True)
