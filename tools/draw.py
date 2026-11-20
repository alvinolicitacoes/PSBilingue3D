import numpy as np, math
from PIL import Image, ImageDraw
def draw_mesh(P, idx, uv, tex, out, az=0, el=0, size=500, center=None, ext=None, panel=None):
    c = center if center is not None else (P.min(0)+P.max(0))/2
    ex = ext if ext is not None else (P.max(0)-P.min(0)).max()
    a=math.radians(az); e=math.radians(el)
    Ry=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
    Rx=np.array([[1,0,0],[0,math.cos(e),-math.sin(e)],[0,math.sin(e),math.cos(e)]])
    R=Rx@Ry; Q=(P-c)@R.T
    tri=Q[idx]                                   # (T,3,3)
    n=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]); ln=np.linalg.norm(n,axis=1)+1e-12; n/=ln[:,None]
    vis=n[:,2]>0
    if tex is not None and uv is not None:
        u=uv[idx].mean(1); h,w=tex.shape[:2]
        col=tex[np.clip((u[:,1]*h).astype(int),0,h-1),np.clip((u[:,0]*w).astype(int),0,w-1)].astype(float)/255
    else: col=np.full((len(idx),3),0.8)
    sh=0.55+0.45*np.clip(n[:,2]*0.8+n[:,1]*0.4,0,1)
    col=np.clip(col*sh[:,None],0,1)
    order=np.argsort(tri[:,:,2].mean(1))
    S=size; im=Image.new('RGB',(S,S),(205,230,245)); d=ImageDraw.Draw(im); sc=S*0.9/ex
    for t in order:
        if not vis[t]: continue
        xy=[(S/2+q[0]*sc,S/2-q[1]*sc) for q in tri[t]]
        d.polygon(xy,fill=tuple((col[t]*255).astype(int)))
    return im
