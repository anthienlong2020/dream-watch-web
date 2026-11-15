"""Frame-by-frame recorder: fake clock, step 1/30 s, JPEG frames -> mp4."""
import asyncio, os, shutil, subprocess, sys, json
from playwright.async_api import async_playwright

W, H, DPR, FPS = 360, 640, 3, 30
ARGS = ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required']

async def record(name, url, start_iso, seconds, script, storage=None, warm=2.0, touch=True):
    """script(pg, t) is awaited before each frame at time t (seconds from clip start)."""
    out = f'/home/claude/promo/frames/{name}'
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
        ctx = await b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR, has_touch=True, is_mobile=True)
        pg = await ctx.new_page()
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        if storage:
            await pg.add_init_script('(()=>{const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(storage))
        await pg.clock.install(time=start_iso)
        await pg.goto(url, wait_until='load')
        # warm-up (loading textures, shaders)
        await pg.wait_for_timeout(1500)
        await pg.clock.run_for(int(warm * 1000))
        n = int(seconds * FPS)
        for i in range(n):
            t = i / FPS
            await script(pg, t)
            await pg.clock.run_for(33 if i % 3 else 34)
            await pg.screenshot(path=f'{out}/{i:05d}.jpg', type='jpeg', quality=92)
            if i % 30 == 0: print(name, i, '/', n, flush=True)
        if errs: print('PAGE ERRORS', errs[:3])
        await b.close()
    mp4 = f'/home/claude/promo/clips/{name}.mp4'; os.makedirs(os.path.dirname(mp4), exist_ok=True)
    tmp = mp4[:-4] + '.part.mp4'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(FPS), '-i', f'{out}/%05d.jpg',
                    '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p', tmp], check=True)
    os.replace(tmp, mp4); print('done', mp4)

TOUCH_JS = """(([x,y])=>{const d=document.createElement('div');Object.assign(d.style,{position:'fixed',left:(x-22)+'px',top:(y-22)+'px',width:'44px',height:'44px',borderRadius:'50%',
background:'rgba(255,255,255,.55)',border:'2px solid rgba(255,255,255,.95)',boxShadow:'0 0 18px rgba(255,255,255,.8)',zIndex:99,pointerEvents:'none',transition:'all .45s ease-out'});
document.body.appendChild(d);requestAnimationFrame(()=>{d.style.transform='scale(1.6)';d.style.opacity='0'});setTimeout(()=>d.remove(),600);})"""
