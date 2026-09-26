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
| `body` + `body_cups` | floor down | 202 × 178 × 82 | floor and walls in one: bulkhead, wall-board ribs, vents, the front opening, the feet's pockets, the rim on top; the cups are the second file, printed black |
| `lid` + `lid_deck` | underside down | 202 × 178 × 11 | flat underneath but for its pocket; the deck on top is the second file, printed black |
| `plate` | face down | 96 × 59 × 22 | black; ribs, slots, ledge and the DevKit's rails on its back |
| `knob` + `knob_cap` | base down | Ø36 × 7.5 | the knurled ring burnt orange, the cap (face and rounded edge) black; D bore; the encoder's shaft is cut to 13.5 above its pcb |
| `foot` | disc down, TPU | Ø18 × 6 | four |
| `spout` | top down, legs up | 40 × 16 × 34 | clips the reservoir's rim |

The body, the lid and the knob each come as two STLs in the same place: the olive (or orange) part and its black part. Load the pair as one object in the slicer (Bambu Studio: import both together and answer yes to loading them as a single object with multiple parts), then give the black part the black filament.

`./export.sh` writes them into `stl/` as they print, no supports. The
front band slopes at 45° underneath; the vents' ceilings, the lid's
pocket ceiling and the DevKit's rails are short bridges.

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
  deck. Three Ø8 holes through the lid, their mouths rounded: one 16 out
  from each bottle on its outer side for the nutrient tube, and a third
  at the rear, midway between the other two.
- **Wall boards.** The ULN2003 stands in two slotted ribs on the right
  wall and the buck in two on the left, beside the cups, dropped in from
  above with the lid off; the boards rest on the slots' floors just off
  the body's floor, components inward.
- **Vents.** Seven rounded slots, 40 × 2, in each side wall beside the
  motors, at 5 mm pitch from 12 up.
- **Faceplate.** A black plate, 3 thick, 96 × 59, centred on the front
  and flush with it, its edge and the opening's edge rounded 1 so the
  seam is a soft groove. Four M3 × 8 at its corner-radius centres into
  inserts in a 12 mm band behind the wall. On its back: the OLED slides
  down two slots into a glass channel and rests on a ledge, the window
  the size of its picture; the KY-040 sits between two ribs, its nut on
  the floor of a Ø38 × 2 recess, and the Ø36 knob hides the nut in a
  pocket in its base, sits 0.5 off the recess floor, and stops on the
  shaft's end (the KY-040's 20 mm shaft cut to 13.5 above the pcb, so
  the knob is only 7.5 thick); behind those, 13 off the plate, the DevKit lies along the
  plate with its module toward it and its pin rows pointing back, its
  short edges (the ones without headers) dropped into a cage: two
  vertical slotted rails, 4 thick, tied by a bar along the bottom, the
  right rail on a full-height post just inside the band's opening, the
  left rail tied at its top to the screen's left rib by a 9 × 12 arm
  behind the screen's way in, so the load runs in one loop through the
  plate. Fit all three, then screw the plate on.
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
and the grommet; the DevKit in its rails, the wall boards in their
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
