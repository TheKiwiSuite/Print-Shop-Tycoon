"""Original music and sound effects for Print Shop Tycoon, written as code.

No samples and nothing downloaded: every sound is synthesized with numpy.
Run with Blender's bundled Python (a short CPU job, no rendering):
  blender -b --factory-startup --python make_audio.py -- --out <folder>
Writes 16-bit 32 kHz WAV files: music-<name>.wav (stereo) and sfx-<name>.wav (mono).
The music is then encoded to Ogg Vorbis with ffmpeg (see README.txt).
"""
import sys, math, wave, json, argparse
from pathlib import Path
import numpy as np

SR = 32000
TAU = 2 * math.pi
rng = np.random.default_rng(20261122)
NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
MAJOR = (0, 2, 4, 5, 7, 9, 11)


def pitch(name):
    """'F#5' or 'Bb4' -> MIDI note number."""
    letter, rest, acc = name[0], name[1:], 0
    while rest and rest[0] in '#b':
        acc += 1 if rest[0] == '#' else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + NOTE[letter] + acc


def hz(p):
    return 440.0 * 2 ** ((p - 69) / 12)


def ax(seconds):
    return np.arange(max(8, int(seconds * SR))) / SR


def fade(sig, attack=.003, release=.03):
    n = len(sig)
    a = min(n // 2, max(1, int(attack * SR)))
    r = min(n // 2, max(1, int(release * SR)))
    env = np.ones(n)
    env[:a] = np.linspace(0, 1, a)
    env[n - r:] *= np.linspace(1, 0, r)
    return sig * env


def partial(f, ratio, t):
    return np.sin(TAU * f * ratio * t) if f * ratio < SR * .45 else 0.0


# ---------- instruments: (frequency, seconds) -> mono samples ----------
_cache = {}


def cached(fn):
    def wrap(p, dur, vel=1.0):
        key = (fn.__name__, p, round(dur, 3))
        if key not in _cache:
            _cache[key] = fn(hz(p), dur)
        return _cache[key] * vel
    return wrap


@cached
def pluck(f, dur):
    """Nylon ukulele string: harmonics that fade faster the higher they are."""
    t = ax(min(1.6, dur + .5))
    out = np.zeros(len(t))
    for k in range(1, 10):
        out += (1 / k ** 1.2) * partial(f, k, t) * np.exp(-t * (2.6 + 1.7 * k))
    n = int(.01 * SR)
    out[:n] += rng.uniform(-1, 1, n) * np.linspace(.22, 0, n)
    return fade(out, .002, .05) * .8


@cached
def glock(f, dur):
    """Music box / glockenspiel bar."""
    t = ax(1.5)
    out = np.zeros(len(t))
    for ratio, amp, dec in ((1, 1, 4.2), (2.76, .32, 9), (5.4, .16, 15), (8.93, .07, 22)):
        out += amp * partial(f, ratio, t) * np.exp(-t * dec)
    return fade(out, .0015, .08) * .7


@cached
def marimba(f, dur):
    t = ax(.9)
    out = (partial(f, 1, t) * np.exp(-t * 7.5) + .26 * partial(f, 4, t) * np.exp(-t * 20)
           + .07 * partial(f, 9.2, t) * np.exp(-t * 34))
    n = int(.004 * SR)
    out[:n] += rng.uniform(-1, 1, n) * np.linspace(.18, 0, n)
    return fade(out, .0015, .05) * .85


@cached
def whistle(f, dur):
    t = ax(dur + .09)
    vib = 1 + .0045 * np.sin(TAU * 5.3 * t) * np.clip((t - .12) / .25, 0, 1)
    ph = TAU * np.cumsum(f * vib) / SR
    out = np.sin(ph) + .1 * np.sin(2 * ph) + .035 * np.sin(3 * ph)
    breath = np.convolve(rng.uniform(-1, 1, len(t)), np.ones(24) / 24, 'same') * .05
    env = np.minimum(1, t / .045) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 45))
    env *= .88 + .12 * np.exp(-t * 6)
    return (out + breath) * env * .6


