"""M5: festivals, one short clip each: tet, trungThu, giangSinh, songkran (1.6 s each)."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import record_app, tap
URL = URLBASE
FEST = {'tet': '2026-11-16T20:09:55+07:00', 'trungThu': '2026-11-16T20:09:55+07:00',
        'giangSinh': '2026-11-16T20:09:55+07:00', 'songkran': '2026-11-16T14:09:55+07:00'}
async def setup(pg):
    await tap(pg, 180, 320, dot=False); await pg.clock.run_for(2500)
async def script(pg, t): pass
if __name__ == '__main__':
    which = sys.argv[1:] or list(FEST)
    pv = len(which) == 1 and which[0] == 'pv'
    for f in (FEST if pv else which):
        st = storage(faceStyle='dream', seasonMode=f, showDate=False)
        asyncio.run(record_app(f'M5_{f}' if not pv else f'pvM5_{f}', URL, FEST[f], 1.6, script, storage=st, setup=setup,
                               shots_only=[0.8] if pv else None))
