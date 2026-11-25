#!/usr/bin/env python3
"""make_gold44.py: gold-plate the .44's metal for the Voice of Set, with the wooden grip panels turned charcoal grey.   Status: 2026-11-25; gold, black and grips seen in game, the smooth screw inlays not yet.

Same method as make_gold.py (recolour each BC1 block's two endpoints at every mip). Two textures: 44_d (frame, cylinder,
barrels, sights; it also holds the wood grips, which are left alone) and 44BullBarrel_d. The materials are copies of the
vanilla ones with the diffuse path changed and the bronze cubemap the Blade's gold uses.

Run:  python3 -B make_gold44.py OUTDIR [LOW HIGH]      (black-and-gold shadows)
Needs `baunpack` (Rhodes refs/fo4-archives.md). Outputs are derived from Bethesda's textures: do NOT commit them.
"""
import os, struct, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_gold as mg
import make_dress as md                # its BC1 block decoder and encoder

mg.GAIN, mg.GAMMA = 1.9, 0.88          # the revolver's steel is much darker than the sword's
CUBE_OLD = 'Shared/Cubemaps/mipblur_DefaultOutside1.dds'
CUBE_NEW = 'Shared/Cubemaps/Bronze_e.dds'
PARTS = [  # (texture base, material file, our name, protect the wood grips)
    ('44', '44.bgsm', 'VoiceGold', True),
    ('44bullbarrel', '44bullbarrel.bgsm', 'VoiceBullGold', False),
]
OLD_TEX = {'44': 'Weapons/44/44_d.dds', '44bullbarrel': 'Weapons/44/44BullBarrel_d.dds'}
# The wooden grip panels, traced on the vanilla 44_d at 1024 x 1024 (outline points), and the screws inside them that are gilded.
GRIPS = [
    [(340,1000),(352,955),(425,820),(462,718),(478,704),(505,702),(548,716),(580,742),(584,752),(598,800),(584,830),(576,900),(582,960),(600,996),(590,1016),(350,1018)],
    [(742,812),(768,760),(800,730),(850,710),(876,710),(892,735),(915,790),(955,875),(1010,975),(1004,1016),(782,1018),(772,992),(796,958),(802,885),(790,832)],
    [(722,850),(752,858),(772,885),(780,935),(772,985),(752,1012),(722,1020),(692,1012),(672,985),(664,935),(672,885),(692,858)],
]
# The metal inlays in the grips, gilded with smooth edges: two round medallions (x, y, radius) and two diamond escutcheons around the screws.
MEDALLIONS = [(501.2, 796.8, 12.4), (848.0, 802.4, 12.4)]
DIAMONDS = [
    [(466.6, 862.0), (478.2, 891.8), (457.4, 921.0), (446.9, 886.1)],
    [(881.1, 865.2), (902.2, 888.6), (893.1, 923.4), (871.7, 894.9)],
]

def inside(poly, x, y):
    hit = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1): hit = not hit
    return hit

def is_wood(u, v):
    x, y = u * 1024, v * 1024
    if y < 695 or x < 335: return False
    return any(inside(p, x, y) for p in GRIPS)

GRIP_GAIN = 0.80                        # grip panels: grey at this fraction of their original brightness (lower = darker)
GRIP_TINT = (0.96, 0.98, 1.00)         # neutral charcoal, a hair cool against the gold

def charcoal(rgb):
    l = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) * GRIP_GAIN
    return tuple(max(0, min(255, int(round(l * t)))) for t in GRIP_TINT)

SHADOWS = (0.07, 0.24)                 # original luminance: below the first = charcoal, above the second = gold; None = gold everywhere
_gold = mg.goldify

def black_and_gold(rgb):
    l = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255.0
    lo, hi = SHADOWS
    t = min(1.0, max(0.0, (l - lo) / (hi - lo))); t = t * t * (3 - 2 * t)
    g, c = _gold(rgb), charcoal(rgb)
    return tuple(int(round(c[i] + (g[i] - c[i]) * t)) for i in range(3))

def tint_with(level, fn):
    keep, mg.goldify = mg.goldify, fn
    try: return mg.tint_bc1(level)[0]
    finally: mg.goldify = keep

def is_inlay(x, y):
    return any((x - cx) ** 2 + (y - cy) ** 2 <= r * r for cx, cy, r in MEDALLIONS) or any(inside(d, x, y) for d in DIAMONDS)

