import numpy as np, os
from scipy import signal
from scipy.io import wavfile
SR = 22050
OUT = '/home/claude/out/audio/'
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

def t_(d): return np.arange(int(d * SR)) / SR
def env(n, a=0.005, d=0.1, s=0.0, r=0.05, hold=None):
    """simple ADSR over n samples; exponential decay to s"""
    e = np.zeros(n); na = max(1, int(a * SR)); nd = int(d * SR)
    e[:na] = np.linspace(0, 1, na)
    k = np.arange(n - na)
    e[na:] = s + (1 - s) * np.exp(-k / max(1, nd / 4.0))
    nr = min(n, max(1, int(r * SR)))
    e[-nr:] *= np.linspace(1, 0, nr)
    return e
def sine(f, d, ph=0): t = t_(d); return np.sin(2 * np.pi * f * t + ph)
def tri(f, d): t = t_(d); return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * t))
def noise(d): return rng.standard_normal(int(d * SR))
def bp(x, lo, hi, o=2): b, a = signal.butter(o, [lo / (SR / 2), hi / (SR / 2)], 'band'); return signal.lfilter(b, a, x)
def lp(x, f, o=2): b, a = signal.butter(o, f / (SR / 2)); return signal.lfilter(b, a, x)
def hp(x, f, o=2): b, a = signal.butter(o, f / (SR / 2), 'high'); return signal.lfilter(b, a, x)
def norm(x, peak=0.8): m = np.max(np.abs(x)) + 1e-9; return x / m * peak
def save(name, x, peak=0.8):
    x = norm(np.nan_to_num(x), peak)
    wavfile.write(OUT + name + '.wav', SR, (x * 32767).astype(np.int16))
def mix(*parts, n=None):
    n = n or max(len(p[1]) + int(p[0] * SR) for p in parts)
    o = np.zeros(n)
    for off, x in parts:
        i = int(off * SR); o[i:i + len(x)] += x[:max(0, n - i)]
    return o
def bell(f, d=0.6, vol=1.0, bright=1.0):
    t = t_(d); mod = bright * 2.0 * np.exp(-t * 6)
    x = np.sin(2 * np.pi * f * t + mod * np.sin(2 * np.pi * f * 3.5 * t))
    x += 0.3 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 8)
    return vol * x * env(len(t), 0.003, d * 0.8, 0, 0.05)
def marimba(f, d=0.45, vol=1.0):
    t = t_(d)
    x = np.sin(2 * np.pi * f * t) + 0.45 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 30) + 0.2 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t * 60)
    return vol * x * np.exp(-t * 7) * env(len(t), 0.002, d, 1, 0.03)
def pluck(f, d=0.8, vol=1.0, decay=0.994):
    N = int(SR / f); n = int(d * SR)
    x = np.zeros(n); x[:N] = rng.uniform(-1, 1, N) * np.hanning(N) ** 0.3
    a = np.zeros(N + 2); a[0] = 1; a[N] = -decay / 2; a[N + 1] = -decay / 2
    y = signal.lfilter([1], a, x)
    return vol * lp(y, 3500) * env(n, 0.001, d, 1, 0.08)
def pad(f, d, vol=1.0):
    t = t_(d); x = sum(np.sin(2 * np.pi * f * m * t + p) for m, p in ((1, 0), (1.003, 1), (2, 2)) ) / 3
    return vol * x * env(len(t), 0.25, d, 0.9, 0.3)
def bass(f, d, vol=1.0):
    t = t_(d); x = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t)
    return vol * x * env(len(t), 0.01, d * 0.9, 0.3, 0.06)
def hz(n): return 440.0 * 2 ** ((n - 69) / 12.0)
NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
def m(name):  # e.g. 'C5', 'F#4'
    n = NOTE[name[0]]; i = 1
    if name[1] == '#': n += 1; i = 2
    elif name[1] == 'b': n -= 1; i = 2
    return 12 * (int(name[i:]) + 1) + n

# ------------------------------------------------------------------ steps ----
for i in range(3):
    d = 0.09; x = bp(noise(d), 250 + 80 * i, 1400 + 200 * i) * env(int(d * SR), 0.002, 0.05, 0, 0.03)
    save(f'step_grass_{i + 1}', x, 0.35)
for i in range(3):
    d = 0.07; x = sine(150 + 25 * i, d) * env(int(d * SR), 0.001, 0.05, 0, 0.02) + 0.7 * hp(noise(d), 1200) * env(int(d * SR), 0.0005, 0.02, 0, 0.02)
    save(f'step_pave_{i + 1}', x, 0.35)
