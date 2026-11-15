"""M6: Settings -> hourly voice recorder, tap the mic -> recording (4 s)."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import record_app, tap
URL = URLBASE + '?touchdot=1'
START = '2026-11-16T10:09:55+07:00'
STORE = storage(hourVoice='ghi', hourRecs=['chung', '7', '8'])
async def setup(pg):
    await tap(pg, 180, 320, dot=False); await pg.clock.run_for(1500)
    await pg.mouse.click(315, 607); await pg.clock.run_for(1200)
    await pg.mouse.move(180, 320)
    for _ in range(92):
        await pg.mouse.wheel(0, 300); await pg.clock.run_for(50)
    await pg.clock.run_for(1500)
done = {}
async def script(pg, t):
    if t >= 0.7 and 'mic' not in done:
        done['mic'] = 1; await pg.mouse.click(240, 384)
if __name__ == '__main__':
    shots = [float(x) for x in sys.argv[1:]] or None
    done.clear()
    asyncio.run(record_app('M6' if shots is None else 'pvM6', URL, START, 4, script, storage=STORE, setup=setup, shots_only=shots))
