// Hydro Doser v3, detailed to BRIEF.md.
//
// Frame: x right(0) -> left(202), y front(0) -> back(178), z up from the
// body's bottom edge. The base plate is below z = 0, the lid above H.
//
// Four printed pieces and a TPU foot:
//   body   the floor and the walls in one: the pump bulkhead, the two cups,
//          the front opening, the wall-board ribs, four snap-in feet under
//          the floor, a rim on top the lid caps over
//   lid    snaps over the body's rim, flush with it: a rounded edge, a
//          raised deck the bottles stand in, a tube hole beside each
//   plate  the black faceplate: carries the screen and the knob, screws
//          into the body at its corner-radius centres, flush, the seam a
//          rounded groove
//   knob, spout, foot
//
// Every edge is rounded. The bottles stand in the middle of the front; the
// three pumps lie across the back, heads forward, motors to the back wall,
// each rolled 42 degrees as in the first design so its flange screws sit on a
// 42 degree line; the DevKit rides on the faceplate behind the knob, the
// driver and the buck in slots on the side walls beside the cups; the jack
// and the GX12 sit low in the back wall between the motors, the grommet
// above the middle one; vents in the side walls beside the motors.

part = "all";
idx  = 0;
$fn  = 64;

// ------------------------------------------------------------------ brief
pump_head = [38, 23];  pump_flange = [55, 41, 3];  pump_motor = [27, 44];
flange_pitch = 48.5;  flange_hole = 3.2;
nozzle_off = 10;  nozzle_pitch = 16;  nozzle_y = 8;   // off the head's circumference; 8 in from the head's face
tube_od = 5;
esp  = [28.3, 51.5, 1.6, 8.5];             // the 30-pin DevKit V1: w (z), l (x), pcb, pins back; the pin rows 1.3 in from the long edges
esp_hole = [3, 2.3];                       // its four corner holes: dia, centre in from both edges (46.9 x 23.7 apart: measure yours)
tds  = [32, 42, 1.6, 6];                   // the DFRobot Gravity TDS (or pH V2) signal board: short side, long side, pcb, parts on its back
tds_hole = [3.1, 3.5];                     // its four corner holes: dia, centre in from both edges (25 x 35 apart: measure yours)
tds_so   = [6, 25, 2.6];                  // standoffs: dia, height (lifts it over the screen's header and its Dupont plugs), pilot for an M3 self-tapper
esp_so   = [5.5, 5, 2.2];                    // standoffs: dia, height off the plate's back (clears the module and the USB), pilot for an M2.5 self-tapper
uln  = [32, 35, 15];  buck = [20, 45, 12]; // both turned to lie along y, between the motors
enc  = [31, 19, 1.6, 6.5, 11.5, 16, 6, 4.5, 9.5];   // pcb w, h, t; body, bushing top, shaft top above the pcb (the KY-040's 20 cut to 16: the knob's bore then reaches 1.2 short of its face); shaft dia, flat; shaft centre from the pcb's top edge
enc_nut = [10, 2.5];
oled = [27.3, 27.8, 1.6, 26.7, 19.3, 1.5, 21.7, 10.9];   // pcb w, h, t; glass w, h, t; active w, h
oled_glass_dz = -0.75;  oled_active_dz = 1.45;              // their centres, from the pcb's
jack_d = 11.5;  gx12_d = 12.2;  grommet_d = 16;
insert = [4, 5.5];  screw = [3.4, 6.7];    // M3 heat-set: hole dia, depth; M3 countersunk: clearance, head dia (+0.2)
bottle = [48, 122];   // measured 48 across; the height is still an estimate
rim = [4, 30];   // the garden reservoir's rim: thickness, drop

// ------------------------------------------------------------------- body
Bx      = 202;  By = 178;  wall = 3;
H       = 74;   R = 20;
lid_t   = 7;    lid_r = 4;                 // the lid: thick, its top edge rounded, flush with the walls
H_lid   = H + lid_t;
base_t  = 4;    base_ch = 1.5;             // the floor, below z = 0; a 45 chamfer under its edge: the one edge not rounded, so it prints from the bed
// The lid's snap: a rim rises from the walls' inner half with a ridge round its
// inside; the lid caps over it with a pocket underneath and a groove in the
// pocket's inner wall. Nothing hangs below the lid, so it prints flat.
// [rim thickness, rim height, clearance, ridge height, ridge proud, groove deep, ridge centre above the seam]  (cap: the reservoir's rim is rim)
cap     = [1.5, 4, 0.25, 1.4, 0.5, 0.7, 2];

// pumps: a row across the back, heads forward, each rolled 42 about its axis
pump_x  = [39, 101, 163];                  // pitch 62: a driver fits between two motors
pump_roll = 42;                            // as the first design: the nozzles lean left, the flange holes sit on a 42 line
head_y  = 99;                              // the head's front face
bulk_y  = head_y + pump_head[1] + pump_flange[2];   // 125: the bulkhead's front face, the flange against it
pump_z  = 28;                              // the axis
bulk_h  = 52;                              // the bulkhead's top: the tubes pass over it
motor_end = bulk_y + wall + pump_motor[1]; // 172
function rolled(dx, dz) = [dx*cos(pump_roll) + dz*sin(pump_roll), -dx*sin(pump_roll) + dz*cos(pump_roll)];   // (dx, dz) in the pump's section, rolled
function nozzle(s)   = rolled(s*nozzle_pitch/2, pump_head[0]/2 + nozzle_off);     // a nozzle's tip, (dx, dz) from the axis
function tube_start(s) = nozzle(s) + rolled(0, 5);                                  // where a tube's first bend can start: 5 beyond the tip, along the nozzle
function fhole(s)    = rolled(s*flange_pitch/2, 0);                                // a flange hole, (dx, dz) from the axis

