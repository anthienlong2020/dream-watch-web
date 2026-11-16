"""M0: transparent pendulum clock, whole movement, slow orbit + push-in (4 s). Plays before M1 Tourbillon."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from rec2 import record

URL = 'http://localhost:8090/movement/?clean'
START = '2026-11-16T10:08:25'
STORE = {'mvSpin': '0', 'mvEsc': 'pendulum', 'mvSec': 'small', 'mvComp': '1'}

SETUP = r"""
(()=>{const m=mv, V=m.THREE.Vector3;
 m.controls.autoRotate=false; m.controls.enableDamping=false;
 const ss=x=>{x=Math.min(1,Math.max(0,x));return x*x*(3-2*x)};
 const D=Math.PI/180, dirAt=(az,el)=>new V(Math.sin(az)*Math.cos(el),Math.sin(el),Math.cos(az)*Math.cos(el));
 const T=m.TARGET.clone();
 window.__shot=t=>{const u=ss(t/4);
   const dir=dirAt((-28+40*u)*D,(6+6*u)*D), dist=640-90*u;
   m.controls.target.copy(T); m.camera.position.copy(T).add(dir.multiplyScalar(dist)); m.controls.update();};
 window.__shot(0);
})()
"""
async def setup(pg): await pg.evaluate(SETUP)
async def script(pg, t): await pg.evaluate(f'window.__shot({t})')
if __name__ == '__main__':
    asyncio.run(record('M0', URL, START, 4, script, setup=setup, storage=STORE))
