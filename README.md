# Hydro Doser

> **v3 is in [`v3/`](v3/)**: a clean-sheet enclosure on its own feet, a faceplate
> with a screen, a knob and the ESP32, snap-on lid, the pumps across the back.
> Its firmware is in [`firmware/v3/`](firmware/v3/). What follows is v1.

## v3

See [`v3/README.md`](v3/README.md) and [`v3/BRIEF.md`](v3/BRIEF.md).


A low unit that stands beside a hydroponic garden and doses straight into it:
a water tank for top-offs, the Nutrient A and Nutrient B bottles, and three
peristaltic pumps. The firmware is in `firmware/` (still the
earlier four-pump, mix-tank version; it waits until the hardware is
settled).

**Status: printable design, not yet printed.** Seven printed pieces, all
inside the P1S bed, bolted together, no glue, no supports, no special
fittings: the tank is a stock Cambro bin with one hole drilled in its lid.
Layout, fit, joints, tool access and printability are checked by
`verify.sh` (58 checks). Some bought-part sizes are estimates: see *Before
printing*. This version follows an independent review, kept in
`REVIEW-2026-09-23.md`.

```
   ╭──────────╮ ╭───╮       tank: a Cambro 6 qt bin on its dock. Its line
   │  WATER   │ │Spr│       comes out of the column, in through a hole in
   │          │ │   │       the lid, and sits on the bottom
   │          │ │Thr│       column: two cans, one bottle each, front / back
   ├──────────┴─┴───┤
   │ [W]  [S]  ●○○ [T]      base: two trays bolted side by side. Pumps behind
   └────────────────┘       removable covers; one sleeved bundle leaves the
   345 × 225 × 315 mm       back, to the reservoir
```

## Why this shape

- **No mix tank.** A hydroponic reservoir circulates its own water, and the usual
  instruction is to add concentrate to it with each top-off. Dosing
  into the reservoir directly removes a tank, a pump, a manifold, and the
  siphon and stratification problems the review found in the mix tank.
- **Every outlet ends in air.** The three lines run to a printed spout that
  hangs on the reservoir's rim and holds the tube ends above the water.
  Only pickups sit on the bottom (in the tank and the bottles). A primed
  line can't siphon in either direction, and a dose leaves the line after
  every run instead of sitting in it.
- **Nutrient A and Nutrient B never share a line.** Two-part concentrates
  precipitate when they meet undiluted, so each has its own pump, chase,
  and outlet.
- **The tank is a stock Cambro bin with a drilled lid.** Its line comes out
  of the top of its chase, 40 mm above the lid, crosses 30 mm, drops through
  a 10 mm hole and sits on the bottom. To fill: lift the lid, or lift the bin out
  from under its tube. A 3 mm curb on the plate locates it; a 1.5 mm rim
  keeps spills on the plate and a notch at the back drains them off the
  outside of the case.
- **Nothing electrical under the tank.** The ESP32, the ULN2003 and the
  buck sit on standoffs in the column tray, behind the Nutrient B pump.
