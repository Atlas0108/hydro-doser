// SUPERSEDED: the back wall now takes the three barbs directly, in
// their own Ø6.4 holes above the middle motor. Kept for reference only.
//
// Hydro Doser v3, outlet block: replaces the grommet in the back wall's
// 16 mm outlet hole with three push-on hose barbs, so the output hoses
// connect at the back.
//
// The barbs are the uxcell plastic bulkhead hose barbs (Amazon B0F5X3DXQ5)
// already used on the Rise service door: an M6 body, a 3 mm barb (out,
// for the hoses) and a 4 mm barb (in, for the doser's tubes). They screw
// down into printed M6 threads in the block's top, pointing up; their nuts
// are not needed, their washers go under their collars. The block is open
// underneath: screw the barbs in, push the doser's three tubes onto their
// inner barbs from below, feed the tubes through the spigot, and press the
// spigot into the wall's hole, where its fingers snap behind the wall.
//
// Frame as the v3 model: x right -> left seen from the front, y front ->
// back, z up. The back wall's outer face is at y = 178.
//
//   openscad -o ../stl/outlet-block.stl --export-format binstl -D 'part="print"' outlet-block.scad

use <../hydro-doser-v3.scad>           // the body as printed, the jack and the GX12: for the checks

part = "all";
$fn = 64;

By = 178;  wall = 3;
hole = [101, 11, 16];                  // the outlet hole: x, z, dia
m6   = [6, 1, 0.25, 8];                // the barbs' thread: major dia, pitch, printed clearance, length in the top
barb_x = [hole[0] - 12, hole[0], hole[0] + 12];   // the three barbs, 12 apart (their collars are 11.5 across corners)
blk  = [38, 18, 2, [2, 38]];           // the block: width, depth off the wall, wall, bottom and top z
barb_y = By + 10;                      // the barbs' line, 10 off the wall: room for the tubes to turn into the spigot
spig = [15.6, 11.6, 1.2];              // the spigot: outside dia (0.4 under the hole), bore, snap lip
fr   = 3;                              // the block's outside edges rounded

assert(blk[3][0] > -4 + 1, "the block runs below the body");
assert(barb_x[2] + 5.8 <= hole[0] + blk[0]/2 - 1 && barb_x[0] - 5.8 >= hole[0] - blk[0]/2 + 1, "a barb's collar runs off the block");

module rbox(size, r) hull() for (x = [r, size[0] - r], y = [r, size[1] - r], z = [r, size[2] - r]) translate([x, y, z]) sphere(r = r, $fn = 24);

// a printed thread: a circle off the axis, twisted once a pitch
module thread(d, p, h, grow = 0) let (e = p/4)
  linear_extrude(h, twist = -360*h/p, slices = ceil(h/p*24), convexity = 6) translate([e, 0]) circle(d = d - 2*e + 2*grow, $fn = 36);

module block() color("#1c1c1c") let (x0 = hole[0] - blk[0]/2, z0 = blk[3][0], z1 = blk[3][1]) difference() {
  union() {
    difference() {
      intersection() {                                                                                                   // rounded outside, but square where it meets the wall and at its open bottom
        translate([x0, By - fr, z0 - fr]) rbox([blk[0], blk[1] + fr, z1 - z0 + fr], fr);
        translate([x0 - 1, By, z0]) cube([blk[0] + 2, blk[1] + 1, z1 - z0 + 1]);
      }
      translate([x0 + blk[2], By + blk[2], z0 - 1]) cube([blk[0] - 2*blk[2], blk[1] - 2*blk[2], z1 - z0 - m6[3] + 1]);   // hollow, open underneath; the top is the barbs' 8 of thread
    }
    // the spigot through the wall, four fingers with a ramped lip that snaps behind the wall's inside face
    translate([hole[0], By + 0.01, hole[1]]) rotate([90, 0, 0]) difference() {
      union() {
        cylinder(d = spig[0], h = wall + 0.2 + 0.01);
        translate([0, 0, wall + 0.2]) cylinder(d1 = spig[0] + 2*spig[2], d2 = spig[0] - 1, h = 2.5);
      }
      translate([0, 0, -1]) cylinder(d = spig[1], h = wall + 5);
      for (a = [0, 90]) rotate([0, 0, a]) translate([-spig[0], -0.75, 1]) cube([2*spig[0], 1.5, wall + 5]);
    }
  }
  translate([hole[0], By - 1, hole[1]]) rotate([-90, 0, 0]) cylinder(d = spig[1], h = blk[2] + 2);                     // the tubes' way through the spigot and the block's back
  for (x = barb_x) translate([x, barb_y, z1 - m6[3] - 0.01]) thread(m6[0], m6[1], m6[3] + 0.02, m6[2]);                 // the barbs' threads
}

// the barbs, for the checks: the thread in the top, the collar above, barbs up and down
module barbs() color("#ddd") for (x = barb_x) translate([x, barb_y, blk[3][1]]) {
  translate([0, 0, -m6[3]]) cylinder(d = 4.9, h = m6[3]);                // the thread, at its root (M6 minor): its crests cut into the printed thread
  cylinder(d = 11.5, h = 3, $fn = 6);                                   // the collar on the top
  translate([0, 0, 3]) cylinder(d = 3.2, h = 14);                       // the 3 mm barb, up, for the hose
  translate([0, 0, -m6[3] - 15.5]) cylinder(d = 4.2, h = 15.5);         // the 4 mm barb, down into the block
}

if (part == "all") { block(); barbs(); }
else if (part == "block") block();
else if (part == "print") translate([0, 0, -blk[3][0]]) block();          // standing on its open bottom: the threads print upright
