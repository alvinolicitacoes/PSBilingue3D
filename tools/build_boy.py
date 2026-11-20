"""Rigs the static 'cute boy' GLB onto a Mixamo-compatible skeleton fitted to his body,
re-using Mixamo clips (idle/walk/run/sit) in place, and authoring wave/cheer/jump clips."""
import sys, json, struct, io
import numpy as np
from scipy.spatial.transform import Rotation as Rot
from PIL import Image
sys.path.insert(0, '/home/claude'); sys.path.insert(0, '/home/claude/tools')
from glbinfo import load
from render_glb import acc
from skin import Rig

ROOT = '/home/claude/proj/PSBilingue3D_Completo/assets/characters/'
BOY = ROOT + 'pietro/base_basic_shaded.glb'
CLIPS = {'idle': 'Breathing Idle.glb', 'walk': 'Walking.glb', 'run': 'Running.glb', 'sit': 'Sitting.glb'}

def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

def Rz(deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1.0]])

def q_of(R): return Rot.from_matrix(R).as_quat()
def R_of(q): return Rot.from_quat(q).as_matrix()
def qmul(a, b): return (Rot.from_quat(a) * Rot.from_quat(b)).as_quat()

# ---------------------------------------------------------------- skeleton ----
base = Rig(ROOT + 'animated/Walking.glb')
bjs = base.js
JN = [bjs['nodes'][j]['name'].replace('mixamorig:', '') for j in base.joints]
K = {n: i for i, n in enumerate(JN)}
par = []
for j in base.joints:
    p = base.parent.get(j)
    par.append(base.joints.index(p) if p in base.joints else -1)
Wb = base.world(base.rest_local())
RwT = [Wb[j][:3, :3] / 0.01 for j in base.joints]               # mannequin T-pose world rotations
arm_node = [i for i, n in enumerate(bjs['nodes']) if n['name'] == 'Armature'][0]
qArm = np.array(bjs['nodes'][arm_node]['rotation'])
RArm = R_of(qArm)

TH = 37.9  # arm angle below horizontal of the boy's A-pose
RlocT = [(RwT[par[k]].T @ RwT[k]) if par[k] >= 0 else RwT[k] for k in range(len(JN))]
Rloc = [m.copy() for m in RlocT]
for side, sgn in (('Left', -1), ('Right', +1)):
    k = K[side + 'Arm']
    RwA = Rz(sgn * TH) @ RwT[k]
    Rloc[k] = RwT[K[side + 'Shoulder']].T @ RwA
RwN = [None] * len(JN)
for k in range(len(JN)):
    RwN[k] = (RwN[par[k]] @ Rloc[k]) if par[k] >= 0 else Rloc[k]

# fitted joint positions (metres, world, bind) -------------------------------
Z0 = 0.04
pos = {
    'Hips': (0, -0.04, Z0), 'Spine': (0, 0.05, Z0 + .005), 'Spine1': (0, 0.17, Z0 + .005), 'Spine2': (0, 0.29, Z0),
    'Neck': (0, 0.38, 0.03), 'Head': (0, 0.46, 0.03), 'HeadTop_End': (0, 0.93, 0.05),
}
dvec = np.array([0.789, -0.615, -0.008]); dvec /= np.linalg.norm(dvec)
S = np.array([0.235, 0.23, -0.005])
for side, sx in (('Left', 1), ('Right', -1)):
    m = np.array([sx, 1, 1.0])
    pos[side + 'Shoulder'] = tuple(np.array([0.05, 0.32, 0.03]) * m)
    pos[side + 'Arm'] = tuple(S * m)
    pos[side + 'ForeArm'] = tuple((S + dvec * 0.20) * m)
    pos[side + 'Hand'] = tuple((S + dvec * 0.40) * m)
    for i, off in enumerate((0.47, 0.50, 0.52, 0.54), 1):
        pos[f'{side}HandIndex{i}'] = tuple((S + dvec * off) * m)
    pos[side + 'UpLeg'] = tuple(np.array([0.093, -0.097, 0.04]) * m)
    pos[side + 'Leg'] = tuple(np.array([0.135, -0.47, 0.02]) * m)
    pos[side + 'Foot'] = tuple(np.array([0.174, -0.79, 0.0]) * m)
    pos[side + 'ToeBase'] = tuple(np.array([0.20, -0.93, 0.13]) * m)
    pos[side + 'Toe_End'] = tuple(np.array([0.215, -0.95, 0.22]) * m)
PW = [np.array(pos[n], float) for n in JN]
tloc = []
for k in range(len(JN)):
    tloc.append(RwN[par[k]].T @ (PW[k] - PW[par[k]]) if par[k] >= 0 else PW[k])
Wrest = []
for k in range(len(JN)):
    M = np.eye(4); M[:3, :3] = RwN[k]; M[:3, 3] = PW[k]; Wrest.append(M)
