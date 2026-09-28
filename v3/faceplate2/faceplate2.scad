// Hydro Doser v3, faceplate 2: every board on the plate itself, no
// adapters. Fits the body as printed (same outline, screws, band opening).
// See BRIEF.md.
//
// Frame as the v3 model: x right -> left seen from the front (0 at the
// body's right edge), y front -> back (0 at the plate's face), z up.
// Seen from the front, left to right: the screen, the ESP32 (hidden
// behind), the knob. The pH board stands over the knob's encoder; the TDS
// board stands on a fin at the screen's end, clear of the left cup (a
// board over the screen would reach into it).
//
//   openscad -o stl/faceplate2.stl --export-format binstl -D 'part="print"' faceplate2.scad

use <../hydro-doser-v3.scad>           // the body as printed, the knob, the wall boards: for the checks

part = "all";
$fn = 64;

// ---------------------------------------------------------- the plate (as v3)
px0 = 12.8;  pz0 = 7.3;  pw = 176.4;  ph = 59.4;  pr = 8;  pt = 3;  pch = 1;
pscrews = [[px0 + pr, pz0 + pr], [px0 + pw - pr, pz0 + pr], [px0 + pw - pr, pz0 + ph - pr], [px0 + pr, pz0 + ph - pr]];
screw  = [3.4, 6.7];                  // M3 countersunk: clearance, head dia
ctl_z  = 37;                          // the controls' line: the plate's middle
opening = [px0 + 12, pz0 + 12, px0 + pw - 12, pz0 + ph - 12];   // the band's opening behind the wall: x0, z0, x1, z1
band_d = 6;                           // the band's depth behind the plate's back
fil    = 1.5;                         // every standoff's fillet into the plate

// ---------------------------------------------------------- the parts
knob     = [36, 9.5, 38, 2, 1.5, 11, 4];          // as v3: dia, height, recess dia, recess depth, chamfer, nut pocket dia, depth
enc      = [31, 19, 1.6, 6.5, 11.5, 16, 6, 4.5, 9.5];   // KY-040: pcb w, h, t; body, bushing top, shaft top; shaft dia, flat; shaft centre from the pcb's top edge
enc_h    = 14;                                   // it stands 14 off the plate's back once mounted (measured)
oled     = [27.3, 27.8, 1.6, 26.7, 19.3, 1.5, 21.7, 10.9];   // pcb w, h, t; glass w, h, t; active w, h
oled_pk  = [0.3, 0.2, 2, 3];                     // its pocket: clearance x, z, wall, depth
esp      = [28.3, 51.5, 1.6, 8.5];               // DevKit V1 30-pin: w (z), l (x), pcb, pins back
esp_hole = [3, 2.3];  esp_so = [5.5, 4, 2.2];     // its holes (dia, in from the edges: measure yours), standoffs (dia, height, M2.5 pilot)
brd      = [32, 42, 1.6];                        // the TDS and pH boards: short side, long side, pcb
brd_hole = [3.1, 3.5];                           // their holes (dia, in from the edges: measure yours)
brd_so   = [5.5, 2.6];                           // their standoffs' dia, M3 pilot

// ---------------------------------------------------------- the layout
oled_x = px0 + pw/2 + 45;                        // the screen: 45 left of centre, seen from the front
knob_x = px0 + pw/2 - 45;                        // the knob: 45 right of centre
esp_c  = [103, ctl_z];                           // the ESP32 between them, lying along x
oled_s = -1;                                     // the screen's way up: -1 header DOWN, so the panel's yellow rows (along the header's edge) come out on top as the firmware draws its title there
oled_pcb_z = ctl_z - 1.45*oled_s;                // the picture on the controls' line: the board sits off-centre from it, by the way up
knob_y = -0.5;                                   // the knob's base 0.5 in front of the flat face (no recess: it prints on the bed)
enc_pcb_y = pt + enc[3];
esp_y  = pt + esp_so[1];                         // its pcb's plate-side face (the module toward the plate)
ph_c   = [knob_x, ctl_z];  ph_y = pt + enc_h + 1.5;   // the pH board over the encoder, 1.5 behind its 14
fin    = [168, 3, 52];                           // the TDS board's fin: its plate-side face x, thickness, reach behind the plate
tds_c  = [fin[0] + fin[1], 31, ctl_z];           // the TDS board against the fin's outer face: x of its face, centre y, centre z

function holes4(c, a, b) = [for (sa = [-1, 1], sb = [-1, 1]) [c[0] + sa*a, c[1] + sb*b]];
esp_holes = holes4(esp_c, esp[1]/2 - esp_hole[1], esp[0]/2 - esp_hole[1]);            // (x, z)
ph_holes  = holes4(ph_c, brd[1]/2 - brd_hole[1], brd[0]/2 - brd_hole[1]);            // (x, z)
tds_holes = holes4([tds_c[1], tds_c[2]], brd[1]/2 - brd_hole[1], brd[0]/2 - brd_hole[1]);   // (y, z) on the fin

