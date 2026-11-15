"""Preview a few times of a clip script: python preview.py module t1 t2 ..."""
import asyncio, sys, importlib, base64, json
sys.path.insert(0, '/home/claude/promo/scripts')
from rec2 import ARGS, W, H, DPR, RAF
from playwright.async_api import async_playwright

async def main(modname, times):
    mod = importlib.import_module(modname)
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
        ctx = await b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR, has_touch=True, is_mobile=True, timezone_id='Asia/Ho_Chi_Minh', locale='vi-VN')
        pg = await ctx.new_page()
        pg.on('pageerror', lambda e: print('ERR', e))
        st = getattr(mod, 'STORE', None)
        if st:
            await pg.add_init_script('(()=>{const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(st))
        import datetime as _dt
        _st=_dt.datetime.fromisoformat(getattr(mod, 'START', '2026-11-16T10:08:25'))
        await pg.clock.install(time=_st-_dt.timedelta(seconds=30))
        if getattr(mod, 'ONE_RAF', True):
            await pg.add_init_script(RAF % 33)
        await pg.goto(mod.URL, wait_until='load')
        await pg.wait_for_timeout(2500)
        await pg.clock.pause_at(_st)
        await pg.clock.run_for(int(getattr(mod, "WARM", 2000)))
        if hasattr(mod, 'setup'):
            await mod.setup(pg)
        cdp = await ctx.new_cdp_session(pg)
        for t in times:
            await mod.script(pg, t)
            await pg.clock.run_for(34)
            import time as _t; _a=_t.time()
            if getattr(mod, 'PW_SHOT', False):
                fn = f'/home/claude/promo/pv_{modname}_{t}.jpg'
                await pg.screenshot(path=fn, type='jpeg', quality=85, timeout=120000); print('pw shot', _t.time()-_a, flush=True); continue
            r = await cdp.send('Page.captureScreenshot', {'format': 'jpeg', 'quality': 85, 'clip': {'x': 0, 'y': 0, 'width': W, 'height': H, 'scale': DPR}, 'captureBeyondViewport': False, 'fromSurface': True})
            fn = f'/home/claude/promo/pv_{modname}_{t}.jpg'
            open(fn, 'wb').write(base64.b64decode(r['data'])); print(fn, flush=True)
        await b.close()

asyncio.run(main(sys.argv[1], [float(x) for x in sys.argv[2:]]))