// cups: two in the middle of the front; a Ø8 hole through the lid 16 mm out from each bottle for its tube, and a third at the rear, midway between them
cup_d = bottle[0] + 4;  cup_wall = 2;  hole_d = 8;   // the pocket: 2 mm round the bottle
cup_c = [[69, 62], [133, 62]];             // Nutrient A (right, fed by pump 0), Nutrient B (left, fed by pump 2)
hole_dx = [-(bottle[0]/2 + 16 + hole_d/2), bottle[0]/2 + 16 + hole_d/2];   // the hole's centre from the cup's: right cup's to the right, left cup's to the left

// boards. The DevKit stands on the faceplate's back behind the knob, its
// long side up, in two slotted rails; the driver and the buck stand in
// slotted ribs on the side walls beside the cups, dropped in from above.
wb      = [[3, 30, 35, 32], [Bx - 3, 30, 45, 20]];   // wall boards: [wall x, y0, length along y, height]: the ULN on the right wall, the buck on the left
wb_rib  = [7, 3.5, 1.8, 1.5, 4];           // rib depth off the wall, thickness (y), slot width, slot depth, pcb face off the wall
vents   = [[130, 40], [12, 5, 7], 2];      // in the side walls beside the motors: [y0, length], [z0, pitch, count], slot height

// feet: TPU, snapping into the base: disc dia, thickness, peg dia, lip dia, lip thickness
foot    = [18, 3, 7.8, 9.4, 1.4];
feet    = [[R, R], [Bx - R, R], [Bx - R, By - R], [R, By - R]];   // at the corners' radius centres

// ports: the back wall. The jack and the GX12 low, between the motors; the grommet above the middle one
ports  = [[(pump_x[0] + pump_x[1])/2, pump_z, jack_d], [pump_x[1], 58, grommet_d], [(pump_x[1] + pump_x[2])/2, pump_z, gx12_d], [pump_x[1], 8, hole_d]];   // x, z, dia: the jack, the grommet, the GX12, and the water tube's plain hole, low between the jack and the GX12 under the middle motor

// the faceplate: black, 3 thick, flush in an opening in the front wall, screwed
// into a band behind the wall. The screen and the knob mount on its back.
ctl_z  = 37;
pt     = 3;                                          // its thickness, the wall's
knob   = [36, 9.5, 38, 2, 1.5, 11, 4];               // dia, height, recess dia, recess depth, chamfer, nut pocket dia, depth
pr     = 8;                                          // the plate's corner radius; its screws sit at the radius centres
m_knob = 14;  m_scr = 14;  gap = 12;  m_v = 10.7;     // margins: beside the knob, beside the screen (the same), between them, above and below
pw_works = m_knob + knob[2] + gap + (oled[6] + 0.6) + m_scr;   // 96.3: the knob, the gap and the screen with their margins; they stay centred on the front
px_works = (Bx - pw_works)/2;
ph     = knob[2] + 2*m_v;
pz0    = ctl_z - ph/2;
deck_in = (pz0 + base_t + (H + lid_t - pz0 - ph))/2;   // 12.8: the mean of the faceplate's padding below (11.3) and above (14.3)
deck    = [[deck_in, deck_in], [Bx - 2*deck_in, By - 2*deck_in], 4, 2, pr, 1.5];   // a raised deck over the lid, inset like the faceplate: corner, size, height, edge radius, corner radius (the plate's), the cove at its foot
px0    = deck_in;  pw = Bx - 2*deck_in;              // the plate: as wide as the deck, the same 12.8 in from each side as above and below
pch    = 1;                                          // the round on its face edge, and on the opening's: the seam a soft groove
band   = [pr + 4, 6];                                // behind the wall around the opening: width inside the plate's outline (2 mm past the insert), depth
pscrews = [[px0 + pr, pz0 + pr], [px0 + pw - pr, pz0 + pr], [px0 + pw - pr, pz0 + ph - pr], [px0 + pr, pz0 + ph - pr]];
oled_rib = [3, 10, 1.2, 2.0];                        // thick (x), deep (y), slot depth, slot width: deep enough to carry the DevKit's cage
esp_c   = [pscrews[1][0] - insert[0]/2 - 4.2 - esp[1]/2, ctl_z];   // the DevKit's centre, lying along x left of the screen (as seen from the front): its left end 4.2 short of the left screws' inserts
esp_holes = [for (sx = [-1, 1], sz = [-1, 1]) [esp_c[0] + sx*(esp[1]/2 - esp_hole[1]), esp_c[1] + sz*(esp[0]/2 - esp_hole[1])]];
oled_x = Bx/2;                                                      // the screen, dead centre
knob_x = (oled_x + px0)/2;                                          // the knob, midway between the screen's centre and the plate's right edge
tds_c   = [oled_x, ctl_z];                 // the TDS board lying along x straight behind the screen, over its header
tds_holes = [for (sx = [-1, 1], sz = [-1, 1]) [tds_c[0] + sx*(tds[1]/2 - tds_hole[1]), tds_c[1] + sz*(tds[0]/2 - tds_hole[1])]];
tds_y   = pt + tds_so[1];
knob_y = knob[3] - 0.5;                              // the knob's base, 0.5 off the recess floor
enc_pcb_y = pt + enc[3];                             // the encoder's pcb, its body against the plate's back
bore_d = knob_y - (enc_pcb_y - enc[5]) + 0.3;        // to the shaft's end, 0.3 clear
assert(knob[1] - bore_d >= 1.2 - 0.01, "the knob's face is thinner than 1.2 over the bore");
oled_pcb_z = ctl_z - oled_active_dz;

