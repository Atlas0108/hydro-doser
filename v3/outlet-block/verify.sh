#!/bin/zsh
# Checks the model against its bought parts and itself by boolean
# intersection: CLEAR means the two bodies share no volume, SOLID means
# they do (used for "sits on", "hits when pushed"). Then every exported
# piece: bed fit, bed contact, unsupported area, manifold.
cd "$(dirname "$0")"
S=$PWD/outlet-block.scad
T=$(mktemp -d); pass=0; fail=0
cat > $T/vol.py <<'PY'
import sys, re
t = open(sys.argv[1]).read()
v = [tuple(map(float, m.groups())) for m in re.finditer(r'vertex\s+(\S+)\s+(\S+)\s+(\S+)', t)]
vol = 0
for i in range(0, len(v), 3):
    a, b, c = v[i], v[i+1], v[i+2]
    vol += (a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
print(f"{abs(vol):.6f}")
PY
cat > $T/piece.py <<'PY'
import sys, re, struct, collections
name, path = sys.argv[1], sys.argv[2]; allow = float(sys.argv[3]) if len(sys.argv) > 3 else 0   # allow: down-facing area that is a short bridge by design
d = open(path, 'rb').read()
n = struct.unpack('<I', d[80:84])[0]; tris = []
for i in range(n):
    o = 84 + i*50; f = struct.unpack('<12f', d[o:o+48]); tris.append((f[0:3], f[3:6], f[6:9], f[9:12]))
xs = [p[k] for t in tris for p in t[1:] for k in [0]]; ys = [p[1] for t in tris for p in t[1:]]; zs = [p[2] for t in tris for p in t[1:]]
w, h, z = max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs); z0 = min(zs)
def area(a, b, c):
    u = [b[i]-a[i] for i in range(3)]; v = [c[i]-a[i] for i in range(3)]
    cx, cy, cz = u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]
    return (cx*cx+cy*cy+cz*cz) ** 0.5 / 2, cz
bed = 0; unsup = 0; vol = 0
for nrm, a, b, c in tris:
    ar, cz = area(a, b, c)
    down = cz < -1e-9
    if down and max(a[2], b[2], c[2]) < z0 + 0.05: bed += ar
    elif down and cz / (2*ar + 1e-12) < -0.72 and min(a[2], b[2], c[2]) > z0 + 0.3: unsup += ar   # faces looking down, steeper than 45, off the bed
    vol += (a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
edges = collections.Counter()
for _, a, b, c in tris:
    for p, q in ((a, b), (b, c), (c, a)): edges[tuple(sorted((p, q)))] += 1
bad = sum(1 for k, v in edges.items() if v != 2)
ok = w <= 256 and h <= 256 and z <= 256 and bed >= 0.06*w*h and unsup <= 1500 + allow and bad == 0
print(f"  {'PASS' if ok else 'FAIL'}  {name}  {w:.1f} {h:.1f} {z:.1f}  bed {bed:.0f} mm2  unsupported {unsup:.0f} mm2  {'' if bad == 0 else f'NON-MANIFOLD {bad} edges  '}~{abs(vol)*1.27/1000:.0f} g solid")
sys.exit(0 if ok else 1)
PY
chk() {  # $1 label  $2 CLEAR|SOLID  $3 body
  printf 'include <%s>\n%s\n' "$S" "$3" > $T/c.scad
  rm -f $T/c.stl
  err=$(openscad -o $T/c.stl --export-format asciistl -D 'part="none"' -D '$fn=32' $T/c.scad 2>&1)
  if echo "$err" | grep -qi "can't open include\|WARNING: Ignoring unknown\|assert"; then
    echo "  ERROR $1 -- $err" | head -2; ((fail++)); return; fi
  vol=0.000000; [[ -s $T/c.stl ]] && vol=$(python3 $T/vol.py $T/c.stl)
  if (( vol < 0.001 )); then got=CLEAR; else got=SOLID; fi
  if [[ "$got" == "$2" ]]; then echo "  PASS  $1"; ((pass++))
  else echo "  FAIL  $1 -- expected $2 got $got ($vol mm3)"; ((fail++)); fi
}

echo "== outlet block =="
chk "the block has geometry" SOLID 'block();'
chk "it sits on the back wall and through the hole, clear of the body" CLEAR 'intersection(){ block(); body(); }'
chk "it bears on the wall: 0.3 nearer it hits" SOLID 'intersection(){ translate([0, -0.3, 0]) block(); body(); }'
chk "its lip snaps behind the wall: pulled 0.5 out it hits" SOLID 'intersection(){ translate([0, 0.5, 0]) block(); body(); }'
chk "it clears the jack and the GX12, their nuts and the plugs in them" CLEAR 'intersection(){ block(); union(){ for (p = [[70, 11.5], [132, 19]]) translate([p[0], By - 1, 11]) rotate([-90, 0, 0]) cylinder(d = p[1], h = 40); } }'
chk "and the water tube coming down to its hole above" CLEAR 'intersection(){ union(){ block(); barbs(); } translate([101, By - 1, 58]) rotate([-90, 0, 0]) cylinder(d = 8, h = 8); }'
chk "the barbs screw in clear of the block but for their threads" CLEAR 'intersection(){ block(); barbs(); }'
chk "a barb 0.5 off its hole hits: the threads hold them" SOLID 'intersection(){ block(); translate([0.5, 0, 0]) barbs(); }'
chk "the tubes pass through the spigot: three 5 mm tubes together" CLEAR 'intersection(){ block(); for (a = [90, 210, 330]) translate([hole[0] + 3*cos(a), By - 10, hole[1] + 3*sin(a)]) rotate([-90, 0, 0]) cylinder(d = 5, h = 14); }'
chk "the collars clear one another" CLEAR 'intersection(){ translate([barb_x[0], barb_y, blk[3][1]]) cylinder(d = 11.5, h = 3, $fn = 6); translate([barb_x[1], barb_y, blk[3][1]]) cylinder(d = 11.5, h = 3, $fn = 6); }'

echo "== the piece =="
mkdir -p ../stl
openscad -q -o ../stl/outlet-block.stl --export-format binstl -D 'part="print"' outlet-block.scad
if python3 $T/piece.py outlet-block ../stl/outlet-block.stl 300; then ((pass++)); else ((fail++)); fi
echo "== $pass passed, $fail failed =="
rm -rf $T
(( fail == 0 ))
