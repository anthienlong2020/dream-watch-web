import asyncio, sys
sys.path.insert(0, '/home/claude/hd/tools')
from hrec import Rec

PART = """(n=>{const m=mv,V=m.THREE.Vector3;const p=new V(m.P[n].x,m.P[n].y,-20);m.barrel.parent.localToWorld(p);p.project(m.camera);
 return [(p.x+1)/2*innerWidth,(1-p.y)/2*innerHeight];})"""
EL = "(id=>{const b=document.getElementById(id).getBoundingClientRect();return [b.x+b.width/2,b.y+b.height/2]})"

async def main():
    r = Rec('t11_steps'); await r.open(start='2026-11-18T10:09:30+07:00', extra={'mvSpin': '0'})
    pg = r.pg
    r.start(); await r.wait(0.5)
    r.cap('Vào Cài đặt, chọn mặt "Cơ khí"'); await r.tap(315, 607, post=1.0); await r.tapt('Cơ khí', post=1.0)
    r.cap('Về tab Đồng hồ'); await r.tap(45, 607, post=2.5)
    fr = [f for f in pg.frames if 'movement' in f.url][0]
    box = await (await fr.frame_element()).bounding_box()
    await fr.evaluate("mv.controls.autoRotate=false")
    async def el(i):
        x, y = await fr.evaluate(EL + f"('{i}')"); return round(box['x'] + x), round(box['y'] + y)
    async def part(n):
        x, y = await fr.evaluate(PART + f"('{n}')"); return round(box['x'] + x), round(box['y'] + y)
    r.cap('Kéo ngón tay để xoay'); await r.drag(110, 300, 210, 310, sec=1.6, post=1.0)
    r.cap('Chụm hai ngón để phóng to'); await r.scroll(-500, 1.6, x=180, y=260); await r.wait(1.0)
    r.mark('s3')
    r.cap('Bấm "Mặt sau" để nhìn bộ máy'); await r.tap(*(await el('bBack')), post=2.0)
    r.cap('Chạm tang cót: nơi giữ năng lượng'); await r.tap(*(await part('barrel')), post=3.5)
    r.cap('Chạm bánh thoát: chia thời gian thành từng giây'); await r.tap(*(await part('escape')), post=3.5)
    r.mark('s4')
    await fr.evaluate('mv.select(null)')
    r.cap('Bấm "Mặt trước", rồi "Tùy chọn"'); await r.tap(*(await el('bFront')), post=1.2); await r.tap(*(await el('bOpts')), post=1.0)
    r.cap('Bộ thoát: Quả lắc → Tourbillon'); await r.tap(*(await el('bEsc')), post=0.8); await r.tap(*(await el('bOpts')), post=0.3)
    await fr.evaluate('mv.select(null)'); await r.wait(3.2)
    r.mark('s5')
    r.cap('Đĩa ngày đêm & tuần trăng, đổi màu kim'); await r.tap(*(await el('bOpts')), post=0.8)
    await r.tap(*(await el('bComp')), post=1.0); await r.tap(*(await el('bComp')), post=1.0)
    await r.tap(*(await el('bHand')), post=0.8); await r.tap(*(await el('bOpts')), post=0.3)
    await fr.evaluate('mv.select(null)'); await r.wait(2.8)
    r.mark('s6')
    r.cap('Bấm "Tua nhanh": 1 phút bằng 12 tiếng'); xf = await el('bFast')
    await r.tap(*xf, post=1.2); await r.tap(*xf, post=5.0)
    await r.close()

if __name__ == "__main__": asyncio.run(main())