@cached
def lead(f, dur):
    """Soft pulse lead: a chiptune flavour without the harsh edge."""
    t = ax(dur + .08)
    out = np.zeros(len(t))
    for k in range(1, 12, 2):
        out += partial(f, k, t) / k ** 1.5
    out += .25 * partial(f, 2, t)
    env = np.minimum(1, t / .008) * (.62 + .38 * np.exp(-t * 7)) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 60))
    return out * env * .5


@cached
def bass(f, dur):
    t = ax(dur + .08)
    out = np.sin(TAU * f * t) + .4 * np.sin(TAU * 2 * f * t) * np.exp(-t * 5) + .14 * np.sin(TAU * 3 * f * t) * np.exp(-t * 9)
    env = np.minimum(1, t / .006) * (.5 + .5 * np.exp(-t * 5)) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 50))
    return out * env * .9


@cached
def keys(f, dur):
    """Soft electric piano."""
    t = ax(dur + .4)
    idx = 1.6 * np.exp(-t * 6) + .25
    out = np.sin(TAU * f * t + idx * np.sin(TAU * f * t)) + .12 * partial(f, 4, t) * np.exp(-t * 14)
    env = np.minimum(1, t / .005) * np.exp(-t * 1.8) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 9))
    return out * env * .6


@cached
def pad(f, dur):
    t = ax(dur + .5)
    out = sum(np.sin(TAU * f * d * t) for d in (.997, 1.0, 1.003)) / 3 + .3 * np.sin(TAU * 2 * f * t)
    env = np.clip(t / .3, 0, 1) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 5))
    return out * env * .5


def kick():
    t = ax(.26)
    fr = 46 + 95 * np.exp(-t * 34)
    return fade(np.sin(TAU * np.cumsum(fr) / SR) * np.exp(-t * 13), .001, .03)


def shaker(length=.07):
    n = int(length * SR)
    x = np.diff(np.diff(rng.uniform(-1, 1, n + 2)))
    k = np.arange(n) / SR
    return x * np.minimum(1, k / .006) * np.exp(-k * 55) * .5


def wood():
    t = ax(.09)
    return fade(np.sin(TAU * 1040 * t) * np.exp(-t * 55) + .5 * np.sin(TAU * 1570 * t) * np.exp(-t * 75), .0008, .02) * .8


def rim():
    t = ax(.06)
    x = np.sin(TAU * 1750 * t) * np.exp(-t * 90) + .4 * np.diff(rng.uniform(-1, 1, len(t) + 1)) * np.exp(-t * 120)
    return fade(x, .0005, .01) * .7


def clap():
    n = int(.16 * SR)
    t = np.arange(n) / SR
    x = np.convolve(np.diff(rng.uniform(-1, 1, n + 1)), np.ones(5) / 5, 'same')
    env = np.zeros(n)
    for d in (0, .011, .022):
        s = int(d * SR)
        env[s:] = np.maximum(env[s:], np.exp(-t[:n - s] * 38))
    return x * env * .55


def ding():
    t = ax(1.1)
    return fade(np.sin(TAU * 2217 * t) * np.exp(-t * 4.5) + .4 * np.sin(TAU * 4434 * t) * np.exp(-t * 7), .001, .1) * .45


def brush():
    n = int(.2 * SR)
    t = np.arange(n) / SR
    x = np.convolve(np.diff(rng.uniform(-1, 1, n + 1)), np.ones(3) / 3, 'same')
    return x * np.sin(np.pi * t / .2) ** 2 * .3


# ---------- harmony helpers ----------
QUAL = {'': (0, 4, 7), 'm': (0, 3, 7), '7': (0, 4, 7, 10), 'm7': (0, 3, 7, 10), 'maj7': (0, 4, 7, 11)}


def chord(sym):
    acc, rest = 0, sym[1:]
    if rest[:1] in ('#', 'b'):
        acc, rest = (1 if rest[0] == '#' else -1), rest[1:]
    root = (NOTE[sym[0]] + acc) % 12
    return root, [(root + i) % 12 for i in QUAL[rest]]


def voicing(sym, low=57, count=4):
    """Close voicing: `count` chord tones rising from `low`."""
    _, pcs = chord(sym)
    out, p = [], low
    while len(out) < count:
        if p % 12 in pcs:
            out.append(p)
        p += 1
    return out


