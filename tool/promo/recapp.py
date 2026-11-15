"""Frame recorder for the Flutter app (fake clock, Playwright screenshots at device scale)."""
import asyncio, os, shutil, json, time, datetime as dt
from playwright.async_api import async_playwright
from rec2 import ARGS, W, H, DPR, FPS, TOUCH_JS, encode

async def open_app(p, url, start_iso, storage, load_wait=4000):
    b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
    ctx = await b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR, has_touch=True,
                              is_mobile=True, timezone_id='Asia/Ho_Chi_Minh', locale='vi-VN')
    pg = await ctx.new_page()
    emoji = open('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf', 'rb').read()

    async def fonts(route):
        u = route.request.url
        if 'emoji' in u.lower():
            await route.fulfill(status=200, body=emoji, headers={'Content-Type': 'font/ttf', 'Access-Control-Allow-Origin': '*'})
        else:
            await route.abort()
    await pg.route('**/fonts.gstatic.com/**', fonts)
    await pg.route('**/fonts.googleapis.com/**', fonts)
    if storage:
        await pg.add_init_script('(()=>{const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(storage))
    st = dt.datetime.fromisoformat(start_iso)
    await pg.clock.install(time=st - dt.timedelta(seconds=25))
    await pg.goto(url, wait_until='load')
    await pg.wait_for_timeout(load_wait)
    await pg.clock.pause_at(st)
    await pg.clock.run_for(1500)
    return b, pg


async def tap(pg, x, y, dot=True):
    """Tap with a visible dot (the app's own ?touchdot=1 draws one too, so dot=False there)."""
    if dot:
        await pg.evaluate(TOUCH_JS + '(%s)' % json.dumps([x, y]))
    await pg.mouse.click(x, y)


async def record_app(name, url, start_iso, seconds, script, storage=None, setup=None, shots_only=None):
    """script(pg, t) runs before frame at t. shots_only: list of t to save (preview)."""
    out = f'/home/claude/promo/frames/{name}'
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
    async with async_playwright() as p:
        b, pg = await open_app(p, url, start_iso, storage)
        if setup:
            await setup(pg)
        n = int(seconds * FPS); t0 = time.time()
        for i in range(n):
            t = i / FPS
            await script(pg, t)
            await pg.clock.run_for(33 if i % 3 else 34)
            if shots_only is not None and not any(abs(t - s) < 0.5 / FPS for s in shots_only):
                continue
            await pg.screenshot(path=f'{out}/{i:05d}.jpg', type='jpeg', quality=92)
            if i % 30 == 0:
                print(name, i, '/', n, f'{time.time()-t0:.0f}s', flush=True)
        await b.close()
    if shots_only is None:
        encode(name)
