#!/bin/zsh
# Checks the model against its bought parts and itself by boolean
# intersection: CLEAR means the two bodies share no volume, SOLID means
# they do (used for "sits on", "hits when pushed"). Then every exported
# piece: bed fit, bed contact, unsupported area, manifold.
cd "$(dirname "$0")"
S=$PWD/hydro-doser-v3.scad
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

echo "== harness self-test =="
chk "the unit has geometry" SOLID 'printed();'
chk "reads real distance as clearance" CLEAR 'intersection(){ printed(); translate([0,0,500]) lid(); }'

echo "== the body, floor and walls in one =="
chk "the floor is closed" CLEAR 'difference(){ translate([0, 0, -base_t + 0.1]) linear_extrude(base_t - 0.2) cav2d(-0.5); body(); for (f = feet) at(f, -base_t - 1) cylinder(d = foot[0] + 1, h = base_t + 2); }'
chk "the feet sit at the corners\x27 radius centres" SOLID 'union(){ for (f = feet) intersection(){ at(f, -20) cylinder(d = 0.2, h = 30); at([f[0] < Bx/2 ? R : Bx - R, f[1] < By/2 ? R : By - R], -20) cylinder(d = 0.3, h = 30); } }'
chk "the feet snap in: each sits in its pocket, its lip in the counterbore, clear of the floor" CLEAR 'intersection(){ feet_shown(); body(); }'
chk "self-test: a foot pushed 0.5 mm up hits the floor" SOLID 'intersection(){ translate([0, 0, 0.5]) feet_shown(); body(); }'
chk "the lip is wider than the hole: a foot cannot fall out without squashing" SOLID 'intersection(){ translate([0, 0, -1.6]) feet_shown(); body(); }'
chk "the feet stand proud of the floor's underside" SOLID 'intersection(){ feet_shown(); translate([-1, -1, -base_t - 10]) cube([Bx + 2, By + 2, 9.99]); }'
chk "the feet stay under the floor: nothing shows above it" CLEAR 'intersection(){ feet_shown(); translate([-1, -1, 0.01]) cube([Bx + 2, By + 2, 10]); }'
chk "the body prints floor down: its underside is one plane" SOLID 'intersection(){ body(); translate([-1, -1, -base_t - 1]) cube([Bx + 2, By + 2, 1.05]); }'
chk "no screws anywhere but the faceplate" SOLID 'screws();'

echo "== the lid =="
chk "the lid sits on the walls\x27 shoulder and the cups" SOLID 'intersection(){ translate([0, 0, -0.3]) lid(); body(); }'
chk "the lid clears the body as placed: the rim in its pocket, the ridge in the groove" CLEAR 'intersection(){ lid(); union(){ body(); plate(); } }'
chk "the lid snaps: lifted 1 mm, the ridge meets the pocket\x27s wall" SOLID 'intersection(){ translate([0, 0, 1]) lid(); body(); }'
chk "the lid prints flat: nothing of it hangs below its underside" CLEAR 'intersection(){ lid(); translate([-1, -1, H - 10]) cube([Bx + 2, By + 2, 9.99]); }'
chk "the lid is located: shifted 1 mm any way it hits the walls" SOLID 'union(){ for (d = [[1,0],[-1,0],[0,1],[0,-1]]) intersection(){ translate([d[0], d[1], 0]) lid(); body(); } }'
chk "the lid is flush with the walls: nothing of it outside the body\x27s outline" CLEAR 'intersection(){ lid(); difference(){ translate([-10, -10, H - 1]) cube([Bx + 20, By + 20, 20]); translate([0, 0, H - 2]) linear_extrude(22) rr(Bx, By, R); } }'
chk "and its edge is the body\x27s: 0.3 in from the outline there is lid at the seam" SOLID 'intersection(){ lid(); difference(){ translate([0, 0, H]) linear_extrude(1) rr(Bx, By, R); translate([0, 0, H - 1]) linear_extrude(3) offset(-0.3) rr(Bx, By, R); } }'

