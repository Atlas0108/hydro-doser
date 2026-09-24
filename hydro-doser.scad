// Hydro Doser -- a low unit that stands beside a hydroponic garden and doses
// straight into it: a water tank for top-offs, the two nutrient bottles,
// three peristaltic pumps. Firmware: firmware/hydro-doser/. Design notes,
// parts and the review that shaped this version: README.md,
// REVIEW-2026-09-23.md.
//
//   front
//   ╭──────────╮ ╭───╮       tank: a Cambro 6 qt bin on its dock. Its line
//   │  WATER   │ │Spr│       comes out of the column, in through a hole in
//   │          │ │   │       the lid, and sits on the bottom
//   │          │ │Thr│       column: two cans, one bottle each, front / back
//   ├──────────┴─┴───┤
//   │ [W]  [S]  ●○○ [T]      base: two trays bolted side by side. Pumps behind
//   └────────────────┘       removable covers; one sleeved bundle leaves the
//   345 wide x 225 deep x 315 tall     back, to the reservoir
//
// Coordinates: x across (0 = left), y depth (0 = front), z up. Printed parts
// are the shell colour, bought parts are drawn in their own colours. All
// printed parts print as they stand, no supports.
//
//   ./export.sh                                          # every print, into stl/
//   openscad -o mockup.stl hydro-doser.scad               # the whole unit, to look at
//   openscad -o x.stl -D 'part="column"' hydro-doser.scad

part    = "assembly";   // assembly | none | tray_dock | tray_col | plate | column | sleeve | cover | spout
bottles = "125";        // "125" = the small bottles in sleeves, "1L" = scaled up
fill    = 0.7;          // how full the tank is drawn, 0..1
$fn = 64;

// ------------------------------------------------------------ bought parts
// Cambro CamSquare 6 qt, 6SFSPP190: 8-3/8 x 8-3/8 x 7-1/4" (213 x 213 x 184),
// lid SFC6. The base taper, corner radius and lid are estimates. MEASURE.
bin_top   = 213;
bin_bot   = 195;
bin_h     = 184;
bin_r     = 14;
lid_w     = 219;
lid_above = 6;
lid_hole_d = 10;       // drilled in the lid for the tank line

// INTLLAB 12 V peristaltic pump, from its drawing: a 38 x 23 head, a
// 55 x 41 diamond flange with two 3.2 mm holes 48.5 apart on the horizontal
// axis, a 29 x 44 motor. Two nozzles stand 10 mm off the top of the head,
// 16 mm apart; the tube runs through the head and out of them.
pump_head_d  = 38;
pump_head_l  = 23;
pump_flange  = [55, 41];
pump_flange_t = 3;
pump_hole_sp = 48.5;   // the two mounting holes, centre to centre, on the flange's long axis
pump_hole_d  = 3.2;
pump_motor_d = 27;     // the drawing says 29 over the can's rim; retailers quote 26 for the can itself
pump_motor_l = 44;
nozzle_h     = 10;
nozzle_sp    = 16;     // the two nozzles, centre to centre, across the head's top
// The pump is rolled about its axis so the nozzles point up and sideways:
// upright, they'd run into the plate; at 90 degrees the upper mounting hole
// would fall inside the motor's U-slot. 42 degrees puts both holes on solid
// bulkhead and the upper nozzle's tube 4.6 mm under the plate. (The first
// dock tray was printed with the pump 2 mm higher: seat the pump at the
// bottom of its slot and roll it 43 degrees; that clears the plate by 2.8.)
pump_roll    = 42;

b125 = [54, 122];      // 125 mL bottle: [diameter, height with cap] (est.)
b1L  = [90, 230];      // a generic 1 L round
tube_od = 6.35;        // 1/4" silicone

// ------------------------------------------------------------------- shell
wall     = 3;
R        = 8;          // the unit's outer vertical corners
f_bot    = 1.5;        // fillet along the base's bottom edge (kept small: it prints as an overhang)
f_top    = 2;          // fillet along the plate's and the column floor's top edge
f_can    = 3;          // cove where each can meets the column floor
f_chase  = 2;          // cove where each chase and web wall meets it (2: stays clear of the pocket bore)
floor_t  = 4;
plate_t  = 4;
dock_w   = bin_top + 12;                   // 225: tank + 6 each side
cen_w    = 120;
D        = bin_top + 12;                   // 225
base_h   = 70;                             // tray + plate; the tank and column stand on this
tray_h   = base_h - plate_t;               // 66
can_h    = 245;                            // the column's cans, above its floor plate
W        = dock_w + cen_w;                 // 345
H        = base_h + can_h;                 // 315

x_cen    = dock_w;                         // the column tray starts here
tank_c   = [dock_w/2, D/2];

