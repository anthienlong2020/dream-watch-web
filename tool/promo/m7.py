"""M7: tap the barrel -> info card; then fast-forward x720 (6 s)."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from rec2 import record, TOUCH_JS

URL = 'http://localhost:8090/movement/?clean'
START = '2026-11-16T10:08:25'
STORE = {'mvSpin': '0', 'mvEsc': 'tourbillon', 'mvSec': 'center', 'mvComp': '1'}

SETUP = r"""
(()=>{const m=mv, V=m.THREE.Vector3;
 m.controls.autoRotate=false; m.controls.enableDamping=false; m.controls.minDistance=10;
 m.info.style.bottom='150px';
 const ss=x=>{x=Math.min(1,Math.max(0,x));return x*x*(3-2*x)};
 const D=Math.PI/180, dirAt=(az,el)=>new V(Math.sin(az)*Math.cos(el),Math.sin(el),Math.cos(az)*Math.cos(el));
 const tgt=new V(-4,-8,-20);
 window.__shot=t=>{
   const u=ss(t/6); const dir=dirAt((-14+30*u)*D,(10+4*u)*D); const dist=400-70*u;
   m.controls.target.copy(tgt); m.camera.position.copy(tgt).add(dir.multiplyScalar(dist)); m.controls.update();
 };
 window.__barrelXY=()=>{const p=new V(m.P.barrel.x,m.P.barrel.y,-20); m.barrel.parent.localToWorld(p); p.project(m.camera);
   return [(p.x+1)/2*innerWidth,(1-p.y)/2*innerHeight];};
 window.__shot(0);
})()
"""
state = {'tap': False, 'fast': False}

async def setup(pg):
    state.update(tap=False, fast=False)
    await pg.evaluate(SETUP)

async def script(pg, t):
    await pg.evaluate(f'window.__shot({t})')
    if t >= 0.7 and not state['tap']:
        state['tap'] = True
        xy = await pg.evaluate('window.__barrelXY()')
        await pg.evaluate(TOUCH_JS + '(%s)' % xy)
        await pg.evaluate('mv.select(mv.barrel)')
    if t >= 3.4 and not state['fast']:
        state['fast'] = True
        await pg.evaluate('mv.select(null); mv.fast(); mv.fast();')

if __name__ == '__main__':
    asyncio.run(record('M7', URL, START, 6, script, setup=setup, storage=STORE))
