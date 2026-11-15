import sys, glob
from PIL import Image
# sheet.py out.jpg files... (or a dir)
out=sys.argv[1]; fs=sys.argv[2:]
if len(fs)==1 and not fs[0].endswith('.jpg') and not fs[0].endswith('.png'): fs=sorted(glob.glob(fs[0]+'/*.jpg'))
ims=[Image.open(f).convert('RGB').resize((270,480)) for f in fs]
c=Image.new('RGB',(270*len(ims),480));[c.paste(im,(k*270,0)) for k,im in enumerate(ims)];c.save(out); print(Image.open(fs[0]).size)