// Pumps: Water and Nutrient A in the dock, Nutrient B in the column tray with the
// electronics. Each lies along y, head to the front behind a removable
// cover, flange screwed from the front to a bulkhead, motor through a U-slot
// in it. Each is rolled so its two barbs point +x, into the room beside the
// head; the tubes loop back and pass through a slot in the bulkhead.
pump_x    = [46, 130, x_cen + 49];
pump_z    = floor_t + 28;                  // 2 mm lower than the first printed dock tray, for headroom over the nozzles
pump_y    = wall + 2;                      // head's front face
bulk_y    = pump_y + pump_head_l + 3;      // bulkhead's front face, where the flange sits
bulk_h    = tray_h - 0.5;                  // up to the plate: it carries the plate mid-span
barb_y    = pump_y + 8;                    // where the nozzles stand on the head
// A point (dx, dz) on the pump's cross-section, after the roll.
function rolled(dx, dz) = [dx*cos(pump_roll) + dz*sin(pump_roll), -dx*sin(pump_roll) + dz*cos(pump_roll)];
function nozzle(i)      = rolled((i == 0 ? -1 : 1) * nozzle_sp/2, pump_head_d/2 + nozzle_h);   // tip of nozzle i, (dx, dz) from the axis
function pump_hole(i)   = rolled((i == 0 ? -1 : 1) * pump_hole_sp/2, 0);                        // mounting hole i, (dx, dz) from the axis
function barb_tip(k)    = pump_x[k] + nozzle(1)[0];          // x of the outer nozzle's tip
function tube_slot_x(k) = pump_x[k] + 40;                    // where the tubes cross the bulkhead
opening   = 50;                            // front access opening (4 mm corners: the flange screws sit at their centres), behind a 66 x 66 cover
cover_w   = 66;
cover_t   = 2;
cover_screw = 29;                          // cover screws at (+-29, +-26), M3 into ribs inside the wall
cover_screw_z = 26;
crossbar_y = 165;                          // second wall across the dock, under the plate
pump_names = ["Water", "Nutrient A", "Nutrient B"];

// The column: two cans on a floor plate. Pockets take bottles up to ~92 mm.
can_od    = 102;
pocket_d  = 96;
can_c     = [[x_cen + cen_w/2, 56], [x_cen + cen_w/2, D - 56]];   // front: Nutrient A, back: Nutrient B; 5 mm in from the floor's edge so the coves land on flat plate
z_floor   = tray_h;                        // the column's floor plate sits on the tray
z_pocket  = z_floor + floor_t;             // 70, pocket floor
z_top     = z_pocket + can_h;              // 315
// Chases: a tube from the floor up, open at the top, one per line. Nutrient A's
// in the front can's front-left corner, Nutrient B's in the back can's
// back-right, and the tank line's in the left web wall. They stand as tall
// as the web walls, 12 mm below the can rims; each line simply comes out of
// the top of its chase.
chase_id  = 12;
chase_od  = 16;
chase_c   = [[x_cen + 19, 15], [x_cen + 12.5, D/2], [x_cen + cen_w - 19, D - 15]];   // Nutrient A, tank line, Nutrient B; each 1 mm into its can wall; the tank line's bore grazes the web wall by 0.5 (exactly tangent exports non-manifold)
chase_h   = floor_t + can_h - 12;
exit_z    = z_floor + chase_h;             // where the tank line leaves its chase
lid_hole  = [x_cen - 30, D/2];             // in the tank lid, under the tank line's exit
// Two walls join the cans into one stiff box section: each runs from the
// front can's centre line to the back can's, fusing into both can walls
// (the pockets cut away what falls inside them). The left one also carries
// the tank chase.
web_x     = [x_cen + 18, x_cen + cen_w - 21];
// The column's floor plate screws to the tray's posts where it is exposed:
// two free corners and the right side at the waist.
col_screws = [[x_cen + cen_w - 8, 8], [x_cen + 8, D - 8], [x_cen + cen_w - 8, D/2]];

// Seam between the trays: three M3 through-bolts, three tube holes (one in
// the front bay for Nutrient A's feed, two behind the bulkhead), a wire hole.
seam_bolts = [[16, 30], [D - 20, 30], [D/2, 56]];    // [y, z]
seam_tube  = [[20, 14], [110, 16], [130, 16]];   // the front one sits between the corner post and the bulkhead
seam_tube_d = 14;
seam_wire  = [150, 16, 10];

// Dock front, local x: the control panel at the far right, stacked: Dose
// below, Stop above, the light beside them.
panel  = [[200, 22, 12.5, "Dose"], [186, 34, 8, "status LED"], [200, 46, 12.5, "Stop"]];   // [x, z, dia]
// Column tray back wall, local x: USB slot for the DevKit, jack, GX12 for
// the float lead, and the grommet the sleeved bundle leaves through.
usb_slot = [20, 12];                                     // local x, z
jacks    = [[50, 30, 11.5, "12 V jack"], [72, 30, 12.2, "GX12, float lead"], [98, 30, 16, "bundle grommet"]];
// Boards on 6 mm standoffs in the column tray, behind the Nutrient B motor.
boards = [   // [local position, size, colour, what]
  [[6, 150, floor_t + 6],  [28, 55, 4],  "#1f4e8c", "ESP32 DevKit, USB to the back"],
  [[40, 140, floor_t + 6], [35, 32, 15], "#1e6b35", "ULN2003, six of its seven channels: two per pump"],
  [[40, 178, floor_t + 6], [45, 20, 12], "#111",    "12 -> 5 V buck"],
];

c_shell = "#EDEBE4";

