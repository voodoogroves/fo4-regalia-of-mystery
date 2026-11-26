#!/usr/bin/env python3
"""Compare the merged RegaliaOfMystery.esp, record by record, with what the six test plugins produce together.

    python3 -B build/check/compare_chain.py [--data DIR] [--new FILE]
    python3 -B build/check/compare_chain.py --chain-only      # just load the test chain and list it

Our records are matched by editor ID, placed references by what they place, and overrides of game records by FormID.
References to our own records are rewritten to editor IDs first, so different FormIDs do not count as differences.
Every difference printed should be one the merge intended. Reads only. Needs Rhodes scripts/esp/esp.py.
"""
import argparse, difflib, struct, sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / 'Repos/Rhodes/scripts/esp'))
from esp import records, edid

CHAIN = ['RegaliaGold1', 'RegaliaGarb2', 'RegaliaVeil1', 'RegaliaBroken2', 'RegaliaVoice12', 'RegaliaWorld10']
DATA = Path.home() / '.local/share/Steam/steamapps/common/Fallout 4/Data'


def load(path):
    """Return (header subrecords, header flags, [(sig, origin file, object id, flags, subrecords)])."""
    with open(path, 'rb') as f:
        head_flags = struct.unpack_from('<I', f.read(12), 8)[0]
    flags_at = record_flags(path)
    header, out = None, []
    for sig, fid, subs in records(str(path)):
        if sig == 'TES4':
            header = subs
            masters = [v.rstrip(b'\0').decode() for k, v in subs if k == 'MAST'] + [path.name]
            continue
        index = min(fid >> 24, len(masters) - 1)
        out.append((sig, masters[index], fid & 0xFFFFFF, flags_at[fid], subs))
    return header, head_flags, out


def record_flags(path):
    data = path.read_bytes()
    found = {}

    def walk(pos, end):
        while pos + 24 <= end:
            sig, size = data[pos:pos + 4], struct.unpack_from('<I', data, pos + 4)[0]
            if sig == b'GRUP':
                walk(pos + 24, pos + size)
                pos += size
                continue
            flags, fid = struct.unpack_from('<II', data, pos + 8)
            found[fid] = flags & ~0x40000          # ignore "compressed"
            pos += 24 + size

    walk(0, len(data))
    return found


def gather(paths):
    """Winning version of each record over the plugins in load order, with our references rewritten to names."""
    names = {}                                      # (origin file, object id) -> editor ID, for our records
    loaded = []
    ours = {p.name for p in paths}
    for path in paths:
        _, _, recs = load(path)
        masters = [v.rstrip(b'\0').decode() for k, v in load(path)[0] if k == 'MAST'] + [path.name]
        loaded.append((masters, recs))
        for sig, origin, oid, flags, subs in recs:
            if origin in ours and edid(subs):
                names[(origin, oid)] = edid(subs)
    winners = {}
    for masters, recs in loaded:
        table = {}                                  # this file's FormID bytes -> token
        for index, master in enumerate(masters):
            for (origin, oid), name in names.items():
                if origin == master:
                    table[struct.pack('<I', index << 24 | oid)] = name
        for sig, origin, oid, flags, subs in recs:
            new = [Sub(k, v, table) for k, v in subs]
            winners[(origin, oid)] = (sig, flags, new, table)
    result = {}
    for (origin, oid), (sig, flags, subs, table) in winners.items():
        if origin in ours:
            name = names.get((origin, oid))
            if not name:                            # a placed reference
                base = next((x.value for x in subs if x.sig == 'NAME'), b'')
                name = 'placed <%s>' % table.get(base, base.hex())
        else:
            name = '%s:%06X' % (origin, oid)
        key = (sig, name)
        if key in result:
            sys.exit('two records share the key %s' % (key,))
        result[key] = (flags, subs, oid, origin in ours)
    return result