esp_y   = pt + esp_so[1];                  // its pcb's plate-side face


// spout, on the reservoir's rim
spout = [40, 16, rim[1] + 4, 3.8, rim[0] + 0.4];   // w, d, h, outer leg, slot

// ------------------------------------------------------------------ rules
assert(pump_x[0] - pump_flange[0]/2 >= wall + 2 && pump_x[2] + pump_flange[0]/2 <= Bx - wall - 2, "the flanges run into the side walls");
assert(pump_x[1] - pump_x[0] >= pump_flange[0] + 3, "the flanges touch");
assert(motor_end + 2 <= By - wall, "the motors run into the back wall");
assert(pump_z + pump_head[0]/2 + nozzle_off + tube_od + 8 <= H, "no room over the nozzles for the tube to turn");
assert(pump_z - (pump_flange[0]/2*sin(pump_roll)) >= 2, "a rolled flange runs into the floor");
assert(pump_z + fhole(-1)[1] - 2 >= 2, "the lower flange screw runs into the floor");
assert(head_y >= cup_c[0][1] + cup_d/2 + cup_wall + 4, "the heads run into the cups");
assert(cup_c[0][1] - cup_d/2 - cup_wall >= band[1] + 4, "the cups run into the faceplate's band");
assert(cup_c[0][0] - cup_d/2 - cup_wall >= wb[0][0] + wb_rib[0] + 12 + 1, "the driver runs into the right cup");
assert(cup_c[1][0] + cup_d/2 + cup_wall <= wb[1][0] - wb_rib[0] - 12 - 1, "the buck runs into the left cup");
assert(wb[0][1] + wb[0][2] + wb_rib[1] + 2 <= bulk_y - pump_flange[0]/2*cos(pump_roll) - 2 && wb[1][1] + wb[1][2] + wb_rib[1] + 2 <= bulk_y, "a wall board runs into the pumps");
assert(cup_c[0][0] + hole_dx[0] - hole_d/2 >= wall + 3 && cup_c[1][0] + hole_dx[1] + hole_d/2 <= Bx - wall - 3, "a tube hole runs into the wall");
assert(cup_c[0][0] + hole_dx[0] - hole_d/2 - 3 >= deck[0][0] && cup_c[1][0] + hole_dx[1] + hole_d/2 + 3 <= deck[0][0] + deck[1][0], "a tube hole runs off the deck");
assert(ports[0][0] - ports[0][2]/2 - 2 >= pump_x[0] + pump_motor[0]/2 && ports[0][0] + ports[0][2]/2 + 2 <= pump_x[1] - pump_motor[0]/2, "the jack runs into a motor");
assert(ports[2][0] - ports[2][2]/2 - 2 >= pump_x[1] + pump_motor[0]/2 && ports[2][0] + ports[2][2]/2 + 2 <= pump_x[2] - pump_motor[0]/2, "the GX12 runs into a motor");
assert(ports[1][1] - ports[1][2]/2 >= pump_z + pump_motor[0]/2 + 6, "the grommet runs into the motor");
assert(vents[0][0] >= bulk_y + wall + 2 && vents[0][0] + vents[0][1] <= By - wall - 2 && vents[1][0] >= 4 && vents[1][0] + vents[1][1]*(vents[1][2] - 1) + vents[2] <= H - cap[1] - 6, "the vents run off the motor section");
assert(bottle[1] - H_lid - deck[2] >= 30, "the bottle must show 30 mm above the deck");
assert(pz0 >= 4 && pz0 + ph + 0.8 <= H - 0.5, "the faceplate's band runs into the lid seam");
assert(esp_c[0] - esp[1]/2 - 1 >= oled_x + oled[0]/2 + 0.2 + oled_rib[0] - 0.01 && esp_c[0] + esp[1]/2 + 1 + 3 <= pscrews[1][0] - insert[0]/2, "the DevKit runs into the screen's rib or the left screws' inserts");
assert(esp_c[1] - esp[0]/2 >= pz0 + 2 && esp_c[1] + esp[0]/2 <= pz0 + ph - 2 && knob_x - knob[2]/2 >= px0 + band[0] + 2, "the DevKit or the knob runs off the plate");
assert(esp_y + esp[2] + esp[3] + 2 <= cup_c[1][1] - cup_d/2 - cup_wall, "the DevKit's pins run into the cups");
assert(tds_c[1] - tds[0]/2 >= pz0 && tds_c[1] + tds[0]/2 <= pz0 + ph && tds_c[0] + tds[1]/2 + 1 <= esp_c[0] - esp[1]/2, "the TDS board runs off the plate or into the DevKit");

assert(oled_x + oled[0]/2 + 0.2 + oled_rib[0] <= px0 + pw - 2 && knob_x - knob[2]/2 >= px0 + band[0] + 2, "the plate's works run off the plate or under the band by the knob");
assert(oled_pcb_z - oled[1]/2 - 2.1 - 1 >= pscrews[0][1] + insert[0]/2 + 1 && oled_pcb_z - oled[1]/2 - 2.1 + oled[1] + 4.6 + 1 <= pscrews[3][1] - insert[0]/2 - 1, "the band's notch for the screen runs into a screw");
assert(Bx <= 256 && By <= 256, "bigger than the bed");