// --------------------------------------------------------------- the rules
assert(b1L[0] + 2 <= pocket_d, "1 L bottle doesn't fit its pocket");
assert(pump_x[1] - pump_head_d/2 > pump_x[0] + pump_head_d/2 + 30, "the dock's pumps need 30 mm between their heads for the tube loops");
assert(pump_z + pump_head_d/2 + 2 <= tray_h, "the pump heads don't fit under the plate");
assert(pump_z + nozzle(0)[1] + tube_od/2 + 2 <= tray_h, "the upper nozzle's tube runs into the plate: roll the pump further");
assert(abs(pump_hole(0)[0]) - pump_hole_d/2 > (pump_motor_d + 3)/2 + 0.5 || pump_hole(0)[1] < 0, "a mounting hole falls inside the motor's U-slot");
assert(abs(pump_hole(1)[0]) - pump_hole_d/2 > (pump_motor_d + 3)/2 + 0.5 || pump_hole(1)[1] < 0, "a mounting hole falls inside the motor's U-slot");
assert(exit_z >= base_h + bin_h + lid_above + 20, "the tank chase's top must sit well above the lid");
assert(max(dock_w, D, floor_t + can_h, tray_h) <= 256, "a printed piece is bigger than the P1S bed");
// every cove foot on flat plate: inside the column floor's top-edge fillet
assert(can_c[0][1] - can_od/2 - f_can >= f_top && D - can_c[1][1] - can_od/2 - f_can >= f_top, "a can's cove runs onto the floor's edge fillet");
for (c = chase_c) assert(c[0] - chase_od/2 - f_chase >= x_cen + f_top && c[0] + chase_od/2 + f_chase <= x_cen + cen_w - f_top
                      && c[1] - chase_od/2 - f_chase >= f_top && c[1] + chase_od/2 + f_chase <= D - f_top, "a chase's cove runs onto the floor's edge fillet");

// ----------------------------------------------------------------- helpers
module rsq(w, d, r) offset(r) square([w - 2*r, d - 2*r], center = true);
module corner(x, y, r, sx, sy) if (r > 0) translate([x + sx*r, y + sy*r]) circle(r); else translate([x + (sx < 0 ? -0.01 : 0), y + (sy < 0 ? -0.01 : 0)]) square(0.01);
module fp(x0, y0, w, d, rl, rr) hull() {
  corner(x0, y0, rl, 1, 1); corner(x0, y0 + d, rl, 1, -1);
  corner(x0 + w, y0, rr, -1, 1); corner(x0 + w, y0 + d, rr, -1, -1);
}
module at(p, z = 0) translate([p[0], p[1], z]) children();
module front_hole(x, z, d) translate([x, wall + 1, z]) rotate([90, 0, 0]) linear_extrude(wall + 2) circle(d = d);
module back_hole(x, z, d)  translate([x, D + 1, z]) rotate([90, 0, 0]) linear_extrude(wall + 2) circle(d = d);
// M3 heat-set, 3 mm walls. Starts inside the floor rather than at z = 0: a corner
// post's square corner pokes a few hundredths past the base's bottom fillet
// where the skin is inset, and that sliver exports as non-manifold edges.
module post(p, h) translate([p[0] - 5, p[1] - 5, floor_t/2]) difference() { cube([10, 10, h - floor_t/2]); translate([5, 5, h - floor_t/2 - 8]) cylinder(d = 4, h = 9); }
// A 2D profile extruded h tall, with a fillet of r_b along its bottom edge
// and r_t along its top: a hull of slices, each inset along the fillet's arc.
module fillet_extrude(h, r_b = 0, r_t = 0, n = 6) hull() {
  if (r_b > 0) for (i = [0:n]) let (a = 90 * i / n, z = r_b - r_b * cos(a), in = r_b - r_b * sin(a))
    translate([0, 0, z]) linear_extrude(0.01) offset(r = -in) children();
  if (r_t > 0) for (i = [0:n]) let (a = 90 * i / n, z = h - r_t + r_t * sin(a), in = r_t - r_t * cos(a))
    translate([0, 0, z - 0.01]) linear_extrude(0.01) offset(r = -in) children();
  translate([0, 0, r_b]) linear_extrude(max(h - r_b - r_t, 0.01)) children();
}
// The base's outer skin, one rounded body across both trays; each tray is
// a slice of it, so the assembled base has no groove at the seam.
module base_skin() fillet_extrude(tray_h, f_bot, 0) fp(0, 0, W, D, R, R);
module x_slice(x0, w) translate([x0, -1, -1]) cube([w, D + 2, H + 20]);
// A rounded-end slot through a wall along y, w wide, from z0 to z1.
module window(x, y0, y1, z0, z1, w) hull() for (z = [z0 + w/2, z1 - w/2]) translate([x, y0, z]) rotate([-90, 0, 0]) cylinder(d = w, h = y1 - y0);
// A concave fillet where a cylinder of diameter d stands on a floor: a ring
// that fills the corner, tangent to both. It widens going down, so it
// prints without support.
// The profile reaches 0.5 mm into the wall it stands against: a face exactly
// coincident with the wall's facets exports as non-manifold edges.
module cove_profile(r, in = 0.5) translate([-in, 0]) difference() { square([r + in, r]); translate([r + in, r]) circle(r); }
module cove(d, r) rotate_extrude() translate([d/2, 0]) cove_profile(r);
// The same along a straight wall t thick and l long (along +y), both sides.
module cove_wall(t, l, r) rotate([90, 0, 0]) translate([0, 0, -l]) linear_extrude(l) for (sx = [-1, 1]) scale([sx, 1]) translate([t/2, 0]) cove_profile(r);
module csk(d = 3.4, h = 10) { cylinder(d = d, h = h); translate([0, 0, h - 2]) cylinder(d1 = d, d2 = d + 4, h = 2.01); }   // countersunk M3, head at the top