# jump / land
t = t_(0.22); f = 320 + 520 * (t / 0.22) ** 0.7
save('jump', np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.005, 0.2, 0, 0.06) * (1 + 0.15 * np.sin(2 * np.pi * 30 * t)), 0.55)
save('land', sine(95, 0.16) * env(int(0.16 * SR), 0.001, 0.12, 0, 0.04), 0.6)
# ------------------------------------------------------------- UI / reward ----
save('click', sine(880, 0.05) * env(int(0.05 * SR), 0.001, 0.04, 0, 0.01) * np.linspace(1, 0.6, int(0.05 * SR)), 0.5)
save('back', sine(520, 0.07) * env(int(0.07 * SR), 0.001, 0.05, 0, 0.02), 0.5)
t = t_(0.3); save('open', bp(noise(0.3), 400, 3000) * np.sin(np.pi * t / 0.3) ** 2 + 0.3 * sine(300 + 600 * t / 0.3, 0.3) * np.sin(np.pi * t / 0.3), 0.4)
save('star', mix(*[(i * 0.07, bell(hz(m(n)), 0.55, 1.0)) for i, n in enumerate(['E6', 'G6', 'C7', 'E7'])]), 0.6)
save('coin', mix((0, bell(hz(m('B5')), 0.12, 1)), (0.07, bell(hz(m('E6')), 0.5, 1))), 0.55)
save('correct', mix(*[(i * 0.11, marimba(hz(m(n)), 0.5)) for i, n in enumerate(['C5', 'E5', 'G5', 'C6'])]), 0.65)
save('wrong', mix((0, tri(hz(m('G4')), 0.22) * env(int(.22 * SR), .01, .2, 0, .05)), (0.18, tri(hz(m('D4')), 0.35) * env(int(.35 * SR), .01, .3, 0, .08))), 0.45)
fan = [(0, 'C5', .18), (.16, 'E5', .18), (.32, 'G5', .18), (.48, 'C6', .5), (.8, 'G5', .15), (.95, 'C6', .15), (1.1, 'E6', .8)]
parts = [(o, marimba(hz(m(n)), d + .5)) for o, n, d in fan] + [(1.1, bell(hz(m('C6')), 1.2, .5)), (1.1, bell(hz(m('G6')), 1.2, .4))]
parts += [(1.1 + i * .05, bell(hz(m(n)), .6, .5)) for i, n in enumerate(['C7', 'E7', 'G7', 'C8'])]
save('win', mix(*parts), 0.7)
save('levelup', mix(*[(i * 0.09, bell(hz(m(n)), 0.6, 1)) for i, n in enumerate(['C5', 'G5', 'C6', 'E6', 'G6', 'C7'])]), 0.6)
save('fail', mix(*[(i * 0.2, tri(hz(m(n)), .4) * env(int(.4 * SR), .02, .35, 0, .1)) for i, n in enumerate(['E4', 'D4', 'C4'])]), 0.4)
# cards / sudoku
t = t_(0.12); save('flip', bp(noise(0.12), 800, 5000) * np.sin(np.pi * t / 0.12) ** 2 * 0.6 + sine(1200, 0.12) * np.exp(-t * 60) * 0.5, 0.45)
save('match', mix((0, bell(hz(m('G5')), .4)), (0.1, bell(hz(m('D6')), .6))), 0.6)
save('mismatch', sine(180, 0.14) * env(int(.14 * SR), .003, .1, 0, .04) * np.linspace(1, .6, int(.14 * SR)), 0.5)
save('tick', (sine(760, 0.05) + .5 * bp(noise(.05), 1500, 4000)) * env(int(.05 * SR), .0005, .035, 0, .01), 0.5)
save('erase', bp(noise(0.12), 600, 3000) * np.linspace(1, 0, int(.12 * SR)), 0.35)
save('error', (tri(150, 0.25) + .3 * tri(153, .25)) * env(int(.25 * SR), .01, .2, 0, .05), 0.4)
save('hint', mix((0, bell(hz(m('A5')), .3)), (.12, bell(hz(m('E6')), .5)), (.24, bell(hz(m('A6')), .6))), 0.5)
t = t_(0.4); save('door', bp(noise(.4), 300, 4000) * np.sin(np.pi * t / .4) + .3 * sine(250 + 700 * (t / .4) ** 2, .4) * np.sin(np.pi * t / .4), 0.5)
save('pop', sine(500 + 400 * np.exp(-t_(0.08) * 60) , 0.08) * env(int(.08 * SR), .001, .05, 0, .02), 0.5)
save('heart', mix((0, bell(hz(m('E6')), .5)), (.08, bell(hz(m('B6')), .6, .8))), 0.5)
save('blip', sine(660, .05) * env(int(.05 * SR), .002, .04, 0, .01) + sine(990, .05) * env(int(.05 * SR), .002, .04, 0, .01) * .5, 0.4)
save('confetti', hp(noise(.25), 600) * env(int(.25 * SR), .001, .2, 0, .05), 0.6)
save('throw', bp(noise(.35), 500, 3500) * np.sin(np.pi * t_(.35) / .35) ** 1.5, 0.45)
x = np.zeros(int(.7 * SR))
for i, (o, g) in enumerate([(0, 1), (.2, .55), (.35, .3), (.45, .15)]):
    s = sine(260 - 20 * i, .1) * env(int(.1 * SR), .001, .08, 0, .02) * g; j = int(o * SR); x[j:j + len(s)] += s