// ---------------------------------------------------------------- helpers
module rr(w, h, rad) offset(rad) offset(-rad) square([w, h]);
module rrc(w, h, rad) translate([-w/2, -h/2]) rr(w, h, rad);
module at(p, z = 0) translate([p[0], p[1], z]) children();
module rounded_top(h, rad, steps = 6) hull() { linear_extrude(h - rad) children(); for (i = [1:steps]) let (a = 90*i/steps) translate([0, 0, h - rad + rad*sin(a) - 0.01]) linear_extrude(0.01) offset(-rad*(1 - cos(a))) children(); }
module plate2d(extra = 0) translate([px0, pz0]) offset(extra) rr(pw, ph, pr);                    // the faceplate's outline, in the (x, z) plane
module on_front() rotate([90, 0, 0]) mirror([0, 0, 1]) children();                                // (x, z) plane at y = 0, extruding into +y
module wedge_x(x0, w, pts) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(w) polygon(pts);   // a prism along x from a (y, z) polygon
module stadium(l, h) hull() for (s = [-1, 1]) translate([s*(l - h)/2, 0]) circle(d = h);   // a slot's outline, l long, h high
module csk(d, head, h) { translate([0, 0, -1]) cylinder(d = d, h = h + 2); translate([0, 0, -0.01]) cylinder(d1 = head, d2 = 0, h = head/2); }   // a countersunk hole, head at z = 0, going +z
// rounds: an edge round on a cut (a staircase of growing slices, from z = 0 up
// into the material), and a cove (a concave fillet) at the foot of a raised shape
function roff(r, t) = r - sqrt(r*r - (r - t)*(r - t));                                            // a quarter circle's inset at depth t into an edge round of radius r
module round_cut(r, steps = 8) for (i = [0:steps - 1]) let (t = r*i/steps) translate([0, 0, -0.01 + t]) linear_extrude(r/steps + 0.02) offset(roff(r, t)) children();   // widens a hole's mouth: children are the hole
module cove(r, steps = 8) for (i = [0:steps - 1]) let (t = r*i/steps) translate([0, 0, t - 0.01]) linear_extrude(r/steps + 0.02) offset(roff(r, t)) children();          // a fillet ring at the foot of children's outline
module cav2d(o = 0) translate([wall, wall]) offset(o) rr(Bx - 2*wall, By - 2*wall, R - wall);                         // the walls' inside, offset o
module rim_ring(o = 0) difference() { cav2d(cap[0]); cav2d(o); }                                                          // the rim's section, its inside pushed in by -o
module lid_rim(steps = 6) translate([0, 0, H]) {   // on the body: the rim and its inward ridge
  linear_extrude(cap[1]) rim_ring();
  for (i = [0:steps - 1]) let (z = cap[6] - cap[3]/2 + cap[3]*i/steps, o = -cap[4]*(1 - abs(2*(i + 0.5)/steps - 1))) translate([0, 0, z]) linear_extrude(cap[3]/steps + 0.01) rim_ring(o);
}
module lid_pocket() {   // in the lid, from its underside (z = 0 local): the ring the rim goes into, and the groove the ridge clicks into
  translate([0, 0, -1]) linear_extrude(cap[1] + 0.2 + 1) difference() { cav2d(cap[0] + cap[2]); cav2d(-cap[2]); }
  translate([0, 0, cap[6] - cap[3]/2]) linear_extrude(cap[3]) difference() { cav2d(-cap[2] + 0.01); cav2d(-cap[2] - cap[5]); }
}