function dock_posts() = [[8, 8], [dock_w - 8, 8], [8, D - 8], [dock_w - 8, D - 8]];

// =========================================================== printed parts
// A tray: floor, walls, bulkhead, posts, holes. i = 0 dock, 1 column tray.
module tray(i) let (x0 = i == 0 ? 0 : x_cen, w = i == 0 ? dock_w : cen_w, rl = i == 0 ? R : 0, rr = i == 0 ? 0 : R) difference() {
  union() {
    difference() {
      intersection() { base_skin(); x_slice(x0, w); }
      translate([0, 0, floor_t]) linear_extrude(tray_h) fp(x0 + wall, wall, w - 2*wall, D - 2*wall, max(rl - wall, 0), max(rr - wall, 0));
    }
    for (p = i == 0 ? dock_posts() : col_screws) post(p, tray_h);
    translate([x0 + wall - 0.01, bulk_y, 0]) cube([w - 2*wall + 0.02, wall, bulk_h]);                 // the bulkhead
    if (i == 0) translate([x0 + wall - 0.01, crossbar_y, 0]) cube([w - 2*wall + 0.02, wall, bulk_h]); // second support for the plate
    // cover-screw ribs inside the front wall, floor to plate, and standoffs for the boards
    for (k = [0:2]) if (pump_x[k] > x0 && pump_x[k] < x0 + w) for (sx = [-1, 1])
      translate([pump_x[k] + sx*cover_screw - 4, wall - 0.01, 0]) cube([8, 6, bulk_h]);
    if (i == 1) for (b = boards, cx = [3, b[1][0] - 3], cy = [3, b[1][1] - 3]) translate([x0 + b[0][0] + cx, b[0][1] + cy, 0]) cylinder(d = 5, h = floor_t + 6);
  }
  for (k = [0:2]) if (pump_x[k] > x0 && pump_x[k] < x0 + w) {
    // front: the access opening; cover screws into the bosses
    translate([pump_x[k], wall + 1, pump_z]) rotate([90, 0, 0]) linear_extrude(wall + 2) rsq(opening, opening, 4);
    for (sx = [-1, 1], sz = [-1, 1]) translate([pump_x[k] + sx*cover_screw, -1, pump_z + sz*cover_screw_z]) rotate([-90, 0, 0]) cylinder(d = 2.8, h = 12);
    // bulkhead: motor U-slot open at the top, flange screws (lower pair), tube slot
    translate([pump_x[k], bulk_y - 1, pump_z]) rotate([-90, 0, 0]) {
      linear_extrude(wall + 2) { circle(d = pump_motor_d + 3); translate([-(pump_motor_d + 3)/2, -bulk_h]) square([pump_motor_d + 3, bulk_h]); }
      for (i = [0, 1]) translate([pump_hole(i)[0], -pump_hole(i)[1], 0]) cylinder(d = 2.8, h = wall + 2);   // the rolled flange's holes; 2D y is -z here
    }
    window(tube_slot_x(k), bulk_y - 1, bulk_y + wall + 1, pump_z - 14, pump_z + 14, 12);
  }
  // the seam: bolts, tube holes, a wire hole, through both trays' walls
  for (b = seam_bolts) translate([x_cen - wall - 1, b[0], b[1]]) rotate([0, 90, 0]) cylinder(d = 3.4, h = wall*2 + 2);
  for (t = seam_tube) translate([x_cen - wall - 1, t[0], t[1]]) rotate([0, 90, 0]) cylinder(d = seam_tube_d, h = wall*2 + 2);
  translate([x_cen - wall - 1, seam_wire[0], seam_wire[1]]) rotate([0, 90, 0]) cylinder(d = seam_wire[2], h = wall*2 + 2);
  if (i == 0) for (p = panel) front_hole(x0 + p[0], p[1], p[2]);
  if (i == 1) {
    for (j = jacks) back_hole(x0 + j[0], j[1], j[2]);
    translate([x0 + usb_slot[0] - 6, D - wall - 1, usb_slot[1]]) cube([12, wall + 2, 8]);
  }
}

// The dock plate: closes the dock, screws to its posts. A 3 mm curb locates
// the tank; a rim keeps spills on the plate and a notch at the back lets
// them run off the outside of the case.
module plate() difference() {
  union() {
    translate([0, 0, tray_h]) fillet_extrude(plate_t, 0, f_top) fp(0, 0, dock_w, D, R, 0);
    at(tank_c, base_h) linear_extrude(3) difference() { rsq(bin_bot + 8, bin_bot + 8, bin_r + 4); rsq(bin_bot + 2, bin_bot + 2, bin_r + 1); }
    translate([0, 0, base_h]) linear_extrude(1.5) difference() { fp(2.5, 2.5, dock_w - 5, D - 5, R - 2.5, 0); fp(4.5, 4.5, dock_w - 9, D - 9, R - 4.5, 0); translate([dock_w/2 - 8, D - 6]) square([16, 8]); }
  }
  for (p = dock_posts()) at(p, tray_h - 1) csk(3.4, plate_t + 1);
}