echo "== the cups and the bottles =="
chk "a bottle drops into its cup from above through the lid and stands on the floor" CLEAR 'intersection(){ union(){ body(); lid(); } union(){ for (i = [0, 1], dz = [0:20:140]) translate([0, 0, dz]) bottle_at(i); } }'
chk "self-test: a bottle 0.3 lower lands on the floor" SOLID 'intersection(){ body(); translate([0, 0, -0.3]) bottle_at(0); }'
chk "self-test: a bottle 3 mm over hits the cup" SOLID 'intersection(){ body(); translate([3, 0, 0]) bottle_at(0); }'
chk "a bottle shows 30 mm above the deck" SOLID 'intersection(){ bottle_at(0); translate([0, 0, H_lid + deck[2] + 28]) cube([Bx, By, 12]); }'
chk "each tube rises through its hole in the lid, 16 out from the bottle, into the cap" CLEAR 'intersection(){ union(){ body(); lid(); bottles(); } union(){ for (i = [0, 1]) at(cup_c[i] + [hole_dx[i], 0], H - 10) cylinder(d = tube_od + 0.5, h = 60); } }'
chk "self-test: the same tube 3 mm over hits the lid" SOLID 'intersection(){ lid(); at(cup_c[0] + [hole_dx[0] + 3, 0], H - 10) cylinder(d = tube_od + 0.5, h = 60); }'
chk "the tube hole passes through the lid and the deck, its mouth rounded" CLEAR 'intersection(){ lid(); union(){ at(cup_c[0] + [hole_dx[0], 0], H - 1) cylinder(d = hole_d - 0.2, h = lid_t + deck[2] + 4); at(cup_c[0] + [hole_dx[0], 0], H + lid_t + deck[2] - 0.05) cylinder(d = hole_d + 1.4, h = 2); } }'