save('bounce', x, 0.5)
save('honk', mix((0, (np.sign(sine(392, .22)) * .5 + sine(392, .22)) * env(int(.22 * SR), .01, .2, .6, .04)), (.2, (np.sign(sine(494, .3)) * .5 + sine(494, .3)) * env(int(.3 * SR), .01, .3, .6, .05))) * 0.5, 0.35)
def chirp(f0, f1, d, am=0):
    t = t_(d); f = f0 + (f1 - f0) * t / d; x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 0.7
    return x * (1 + am * np.sin(2 * np.pi * 40 * t))
for i, (a, b) in enumerate([(3200, 4600), (4500, 3000), (3800, 3800)]):
    save(f'bird_{i + 1}', mix((0, chirp(a, b, .09, .3)), (.12, chirp(b, a + 400, .1, .3)), (.26, chirp(a, b + 300, .08, .3))), 0.35)

# ------------------------------------------------------------------- bulldog --
def voiced(f0_curve, d, formants, noise_amt=0.15):
    n = int(d * SR); t = np.arange(n) / SR
    f0 = f0_curve(t); ph = np.cumsum(f0) / SR; saw = 2 * (ph % 1) - 1
    src = saw + noise_amt * noise(d)
    out = sum(g * bp(src, f - bw, f + bw) for f, bw, g in formants)
    return out
FM = [(700, 220, 1.0), (1500, 400, .7), (2600, 600, .3)]
def bark(f_start, f_peak, d, form=FM):
    cur = lambda t: f_start + (f_peak - f_start) * np.sin(np.pi * np.minimum(t / d, 1) * .5) - 60 * (t / d) ** 2
    x = voiced(cur, d, form) * env(int(d * SR), .004, d * .8, 0, .03)
    return lp(x, 4500)
save('bark1', bark(300, 380, .17))
save('bark2', bark(340, 440, .14, [(850, 250, 1), (1700, 450, .6), (2800, 600, .3)]))
b = bark(520, 700, .09, [(1000, 250, 1), (2100, 500, .6), (3000, 500, .3)])
save('bark_happy', mix((0, b), (.14, b * .9), (.28, bark(560, 760, .08, [(1000, 250, 1), (2100, 500, .6)]))))
save('woof', mix((0, bark(250, 300, .22)), (.3, bark(240, 280, .2))))
sn = bp(noise(.3), 300, 2500) * env(int(.3 * SR), .02, .25, 0, .08) * (1 + .5 * np.sin(2 * np.pi * 18 * t_(.3)))
save('snort', sn, 0.4)
t = t_(.5); f = 900 - 500 * (t / .5) ** .8; save('whimper', (voiced(lambda tt: 900 - 500 * (tt / .5) ** .8, .5, [(900, 250, 1), (1800, 400, .5)], .05) * np.sin(np.pi * t / .5)), 0.4)
t = t_(1.6); pant = bp(noise(1.6), 500, 3500) * (np.sin(2 * np.pi * 2.6 * t) ** 2); save('pant', pant, 0.25)
t = t_(.35); save('sniff', bp(noise(.35), 1000, 5000) * (np.sin(2 * np.pi * 7 * t) ** 2) * np.sin(np.pi * t / .35), 0.3)

# --------------------------------------------------------------- ambience -----
def loopify(x, xf=0.8):
    n = int(xf * SR); y = x[:-n].copy(); y[:n] = y[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n); return y