// A cover for a pump's front opening: a plate with two countersunk screws.
module cover(k = 0) translate([pump_x[k], 0, pump_z]) rotate([90, 0, 0]) difference() {
  fillet_extrude(cover_t, 0, 1) rsq(cover_w, cover_w, 6);
  for (sx = [-1, 1], sz = [-1, 1]) translate([sx*cover_screw, sz*cover_screw_z, -0.01]) csk(3.4, cover_t + 0.02);
}
// The cover, lying flat for export: outside face on the bed.
module cover_flat() rotate([-90, 0, 0]) translate([-pump_x[0], 0, -pump_z]) cover(0);

// The column: two cans on a floor plate, a web between them, a chase tube
// on each can for a line. Screws down to the tray's posts at its corners,
// where the plate is exposed. Prints on its floor.
module column() difference() {
  union() {
    translate([0, 0, z_floor]) fillet_extrude(floor_t, 0, f_top) fp(x_cen, 0, cen_w, D, 0, R);
    for (c = can_c) at(c, z_floor) cylinder(d = can_od, h = floor_t + can_h);
    for (x = web_x) translate([x, can_c[0][1], z_floor]) cube([3, can_c[1][1] - can_c[0][1], floor_t + can_h - 12]);   // the web walls
    for (c = chase_c) at(c, z_floor) cylinder(d = chase_od, h = chase_h);
    // coves at the foot of each can, chase and web wall. Every foot must land
    // on the floor's flat top, inside its edge fillet: a cove that crosses
    // the rounded edge would have to be cut, and the cut shows (see the rules).
    for (c = can_c) at(c, z_pocket) cove(can_od, f_can);
    difference() {   // a chase cove stops inside its can's wall, short of the pocket bore: tangent to it exports non-manifold
      for (c = chase_c) at(c, z_pocket) cove(chase_od, f_chase);
      for (k = can_c) at(k, z_pocket - 1) cylinder(d = pocket_d + 2, h = f_chase + 2);
    }
    for (x = web_x) translate([x + 1.5, can_c[0][1], z_pocket]) cove_wall(3, can_c[1][1] - can_c[0][1], f_chase);
  }
  for (c = can_c) { at(c, z_pocket) cylinder(d = pocket_d, h = can_h + 1); at(c, z_top - 1.5) cylinder(d1 = pocket_d, d2 = pocket_d + 3, h = 1.51); }
  for (c = chase_c) { at(c, z_floor - 1) cylinder(d = chase_id, h = chase_h + 2); at(c, z_floor + chase_h - 1.5) cylinder(d1 = chase_id, d2 = chase_id + 3, h = 1.51); }   // bores, rims chamfered
  window(can_c[0][0], -1, can_c[0][1] - pocket_d/2 + 1, z_pocket + 26, z_top - 15, 12);       // front window, through the can wall
  window(can_c[1][0], can_c[1][1] + pocket_d/2 - 1, D + 1, z_pocket + 26, z_top - 15, 12);     // back window
  for (p = col_screws) at(p, z_floor - 1) csk(3.4, floor_t + 1);
}

// Sleeve for a 125 mL bottle in a 96 mm pocket: a cup on three fins
// and a base ring, the cap at the rim, a window to the front, a notch to
// lift it out. The cup's bottom is a 45-degree cone so it prints unsupported.
sleeve_h = can_h - 2;
cup_h = b125[1] + 8;
module sleeve() difference() {
  union() {
    translate([0, 0, sleeve_h - cup_h]) cylinder(d = b125[0] + 5.5, h = cup_h);
    translate([0, 0, sleeve_h - cup_h - (b125[0] + 5.5)/2]) cylinder(d1 = 0, d2 = b125[0] + 5.5, h = (b125[0] + 5.5)/2);
    difference() { cylinder(d = pocket_d - 1.5, h = 4); translate([0, 0, -1]) cylinder(d = pocket_d - 7.5, h = 6); }   // base ring
    translate([0, 0, sleeve_h - 6]) difference() { cylinder(d = pocket_d - 1.5, h = 6); translate([0, 0, -1]) cylinder(d = pocket_d - 5.5, h = 8); }   // rim ring
    for (a = [90, 210, 330]) rotate(a) translate([0, -1, 0]) cube([pocket_d/2 - 0.75, 2, sleeve_h]);                                              // fins
  }
  translate([0, 0, sleeve_h - b125[1]]) cylinder(d = b125[0] + 1.5, h = b125[1] + 1);
  translate([0, 0, sleeve_h - 1.5]) cylinder(d1 = b125[0] + 1.5, d2 = b125[0] + 4.5, h = 1.51);
  window(0, -pocket_d/2 - 1, -b125[0]/2 + 4, sleeve_h - b125[1] + 10, sleeve_h + 6, 12);
  hull() for (y = [-2, 2]) translate([-pocket_d/2 - 1, y, sleeve_h - 6]) rotate([0, 90, 0]) cylinder(d = 12, h = 12);
}

