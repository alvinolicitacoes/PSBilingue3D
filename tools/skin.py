import sys, math, numpy as np
sys.path.insert(0,'/home/claude')
from glbinfo import load
from render_glb import acc, nodemat, qmat
def tmat(t,r,s):
    M=np.eye(4); R=np.eye(4); R[:3,:3]=qmat(r); S=np.diag(list(s)+[1]); T=np.eye(4); T[:3,3]=t
    return T@R@S
class Rig:
    def __init__(self,path):
        self.js,self.b=load(path); js=self.js
        self.parent={}
        for i,n in enumerate(js['nodes']):
            for c in n.get('children',[]): self.parent[c]=i
        self.skin=js['skins'][0]; self.joints=self.skin['joints']
        self.ibm=acc(js,self.b,self.skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
        pr=js['meshes'][0]['primitives'][0]
        self.P=acc(js,self.b,pr['attributes']['POSITION']).astype(float)
        self.J=acc(js,self.b,pr['attributes']['JOINTS_0']).astype(int)
        self.W=acc(js,self.b,pr['attributes']['WEIGHTS_0']).astype(float)
        self.idx=acc(js,self.b,pr['indices']).reshape(-1,3)
        self.name2node={n['name']:i for i,n in enumerate(js['nodes'])}
    def world(self,local):
        W={}
        def w(i):
            if i in W: return W[i]
            p=self.parent.get(i)
            W[i]=(w(p) if p is not None else np.eye(4))@local[i]; return W[i]
        for i in range(len(self.js['nodes'])): w(i)
        return W
    def rest_local(self):
        return {i:nodemat(n) for i,n in enumerate(self.js['nodes'])}
    def anim_tracks(self,anim=0):
        js=self.js; a=js['animations'][anim]; tr={}
        for c in a['channels']:
            s=a['samplers'][c['sampler']]
            t=acc(js,self.b,s['input'])[:,0]; o=acc(js,self.b,s['output']).astype(float)
            tr[(c['target']['node'],c['target']['path'])]=(t,o)
        return tr
    def pose_local(self,tracks,time):
        loc=self.rest_local()
        nodes=self.js['nodes']
        tv={}
        for (ni,path),(t,o) in tracks.items():
            tt=min(max(time,t[0]),t[-1])
            k=np.searchsorted(t,tt); k=min(max(k,1),len(t)-1) if len(t)>1 else 0
            if len(t)>1:
                a=(tt-t[k-1])/max(t[k]-t[k-1],1e-9); v0,v1=o[k-1],o[k]
                if path=='rotation':
                    if np.dot(v0,v1)<0: v1=-v1
                    v=v0*(1-a)+v1*a; v/=np.linalg.norm(v)
                else: v=v0*(1-a)+v1*a
            else: v=o[0]
            tv.setdefault(ni,{})[path]=v
        for ni,d in tv.items():
            n=nodes[ni]
            loc[ni]=tmat(d.get('translation',n.get('translation',[0,0,0])),d.get('rotation',n.get('rotation',[0,0,0,1])),d.get('scale',n.get('scale',[1,1,1])))
        return loc
    def skinned(self,loc,meshnode=None):
        W=self.world(loc)
        mesh_node=[i for i,n in enumerate(self.js['nodes']) if 'skin' in n][0]
        inv_mesh=np.linalg.inv(W[mesh_node])
        JM=np.array([W[j]@self.ibm[k] for k,j in enumerate(self.joints)])
        Ph=np.c_[self.P,np.ones(len(self.P))]
        out=np.zeros((len(self.P),3))
        for k in range(4):
            M=JM[self.J[:,k]]
            out+=self.W[:,k:k+1]*np.einsum('nij,nj->ni',M,Ph)[:,:3]
        return out
