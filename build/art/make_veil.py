#!/usr/bin/env python3
"""make_veil.py: recolour the Raider Surgical Mask's diffuse texture into the Veil of Secrets: black fabric, optionally with a cream-gold lace pattern.
Status: WRITTEN 2026-11-24 (first pass; look tuning needs in-game screenshots).

The Surgical Mask (ARMO 000787DA, addon AA_Raider_02_Helmet_Mask 000787D0, worn meshes Armor\\Raider02\\Raider02MaskM.nif and ...F.nif) has one material,
Armor\\Raider02\\Raider02Mask.bgsm, and one texture set, RaiderMask_d/n/s.dds. The diffuse is BC3 (DXGI 77), 1024 x 1024, 11 mips. The picture holds the mask
cloth (a dirty-beige patch, bottom), the ear straps (beige strips, top) and other Raider parts (dark) that the mask does not use. BC3 = a BC4-style alpha
block (8 bytes, kept as is) plus a BC1-style colour block (8 bytes, always four-colour). Black fabric: every pixel goes through a darkening ramp (the folds and
stains remain as shading). Lace: pixels that were beige in the ORIGINAL (the cloth) get a cream-gold diamond lattice with dots, anti-aliased at every mip level.

Run:  python3 -I make_veil.py OUTDIR [--lace] [--period 0.052] [--line 0.0022] [--dot 0.0055] [--cdot 0] [--gain 0.22] [--cap 0.42]
Writes: Textures/Armor/VeilOfSecrets/VeilOfSecrets_d.dds, Materials/Armor/VeilOfSecrets/VeilOfSecrets.BGSM, preview/*.png.   Needs baunpack.
Outputs are derived from Bethesda's texture: NOT committed to a public repo.
"""
import os, struct, sys, tempfile, argparse, math, importlib.util

here = os.path.dirname(os.path.abspath(__file__))
def load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(here, name + '.py')); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
mg = load('make_gold'); md = load('make_dress')

OLD_TEX = 'armor/raider02/raidermask_d.dds'
NEW_TEX = 'Armor/VeilOfSecrets/VeilOfSecrets_d.dds'
BLACK = (0.96, 0.96, 1.00)      # a very slightly cool black
CREAM = (0.92, 0.84, 0.68)      # the cream-gold of the Garb's cowl (measured 198,181,150)
CREAM_FLAT = (198, 181, 150)

