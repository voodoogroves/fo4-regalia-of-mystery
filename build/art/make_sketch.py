#!/usr/bin/env python3
"""make_sketch.py: turn our Fallout 4 screenshot into the pencil sketch on the Cryptos book. Plain ffmpeg filters, no generative AI.

The source is the owner's own screenshot (vanilla assets and this mod's gear), kept outside the repos as
photo-candidates/candidate-04-source-screenshot.png. The crop and the white box below fit that picture only.

Run:  python3 -B make_sketch.py SCREENSHOT OUT.png      then give OUT.png to make_photo.py.
Needs ffmpeg. The output shows Bethesda's art: do NOT commit it.
"""
import os, subprocess, sys, tempfile

SKETCH = ('[0]crop=560:700:60:45,scale=1216:1520:flags=lanczos,format=gray,median=radius=2,split=3[g][b][t];'
          '[b]negate,gblur=sigma=20[i];'
          '[i][g]blend=all_mode=dodge,eq=gamma=0.6[line];'
          "[t]gblur=sigma=1.2,curves=all='0/0.12 0.35/0.55 0.6/0.95 1/1',eq=gamma=1.8[tone];"
          '[line][tone]blend=all_mode=multiply:all_opacity=0.75,format=gray')
WHITEN = "curves=all='0/0 0.5/0.5 0.86/0.96 0.91/1 1/1',format=gray"        # clear the sky
BLANK = 'drawbox=x=0:y=1385:w=520:h=135:color=white:t=fill,format=gray'     # remove the rooftop block


def ffmpeg(source, option, filters, target):
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', source, option, filters, '-frames:v', '1', target], check=True)


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    source, out = sys.argv[1], sys.argv[2]
    with tempfile.TemporaryDirectory(prefix='mksketch.') as tmp:
        sketch, whitened = os.path.join(tmp, 'sketch.png'), os.path.join(tmp, 'whitened.png')
        ffmpeg(source, '-filter_complex', SKETCH, sketch)
        ffmpeg(sketch, '-vf', WHITEN, whitened)
        ffmpeg(whitened, '-vf', BLANK, out)
    print('wrote', out)


if __name__ == '__main__':
    main()