assert(esp_c[0] - esp[1]/2 >= knob_x + enc[0]/2 + 1 && esp_c[0] + esp[1]/2 + 1 <= oled_x - oled[0]/2 - oled_pk[0] - oled_pk[2], "the ESP32 runs into the encoder or the screen's pocket");
assert(fin[0] >= oled_x + oled[0]/2 + oled_pk[0] + oled_pk[2] + 2 && fin[0] + fin[1] + brd[2] + 8 <= opening[2] + 20, "the fin runs into the screen's pocket");

// ---------------------------------------------------------- helpers
module rr(w, h, r) offset(r) offset(-r) square([w, h]);
module rrc(w, h, r) translate([-w/2, -h/2]) rr(w, h, r);
module plate2d(extra = 0) translate([px0, pz0]) offset(extra) rr(pw, ph, pr);
module on_back(y = pt) translate([0, y, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0]) children();   // (x, z) plane at y, extruding into +y
module csk(d, head, h) { translate([0, 0, -1]) cylinder(d = d, h = h + 2); translate([0, 0, -0.01]) cylinder(d1 = head, d2 = 0, h = head/2); }
// a post off the plate's back toward +y at (x, z): dia, height, filleted into the plate
module post(x, z, d, h) translate([x, pt - 0.01, z]) rotate([-90, 0, 0]) {
  cylinder(d = d, h = h + 0.01);
  for (i = [0:5]) let (a0 = 90*i/6, a1 = 90*(i + 1)/6, h0 = fil*(1 - cos(a0)), h1 = fil*(1 - cos(a1)))           // the fillet: widest at the plate
    translate([0, 0, h0]) cylinder(r1 = d/2 + fil*(1 - sin(a0)), r2 = d/2 + fil*(1 - sin(a1)), h = h1 - h0 + 0.01);
}

// ---------------------------------------------------------- the plate
module plate2() color("#1c1c1c") difference() {
  union() {
    rotate([90, 0, 0]) mirror([0, 0, 1]) hull() { translate([0, 0, pch]) linear_extrude(pt - pch) plate2d(); linear_extrude(pch + 0.01) plate2d(-pch); }   // the plate, its face edge rounded off
    // the screen's pocket: a low frame it drops into from behind
    translate([oled_x, pt - 0.01, oled_pcb_z]) rotate([-90, 0, 0]) linear_extrude(oled_pk[3] + 0.01) difference() {
      offset(oled_pk[2]) square([oled[0] + 2*oled_pk[0], oled[1] + 2*oled_pk[1]], center = true);
      square([oled[0] + 2*oled_pk[0], oled[1] + 2*oled_pk[1]], center = true);
    }
    // no rib by the encoder: its harness plugs in on that side; its bushing's nut holds it
    // standoffs: the ESP32's, the pH board's (over the encoder)
    for (h = esp_holes) post(h[0], h[1], esp_so[0], esp_so[1]);
    for (h = ph_holes) post(h[0], h[1], brd_so[0], ph_y - pt);
    // the TDS board's fin, and its foot filleted into the plate
    translate([fin[0], pt - 0.01, opening[1] + 0.5]) cube([fin[1], fin[2] + 0.01, opening[3] - opening[1] - 1]);
    for (s = [-1, 1]) translate([fin[0] + (s < 0 ? 0 : fin[1]), pt - 0.01, opening[1] + 0.5]) mirror([s < 0 ? 1 : 0, 0, 0]) linear_extrude(opening[3] - opening[1] - 1) difference() { square(4); translate([4, 4]) circle(r = 4); }
  }
  for (s = pscrews) translate([s[0], 0, s[1]]) rotate([-90, 0, 0]) csk(screw[0], screw[1], pt);                                   // its screws, countersunk in the face
  translate([knob_x, -1, ctl_z]) rotate([-90, 0, 0]) cylinder(d = 7.5, h = pt + 2);                                             // the bushing hole
  translate([oled_x, -1, ctl_z]) rotate([-90, 0, 0]) linear_extrude(pt + 2) rrc(oled[6] + 0.6, oled[7] + 0.6, 2);                 // the window, the picture's size
  translate([oled_x - oled[3]/2 - oled_pk[0], pt - oled[5] - 0.2, oled_pcb_z - 0.75*oled_s - oled[4]/2 - oled_pk[1]]) cube([oled[3] + 2*oled_pk[0], oled[5] + 1, oled[4] + 2*oled_pk[1]]);   // the glass's recess
  for (h = esp_holes) translate([h[0], pt + 1, h[1]]) rotate([-90, 0, 0]) cylinder(d = esp_so[2], h = esp_so[1] + 1);             // pilots
  for (h = ph_holes) translate([h[0], pt + 1, h[1]]) rotate([-90, 0, 0]) cylinder(d = brd_so[1], h = ph_y);
  for (h = tds_holes) translate([fin[0] - 1, h[0], h[1]]) rotate([0, 90, 0]) cylinder(d = brd_so[1], h = fin[1] + 2);
}