def root_at(sym, low):
    root, _ = chord(sym)
    p = low
    while p % 12 != root:
        p += 1
    return p


def third_below(p, key):
    """Diatonic third under a melody note, for a sweet harmony line."""
    rel = (p - key) % 12
    if rel not in MAJOR:
        return p - 3
    i = MAJOR.index(rel)
    j = (i - 2) % 7
    drop = (rel - MAJOR[j]) % 12
    return p - drop


def parse(bar):
    """'E5/.5 G5/.5 r/1 C6/2' -> [(beat, beats, midi or None)], and the bar must add up to 4."""
    out, at = [], 0.0
    for token in bar.split():
        name, dur = token.split('/')
        d = float(dur)
        out.append((at, d, None if name == 'r' else pitch(name)))
        at += d
    assert abs(at - 4.0) < 1e-6, 'bar does not add up to 4 beats: ' + bar
    return out


# ---------- sequencer ----------
class Song:
    def __init__(self, bpm, bars, swing=0.0, tail=3.0):
        self.spb = 60.0 / bpm
        self.swing = swing
        self.bars = bars
        n = int((bars * 4 * self.spb + tail) * SR)
        self.dry = np.zeros((n, 2))
        self.wet = np.zeros((n, 2))

    def seconds(self, beat):
        whole = math.floor(beat + 1e-9)
        f = beat - whole
        if abs(f - .5) < 1e-6:
            f = .5 + self.swing        # late off-beats give the lazy swing feel
        return (whole + f) * self.spb

    def add(self, sig, beat, gain=1.0, pan=0.0, send=.2, jitter=.004):
        start = max(0, int((self.seconds(beat) + rng.normal(0, jitter)) * SR))
        end = min(len(self.dry), start + len(sig))
        if end <= start:
            return
        seg = sig[:end - start] * gain
        left, right = math.cos((pan + 1) * math.pi / 4), math.sin((pan + 1) * math.pi / 4)
        self.dry[start:end, 0] += seg * left
        self.dry[start:end, 1] += seg * right
        self.wet[start:end, 0] += seg * left * send
        self.wet[start:end, 1] += seg * right * send

    def note(self, inst, p, beat, beats, vel=1.0, gain=1.0, pan=0.0, send=.2, gate=.92):
        vel *= rng.uniform(.9, 1.06)
        self.add(inst(p, beats * self.spb * gate, vel), beat, gain, pan, send)

    def melody(self, inst, bars, start_bar, gain=1.0, pan=0.0, send=.3, shift=0, harmony_key=None, gate=.92):
        for b, bar in enumerate(bars):
            for at, beats, p in parse(bar):
                if p is None:
                    continue
                q = third_below(p, harmony_key) if harmony_key is not None else p
                self.note(inst, q + shift, (start_bar + b) * 4 + at, beats, 1.0, gain, pan, send, gate)

    def render(self, reverb=.22):
        n = int(1.2 * SR)
        t = np.arange(n) / SR
        ir = rng.normal(0, 1, (n, 2)) * np.exp(-t * 5.2)[:, None]
        for c in range(2):
            ir[:, c] = np.convolve(ir[:, c], np.ones(7) / 7, 'same')
        ir[:int(.012 * SR)] = 0
        ir /= np.sqrt((ir ** 2).sum(axis=0))
        size = 1 << int(math.ceil(math.log2(len(self.wet) + n)))
        out = self.dry.copy()
        for c in range(2):
            conv = np.fft.irfft(np.fft.rfft(self.wet[:, c], size) * np.fft.rfft(ir[:, c], size), size)
            out[:, c] += conv[:len(out)] * reverb * 3.0
        out -= out.mean(axis=0)
        out = np.tanh(out / np.abs(out).max() * 1.25)
        out = out / np.abs(out).max() * .89
        # Match loudness between tunes so one volume setting suits them all.
        rms = float(np.sqrt((out ** 2).mean()))
        return out * min(1.0, .16 / rms)


def strum(song, sym, beat, down=True, vel=.5, gain=.3, pan=-.25, low=57):
    notes = voicing(sym, low)
    order = notes if down else notes[::-1]
    for i, p in enumerate(order):
        song.note(pluck, p, beat + i * .014 / song.spb, 1.0, vel * (1 - .07 * i), gain, pan, .18)