// ------------------------------------------------------------------- body
module body() color("#5a7a48") difference() {
  union() {
    difference() { linear_extrude(H) rr(Bx, By, R); translate([0, 0, -1]) linear_extrude(H + 2) cav2d(); }                         // the walls
    translate([0, 0, -base_t]) hull() { linear_extrude(0.01) offset(-base_ch) rr(Bx, By, R); translate([0, 0, base_ch]) linear_extrude(base_t - base_ch) rr(Bx, By, R); }   // the floor, chamfered under its edge, meeting the walls at z = 0
    translate([wall - 0.01, bulk_y, 0]) cube([Bx - 2*wall + 0.02, wall, bulk_h]);                                                    // the bulkhead
    for (c = cup_c) at(c, 0) cylinder(d = cup_d + 2*cup_wall, h = H);                                                                // the cups, open tubes
    on_front() translate([0, 0, wall - 0.01]) linear_extrude(band[1] + 0.01) difference() { plate2d(0.3 + 0.5); plate2d(-band[0]); }   // the band behind the wall the plate screws into
    lid_rim();                                                                                                                       // the rim the lid caps over
    for (b = wb) let (x0 = b[0] < Bx/2 ? b[0] - 0.01 : b[0] - wb_rib[0] + 0.01)                                                   // slotted ribs on the side walls, above the base's lip: the driver right, the buck left
      for (y = [b[1] - wb_rib[1], b[1] + b[2]]) translate([x0, y, -0.01]) cube([wb_rib[0], wb_rib[1], b[3] + 4]);
  }
  for (b = wb) let (sx = b[0] < Bx/2 ? 1 : -1, xs = b[0] + sx*wb_rib[4] - (sx > 0 ? 0 : wb_rib[2]))                                 // the slots the boards drop into
    for (y = [b[1] - wb_rib[3], b[1] + b[2] - 0.01]) translate([xs, y, 1]) cube([wb_rib[2], wb_rib[3] + 0.01, b[3] + 10]);
  for (sx = [0, 1], i = [0:vents[1][2] - 1]) translate([sx ? Bx - wall - 1 : -1, vents[0][0] + vents[0][1]/2, vents[1][0] + i*vents[1][1] + vents[2]/2]) rotate([90, 0, 90]) linear_extrude(wall + 2) stadium(vents[0][1], vents[2]);   // vents beside the motors
  for (f = feet) at(f, -base_t - 1) { cylinder(d = foot[2] + 0.4, h = base_t + 2); cylinder(d = foot[0] + 0.4, h = 2); translate([0, 0, base_t + 1 - foot[4] - 0.1]) cylinder(d = foot[3] + 0.6, h = foot[4] + 0.2); }   // a foot: its peg's hole, a pocket for the disc below, a counterbore for the lip above
  for (x = pump_x) translate([x, bulk_y - 1, pump_z]) rotate([-90, 0, 0]) {
    cylinder(d = pump_motor[0] + 2, h = wall + 2);                                                                                  // the motor's U-slot ...
    translate([-(pump_motor[0] + 2)/2, -H, 0]) cube([pump_motor[0] + 2, H, wall + 2]);                                              // ... open at the top
    for (s = [-1, 1]) translate([fhole(s)[0], -fhole(s)[1], 0]) cylinder(d = 3.4, h = wall + 2);                                     // the flange screws' holes, on the 42 line; screws from the motor side, threading into the flange
  }
  for (c = cup_c) at(c, 0) cylinder(d = cup_d, h = H + 2);                                                                           // the pockets, down to the floor
  for (p = ports) translate([p[0], By + 1, p[1]]) rotate([90, 0, 0]) cylinder(d = p[2], h = wall + 2);                              // the ports
  on_front() {
    translate([0, 0, -1]) linear_extrude(wall + 1) plate2d(0.3);                                                                     // the opening the plate sits in, through the wall only: the band behind bears the plate
    round_cut(pch) plate2d(0.3);                                                                                                     // its edge rounded
    translate([0, 0, -1]) linear_extrude(wall + band[1] + 2) plate2d(-band[0] + 0.05);                                               // through the band: the plate's works pass
    hull() { translate([esp_c[0] - esp[1]/2 - 1, esp_c[1] - esp[0]/2 - 1, wall - 0.01]) cube([esp[1] + 2, esp[0] + 2, 0.01]); translate([esp_c[0] - esp[1]/2 - 1, esp_c[1] - esp[0]/2 - 1, wall + band[1] + 1]) cube([esp[1] + 2, esp[0] + 2 + band[1] + 1, 0.01]); }   // the band notched under the DevKit, its ceiling rising 45 into the box so it prints; the inserts' bosses untouched

    for (s = pscrews) translate([s[0], s[1], wall - 0.01]) cylinder(d = insert[0], h = insert[1] + 0.01);                            // inserts in the band
  }
  wedge_x(px0 - 2, pw + 4, [[wall, pz0 - 0.8], [wall + 12, pz0 - 0.8 + 12], [wall + 12, 0.01], [wall, 0.01]]);                   // the band's underside slopes 45 down to the wall, stopping at the floor
  let (zt = pz0 + ph - band[0] + 0.05) wedge_x(px0 + band[0] - 0.5, pw - 2*band[0] + 1, [[wall - 0.1, zt - 0.1], [wall + 12, zt + 11.9], [wall + 12, zt - 0.1]]);   // the opening's ceiling slopes 45 up from the wall
}

// ------------------------------------------------------------------- feet
module foot_local() color("#333") { cylinder(d = foot[0], h = foot[1]); translate([0, 0, foot[1] - 0.01]) cylinder(d = foot[2], h = base_t - 1 - foot[4] + 0.02 + foot[4]); translate([0, 0, foot[1] + base_t - 1 - foot[4]]) cylinder(d = foot[3], h = foot[4]); }   // disc, peg, lip
module foot_at(i) at(feet[i], -base_t - foot[1] + 1) foot_local();

// -------------------------------------------------------------------- lid
// Two colours: the deck black (everything above the lid's top face inside
// the deck's footprint and its cove), the rest olive.
module deck_region() translate([deck[0][0], deck[0][1], H + lid_t - 0.005]) linear_extrude(deck[2] + 2) offset(deck[5] + 0.2) rr(deck[1][0], deck[1][1], deck[4]);   // 0.005 under the top face: a cut on the face itself leaves the mesh non-manifold
module lid_main() color("#5a7a48") difference() { lid(); deck_region(); }
module lid_deck() color("#1c1c1c") intersection() { lid(); deck_region(); }
module lid() translate([0, 0, H]) difference() {
  union() {
    rounded_top(lid_t, lid_r) rr(Bx, By, R);                                                                                          // flush with the walls, its top edge rounded
    translate([deck[0][0], deck[0][1], lid_t - 0.01]) rounded_top(deck[2] + 0.01, deck[3]) rr(deck[1][0], deck[1][1], deck[4]);       // the bottle deck ...
    translate([deck[0][0], deck[0][1], lid_t - 0.01]) cove(deck[5]) rr(deck[1][0], deck[1][1], deck[4]);                              // ... a cove at its foot
  }
  lid_pocket();                                                                                                                       // over the body's rim
  for (c = cup_c) at(c, -1) { cylinder(d = cup_d + 0.4, h = lid_t + deck[2] + 2); translate([0, 0, lid_t + deck[2] + 1]) mirror([0, 0, 1]) round_cut(1) circle(d = cup_d + 0.4); }   // the bottles' holes, their mouths rounded
  for (h = [cup_c[0] + [hole_dx[0], 0], cup_c[1] + [hole_dx[1], 0]]) at(h, -1) { cylinder(d = hole_d, h = lid_t + deck[2] + 2); translate([0, 0, lid_t + deck[2] + 1]) mirror([0, 0, 1]) round_cut(1) circle(d = hole_d); }   // the tubes' holes: 16 out from each bottle, through the deck
}

