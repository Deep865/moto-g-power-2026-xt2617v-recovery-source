#!/usr/bin/env python3
"""Inspect a vendor_boot v4 image and extract its ramdisk fragments.

Usage: extract_frags.py <vendor_boot.img> <outdir>
Writes:
  <outdir>/frag_<i>_type<t>_<name>.lz4   for every fragment
  <outdir>/recovery_ramdisk.lz4          copy of the largest type-2 (recovery) fragment, if any
Prints a summary so the caller can decide whether a repack is needed.
"""
import struct, sys, os, shutil

def align(x, p):
    return (x + p - 1) // p * p

def main():
    img, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    d = open(img, 'rb').read()
    if d[:8] != b'VNDRBOOT':
        raise SystemExit('not a VNDRBOOT image')
    hv, page = struct.unpack_from('<II', d, 8)
    rs = struct.unpack_from('<I', d, 24)[0]
    ds = struct.unpack_from('<I', d, 2100)[0]
    ts, tn, tes = struct.unpack_from('<III', d, 2112)

    dtb_off = align(page + rs, page)
    tab_off = align(dtb_off + ds, page)
    print(f'header_version={hv} page={page} vendor_ramdisk_size={rs} dtb_size={ds}')
    print(f'fragment_table: size={ts} entries={tn} entry_size={tes}')

    rec = None
    for i in range(tn):
        b = tab_off + i * tes
        rsize, roff, rtype = struct.unpack_from('<III', d, b)
        name = d[b + 12:b + 44].split(b'\x00')[0].decode('ascii', 'replace')
        start = page + roff
        blob = d[start:start + rsize]
        safe = name.replace('/', '_') or 'noname'
        path = os.path.join(outdir, f'frag_{i}_type{rtype}_{safe}.lz4')
        open(path, 'wb').write(blob)
        kind = {1: 'platform', 2: 'recovery'}.get(rtype, '?')
        print(f'  [{i}] type={rtype} ({kind}) name={name!r} offset={roff} size={rsize} -> {path}')
        if rtype == 2 and (rec is None or rsize > rec[0]):
            rec = (rsize, blob)

    if rec:
        out = os.path.join(outdir, 'recovery_ramdisk.lz4')
        open(out, 'wb').write(rec[1])
        print(f'RECOVERY_FRAGMENT {out} ({rec[0]} bytes)')
    else:
        print('NO_RECOVERY_FRAGMENT')

if __name__ == '__main__':
    main()