echo "== the pumps =="
chk "the pumps sit in their slots, flanges on the bulkhead, clear of the printed parts" CLEAR 'intersection(){ printed(); pumps(); }'
chk "self-test: a pump 3 mm lower hits the slot" SOLID 'intersection(){ body(); translate([0, 0, -3]) pump(0); }'
chk "self-test: a pump pushed 1 mm into the bulkhead hits it" SOLID 'intersection(){ body(); translate([0, 1, 0]) pump(0); }'
chk "each pump lifts straight up and out, lid off" CLEAR 'intersection(){ body(); union(){ for (k = [0:2], dz = [0:10:70]) translate([0, 0, dz]) pump(k); } }'
chk "the flange screws sit on the 42 line, as the first design: from the motor side through the bulkhead into the flange" CLEAR 'intersection(){ union(){ body(); pumps(); } union(){ for (k = [0:2], s = [-1, 1]) translate([pump_x[k] + fhole(s)[0], bulk_y - 2, pump_z + fhole(s)[1]]) rotate([-90, 0, 0]) cylinder(d = 2.4, h = wall + 4); } }'
chk "self-test: a screw 3 mm over hits the bulkhead" SOLID 'intersection(){ body(); translate([pump_x[0] + fhole(1)[0] + 3, bulk_y - 2, pump_z + fhole(1)[1]]) rotate([-90, 0, 0]) cylinder(d = 2.4, h = wall + 4); }'
chk "a driver reaches every screw from the back, between the motors, under the ports" CLEAR 'intersection(){ union(){ body(); pumps(); port_hw(); } union(){ for (k = [0:2], s = [-1, 1]) translate([pump_x[k] + fhole(s)[0], bulk_y + wall + 0.5, pump_z + fhole(s)[1]]) rotate([-90, 0, 0]) cylinder(d = 6, h = By - wall - 1 - bulk_y - wall - 0.5); } }'
chk "the tubes rise off the rolled nozzles clear of the lid and the cups" CLEAR 'intersection(){ union(){ body(); lid(); pumps(); } union(){ for (k = [0:2], s = [-1, 1]) hull() { translate([pump_x[k] + tube_start(s)[0], head_y + nozzle_y, pump_z + tube_start(s)[1]]) sphere(d = 6); translate([pump_x[k] + nozzle(s)[0] + 4, head_y + nozzle_y, H - 8]) sphere(d = 6); } } }'
chk "the nutrient tubes run forward to under their holes" CLEAR 'intersection(){ union(){ body(); lid(); pumps(); electronics(); port_hw(); } union(){ for (k = [0, 2]) let (c = cup_c[k/2]) hull() { translate([pump_x[k] + nozzle(-1)[0] + 4, head_y + nozzle_y, H - 8]) sphere(d = 6); translate([c[0] + hole_dx[k/2], c[1], H - 8]) sphere(d = 6); } } }'
chk "the water tube\x27s hole is high in the back wall above the middle motor, and a tube from it runs forward over the motor and the bulkhead to the nozzles" CLEAR 'intersection(){ union(){ body(); lid(); pumps(); port_hw(); } union(){ translate([ports[3][0], By - wall - 1, ports[3][1]]) rotate([-90, 0, 0]) cylinder(d = 5.5, h = wall + 10); hull() { translate([ports[3][0], By - wall - 1, ports[3][1]]) sphere(d = 5); translate([122, 133, ports[3][1]]) sphere(d = 5); } hull() { translate([122, 133, ports[3][1]]) sphere(d = 5); translate([122, 120, 62]) sphere(d = 5); } for (s = [-1, 1]) hull() { translate([122, 120, 62]) sphere(d = 5); translate([pump_x[1] + tube_start(s)[0], head_y + nozzle_y, pump_z + tube_start(s)[1]]) sphere(d = 5); } } }'
chk "self-test: the same hole probe 6 mm higher hits the wall" SOLID 'intersection(){ body(); translate([ports[3][0], By - wall - 1, ports[3][1] + 6]) rotate([-90, 0, 0]) cylinder(d = 5.5, h = wall + 10); }'
chk "self-test: the water hole and the grommet are both on the middle motor\x27s line, midway between the jack and the GX12" SOLID 'intersection(){ translate([ports[3][0] - 0.1, By - 5, -1]) cube([0.2, 10, 80]); translate([ports[1][0] - 0.1, By - 5, -1]) cube([0.2, 10, 80]); translate([(ports[0][0] + ports[2][0])/2 - 0.1, By - 5, -1]) cube([0.2, 10, 80]); }'
chk "the jack, the grommet and the GX12 sit on one line" SOLID 'intersection(){ intersection_for (i = [0:2]) translate([ports[i][0], By - wall - 1, ports[i][1]]) rotate([-90, 0, 0]) linear_extrude(wall + 2) translate([-100, -0.1]) square([200, 0.2]); translate([0, By - wall - 1, -10]) cube([Bx, wall + 2, 100]); }'
chk "the outlet tubes run back over the bulkhead, down between the motors beside the jack and the GX12, and along the floor under the middle motor to the grommet" CLEAR 'intersection(){ union(){ body(); lid(); pumps(); electronics(); port_hw(); } union(){ for (k = [0, 2]) let (xd = k == 0 ? 62 : 140) { hull() { translate([pump_x[k] + nozzle(1)[0] + 4, head_y + nozzle_y, H - 8]) sphere(d = 6); translate([pump_x[k] + nozzle(1)[0] + 4, bulk_y + wall + 10, H - 8]) sphere(d = 6); } hull() { translate([pump_x[k] + nozzle(1)[0] + 4, bulk_y + wall + 10, H - 8]) sphere(d = 6); translate([xd, bulk_y + wall + 12, H - 8]) sphere(d = 6); } hull() { translate([xd, bulk_y + wall + 12, H - 8]) sphere(d = 6); translate([xd, bulk_y + wall + 12, 5]) sphere(d = 6); } hull() { translate([xd, bulk_y + wall + 12, 5]) sphere(d = 6); translate([ports[1][0] + (k == 0 ? -3 : 3), By - wall - 7, ports[1][1] - 2]) sphere(d = 6); } } } }'

