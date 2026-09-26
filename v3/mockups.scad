// Hydro Doser v3, massing mockups. Three layouts to choose between, drawn
// as blocks to the brief (BRIEF.md). No detailing: no fillets, fasteners,
// knurl or tube runs. Frame: x right(0) -> left, y front(0) -> back, z up
// from the tank's rim, which the box sits on.
//
//   opt 1  "Low":     pumps lying along the right side, box 74 tall,
//                     the bottles stand 50 above the lid.
//   opt 2  "Tall":    the same plan, box 110 tall, only the caps show.
//   opt 3  "Upright": pumps standing on the right, heads up, box 88 tall.

opt  = 1;
part = "all";     // all | shell | lid | panel | knob | pumps | boards | bottles | bin
$fn  = 48;

// ------------------------------------------------------------ the brief
bin_top = 213; bin_bot = 195; bin_h = 184; bin_r = 14; rim_t = 2;
pump_head = [38, 23]; pump_flange = [55, 41, 3]; pump_motor = [27, 44];
nozzle_off = 10; nozzle_pitch = 16; tube_od = 5;
esp = [55, 28, 12.5]; uln = [35, 32, 15]; buck = [45, 20, 12];
oled_win = [21.7, 10.9]; knob_d = 36; knob_h = 13; knob_sink = 2;
jack_d = 11.5; gx12_d = 12.2; grommet_d = 16;
bottle = [54, 122];

// ------------------------------------------------------------ the box
B = 219; wall = 3; floor_t = 4; lid_t = 5; R = 6;
H = opt == 1 ? 74 : opt == 2 ? 110 : 88;     // the walls
lip = [bin_top - 2*rim_t - 1, 8];           // a locator under the floor, inside the rim
ctl_z = opt == 2 ? 55 : H/2;                 // the controls' line on the front
upright = opt == 3;

// pumps: a row along the right side, behind the controls' zone
pump_y   = upright ? [60, 118, 176] : [60, 120, 180];   // upright: the flange is 55 long, so the pitch is 58
head_x   = wall + 4;                                   // lying: the head's face off the panel
bulk_x   = head_x + pump_head[1];                      // lying: the bulkhead the flanges sit on
pump_z   = 30;                                         // lying: the axis
shelf_z  = floor_t + pump_motor[1];                    // upright: the shelf the flanges sit on
pump_x   = wall + pump_head[0]/2 + 2;                  // upright: the row's x
panel_y  = [35, 205];                  // the side panel's span

// cups: two, along the left wall, behind the screen's zone
cup_d = 58; cup_wall = 2; cup_floor = 3;
cup_c = [[B - wall - cup_d/2 - cup_wall, B - wall - cup_d/2 - cup_wall], [B - wall - cup_d/2 - cup_wall, B - wall - cup_d/2 - cup_wall - 66]];

// boards: a strip between the pumps and the cups
strip_x = upright ? 60 : 88;
boards = [[[strip_x, 60, floor_t + 6], [esp[1], esp[0], esp[2]]], [[strip_x, 125, floor_t + 6], uln], [[strip_x, 168, floor_t + 6], buck]];

// ports: the back wall, over the boards
ports = [[105, jack_d], [127, gx12_d], [148, grommet_d]];
port_z = min(ctl_z, 40);

// controls: the front face, screen left, knob right
knob_x = 55; oled_x = B - 55;

// ------------------------------------------------------------ helpers
module rr(w, h, r) offset(r) offset(-r) square([w, h]);
module rrc(w, h, r) translate([-w/2, -h/2]) rr(w, h, r);