ISLAND = ((0, True, 1.0), (1, True, .8), (1.5, False, .6), (2.5, False, .65), (3, True, .85), (3.5, False, .6))


def island_bar(song, bar, chords, gain=.3):
    """The classic ukulele strum: down, down-up, up-down-up."""
    for at, down, vel in ISLAND:
        strum(song, chords[0] if at < 2 else chords[1], bar * 4 + at, down, vel * .55, gain)


def bounce_bass(song, bar, chords, gain=.5):
    a, b = chords
    song.note(bass, root_at(a, 36), bar * 4, 1.3, .95, gain, 0, .05)
    song.note(bass, root_at(a, 36) + 12, bar * 4 + 1.5, .5, .6, gain, 0, .05)
    song.note(bass, root_at(b, 36) + 7 if a == b else root_at(b, 36), bar * 4 + 2, 1.3, .85, gain, 0, .05)
    song.note(bass, root_at(b, 36) + 12, bar * 4 + 3.5, .5, .55, gain, 0, .05)


def walking_bass(song, bar, chords, next_sym, gain=.5):
    a, b = chords
    r, pcs = chord(a)
    root = root_at(a, 36)
    line = [root, root + (pcs[1] - r) % 12, root_at(b, 36) + 7 if a == b else root_at(b, 36)]
    target = root_at(next_sym, 36)
    line.append(target - 1 if target > line[-1] else target + 2)
    for i, p in enumerate(line):
        song.note(bass, p, bar * 4 + i, .95, .9 if i == 0 else .75, gain, 0, .05)


def light_drums(song, bar, level=1.0, kick_on=(0, 2.5), wood_on=(1, 3)):
    for e in range(8):
        song.add(shaker(.09 if e % 2 else .06), bar * 4 + e * .5, (.5 if e % 2 else .32) * level, .35, .1)
    for at in kick_on:
        song.add(kick(), bar * 4 + at, .5 * level, 0, .02)
    for at in wood_on:
        song.add(wood(), bar * 4 + at, .22 * level, -.3, .15)


def brush_drums(song, bar, level=1.0):
    for q in range(4):
        song.add(brush(), bar * 4 + q, .8 * level, .2, .15)
        song.add(shaker(.05), bar * 4 + q + .5, .3 * level, .3, .1)
    for at in (1, 3):
        song.add(rim(), bar * 4 + at, .3 * level, -.25, .2)
    song.add(kick(), bar * 4, .38 * level, 0, .02)


def pop_drums(song, bar, level=1.0):
    for e in range(8):
        song.add(shaker(.05), bar * 4 + e * .5, (.42 if e % 2 else .3) * level, .35, .08)
    for at in (0, 1.5, 2):
        song.add(kick(), bar * 4 + at, .42 * level, 0, .02)
    for at in (1, 3):
        song.add(clap(), bar * 4 + at, .5 * level, -.1, .25)


def pairs(symbols):
    """'C Am F G | Dm,G' style list -> [(first half, second half)] per bar."""
    out = []
    for item in symbols.split():
        a, _, b = item.partition(',')
        out.append((a, b or a))
    return out


