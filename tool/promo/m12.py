"""M1 (0-3s Tourbillon close-up, dial hidden) + M2 (3-7s pull back, dial fades in) as one take."""
import asyncio, sys
sys.path.insert(0, '/home/claude/promo/scripts')
from rec2 import record

URL = 'http://localhost:8090/movement/?clean'
STORE = {'mvSpin': '0', 'mvEsc': 'tourbillon', 'mvSec': 'center', 'mvComp': '1'}

SETUP = r"""
(()=>{const m=mv, V=m.THREE.Vector3;
 m.controls.autoRotate=false; m.controls.minDistance=10; m.controls.enableDamping=false;
 const G=m.dial.children[0].material, G0=G.opacity, pm=m.dial.userData.print.material;
 const T1=new V(m.P.escape.x,m.P.escape.y,-13), T2=m.TARGET.clone();
 const ss=x=>{x=Math.min(1,Math.max(0,x));return x*x*(3-2*x)};
 const dirAt=(az,el)=>new V(Math.sin(az)*Math.cos(el),Math.sin(el),Math.cos(az)*Math.cos(el));
 const D=Math.PI/180, farDir=new V(0.45,0.12,1).normalize();
 window.__shot=t=>{
   let tgt,dir,dist;
   if(t<3){const u=t/3; dir=dirAt((22+16*u)*D,14*D); dist=68-10*u; tgt=T1;}
   else{const u=ss((t-3)/4); const d0=dirAt(38*D,14*D);
     dir=d0.clone().lerp(farDir,u).normalize(); dist=58*Math.pow(560/58,u); tgt=T1.clone().lerp(T2,u);}
   m.controls.target.copy(tgt); m.camera.position.copy(tgt).add(dir.multiplyScalar(dist)); m.controls.update();
   G.opacity=G0*ss((t-3.5)/2.5);
   m.dial.visible=t>4.3; pm.opacity=ss((t-4.3)/2.2);
 };
 window.__shot(0);
})()
"""

async def setup(pg):
    await pg.evaluate(SETUP)

async def script(pg, t):
    await pg.evaluate(f'window.__shot({t})')

if __name__ == '__main__':
    asyncio.run(record('M12', URL, '2026-11-16T10:08:25', 7, script, setup=setup, storage=STORE))
