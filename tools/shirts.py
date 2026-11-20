import sys,io,numpy as np,colorsys; sys.path.insert(0,'/home/claude')
from PIL import Image, ImageDraw
from glbinfo import load
from render_glb import acc
js,b=load('/home/claude/proj/PSBilingue3D_Completo/assets/characters/pietro/base_basic_shaded.glb')
pr=js['meshes'][0]['primitives'][0]
P=acc(js,b,pr['attributes']['POSITION']).astype(float); UV=acc(js,b,pr['attributes']['TEXCOORD_0']).astype(float)
idx=acc(js,b,pr['indices']).reshape(-1,3)
bv=js['bufferViews'][js['images'][0]['bufferView']]
tex=Image.open(io.BytesIO(b[bv['byteOffset']:bv['byteOffset']+bv['byteLength']])).convert('RGB')
W,H=tex.size; mask=Image.new('L',(W,H),0); d=ImageDraw.Draw(mask)
cy=P[idx][:,:,1].mean(1); cx=np.abs(P[idx][:,:,0]).mean(1)
sel=(cy>-0.14)&(cy<0.37)&(cx<0.46)
for t in np.where(sel)[0]:
    d.polygon([(UV[v][0]*W,UV[v][1]*H) for v in idx[t]],fill=255)
m=np.array(mask)>0
import scipy.ndimage as ndi
m=ndi.binary_dilation(m,iterations=2)
hsv=np.array(tex.convert('HSV')).astype(float)
h,s,v=hsv[...,0]/255*360,hsv[...,1]/255,hsv[...,2]/255
blue=m&(h>170)&(h<235)&(s>0.25)
print('shirt texels',blue.sum())
out='/home/claude/out/tex/'; import os; os.makedirs(out,exist_ok=True)
variants={'azul':None,'vermelha':355,'verde':120,'amarela':48,'roxa':280,'laranja':24,'rosa':322,'branca':'white'}
for name,hue in variants.items():
    im=hsv.copy()
    if hue=='white':
        im[...,1][blue]*=0.08; im[...,2][blue]=np.clip(im[...,2][blue]*1.35+30,0,255)
    elif hue is not None:
        cur=np.median(h[blue]); sh=(hue-cur)
        nh=(h[blue]+sh)%360; im[...,0][blue]=nh/360*255; im[...,1][blue]=np.clip(im[...,1][blue]*1.35,0,255); im[...,2][blue]=np.clip(im[...,2][blue]*1.12,0,255)
        if name=='amarela': im[...,2][blue]=np.clip(im[...,2][blue]*1.15,0,255)
    img=Image.fromarray(im.astype(np.uint8),'HSV').convert('RGB').resize((1024,1024),Image.LANCZOS)
    img.save(out+f'camisa_{name}.jpg',quality=90)
    print(name,os.path.getsize(out+f'camisa_{name}.jpg')//1024,'KB')