# ---------- the four tunes ----------
def open_sign():
    """Bouncy ukulele and glockenspiel in C: the shop's main daytime tune."""
    A = ['E5/.5 G5/.5 C6/1 G5/.5 E5/.5 G5/1', 'A5/1.5 G5/.5 E5/1 C5/1', 'F5/.5 A5/.5 C6/1 A5/.5 F5/.5 A5/1',
         'G5/1.5 B5/.5 D6/1.5 r/.5', 'E6/.5 D6/.5 C6/1 G5/.5 E5/.5 G5/1', 'A5/1 C6/.5 A5/.5 G5/1 E5/1',
         'F5/.5 E5/.5 D5/1 G5/.5 A5/.5 B5/1', 'C6/2 r/1 G5/.5 A5/.5']
    B = ['A5/1 C6/1 F6/1.5 E6/.5', 'D6/1 B5/1 G5/2', 'G5/1 B5/1 E6/1.5 D6/.5', 'C6/1 A5/1 E5/2',
         'F5/.5 G5/.5 A5/.5 C6/.5 A5/1 F5/1', 'G5/.5 A5/.5 B5/.5 D6/.5 B5/1 G5/1', 'C6/1 E6/1 G6/1 E6/1',
         'D6/1 B5/1 G5/1 G5/.5 A5/.5']
    ca, cb = pairs('C Am F G C Am Dm,G C'), pairs('F G Em Am F G C G7')
    form = [('intro', pairs('C G')), ('A1', ca), ('A2', ca), ('B', cb), ('A3', ca), ('out', pairs('C C'))]
    song = Song(108, sum(len(c) for _, c in form))
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            if name == 'out' and i == 1:
                for k, p in enumerate(voicing('C', 60, 5)):
                    song.note(pluck, p, (bar + i) * 4 + k * .12, 3, .7, .4, -.2, .4)
                    song.note(glock, p + 12, (bar + i) * 4 + k * .12, 3, .6, .3, .25, .5)
                song.note(bass, 36, (bar + i) * 4, 3, .9, .5, 0, .05)
                continue
            island_bar(song, bar + i, ch, .26 if name == 'intro' else .3)
            bounce_bass(song, bar + i, ch, .38)
            if name != 'intro':
                light_drums(song, bar + i, .8 if name == 'A1' else 1.0)
        if name in ('A1', 'A2', 'A3'):
            song.melody(whistle, A, bar, .5, .1, .32)
            if name != 'A1':
                song.melody(glock, A, bar, .28, .35, .45, 12)
            if name == 'A3':
                song.melody(whistle, A, bar, .22, -.3, .32, 0, pitch('C4'))
        if name == 'B':
            song.melody(glock, B, bar, .34, .2, .45)
            song.melody(whistle, B, bar, .3, -.1, .32, -12)
        if name == 'out':
            song.melody(whistle, ['C6/1 E6/1 G6/2'], bar, .45, .1, .4)
        bar += len(chords)
    return song.render(.22)


def weeding_by_the_window():
    """Lazy swing in F with a whistled tune over marimba: slow afternoons."""
    A = ['C5/1 F5/1 A5/1.5 G5/.5', 'F5/2 D5/1 F5/1', 'D5/1 F5/1 Bb5/1.5 A5/.5', 'G5/2 E5/1 C5/1',
         'A5/.5 C6/.5 A5/1 F5/1 A5/1', 'D6/1.5 C6/.5 A5/1 F5/1', 'Bb5/1 G5/1 E5/1 G5/1', 'F5/3 r/1']
    B = ['Bb5/1 D6/1 F6/2', 'E6/1 C6/1 G5/2', 'A5/1 C6/1 E6/2', 'D6/1 A5/1 F5/2',
         'Bb5/.5 A5/.5 G5/1 F5/1 D5/1', 'C5/.5 D5/.5 E5/1 G5/1 Bb5/1', 'A5/2 F5/2', 'G5/1 E5/1 C5/2']
    ca, cb = pairs('F Dm Bb C F Dm Gm,C F'), pairs('Bb C Am Dm Bb C F C7')
    form = [('intro', pairs('F C7')), ('A1', ca), ('A2', ca), ('B', cb), ('A3', ca), ('out', pairs('F F'))]
    song = Song(92, sum(len(c) for _, c in form), swing=.14)
    flat = [ch for _, chords in form for ch in chords]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            n = bar + i
            nxt = flat[n + 1][0] if n + 1 < len(flat) else 'F'
            if name == 'out' and i == 1:
                for k, p in enumerate(voicing('F', 53, 5)):
                    song.note(marimba, p, n * 4 + k * .16, 2, .8, .5, -.2, .4)
                song.note(bass, 41, n * 4, 3, .9, .5, 0, .05)
                song.note(whistle, pitch('F5'), n * 4 + .8, 2.6, .9, .4, .1, .4)
                continue
            walking_bass(song, n, ch, nxt, .4)
            for at in (1, 3):                       # marimba answers on the back beats
                for p in voicing(ch[0] if at < 2 else ch[1], 60, 3):
                    song.note(marimba, p, n * 4 + at, .5, .6, .3, -.3, .25)
            for at, k in ((0, 0), (.5, 2), (2, 1), (2.5, 3)):   # and a little broken chord between
                song.note(marimba, voicing(ch[0] if at < 2 else ch[1], 65, 4)[k], n * 4 + at, .5, .45, .22, .3, .3)
            if name != 'intro':
                brush_drums(song, n, .8 if name == 'A1' else 1.0)
        if name in ('A1', 'A2', 'A3'):
            song.melody(whistle, A, bar, .52, .05, .35)
            if name == 'A3':
                song.melody(glock, A, bar, .16, .35, .45, 12)
        if name == 'B':
            song.melody(whistle, B, bar, .5, .05, .35)
            song.melody(keys, B, bar, .16, -.3, .3, -12, pitch('F3'))
        bar += len(chords)
    return song.render(.24)