echo "== the boards and the ports =="
chk "the boards clear the printed parts, the pumps and the ports" CLEAR 'intersection(){ union(){ printed(); pumps(); port_hw(); } electronics(); }'
chk "the DevKit stands on its standoffs, clear of the plate, the encoder and the screen" CLEAR 'intersection(){ board(0); union(){ plate(); enc_at(); oled_at(); } }'
chk "each standoff sits under one of the DevKit\x27s holes, and an M2.5 through the hole bites its pilot" SOLID 'union(){ for (h = esp_holes) intersection(){ plate(); translate([h[0], pt + 1.5, h[1]]) rotate([-90, 0, 0]) cylinder(d = 2.5, h = esp_so[1] - 2); } }'
chk "the pilots are open: an M2.5 core goes in" CLEAR 'intersection(){ plate(); union(){ for (h = esp_holes) translate([h[0], pt + 1.2, h[1]]) rotate([-90, 0, 0]) cylinder(d = 1.8, h = esp_so[1]); } }'
chk "the DevKit rests on its standoffs: 0.3 nearer the plate it hits them" SOLID 'intersection(){ plate(); translate([0, -0.3, 0]) board(0); }'
chk "the band is notched under it: it clears the body" CLEAR 'intersection(){ body(); board(0); }'
chk "the pH adapter slides onto the encoder\x27s ribs, clear of the plate\x27s other parts, the encoder and its plugs, the screen and the body" CLEAR 'intersection(){ ph_adapter(); union(){ difference(){ plate(); for (x = [rib_x[0], rib_x[1] - 2]) translate([x - 0.001, pt - 1, rib_z[0] - 1]) cube([2.002, 20, 40]); } enc_at(); oled_at(); body(); board(3); } }'
chk "and clear of the ribs themselves: a sliding fit" CLEAR 'intersection(){ ph_adapter(); plate(); }'
chk "its legs hug the ribs: 0.3 inward either side it hits them" SOLID 'union(){ intersection(){ translate([0.3, 0, 0]) ph_adapter(); plate(); } intersection(){ translate([-0.3, 0, 0]) ph_adapter(); plate(); } }'
chk "its lips rest on the ribs\x27 tops: 0.3 lower it hits" SOLID 'intersection(){ translate([0, 0, -0.3]) ph_adapter(); plate(); }'
chk "it slides off backward: nothing holds it but the ribs" CLEAR 'intersection(){ plate(); union(){ for (dy = [0:2:20]) translate([0, dy, 0]) ph_adapter(); } }'
chk "the pH board stands on its standoffs, clear of the adapter, the TDS board, the driver and the cups" CLEAR 'intersection(){ board(4); union(){ ph_adapter(); board(3); board(1); body(); plate(); enc_at(); oled_at(); } }'
chk "it rests on them: 0.3 nearer the plate it hits" SOLID 'intersection(){ ph_adapter(); translate([0, -0.3, 0]) board(4); }'
chk "an M3 through each of its holes bites a pilot" SOLID 'union(){ for (h = phb_holes) intersection(){ ph_adapter(); translate([h[0], pha_y + 1.5, h[1]]) rotate([-90, 0, 0]) cylinder(d = 3, h = pha[1] + pha[2] - 2); } }'
chk "the TDS board stands on its standoffs behind the screen, clear of the plate, the encoder and its pins, and the screen and its Dupont plugs" CLEAR 'intersection(){ board(3); union(){ plate(); enc_at(); oled_at(); } }'
chk "it rests on them: 0.3 nearer the plate it hits" SOLID 'intersection(){ plate(); translate([0, -0.3, 0]) board(3); }'
chk "an M3 through each of its holes bites a pilot" SOLID 'union(){ for (h = tds_holes) intersection(){ plate(); translate([h[0], pt + 1.5, h[1]]) rotate([-90, 0, 0]) cylinder(d = 3, h = tds_so[1] - 2); } }'
chk "its pilots are open" CLEAR 'intersection(){ plate(); union(){ for (h = tds_holes) translate([h[0], pt + 1.2, h[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = tds_so[1]); } }'
chk "its standoffs clear the body: the band is pocketed round them" CLEAR 'intersection(){ body(); plate(); }'
chk "it clears the body and the cups either side of it" CLEAR 'intersection(){ board(3); union(){ body(); board(1); } }'
chk "its pins clear the cups" CLEAR 'intersection(){ board(0); body(); }'
chk "the driver and the buck stand in their slots on the side walls, clear of the body, the cups and the pumps" CLEAR 'intersection(){ union(){ board(1); board(2); } union(){ body(); pumps(); } }'
chk "they slide down into their slots from above, lid off" CLEAR 'intersection(){ body(); union(){ for (dz = [0:5:80]) translate([0, 0, dz]) { board(1); board(2); } } }'
chk "the slots hold them: shifted 1 mm off the wall, or 2 mm along it, they hit" SOLID 'for (d = [[1,0],[-1,0],[0,2],[0,-2]]) intersection(){ body(); translate([d[0], d[1], 0]) union(){ board(1); board(2); } }'
chk "the slot floors hold them: 0.5 mm lower they hit" SOLID 'intersection(){ body(); translate([0, 0, -0.5]) union(){ board(1); board(2); } }'
chk "the vents open through both side walls beside the motors" CLEAR 'intersection(){ body(); union(){ for (sx = [0, 1], i = [0:vents[1][2] - 1]) translate([sx ? Bx - wall - 2 : -2, vents[0][0] + vents[0][1]/2, vents[1][0] + i*vents[1][1] + vents[2]/2]) rotate([0, 90, 0]) cylinder(d = vents[2] - 0.6, h = wall + 4); } }'
chk "self-test: between two vents the wall is solid" SOLID 'intersection(){ body(); translate([-2, vents[0][0] + vents[0][1]/2, vents[1][0] + vents[1][1]/2 + vents[2]/2]) rotate([0, 90, 0]) cylinder(d = 1.5, h = wall + 4); }'
chk "the jack and the GX12 sit low between the motors, the grommet above the middle one, all clear" CLEAR 'intersection(){ port_hw(); union(){ pumps(); body(); } }'
chk "the ports pass their holes clear of everything" CLEAR 'intersection(){ union(){ printed(); electronics(); pumps(); } port_hw(); }'
chk "self-test: a port 4 mm over hits the wall" SOLID 'intersection(){ body(); translate([4, 0, 0]) port_hw(); }'

