#!/usr/bin/env python3
"""make_photo.py: put our own picture into the Silver Shroud photo's frame, for the Cryptos book.
Status: the card seen in game 2026-11-25 (looked good). The faded note page (round 4) is not yet reported.

TWO textures. The card in the world (low-poly mesh) gets the full picture. The reading view and inventory preview use the standard full
note page (Interface\\Newspaper\\Note.nif, material Interface\\Note\\Note.BGSM): the picture is printed FADED into that paper (multiplied,
so the creases stay), so the book text can be read over it (--fade: 0 = blank paper, 1 = full strength). The first try used the large
photo page, where the text ran off the right edge.

The photo (our copy of BOOK 0018AC1E) uses Props\\Photo01LowPoly_SilverShroud.nif, and so does its inventory STAT 0020B29A.
One material, Interface\\Note\\PhotoHorizLowPolySilverShroud.BGSM; its diffuse is BC3, 2048 x 2048, ONE mip. The front of the card is
the left part of the texture, the brown back is the right part. Only the picture area inside the frame is replaced (the frame, the back
and the alpha blocks stay vanilla). The picture is scaled to cover that area, centre-cropped, and warmed and dimmed a little.

Run:  python3 -B make_photo.py PICTURE OUTDIR [--dim 0.86] [--fade 0.35]
Writes: Textures/RegaliaOfMystery/Cryptos{Sketch,Page}_d.dds, Materials/RegaliaOfMystery/Cryptos{Sketch,Page}.BGSM, preview/{photo,page}.png.
Needs baunpack and ffmpeg. Outputs hold Bethesda's texture: do NOT commit them.
"""
import os, struct, subprocess, sys, tempfile, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_gold as mg
import make_dress as md                # its BC1 block decoder and encoder

# our name: (vanilla texture and material, texture path as written in the material, picture area in pixels, preview file)
CARD = ('CryptosSketch', 'interface/note/photohorizlowpolysilvershroud', 'Interface/Note/PhotoHorizLowPolySilverShroud_d.dds', (52, 230, 1188, 1614), 'photo')
PAGE = ('CryptosPage', 'interface/note/note', 'Interface/Note/Note_d.dds', (416, 264, 1632, 1784), 'page')
PICTURE_PAPER = 0.90                   # brightness of the sketch's own blank paper: that and brighter leaves the note page untouched
WARM = (1.00, 0.96, 0.88)              # aged paper

def load_picture(path, w, h):
    """The picture as raw RGB, scaled to cover w x h and centre-cropped."""
    vf = 'scale=%d:%d:force_original_aspect_ratio=increase:flags=lanczos,crop=%d:%d' % (w, h, w, h)
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-vf', vf, '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
                         check=True, stdout=subprocess.PIPE).stdout
    if len(raw) != w * h * 3: raise SystemExit('ffmpeg returned %d bytes, expected %d' % (len(raw), w * h * 3))
    return raw

def build(a, out, part, fade):
    name, src, old_tex, area, preview = part
    with tempfile.TemporaryDirectory(prefix='mkphoto.') as tmp:
        mg.extract('Fallout4 - Textures*.ba2', src + '_d.dds', tmp); mg.extract('Fallout4 - Materials.ba2', src + '.bgsm', tmp)
        dds = open(os.path.join(tmp, 'textures/%s_d.dds' % src), 'rb').read()
        bgsm = open(os.path.join(tmp, 'materials/%s.bgsm' % src), 'rb').read()
    h, w = struct.unpack_from('<II', dds, 12)
    if dds[84:88] != b'DX10' or struct.unpack_from('<I', dds, 128)[0] not in (77, 78) or len(dds) != 148 + w * h:
        raise SystemExit('unexpected texture format (expected BC3 with one mip)')
    left, top, right, bottom = area; pw, ph = right - left, bottom - top
    pic = load_picture(a.picture, pw, ph)
    def new_pixel(x, y, under):
        o = (y * pw + x) * 3
        if fade is None: return tuple(min(255, int(round(pic[o + c] * WARM[c] * a.dim))) for c in range(3))
        ink = min(1.0, (0.299 * pic[o] + 0.587 * pic[o + 1] + 0.114 * pic[o + 2]) / 255.0 / PICTURE_PAPER)
        return tuple(int(round(c * (1.0 - fade * (1.0 - ink)))) for c in under)
    res = bytearray(dds); full = bytearray(w * h * 3); bw = w // 4
    for by in range(h // 4):
        for bx in range(bw):
            o = 148 + (by * bw + bx) * 16 + 8              # the colour half; the alpha half before it is left as it was
            old = md.decode_block(bytes(res[o:o + 8]))
            xy = [(bx * 4 + (k & 3), by * 4 + (k >> 2)) for k in range(16)]
            if any(left <= x < right and top <= y < bottom for x, y in xy):
                px = [new_pixel(x - left, y - top, p) if left <= x < right and top <= y < bottom else p for (x, y), p in zip(xy, old)]
                res[o:o + 8] = md.encode_block(px)
                old = md.decode_block(bytes(res[o:o + 8]))
            for (x, y), p in zip(xy, old): full[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(p)
    new_tex = 'RegaliaOfMystery/%s_d.dds' % name
    open(os.path.join(out, 'Textures', new_tex), 'wb').write(res)
    open(os.path.join(out, 'Materials/RegaliaOfMystery/%s.BGSM' % name), 'wb').write(mg.patch_bgsm(bgsm, old_tex, new_tex))
    mg.write_png(os.path.join(out, 'preview/%s.png' % preview), w, h, full)
    print('%s: texture %dx%d, picture area %dx%d, dim %.2f, fade %s' % (name, w, h, pw, ph, a.dim, fade))

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('picture'); ap.add_argument('out')
    ap.add_argument('--dim', type=float, default=0.86); ap.add_argument('--fade', type=float, default=0.35)
    a = ap.parse_args(); out = os.path.abspath(a.out)
    for d in ('Textures/RegaliaOfMystery', 'Materials/RegaliaOfMystery', 'preview'): os.makedirs(os.path.join(out, d), exist_ok=True)
    build(a, out, CARD, None)
    build(a, out, PAGE, a.fade)

if __name__ == '__main__': main()