def rush_order():
    """Up-tempo and perky in G for busy days."""
    A = ['D5/.5 G5/.5 B5/.5 G5/.5 D6/1 B5/1', 'E5/.5 G5/.5 B5/.5 G5/.5 E6/1 B5/1', 'C6/.5 E6/.5 G6/1 E6/.5 C6/.5 E6/1',
         'D6/1 A5/.5 D6/.5 F#6/1.5 r/.5', 'G6/.5 F#6/.5 D6/1 B5/.5 D6/.5 G5/1', 'E6/.5 D6/.5 B5/1 G5/.5 B5/.5 E5/1',
         'C6/.5 B5/.5 A5/1 D6/.5 C6/.5 A5/1', 'G5/2 r/1 D5/.5 F#5/.5']
    B = ['E6/1.5 C6/.5 G5/2', 'F#6/1.5 D6/.5 A5/2', 'D6/1 B5/1 F#5/1 B5/1', 'E6/1 B5/1 G5/2',
         'C6/.5 D6/.5 E6/.5 G6/.5 E6/1 C6/1', 'D6/.5 E6/.5 F#6/.5 A6/.5 F#6/1 D6/1', 'G6/1 D6/1 B5/1 D6/1',
         'A5/1 D6/1 F#6/1 A6/1']
    ca, cb = pairs('G Em C D G Em C,D G'), pairs('C D Bm Em C D G D')
    form = [('intro', pairs('G D')), ('A1', ca), ('A2', ca), ('B', cb), ('A3', ca), ('out', pairs('G G'))]
    song = Song(126, sum(len(c) for _, c in form))
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            n = bar + i
            if name == 'out' and i == 1:
                for k, p in enumerate(voicing('G', 55, 5)):
                    song.note(keys, p, n * 4 + k * .1, 3, .7, .4, -.2, .4)
                    song.note(glock, p + 24, n * 4 + k * .1, 3, .5, .25, .3, .5)
                song.note(bass, 43, n * 4, 3, .9, .5, 0, .05)
                continue
            for e in range(8):                      # driving eighth-note bass, root and octave
                sym = ch[0] if e < 4 else ch[1]
                song.note(bass, root_at(sym, 36) + (12 if e % 2 else 0), n * 4 + e * .5, .45, .85 if e % 2 == 0 else .6, .30, 0, .04)
            for at in (0, 1.5, 3):                  # bright off-beat keys
                for p in voicing(ch[0] if at < 2 else ch[1], 60, 3):
                    song.note(keys, p, n * 4 + at, .5, .6, .2, -.3, .25)
            if name != 'intro':
                pop_drums(song, n, .75 if name == 'A1' else 1.0)
        if name in ('A1', 'A2', 'A3'):
            song.melody(lead, A, bar, .34, .1, .28)
            song.melody(glock, A, bar, .26, .35, .45, 12)
            if name == 'A3':
                song.melody(lead, A, bar, .16, -.3, .28, 0, pitch('G3'))
        if name == 'B':
            song.melody(lead, B, bar, .32, .1, .3)
            song.melody(pluck, B, bar, .26, -.3, .3, -12)
        if name == 'out':
            song.melody(lead, ['G5/.5 B5/.5 D6/.5 G6/2.5'], bar, .3, .1, .4)
        bar += len(chords)
    return song.render(.2)


