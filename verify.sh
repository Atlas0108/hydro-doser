#!/bin/zsh
# Boolean-intersects the unit against its bought parts, measuring the VOLUME
# of what comes back. Zero volume = clearance; touching faces give a
# zero-volume sheet. Then checks the joints, tool access, and every exported
# piece (./export.sh first): bed fit, bed contact, unsupported area, and that
# the mesh is manifold (Bambu Studio refuses an STL with non-manifold edges).
S="$(cd "$(dirname "$0")" && pwd)/hydro-doser.scad"
[[ -f "$S" ]] || { echo "cannot find $S"; exit 2; }
T=$(mktemp -d)
pass=0; fail=0
cat > $T/vol.py <<'PY'
import sys
v=[];t=0.0
for l in open(sys.argv[1]):
    l=l.strip()
    if l.startswith('vertex'):
        v.append(tuple(map(float,l.split()[1:4])))
        if len(v)==3:
            (ax,ay,az),(bx,by,bz),(cx,cy,cz)=v
            t+=(ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx))/6.0
            v=[]
print("%.6f"%abs(t))
PY
# Per exported piece: bounding box, lowest z, bed-contact area (faces on the
# bed pointing down), unsupported area (down-facing faces off the bed that
# more than 50 degrees from vertical: they'd need support; 45-degree cones pass), volume,
# and non-manifold edges: an edge not on exactly two faces, zero-area faces
# included, which is how Bambu Studio counts (it refuses an STL that has any).
cat > $T/stl.py <<'PY'
import sys, math, collections
lo=[1e9]*3; hi=[-1e9]*3; v=[]; bed=0.0; unsup=0.0; vol=0.0; edges=collections.Counter()
for l in open(sys.argv[1]):
    l=l.split()
    if l and l[0]=='vertex':
        p=tuple(map(float,l[1:4])); v.append(p)
        for i in range(3): lo[i]=min(lo[i],p[i]); hi[i]=max(hi[i],p[i])
        if len(v)==3:
            (a,b,c)=v; v=[]
            ux,uy,uz=b[0]-a[0],b[1]-a[1],b[2]-a[2]; wx,wy,wz=c[0]-a[0],c[1]-a[1],c[2]-a[2]
            nx,ny,nz=uy*wz-uz*wy,uz*wx-ux*wz,ux*wy-uy*wx
            area=math.sqrt(nx*nx+ny*ny+nz*nz)/2
            vol+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6.0
            for e in ((a,b),(b,c),(c,a)): edges[tuple(sorted(tuple(round(x,5) for x in q) for q in e))]+=1
            if area<1e-9: continue
            nz/=2*area
            if nz<-0.999 and max(a[2],b[2],c[2])<0.01: bed+=area
            elif nz<-0.77 and min(a[2],b[2],c[2])>0.5: unsup+=area
bad=sum(1 for n in edges.values() if n!=2)
print(" ".join("%.1f"%(hi[i]-lo[i]) for i in range(3)), "%.2f"%lo[2], "%.0f"%bed, "%.0f"%unsup, "%.0f"%abs(vol), bad)
PY
chk() {  # $1 label  $2 CLEAR|SOLID  $3 body
  printf 'include <%s>\n%s\n' "$S" "$3" > $T/c.scad
  rm -f $T/c.stl
  err=$(openscad -o $T/c.stl -D 'part="none"' -D '$fn=32' $T/c.scad 2>&1)
  if echo "$err" | grep -qi "can't open include\|WARNING: Ignoring unknown\|assert"; then
    echo "  ERROR $1 -- $err" | head -2; ((fail++)); return; fi
  vol=0.000000; [[ -s $T/c.stl ]] && vol=$(python3 $T/vol.py $T/c.stl)
  if (( vol < 0.001 )); then got=CLEAR; else got=SOLID; fi
  if [[ "$got" == "$2" ]]; then echo "  PASS  $1"; ((pass++))
  else echo "  FAIL  $1 -- expected $2 got $got (${vol} mm3)"; ((fail++)); fi
}

echo "== harness self-test =="
chk "the unit has geometry" SOLID 'printed();'
chk "reads real distance as clearance" CLEAR 'intersection(){ printed(); translate([0,0,500]) bin(); }'

