"""Interactive driver: persistent Playwright page; commands via HTTP GET /cmd?code=<python async expr>."""
import asyncio, json, sys, datetime as dt, traceback
sys.path.insert(0, '/home/claude/dream-watch-web/tool/promo')
from aiohttp import web
from playwright.async_api import async_playwright
from rec2 import ARGS, W, H, DPR
from app_common import storage
G = {}
async def start(edition='pro', start_iso='2026-11-18T10:09:50+07:00', url='http://localhost:8091/?touchdot=1', **st):
    p = G.get('p')
    if 'b' in G: await G['b'].close()
    b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
    ctx = await b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=DPR, has_touch=True, is_mobile=True, timezone_id='Asia/Ho_Chi_Minh', locale='vi-VN')
    pg = await ctx.new_page()
    emoji = open('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf','rb').read()
    async def fonts(route):
        if 'emoji' in route.request.url.lower(): await route.fulfill(status=200, body=emoji, headers={'Content-Type':'font/ttf','Access-Control-Allow-Origin':'*'})
        else: await route.abort()
    await pg.route('**/fonts.gstatic.com/**', fonts); await pg.route('**/fonts.googleapis.com/**', fonts)
    s = storage(edition, **st)
    s['mvQuality'] = 'high'
    await pg.add_init_script('(()=>{if(sessionStorage.__init)return;sessionStorage.__init=1;const s=%s;for(const k in s)localStorage.setItem(k,s[k]);})()' % json.dumps(s))
    t = dt.datetime.fromisoformat(start_iso)
    await pg.clock.install(time=t - dt.timedelta(seconds=120))
    await pg.goto(url, wait_until='load'); await pg.wait_for_timeout(4000)
    await pg.clock.pause_at(t); await pg.clock.run_for(1500)
    G.update(b=b, pg=pg)
    return 'started'
async def shot(path='/tmp/x.png', s=1.0):
    await G['pg'].screenshot(path='/tmp/full.png')
    from PIL import Image
    im=Image.open('/tmp/full.png'); im.resize((int(360*s),int(640*s))).save(path); return path
async def click(x, y, wait=1200):
    pg = G['pg']; await pg.mouse.click(x, y)
    for _ in range(4):
        await pg.clock.run_for(100); await pg.mouse.move(x+1, y); await pg.mouse.move(x, y)
    for _ in range(wait//50): await pg.clock.run_for(50)
    return 'ok'
async def wheel(dy, n=1, x=180, y=320):
    pg = G['pg']; await pg.mouse.move(x, y)
    for _ in range(n): await pg.mouse.wheel(0, dy); await pg.clock.run_for(50)
    for _ in range(20): await pg.clock.run_for(50)
    return 'ok'
async def run(ms):
    pg = G['pg']
    for _ in range(ms//50): await pg.clock.run_for(50)
    return 'ok'
async def pages(n, dy=500, path='/tmp/p.png', x=180, y=320):
    from PIL import Image
    ims=[]
    for i in range(n):
        await G['pg'].screenshot(path='/tmp/full.png'); ims.append(Image.open('/tmp/full.png').resize((360,640)))
        if i<n-1: await wheel(100, dy, x, y)
    out=Image.new('RGB',(360*n+8*(n-1),640),(255,0,0))
    for i,im in enumerate(ims): out.paste(im,(i*368,0))
    out.save(path); return path
SEM_JS = '''(()=>{const out=[];document.querySelectorAll('flt-semantics').forEach(e=>{const r=e.getBoundingClientRect();
 let t=(e.getAttribute('aria-label')||'')+' '+([...e.childNodes].filter(n=>n.nodeType==3).map(n=>n.textContent).join(''));
 t=t.trim(); if(!t||r.width==0||r.y>640||r.y+r.height<0)return; out.push([Math.round(r.x+r.width/2),Math.round(r.y+r.height/2),Math.round(r.width),Math.round(r.height),e.getAttribute('role')||'',t.slice(0,60)]);});
 return out.map(o=>o.join(' | ')).join('\\n');})()'''
async def sem():
    pg=G['pg']
    if not await pg.evaluate("!!document.querySelector('flt-semantics')"):
        await pg.evaluate("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click();})()")
        await run(500)
    return await pg.evaluate(SEM_JS)
async def handle(req):
    code = req.query['code']
    try:
        env = dict(sem=sem, pages=pages, G=G, start=start, shot=shot, click=click, wheel=wheel, run=run, pg=G.get('pg'))
        exec('async def __f():\n return (' + code + ')', env)
        r = await env['__f']()
        return web.Response(text=str(r))
    except Exception:
        return web.Response(text=traceback.format_exc())
async def main():
    async with async_playwright() as p:
        G['p'] = p
        app = web.Application(); app.router.add_get('/c', handle)
        r = web.AppRunner(app); await r.setup(); await web.TCPSite(r, 'localhost', 9000).start()
        print('ready', flush=True); await asyncio.Event().wait()
asyncio.run(main())