def coverage(bx, by, mw, mh):
    """Per-pixel share (0..1) of an inlay for the 16 pixels of a block, 3 x 3 samples each."""
    out = []
    for k in range(16):
        px, py = bx * 4 + (k & 3), by * 4 + (k >> 2)
        n = sum(is_inlay((px + (i + 0.5) / 3) / mw * 1024, (py + (j + 0.5) / 3) / mh * 1024) for i in range(3) for j in range(3))
        out.append(n / 9)
    return out

def paint(body, w, h, mips, protect):
    out, kept, o = bytearray(), 0, 0
    for m in range(mips):
        mw, mh = max(1, w >> m), max(1, h >> m)
        bw, bh = max(1, (mw + 3) // 4), max(1, (mh + 3) // 4)
        level = body[o:o + bw * bh * 8]; o += bw * bh * 8
        tinted = bytearray(tint_with(level, black_and_gold if SHADOWS else _gold))
        if protect:
            grey = tint_with(level, charcoal)
            gilt = tint_with(level, _gold)
            for i in range(bw * bh):
                if is_wood((i % bw + 0.5) / bw, (i // bw + 0.5) / bh):
                    o8 = slice(i * 8, i * 8 + 8)
                    cov = coverage(i % bw, i // bw, bw * 4, bh * 4)
                    if max(cov) == 0: tinted[o8] = grey[o8]
                    elif min(cov) == 1: tinted[o8] = gilt[o8]
                    else:                              # an inlay edge: blend per pixel and re-encode
                        a, b = md.decode_block(bytes(grey[o8])), md.decode_block(bytes(gilt[o8]))
                        tinted[o8] = md.encode_block([md.lerp(a[k], b[k], cov[k]) for k in range(16)])
                    kept += 1
        out += tinted
    if o != len(body): raise SystemExit('size mismatch: mips say %d, file has %d' % (o, len(body)))
    return bytes(out), kept

def main():
    global SHADOWS
    if len(sys.argv) not in (2, 4): raise SystemExit(__doc__)
    if len(sys.argv) == 4: SHADOWS = (float(sys.argv[2]), float(sys.argv[3]))
    out = os.path.abspath(sys.argv[1])
    for d in ('Textures/Weapons/VoiceOfSet', 'Materials/Weapons/VoiceOfSet', 'preview'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mkgold44.') as tmp:
        mg.extract('Fallout4 - Textures*.ba2', 'textures/weapons/44/', tmp)
        mg.extract('Fallout4 - Materials.ba2', 'materials/weapons/44/', tmp)
        for base, matfile, name, protect in PARTS:
            dds = open(os.path.join(tmp, 'textures/weapons/44/%s_d.dds' % base), 'rb').read()
            bgsm = open(os.path.join(tmp, 'materials/weapons/44/' + matfile), 'rb').read()
            h, w = struct.unpack_from('<II', dds, 12); mips = struct.unpack_from('<I', dds, 28)[0]
            if dds[84:88] != b'DX10' or struct.unpack_from('<I', dds, 128)[0] not in (71, 72): raise SystemExit('unexpected format for ' + base)
            body = dds[148:]
            new, kept = paint(body, w, h, mips, protect)
            tex = 'Weapons/VoiceOfSet/%s_d.dds' % name
            open(os.path.join(out, 'Textures', tex), 'wb').write(dds[:148] + new)
            bgsm = mg.patch_bgsm(mg.patch_bgsm(bgsm, OLD_TEX[base], tex), CUBE_OLD, CUBE_NEW)
            open(os.path.join(out, 'Materials/Weapons/VoiceOfSet/%s.BGSM' % name), 'wb').write(bgsm)
            # preview at mip 1
            skip = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * 8
            pw, ph = w // 2, h // 2
            a = mg.decode_bc1_mip0(body[skip:], pw, ph); b = mg.decode_bc1_mip0(new[skip:], pw, ph)
            sbs = bytearray()
            for y in range(ph): sbs += a[y * pw * 3:(y + 1) * pw * 3] + b[y * pw * 3:(y + 1) * pw * 3]
            mg.write_png(os.path.join(out, 'preview/%s-side-by-side.png' % name), pw * 2, ph, sbs)
            print('%s: %dx%d, %d mips, %d grip blocks greyed' % (name, w, h, mips, kept))

if __name__ == '__main__': main()