d = 18; n = int(d * SR)
wind = lp(noise(d), 500) * (0.6 + 0.4 * np.sin(2 * np.pi * t_(d) / 9.0 + 1)); wind = wind / np.max(np.abs(wind)) * 0.35
amb = wind.copy()
for _ in range(14):
    o = rng.uniform(0, d - 1); c = int(rng.integers(1, 4)); 
    x = mix((0, chirp(3000 + rng.uniform(-300, 500), 4500, .09, .3)), (.12, chirp(4400, 3200, .1, .3)), (.25, chirp(3300, 4800, .08, .3))) * rng.uniform(.06, .12)
    i = int(o * SR); amb[i:i + len(x)] += x[:max(0, n - i)]
save('ambient_city', loopify(amb), 0.45)
fz = hp(lp(noise(8), 5500), 700) * (0.8 + 0.2 * np.sin(2 * np.pi * t_(8) * 3.1)); save('fountain', loopify(fz, 0.6), 0.25)

# ------------------------------------------------------------------- music ----
def song(bpm, bars, chords, melody, kind, name, swing=0):
    beat = 60.0 / bpm; total = bars * 4 * beat; n = int((total + 1.5) * SR); o = np.zeros(n)
    def put(t, x): i = int(t * SR); o[i:i + len(x)] += x[:max(0, n - i)]
    for bi, ch in enumerate(chords * (bars // len(chords))):
        t0 = bi * 4 * beat; root = m(ch[0]); notes = [m(x) for x in ch[1:]]
        put(t0, bass(hz(root - 12), 1.6 * beat, .9)); put(t0 + 2 * beat, bass(hz(root - 12 + (7 if kind == 'city' else 0)), 1.6 * beat, .7))
        if kind == 'city':
            for k in range(8):
                put(t0 + k * beat / 2, marimba(hz(notes[k % 3] + 12 * (k % 3 == 2)), .35, .28))
            for k in range(8):
                put(t0 + k * beat / 2 + beat / 2 * 0.0, hp(noise(.05), 6000) * env(int(.05 * SR), .001, .03, 0, .01) * (0.12 if k % 2 else 0.2))
            put(t0 + 0, pad(hz(notes[0] + 12), 4 * beat, .18))
        else:
            for k in range(8):
                put(t0 + k * beat / 2, pluck(hz(notes[k % 3] if k % 4 else notes[0]), 1.2, .5))
            put(t0, pad(hz(notes[1]), 4 * beat, .14))
    for b0, nm, dur in melody:
        if kind == 'city': put(b0 * beat, marimba(hz(m(nm)) * 2, dur * beat + .3, .55) * 0.8 + 0.25 * bell(hz(m(nm)) * 2, dur * beat + .3, 0.4, .5))
        else: put(b0 * beat, bell(hz(m(nm)), dur * beat + .6, .5, .6))
    # loop: fold tail into head
    L = int(total * SR); y = o[:L].copy(); tail = o[L:]; y[:len(tail)] += tail[:L]
    save(name, y, 0.5)
C, Am, F, G = ['C3', 'E3', 'G3', 'C4'], ['A2', 'C3', 'E3', 'A3'], ['F2', 'A2', 'C3', 'F3'], ['G2', 'B2', 'D3', 'G3']
mel_city = [(0, 'E5', 1), (1, 'G5', 1), (2, 'A5', 1), (3, 'G5', 1),  (4, 'E5', 1), (5, 'C5', 1), (6, 'D5', 2),
            (8, 'C5', 1), (9, 'E5', 1), (10, 'A5', 1), (11, 'G5', 1), (12, 'F5', 1), (13, 'E5', 1), (14, 'D5', 2),
            (16, 'F5', 1), (17, 'A5', 1), (18, 'C6', 1), (19, 'A5', 1), (20, 'F5', 1), (21, 'A5', 1), (22, 'G5', 2),
            (24, 'G5', 1), (25, 'E5', 1), (26, 'D5', 1), (27, 'E5', 1), (28, 'C5', 4)]
song(104, 8, [C, Am, F, G], mel_city, 'city', 'music_city')
mel_quiz = [(0, 'E5', 2), (2, 'D5', 1), (3, 'C5', 1), (4, 'D5', 3), (8, 'G5', 2), (10, 'E5', 2), (12, 'C5', 4),
            (16, 'A5', 2), (18, 'G5', 1), (19, 'F5', 1), (20, 'E5', 3), (24, 'D5', 2), (26, 'B4', 2), (28, 'C5', 4)]
song(80, 8, [C, F, Am, G], mel_quiz, 'quiz', 'music_quiz')
print(len(os.listdir(OUT)), 'files', sum(os.path.getsize(OUT + f) for f in os.listdir(OUT)) // 1024, 'KB')
