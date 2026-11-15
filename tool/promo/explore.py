"""Interactive-ish explorer: run a list of actions, screenshot after each."""
import asyncio, sys, json
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import open_app, tap
from playwright.async_api import async_playwright
async def main(store, actions, start='2026-11-16T10:09:55+07:00'):
    async with async_playwright() as p:
        b, pg = await open_app(p, URLBASE + '?touchdot=1', start, store)
        await tap(pg, 180, 320, dot=False); await pg.clock.run_for(1500)
        for k, a in enumerate(actions):
            if a[0] == 'tap':
                await pg.mouse.click(a[1], a[2])
                for _ in range(3):
                    await pg.clock.run_for(100); await pg.mouse.move(a[1] + 1, a[2]); await pg.mouse.move(a[1], a[2])
            elif a[0] == 'touch': await pg.touchscreen.tap(a[1], a[2])
            elif a[0] == 'file':
                async with pg.expect_file_chooser(timeout=60000) as fc:
                    await pg.mouse.click(a[1], a[2])
                    for _ in range(20):
                        await pg.clock.run_for(100)
                await (await fc.value).set_files(a[4])
                for _ in range(5):
                    await pg.clock.run_for(100); await pg.mouse.move(a[1] + 1, a[2]); await pg.mouse.move(a[1], a[2])
            elif a[0] == 'wheel':
                await pg.mouse.move(180, 320)
                for _ in range(a[2] or 1):
                    await pg.mouse.wheel(0, a[1]); await pg.clock.run_for(50)
            for _ in range((a[3] if len(a) > 3 else 800) // 33):
                await pg.clock.run_for(33)
            await pg.screenshot(path=f'/home/claude/promo/ex_{k}.jpg', type='jpeg', quality=70)
            print('shot', k, flush=True)
        await b.close()
if __name__ == '__main__':
    st = storage(**json.loads(sys.argv[1])); acts = json.loads(sys.argv[2])
    asyncio.run(main(st, acts))