- **Pumps are serviceable without lifting anything.** Each pump drops into
  its tray from above, motor through a U-slot in a bulkhead, head in the
  front bay behind a 50 mm opening. Its two flange screws are driven from
  the front through that opening; a cover with four countersunk screws
  closes it. The INTLLAB pump's tube nozzles stand off the top of its head,
  so each pump is rolled 42° about its axis: the nozzles point up and
  sideways into the room beside the head, 4.6 mm under the plate, and both
  mounting holes (48.5 mm apart on the flange's axis) land on solid
  bulkhead, clear of the slot. The tubes loop back through a 12 × 28 mm
  slot in the bulkhead.
- **The column is two cans.** The pockets are the walls, so there's no box
  around them, no bridging, and about half the plastic of a boxed column.
  Two walls run from can to can and fuse into both, making the pair one
  box section; the left one carries the tank chase. Three chase tubes, as
  tall as the walls, carry the lines: Nutrient A's and Nutrient B's from the bottle
  caps down through the floor, the tank line up from the floor and out of
  the top. The column's floor
  plate screws down at the three corners the cans leave exposed,
  countersunk, reachable from above.
- **Two trays make the base**, sliced from one rounded body so the seam has
  no groove: three M3 through-bolts (one high, at the middle, so the trays
  can't hinge), three 14 mm tube holes, a wire hole. The bulkhead runs to
  the plate and a second crossbar sits under it, so the 4 mm plate has
  three supports under the tank.

## Pieces

`./export.sh` writes each one into `stl/`, as it prints: standing, no
supports. Masses are solid PETG; the slicer's infill brings the plate and
floors down. Three colours: the trays, plate and the column's floor in matte olive, the
column's towers and the spout in matte white, the sleeves and pump covers in
matte black. For the column, load `stl/two-colour/column_floor.stl` and
`column_towers.stl` together as one object with several parts (Bambu Studio
asks) and give each its filament; they are already in position.

| Piece | Print | Size (mm) | ~g | |
|---|---|---|---|---|
| `tray_dock` | 1 | 225 × 225 × 66 | 580 | tank dock, Water + Nutrient A pumps, panel |
| `tray_col` | 1 | 120 × 225 × 66 | 335 | Nutrient B pump, electronics, jacks |
| `plate` | 1 | 225 × 225 × 7 | 270 | dock plate: curb, drip rim |
| `column` | 1 | 120 × 225 × 249 | 870 | two cans, web walls, three chases; in two colours as `stl/two-colour/column_floor.stl` (green) + `column_towers.stl` (white) |
| `sleeve` | 2 | 95 × 95 × 243 | 180 | for the 125 mL bottles; skip for 1 L |
| `cover` | 3 | 68 × 62 × 2 | 11 | pump covers, 5 mm around each screw |
| `spout` | 1 | 40 × 20 × 42 | 19 | hangs on the reservoir's rim |
| `panel_plate` | 1 | 36 × 48 × 12 | 17 | behind the front wall: two 6 × 6 tactile switches, the LED in its bezel tube |
| `button_cap` | 2 | 14 × 14 × 6 | 1 | through the 12.5 holes, flange behind |

**PETG**, 3 walls, 15 % infill, brim on the big flat pieces. Every piece's
bed contact and unsupported area are measured by `verify.sh` (45° cones
pass, flatter overhangs don't).

Hardware: 9 × M3 heat-set inserts (4 dock posts, 3 column posts, 2 in the
panel plate), 7 × M3×8 countersunk (plate, column), 6 × M3×8 countersunk
(covers), 2 × M3×8 countersunk (panel plate, from the front), 6 × M3
self-tapping (pump flanges), 3 × M3×12 with nuts (seam), M2.5 for the
boards.

**The panel.** Drop the two switches into the plate's pockets (pins out the
back), push the LED in from the back until its flange meets the shoulder,
set the caps in their recesses, offer the plate up behind the wall so the
caps and the LED tube come through, and put in the two screws from the
front. The switch plunger sits 0.1 mm behind the cap; the cap bottoms after
0.4 mm, past the switch's click. Solder the leads on the back afterwards.

## Bill of materials

Everything that isn't printed, with two places to buy each. Roughly
$230 for the parts and $75 for the filament.

| | Qty | Source | Amazon |
|---|---|---|---|
| Cambro CamSquare 6 qt container, translucent (6SFSPP190) | 1 | [WebstaurantStore](https://www.webstaurantstore.com/cambro-6sfspp190-6-qt-translucent-square-food-storage-container-with-winter-rose-colored-gradations/2146SFSPP.html) | [Amazon](https://www.amazon.com/dp/B07FC7L861) |
| Cambro seal lid for the 6 and 8 qt (SFC6SCPP190), drilled Ø10 | 1 | [WebstaurantStore](https://www.webstaurantstore.com/cambro-sfc6scpp190-translucent-6-and-8-qt-camwear-seal-cover/214SFC6SCPP.html) | [Amazon](https://www.amazon.com/dp/B01L7RKD9W) |
| INTLLAB 12 V peristaltic dosing pump, 3 × 5 mm tube (Amazon sells a 4-pack) | 3 | [INTLLAB](https://intllab.net/products/mini-12v-peristaltic-dosing-pump) | [Amazon](https://www.amazon.com/dp/B088TBKNSY) |
| Silicone pump tubing, 3 mm ID × 5 mm OD, about 6 m | 1 | [INTLLAB](https://intllab.net/products/peristaltic-doing-pump-tubing) | [Amazon](https://www.amazon.com/dp/B092V7B77V) |
| ESP32-DevKitC, 38 pin (Amazon's is the WROVER-E variant, same footprint) | 1 | [DigiKey](https://www.digikey.com/en/products/detail/espressif-systems/ESP32-DEVKITC-32E/12091810) | [Amazon](https://www.amazon.com/dp/B087TNPQCV) |
| ULN2003 driver board (six of its seven channels: two per pump) | 1 | [Makerfabs](https://www.makerfabs.com/uln2003-stepper-motor-driver.html) | [Amazon](https://www.amazon.com/dp/B07X2WGK2P) |
| 12 V → 5 V step-down regulator, 2 A or more (Pololu D24V22F5, or any small buck module) | 1 | [Pololu](https://www.pololu.com/product/2858) | [Amazon](https://www.amazon.com/dp/B0GYJDP96Q) |
| 12 V 2 A wall adapter, 5.5 × 2.1 mm plug, UL listed | 1 | [DigiKey](https://www.digikey.com/en/products/detail/cui-inc/SWI25-12-N-P5/7070093) | [Amazon](https://www.amazon.com/dp/B013S9RGNS) |
| Panel-mount DC jack, 5.5 × 2.1 mm, threaded | 1 | [Adafruit](https://www.adafruit.com/product/610) | [Amazon](https://www.amazon.com/dp/B07C46XMPT) |
| Resettable fuse, 1.6 A hold, radial (Bourns MF-R160) | 1 | [DigiKey](https://www.digikey.com/en/products/detail/bourns-inc/MF-R160/259972) | [Amazon](https://www.amazon.com/dp/B0DHSW186L) |
| Vertical float switch, polypropylene, with cable (Cynergy3 RSF54Y100RC) | 1 | [DigiKey](https://www.digikey.com/en/products/detail/sensata-cynergy3/RSF54Y100RC/753328) | [Amazon](https://www.amazon.com/dp/B07DYW1C7P) |
| GX12 6-pin panel connector, socket and plug (float switch, TDS probe, temperature probe) | 1 | [ZYLtech](https://www.zyltech.com/new-zyltech-aviation-plug-6-pin-12mm/) | [Amazon](https://www.amazon.com/dp/B089YT21LY) |
| 6 × 6 × 5 mm tactile switch, 4 pin | 2 | [Adafruit](https://www.adafruit.com/product/367) | [Amazon](https://www.amazon.com/dp/B0796QHL5Z) |
| 5 mm green LED | 1 | [Adafruit](https://www.adafruit.com/product/298) | [Amazon](https://www.amazon.com/dp/B01C3ZZTB4) |
| Push-in grommet for a 5/8" hole, 1/2" ID | 1 | [Grainger](https://www.grainger.com/product/GRAINGER-APPROVED-Grommet-3MPL5) | [Amazon](https://www.amazon.com/dp/B0FH2DNHN6) |
| Expandable braided sleeving, 1/2", 10 ft | 1 | [McMaster-Carr](https://www.mcmaster.com/9284K614/) | [Amazon](https://www.amazon.com/dp/B071ZV6MZ2) |
| M3 brass heat-set inserts (9 used) | 1 pack | [McMaster-Carr](https://www.mcmaster.com/94459A130/) | [Amazon](https://www.amazon.com/dp/B0BVMMBG2N) |
| M3 × 8 flat-head socket screws, stainless (15 used) | 1 pack | [Bolt Depot](https://boltdepot.com/Product-Details?product=7213) | [Amazon](https://www.amazon.com/dp/B01HBN0UU8) |
| M3 × 12 socket-head screws, stainless (3 used, the seam) | 1 pack | [Bolt Depot](https://boltdepot.com/Product-Details?product=6381) | [Amazon](https://www.amazon.com/dp/B01MYX1XBO) |
| M3 hex nuts, stainless (3 used) | 1 pack | [Bolt Depot](https://boltdepot.com/Product-Details?product=4773) | [Amazon](https://www.amazon.com/dp/B01MYX1XBO) |
| M3 × 10 thread-forming screws for plastic (6 used, the pump flanges) | 1 pack | [McMaster-Carr](https://www.mcmaster.com/95893A191/) | [Amazon](https://www.amazon.com/dp/B0779QYZXH) |
| Matte olive green PETG, 1 kg: the trays, plate and column floor | 2 | [California Filament](https://californiafilament.com/products/matte-olive-green-petg-filament-1-75mm-1kg) | [Amazon](https://www.amazon.com/dp/B0GGB1TS3Z) |
| Matte white PETG, 1 kg: the column's towers and the spout | 1 | [eSUN](https://esun3dstore.com/products/petg-matte) | [Amazon](https://www.amazon.com/dp/B0GGBCGJBC) |
| Matte black PETG, 1 kg: the sleeves and pump covers | 1 | [California Filament](https://californiafilament.com/products/matte-black-petg-filament-1-75mm) | [Amazon](https://www.amazon.com/dp/B0GGBMB1HJ) |

## Before printing

1. **Measure a Cambro 6 qt bin and lid**, a small nutrient bottle and a pump, and put
   the numbers in at the top of the `.scad` (`bin_bot`, `bin_r`, `lid_w`,
   `lid_above`, `pump_*`, `b125`). Only the bin's nominal outside size is
   from the spec sheet.
2. **Measure the reservoir's fill opening** for the spout (`rim_t`,
   `rim_drop`).
3. **Print the column tray and one cover first.** They test a pump opening,
   the U-slot, the tube slot, the cover screws, the standoffs and the jacks
   for a few dollars of filament.

**The first dock tray** was printed before the pump drawing arrived, with
the pump axis 2 mm higher (z 34) and pilot holes for a guessed bracket. It
still works: seat each pump at the bottom of its U-slot, roll it 43° so the
nozzles point up and toward the neighbouring pump, mark through the flange's
two holes, and drill Ø2.5. That clears the plate by 2.8 mm. It also has no
holes for the panel plate's screws: drill Ø3.5 at 183 mm from the dock's
left edge, 16 and 52 mm up, and countersink them from the front.

## Files

Published on its own at <https://github.com/Atlas0108/hydro-doser> (this
folder at the root, `firmware/` as `firmware/`); this copy is
the working one.

```sh
./export.sh                                   # every piece into stl/, plus mockup.stl
./verify.sh                                   # 57 checks (export first)
openscad -D 'bottles="1L"' hydro-doser.scad    # the scaled-up bottles
```

`mockup.stl` is the assembled unit with its bought parts, one body, for
viewing only. Open the `.scad` in OpenSCAD to see it in colour.

`verify.sh` checks: the tank clears everything and lifts straight up, the
curb is 3 mm and stops a misplaced tank, the rim is lower than the curb,
the lid hole is over the bin with a straight drop to the floor, the tank
line comes straight out of the top of its chase, 20+ mm above the lid, and the
chases stand as tall as the web walls; 1 L bottles
and the sleeves fit, a 125 mL bottle sits with its cap at the rim, each
chase runs clear top to tray and none opens into a pocket, each web wall fuses into both cans; the pumps sit
inside and lift straight out, the covers fit and their screws meet their
ribs, the flange screws can be driven from the front, each pump's tubes
have a 20 mm loop and pass their slot; the boards rest on standoffs, clear
everything and fit under the column; the panel hardware fits; the seam
carries its holes; the floors are closed; no two printed pieces overlap,
every screw meets its hole, a driver reaches every column and plate screw,
every post stands against a wall, the bulkhead reaches the plate; and every
exported STL fits the P1S, sits on the bed with real contact area, and has
no unsupported overhang.

## Next

- **Firmware** (on hold until the hardware is settled): three pumps, dose
  and top-off straight into the reservoir, the float gate on every run, a water
  tank counter with a refill button, a rolling daily water cap, the panel's
  buttons and light.
- **Level sensing:** a load cell under the dock plate would weigh the tank;
  the plate has the room.
- **Tube ends:** a small weight or a printed foot on each pickup keeps it on
  the bottom.
- **A product version** would mould the two trays as one, the column as one,
  with bosses instead of inserts, a moulded tank and lid, one PCB instead of
  the DevKit and driver boards, and a snap-on pump cover. The layout
  survives.
