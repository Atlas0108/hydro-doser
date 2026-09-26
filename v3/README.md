# Hydro Doser v3

Detailed to `BRIEF.md`. A printed enclosure on its own feet: three
peristaltic pumps, a screen, a knob and the DevKit on a black faceplate,
the driver and the buck on the side walls, and the two 125 mL nutrient
bottles standing in a deck on the lid. No tank under it.

```
   from the front                          from above, lid off
   ╭───────────────────╮                   ╭───────────────────╮
   │     [=]   (o)     │  bottles 37       │ ═══ ═══ ═══  pumps│  heads forward, rolled 42°,
   │  ▔▔▔▔▔▔▔▔▔▔▔▔▔    │  above the deck   │ ▪   (B)   (A)   ▪ │  motors to the back
   ╰───────────────────╯                   ╰───────────────────╯  ▪ wall boards, (A)(B) cups
    ▪               ▪   feet
   202 x 178 footprint, 85 tall from the plate's underside to the lid, 89 at the deck
```

The lid snaps on; the faceplate is the only screwed piece,
its four screws at the centres of its corner radii. The feet sit at the
centres of the body's corner radii. Every edge is rounded.

Published at <https://github.com/Atlas0108/hydro-doser> under `v3/`, with
the firmware under `firmware/v3/`; this copy is the working one.

## Pieces

| Piece | Prints | Size | |
|---|---|---|---|
| `body` | floor down | 202 × 178 × 82 | floor and walls in one: bulkhead, cups, wall-board ribs, vents, the front opening, the feet's pockets, the rim on top |
| `lid` + `lid_deck` | underside down | 202 × 178 × 11 | flat underneath but for its pocket; the deck on top is the second file, printed black |
| `plate` | face down | 176 × 59 × 28 | black; the screen's pocket, the knob's ribs, and standoffs for the DevKit and the TDS board on its back |
| `knob` + `knob_cap` | base down | Ø36 × 9.5 | the knurled ring brown-red, the cap (face and rounded edge) black; the D bore reaches 1.2 short of the face; the encoder's shaft is cut to 16 above its pcb |
| `ph_adapter` | on its bottom edge | 42 × 18 × 33 | black; hangs on the encoder's ribs and carries the pH board. Tall on a small footprint: print it with a brim |
| `foot` | disc down, TPU | Ø18 × 6 | four |
| `spout` | top down, legs up | 40 × 16 × 34 | clips the reservoir's rim |

The lid and the knob each come as two STLs in the same place: the olive (or orange) part and its black part. Load the pair as one object in the slicer (Bambu Studio: import both together and answer yes to loading them as a single object with multiple parts), then give the black part the black filament.

`./export.sh` writes them into `stl/` as they print, no supports. The
front band slopes at 45° underneath; the vents' ceilings, the lid's
pocket ceiling is a short bridge.

