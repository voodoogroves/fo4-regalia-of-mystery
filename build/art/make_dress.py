#!/usr/bin/env python3
"""make_dress.py: recolour the Sequin Dress's diffuse texture for the Garb of Mysteries: charcoal body, emerald chevrons, cream-gold top band.
Status: WRITTEN 2026-11-24 (first pass; the stripe placement needs in-game screenshots to tune).

The Sequin Dress (ClothesSequinDress 0011A27B, worn mesh Clothes\\SlinkyDress\\DressFSequin.nif) has ONE material
(SequinDress.BGSM) and ONE texture set, SlinkySequinDress_d.dds: BC1 (DXGI 71), 2048 x 2048, 12 mips. The picture is already a
dark navy-black sequin dress: a darker band across the top, a big body area, and a strip of small parts on the right.
A BC1 block is 4 x 4 pixels (8 bytes: two RGB565 endpoints and 16 two-bit indices), so recolouring only the blocks that fall
inside a stripe shape paints the stripe while keeping the sequin sparkle. Every mip level is painted from the same shape in
normalised coordinates, so the stripes do not vanish at a distance.

Run:  python3 -I make_dress.py OUTDIR [--uc 0.415] [--y0 0.40] [--pitch 0.115] [--bands 3] [--thick 0.045] [--slope 0.30]
Writes under OUTDIR:  Textures/Clothes/GarbOfMysteries/GarbOfMysteries_d.dds,  Materials/Clothes/GarbOfMysteries/GarbOfMysteries.BGSM
                      preview/original.png, preview/chevrons.png, preview/side-by-side.png   (decoded here, mip 2, 512 x 512)
Needs baunpack (Rhodes refs/fo4-archives.md). Outputs are derived from Bethesda's texture: NOT committed to a public repo.
Coordinates are fractions of the texture (u to the right, v DOWN as in the preview). The body area is about u 0.00-0.83, v 0.23-1.00.
"""
import os, struct, sys, tempfile, glob, argparse, importlib.util

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('make_gold', os.path.join(here, 'make_gold.py'))
mg = importlib.util.module_from_spec(spec); spec.loader.exec_module(mg)

# Colour references, measured 2026-11-24 from an in-game picture of the Fallout 76 outfit (median RGB): green chevrons 65,137,80;
# dress body 53,56,57 (neutral charcoal); gloves and leggings 39,41,41; collar ruffle 198,181,150 (pale cream-gold).
# (The concept art Chris saved first had darker greens: median 36,68,38; it is a painting, the in-game picture is lit.)
TINT = (0.47, 1.00, 0.58)    # chevron green: a mid emerald with a cool, slightly mint cast
GAIN = 1.60                  # lifts the dark base (mean luminance about 0.25) to roughly RGB 48,102,60 (Chris: darker than the in-game reference 65,137,80)
CAP = 0.72                   # caps the brightest sparkle
SHOE_U, SHOE_V = 0.825, 0.165   # the SHOE shape sits in the lower right corner of the band region (u >= 0.825, v >= 0.165): leave it alone
CHARCOAL = (0.97, 1.00, 1.00); CHARCOAL_GAIN = 0.50; CHARCOAL_CAP = 0.30   # darker body; the cap keeps the sequin sparkle from lightening it     # body: neutral charcoal (navy blue cast removed)
CREAM = (0.92, 0.84, 0.68); CREAM_GAIN = 3.4; CREAM_CAP = 0.95   # top band: pale cream-gold, the folds stay as shading
# Chevron geometry (fractions of the texture; v is DOWN). MEASURED in game 2026-11-24 with the --debug-uv texture on mannequins:
#   - the FRONT centre of the body is at u about 0.45 (the green/cyan boundary); yellow (u 0.2) is the wearer's right side, blue (0.65) the left;
#   - the BACK centre is the texture's seam (magenta u 0.83 meets red u 0.0); u runs 0 to 0.83 around the whole body;
#   - v runs down the body: the neckline is at the top (v about 0.23), the hem at the bottom (1.0);
#   - the top band (v < 0.225) is the shoulder cowl; its own seam is at the FRONT of the chest;
#   - the SHOES reuse the right-hand part of the top band (u above about 0.8), so that part must not be tinted cream.
OLD_TEX = 'Clothes/SlinkyDress/SlinkySequinDress_d.dds'
NEW_TEX = 'Clothes/GarbOfMysteries/GarbOfMysteries_d.dds'