// ------------------------------------------------------------ pieces
module shell() color("#5a7a48") difference() {
  union() {
    difference() {
      linear_extrude(H) rr(B, B, R);
      translate([wall, wall, floor_t]) linear_extrude(H) rr(B - 2*wall, B - 2*wall, R - wall);
    }
    translate([(B - lip[0])/2, (B - lip[0])/2, -lip[1]]) difference() { linear_extrude(lip[1] + 0.01) rr(lip[0], lip[0], R); translate([2, 2, -1]) linear_extrude(lip[1] + 3) rr(lip[0] - 4, lip[0] - 4, R - 2); }
    if (!upright) translate([bulk_x, wall, floor_t - 0.01]) cube([wall, B - 2*wall, H - floor_t]);                 // the bulkhead
    if (upright) translate([wall, panel_y[0], shelf_z]) cube([pump_flange[1] + 4, panel_y[1] - panel_y[0], pump_flange[2]]);   // the shelf
    for (c = cup_c) translate([c[0], c[1], floor_t - 0.01]) cylinder(d = cup_d + 2*cup_wall, h = H - floor_t);   // the cups
    for (b = boards) translate(b[0] - [0, 0, 6]) cube([b[1][0], b[1][1], 6]);                                       // standoff blocks
  }
  translate([-1, panel_y[0], 8]) cube([wall + 2, panel_y[1] - panel_y[0], H - 12]);                                 // the side panel's opening
  for (c = cup_c) translate([c[0], c[1], floor_t + cup_floor]) cylinder(d = cup_d, h = H);                          // the pockets
  if (!upright) for (y = pump_y) translate([bulk_x - 1, y, pump_z]) rotate([0, 90, 0]) { cylinder(d = pump_motor[0] + 2, h = wall + 2); translate([-H, -(pump_motor[0] + 2)/2, 0]) cube([H, pump_motor[0] + 2, wall + 2]); }   // U-slots
  if (upright) for (y = pump_y) translate([pump_x, y, shelf_z - 1]) cylinder(d = pump_motor[0] + 2, h = pump_flange[2] + 2);
  for (p = ports) translate([p[0], B + 1, port_z]) rotate([90, 0, 0]) cylinder(d = p[1], h = wall + 2);            // the ports, back
  translate([oled_x, -1, ctl_z]) rotate([-90, 0, 0]) linear_extrude(wall + 2) rrc(oled_win[0] + 0.6, oled_win[1] + 0.6, 2);   // the window
  translate([knob_x, -1, ctl_z]) rotate([-90, 0, 0]) { cylinder(d = 7.5, h = wall + 2); cylinder(d = knob_d + 2, h = knob_sink + 1); }   // the bushing, the recess
}
module lid() color("#5a7a48") translate([0, 0, H]) difference() {
  linear_extrude(lid_t) rr(B, B, R);
  for (c = cup_c) translate([c[0], c[1], -1]) cylinder(d = cup_d + 0.4, h = lid_t + 2);
}
module panel() color("#3f5a33") translate([0, panel_y[0] + 0.3, 8.3]) cube([wall, panel_y[1] - panel_y[0] - 0.6, H - 12.6]);
module knob() color("#222") translate([knob_x, knob_sink, ctl_z]) rotate([90, 0, 0]) { cylinder(d = knob_d, h = knob_h - 2); translate([0, 0, knob_h - 2]) cylinder(d1 = knob_d, d2 = knob_d - 4, h = 2); }

module pump_lying() rotate([0, 90, 0]) {   // along +x from the head's face
  cylinder(d = pump_head[0], h = pump_head[1]);
  for (s = [-1, 1]) translate([-pump_head[0]/2 - nozzle_off + 3, s*nozzle_pitch/2, pump_head[1]/2]) rotate([0, 90, 0]) cylinder(d = 4, h = nozzle_off + 3);   // nozzles, pointing up
  translate([0, 0, pump_head[1]]) linear_extrude(pump_flange[2]) rrc(pump_flange[1], pump_flange[0], 6);
  translate([0, 0, pump_head[1] + pump_flange[2]]) cylinder(d = pump_motor[0], h = pump_motor[1]);
}
module pump_upright() {   // motor down, head up
  cylinder(d = pump_motor[0], h = pump_motor[1]);
  translate([0, 0, pump_motor[1]]) linear_extrude(pump_flange[2]) rrc(pump_flange[1], pump_flange[0], 6);
  translate([0, 0, pump_motor[1] + pump_flange[2]]) cylinder(d = pump_head[0], h = pump_head[1]);
  for (s = [-1, 1]) translate([s*nozzle_pitch/2, 0, pump_motor[1] + pump_flange[2] + pump_head[1] - 0.01]) cylinder(d = 4, h = nozzle_off);   // nozzles up
}
module pumps() color("#d8d8d8") for (y = pump_y) if (upright) translate([pump_x, y, floor_t]) pump_upright(); else translate([head_x, y, pump_z]) pump_lying();
module boards() for (b = boards) color("#1f3a5f") translate(b[0]) cube(b[1]);
module bottles() for (i = [0, 1]) let (c = cup_c[i]) translate([c[0], c[1], floor_t + cup_floor]) color(i == 0 ? "#b3662a" : "#ecebe3") { cylinder(d = bottle[0], h = bottle[1] - 22); translate([0, 0, bottle[1] - 22]) cylinder(d1 = bottle[0], d2 = bottle[0]*0.55, h = 8); translate([0, 0, bottle[1] - 16]) cylinder(d = bottle[0]*0.55, h = 16); }
module bin() color([0.72, 0.81, 0.88, 0.35]) translate([B/2, B/2, -bin_h]) hull() {
  linear_extrude(0.01) rrc(bin_bot, bin_bot, bin_r);
  translate([0, 0, bin_h - 0.01]) linear_extrude(0.01) rrc(bin_top, bin_top, bin_r);
}

if (part == "all")     { shell(); lid(); panel(); knob(); pumps(); boards(); bottles(); bin(); }
if (part == "shell")   shell();
if (part == "lid")     lid();
if (part == "panel")   panel();
if (part == "knob")    knob();
if (part == "pumps")   pumps();
if (part == "boards")  boards();
if (part == "bottles") bottles();
if (part == "bin")     bin();
