import numpy as np, math, sys
sys.path.insert(0,'/home/claude/tools')
from PIL import Image, ImageDraw
CAR=(0.80,0.54,0.27); CAR_L=(0.86,0.62,0.34); WHT=(0.98,0.95,0.90); BLK=(0.11,0.10,0.11); PNK=(0.94,0.47,0.55); EAR_IN=(0.90,0.66,0.58); EYE=(0.07,0.05,0.05)
# name, parent, pos, rot(deg xyz), size(x,y,z diameters; None=pivot), color, glossy
S=[]
def add(n,p,pos,size=None,col=None,rot=(0,0,0),g=0.0): S.append(dict(n=n,p=p,pos=pos,rot=rot,size=size,col=col,g=g))
add('Root',None,(0,0,0))
add('Body','Root',(0,0.28,0))
add('Torso','Body',(0,0.03,0.0),(0.35,0.32,0.44),CAR)
add('Rump','Body',(0,0.03,-0.14),(0.32,0.31,0.27),CAR)
add('Back','Body',(0,0.09,-0.02),(0.30,0.18,0.36),CAR_L)
add('Chest','Body',(0,-0.02,0.15),(0.33,0.30,0.24),WHT)
add('Belly','Body',(0,-0.075,-0.02),(0.22,0.10,0.34),WHT)
add('Neck','Body',(0,0.08,0.20),(0.26,0.22,0.18),CAR)
add('Head','Body',(0,0.15,0.26))
add('Skull','Head',(0,0.05,0.04),(0.41,0.33,0.31),CAR)
add('Brow','Head',(0,0.115,0.14),(0.30,0.07,0.12),CAR_L)
add('Blaze','Head',(0,0.10,0.175),(0.06,0.14,0.07),WHT)
add('CheekL','Head',(0.125,-0.015,0.12),(0.12,0.12,0.13),CAR)
add('CheekR','Head',(-0.125,-0.015,0.12),(0.12,0.12,0.13),CAR)
add('Muzzle','Head',(0,-0.005,0.205),(0.23,0.125,0.10),BLK,g=0.3)
add('FlewL','Head',(0.075,-0.03,0.19),(0.085,0.075,0.09),BLK,g=0.3)
add('FlewR','Head',(-0.075,-0.03,0.19),(0.085,0.075,0.09),BLK,g=0.3)
add('Nose','Head',(0,0.035,0.255),(0.085,0.05,0.035),BLK,g=0.9)
add('Jaw','Head',(0,-0.04,0.12))
add('JawMesh','Jaw',(0,-0.012,0.07),(0.14,0.04,0.13),BLK,g=0.3)
add('Tongue','Jaw',(0,0.0,0.095),(0.06,0.014,0.07),PNK)
add('EyeL','Head',(0.105,0.08,0.2),(0.062,0.072,0.03),EYE,g=0.9)
add('EyeR','Head',(-0.105,0.08,0.2),(0.062,0.072,0.03),EYE,g=0.9)
add('GlintL','Head',(0.095,0.097,0.218),(0.02,0.02,0.01),(1,1,1),g=0.9)
add('GlintR','Head',(-0.115,0.097,0.218),(0.02,0.02,0.01),(1,1,1),g=0.9)
add('EarL','Head',(0.135,0.17,0.02),None,None,(0,0,-16))
add('EarMeshL','EarL',(0.005,0.09,0),(0.13,0.21,0.05),CAR)
add('EarInL','EarL',(0.005,0.075,0.016),(0.085,0.15,0.02),EAR_IN)
add('EarR','Head',(-0.135,0.17,0.02),None,None,(0,0,16))
add('EarMeshR','EarR',(-0.005,0.09,0),(0.13,0.21,0.05),CAR)
add('EarInR','EarR',(-0.005,0.075,0.016),(0.085,0.15,0.02),EAR_IN)
for s,x in (('L',1),('R',-1)):
    add('LegF'+s,'Body',(0.115*x,-0.03,0.15))
    add('ArmF'+s,'LegF'+s,(0,-0.105,0),(0.12,0.22,0.125),CAR)
    add('PawF'+s,'LegF'+s,(0,-0.215,0.02),(0.105,0.07,0.14),WHT)
    add('LegB'+s,'Body',(0.12*x,-0.0,-0.15))
    add('ThighB'+s,'LegB'+s,(0,-0.06,0.0),(0.17,0.22,0.22),CAR)
    add('ShinB'+s,'LegB'+s,(0,-0.16,0.0),(0.10,0.14,0.10),CAR)
    add('PawB'+s,'LegB'+s,(0,-0.245,0.03),(0.105,0.065,0.15),WHT)