// The spout: hangs on the reservoir's rim and holds the three tube
// ends and the float lead above the water, so no line can siphon. Rim
// thickness and depth are guesses: measure the reservoir's fill opening.
rim_t = 4; rim_drop = 30;
module spout() difference() {
  union() {
    cube([40, rim_t + 2*wall, rim_drop + 12]);                                              // the hook
    translate([0, -10, 0]) cube([40, 10, 14]);                                              // the ledge the tubes lie in, inside the rim
  }
  translate([-1, wall, 12]) cube([42, rim_t, rim_drop + 1]);                                 // slides over the rim
  for (x = [7, 17, 27]) translate([x, -11, 7]) rotate([-90, 0, 0]) cylinder(d = tube_od + 0.6, h = rim_t + 2*wall + 12);   // three tubes
  translate([34, -11, 7]) rotate([-90, 0, 0]) cylinder(d = 4, h = rim_t + 2*wall + 12);     // the float lead
}

// ============================================================ bought parts
module bin_shape(inset = 0, h = bin_h) hull() {
  linear_extrude(0.01) rsq(bin_bot - 2*inset, bin_bot - 2*inset, bin_r - inset);
  translate([0, 0, h - 0.01]) linear_extrude(0.01)
    let (s = bin_bot + (bin_top - bin_bot) * h / bin_h) rsq(s - 2*inset, s - 2*inset, bin_r - inset);
}
module bin(water = true) at(tank_c, base_h) {
  color([0.85, 0.9, 0.95, 0.35]) difference() { bin_shape(); translate([0, 0, 2]) bin_shape(2, bin_h); }
  if (water) color([0.35, 0.6, 0.85, 0.5]) translate([0, 0, 2.01]) bin_shape(2.5, (bin_h - 25) * fill);
}
module bin_lid() color([0.95, 0.95, 0.95, 0.8]) difference() {
  at(tank_c, base_h + bin_h) linear_extrude(lid_above) rsq(lid_w, lid_w, bin_r + 3);
  at(lid_hole, base_h + bin_h - 1) cylinder(d = lid_hole_d, h = lid_above + 2);
}
// The pump, in the pieces it really has, so renders can colour each one:
// a white head with a roller chamber behind a clear cover, the square
// flange, the motor can, its end cap, and the two barbs.
module pump_frame(k) translate([pump_x[k], 0, pump_z]) rotate([0, pump_roll, 0]) children();   // the pump's own frame, rolled
module pump_head(k) pump_frame(k) color("white") difference() {
  translate([0, pump_y + 3, 0]) rotate([-90, 0, 0]) cylinder(d = pump_head_d, h = pump_head_l - 3);
  translate([0, pump_y + 2, 0]) rotate([-90, 0, 0]) cylinder(d = pump_head_d - 8, h = 7);            // roller chamber
}
module pump_cover(k) pump_frame(k) color([0.9, 0.93, 0.95, 0.5]) translate([0, pump_y, 0]) rotate([-90, 0, 0]) cylinder(d = pump_head_d - 4, h = 3);
module pump_rollers(k) pump_frame(k) color("#777") {
  translate([0, pump_y + 3, 0]) rotate([-90, 0, 0]) cylinder(d = 8, h = 5);                                    // hub
  for (a = [0, 120, 240]) rotate([0, a, 0]) translate([9.5, pump_y + 3, 0]) rotate([-90, 0, 0]) cylinder(d = 7, h = 5);   // three rollers
}
module pump_flange(k) pump_frame(k) color("#222") translate([0, bulk_y - pump_flange_t, 0]) rotate([-90, 0, 0]) linear_extrude(pump_flange_t) difference() {
  polygon([[-pump_flange[0]/2, 0], [0, pump_flange[1]/2], [pump_flange[0]/2, 0], [0, -pump_flange[1]/2]]);   // the diamond
  for (s = [-1, 1]) translate([s*pump_hole_sp/2, 0]) circle(d = pump_hole_d);
}
module pump_motor(k) pump_frame(k) color("silver") translate([0, bulk_y, 0]) rotate([-90, 0, 0]) cylinder(d = pump_motor_d, h = wall + pump_motor_l);
module pump_cap(k) pump_frame(k) color("#333") {
  translate([0, bulk_y + wall + pump_motor_l, 0]) rotate([-90, 0, 0]) cylinder(d = pump_motor_d - 6, h = 3);
  for (dz = [-5, 5]) translate([-0.4, bulk_y + wall + pump_motor_l + 3, dz - 1]) cube([0.8, 4, 2]);        // solder tabs
}
module pump_barbs(k) pump_frame(k) color("#666") for (s = [-1, 1]) translate([s*nozzle_sp/2, barb_y, pump_head_d/2 - 2]) cylinder(d = 5, h = nozzle_h + 2);   // the two nozzles, off the top
module pump(k) { pump_head(k); pump_cover(k); pump_rollers(k); pump_flange(k); pump_motor(k); pump_cap(k); pump_barbs(k); }
module bottle(d, h, c) {
  color(c) { cylinder(d = d, h = h - 22); translate([0, 0, h - 22]) cylinder(d1 = d, d2 = d * 0.55, h = 8); }
  color("white") { translate([0, 0, h - 16]) cylinder(d = d * 0.55, h = 16); translate([0, 0, h * 0.3]) cylinder(d = d + 0.4, h = h * 0.35); }
}
module pcb(size, c) color(c) cube([size[0], size[1], 1.6]);
module esp32_pcb()   translate([x_cen, 0, 0] + boards[0][0]) pcb([28, 55], "#101418");
module esp32_can()   translate([x_cen, 0, 0] + boards[0][0]) color("#b8bbbd") translate([5, 24, 1.6]) cube([18, 19, 3]);   // WROOM shield; the 6 mm past it is the antenna
module esp32_usb()   translate([x_cen, 0, 0] + boards[0][0]) color("#c8c8c8") translate([9, 48, 1.6]) cube([10, 8, 3.5]);
module esp32_pins()  translate([x_cen, 0, 0] + boards[0][0]) color("#222") for (x = [0.6, 24.9]) {
  translate([x, 4, 1.6]) cube([2.5, 48, 2.5]);                                                                   // plastic strip
  for (i = [0:18]) translate([x + 0.93, 4.6 + i*2.54, 4.1]) cube([0.64, 0.64, 6]);                                // the pins
}
module esp32_small() translate([x_cen, 0, 0] + boards[0][0]) color("#2a2a2a") {
  translate([11, 12, 1.6]) cube([5, 5, 1]);                                                                       // USB bridge chip
  for (x = [4, 20]) translate([x, 46, 1.6]) cube([4, 4, 2.5]);                                                    // EN / BOOT buttons
  translate([18, 14, 1.6]) cube([3, 3, 1.2]);                                                                     // regulator
}
module esp32() { esp32_pcb(); esp32_can(); esp32_usb(); esp32_pins(); esp32_small(); }
module uln_pcb(j)  translate([x_cen, 0, 0] + boards[j][0]) pcb([35, 32], "#1e6b35");
module uln_chip(j) translate([x_cen, 0, 0] + boards[j][0]) color("#111") difference() { translate([7, 12, 1.6]) cube([20, 7, 4]); translate([7, 15.5, 5]) cylinder(d = 2, h = 1); }
module uln_hdr(j)  translate([x_cen, 0, 0] + boards[j][0]) color("white") difference() { translate([2, 23, 1.6]) cube([12, 6, 6]); translate([3, 24, 3]) cube([10, 4, 6]); }
module uln_pins(j) translate([x_cen, 0, 0] + boards[j][0]) color("#222") { translate([26, 2, 1.6]) cube([2.5, 18, 2.5]); for (i = [0:6]) translate([26.9, 2.9 + i*2.54, 4.1]) cube([0.64, 0.64, 6]); }
module uln_leds(j) translate([x_cen, 0, 0] + boards[j][0]) color("#c0392b") for (i = [0:3]) translate([16 + i*4, 26, 1.6]) cylinder(d = 3, h = 4);
module uln_res(j)  translate([x_cen, 0, 0] + boards[j][0]) color("#d9c9a3") for (i = [0:3]) translate([16 + i*4, 6, 2.6]) rotate([-90, 0, 0]) cylinder(d = 2, h = 5);
module uln(j) { uln_pcb(j); uln_chip(j); uln_hdr(j); uln_pins(j); uln_leds(j); uln_res(j); }
module buck_body() translate([x_cen, 0, 0] + boards[2][0]) color("#111") cube([45, 20, 12]);
module buck_wire(c) translate([x_cen, 0, 0] + boards[2][0]) color(c == 0 ? "#c00" : "#222") translate([-6, c == 0 ? 6 : 12, 8]) rotate([0, 90, 0]) cylinder(d = 2, h = 6);
module buck() { buck_body(); buck_wire(0); buck_wire(1); }
module button(x, z, d) translate([x, 0, z]) {
  color("#222") { translate([0, -1.5, 0]) rotate([90, 0, 0]) cylinder(d = d + 3, h = 2); translate([0, -6, 0]) rotate([90, 0, 0]) cylinder(d = d - 2, h = 4.5); }
  color("#777") translate([0, wall + 1, 0]) rotate([-90, 0, 0]) { cylinder(d = d + 3, h = 2); cylinder(d = d - 1.5, h = 10); }
  color("#444") translate([0, wall + 11, 0]) rotate([-90, 0, 0]) cylinder(d = 3, h = 8);
}
module light_pipe(x, z) translate([x, 0, z]) {
  color([0.75, 0.95, 0.75, 0.9]) translate([0, -2, 0]) rotate([-90, 0, 0]) cylinder(d = 8, h = wall + 8);
  color("#333") translate([0, wall + 2, 0]) rotate([-90, 0, 0]) cylinder(d = 11, h = 2);
}
module dc_jack() translate([x_cen + jacks[0][0], D, jacks[0][1]]) color("#222") {
  translate([0, 1, 0]) rotate([-90, 0, 0]) cylinder(d = 14, h = 2);
  translate([0, -wall - 16, 0]) rotate([-90, 0, 0]) cylinder(d = 11, h = wall + 16);
}
module gx12() translate([x_cen + jacks[1][0], D, jacks[1][1]]) color("#888") {
  rotate([-90, 0, 0]) cylinder(d = 15, h = 6);
  translate([0, -wall - 12, 0]) rotate([-90, 0, 0]) cylinder(d = 12, h = wall + 12);
  color("#222") translate([0, -wall - 2, 0]) rotate([-90, 0, 0]) cylinder(d = 16, h = 2, $fn = 6);
}
module grommet() translate([x_cen + jacks[2][0], D, jacks[2][1]]) color("#222")
  rotate([-90, 0, 0]) difference() { union() { translate([0, 0, -wall - 2]) cylinder(d = 20, h = 2); translate([0, 0, -wall]) cylinder(d = jacks[2][2] - 0.2, h = wall); cylinder(d = 20, h = 2); } translate([0, 0, -wall - 3]) cylinder(d = 11, h = wall + 6); }
