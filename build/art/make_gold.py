#!/usr/bin/env python3
"""make_gold.py: build a gold-tinted copy of the Chinese Officer Sword's diffuse texture and a matching material (.bgsm),
under OUR OWN paths, for the Blade of Bastet.   Status: WRITTEN 2026-11-24; read the report it prints.

Why this works (checked 2026-11-24 with baunpack): the sword's diffuse ChineseOfficerSword01_d.dds is BC1 (DXGI 71),
512 x 1024, 11 mips. A BC1 block is 8 bytes: two RGB565 endpoints and 16 two-bit indices. Recolouring the two endpoints of
every block (all mip levels) recolours the picture without decoding or re-encoding pixels, so the file stays valid.
The material is a copy of ChineseOfficerSword01B.BGSM (the bronze-cubemap variant) with the diffuse path changed.

Run:  python3 -I make_gold.py OUTDIR
It needs `baunpack` (Rhodes refs/fo4-archives.md). It writes under OUTDIR:
    Textures/Weapons/BladeOfBastet/BladeOfBastet_d.dds
    Materials/Weapons/BladeOfBastet/BladeOfBastetGold.BGSM
    preview/ original.png, gold.png, side-by-side.png   (mip 0, decoded here, for a look)
Outputs are derived from Bethesda's texture: do NOT commit them to a public repo.
"""
import os, struct, subprocess, sys, tempfile, zlib, glob

DATA = os.path.expanduser('~/.local/share/Steam/steamapps/common/Fallout 4/Data')
BAUNPACK = os.path.expanduser('~/.local/bin/baunpack')
NEW_TEX = 'Weapons/BladeOfBastet/BladeOfBastet_d.dds'          # path as stored inside the .bgsm (no "Textures/" prefix)
OLD_TEX = 'Weapons/ChineseOfficerSword/ChineseOfficerSword01_d.dds'
GOLD = (1.00, 0.80, 0.34)     # gold tint, applied to the luminance of each endpoint
GAIN = 1.35                   # brightness gain before tinting (the steel is mid-grey)
GAMMA = 0.92                  # <1 lifts the shadows slightly

