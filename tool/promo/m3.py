"""M3: Standard edition (antique pendulum clock) right before 17:00 chime (6 s)."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import record_app, tap
URL = URLBASE
START = '2026-11-16T16:59:54+07:00'
STORE = storage(edition='standard', faceStyle='dream', tickOn=True, chimeMode='westminster')
async def setup(pg):
    await tap(pg, 180, 320, dot=False); await pg.clock.run_for(1500)
async def script(pg, t): pass
if __name__ == '__main__':
    shots = [float(x) for x in sys.argv[1:]] or None
    asyncio.run(record_app('M3' if shots is None else 'pvM3', URL, START, 6, script, storage=STORE, setup=setup, shots_only=shots))