module bundle() translate([x_cen + jacks[2][0], D, jacks[2][1]]) color("#1a1a1a") translate([0, 2, 0]) rotate([-90, 0, 0]) cylinder(d = 12, h = 45);   // the sleeved bundle, to the reservoir
module panel_hw() { button(panel[0][0], panel[0][1], panel[0][2]); light_pipe(panel[1][0], panel[1][1]); button(panel[2][0], panel[2][1], panel[2][2]); dc_jack(); gx12(); grommet(); bundle(); }
module pumps() for (k = [0:2]) pump(k);
module covers() for (k = [0:2]) color(c_shell) cover(k);
module electronics() { esp32(); uln(1); buck(); }
module sleeve_at(i) at(can_c[i], z_pocket) color(c_shell) sleeve();
module bottle_at(i) at(can_c[i], z_pocket) let (c = i == 0 ? [0.7, 0.4, 0.15, 0.8] : [0.93, 0.93, 0.9, 0.8]) {
  if (bottles == "1L") bottle(b1L[0], b1L[1], c);
  else translate([0, 0, sleeve_h - b125[1]]) bottle(b125[0], b125[1], c);
}
module bottles_shown() for (i = [0, 1]) { if (bottles != "1L") sleeve_at(i); bottle_at(i); }

// ================================================================= output
module piece(n) {
  if (n == 0) tray(0);
  if (n == 1) tray(1);
  if (n == 2) plate();
  if (n == 3) column();
}
module printed() color(c_shell) for (n = [0:3]) piece(n);
module assembly() {
  printed(); covers();
  bin(); bin_lid();
  pumps(); electronics(); panel_hw(); bottles_shown();
}