class Sub:
    """One subrecord. Two are equal when their bytes match, except where both sides hold a reference to the same one of our records."""

    def __init__(self, sig, value, table):
        self.sig, self.value, self.table = sig, value, table

    def __hash__(self):
        return hash((self.sig, len(self.value)))

    def __eq__(self, other):
        a, b = self.value, other.value
        if self.sig != other.sig or len(a) != len(b):
            return False
        i = 0
        while i < len(a):
            name = self.table.get(a[i:i + 4])
            if name and other.table.get(b[i:i + 4]) == name:
                i += 4
            elif a[i] == b[i]:
                i += 1
            else:
                return False
        return True

    def __str__(self):
        if len(self.value) == 4 and self.value in self.table:
            return '%s <%s>' % (self.sig, self.table[self.value])
        return '%s %s' % (self.sig, show(self.sig, self.value))


def show(sig, value):
    text = value.rstrip(b'\0')
    if text and all(32 <= c < 127 or c in (9, 10, 13) for c in text) and (len(text) > 3 or sig in ('FULL', 'EDID')):
        return repr(text.decode())
    return value.hex(' ', 4) if len(value) <= 64 else value[:64].hex(' ', 4) + ' ... (%d bytes)' % len(value)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', type=Path, default=DATA)
    ap.add_argument('--new', type=Path)
    ap.add_argument('--chain-only', action='store_true')
    args = ap.parse_args()
    old = gather([args.data / (n + '.esp') for n in CHAIN])
    if args.chain_only:
        for sig, name in sorted(old):
            print(sig, name)
        print(len(old), 'records')
        return
    path = args.new or args.data / 'RegaliaOfMystery.esp'
    header, head_flags, recs = load(path)
    new = gather([path])
    masters = [v.rstrip(b'\0').decode() for k, v in header if k == 'MAST']
    version, count, next_id = struct.unpack('<fII', dict(header)['HEDR'])
    own = [r for r in recs if r[1] == path.name]
    outside = [r for r in own if not 0x800 <= r[2] <= 0xFFF]
    print('file         ', path)
    print('masters      ', masters)
    print('light flag   ', 'set' if head_flags & 0x200 else 'NOT SET')
    print('HEDR          version %.2f, records %d, next object ID %X' % (version, count, next_id))
    print('description  ', dict(header).get('SNAM', b'').rstrip(b'\0').decode('latin1'))
    print('own records  ', len(own), '| outside 800-FFF:', len(outside))
    print('overrides    ', sorted('%s %s' % k for k, v in new.items() if not v[3]))
    dangling = []
    for sig, origin, oid, flags, subs in recs:
        for k, v in subs:
            if len(v) == 4:
                value = struct.unpack('<I', v)[0]
                if value >> 24 == len(masters) and (path.name, value & 0xFFFFFF) not in {(r[1], r[2]) for r in own}:
                    dangling.append('%s %06X %s -> %08X' % (sig, oid, k, value))
    print('possible dangling references:', dangling or 'none')
    for title, keys in (('ONLY IN THE TEST CHAIN', set(old) - set(new)), ('ONLY IN THE MERGED PLUGIN', set(new) - set(old))):
        print('\n== %s (%d)' % (title, len(keys)))
        for key in sorted(keys):
            print('  %s %s' % key)
    same = 0
    print('\n== DIFFERENT')
    for key in sorted(set(old) & set(new)):
        a, b = old[key], new[key]
        if a[0] == b[0] and a[1] == b[1]:
            same += 1
            continue
        print('\n  %s %s' % key)
        if a[0] != b[0]:
            print('    record flags %08X -> %08X' % (a[0], b[0]))
        for op, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a[1], b[1], autojunk=False).get_opcodes():
            if op != 'equal':
                for x in a[1][i1:i2]:
                    print('    -' + str(x))
                for y in b[1][j1:j2]:
                    print('    +' + str(y))
    print('\n%d records identical' % same)


if __name__ == '__main__':
    main()