IBM = np.array([np.linalg.inv(M) for M in Wrest])

# ---------------------------------------------------------------- boy mesh ----
bjs_boy, bb = load(BOY)
pr = bjs_boy['meshes'][0]['primitives'][0]
P = acc(bjs_boy, bb, pr['attributes']['POSITION']).astype(float)
N = acc(bjs_boy, bb, pr['attributes']['NORMAL']).astype(np.float32)
UV = acc(bjs_boy, bb, pr['attributes']['TEXCOORD_0']).astype(np.float32)
IDX = acc(bjs_boy, bb, pr['indices']).reshape(-1).astype(np.uint32)
imv = bjs_boy['bufferViews'][bjs_boy['images'][0]['bufferView']]
TEX = Image.open(io.BytesIO(bb[imv.get('byteOffset', 0):imv.get('byteOffset', 0) + imv['byteLength']])).convert('RGB')

def compute_weights(P):
    n = len(P); x, y, z = P[:, 0], P[:, 1], P[:, 2]
    W = np.zeros((n, len(JN)))
    # torso hat weights along y
    chain = ['Hips', 'Spine', 'Spine1', 'Spine2', 'Neck', 'Head']
    hy = [pos[c][1] for c in chain]
    torso = np.zeros((n, len(JN)))
    for i in range(n):
        pass
    yy = np.clip(y, hy[0], hy[-1])
    for a in range(len(chain) - 1):
        m = (yy >= hy[a]) & (yy <= hy[a + 1])
        t = (yy[m] - hy[a]) / (hy[a + 1] - hy[a])
        torso[m, K[chain[a]]] += 1 - t
        torso[m, K[chain[a + 1]]] += t
    sideL = smooth(-0.02, 0.02, x)
    arm_tot = np.zeros(n); arm_w = np.zeros((n, len(JN)))
    for side, sx in (('Left', 1), ('Right', -1)):
        xm = x * sx
        v = np.stack([xm, y, z], 1) - S
        t = v @ dvec
        dist = np.linalg.norm(v - np.outer(t, dvec), axis=1)
        r0 = 0.062 + 0.06 * smooth(0.30, 0.45, t)
        amt = (1 - smooth(r0, r0 + 0.04, dist)) * smooth(-0.02, 0.07, t) * (xm > 0.05) * (y > -0.3)
        amt = np.maximum(amt, smooth(0.28, 0.34, xm) * (y > -0.3) * (y < 0.4))
        wA = 1 - smooth(0.17, 0.23, t)
        wF = smooth(0.17, 0.23, t) * (1 - smooth(0.37, 0.43, t))
        wH = smooth(0.37, 0.43, t)
        arm_w[:, K[side + 'Arm']] += amt * wA
        arm_w[:, K[side + 'ForeArm']] += amt * wF
        arm_w[:, K[side + 'Hand']] += amt * wH
        arm_tot += amt
    arm_tot = np.clip(arm_tot, 0, 1)
    leg_w = np.zeros((n, len(JN))); leg_tot = np.zeros(n)
    base_leg = smooth(-0.05, -0.18, y) * (1 - arm_tot) * (1 - smooth(0.26, 0.34, np.abs(x)) * (y > -0.35))
    wUp = 1 - smooth(-0.43, -0.51, y)
    wLg = smooth(-0.43, -0.51, y) * (1 - smooth(-0.76, -0.82, y))
    wFt = smooth(-0.76, -0.82, y)
    for side, sgn in (('Left', sideL), ('Right', 1 - sideL)):
        a = base_leg * sgn
        leg_w[:, K[side + 'UpLeg']] += a * wUp
        leg_w[:, K[side + 'Leg']] += a * wLg
        leg_w[:, K[side + 'Foot']] += a * wFt
        leg_tot += a
    leg_tot = np.clip(leg_tot, 0, 1)
    rest = np.clip(1 - arm_tot - leg_tot, 0, 1)
    W = arm_w + leg_w + torso * rest[:, None]
    # keep top 4
    idx = np.argsort(-W, axis=1)[:, :4]
    top = np.take_along_axis(W, idx, 1)
    top /= np.maximum(top.sum(1, keepdims=True), 1e-9)
    return idx.astype(np.uint8), top.astype(np.float32)

JOINTS, WEIGHTS = compute_weights(P)

