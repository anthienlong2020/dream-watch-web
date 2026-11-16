"""Long/extra app clips for the rough cut (v2): M4L, M4F, M3L, M5 2.4 s, M8, M9."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from app_common import *
from recapp import record_app, tap

async def start(pg):
    await tap(pg, 180, 320, dot=False); await pg.clock.run_for(1500)

async def noop(pg, t): pass

def fast_script(speed):
    async def s(pg, t):
        await pg.clock.run_for(int(33 * (speed - 1)))
    return s

def nudge(pg):
    pass

def taps(plan):
    """plan: list of (t, x, y). Taps once each, then wiggles the mouse so Flutter repaints."""
    done = set()
    async def s(pg, t):
        for i, (at, x, y) in enumerate(plan):
            if t >= at and i not in done:
                done.add(i); await tap(pg, x, y)
        await pg.mouse.move(300 + (int(t * 30) % 2), 120)
    return s

JOBS = {
    'M4L': lambda: record_app('M4L', URLBASE, '2026-11-16T10:09:50+07:00', 14.6, noop,
                              storage=storage(faceStyle='dream', showDate=False), setup=start),
    'M4F': lambda: record_app('M4F', URLBASE, '2026-11-16T10:13:30+07:00', 8.0, fast_script(60),
                              storage=storage(faceStyle='dream', showDate=False), setup=start),
    'M3L': lambda: record_app('M3L', URLBASE, '2026-11-16T16:59:51+07:00', 12.0, noop,
                              storage=storage(edition='standard', tickOn=True), setup=start),
    # Đếm giờ: Báo thức (có 2 báo thức) → Hẹn giờ → Bấm giờ
    'M8': lambda: record_app('M8', URLBASE, '2026-11-16T10:09:50+07:00', 5.0,
                             taps([(0.0, 135, 607), (1.4, 180, 28), (2.8, 270, 28), (3.5, 240, 221)]),
                             storage={**storage(), 'flutter.alarms': '"[{\\"id\\":1,\\"hour\\":6,\\"minute\\":0,\\"label\\":\\"Dậy thôi!\\",\\"days\\":[1,2,3,4,5],\\"enabled\\":true},{\\"id\\":2,\\"hour\\":21,\\"minute\\":30,\\"label\\":\\"Uống thuốc cho mẹ\\",\\"days\\":[],\\"enabled\\":true}]"'},
                             setup=start),
    # Lịch → Ngày nhớ → Thế giới
    'M9': lambda: record_app('M9', URLBASE, '2026-11-16T10:09:50+07:00', 5.4,
                             taps([(0.0, 225, 607), (2.0, 180, 28), (3.6, 270, 28)]),
                             storage={**storage(), 'flutter.specialDays': '"[{\\"id\\":1,\\"name\\":\\"Tết Nguyên Đán\\",\\"kind\\":\\"le\\",\\"lunar\\":true,\\"day\\":1,\\"month\\":1,\\"remindBefore\\":-1,\\"remindHour\\":8,\\"onClock\\":true},{\\"id\\":2,\\"name\\":\\"Sinh nhật mẹ\\",\\"kind\\":\\"sinhNhat\\",\\"lunar\\":true,\\"day\\":12,\\"month\\":10,\\"year\\":1960,\\"remindBefore\\":1,\\"remindHour\\":8,\\"onClock\\":false},{\\"id\\":3,\\"name\\":\\"Giỗ ông nội\\",\\"kind\\":\\"gio\\",\\"lunar\\":true,\\"day\\":3,\\"month\\":12,\\"year\\":2015,\\"remindBefore\\":3,\\"remindHour\\":7,\\"onClock\\":false},{\\"id\\":4,\\"name\\":\\"Kỷ niệm ngày cưới\\",\\"kind\\":\\"kyNiem\\",\\"lunar\\":false,\\"day\\":14,\\"month\\":2,\\"year\\":2016,\\"remindBefore\\":7,\\"remindHour\\":9,\\"onClock\\":false}]"', 'flutter.settings': json.dumps(json.dumps({'presetName': 'Chuẩn', 'faceStyle': 'dream', 'remindMoon': True, 'remindMoonEve': True}))},
                             setup=start),
}
JOBS['M3X'] = lambda: record_app('M3X', URLBASE, '2026-11-16T16:59:52+07:00', 14.8, noop,
                                 storage=storage(edition='standard', tickOn=True), setup=start)
for f, st in {'tet': '20:09:55', 'trungThu': '20:09:55', 'giangSinh': '20:09:55', 'songkran': '14:09:55'}.items():
    JOBS['M5L_' + f] = (lambda f=f, st=st: record_app('M5L_' + f, URLBASE, f'2026-11-16T{st}+07:00', 2.4, noop,
                        storage=storage(faceStyle='dream', seasonMode=f, showDate=False), setup=start))

if __name__ == '__main__':
    for name in sys.argv[1:] or JOBS:
        asyncio.run(JOBS[name]())