echo "== the faceplate =="
chk "the plate sits in its opening, clear of the body" CLEAR 'intersection(){ plate(); body(); }'
chk "it bears on the band behind the wall: pushed in 0.3 it hits" SOLID 'intersection(){ translate([0, 0.3, 0]) plate(); body(); }'
chk "the opening holds it: shifted 1 mm any way it hits the wall" SOLID 'union(){ for (d = [[1,0],[-1,0],[0,1],[0,-1]]) intersection(){ translate([d[0], 0, d[1]]) plate(); body(); } }'
chk "it is flush: nothing of it stands proud of the face" CLEAR 'intersection(){ plate(); translate([-1, -10, -1]) cube([Bx + 2, 10, H + 2]); }'
chk "and its face is at the wall\x27s: 0.2 back and it is inside the wall\x27s plane" SOLID 'intersection(){ plate(); translate([-1, -10, -1]) cube([Bx + 2, 10.2, H + 2]); }'
chk "the seam is rounded both sides: a groove opens at the face" CLEAR 'intersection(){ union(){ plate(); body(); } on_front() translate([0, 0, -1]) linear_extrude(1.04) difference(){ plate2d(0.3 + pch - 0.3); plate2d(-pch + 0.3); } }'
chk "self-test: the same groove 0.6 deeper finds plastic" SOLID 'intersection(){ union(){ plate(); body(); } on_front() translate([0, 0, -1]) linear_extrude(1 + pch + 0.1) difference(){ plate2d(0.3 + pch - 0.3); plate2d(-pch + 0.3); } }'
chk "the plate\x27s screws sit at the centres of its corner radii" SOLID 'union(){ for (s = pscrews) intersection(){ translate([s[0], -1, s[1]]) rotate([-90, 0, 0]) cylinder(d = 0.2, h = 5); translate([s[0] < px0 + pw/2 ? px0 + pr : px0 + pw - pr, -1, s[1] < pz0 + ph/2 ? pz0 + pr : pz0 + ph - pr]) rotate([-90, 0, 0]) cylinder(d = 0.3, h = 5); } }'
chk "its screws pass the plate into the inserts in the band, clear, heads flush" CLEAR 'intersection(){ for (s = pscrews) translate([s[0], 0, s[1]]) rotate([90, 0, 0]) translate([0, 0, -8]) m3csk(8); union(){ plate(); body(); translate([-1, -10, -1]) cube([Bx + 2, 10, H + 2]); } }'
chk "self-test: a plate screw 1.5 mm over hits" SOLID 'intersection(){ for (s = pscrews) translate([s[0] + 1.5, 0, s[1]]) rotate([90, 0, 0]) translate([0, 0, -8]) m3csk(8); union(){ plate(); body(); } }'
chk "the plate\x27s works pass through the band into the box" CLEAR 'intersection(){ body(); union(){ plate(); enc_at(); oled_at(); } }'