Hardware: 4 × M3 heat-set inserts and 4 × M3 × 8 countersunk (the
faceplate), 6 × M3 × 8 (pump flanges, from the motor side, threading into
the flanges' Ø3.2 holes). Bought parts as in `BRIEF.md`.

## How it goes together

- **Body.** Floor and walls in one piece, open at the top. The floor is
  4 thick with a 1.5 chamfer under its edge, the one edge that is not
  rounded, because it prints from the bed. Four TPU feet snap into the
  floor at the corners' radius centres, a disc in a pocket underneath and
  a lipped peg into a counterbore above, flush with the floor's top.
- **Pumps.** Three INTLLAB pumps lie across the back, heads forward,
  motors through U-slots in a bulkhead at 125 and back to the wall, all
  standing on the floor. Each
  is rolled 42° about its axis, as in the first design, so its diamond
  flange's two holes sit on a 42° line: one high on the right, one low on
  the left of the axis. The bulkhead has Ø3.4 holes to match; the screws
  go in from the motor side, between the motors with a stubby or
  right-angle driver, and thread into the flange. Nozzles lean left. Pump
  0 (right) is Nutrient A, pump 1 (middle) Water, pump 2 (left) Nutrient
  B.
- **Cups.** Two Ø52 tubes (2 mm round the Ø48 bottles) side by side in the middle of the front, open
  at both ends. A bottle stands on the base plate and shows 37 above the
  deck. Two Ø8 holes through the lid, their mouths rounded, one 16 out
  from each bottle on its outer side for the nutrient tube. The water
  tube comes in through a plain Ø8 hole low in the back wall, midway
  between the jack and the GX12, under the middle motor: it runs under
  the motor, up between the motors and over the bulkhead to the nozzles.
- **Bottles.** The Rise Gardens 125 mL Sprout and Thrive bottles, measured
  Ø48 × 122: a white HDPE cylinder round, rounded shoulder, 24 mm neck, a
  black disc-top cap, a wraparound label (Sprout green, Thrive blue). In the
  model as body, cap and label so the pages and the render colour them apart.
- **Wall boards.** The ULN2003 stands in two slotted ribs on the right
  wall and the buck in two on the left, beside the cups, dropped in from
  above with the lid off; the boards rest on the slots' floors just off
  the body's floor, components inward.
- **Vents.** Seven rounded slots, 40 × 2, in each side wall beside the
  motors, at 5 mm pitch from 12 up.
- **Faceplate.** A black plate, 3 thick, 96 × 59, centred on the front
  and flush with it, its edge and the opening's edge rounded 1 so the
  seam is a soft groove. Four M3 × 8 at its corner-radius centres into
  inserts in a 12 mm band behind the wall. On its back: the OLED drops
  straight into a pocket, a 3 mm frame 0.3 clear each side and 0.2 top
  and bottom, its glass in a blind recess behind the face (a dab of hot
  glue or foam tape keeps it seated); the window
  the size of its picture; the KY-040 sits between two ribs, its nut on
  the floor of a Ø38 × 2 recess, and the Ø36 knob hides the nut in a
  pocket in its base, sits 0.5 off the recess floor, and stops on the
  shaft's end (the KY-040's 20 mm shaft cut to 16 above the pcb; the
  knob is 9.5 thick and its D bore runs to 1.2 short of the face).
  The screen sits dead centre; the knob is midway between the screen's
  centre and the plate's right edge. Left of the screen, as seen from
  the front, the 30-pin ESP32 DevKit lies along the plate, its left end
  4 short of the left screws' inserts. It stands on four Ø5.5 standoffs, 5 tall, module toward the plate and
  pins pointing into the box, held by M2.5 self-tappers through its
  corner holes into Ø2.2 pilots. The holes are taken as Ø3, 2.3 in from
  each edge (46.9 × 23.7 apart): measure your board and change
  `esp_hole` if it differs. The band behind the wall is notched there
  so the board clears it, the notch's ceiling sloped 45° so it prints.
  Straight behind the screen, the DFRobot Gravity TDS (or pH V2) signal
  board, 42 × 32, lies along the plate on four Ø6 standoffs, 25 tall, so
  it clears the screen's header and the Dupont plugs on it; its back
  runs between the two cups. Two of the standoffs merge into the
  screen's side ribs. M3 self-tappers through its corner holes into
  Ø2.6 pilots. The holes are taken as Ø3.1, 3.5 in from each edge (35 ×
  25 apart): measure your board and change `tds_hole` if it differs.
  Fit the screen before the board: the board covers its way in.
  The pH board (PH-4502C type, 42 × 32, its BNC removed) hangs on the
  encoder's two ribs on a printed adapter, `ph_adapter`: two legs hug
  the ribs' outer faces for 8 mm, a lip on each rests on a rib's top,
  and a bridge spans behind the encoder, 2 clear of its back. It slides
  on from behind after the encoder is in and lifts straight off. The
  board sits on four Ø5.5 standoffs, 5 tall, on the bridge, beside the
  TDS board with 2 between them; M3 self-tappers into Ø2.6 pilots. The
  holes are taken as Ø3.1, 3.5 in from each edge (35 × 25 apart):
  measure yours and change `phb_hole` if it differs.
  Fit all four, then screw the plate on.
  The window sits 14 from the plate's edge, the same as the knob's
  recess; the screen's outer rib lands where the band would be, so the
  band is notched there between the two screws.
- **Back.** The jack and the GX12-6 low in the back wall at the motors'
  height, between the motors; the grommet above the middle motor. The
  nutrient outlets run back over the bulkhead to the grommet with the
  float lead.
- **Lid.** Flush with the walls, 7 thick with a 4 mm round on its edge.
  A 1.5 mm rim rises 4 from the walls' inner half with a ridge round its
  inside; the lid's underside has a pocket ring over it with a groove the
  ridge clicks into, so nothing hangs below the lid and it prints flat.
  A raised deck over the cups, rounded on top with a cove at its foot.

## Texture

The body's vertical faces get a fuzzy-skin band, from 4 above the bottom
up to the lid seam, so it clears the faceplate by the same 3.3 above and
below, stopping 3 mm short of the faceplate's
opening. The faceplate, lid and base stay smooth. It is a slicer effect,
so nothing in the STL changes; `stl/fuzz-modifier.stl` is a modifier
shell that puts it exactly there:

1. In Bambu Studio or OrcaSlicer, select the body, right-click, Add
   Modifier, Load, pick `fuzz-modifier.stl`. It lands in place (same
   origin as `body.stl`).
2. On the modifier, set Fuzzy Skin to Contour, thickness 0.3, point
   distance 0.8. In OrcaSlicer 2.3 or later pick a noise type: Perlin at
   feature size 1 for a fine grain, Voronoi at 2 to 3 for a patchwork.
3. Leave Fuzzy Skin off on the body itself and every other piece.

Contour fuzzes only the outer wall, and only inside the shell, so the
snap fits, the opening and the cavity stay smooth. Print a small test
band first: fuzzy skin adds 0.3 to the outside, so the lid and base seams
show a 0.3 step unless the texture band is what you want to read there.
(The body's bottom 4 mm and the lid sit inside the band.)

## Checks

`./verify.sh` (export first) runs the boolean checks: the floor closed;
feet at the radius centres, snapping in and staying under; the
lid on the shoulder, its pocket over the rim, snapping, located, flush,
flat underneath; bottles dropping in and showing 30; tubes up through
their three holes; pumps seated, lifting out, their flange screws on the
42° line reaching from the back with a driver; tube runs to the holes
and the grommet; the DevKit on its standoffs, the wall boards in their
slots, all sliding in, held and clear; ports between the motors; vents
open; the plate seated on its band, flush, held every way, its screws
at its radius centres, the seam groove open; the encoder, nut, knob and
D flat; the screen sliding in, held, its picture shown; the spout; every
piece on the bed, unsupported and manifold.

## Open

- The bottles measure Ø48; their height, 122, is still an estimate.
- Firmware: v1's pin plan with the pumps re-labelled (0 A, 1 Water, 2 B),
  the OLED on GPIO21/22, the encoder on 18/19/23.
- The float switch has no mount yet.
