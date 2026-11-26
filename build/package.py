#!/usr/bin/env python3
"""package.py: pack the art into the two .ba2 archives and make the installable release zip.

    python3 -B build/package.py VERSION [--plugin PATH]

Takes the built plugin (from the game's Data folder, or from --plugin, for a copy kept elsewhere) and the art from the three MO2 art
mods (made by build/art/), then:
checks that every material and texture the plugin and materials name is there, packs "RegaliaOfMystery - Main.ba2" (materials) and
"RegaliaOfMystery - Textures.ba2" with xEdit's BSArch through Proton's Wine, unpacks both with baunpack and compares them with the
sources, and writes RegaliaOfMystery-VERSION.zip with the readme from docs/release-readme.txt. It prints the plugin's SHA-256. Everything is written under ~/Games/mo2-lint/tools/our-assets/release/, outside the
repo: the output holds Bethesda-derived art and must NOT be committed.

Run it from the VS Code sandbox (it starts Wine on the host with flatpak-spawn). Needs baunpack and Rhodes scripts/esp/esp.py.
"""
import argparse, hashlib, re, shutil, subprocess, sys, zipfile
from pathlib import Path

HOME = Path.home()
sys.path.insert(0, str(HOME / 'Repos/Rhodes/scripts/esp'))
from esp import records

NAME = 'RegaliaOfMystery'
PLUGIN = HOME / '.local/share/Steam/steamapps/common/Fallout 4/Data' / (NAME + '.esp')
MODS = HOME / 'Games/mo2-lint/mo2-fallout4-steam/mods'
ART_MODS = ['Blade of Bastet Art', 'Garb of Mysteries Art', 'Veil of Secrets Art']
TOOLS = HOME / 'Games/mo2-lint/tools'
BSARCH = TOOLS / 'xEdit-4.1.5f/BSArch.exe'
WINE = HOME / '.local/share/Steam/steamapps/common/Proton 11.0/files/bin/wine'
PREFIX = TOOLS / 'bsarch-prefix'
BAUNPACK = HOME / '.local/bin/baunpack'
RELEASE = TOOLS / 'our-assets/release'
OUR_FOLDERS = ('regaliaofmystery/', 'weapons/bladeofbastet/', 'weapons/voiceofset/', 'clothes/garbofmysteries/', 'armor/veilofsecrets/')

README = Path(__file__).resolve().parent.parent / 'docs/release-readme.txt'


def fail(message):
    sys.exit('FAIL: ' + message)


def art_files():
    """lower-case relative path -> source file, over the art mods."""
    found = {}
    for mod in ART_MODS:
        for kind in ('Materials', 'Textures'):
            for path in sorted((MODS / mod / kind).rglob('*')):
                if path.is_file():
                    key = path.relative_to(MODS / mod).as_posix().lower()
                    if key in found:
                        fail('two art mods supply ' + key)
                    found[key] = path
    return found


def check(files, plugin):
    """Every material of ours that the plugin swaps in, and every texture of ours those materials name, must be present, and nothing else."""
    wanted = set()
    for sig, _, subs in records(str(plugin), {'MSWP'}):
        for key, value in subs:
            if sig == 'MSWP' and key == 'SNAM':    # the header (TES4) comes through too, with its own SNAM
                wanted.add('materials/' + value.rstrip(b'\0').decode().replace('\\', '/').lower())
    for material in sorted(wanted):
        if material not in files:
            fail('the plugin names a missing material: ' + material)
    textures = set()
    for material in wanted:
        for hit in re.findall(rb'[ -~]+\.dds', files[material].read_bytes(), re.IGNORECASE):
            path = hit.decode().replace('\\', '/').lower()
            if any(folder in path for folder in OUR_FOLDERS):
                textures.add('textures/' + path[path.index(next(f for f in OUR_FOLDERS if f in path)):])
    for texture in sorted(textures):
        if texture not in files:
            fail('a material names a missing texture: ' + texture)
    extra = set(files) - wanted - textures
    if extra:
        fail('art files nothing refers to: %s' % sorted(extra))
    print('art: %d materials, %d textures, all referenced' % (len(wanted), len(textures)))