def paper_and_ink():
    """Gentle music box in D for the title screen."""
    A = ['F#5/1 A5/1 D6/2', 'D6/1 B5/1 F#5/2', 'G5/1 B5/1 D6/1 B5/1', 'A5/2 E5/1 A5/1',
         'F#5/1 A5/1 F#6/1.5 E6/.5', 'D6/2 B5/2', 'G5/1 B5/1 A5/1 C#6/1', 'D6/4']
    B = ['B5/1 D6/1 G6/2', 'A5/1 C#6/1 E6/2', 'F#5/1 A5/1 C#6/2', 'B5/1 D6/1 F#6/2',
         'G6/1 F#6/1 D6/1 B5/1', 'E6/1 C#6/1 A5/2', 'D6/1 F#6/1 A6/2', 'D6/4']
    ca, cb = pairs('D Bm G A D Bm Em,A D'), pairs('G A F#m Bm G A D D')
    form = [('A1', ca), ('B', cb), ('A2', ca)]
    song = Song(84, sum(len(c) for _, c in form), tail=3.5)
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            n = bar + i
            for h, sym in enumerate(ch):
                for p in voicing(sym, 50, 3):
                    song.note(pad, p, n * 4 + h * 2, 2, .5, .16, -.1 + .1 * h, .5)
                song.note(bass, root_at(sym, 38), n * 4 + h * 2, 1.8, .7, .3, 0, .05)
                v = voicing(sym, 62, 4)
                for e, k in enumerate((0, 2, 1, 3)):
                    song.note(glock, v[k], n * 4 + h * 2 + e * .5, .5, .4, .15, -.35, .5)
            if i % 4 == 3:
                song.add(ding(), n * 4 + 3, .3, .5, .6)
        song.melody(glock, A if name != 'B' else B, bar, .5, .2, .55, 12 if name == 'A2' else 0)
        if name != 'A1':
            song.melody(whistle, A if name != 'B' else B, bar, .2, -.15, .45, -12)
        bar += len(chords)
    return song.render(.3)


# ---------- sound effects (mono) ----------
def mono(parts, seconds):
    out = np.zeros(int(seconds * SR))
    for sig, at, gain in parts:
        s = int(at * SR)
        e = min(len(out), s + len(sig))
        out[s:e] += sig[:e - s] * gain
    return fade(out, .001, .02)


def sfx_click():
    t = ax(.07)
    return fade(np.sin(TAU * np.cumsum(520 + 380 * np.exp(-t * 45)) / SR) * np.exp(-t * 55), .001, .01) * .6


def sfx_place():
    t = ax(.22)
    thunk = np.sin(TAU * np.cumsum(70 + 110 * np.exp(-t * 30)) / SR) * np.exp(-t * 20)
    return mono([(thunk, 0, .9), (wood(), .004, .35)], .26)


def sfx_cash():
    t = ax(.6)
    shimmer = sum(np.sin(TAU * f * t + rng.uniform(0, TAU)) for f in (3140, 3960, 4710, 5280, 6270)) / 5 * np.exp(-t * 7)
    return mono([(glock(pitch('B6'), .3), 0, .7), (glock(pitch('E7'), .5), .09, .8), (shimmer, .09, .22), (wood(), 0, .25)], .8)


def sfx_door():
    return mono([(glock(pitch('E6'), .5), 0, .7), (glock(pitch('C6'), .8), .24, .7)], 1.2)


def sfx_done():
    return mono([(marimba(pitch('C5'), .2), 0, .7), (marimba(pitch('E5'), .2), .08, .7), (marimba(pitch('G5'), .2), .16, .7),
                 (glock(pitch('C6'), .5), .24, .5)], .95)


def sfx_fanfare():
    parts = []
    for k, name in enumerate(('C5', 'E5', 'G5', 'C6', 'E6', 'G6')):
        parts.append((pluck(pitch(name), .4), k * .09, .6))
        parts.append((glock(pitch(name) + 12, .4), k * .09, .35))
    for name in ('C6', 'E6', 'G6', 'C7'):
        parts.append((glock(pitch(name), 1.0), .62, .4))
    return mono(parts, 2.0)


def sfx_levelup():
    parts = [(glock(pitch(n), .3), k * .06, .5) for k, n in enumerate(('G5', 'B5', 'D6', 'G6', 'B6', 'D7'))]
    parts.append((ding(), .36, .6))
    return mono(parts, 1.5)