def green(rgb):
    l = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255.0
    l = min(CAP, l * GAIN)
    return tuple(max(0, min(255, int(round(255 * l * t)))) for t in TINT)

def make_zones(a):
    """Return zone(u, v) -> 'stripe' | 'band' | 'body' | None.  Texture layout: top band v<0.225 (u up to 0.98), body u<0.83 v>=0.23,
    a strip of small parts (zip, shoes) on the right that is left alone."""
    def zone(u, v):
        if v < 0.225:
            if u >= 0.985 or (u >= SHOE_U and v >= SHOE_V): return None
            return 'band'
        if u > 0.83: return None
        d = abs(u - a.uc)
        if d <= a.uspan:
            centre = a.y0 + a.slope * (a.uspan - d)        # V pointing down: lowest (largest v) at the centre line
            for k in range(a.bands):
                if abs(v - (centre + k * a.pitch)) <= a.thick / 2: return 'stripe'
        return 'body'
    return zone

def tone(rgb, tint, gain, cap):
    l = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255.0
    l = min(cap, l * gain)
    return tuple(max(0, min(255, int(round(255 * l * t)))) for t in tint)

DEBUG_HUES = [(1, .1, .1), (1, .55, .05), (1, 1, .1), (.55, 1, .1), (.05, .8, .2), (.05, .9, .9), (.1, .3, 1), (.55, .2, 1), (1, .1, .85), (1, 1, 1)]
def debug_colour(u, v):
    """UV test colour: column (u in tenths) = a distinct hue; row (v in tenths) fades from light (top) to dark (bottom)."""
    h = DEBUG_HUES[min(9, int(u * 10))]; f = 1.0 - 0.07 * min(9, int(v * 10))
    return pack565(int(255 * h[0] * f), int(255 * h[1] * f), int(255 * h[2] * f))

def pack565(r, g, b): return mg.pack565(r, g, b)

def stripe_sd(u, v, a):
    """Signed distance (uv units, negative inside) to the chevron stripes: bands pointing down, limited to |u-uc| <= uspan."""
    import math
    d = abs(u - a.uc)
    best = 9.0
    for k in range(a.bands):
        c = a.y0 + a.slope * (a.uspan - d) + k * a.pitch
        best = min(best, abs(v - c) - a.thick / 2)
    return max(best / math.sqrt(1 + a.slope * a.slope), d - a.uspan)

