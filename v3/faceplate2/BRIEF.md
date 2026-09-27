# Faceplate 2: brief

A new faceplate for the Hydro Doser v3 that carries every board itself:
no adapters, no parts on the body. Nothing is drawn until this is agreed.

## Fixed: it must fit the body as printed

| What | Value |
|---|---|
| Outline | 176.4 × 59.4, 3 thick, 8 mm corner radius, face edge rounded 1 |
| Screws | four M3 × 8 countersunk at the corner-radius centres, into the inserts already in the body |
| Opening in the band behind the wall | 152.4 × 35.4 (x 24.8 to 177.2, z 19.3 to 54.7): anything within 6 of the plate's back must stay inside it |
| Depth behind the plate | the bottle cups start 31 behind the plate at their nearest; nothing may reach them |
| Body | unchanged, no reprint |

## The parts it carries

| Part | Size | How it mounts |
|---|---|---|
| OLED 0.96" (SSD1306) | pcb 27.3 × 27.8, glass 26.7 × 19.3 | drops into a pocket from behind, 0.3 clear each side, 0.2 top and bottom; window the size of the picture |
| KY-040 encoder | pcb 31 × 19, 14 tall off the plate | bushing through the plate with its nut in the knob's recess; its pins out of its short edge toward the ESP32; one rib on the far side stops it turning |
| Knob | Ø36 × 9.5, brown-red ring, black cap | as now |
| ESP32 DevKit V1, 30-pin | 51.5 × 28.3 | four standoffs, M2.5 self-tappers, module toward the plate |
| DFRobot Gravity TDS board | 42 × 32 | four standoffs, M3 self-tappers |
| pH board (PH-4502C type) | 42 × 32 | four standoffs, M3 self-tappers |

Hole spacings for the three boards are still assumed (DevKit 46.9 × 23.7,
the two 42 × 32 boards 35 × 25). Measure them before this is drawn.

## Layout

Seen from the front, left to right: **screen, ESP32, knob.** The ESP32 is
hidden behind the plate, so the face shows the screen on the left and the
knob on the right, each the same distance from the plate's centre, with
the ESP32 between them behind.

The pH board stands on taller standoffs directly over the knob's
encoder. The TDS board cannot stand over the screen: the left bottle cup
sits right behind it, and the screen's plug alone reaches 27 of the 31
available. It mounts instead on a fin standing off the plate's back at
the screen's end, outside the cup, printed with the plate. The ESP32's
middle stays open for the wiring to converge on its headers.

Built as `faceplate2.scad` (it uses the v3 model for the body, the knob
and the wall boards); `./verify.sh` checks it against them and writes
`../stl/faceplate2.stl`, face down.

## Rules

- One radius family: 8 at the plate's corners, 1.5 on every standoff's
  fillet into the plate.
- Every standoff, rib and pocket backed by a part; nothing decorative.
- Every plug reaches its ESP32 pins in one piece: the knob's 5-pin plug,
  the TDS board's 3-pin plug, the screen's 4-pin plug.
- Prints face down, no supports.

## Open questions

1. **Spacing on the face:** screen and knob each 45 mm from the centre
   (the default), or pushed out toward the ends?
2. **The two sensor boards:** over the screen and the knob (the default),
   or stacked behind the ESP32?
3. **Measurements:** the hole spacings of the DevKit, the TDS board and
   the pH board.