def extract(archive_glob, pattern, dest):
    for a in sorted(glob.glob(os.path.join(DATA, archive_glob))):
        subprocess.run([BAUNPACK, a, '--', pattern], cwd=dest, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def rgb565(v): return (((v >> 11) & 31) * 255 // 31, ((v >> 5) & 63) * 255 // 63, (v & 31) * 255 // 31)
def pack565(r, g, b): return ((r * 31 + 127) // 255 << 11) | ((g * 63 + 127) // 255 << 5) | ((b * 31 + 127) // 255)

def goldify(rgb):
    l = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255.0
    l = min(1.0, (l ** GAMMA) * GAIN)
    return tuple(max(0, min(255, int(round(255 * l * t)))) for t in GOLD)

def tint_bc1(data):
    """Recolour every BC1 block's endpoints. Keeps the 4-colour (c0>c1) or 3-colour (c0<=c1) mode, permuting indices on a swap."""
    out = bytearray(data)
    n = len(data) // 8
    swaps = 0
    for i in range(n):
        o = i * 8
        c0, c1 = struct.unpack_from('<HH', out, o)
        four = c0 > c1
        n0 = pack565(*goldify(rgb565(c0)))
        n1 = pack565(*goldify(rgb565(c1)))
        idx = struct.unpack_from('<I', out, o + 4)[0]
        if four:
            if n0 == n1: n0 = min(0xFFFF, n1 + 1)          # keep 4-colour mode
            if n0 < n1:                                    # order flipped: swap endpoints, permute 0<->1 and 2<->3
                n0, n1 = n1, n0
                idx = permute(idx, {0: 1, 1: 0, 2: 3, 3: 2}); swaps += 1
        else:
            if n0 > n1:                                    # keep 3-colour mode: swap, permute 0<->1 (2 and 3 stay)
                n0, n1 = n1, n0
                idx = permute(idx, {0: 1, 1: 0, 2: 2, 3: 3}); swaps += 1
        struct.pack_into('<HHI', out, o, n0, n1, idx)
    return bytes(out), swaps

def permute(idx, m):
    r = 0
    for k in range(16):
        r |= m[(idx >> (2 * k)) & 3] << (2 * k)
    return r

def decode_bc1_mip0(data, w, h):
    px = bytearray(w * h * 3)
    bw = (w + 3) // 4
    for by in range((h + 3) // 4):
        for bx in range(bw):
            o = (by * bw + bx) * 8
            c0, c1, idx = struct.unpack_from('<HHI', data, o)
            a, b = rgb565(c0), rgb565(c1)
            if c0 > c1:
                cols = [a, b, tuple((2 * x + y) // 3 for x, y in zip(a, b)), tuple((x + 2 * y) // 3 for x, y in zip(a, b))]
            else:
                cols = [a, b, tuple((x + y) // 2 for x, y in zip(a, b)), (0, 0, 0)]
            for k in range(16):
                x, y = bx * 4 + (k & 3), by * 4 + (k >> 2)
                if x < w and y < h:
                    px[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(cols[(idx >> (2 * k)) & 3])
    return px

def write_png(path, w, h, rgb):
    raw = b''.join(b'\x00' + bytes(rgb[y * w * 3:(y + 1) * w * 3]) for y in range(h))
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))

def patch_bgsm(src, old, new):
    """Replace one length-prefixed (u32, includes the NUL) string inside a .bgsm."""
    o = old.encode() + b'\x00'
    i = src.find(struct.pack('<I', len(o)) + o)
    if i < 0: raise SystemExit('could not find the length-prefixed string %r in the .bgsm' % old)
    n = new.encode() + b'\x00'
    return src[:i] + struct.pack('<I', len(n)) + n + src[i + 4 + len(o):]

def main():
    if len(sys.argv) != 2: raise SystemExit(__doc__)
    out = os.path.abspath(sys.argv[1])
    for d in ('Textures/Weapons/BladeOfBastet', 'Materials/Weapons/BladeOfBastet', 'preview'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mkgold.') as tmp:
        extract('Fallout4 - Textures*.ba2', 'weapons/chineseofficersword/chineseofficersword01_d.dds', tmp)
        extract('Fallout4 - Materials.ba2', 'weapons/chineseofficersword/chineseofficersword01b.bgsm', tmp)
        dds = open(os.path.join(tmp, 'textures/weapons/chineseofficersword/chineseofficersword01_d.dds'), 'rb').read()
        bgsm = open(os.path.join(tmp, 'materials/weapons/chineseofficersword/chineseofficersword01b.bgsm'), 'rb').read()
    magic, size, flags, h, w, pitch, depth, mips = struct.unpack('<4sIIIIIII', dds[:32])
    fourcc = dds[84:88]
    dxgi = struct.unpack('<I', dds[128:132])[0] if fourcc == b'DX10' else 0
    if magic != b'DDS ' or fourcc != b'DX10' or dxgi not in (71, 72): raise SystemExit('unexpected texture format: %r dxgi %d' % (fourcc, dxgi))
    hdr_len = 148
    body = dds[hdr_len:]
    total = sum(max(1, (max(1, w >> m) + 3) // 4) * max(1, (max(1, h >> m) + 3) // 4) * 8 for m in range(mips))
    if total != len(body): raise SystemExit('size mismatch: mips say %d, file has %d' % (total, len(body)))
    tinted, swaps = tint_bc1(body)
    open(os.path.join(out, 'Textures/Weapons/BladeOfBastet/BladeOfBastet_d.dds'), 'wb').write(dds[:hdr_len] + tinted)
    open(os.path.join(out, 'Materials/Weapons/BladeOfBastet/BladeOfBastetGold.BGSM'), 'wb').write(patch_bgsm(bgsm, OLD_TEX, NEW_TEX))
    a = decode_bc1_mip0(body, w, h); b = decode_bc1_mip0(tinted, w, h)
    write_png(os.path.join(out, 'preview/original.png'), w, h, a)
    write_png(os.path.join(out, 'preview/gold.png'), w, h, b)
    sbs = bytearray()
    for y in range(h): sbs += a[y * w * 3:(y + 1) * w * 3] + b[y * w * 3:(y + 1) * w * 3]
    write_png(os.path.join(out, 'preview/side-by-side.png'), w * 2, h, sbs)
    print('texture %dx%d BC1, %d mips, %d blocks recoloured, %d endpoint swaps' % (w, h, mips, len(body) // 8, swaps))
    print('wrote:'); [print('  ', os.path.relpath(p, out)) for p in sorted(glob.glob(out + '/**/*.*', recursive=True))]

if __name__ == '__main__': main()
