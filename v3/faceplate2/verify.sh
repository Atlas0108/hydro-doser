#!/bin/zsh
# Checks the model against its bought parts and itself by boolean
# intersection: CLEAR means the two bodies share no volume, SOLID means
# they do (used for "sits on", "hits when pushed"). Then every exported
# piece: bed fit, bed contact, unsupported area, manifold.
cd "$(dirname "$0")"
S=$PWD/faceplate2.scad
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

echo "== faceplate 2 =="
chk "the plate has geometry" SOLID 'plate2();'
chk "it fits the body as printed: clear of the walls, the band and the inserts" CLEAR 'intersection(){ plate2(); body(); }'
chk "the bezel's three alignment holes are open 2 into the face" CLEAR 'intersection(){ plate2(); for (i = [0:2]) let (a = bezel_pin[4] + 120*i) translate([knob_x + bezel_pin[1]*cos(a), -0.1, ctl_z + bezel_pin[1]*sin(a)]) rotate([-90, 0, 0]) cylinder(d = 1.8, h = 1.9); }'
chk "and blind: the plate's back is whole behind them" SOLID 'union(){ for (i = [0:2]) let (a = bezel_pin[4] + 120*i) intersection(){ plate2(); translate([knob_x + bezel_pin[1]*cos(a), 2.2, ctl_z + bezel_pin[1]*sin(a)]) rotate([-90, 0, 0]) cylinder(d = 1.8, h = 0.7); } }'
chk "the holes sit outside the knob, under a bezel's ring" CLEAR 'intersection(){ union(){ knob2(); knob2_cap(); } for (i = [0:2]) let (a = bezel_pin[4] + 120*i) translate([knob_x + bezel_pin[1]*cos(a), -12, ctl_z + bezel_pin[1]*sin(a)]) rotate([-90, 0, 0]) cylinder(d = 2, h = 13); }'
chk "the knob sits 0.5 in front of the flat face, clear of the plate" CLEAR 'intersection(){ plate2(); union(){ knob2(); knob2_cap(); } }'
chk "the nut on the face sits in the knob's base pocket, clear of the knob" CLEAR 'intersection(){ union(){ knob2(); knob2_cap(); } enc2(); }'
chk "the shaft reaches into the knob's bore" SOLID 'intersection(){ translate([knob_x, knob_y - 5, ctl_z]) rotate([90, 0, 0]) cylinder(d = 3, h = 1); enc2(); }'
chk "the encoder sits on the plate's back, clear" CLEAR 'intersection(){ plate2(); enc2(); }'
chk "the screen sits in its pocket, clear" CLEAR 'intersection(){ plate2(); oled2(); }'
chk "the groove along the screen board's top edge takes its solder points: 1.2 proud of the board, clear" CLEAR 'intersection(){ plate2(); translate([oled_x - 6, pt - 1.2, oled_pcb_z + oled[1]/2 - 4]) cube([12, 1.21, 3.5]); }'
chk "and leaves 1.5 of plate in front of it" SOLID 'intersection(){ plate2(); translate([oled_x - 6, 0.2, oled_pcb_z + oled[1]/2 - 4]) cube([12, 1.2, 3.5]); }'
chk "the pocket holds it: 0.5 mm any way across the plate it hits" SOLID 'for (d = [[0.5,0],[-0.5,0],[0,0.5],[0,-0.5]]) intersection(){ plate2(); translate([d[0], 0, d[1]]) oled2(); }'
chk "the ESP32 stands on its standoffs, clear" CLEAR 'intersection(){ plate2(); esp2(); }'
chk "it rests on them: 0.3 nearer the plate it hits" SOLID 'intersection(){ plate2(); translate([0, -0.3, 0]) esp2(); }'
chk "the pH board stands over the encoder on its standoffs, clear" CLEAR 'intersection(){ plate2(); ph2(); }'
chk "it rests on them: 0.3 nearer it hits" SOLID 'intersection(){ plate2(); translate([0, -0.3, 0]) ph2(); }'
chk "the TDS board stands against its fin, clear" CLEAR 'intersection(){ plate2(); tds2(); }'
chk "it rests on the fin: 0.3 toward it, it hits" SOLID 'intersection(){ plate2(); translate([-0.3, 0, 0]) tds2(); }'
chk "the parts clear one another" CLEAR 'union(){ intersection(){ esp2(); union(){ enc2(); oled2(); ph2(); tds2(); } } intersection(){ enc2(); union(){ oled2(); ph2(); tds2(); } } intersection(){ oled2(); union(){ ph2(); tds2(); } } intersection(){ ph2(); tds2(); } }'
chk "everything on the plate clears the body, its cups, the bottles and the wall boards" CLEAR 'intersection(){ union(){ plate2(); parts2(); } union(){ body(); bottles(); board(1); board(2); } }'
chk "an M2.5 bites each ESP32 pilot" SOLID 'union(){ for (h = esp_holes) intersection(){ plate2(); translate([h[0], pt + 0.5, h[1]]) rotate([-90, 0, 0]) cylinder(d = 2.5, h = esp_so[1]); } }'
chk "an M3 bites each pH board pilot" SOLID 'union(){ for (h = ph_holes) intersection(){ plate2(); translate([h[0], pt + 0.5, h[1]]) rotate([-90, 0, 0]) cylinder(d = 3, h = ph_y - pt); } }'
chk "an M3 bites each TDS board pilot" SOLID 'union(){ for (h = tds_holes) intersection(){ plate2(); translate([fin[0] - 0.5, h[0], h[1]]) rotate([0, 90, 0]) cylinder(d = 3, h = fin[1] + 1); } }'
chk "the screws sit at the corners' radius centres, countersunk" SOLID 'union(){ for (s = pscrews) intersection(){ plate2(); translate([s[0], -1, s[1]]) rotate([-90, 0, 0]) cylinder(d = 7, h = 1.5); } }'

echo "== the piece =="
mkdir -p ../stl
openscad -q -o ../stl/faceplate2.stl --export-format binstl -D 'part="print"' faceplate2.scad
if python3 $T/piece.py faceplate2 ../stl/faceplate2.stl 600; then ((pass++)); else ((fail++)); fi
echo "== $pass passed, $fail failed =="
rm -rf $T
(( fail == 0 ))