def decode_block(blk):
    c0, c1, idx = struct.unpack('<HHI', blk)
    A, B = mg.rgb565(c0), mg.rgb565(c1)
    if c0 > c1: cols = [A, B, tuple((2 * x + y) // 3 for x, y in zip(A, B)), tuple((x + 2 * y) // 3 for x, y in zip(A, B))]
    else: cols = [A, B, tuple((x + y) // 2 for x, y in zip(A, B)), (0, 0, 0)]
    return [cols[(idx >> (2 * k)) & 3] for k in range(16)]

def encode_block(px):
    """A simple BC1 encoder (4-colour mode): endpoints at the darkest and brightest pixel, indices to the nearest palette colour."""
    lum = lambda p: 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
    lo = min(px, key=lum); hi = max(px, key=lum)
    c0 = mg.pack565(*hi); c1 = mg.pack565(*lo)
    if c0 == c1: c0 = min(0xFFFF, c1 + 1)
    if c0 < c1: c0, c1 = c1, c0
    A, B = mg.rgb565(c0), mg.rgb565(c1)
    pal = [A, B, tuple((2 * x + y) // 3 for x, y in zip(A, B)), tuple((x + 2 * y) // 3 for x, y in zip(A, B))]
    idx = 0
    for k, p in enumerate(px):
        j = min(range(4), key=lambda i: (p[0] - pal[i][0]) ** 2 + (p[1] - pal[i][1]) ** 2 + (p[2] - pal[i][2]) ** 2)
        idx |= j << (2 * k)
    return struct.pack('<HHI', c0, c1, idx)

def lerp(p, q, t): return tuple(int(round(x * (1 - t) + y * t)) for x, y in zip(p, q))

def endpoint_transform(out, o, fn):
    c0, c1, idx = struct.unpack_from('<HHI', out, o)
    four = c0 > c1
    n0 = mg.pack565(*fn(mg.rgb565(c0))); n1 = mg.pack565(*fn(mg.rgb565(c1)))
    if four:
        if n0 == n1: n0 = min(0xFFFF, n1 + 1)
        if n0 < n1: n0, n1 = n1, n0; idx = mg.permute(idx, {0: 1, 1: 0, 2: 3, 3: 2})
    else:
        if n0 > n1: n0, n1 = n1, n0; idx = mg.permute(idx, {0: 1, 1: 0, 2: 2, 3: 3})
    struct.pack_into('<HHI', out, o, n0, n1, idx)

def paint_level(data, w, h, zone, a, debug=False):
    """Recolour one mip level. Blocks wholly inside a stripe or wholly outside are recoloured by their endpoints (keeps the sparkle);
    blocks the stripe EDGE crosses are decoded, blended per pixel by anti-aliased coverage, and re-encoded: smooth edges at every mip."""
    out = bytearray(data)
    bw, bh = max(1, (w + 3) // 4), max(1, (h + 3) // 4)
    counts = {'stripe': 0, 'band': 0, 'body': 0, 'edge': 0}
    ps = 1.0 / max(w, 4); hd = 2.9 * ps
    body_fn = lambda x: tone(x, CHARCOAL, CHARCOAL_GAIN, CHARCOAL_CAP)
    stripe_fn = lambda x: tone(x, TINT, GAIN, CAP)
    cream_fn = lambda x: tone(x, CREAM, CREAM_GAIN, CREAM_CAP)
    for by in range(bh):
        for bx in range(bw):
            u = min(1.0, (bx * 4 + 2) / max(w, 4)); v = min(1.0, (by * 4 + 2) / max(h, 4))
            z = zone(u, v)
            if z is None: continue
            o = (by * bw + bx) * 8
            if debug:
                c = debug_colour(u, v); struct.pack_into('<HHI', out, o, c, c, 0); counts[z] += 1; continue
            if z == 'band':
                endpoint_transform(out, o, cream_fn); counts['band'] += 1; continue
            # body area: is the stripe near?
            sd = stripe_sd(u, v, a)
            if sd > hd + ps: endpoint_transform(out, o, body_fn); counts['body'] += 1
            elif sd < -(hd + ps): endpoint_transform(out, o, stripe_fn); counts['stripe'] += 1
            else:
                px = decode_block(bytes(out[o:o + 8])); newpx = []
                for k, p in enumerate(px):
                    pu = (bx * 4 + (k & 3) + 0.5) / max(w, 4); pv = (by * 4 + (k >> 2) + 0.5) / max(h, 4)
                    cov = max(0.0, min(1.0, 0.5 - stripe_sd(pu, pv, a) / ps))
                    newpx.append(lerp(body_fn(p), stripe_fn(p), cov))
                out[o:o + 8] = encode_block(newpx); counts['edge'] += 1
    return bytes(out), counts

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('out')
    ap.add_argument('--uc', type=float, default=0.45, help='front centre of the dress (fraction of texture width; measured 0.45)')
    ap.add_argument('--uspan', type=float, default=0.15, help='half-width of the chevrons'); ap.add_argument('--y0', type=float, default=0.31, help='v of the top band at its outer ends (just under the cowl)')
    ap.add_argument('--pitch', type=float, default=0.095); ap.add_argument('--bands', type=int, default=3)
    ap.add_argument('--thick', type=float, default=0.04); ap.add_argument('--slope', type=float, default=0.60)
    ap.add_argument('--debug-uv', action='store_true', help='write a UV test texture (coloured columns and light-to-dark rows) instead of the recolour')
    ap.add_argument('--tint', default=None, help='r,g,b fractions, e.g. 0.30,0.74,0.10 for the brighter kelly green'); ap.add_argument('--gain', type=float, default=None); ap.add_argument('--cap', type=float, default=None)
    a = ap.parse_args(); out = os.path.abspath(a.out)
    global TINT, GAIN, CAP
    if a.tint: TINT = tuple(float(x) for x in a.tint.split(','))
    if a.gain is not None: GAIN = a.gain
    if a.cap is not None: CAP = a.cap
    for d in ('Textures/Clothes/GarbOfMysteries', 'Materials/Clothes/GarbOfMysteries', 'preview'): os.makedirs(os.path.join(out, d), exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mkdress.') as tmp:
        mg.extract('Fallout4 - Textures*.ba2', 'clothes/slinkydress/slinkysequindress_d.dds', tmp)
        mg.extract('Fallout4 - Materials.ba2', 'clothes/slinkydress/sequindress.bgsm', tmp)
        dds = open(os.path.join(tmp, 'textures/clothes/slinkydress/slinkysequindress_d.dds'), 'rb').read()
        bgsm = open(os.path.join(tmp, 'materials/clothes/slinkydress/sequindress.bgsm'), 'rb').read()
    magic, size, flags, h, w, pitch, depth, mips = struct.unpack('<4sIIIIIII', dds[:32])
    if magic != b'DDS ' or dds[84:88] != b'DX10' or struct.unpack('<I', dds[128:132])[0] not in (71, 72): raise SystemExit('unexpected texture format')
    hdr = 148; body = dds[hdr:]; zone = make_zones(a)
    res = bytearray(); off = 0; total = {'stripe': 0, 'band': 0, 'body': 0, 'edge': 0}; level_dump = {}
    for m in range(mips):
        lw, lh = max(1, w >> m), max(1, h >> m)
        sz = max(1, (lw + 3) // 4) * max(1, (lh + 3) // 4) * 8
        lvl, n = paint_level(body[off:off + sz], lw, lh, zone, a, a.debug_uv)
        res += lvl; level_dump[m] = (off, sz, lw, lh); off += sz
        for k in n: total[k] += n[k]
    if off != len(body): raise SystemExit('size mismatch')
    open(os.path.join(out, 'Textures/Clothes/GarbOfMysteries/GarbOfMysteries_d.dds'), 'wb').write(dds[:hdr] + bytes(res))
    open(os.path.join(out, 'Materials/Clothes/GarbOfMysteries/GarbOfMysteries.BGSM'), 'wb').write(mg.patch_bgsm(bgsm, OLD_TEX, NEW_TEX))
    o2, s2, w2, h2 = level_dump[2]
    A = mg.decode_bc1_mip0(body[o2:o2 + s2], w2, h2); B = mg.decode_bc1_mip0(bytes(res)[o2:o2 + s2], w2, h2)
    mg.write_png(os.path.join(out, 'preview/original.png'), w2, h2, A); mg.write_png(os.path.join(out, 'preview/' + ('uvdebug.png' if a.debug_uv else 'garb.png')), w2, h2, B)
    sbs = bytearray()
    for y in range(h2): sbs += A[y * w2 * 3:(y + 1) * w2 * 3] + B[y * w2 * 3:(y + 1) * w2 * 3]
    mg.write_png(os.path.join(out, 'preview/side-by-side.png'), w2 * 2, h2, sbs)
    if not a.debug_uv:      # full-resolution crop (mip 0) around the chevrons, original beside recoloured
        lw0 = w; cx0, cx1 = int((a.uc - a.uspan - 0.03) * w), int((a.uc + a.uspan + 0.03) * w); cy0, cy1 = int((a.y0 - 0.04) * h), int((a.y0 + a.slope * a.uspan + a.pitch * a.bands + 0.05) * h)
        sz0 = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * 8
        P0 = mg.decode_bc1_mip0(body[:sz0], w, h); P1 = mg.decode_bc1_mip0(bytes(res)[:sz0], w, h)
        cw = cx1 - cx0; crop = bytearray()
        for y in range(cy0, cy1): crop += P0[(y * w + cx0) * 3:(y * w + cx1) * 3] + P1[(y * w + cx0) * 3:(y * w + cx1) * 3]
        mg.write_png(os.path.join(out, 'preview/chevron-crop-mip0.png'), cw * 2, cy1 - cy0, crop)
    print('texture %dx%d BC1, %d mips, blocks recoloured (all mips): %s%s' % (w, h, mips, total, '  [UV DEBUG TEXTURE]' if a.debug_uv else ''))
    print('params:', {k: v for k, v in vars(a).items() if k != 'out'})
    for p in sorted(glob.glob(out + '/**/*.*', recursive=True)): print('  ', os.path.relpath(p, out))

if __name__ == '__main__': main()