def sfx_error():
    def boop(f, seconds):
        t = ax(seconds)
        return fade(np.sin(TAU * f * t) + .2 * np.sin(TAU * 2 * f * t), .008, .05) * .6
    return mono([(boop(196, .12), 0, 1), (boop(156, .18), .14, 1)], .36)


def sfx_cutter():
    t = ax(.55)
    f = 210 + 110 * np.sin(TAU * 1.8 * t) ** 2
    ph = TAU * np.cumsum(f) / SR
    motor = (np.sin(ph) + .5 * np.sin(2 * ph) + .3 * np.sin(3 * ph)) * (.75 + .25 * np.sin(TAU * 31 * t))
    hiss = np.diff(rng.uniform(-1, 1, len(t) + 1)) * .12
    return fade((motor * .3 + hiss) * np.sin(np.pi * t / .55) ** .5, .01, .06) * .55


def sfx_press():
    t = ax(.7)
    hiss = np.convolve(np.diff(rng.uniform(-1, 1, len(t) + 1)), np.ones(3) / 3, 'same') * np.exp(-t * 4.5) * .3
    return mono([(sfx_place(), 0, .9), (fade(hiss, .04, .1), .05, 1)], .8)


def sfx_print():
    t = ax(.7)
    sweep = np.sin(TAU * 2.9 * t) ** 2
    noise = np.convolve(rng.uniform(-1, 1, len(t)), np.ones(6) / 6, 'same')
    hum = np.sin(TAU * 120 * t) * .12
    return fade(noise * sweep * .5 + hum, .02, .08) * .6


def sfx_pack():
    t = ax(.3)
    rip = np.diff(rng.uniform(-1, 1, len(t) + 1)) * (.4 + .6 * t / .3)
    zipp = np.sin(TAU * np.cumsum(500 + 2600 * t) / SR) * .15
    return fade((rip * .4 + zipp) * np.minimum(1, t / .01), .004, .04) * .6


def sfx_day():
    return mono([(glock(pitch('G5'), .5), 0, .6), (glock(pitch('E5'), .5), .2, .6), (glock(pitch('C5'), .9), .4, .7),
                 (pad(pitch('C4'), .8), .4, .5), (pad(pitch('E4'), .8), .4, .4), (pad(pitch('G4'), .8), .4, .4)], 2.0)


MUSIC = {'open-sign': open_sign, 'weeding-by-the-window': weeding_by_the_window, 'rush-order': rush_order,
         'paper-and-ink': paper_and_ink}
SFX = {'click': sfx_click, 'place': sfx_place, 'cash': sfx_cash, 'door': sfx_door, 'done': sfx_done,
       'fanfare': sfx_fanfare, 'levelup': sfx_levelup, 'error': sfx_error, 'cutter': sfx_cutter, 'press': sfx_press,
       'print': sfx_print, 'pack': sfx_pack, 'day': sfx_day}


def write(path, data):
    data = np.atleast_2d(data.T).T if data.ndim == 1 else data
    pcm = (np.clip(data, -1, 1) * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(pcm.shape[1])
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--only', default='')
    args = ap.parse_args(sys.argv[sys.argv.index('--') + 1:])
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    report = {}
    for name, fn in MUSIC.items():
        if args.only and args.only not in name:
            continue
        audio = fn()
        write(out / ('music-%s.wav' % name), audio)
        rms = float(np.sqrt((audio ** 2).mean()))
        report['music-' + name] = {'seconds': round(len(audio) / SR, 2), 'peak': round(float(np.abs(audio).max()), 3), 'rms': round(rms, 4)}
        print('MUSIC', name, report['music-' + name], flush=True)
    for name, fn in SFX.items():
        if args.only and args.only not in name:
            continue
        audio = fn()
        audio = audio / max(1e-6, np.abs(audio).max()) * .8
        write(out / ('sfx-%s.wav' % name), audio)
        report['sfx-' + name] = {'seconds': round(len(audio) / SR, 2)}
        print('SFX', name, report['sfx-' + name], flush=True)
    (out / 'audio-report.json').write_text(json.dumps(report, indent=2))
    print('AUDIO_DONE', flush=True)