def windows(path):
    return 'Z:' + str(path).replace('/', '\\')


def pack(stage, archive, mode):
    command = ['flatpak-spawn', '--host', 'env', 'WINEPREFIX=%s' % PREFIX, 'WINEDEBUG=-all', str(WINE), str(BSARCH),
               'pack', windows(stage), windows(archive), mode, '-z']
    result = subprocess.run(command, capture_output=True, text=True, errors='replace', timeout=600)
    if result.returncode or not archive.exists():
        print(result.stdout[-3000:], result.stderr[-3000:])
        fail('BSArch did not make ' + archive.name)


def verify(archive, files, kind, out):
    out.mkdir(parents=True)
    subprocess.run([str(BAUNPACK), str(archive), '--', '/'], cwd=out, check=True, stdout=subprocess.DEVNULL)
    got = {p.relative_to(out).as_posix().lower(): p for p in out.rglob('*') if p.is_file()}
    expected = {k: v for k, v in files.items() if k.startswith(kind)}
    if set(got) != set(expected):
        fail('%s holds %s, expected %s' % (archive.name, sorted(got), sorted(expected)))
    for key, source in expected.items():
        a, b = source.read_bytes(), got[key].read_bytes()
        if kind == 'textures':              # the archive stores pixel data and rebuilds the header: compare the pixels
            a, b = pixels(a), pixels(b)
        if a != b:
            fail('%s differs after unpacking' % key)
    head = archive.read_bytes()[:12]
    print('%s: %d files verified, format %s v%d, %d bytes' % (archive.name, len(got), head[8:12].decode(), head[4], archive.stat().st_size))


def pixels(dds):
    return dds[148:] if dds[84:88] == b'DX10' else dds[128:]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('version')
    parser.add_argument('--plugin', type=Path, default=PLUGIN, help='the built %s.esp (default: the game\'s Data folder)' % NAME)
    args = parser.parse_args()
    version, plugin = args.version, args.plugin.expanduser().resolve()
    if not plugin.is_file():
        fail('no plugin at %s; build it, or point --plugin at a kept copy' % plugin)
    if plugin.name != NAME + '.esp':
        fail('the plugin must be named %s.esp, not %s' % (NAME, plugin.name))
    print('plugin: %s\nsha256: %s' % (plugin, hashlib.sha256(plugin.read_bytes()).hexdigest()))
    readme = README.read_text(encoding='ascii').format(version=version, name=NAME)
    files = art_files()
    check(files, plugin)
    work = RELEASE / version
    if work.exists():
        fail('%s already exists; use a new version or move it away' % work)
    for key, source in files.items():
        relative = source.relative_to(source.parents[len(Path(key).parts) - 1])
        target = work / 'stage' / key.split('/')[0] / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    package = work / 'package'
    package.mkdir(parents=True)
    shutil.copyfile(plugin, package / plugin.name)
    main_ba2, tex_ba2 = package / (NAME + ' - Main.ba2'), package / (NAME + ' - Textures.ba2')
    pack(work / 'stage/materials', main_ba2, '-fo4')
    pack(work / 'stage/textures', tex_ba2, '-fo4dds')
    verify(main_ba2, files, 'materials', work / 'check/main')
    verify(tex_ba2, files, 'textures', work / 'check/textures')
    zip_path = RELEASE / ('%s-%s.zip' % (NAME, version))
    with zipfile.ZipFile(zip_path, 'x', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(package.iterdir()):
            z.write(path, path.name)
        z.writestr(NAME + ' - readme.txt', readme.replace('\n', '\r\n'))
    with zipfile.ZipFile(zip_path) as z:
        if z.testzip():
            fail('the zip is damaged')
        print('zip:', zip_path, zip_path.stat().st_size, 'bytes:', z.namelist())


if __name__ == '__main__':
    main()