# --------------------------------------------------------------- animation ---
def clip_tracks(fname, keep_forward):
    r = Rig(ROOT + 'animated/' + fname)
    tr = r.anim_tracks()
    rot = {}; times = None
    for k, j in enumerate(base.joints):
        if (j, 'rotation') in tr:
            t, o = tr[(j, 'rotation')]
            o = o.copy()
            if JN[k] == 'Hips':
                o = np.array([qmul(qArm, q) for q in o])
            rot[k] = o
            times = t if times is None or len(t) > len(times) else times
    t0 = times[0]
    times = times - t0
    ht, ho = tr[(base.joints[0], 'translation')]
    wt = 0.01 * (ho @ RArm.T)                                    # to metres, world axes
    wt[:, 0] -= wt[:, 0].mean()
    wt[:, 0] *= 0.6
    wt[:, 0] += pos['Hips'][0]
    if keep_forward:                                             # sit: preserve relative z shift
        wt[:, 2] = pos['Hips'][2] + (wt[:, 2] - wt[0, 2])
    else:
        wt[:, 2] = pos['Hips'][2]
    return times, rot, wt

SKIP = ('HandIndex', 'Toe_End', 'HeadTop_End')
ANIMS = {}
for name, f in CLIPS.items():
    ANIMS[name] = clip_tracks(f, keep_forward=(name == 'sit'))

# ---- authored clips (built from the idle pose) ---------------------------------
def pose_world(qs):
    Rw = [None] * len(JN)
    for k in range(len(JN)):
        Rl = R_of(qs[k])
        Rw[k] = (Rw[par[k]] @ Rl) if par[k] >= 0 else Rl
    return Rw

idle_t, idle_rot, idle_hips = ANIMS['idle']
pose0 = {k: idle_rot[k][0] for k in idle_rot}
for k in range(len(JN)):
    if k not in pose0: pose0[k] = q_of(Rloc[k])

def author(name, dur, fps, arm_fn, hips_fn, spine_fn=None):
    n = int(dur * fps)
    times = np.arange(n) / fps
    rot = {k: np.tile(pose0[k], (n, 1)) for k in pose0}
    hips = np.zeros((n, 3))
    for i in range(n):
        t = times[i]
        qs = {k: pose0[k].copy() for k in pose0}
        if spine_fn:
            for kn, R in spine_fn(t).items():
                qs[K[kn]] = q_of(R_of(qs[K[kn]]) @ R)
        Rw = pose_world(qs)
        for side, sgn in (('Left', 1), ('Right', -1)):
            th, ph = arm_fn(t, side)
            ka, kf = K[side + 'Arm'], K[side + 'ForeArm']
            if th is None:
                continue
            Rarm = Rz(sgn * th) @ RwT[ka]
            Rfore = Rz(sgn * (th + ph)) @ RwT[kf]
            Rsh = Rw[K[side + 'Shoulder']]
            qs[ka] = q_of(Rsh.T @ Rarm)
            qs[kf] = q_of(Rarm.T @ Rfore)
        for k in qs: rot[k][i] = qs[k]
        hips[i] = hips_fn(t)
    return times, rot, hips

hx, hy0, hz = pos['Hips']
H0 = float(idle_hips[0, 1])
ANIMS['wave'] = author('wave', 2.0, 30,
    lambda t, s: ((88 + 4 * np.sin(2 * np.pi * 1.0 * t)), 30 * np.sin(2 * np.pi * 2.5 * t)) if s == 'Right' else (None, None),
    lambda t: (hx, H0, hz))
ANIMS['cheer'] = author('cheer', 1.2, 30,
    lambda t, s: (68 + 8 * np.sin(2 * np.pi * 2.5 * t + (0 if s == 'Left' else np.pi)), 6 * np.sin(2 * np.pi * 2.5 * t)),
    lambda t: (hx, H0 + 0.07 * abs(np.sin(2 * np.pi * 1.25 * t)) - 0.03, hz),
    lambda t: {'Spine1': Rot.from_euler('z', 3 * np.sin(2 * np.pi * 1.25 * t), degrees=True).as_matrix()})
ANIMS['jump'] = author('jump', 0.7, 30,
    lambda t, s: (20 + 40 * np.sin(np.pi * min(t / 0.5, 1)), 6),
    lambda t: (hx, H0 - 0.12 * (1 - smooth(0.0, 0.18, t)) + 0.10 * smooth(0.15, 0.3, t), hz))

# --------------------------------------------------------------- glTF write --
class Buf:
    def __init__(self):
        self.data = bytearray(); self.views = []; self.accs = []
    def view(self, raw, target=None):
        while len(self.data) % 4: self.data += b'\0'
        v = {'buffer': 0, 'byteOffset': len(self.data), 'byteLength': len(raw)}
        if target: v['target'] = target
        self.data += raw; self.views.append(v); return len(self.views) - 1
    def acc(self, arr, ctype, atype, target=None, minmax=False):
        dt = {5126: '<f4', 5125: '<u4', 5121: 'u1', 5123: '<u2'}[ctype]
        a = np.ascontiguousarray(arr.astype(dt))
        vi = self.view(a.tobytes(), target)
        d = {'bufferView': vi, 'componentType': ctype, 'count': int(len(a)), 'type': atype}
        if minmax:
            d['min'] = [float(v) for v in a.reshape(len(a), -1).min(0)]
            d['max'] = [float(v) for v in a.reshape(len(a), -1).max(0)]
        self.accs.append(d); return len(self.accs) - 1