// -------------------------------------------------------------- faceplate
module plate() color("#1c1c1c") difference() {
  union() {
    on_front() translate([0, 0, pt]) mirror([0, 0, 1]) rounded_top(pt, pch) plate2d(0);                                             // the plate, its face edge rounded
    for (s = [-1, 1]) translate([knob_x + s*(enc[0]/2 + 0.3) - (s < 0 ? 2 : 0), pt - 0.01, ctl_z - 17]) cube([2, 9, 30]);         // ribs either side of the encoder's pcb, inside the band's opening
    for (s = [-1, 1]) translate([oled_x + s*(oled[0]/2 + 0.2) - (s < 0 ? oled_rib[0] : 0), pt - 0.01, oled_pcb_z - oled[1]/2 - 2.1]) cube([oled_rib[0], oled_rib[1], oled[1] + 4.6]);   // the screen's ribs
    translate([oled_x - oled[0]/2, pt - 0.01, oled_pcb_z - oled[1]/2 - 2]) cube([oled[0], oled_rib[3], 2]);                          // the ledge it sits on
    for (h = esp_holes) translate([h[0], pt - 0.01, h[1]]) rotate([-90, 0, 0]) cylinder(d = esp_so[0], h = esp_so[1] + 0.01);   // the DevKit's four standoffs
    for (h = tds_holes) translate([h[0], pt - 0.01, h[1]]) rotate([-90, 0, 0]) cylinder(d = tds_so[0], h = tds_so[1] + 0.01);   // the TDS board's four, taller
  }
  for (h = esp_holes) translate([h[0], pt + 1, h[1]]) rotate([-90, 0, 0]) cylinder(d = esp_so[2], h = esp_so[1] + 1);
  for (h = tds_holes) translate([h[0], pt + 1, h[1]]) rotate([-90, 0, 0]) cylinder(d = tds_so[2], h = tds_so[1] + 1);             // their pilots             // their pilots, blind: 1 of plate under them
  for (s = pscrews) translate([s[0], 0, s[1]]) rotate([-90, 0, 0]) csk(screw[0], screw[1], pt);                                     // its screws, countersunk in the face, at the corners' radius centres
  translate([knob_x, -1, ctl_z]) rotate([-90, 0, 0]) { cylinder(d = 7.5, h = pt + 2); cylinder(d = knob[2], h = knob[3] + 1); translate([0, 0, 1]) round_cut(0.8) circle(d = knob[2]); }   // the bushing hole, the knob's recess, its mouth rounded
  translate([oled_x, -1, ctl_z]) rotate([-90, 0, 0]) { linear_extrude(pt + 2) rrc(oled[6] + 0.6, oled[7] + 0.6, 2); translate([0, 0, 1]) round_cut(0.5) rrc(oled[6] + 0.6, oled[7] + 0.6, 2); }   // the window, the picture's size, its mouth rounded
  translate([oled_x - oled[3]/2 - 0.2, pt - oled[5] - 0.2, oled_pcb_z + oled_glass_dz - oled[4]/2 - 0.2]) cube([oled[3] + 0.4, oled[5] + 1, H]);   // a channel for the glass, open at the plate's top edge: the module slides down it
  for (s = [-1, 1]) translate([oled_x + s*(oled[0]/2 + 0.2) - (s < 0 ? oled_rib[2] : 0), pt - 0.01, oled_pcb_z - oled[1]/2 - 7]) cube([oled_rib[2], oled_rib[3], H]);   // the slots the pcb slides down
}

// ------------------------------------------------------------------- knob
module knurled(d, h, n = 60, twist = 30) intersection_for (s = [-1, 1]) linear_extrude(h, twist = s*twist, slices = 24) offset(s < 0 ? 0.05 : 0.1) difference() { circle(d = d); for (a = [0:360/n:359]) rotate(a) translate([d/2, 0]) rotate(45) square(1.2, center = true); }   // the two sets differ by 0.05 so the mesh stays manifold
module knob_local() color("#a8451a") difference() {   // burnt orange          // z up its axis, base at 0
  union() { knurled(knob[0], knob[1] - knob[4]); translate([0, 0, knob[1] - knob[4] - 2 - 0.01]) rounded_top(knob[4] + 2, knob[4]) circle(d = knob[0] - 1.2); }   // knurled, its front edge rounded
  translate([0, 0, -1]) cylinder(d = knob[5], h = knob[6] + 1);                                                         // the nut's pocket
  translate([0, 0, -1]) linear_extrude(bore_d + 1) difference() { circle(d = enc[6] + 0.1); translate([-5, enc[7] - enc[6]/2 + 0.05]) square([10, 5]); }   // the D bore, stopping on the shaft's end
}
// Two colours: the knurled ring brown-red, the cap (the face and its
// rounded edge, everything above the knurl) black.
module cap_region() translate([0, 0, knob[1] - knob[4] + 0.01]) cylinder(d = knob[0] + 2, h = knob[4] + 1);   // 0.01 above the knurl's top, off its face
module knob_ring() color("#7a2e1e") difference() { knob_local(); cap_region(); }
module knob_cap() color("#1c1c1c") intersection() { knob_local(); cap_region(); }
module knob_at() translate([knob_x, knob_y, ctl_z]) rotate([90, 0, 0]) knob_local();
module knob_ring_at() translate([knob_x, knob_y, ctl_z]) rotate([90, 0, 0]) knob_ring();
module knob_cap_at() translate([knob_x, knob_y, ctl_z]) rotate([90, 0, 0]) knob_cap();