echo "== the tank =="
chk "the bin and its lid clear the printed parts" CLEAR 'intersection(){ union(){ printed(); covers(); } union(){ bin(); bin_lid(); } }'
chk "the tank lifts straight up and away" CLEAR 'intersection(){ printed(); union(){ for (dz=[0:20:300]) translate([0,0,dz]) bin(); } }'
chk "self-test: a tank 6 mm off its dock hits the curb" SOLID 'intersection(){ printed(); translate([6,0,0]) bin(); }'
chk "the curb stands 3 mm proud of the plate" SOLID 'intersection(){ plate(); translate([0, 0, base_h + 2.9]) cube([dock_w, D, 1]); }'
chk "the drip rim stands 1.5 mm proud, lower than the curb" SOLID 'intersection(){ plate(); translate([0, 0, base_h + 1.2]) cube([dock_w, 6, 0.2]); }'
chk "the lid hole is over the bin, clear of the rim" CLEAR 'difference(){ at(lid_hole, base_h + bin_h - 30) cylinder(d = lid_hole_d + 6, h = 30); at(tank_c, base_h) bin_shape(6, bin_h); }'
chk "a tube passes the lid hole down to the bin floor" CLEAR 'intersection(){ union(){ printed(); bin(false); bin_lid(); } at(lid_hole, base_h + 4) cylinder(d = 7, h = bin_h + 20); }'
chk "the tank line comes straight out of the top of its chase" CLEAR 'intersection(){ printed(); at(chase_c[1], exit_z - 30) cylinder(d = 7, h = 60); }'
chk "the chase tops sit at least 20 mm above the lid" CLEAR 'intersection(){ bin_lid(); translate([0, 0, exit_z - 20]) cube([W, D, 60]); }'
chk "the chases stand as tall as the web walls" SOLID 'intersection(){ union(){ for (c = chase_c) at(c, exit_z - 1) cylinder(d = chase_od - 1, h = 1); } union(){ for (x = web_x) translate([x, can_c[0][1], exit_z - 1]) cube([3, can_c[1][1] - can_c[0][1], 1]); at(chase_c[1], exit_z - 1) cylinder(d = chase_od, h = 1); } }'

echo "== the bottles =="
chk "1 L bottles clear the column" CLEAR 'intersection(){ printed(); for (c = can_c) at(c, z_pocket) bottle(b1L[0], b1L[1], "red"); }'
chk "the sleeves sit in the pockets" CLEAR 'intersection(){ printed(); for (i = [0, 1]) sleeve_at(i); }'
chk "a 125 mL bottle in its sleeve has its cap at the rim" SOLID 'intersection(){ bottle_at(0); translate([0, 0, z_top - 12]) cube([W, D, 12]); }'
chk "self-test: a 100 mm bottle doesn't fit" SOLID 'intersection(){ printed(); at(can_c[0], z_pocket) cylinder(d = 100, h = 50); }'
chk "each chase runs clear from the top, through the column floor, into the tray" CLEAR 'intersection(){ printed(); for (c = chase_c) at(c, floor_t + 1) cylinder(d = 8, h = H); }'
chk "the chases don't open into the pockets" CLEAR 'intersection(){ union(){ for (c = chase_c) at(c, z_pocket) cylinder(d = chase_id, h = can_h); } union(){ for (c = can_c) at(c, z_pocket) cylinder(d = pocket_d, h = can_h); } }'
chk "each web wall fuses into both cans along its height" SOLID 'for (x = web_x, c = can_c) intersection(){ translate([x, can_c[0][1], z_floor + 100]) cube([3, can_c[1][1] - can_c[0][1], 1]); at(c, z_floor + 99) difference(){ cylinder(d = can_od, h = 3); translate([0,0,-1]) cylinder(d = pocket_d, h = 5); } }'
chk "the web walls don't reach into the pockets" CLEAR 'intersection(){ printed(); union(){ for (c = can_c) at(c, z_pocket) cylinder(d = pocket_d, h = can_h); } }'
chk "the windows open into the pockets" CLEAR 'intersection(){ printed(); translate([can_c[0][0] - 4, -5, z_pocket + 60]) cube([8, 30, 40]); }'