add('Tail','Body',(0,0.09,-0.27))
add('TailMesh','Tail',(0,0.01,-0.03),(0.055,0.055,0.10),CAR)
SPEC=S
def eul(r):
    x,y,z=[math.radians(a) for a in r]
    Rx=np.array([[1,0,0],[0,math.cos(x),-math.sin(x)],[0,math.sin(x),math.cos(x)]])
    Ry=np.array([[math.cos(y),0,math.sin(y)],[0,1,0],[-math.sin(y),0,math.cos(y)]])
    Rz=np.array([[math.cos(z),-math.sin(z),0],[math.sin(z),math.cos(z),0],[0,0,1]])
    return Ry@Rx@Rz     # Godot YXZ order
def world():
    W={}
    for p in SPEC:
        M=np.eye(4); M[:3,:3]=eul(p['rot']); M[:3,3]=p['pos']
        W[p['n']]=(W[p['p']]@M) if p['p'] else M
    return W
def sphere_mesh(nl=10,nm=16):
    v=[];f=[]
    for i in range(nl+1):
        th=math.pi*i/nl
        for j in range(nm):
            ph=2*math.pi*j/nm; v.append((math.sin(th)*math.cos(ph),math.cos(th),math.sin(th)*math.sin(ph)))
    for i in range(nl):
        for j in range(nm):
            a=i*nm+j;b=i*nm+(j+1)%nm;c=(i+1)*nm+j;d=(i+1)*nm+(j+1)%nm; f+= [(a,c,b),(b,c,d)]
    return np.array(v)*0.5,np.array(f)
def render(az,el=12,size=520,out=None):
    W=world(); V0,F0=sphere_mesh(); tris=[]
    for p in SPEC:
        if p['size'] is None: continue
        M=W[p['n']]; V=(V0*np.array(p['size']))@M[:3,:3].T+M[:3,3]
        for f in F0: tris.append((V[f],p['col'],p['g']))
    a=math.radians(az); e=math.radians(el)
    Ry=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]]); Rx=np.array([[1,0,0],[0,math.cos(e),-math.sin(e)],[0,math.sin(e),math.cos(e)]])
    R=Rx@Ry; c=np.array([0,0.28,0.05]); im=Image.new('RGB',(size,size),(205,230,245)); d=ImageDraw.Draw(im); sc=size*0.9/0.9
    P=[((t[0]-c)@R.T,t[1],t[2]) for t in tris]; P.sort(key=lambda t:t[0][:,2].mean())
    for v,col,g in P:
        n=np.cross(v[1]-v[0],v[2]-v[0]); l=np.linalg.norm(n)
        if l<1e-12: continue
        n/=l
        if n[2]<0: continue
        sh=0.55+0.45*max(0,n[2]*0.7+n[1]*0.5+n[0]*0.2)+g*0.15*max(0,n[2])**8
        d.polygon([(size/2+q[0]*sc,size*0.62-q[1]*sc) for q in v],fill=tuple(int(min(1,x*sh)*255) for x in col))
    return im
if __name__=='__main__':
    S_=Image.new('RGB',(1560,520))
    for i,az in enumerate((0,35,90)): S_.paste(render(az),(i*520,0))
    S_.save('/home/claude/prev/dog.png')