// --------------------------------------------------------- fuzz modifier
// Not a print: a slicer modifier. A shell hugging the body's outer vertical
// faces, 4 above the bottom up to the lid seam, 3 mm off the
// faceplate's opening. Load it in Bambu Studio or OrcaSlicer as a modifier
// on the body and set Fuzzy Skin = Contour on it: the texture lands on the
// outer walls inside the shell and nowhere else, so the snap fits, the
// opening and the cavity stay smooth.
fuzz = [4, 1.5, 3];   // smooth margin at the bottom (the chamfer's height), depth into the wall, margin round the opening; the band runs up to the lid seam, so it clears the plate equally above and below
module fuzz_mod() difference() {
  translate([0, 0, -base_t + fuzz[0]]) linear_extrude(H + base_t - fuzz[0]) difference() { offset(1) rr(Bx, By, R); offset(-fuzz[1]) rr(Bx, By, R); }
  on_front() translate([0, 0, -2]) linear_extrude(12) plate2d(0.3 + fuzz[2]);   // deep enough to clear it where the plate reaches into the corners' curve
}

// ------------------------------------------------------------------ spout
module spout() difference() {
  cube([spout[0], spout[1], spout[2]]);
  translate([-1, spout[3], 4]) cube([spout[0] + 2, spout[4], spout[2]]);                                              // the rim's slot
  for (i = [0:2]) translate([7 + 10*i, spout[3] + spout[4] + (spout[1] - spout[3] - spout[4])/2, -1]) cylinder(d = tube_od + 0.4, h = spout[2] + 2);   // three tubes down the inner leg
  translate([spout[0] - 5, spout[3] + spout[4] + (spout[1] - spout[3] - spout[4])/2, -1]) cylinder(d = 4, h = spout[2] + 2);   // the float's lead
}

// ----------------------------------------------------------- bought parts
module pump(k) color("#d8d8d8") translate([pump_x[k], head_y, pump_z]) rotate([0, pump_roll, 0]) {
  rotate([-90, 0, 0]) { cylinder(d = pump_head[0], h = pump_head[1]); translate([0, 0, pump_head[1]]) linear_extrude(pump_flange[2]) difference() { polygon([[-pump_flange[0]/2, 0], [0, pump_flange[1]/2], [pump_flange[0]/2, 0], [0, -pump_flange[1]/2]]); for (s = [-1, 1]) translate([s*flange_pitch/2, 0]) circle(d = flange_hole); } translate([0, 0, pump_head[1] + pump_flange[2]]) cylinder(d = pump_motor[0], h = pump_motor[1]); }   // head, the diamond flange, motor
  for (s = [-1, 1]) translate([s*nozzle_pitch/2, nozzle_y, pump_head[0]/2 - 2]) cylinder(d = 4, h = nozzle_off + 2);   // nozzles, up
}
module pumps() for (k = [0:2]) pump(k);
module board(i) color(i == 0 ? "#101418" : i == 1 ? "#1e6b35" : i == 3 ? "#1d4fa0" : "#111") {
  if (i == 3) translate([tds_c[0], tds_y, tds_c[1]]) difference() { union() {
    translate([-tds[1]/2, 0, -tds[0]/2]) cube([tds[1], tds[2], tds[0]]);                                                              // the pcb, lying along x
    translate([-tds[1]/2 + 6, tds[2], -tds[0]/2 + 7]) cube([tds[1] - 12, tds[3], tds[0] - 14]);                                        // its parts and connectors, back into the box
  }
  for (h = tds_holes) translate([h[0] - tds_c[0], -4, h[1] - tds_c[1]]) rotate([-90, 0, 0]) cylinder(d = tds_hole[0], h = 10); }
  if (i == 0) translate([esp_c[0], esp_y, esp_c[1]]) difference() { union() {
    translate([-esp[1]/2, 0, -esp[0]/2]) cube([esp[1], esp[2], esp[0]]);                                                              // the pcb, lying along x
    color("#bbb") translate([esp[1]/2 - 25.5, -3.1, -9]) cube([25.5, 3.1, 18]);                                                        // the module, toward the plate, at the left end
    color("#999") translate([-esp[1]/2 - 0.5, -3, -4]) cube([6, 3, 8]);                                                             // the USB, at the right end by the screen
    for (sz = [-1, 1]) translate([-esp[1]/2 + 4.5, esp[2], sz*(esp[0]/2 - 1.3) - 1.25]) cube([esp[1] - 9, esp[3], 2.5]);              // the pin rows, back into the box
  }
  for (h = esp_holes) translate([h[0] - esp_c[0], -4, h[1] - esp_c[1]]) rotate([-90, 0, 0]) cylinder(d = esp_hole[0], h = 10); }
  if (i == 1) let (b = wb[0]) translate([b[0] + wb_rib[4], b[1] - wb_rib[3], 1.2]) { cube([1.6, b[2] + 2*wb_rib[3], b[3]]); translate([1.6, wb_rib[3] + 3, 3]) cube([12, b[2] - 6, b[3] - 6]); }   // in its slots on the right wall, components inward
  if (i == 2) let (b = wb[1]) translate([b[0] - wb_rib[4] - 1.6, b[1] - wb_rib[3], 1.2]) { cube([1.6, b[2] + 2*wb_rib[3], b[3]]); translate([-10, wb_rib[3] + 3, 3]) cube([10, b[2] - 6, b[3] - 6]); }   // in its slots on the left wall
}
module electronics() for (i = [0:3]) board(i);
module port_hw() for (i = [0:2]) let (p = ports[i]) translate([p[0], By, p[1]]) color(i == 1 ? "#222" : "#888") {
  translate([0, 1, 0]) rotate([-90, 0, 0]) cylinder(d = p[2] + 4, h = 2);
  translate([0, -wall - 14, 0]) rotate([-90, 0, 0]) cylinder(d = p[2] - 0.3, h = wall + 14);
  if (i == 1) color("#1a1a1a") translate([0, 3, 0]) rotate([-90, 0, 0]) cylinder(d = 12, h = 45);
}
module enc_at() color("#3a7a3a") translate([knob_x, enc_pcb_y, ctl_z]) {
  translate([-enc[0]/2, 0, enc[8] - enc[1]]) cube([enc[0], enc[2], enc[1]]);                                         // the pcb
  rotate([90, 0, 0]) { translate([-6, -6, 0]) cube([12, 12, enc[3]]); cylinder(d = 7, h = enc[4]); color("#bbb") linear_extrude(enc[5]) difference() { circle(d = enc[6]); translate([-5, enc[7] - enc[6]/2]) square([10, 5]); } }   // body, bushing, D shaft
  color("#999") translate([0, knob[3] - enc_pcb_y, 0]) rotate([90, 0, 0]) cylinder(d = enc_nut[0], h = enc_nut[1], $fn = 6);   // the nut, on the recess floor
  color("#222") translate([-6.35, enc[2]/2 - 1.27, enc[8] - enc[1] - 22]) cube([12.7, 2.54, 22]);                                 // its five pins and the Dupont housings on them, pointing down
}
module oled_at() translate([oled_x, pt, oled_pcb_z]) {
  color("#1f3a5f") translate([-oled[0]/2, 0, -oled[1]/2]) cube([oled[0], oled[2], oled[1]]);                            // the pcb, against the plate's back
  color("#111") translate([-oled[3]/2, -oled[5], oled_glass_dz - oled[4]/2]) cube([oled[3], oled[5], oled[4]]);           // the glass, into the plate
  color("#888") translate([-5, oled[2], oled[1]/2 - 3]) cube([10, 8, 2]);                                                // the header, pointing in
  color("#222") translate([-5.2, oled[2] + 8 - 6, oled[1]/2 - 3 - 0.27]) cube([10.4, 20, 2.54]);                          // its Dupont plugs, 14 past the pins
}
// The Rise Gardens 125 mL bottle (Sprout in the right cup, Thrive in the
// left): a white HDPE cylinder round, its shoulder rounded into a 24 mm
// neck, a black disc-top cap, a wraparound label. Three pieces so they can
// be coloured apart: body, cap, label.
module bottle_body() rotate_extrude($fn = 96) polygon([[0, 0], [21, 0], [23.4, 1], [24, 3], [24, 90], [23.6, 93.5], [22.4, 96.6], [20.5, 99.3], [18, 101.5], [15.2, 103.1], [12.5, 104], [12, 104.5], [12, 110], [0, 110]]);
module bottle_cap()  rotate_extrude($fn = 96) polygon([[0, 108], [13.5, 108], [13.5, 119.5], [12.8, 121.2], [11.5, 122], [0, 122]]);
module bottle_label() rotate_extrude($fn = 96) polygon([[24, 14], [24.3, 14], [24.3, 80], [24, 80]]);
module bottle_at(i) at(cup_c[i], 0) { color([0.93, 0.93, 0.9, 0.8]) bottle_body(); color("#111") bottle_cap(); color(i == 0 ? "#4a9a4a" : "#3a86b0") bottle_label(); }
module bottle_cap_at(i) at(cup_c[i], 0) bottle_cap();
module bottle_label_at(i) at(cup_c[i], 0) bottle_label();
module bottle_body_at(i) at(cup_c[i], 0) bottle_body();
module bottles() for (i = [0, 1]) bottle_at(i);
module m3csk(l) { cylinder(d = 3, h = l - (screw[1] - 3)/2); translate([0, 0, l - (screw[1] - 3)/2]) cylinder(d1 = 3, d2 = screw[1] - 0.2, h = (screw[1] - 3)/2); }   // M3 countersunk, its head's top at z = l
module screws() color("#999") for (s = pscrews) translate([s[0], 0, s[1]]) rotate([90, 0, 0]) translate([0, 0, -8]) m3csk(8);   // the plate's M3 x 8: the only screws
module feet_shown() for (i = [0:3]) foot_at(i);