echo "== the controls, on the plate =="
chk "the encoder sits against the plate\x27s back between its ribs, clear" CLEAR 'intersection(){ union(){ plate(); knob_at(); } enc_at(); }'
chk "the ribs hold it: shifted 3 mm either way it hits" SOLID 'for (dx = [-3, 3]) intersection(){ plate(); translate([dx, 0, 0]) enc_at(); }'
chk "the nut sits on the recess floor" SOLID 'intersection(){ plate(); translate([0, 0.3, 0]) enc_at(); }'
chk "the knob sits in its recess clear of the plate, the nut and the shaft" CLEAR 'intersection(){ knob_at(); union(){ plate(); enc_at(); } }'
chk "self-test: the knob 1.5 mm over hits the recess wall" SOLID 'intersection(){ plate(); translate([1.5, 0, 0]) knob_at(); }'
chk "pushed 0.5 mm in it stops on the shaft\x27s end" SOLID 'intersection(){ translate([0, 0.5, 0]) knob_at(); enc_at(); }'
chk "and pushed 0.4 mm it still clears the recess floor" CLEAR 'intersection(){ translate([0, 0.4, 0]) knob_at(); plate(); }'
chk "the knob\x27s bore has its D flat" SOLID 'intersection(){ knob_at(); translate([knob_x - 2, knob_y - 9, ctl_z + enc[7] - enc[6]/2 + 0.3]) cube([4, 3, 1]); }'
chk "the knob is countersunk: its base is behind the face" SOLID 'intersection(){ knob_at(); translate([0, 0.01, 0]) cube([Bx, wall, H]); }'
chk "the screen sits in its pocket, clear of the plate" CLEAR 'intersection(){ plate(); oled_at(); }'
chk "it drops straight in from behind" CLEAR 'intersection(){ plate(); union(){ for (dy = [0:2:30]) translate([0, dy, 0]) oled_at(); } }'
chk "it cannot come out the front" SOLID 'intersection(){ plate(); translate([0, -2, 0]) oled_at(); }'
chk "the pocket holds it: shifted 0.5 mm any way across the plate it hits" SOLID 'for (d = [[0.5,0],[-0.5,0],[0,0.5],[0,-0.5]]) intersection(){ plate(); translate([d[0], 0, d[1]]) oled_at(); }'
chk "the window shows the whole picture" CLEAR 'intersection(){ plate(); translate([oled_x, -1, ctl_z]) rotate([-90, 0, 0]) linear_extrude(pt + 1) rrc(oled[6], oled[7], 1.5); }'
chk "the glass sits behind a skin of the face" SOLID 'intersection(){ plate(); translate([oled_x - 12, 0.2, ctl_z + oled[7]/2 + 1.5]) cube([24, 1, 1]); }'
chk "the knob and the screen sit on one line, the plate\x27s middle" SOLID 'intersection(){ union(){ knob_at(); oled_at(); } translate([0, -20, ctl_z - 0.5]) cube([Bx, 40, 1]); }'

echo "== the second colours =="
chk "the deck is the lid\x27s black part: no overlap with the rest" CLEAR 'intersection(){ lid_main(); lid_deck(); }'
chk "the deck exists as black" SOLID 'lid_deck();'
chk "the lid\x27s olive part has no deck above its top face" CLEAR 'intersection(){ lid_main(); translate([deck[0][0] + 5, deck[0][1] + 5, H + lid_t + 0.05]) cube([deck[1][0] - 10, deck[1][1] - 10, deck[2]]); }'
chk "the knob\x27s cap and ring don\x27t overlap" CLEAR 'intersection(){ knob_ring(); knob_cap(); }'
chk "the cap is the face and the rounded edge: nothing of it below the knurl\x27s top" CLEAR 'intersection(){ knob_cap(); translate([-30, -30, -1]) cube([60, 60, knob[1] - knob[4] + 1 - 0.05]); }'
chk "and the ring stops at the knurl\x27s top" CLEAR 'intersection(){ knob_ring(); translate([-30, -30, knob[1] - knob[4] + 0.05]) cube([60, 60, 10]); }'

