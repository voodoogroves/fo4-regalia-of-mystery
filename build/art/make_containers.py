#!/usr/bin/env python3
"""make_containers.py: charcoal-and-emerald skins for the four containers the Mysterious Traveler left behind.
Status: seen in game 2026-11-25: suitcase, duffle and tool case good. The first aid kit lettering read upside down; chevrons replace it (seen, looks right).

Suitcase (SetDressing\\Suitcase\\Suitcase_prewar.nif), duffle bag, tool case and pharmacy first aid kit. Each diffuse is BC1 with mips.
Every block is decoded, recoloured per pixel (the original brightness is kept as shading, so wear and dirt survive) and re-encoded.
Stripe places are given in texture coordinates, read off the flat textures: how they sit on the model is NOT yet checked in game.

Run:  python3 -B make_containers.py OUTDIR
Writes Textures/RegaliaOfMystery/Cont*_d.dds, Materials/RegaliaOfMystery/Cont*.BGSM and preview/*.png. Needs baunpack.
Outputs are derived from Bethesda's textures: do NOT commit them. A texture-only change needs a game restart, not a rebuild.
"""
import os, struct, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_gold as mg
import make_dress as md                # its BC1 block decoder and encoder

CHARCOAL = (53, 56, 57)                # the Garb's colours
GREEN = (65, 137, 80)

def lum(p): return (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / 255.0
def shade(colour, l, mean, lo=0.40, hi=1.55):
    f = max(lo, min(hi, l / mean))
    return tuple(max(0, min(255, int(round(c * f)))) for c in colour)
def box(u, v, u0, v0, u1, v1): return u0 <= u < u1 and v0 <= v < v1

def chevrons(u, v, uc, tops, slope, half):
    """Two V-shaped bands: the point of each V is at (uc, top)."""
    return any(abs(v - (t - slope * abs(u - uc))) < half for t in tops)

def suitcase(p, u, v):
    if box(u, v, 0.0, 0.055, 0.845, 1.0) or v >= 0.635:        # lid and sides (the hardware along the top and right stays)
        if box(u, v, 0.05, 0.11, 0.79, 0.57) and chevrons(u, v, 0.42, (0.39, 0.52), 0.34, 0.028): return shade(GREEN, lum(p), 0.62)
        return shade(CHARCOAL, lum(p), 0.62)
    return p

def duffle(p, u, v):
    if box(u, v, 0.0, 0.84, 0.10, 1.0): return p               # buckles
    if v > 0.21 and (abs(u - 0.36) < 0.024 or abs(u - 0.64) < 0.024): return shade(GREEN, lum(p), 0.25)
    return shade(CHARCOAL, lum(p), 0.25, 0.55, 1.5)

def toolcase(p, u, v):
    painted = (box(u, v, 0.0, 0.0, 0.728, 0.628) or box(u, v, 0.762, 0.04, 0.975, 0.512) or box(u, v, 0.70, 0.60, 1.0, 0.825) or v >= 0.825)
    if not painted or p[0] - p[2] <= 35: return p              # bare metal stays; orange paint and rust in the painted areas turn charcoal
    if box(u, v, 0.05, 0.06, 0.68, 0.58) and chevrons(u, v, 0.364, (0.34, 0.47), 0.36, 0.028): return shade(GREEN, lum(p), 0.55)
    return shade(CHARCOAL, lum(p), 0.55)

def medkit(p, u, v):
    l = lum(p)
    if box(u, v, 0.17, 0.15, 0.75, 0.445):                     # the lid label: lettering painted out, two chevrons instead
        if box(u, v, 0.19, 0.17, 0.73, 0.43) and any(abs(v - (t + 0.30 * abs(u - 0.46))) < 0.025 for t in (0.215, 0.315)): return shade(GREEN, 0.62, 0.62)
        return shade(CHARCOAL, 0.70, 0.70)
    if l < 0.36: return p                                      # black hardware
    if v > 0.66 and u < 0.78 and (abs(v - 0.752) < 0.017 or abs(v - 0.912) < 0.017): return shade(GREEN, l, 0.62)
    return shade(CHARCOAL, l, 0.62)

# our name: (texture, material file, texture path as written in the material, painter)
PARTS = {
    'ContSuitcase': ('suitcase/suitcaseprewar_d', 'suitcase/suitcase_prewar', 'SetDressing/Suitcase/SuitcasePrewar_d.dds', suitcase),
    'ContDuffle':   ('dufflebag/dufflebag_d', 'dufflebag/dufflebag', 'SetDressing/DuffleBag/DuffleBag_d.dds', duffle),
    'ContToolCase': ('toolcase/toolcase01_d', 'toolcase/toolcase1', 'SetDressing/ToolCase/ToolCase01_d.dds', toolcase),
    'ContMedKit':   ('firstaidkit/firstaidkitpharm_d', 'firstaidkit/firstaidkitpharm', 'SetDressing/FirstAidKit/FirstAidKitPharm_d.dds', medkit),
}

def repaint(body, w, h, mips, painter):
    out, o, top = bytearray(), 0, bytearray(w * h * 3)
    for m in range(mips):
        mw, mh = max(1, w >> m), max(1, h >> m)
        bw, bh = max(1, (mw + 3) // 4), max(1, (mh + 3) // 4)
        for by in range(bh):
            for bx in range(bw):
                old = md.decode_block(bytes(body[o:o + 8])); o += 8
                xy = [(bx * 4 + (k & 3), by * 4 + (k >> 2)) for k in range(16)]
                blk = md.encode_block([painter(p, (x + 0.5) / max(mw, 4), (y + 0.5) / max(mh, 4)) for (x, y), p in zip(xy, old)])
                out += blk
                if m == 0:
                    for (x, y), p in zip(xy, md.decode_block(blk)): top[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(p)
    if o != len(body): raise SystemExit('size mismatch: mips say %d, file has %d' % (o, len(body)))
    return bytes(out), top

def main():
    if len(sys.argv) != 2: raise SystemExit(__doc__)
    out = os.path.abspath(sys.argv[1])
    for d in ('Textures/RegaliaOfMystery', 'Materials/RegaliaOfMystery', 'preview'): os.makedirs(os.path.join(out, d), exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mkcont.') as tmp:
        for name, (tex, mat, old_path, painter) in PARTS.items():
            mg.extract('Fallout4 - Textures*.ba2', 'setdressing/%s.dds' % tex, tmp)
            mg.extract('Fallout4 - Materials.ba2', 'setdressing/%s.bgsm' % mat, tmp)
            dds = open(os.path.join(tmp, 'textures/setdressing/%s.dds' % tex), 'rb').read()
            bgsm = open(os.path.join(tmp, 'materials/setdressing/%s.bgsm' % mat), 'rb').read()
            h, w = struct.unpack_from('<II', dds, 12); mips = struct.unpack_from('<I', dds, 28)[0]
            if dds[84:88] != b'DX10' or struct.unpack_from('<I', dds, 128)[0] not in (71, 72): raise SystemExit('unexpected format for ' + name)
            new, top = repaint(dds[148:], w, h, mips, painter)
            path = 'RegaliaOfMystery/%s_d.dds' % name
            open(os.path.join(out, 'Textures', path), 'wb').write(dds[:148] + new)
            open(os.path.join(out, 'Materials/RegaliaOfMystery/%s.BGSM' % name), 'wb').write(mg.patch_bgsm(bgsm, old_path, path))
            mg.write_png(os.path.join(out, 'preview/%s.png' % name), w, h, top)
            print('%s: %dx%d, %d mips' % (name, w, h, mips))

if __name__ == '__main__': main()
