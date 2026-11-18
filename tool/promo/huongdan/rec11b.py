import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools'); sys.path.insert(0, '/home/claude/hd/eps')
from hrec import Rec
from rec11 import PART, EL
async def main():
    r = Rec('t11_parts'); await r.open(start='2026-11-18T10:09:40+07:00', faceStyle='mech', extra={'mvSpin': '0'})
    fr = [f for f in r.pg.frames if 'movement' in f.url][0]
    box = await (await fr.frame_element()).bounding_box()
    async def el(i):
        x, y = await fr.evaluate(EL + f"('{i}')"); return round(box['x'] + x), round(box['y'] + y)
    async def part(n, dx):
        x, y = await fr.evaluate(PART + f"('{n}')"); return round(box['x'] + x + dx), round(box['y'] + y)
    r.start(); await r.wait(0.3)
    r.cap('Bấm "Mặt sau" để nhìn bộ máy'); await r.tap(*(await el('bBack')), post=2.0)
    r.cap('Chạm tang cót: nơi giữ năng lượng'); await r.tap(*(await part('barrel', 20)), post=3.8)
    r.cap('Chạm bánh thoát: chia thời gian thành từng giây'); await r.tap(*(await part('escape', 12)), post=0.0)
    print(await fr.evaluate("""(()=>{let o=null;mv.camera.parent;const sc=mv.barrel.parent; let root=sc; while(root.parent) root=root.parent;
      root.traverse(x=>{if(!o&&x.userData&&x.userData.info&&x.userData.info.name.startsWith('Bánh thoát'))o=x;}); if(o) mv.select(o); return o?o.userData.info.name:'none';})()"""))
    await r.wait(3.8)
    await r.close()
asyncio.run(main())