echo "== the fuzz modifier =="
chk "the fuzz modifier wraps the body\x27s outer walls between the seams" SOLID 'intersection(){ fuzz_mod(); body(); }'
chk "it reaches 1 mm outside the body, so the outer wall is inside it everywhere" SOLID 'intersection(){ fuzz_mod(); difference(){ translate([-0.5, -0.5, 0]) linear_extrude(H) offset(0.5) rr(Bx, By, R); linear_extrude(H) rr(Bx, By, R); } }'
chk "it stays clear of the faceplate\x27s opening and its band" CLEAR 'intersection(){ fuzz_mod(); on_front() translate([0, 0, -2]) linear_extrude(12) plate2d(0.3 + fuzz[2] - 0.05); }'
chk "it leaves a smooth margin at the bottom and stops at the lid seam" CLEAR 'intersection(){ fuzz_mod(); union(){ translate([-1, -1, H + 0.01]) cube([Bx + 2, By + 2, 10]); translate([-1, -1, -base_t - 1]) cube([Bx + 2, By + 2, fuzz[0] + 1 - 0.01]); } }'
chk "the band clears the faceplate by the same amount above and below" SOLID 'intersection(){ fuzz_mod(); union(){ translate([-1, -1, pz0 + ph + 0.3 + 3.3 - 0.5]) cube([Bx + 2, By + 2, 1]); translate([-1, -1, pz0 - 0.3 - 3.3 - 0.5]) cube([Bx + 2, By + 2, 1]); } }'
chk "it does not reach the cavity: the walls\x27 inner half is outside it" CLEAR 'intersection(){ fuzz_mod(); translate([0, 0, fuzz[0] - 1]) linear_extrude(H) cav2d(fuzz[1] - 0.05); }'

echo "== the spout =="
chk "the reservoir\x27s rim fits the spout\x27s slot" CLEAR 'intersection(){ spout(); translate([-1, spout[3] + 0.2, 4.2]) cube([spout[0] + 2, rim[0], rim[1]]); }'
chk "self-test: a rim 1 mm thicker hits" SOLID 'intersection(){ spout(); translate([-1, spout[3] + 0.2, 4.2]) cube([spout[0] + 2, rim[0] + 1, rim[1]]); }'
chk "the tubes and the float lead pass through" CLEAR 'intersection(){ spout(); union(){ for (i = [0:2]) translate([7 + 10*i, spout[3] + spout[4] + (spout[1] - spout[3] - spout[4])/2, -1]) cylinder(d = tube_od, h = spout[2] + 2); translate([spout[0] - 5, spout[3] + spout[4] + (spout[1] - spout[3] - spout[4])/2, -1]) cylinder(d = 3.5, h = spout[2] + 2); } }'

echo "== every exported piece fits the bed and prints unsupported =="
for p in body lid lid_deck plate knob knob_cap foot spout ph_adapter; do
  [[ -s stl/$p.stl ]] || { echo "  FAIL  $p  no stl/$p.stl (run ./export.sh)"; ((fail++)); continue; }
  allow=0; [[ $p == lid ]] && allow=2100   # the pocket's ceiling and the groove's top: 2 mm and 0.7 mm bridges round the rim
  [[ $p == lid_deck ]] && allow=30000; [[ $p == knob_cap ]] && allow=1100   # the second colours sit on their piece: their undersides are its top
  [[ $p == body ]] && allow=2000           # the vents' ceilings: fourteen 2 mm bridges; the wall-board ribs' undersides; the flange and port holes
  [[ $p == plate ]] && allow=600           # the knob's ribs' tops
  if python3 $T/piece.py $p stl/$p.stl $allow; then ((pass++)); else ((fail++)); fi
done
echo "== $pass passed, $fail failed =="
rm -rf $T
(( fail == 0 ))