def lum(p): return (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / 255.0
def black_of(p, gain, cap):
    l = min(cap, lum(p) * gain); return tuple(max(0, min(255, int(round(255 * l * t)))) for t in BLACK)
def is_beige(p): return (p[0] - p[2]) > 18 and lum(p) > 0.28      # the cloth and the straps, in the original
def is_cloth(p, u, v):
    """The cloth patch (bottom, u < 0.82, v > 0.53) by GEOMETRY, plus anything beige (the straps at the top): a colour test alone broke on the stains."""
    return is_beige(p) or (u < 0.82 and v > 0.53)

def lace_cov(u, v, a, ps):
    """Coverage (0..1) of the lace at a texture position: a diamond lattice (lines) with a dot at every crossing and a small dot at every diamond centre."""
    p = a.period; r2 = math.sqrt(2.0)
    fa = ((u + v) / p) % 1.0; fb = ((u - v) / p) % 1.0
    dA = min(fa, 1 - fa) * p / r2; dB = min(fb, 1 - fb) * p / r2        # perpendicular distances to the two line families
    line = min(dA, dB) - a.line / 2
    dot = math.sqrt(dA * dA + dB * dB) - a.dot
    half = p / (2 * r2)
    cen = math.sqrt((half - dA) ** 2 + (half - dB) ** 2) - a.cdot
    sd = min(line, dot, cen)
    return max(0.0, min(1.0, 0.5 - sd / ps))

def bc3_level(buf, w, h, a, lace):
    out = bytearray(buf); bw = max(1, w // 4); bh = max(1, h // 4); ps = 1.0 / max(w, 4); n_lace = 0
    for by in range(bh):
        for bx in range(bw):
            o = (by * bw + bx) * 16
            px = md.decode_block(bytes(buf[o + 8:o + 16]))
            new = []
            for k, p in enumerate(px):
                b = black_of(p, a.gain, a.cap)
                u = (bx * 4 + (k & 3) + 0.5) / max(w, 4); v = (by * 4 + (k >> 2) + 0.5) / max(h, 4)
                if lace and is_cloth(p, u, v):
                    c = lace_cov(u, v, a, ps)
                    if c > 0:
                        cream = tuple(int(round(min(255, x * (0.80 + 0.45 * lum(p))))) for x in CREAM_FLAT)   # keep a little of the cloth's own shading
                        b = md.lerp(b, cream, c); n_lace += 1
                new.append(b)
            out[o + 8:o + 16] = md.encode_block(new)            # the alpha block (o .. o+8) is left exactly as it was
    return bytes(out), n_lace

def decode_bc3(buf, w, h):
    rgb = bytearray(w * h * 3); bw = w // 4
    for by in range(h // 4):
        for bx in range(bw):
            o = (by * bw + bx) * 16
            for k, p in enumerate(md.decode_block(bytes(buf[o + 8:o + 16]))):
                x, y = bx * 4 + (k & 3), by * 4 + (k >> 2); rgb[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(p)
    return rgb

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('out'); ap.add_argument('--lace', action='store_true')
    ap.add_argument('--period', type=float, default=0.052); ap.add_argument('--line', type=float, default=0.0022); ap.add_argument('--dot', type=float, default=0.0055)
    ap.add_argument('--cdot', type=float, default=0.0, help='radius of the small dot at each diamond centre (0 = none)')
    ap.add_argument('--gain', type=float, default=0.22); ap.add_argument('--cap', type=float, default=0.42)
    a = ap.parse_args(); out = os.path.abspath(a.out)
    for d in ('Textures/Armor/VeilOfSecrets', 'Materials/Armor/VeilOfSecrets', 'preview'): os.makedirs(os.path.join(out, d), exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mkveil.') as tmp:
        mg.extract('Fallout4 - Textures*.ba2', 'armor/raider02/raidermask_d.dds', tmp); mg.extract('Fallout4 - Materials.ba2', 'armor/raider02/raider02mask.bgsm', tmp)
        dds = open(os.path.join(tmp, 'textures/armor/raider02/raidermask_d.dds'), 'rb').read(); bgsm = open(os.path.join(tmp, 'materials/armor/raider02/raider02mask.bgsm'), 'rb').read()
    magic, size, flags, h, w, pitch, depth, mips = struct.unpack('<4sIIIIIII', dds[:32])
    if magic != b'DDS ' or dds[84:88] != b'DX10' or struct.unpack('<I', dds[128:132])[0] not in (77, 78): raise SystemExit('unexpected texture format (expected BC3)')
    hdr = 148; body = dds[hdr:]; res = bytearray(); off = 0; levels = {}; total = 0
    for m in range(mips):
        lw, lh = max(1, w >> m), max(1, h >> m); sz = max(1, lw // 4) * max(1, lh // 4) * 16
        if lw < 4 or lh < 4: res += body[off:off + sz]; off += sz; continue
        lvl, n = bc3_level(body[off:off + sz], lw, lh, a, a.lace); res += lvl; levels[m] = (off, sz, lw, lh); total += n; off += sz
    if off != len(body): raise SystemExit('size mismatch')
    open(os.path.join(out, 'Textures/Armor/VeilOfSecrets/VeilOfSecrets_d.dds'), 'wb').write(dds[:hdr] + bytes(res))
    open(os.path.join(out, 'Materials/Armor/VeilOfSecrets/VeilOfSecrets.BGSM'), 'wb').write(mg.patch_bgsm(bgsm, OLD_TEX, NEW_TEX))
    o1, s1, w1, h1 = levels[1]
    A = decode_bc3(body[o1:o1 + s1], w1, h1); B = decode_bc3(bytes(res)[o1:o1 + s1], w1, h1); sbs = bytearray()
    for y in range(h1): sbs += A[y * w1 * 3:(y + 1) * w1 * 3] + B[y * w1 * 3:(y + 1) * w1 * 3]
    tag = 'lace' if a.lace else 'black'
    mg.write_png(os.path.join(out, 'preview/side-by-side-%s.png' % tag), w1 * 2, h1, sbs)
    o0, s0, w0, h0 = levels[0]; P = decode_bc3(bytes(res)[o0:o0 + s0], w0, h0)
    cx0, cx1, cy0, cy1 = int(0.0 * w0), int(0.45 * w0), int(0.52 * h0), int(0.86 * h0); crop = bytearray()
    for y in range(cy0, cy1): crop += P[(y * w0 + cx0) * 3:(y * w0 + cx1) * 3]
    mg.write_png(os.path.join(out, 'preview/cloth-crop-mip0-%s.png' % tag), cx1 - cx0, cy1 - cy0, crop)
    print('texture %dx%d BC3, %d mips, mode %s, lace pixels %d, params %s' % (w, h, mips, tag, total, {k: v for k, v in vars(a).items() if k != 'out'}))

if __name__ == '__main__': main()