idx = 0;
if (part == "assembly") assembly();
else if (part == "tray_dock") tray(0);
else if (part == "tray_col")  translate([-x_cen, 0, 0]) tray(1);
else if (part == "plate")     translate([0, 0, -tray_h]) plate();
else if (part == "column")    translate([-x_cen, 0, -z_floor]) column();
else if (part == "sleeve")    sleeve();
else if (part == "cover")     cover_flat();
else if (part == "spout")     spout();
else if (part == "spout_at")  translate([303, 300, 0]) spout();
else if (part == "piece")     piece(idx);
else if (part == "bin")       bin(false);
else if (part == "water")     at(tank_c, base_h + 2.01) bin_shape(2.5, (bin_h - 25) * fill);
else if (part == "lid")       bin_lid();
else if (part == "pump")      pump(idx);
else if (part == "cover_at")  cover(idx);
else if (part == "esp32")     esp32();
else if (part == "uln")       uln(idx);
else if (part == "buck")      buck();
else if (part == "sleeve_at") sleeve_at(idx);
else if (part == "bottle")    bottle_at(idx);
else if (part == "dose")      button(panel[0][0], panel[0][1], panel[0][2]);
else if (part == "stop")      button(panel[2][0], panel[2][1], panel[2][2]);
else if (part == "led")       light_pipe(panel[1][0], panel[1][1]);
else if (part == "dcjack")    dc_jack();
else if (part == "gx12")      gx12();
else if (part == "grommet")   grommet();
else if (part == "bundle")    bundle();
// sub-parts, for renders that colour each piece
else if (part == "pump_head")    pump_head(idx);
else if (part == "pump_cover")   pump_cover(idx);
else if (part == "pump_rollers") pump_rollers(idx);
else if (part == "pump_flange")  pump_flange(idx);
else if (part == "pump_motor")   pump_motor(idx);
else if (part == "pump_cap")     pump_cap(idx);
else if (part == "pump_barbs")   pump_barbs(idx);
else if (part == "esp32_pcb")    esp32_pcb();
else if (part == "esp32_can")    esp32_can();
else if (part == "esp32_usb")    esp32_usb();
else if (part == "esp32_pins")   esp32_pins();
else if (part == "esp32_small")  esp32_small();
else if (part == "uln_pcb")      uln_pcb(idx);
else if (part == "uln_chip")     uln_chip(idx);
else if (part == "uln_hdr")      uln_hdr(idx);
else if (part == "uln_pins")     uln_pins(idx);
else if (part == "uln_leds")     uln_leds(idx);
else if (part == "uln_res")      uln_res(idx);
else if (part == "buck_body")    buck_body();
else if (part == "buck_wire")    buck_wire(idx);
