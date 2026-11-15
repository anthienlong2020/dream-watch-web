import sys
from PIL import Image
# stitch.py out H top_png bottom_png bottom_offset
out,Hh,a,b,off=sys.argv[1],int(sys.argv[2]),sys.argv[3],sys.argv[4],int(sys.argv[5])
A,B=Image.open(a).convert('RGB'),Image.open(b).convert('RGB')
c=Image.new('RGB',(A.width,Hh)); c.paste(B,(0,off)); c.paste(A.crop((0,0,A.width,min(A.height,off+20))),(0,0)); c.save(out,quality=95); print(out,c.size)