echo "== the base =="
chk "pumps sit inside: motors through the bulkhead, flanges against it" CLEAR 'intersection(){ printed(); pumps(); }'
chk "self-test: a pump 3 mm lower hits the bulkhead's slot" SOLID 'intersection(){ printed(); translate([0,0,-3]) pump(0); }'
chk "each pump lifts straight up and out (plate off)" CLEAR 'intersection(){ union(){ tray(0); tray(1); } union(){ for (k = [0:2], dz = [0:10:80]) translate([0,0,dz]) pump(k); } }'
chk "the covers close the openings and their screws meet the bosses" CLEAR 'intersection(){ printed(); union(){ covers(); for (k = [0:2], sx = [-1, 1], sz = [-1, 1]) translate([pump_x[k] + sx*cover_screw, -3, pump_z + sz*cover_screw_z]) rotate([-90, 0, 0]) cylinder(d = 2.6, h = 12); } }'
chk "self-test: a cover screw 3 mm over misses its boss" SOLID 'intersection(){ printed(); translate([pump_x[0] + cover_screw + 3, -3, pump_z + cover_screw_z]) rotate([-90, 0, 0]) cylinder(d = 2.6, h = 12); }'
chk "the flange screws can be driven from the front, through the opening" CLEAR 'intersection(){ union(){ printed(); pumps(); } union(){ for (k = [0:2], i = [0, 1]) translate([pump_x[k] + pump_hole(i)[0], -30, pump_z + pump_hole(i)[1]]) rotate([-90, 0, 0]) cylinder(d = 5, h = bulk_y - pump_flange_t + 29); } }'
chk "the flange screws meet their pilot holes in the bulkhead" CLEAR 'intersection(){ printed(); union(){ for (k = [0:2], i = [0, 1]) translate([pump_x[k] + pump_hole(i)[0], bulk_y - 2, pump_z + pump_hole(i)[1]]) rotate([-90, 0, 0]) cylinder(d = 2.6, h = wall + 4); } }'
chk "self-test: a screw 3 mm over hits the bulkhead" SOLID 'intersection(){ printed(); translate([pump_x[0] + pump_hole(0)[0] + 3, bulk_y - 2, pump_z + pump_hole(0)[1]]) rotate([-90, 0, 0]) cylinder(d = 2.6, h = wall + 4); }'
chk "the upper nozzle's tube clears the plate and the column" CLEAR 'intersection(){ union(){ plate(); column(); } union(){ for (k = [0:2], i = [0, 1]) translate([pump_x[k] + nozzle(i)[0], barb_y, pump_z + nozzle(i)[1]]) sphere(d = tube_od + 1); } }'
chk "each pump's two tubes have room to loop from the nozzles back to the slot" CLEAR 'intersection(){ union(){ printed(); pumps(); panel_hw(); } union(){ for (k = [0:2]) translate([pump_x[k] + nozzle(1)[0] + 3, barb_y - 2, pump_z + 14]) cube([tube_slot_x(k) + 3 - pump_x[k] - nozzle(1)[0], bulk_y - barb_y + 1, tray_h - pump_z - 15]); } }'
chk "each pump's two tubes pass the slot beside it in the bulkhead" CLEAR 'intersection(){ printed(); union(){ for (k = [0:2], dz = [-8, 8]) translate([tube_slot_x(k), bulk_y - 12, pump_z + dz]) rotate([-90,0,0]) cylinder(d = 7, h = 30); } }'
chk "the boards rest on their standoffs" SOLID 'intersection(){ tray(1); union(){ for (b = boards) translate([x_cen, 0, -0.5] + b[0]) cube([b[1][0], b[1][1], 0.5]); } }'
chk "the boards clear the printed parts and the pumps" CLEAR 'intersection(){ union(){ printed(); pumps(); } electronics(); }'
chk "the boards fit under the column floor" CLEAR 'intersection(){ electronics(); translate([0,0,tray_h]) cube([W, D, 10]); }'
chk "no board sits over another" CLEAR 'for (a = [0:2], b = [0:2]) if (a < b) intersection(){ translate([x_cen,0,0] + boards[a][0]) cube(boards[a][1]); translate([x_cen,0,0] + boards[b][0]) cube(boards[b][1]); }'
chk "the USB slot lands on the DevKit's end" SOLID 'intersection(){ translate([x_cen + usb_slot[0] - 6, D - wall - 1, usb_slot[1]]) cube([12, wall + 2, 8]); translate([x_cen + boards[0][0][0] - 1, D - wall - 2, boards[0][0][2] - 2]) cube([boards[0][1][0] + 2, 3, 10]); }'
chk "panel hardware passes its holes and clears everything" CLEAR 'intersection(){ union(){ printed(); electronics(); pumps(); covers(); } panel_hw(); }'
chk "self-test: the DC jack 4 mm over hits the back wall" SOLID 'intersection(){ printed(); translate([4,0,0]) dc_jack(); }'
chk "the seam carries two tube holes and a wire hole" CLEAR 'intersection(){ printed(); union(){ for (t = seam_tube) translate([x_cen - 10, t[0], t[1]]) rotate([0,90,0]) cylinder(d = seam_tube_d - 1, h = 20); translate([x_cen - 10, seam_wire[0], seam_wire[1]]) rotate([0,90,0]) cylinder(d = seam_wire[2] - 1, h = 20); } }'
chk "the floors are closed: no hole leads out of the bottom of the case" CLEAR 'difference(){ translate([wall, wall, 0.1]) cube([W - 2*wall, D - 2*wall, floor_t - 0.2]); printed(); }'
chk "self-test: the same slab 0.5 mm taller finds the cavities" SOLID 'difference(){ translate([wall, wall, 0]) cube([W - 2*wall, D - 2*wall, floor_t + 0.5]); printed(); }'

