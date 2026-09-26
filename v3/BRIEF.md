# Hydro Doser v3, the brief

No geometry, no code. This is everything a clean design starts from: the
parts it has to fit, the printer it has to come off, and the rules it has
to keep. Nothing from v1 or v2 carries over except these numbers.

## 1. Bought parts, measured

Marked *(est.)* where the number came from a listing or a drawing rather
than calipers. Measure those before the first print.

### The tank: Cambro CamSquare 6 qt, 6SFSPP190

| | mm |
|---|---|
| outside at the rim | 213 × 213 |
| outside at the base | 195 × 195 *(est.)* |
| height | 184 |
| corner radius | 14 *(est.)* |
| rim, wall thickness | ~2 *(est.)* |

The unit does not sit on the tank. It stands on its own feet and can be
used with any reservoir, or none; the water inlet leaves through the
back with the outlets.

### Pumps: INTLLAB 12 V peristaltic, three of them

| | mm |
|---|---|
| head | Ø38 × 23 long |
| flange (diamond) | 55 wide × 41 tall × 3 thick |
| flange hole pitch | 48.5 |
| flange holes | Ø3.2 |
| motor | Ø27 × 44 long |
| nozzles | two, 10 off the head's face, 16 apart |
| tube | silicone, 3 ID × 5 OD |

The motor goes through the wall; the flange sits on the wall and takes
two M3 screws; the head and its two nozzles stay on the accessible side.
The tube loops off the two nozzles and needs about 30 mm of room beyond
the head.

### Electronics

| Board | mm | Notes |
|---|---|---|
| ESP32 DevKitC | 55 × 28 | pin headers down, 8.5 tall; USB on a short end |
| ULN2003 driver | 35 × 32 | ~15 tall with its header |
| 12 → 5 V buck | 45 × 20 × 12 | |
| KY-040 encoder | pcb 31 × 19 × 1.6 | body 6.5 above the pcb; threaded bushing (M7) to 11.5; D shaft Ø6, flat at 4.5, to 20 (cut to 13.5 for the thin knob); shaft centre 9.5 from the pcb's top edge |
| 0.96" OLED | pcb 27.3 × 27.8 × 1.6 | glass 26.7 × 19.3 × 1.5, centred 0.75 below the pcb's centre; active area 21.7 × 10.9, centred 1.45 above; 4 pins on the top edge |

### Panel hardware

| | hole |
|---|---|
| 5.5 × 2.1 DC jack | Ø11.5 |
| GX12-6 (float switch + probes) | Ø12.2 |
| grommet for the sleeved bundle (3 tubes + float lead) | Ø16 |

### Fasteners and the rest

| | mm |
|---|---|
| M3 heat-set inserts | hole Ø4, 5 deep |
| M3 self-tappers (flanges) | pilot Ø2.6 |
| nutrient bottles, 125 mL, two | Ø48 (measured) × 122 *(est.)* |
| garden reservoir rim (for the spout) | 4 thick, 30 drop *(est.)* |

## 2. Layout rules

- Every screw hole and every foot sits at the centre of its corner's
  radius. Never near an edge.
- As compact as the parts allow.
- The pumps mount as in the first design: rolled 42° about their axes,
  so the flange's two holes sit on a 42° line.

## 3. Printer

- Bambu P1S: 256 × 256 × 256 usable. Every piece fits flat on that bed.
- PETG. No supports. Each piece prints in the orientation it is exported
  in, and the export says which face is down.
- Overhangs at or under 45°, or chamfered to get there. Bridges under
  40 mm. Every piece keeps at least ~6 % of its footprint on the bed.
- Clearances: 0.2 on a magnet pocket, 0.3 on a through-hole for a bought
  part, 0.4 on a sliding fit.

## 4. What it has to do

1. One printed enclosure on its own feet, the floor and the walls one
   piece, with standard foot pads (snap-in TPU pads) under the floor. No
   tank features. Anything that goes to a tank goes out the back.
2. Three pumps in a row, evenly spaced, heads toward one side, reached
   by taking the lid off. No side panel.
3. Ports in the back: the 12 V jack and the GX12-6 low, spaced between
   the three pumps; the grommet the outlet tubes and the float lead leave
   through above. The driver and the buck mount on the inner side walls
   in the bottles' section. Vent slots, as on a router, in both side
   walls beside the motors.
4. A faceplate carries the controls, the screen left of the knob and
   close to it, with even spacing around the knob. The screen, the knob
   and the ESP32 mount to the faceplate, the ESP32 behind the other two; the faceplate screws into the body with
   M3 countersunk screws into heat-set inserts, flush with the body, the
   seam chamfered on both sides.
5. The screen is flush, mounted from behind, with a window the size of
   its picture. The knob is Ø36, countersunk into the face, diamond-
   knurled on the exposed part, chamfered after the knurl.
6. The two 125 mL bottles stand inside the body in cup-holder cutouts in
   the lid, in the middle of the front. No holders, clips or brackets of
   any kind.
7. The lid snaps on, the same size as the body, flush: no shadow line.
   The faceplate is the only screwed piece.
8. Every 90° is filleted and every edge rounded. The body's vertical
   faces carry a fuzzy-skin texture band; the faceplate does not.
9. The bottles' tubes pass through plain holes in the lid, 16 mm out from
   each bottle, on its outer side: no channels on the cups. A third hole
   of the same kind at the lid's rear edge, midway between the other two.
10. The wiring stays as built: ULN2003 IN1/2/3 from GPIO25/26/27; right
   pump Nutrient B, middle Nutrient A, left Water; +V chained to the pump
   + terminals; jumper on; 12 V to the board when the jack arrives.
   Reserve GPIO21/22 for the OLED and 18/19/23 for the encoder.

## 5. To measure before the first print

- The bottles' height and the cap's diameter.
- The reservoir's rim: thickness and drop.
- The pump: confirm the nozzle spacing and flange from the part in hand.