B = Buf()
a_pos = B.acc(P, 5126, 'VEC3', 34962, True)
a_nrm = B.acc(N, 5126, 'VEC3', 34962)
a_uv = B.acc(UV, 5126, 'VEC2', 34962)
a_jt = B.acc(JOINTS, 5121, 'VEC4', 34962)
a_wt = B.acc(WEIGHTS, 5126, 'VEC4', 34962)
a_ix = B.acc(IDX, 5125, 'SCALAR', 34963)
a_ibm = B.acc(np.array([m.T.reshape(16) for m in IBM]), 5126, 'MAT4')
buf = io.BytesIO(); TEX.resize((1024, 1024), Image.LANCZOS).save(buf, 'JPEG', quality=92)
img_view = B.view(buf.getvalue())

nodes = []
for k in range(len(JN)):
    q = q_of(Rloc[k]) if par[k] >= 0 else q_of(Rloc[k])
    nd = {'name': JN[k], 'translation': [float(v) for v in tloc[k]], 'rotation': [float(v) for v in q]}
    ch = [c for c in range(len(JN)) if par[c] == k]
    if ch: nd['children'] = ch
    nodes.append(nd)
nodes.append({'name': 'PietroMesh', 'mesh': 0, 'skin': 0})
GLB_ANIMS = []
for name, (times, rot, hips) in ANIMS.items():
    samplers = []; channels = []
    ti = B.acc(times.astype(np.float32).reshape(-1, 1)[:, 0], 5126, 'SCALAR', None, True)
    def add(node, path, arr, typ):
        ai = B.acc(arr, 5126, typ)
        samplers.append({'input': ti, 'output': ai, 'interpolation': 'LINEAR'})
        channels.append({'sampler': len(samplers) - 1, 'target': {'node': node, 'path': path}})
    for k, arr in rot.items():
        if any(s in JN[k] for s in SKIP): continue
        if len(arr) != len(times):
            continue
        add(k, 'rotation', arr, 'VEC4')
    add(0, 'translation', hips, 'VEC3')
    lname = {'idle': 'idle-loop', 'walk': 'walk-loop', 'run': 'run-loop', 'sit': 'sit', 'wave': 'wave-loop',
             'cheer': 'cheer-loop', 'jump': 'jump'}[name]
    GLB_ANIMS.append({'name': lname, 'samplers': samplers, 'channels': channels})

gl = {
    'asset': {'version': '2.0', 'generator': 'PSBilingue rig builder'},
    'extensionsUsed': ['KHR_materials_unlit'],
    'scene': 0, 'scenes': [{'nodes': [0, len(JN)]}],
    'nodes': nodes,
    'meshes': [{'name': 'Pietro', 'primitives': [{'attributes': {'POSITION': a_pos, 'NORMAL': a_nrm, 'TEXCOORD_0': a_uv, 'JOINTS_0': a_jt, 'WEIGHTS_0': a_wt}, 'indices': a_ix, 'material': 0}]}],
    'materials': [{'name': 'PietroMat', 'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'metallicFactor': 0.0, 'roughnessFactor': 1.0}, 'extensions': {'KHR_materials_unlit': {}}, 'doubleSided': True}],
    'textures': [{'sampler': 0, 'source': 0}], 'samplers': [{'magFilter': 9729, 'minFilter': 9987}],
    'images': [{'bufferView': img_view, 'mimeType': 'image/jpeg'}],
    'skins': [{'inverseBindMatrices': a_ibm, 'joints': list(range(len(JN))), 'skeleton': 0}],
    'animations': GLB_ANIMS,
    'accessors': B.accs, 'bufferViews': B.views, 'buffers': [{'byteLength': len(B.data)}],
}
js_bytes = json.dumps(gl, separators=(',', ':')).encode()
js_bytes += b' ' * ((4 - len(js_bytes) % 4) % 4)
bin_bytes = bytes(B.data) + b'\0' * ((4 - len(B.data) % 4) % 4)
out = '/home/claude/out/pietro_rigged.glb'
import os; os.makedirs('/home/claude/out', exist_ok=True)
with open(out, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js_bytes) + 8 + len(bin_bytes)))
    f.write(struct.pack('<II', len(js_bytes), 0x4E4F534A)); f.write(js_bytes)
    f.write(struct.pack('<II', len(bin_bytes), 0x004E4942)); f.write(bin_bytes)
print('wrote', out, os.path.getsize(out) // 1024, 'KB; anims', [(a['name'], len(a['channels'])) for a in GLB_ANIMS])