echo "== the joints =="
chk "no two printed pieces overlap" CLEAR 'for (a = [0:2], b = [0:2]) if (a < b) intersection(){ piece(a); piece(b); }'
chk "seam bolts pass through both walls" CLEAR 'intersection(){ printed(); union(){ for (b = seam_bolts) translate([x_cen - 10, b[0], b[1]]) rotate([0,90,0]) cylinder(d = 3, h = 20); } }'
chk "plate screws reach the dock's posts" CLEAR 'intersection(){ printed(); union(){ for (p = dock_posts()) at(p, tray_h - 7) cylinder(d = 3, h = 12); } }'
chk "column screws reach the column tray's posts" CLEAR 'intersection(){ printed(); union(){ for (p = col_screws) at(p, tray_h - 7) cylinder(d = 3, h = 12); } }'
chk "self-test: a screw 3 mm off misses its hole" SOLID 'intersection(){ printed(); at(col_screws[0] + [3, 0], tray_h - 7) cylinder(d = 3, h = 12); }'
chk "a driver reaches every column and plate screw from above" CLEAR 'intersection(){ union(){ printed(); bottles_shown(); } union(){ for (p = concat(col_screws, dock_posts())) at(p, base_h + 0.5) cylinder(d = 7, h = 400); } }'
chk "every post stands against a wall" SOLID 'for (p = concat(col_screws, dock_posts())) intersection(){ post(p, tray_h); union(){ cube([W, wall + 0.01, tray_h]); translate([0, D - wall - 0.01, 0]) cube([W, wall + 0.01, tray_h]); cube([wall + 0.01, D, tray_h]); translate([W - wall - 0.01, 0, 0]) cube([wall + 0.01, D, tray_h]); translate([x_cen - wall - 0.01, 0, 0]) cube([wall*2 + 0.02, D, tray_h]); } }'
chk "the bulkhead reaches up to the plate and the column floor" SOLID 'intersection(){ union(){ tray(0); tray(1); } translate([wall + 1, bulk_y, tray_h - 1]) cube([W - 2*wall - 2, wall, 0.4]); }'

echo "== every exported piece: fits the P1S, sits on the bed, mostly supported =="
D0="$(dirname "$S")/stl"
[[ -d "$D0" ]] || { echo "  ERROR no stl/ -- run ./export.sh"; ((fail++)); }
total=0
for f in $D0/*.stl(N); do
  r=($(python3 $T/stl.py $f))
  fp=$(awk -v x=${r[1]} -v y=${r[2]} 'BEGIN{print x*y}')
  ok=$(awk -v x=${r[1]} -v y=${r[2]} -v z=${r[3]} -v lo=${r[4]} -v bed=${r[5]} -v un=${r[6]} -v fp=$fp -v nm=${r[8]} 'BEGIN{print (x<=256&&y<=256&&z<=256&&lo>-0.01&&lo<0.01&&bed>=0.08*fp&&un<=800&&nm==0)}')
  g=$(awk -v v=${r[7]} 'BEGIN{printf "%.0f", v*1.27/1000}')
  total=$((total + g))
  if [[ $ok == 1 ]]; then echo "  PASS  ${f:t:r}  ${r[1,3]}  bed ${r[5]} mm2  unsupported ${r[6]} mm2  ~${g} g solid"; ((pass++))
  else echo "  FAIL  ${f:t:r}  ${r[1,3]}  lowest z ${r[4]}  bed ${r[5]} of ${fp} mm2  unsupported ${r[6]} mm2  non-manifold edges ${r[8]}"; ((fail++)); fi
done
echo "  (solid PETG mass per piece; the slicer's infill brings the big ones down)"

rm -rf $T
echo "== $pass passed, $fail failed =="
(( fail == 0 ))
