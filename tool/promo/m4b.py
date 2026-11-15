"""M4b: AI portrait -> Chibi 3D in the app's maker, then the clock with the chibi wrapped in fire (8 s)."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import record_app, tap

URL = URLBASE + '?touchdot=1'
START = '2026-11-16T13:09:40+07:00'   # hour 1 -> slot I sits in the centre
PHOTO = '/home/claude/promo/flow/S3_co2.jpg'
STORE = storage(faceStyle='dream', seasonMode='off', showDate=False, effectsOn=True,
                slotElement=[None, 'lua'] + [None] * 10)


async def settle(pg, x=180, y=320, n=4):
    """Flutter under a paused clock sometimes waits for an input event before drawing: nudge it."""
    for _ in range(n):
        await pg.clock.run_for(100)
        await pg.mouse.move(x + 1, y); await pg.mouse.move(x, y)


async def click(pg, x, y, wait=1200):
    await pg.mouse.click(x, y); await settle(pg, x, y)
    for _ in range(wait // 33):
        await pg.clock.run_for(33)


async def setup(pg):
    await tap(pg, 180, 320, dot=False); await pg.clock.run_for(1500)
    await click(pg, 315, 607)                      # Cài đặt
    await pg.mouse.move(180, 320)
    for _ in range(30):
        await pg.mouse.wheel(0, 300); await pg.clock.run_for(50)
    for _ in range(60):
        await pg.clock.run_for(33)
    await click(pg, 51, 253, 1500)                 # slot I
    await click(pg, 180, 600, 2000)                # "Tạo Chibi từ ảnh người"
    got = {}

    async def on_fc(fc):
        await fc.set_files(PHOTO); got['ok'] = 1
    pg.on('filechooser', on_fc)
    for attempt in range(6):
        await pg.mouse.click(180, 431)             # "Chọn ảnh người"
        await settle(pg, 180, 431, 15)
        if got:
            break
    if not got:
        raise RuntimeError('file chooser did not open')
    await settle(pg, 180, 431, 10)
    for _ in range(90):
        await pg.clock.run_for(33)
    # zoom the face circle in
    await pg.mouse.move(80, 404); await pg.mouse.down()
    for k in range(10):
        await pg.mouse.move(80 + 3 * (k + 1), 404); await pg.clock.run_for(33)
    await pg.mouse.up(); await settle(pg, 150, 404)
    await pg.mouse.move(180, 320)
    for _ in range(10):
        await pg.mouse.wheel(0, 300); await pg.clock.run_for(50)
    for _ in range(60):
        await pg.clock.run_for(33)

done = {}


async def script(pg, t):
    async def once(key, at, fn):
        if t >= at and key not in done:
            done[key] = 1; await fn()
    # swipe the chibi preview to spin it
    if 0.4 <= t < 1.4:
        if 'down' not in done:
            done['down'] = 1; await pg.mouse.move(110, 300); await pg.mouse.down()
        x = 110 + (t - 0.4) * 160
        await pg.mouse.move(x, 300)
    await once('up', 1.4, lambda: pg.mouse.up())
    await once('vay', 1.7, lambda: pg.mouse.click(155, 476))
    await once('dung', 2.8, lambda: pg.mouse.click(180, 612))
    await once('clock', 3.3, lambda: pg.mouse.click(45, 607))
    if t >= 1.45:
        await pg.mouse.move(181 if int(t * 30) % 2 else 180, 330)


if __name__ == '__main__':
    shots = [float(x) for x in sys.argv[1:]] or None
    asyncio.run(record_app('M4b' if shots is None else 'pvM4b', URL, START, 8, script, storage=STORE, setup=setup,
                           shots_only=shots))