// ---------------------------------------------------------- the parts, placed
module knob2() translate([knob_x, knob_y, ctl_z]) rotate([90, 0, 0]) knob_ring();
module knob2_cap() translate([knob_x, knob_y, ctl_z]) rotate([90, 0, 0]) knob_cap();
module enc2() color("#3a7a3a") translate([knob_x, enc_pcb_y, ctl_z]) {
  translate([-enc[0]/2, 0, enc[8] - enc[1]]) cube([enc[0], enc[2], enc[1]]);                                             // the pcb
  rotate([90, 0, 0]) { translate([-6, -6, 0]) cube([12, 12, enc[3]]); cylinder(d = 7, h = enc[4]); linear_extrude(enc[5]) difference() { circle(d = enc[6]); translate([-5, enc[7] - enc[6]/2]) square([10, 5]); } }   // body, bushing, the D shaft
  translate([0, -enc_pcb_y, 0]) rotate([90, 0, 0]) cylinder(d = 10, h = 2.5, $fn = 6);                                 // the nut, on the face, inside the knob's base
  translate([enc[0]/2, enc[2]/2 - 1.27, enc[8] - enc[1]/2 - 6.35]) cube([22, 2.54, 12.7]);                             // its pins and plugs, out of its short edge toward the ESP32
  translate([-enc[0]/2, enc[2], enc[8] - enc[1]]) cube([enc[0], pt + enc_h - enc_pcb_y - enc[2], enc[1]]);             // everything on its back, to 14 off the plate
}
module oled2() translate([oled_x, pt, oled_pcb_z]) mirror([0, 0, oled_s < 0 ? 1 : 0]) {   // drawn header up, turned to its way up
  translate([-oled[0]/2, 0, -oled[1]/2]) cube([oled[0], oled[2], oled[1]]);
  translate([-oled[3]/2, -oled[5], -0.75 - oled[4]/2]) cube([oled[3], oled[5], oled[4]]);
  translate([-5, oled[2], oled[1]/2 - 3]) cube([10, 8, 2]);                                                             // its header
  translate([-5.2, oled[2] + 2, oled[1]/2 - 3.27]) cube([10.4, 20, 2.54]);                                              // its Dupont plugs
}
module esp2() color("#101418") translate([esp_c[0], esp_y, esp_c[1]]) difference() {
  union() {
    translate([-esp[1]/2, 0, -esp[0]/2]) cube([esp[1], esp[2], esp[0]]);
    translate([esp[1]/2 - 25.5, -3.1, -9]) cube([25.5, 3.1, 18]);                                                        // the module, toward the plate
    translate([-esp[1]/2 - 0.5, -3, -4]) cube([6, 3, 8]);                                                                // the USB
    for (sz = [-1, 1]) translate([-esp[1]/2 + 4.5, esp[2], sz*(esp[0]/2 - 1.3) - 1.25]) cube([esp[1] - 9, esp[3] + 14, 2.5]);   // the pin rows and their plugs
  }
  for (h = esp_holes) translate([h[0] - esp_c[0], -4, h[1] - esp_c[1]]) rotate([-90, 0, 0]) cylinder(d = esp_hole[0], h = 10);
}
module ph2() color("#1e7a3c") translate([ph_c[0], ph_y, ph_c[1]]) difference() {
  union() {
    translate([-brd[1]/2, 0, -brd[0]/2]) cube([brd[1], brd[2], brd[0]]);
    translate([-brd[1]/2 + 6, brd[2], -brd[0]/2 + 6]) cube([brd[1] - 12, 8, brd[0] - 12]);                             // its chips and trimmers
    translate([-brd[1]/2 - 22, brd[2] - 1.3, -7.6]) cube([22, 2.6, 15.2]);                                              // its header and plugs, out of its short edge
  }
  for (h = ph_holes) translate([h[0] - ph_c[0], -4, h[1] - ph_c[1]]) rotate([-90, 0, 0]) cylinder(d = brd_hole[0], h = 10);
}
module tds2() color("#1d4fa0") translate([tds_c[0], tds_c[1], tds_c[2]]) difference() {
  union() {
    translate([0, -brd[1]/2, -brd[0]/2]) cube([brd[2], brd[1], brd[0]]);                                                 // the pcb, against the fin
    translate([brd[2], -brd[1]/2 + 6, -brd[0]/2 + 6]) cube([6, brd[1] - 12, brd[0] - 12]);                             // its connectors, outward
  }
  for (h = tds_holes) translate([-4, h[0] - tds_c[1], h[1] - tds_c[2]]) rotate([0, 90, 0]) cylinder(d = brd_hole[0], h = 10);
}
module parts2() { knob2(); knob2_cap(); enc2(); oled2(); esp2(); ph2(); tds2(); }

// ---------------------------------------------------------- output
if (part == "all") { plate2(); parts2(); }
else if (part == "plate") plate2();
else if (part == "print") rotate([90, 0, 0]) plate2();                            // face down: its back and everything on it up
else if (part == "parts") parts2();