// --------------------------------------------------------------- assembly
module printed() { body(); lid_main(); lid_deck(); plate(); knob_ring_at(); knob_cap_at(); }
module unit() { printed(); pumps(); electronics(); port_hw(); enc_at(); oled_at(); bottles(); screws(); feet_shown(); }

if      (part == "all")      unit();
else if (part == "none")     ;
else if (part == "body")     translate([0, 0, base_t]) body();                             // floor down
else if (part == "body_at")  body();
else if (part == "lid")      translate([0, 0, -H]) lid_main();                             // underside down: the deck on top; olive
else if (part == "lid_deck") translate([0, 0, -H]) lid_deck();                             // the same place; black
else if (part == "deck")     lid_deck();
else if (part == "plate")    rotate([90, 0, 0]) translate([-px0, 0, -(pz0 + ph)]) plate();  // face down
else if (part == "knob")     knob_ring();                                                  // base down; burnt orange
else if (part == "knob_cap") knob_cap();                                                   // the same place; black
else if (part == "foot")     foot_local();                                                 // disc down (TPU)
else if (part == "spout")    spout();                                                      // top down, legs up
else if (part == "fuzz")     fuzz_mod();                                                   // a slicer modifier, not a print
else if (part == "lid_at")   lid_main();
else if (part == "plate_at") plate();
else if (part == "knob_at")  knob_ring_at();
else if (part == "cap")      knob_cap_at();
else if (part == "feet")     feet_shown();
else if (part == "screws")   screws();
else if (part == "pump")     pump(idx);
else if (part == "board")    board(idx);
else if (part == "encoder")  enc_at();
else if (part == "oled")     oled_at();
else if (part == "ports")    port_hw();
else if (part == "bottle")   bottle_body_at(idx);
else if (part == "cap_b")    bottle_cap_at(idx);
else if (part == "label")    bottle_label_at(idx);
