#!/usr/bin/env python3
"""Verify a vendor_boot v4 image against the stock revert image."""
import struct, hashlib, sys, os

MAGIC = b'VNDRBOOT'

def align(x, p):
    return (x + p - 1) // p * p

def parse(path):
    d = open(path, 'rb').read()
    if d[:8] != MAGIC:
        raise SystemExit(f'{path}: bad magic {d[:8]!r}')
    hv, page = struct.unpack_from('<II', d, 8)
    ka, ra, rs = struct.unpack_from('<III', d, 16)
    cmdline = d[28:28 + 2048].split(b'\x00')[0].decode('ascii', 'replace')
    tags = struct.unpack_from('<I', d, 2076)[0]
    hsize = struct.unpack_from('<I', d, 2096)[0]
    ds = struct.unpack_from('<I', d, 2100)[0]
    dta = struct.unpack_from('<Q', d, 2104)[0]
    ts, tn, tes = struct.unpack_from('<III', d, 2112)
    bcs = struct.unpack_from('<I', d, 2124)[0]

    rd_off = page
    dtb_off = align(page + rs, page)
    dtb = d[dtb_off:dtb_off + ds]
    tab_off = align(dtb_off + ds, page)

    frags = []
    for i in range(tn):
        b = tab_off + i * tes
        rsize, roff, rtype = struct.unpack_from('<III', d, b)
        name = d[b + 12:b + 44].split(b'\x00')[0].decode('ascii', 'replace')
        frags.append((rtype, name, roff, rsize))

    return dict(path=path, size=len(d), hv=hv, page=page, ka=ka, ra=ra, tags=tags,
                hsize=hsize, rs=rs, ds=ds, dta=dta, cmdline=cmdline,
                dtb_sha=hashlib.sha256(dtb).hexdigest(), table=(ts, tn, tes),
                bootconfig=bcs, frags=frags)

def ck(label, ok, a=None, b=None):
    extra = '' if a is None else f'  stock={a} built={b}'
    print(f"{label:34} {'OK' if ok else 'FAIL'}{extra}")

def main():
    built_p = sys.argv[1] if len(sys.argv) > 1 else r'C:\Users\<you>\MotoRoot\wsl-build\vendor_boot_14.img'
    stock_p = sys.argv[2] if len(sys.argv) > 2 else r'C:\Users\<you>\MotoRoot\revert\vendor_boot_a.img'
    b = parse(built_p)
    s = parse(stock_p)

    print(f"built: {b['path']}  ({b['size']} bytes)")
    print(f"stock: {s['path']}  ({s['size']} bytes)")
    print()
    ck('magic VNDRBOOT', True)
    ck('header version 4', b['hv'] == 4, s['hv'], b['hv'])
    ck('page size 4096', b['page'] == 4096, s['page'], b['page'])
    ck('kernel addr 0x40000000', b['ka'] == 0x40000000, hex(s['ka']), hex(b['ka']))
    ck('ramdisk addr 0x66f00000', b['ra'] == 0x66f00000, hex(s['ra']), hex(b['ra']))
    ck('dtb size 183530', b['ds'] == 183530, s['ds'], b['ds'])
    ck('dtb sha256 matches stock', b['dtb_sha'] == s['dtb_sha'], s['dtb_sha'][:16], b['dtb_sha'][:16])
    ck('total <= 67108864', b['size'] <= 67108864, s['size'], b['size'])
    print()
    print('cmdline     :', repr(b['cmdline']))
    print('fragments   :', len(b['frags']))
    for t, n, off, sz in b['frags']:
        print(f'  type={t} ({ {1:"platform",2:"recovery"}.get(t,"?") }) name={n!r} off={off} size={sz}')
    print()
    platform_only = len(b['frags']) == 1 and b['frags'][0][0] == 1
    print('single platform fragment:', 'YES' if platform_only else 'NO (repack per handoff)')
    ok = (b['hv'] == 4 and b['page'] == 4096 and b['ka'] == 0x40000000 and b['ra'] == 0x66f00000
          and b['ds'] == 183530 and b['dtb_sha'] == s['dtb_sha'] and b['size'] <= 67108864)
    print('VERDICT:', 'PASS' if ok else 'FAIL')

if __name__ == '__main__':
    main()
