# Hydro Doser → mixes nutrient water and tops off the garden

An ESP32 running ESPHome (`hydro-doser.yaml`), with four 12 V peristaltic
pumps (INTLLAB 4-pack) switched by two ULN2003 boards.

**Status: firmware written and compiling. Hardware not built yet.**

```
 Nutrient A bottle ──[Nutrient A]──┐
 Nutrient B bottle ──[Nutrient B]──┤
 water jug     ──[Water]───┴──►  mix tank  ──[Transfer]──►  reservoir
                                                              (float switch)
```

The reservoir only ever gets something from the mix tank: plain water
(*Mix Water Batch*) or nutrient water (*Mix Nutrient Batch*). Nutrient never
goes straight into the garden, and Nutrient A and Nutrient B never touch each other
undiluted.

## Parts

| | |
|---|---|
| ESP32 dev board | any ESP32-WROOM DevKit (`board: esp32dev`) |
| 4 × peristaltic pump | INTLLAB 12 V DC, 5–100 mL/min. The motor must stay dry: mount the pumps above the tanks. |
| 2 × ULN2003 board | the ones from the stepper kits, jumper set to 5–12 V |
| 12 V supply | 12 V, 2 A or more |
| 12 V → 5 V buck | powers the ESP32 from the same supply |
| Float switch | in the reservoir, at the fill line |
| Mix tank | anything with a lid. Set *Mix Tank Capacity* to match. |
| Silicone tubing | to fit the pump barbs, plus spares: pump tubing wears out |

## Wiring

| ESP32 | goes to | |
|---|---|---|
| GPIO25 | board A IN1 **and** IN2 | Nutrient A |
| GPIO26 | board A IN3 **and** IN4 | Nutrient B |
| GPIO27 | board B IN1 **and** IN2 | Water |
| GPIO32 | board B IN3 **and** IN4 | Transfer |
| GPIO33 | float switch → GND | reservoir full |
| GND | both boards' −, buck −, 12 V − | **common ground, required** |
| VIN (5V) | buck 5 V out | |

Each pump uses two channels in parallel, so there's plenty of current margin.
On each board, the pump's **+** goes to the board's **+** pin (12 V). Its
**−** goes to both OUT pins on the white connector for its two channels.
The ULN2003 has flyback diodes built in. If the ESP32 resets when a pump
starts, solder a 100 nF capacitor across that motor's terminals.

**The float switch has to be fail-safe.** Mount it so the contact is **closed
while the water is below it**. Most float switches flip over to change which
way they work. An open circuit reads *full*: an unplugged or broken switch
blocks transfers rather than letting the pump run until the reservoir
overflows. With no float wired, *Transfer to Reservoir* does nothing, by design.

## Calibrate before first use

The pumps are rated "up to 100 mL/min". The real rate depends on the tubing
and on the ~1 V the ULN2003 drops, so measure it:

1. Put the pump's inlet in its liquid and its outlet in a measuring cup.
2. Choose it in *Calibrate Pump*, then press *Run Pump 60 s*. The first run
   also primes the tube, so empty the cup and run it a second time.
3. Enter the mL it moved as that pump's *Flow* (mL/min).

Recalibrate every few months. As the tubing wears, the flow drops.

## Use

1. Set **Nutrient A Dose** and **Nutrient B Dose** (mL per liter of water) from the nutrient maker's
   feeding directions. Both start at 0. Set Nutrient A back to 0 once the plants
   no longer need it.
2. **Mix Nutrient Batch** or **Mix Water Batch** fills the mix tank with
   *Batch Size* liters: 80% of the water, then Nutrient A, then Nutrient B, then the
   last 20% of the water to rinse the lines and stir the tank. The whole batch
   is checked first: if it won't fit in the tank or needs too long a run, it
   doesn't start.
3. **Transfer to Reservoir** pumps up to *Transfer Amount* liters (0 means all of
   it) into the garden. It stops early if the float trips or the mix tank
   runs out.
4. **Stop** stops everything. A run that was cut short still counts toward the
   mix tank.

**Status** shows the last thing the doser did or refused. **Nutrient A Used** and
**Nutrient B Used** count up from the last *Bottle Refilled* press.

The same things are available as HA actions, for automations:
`esphome.hydro_doser_dose` (`pump`: sprout/thrive/water/transfer, `ml`),
`esphome.hydro_doser_make_batch` (`liters`, `nutrients`),
`esphome.hydro_doser_transfer` (`liters`, 0 = all).

## How it keeps count, and its limits

Nothing measures the mix tank. **Mix Tank Volume** is flow rate × run time,
kept across reboots. If it drifts (spills, hand-filling, a bad calibration),
empty the tank and press *Mix Tank Emptied*.

- Only one pump runs at a time. Commands wait in a queue.
- A single run is capped at 45 min (4.5 L at 100 mL/min). A fill needing more
  than that is refused; a transfer stops at the cap and leaves the rest.
- A dry water jug isn't detected. Peristaltic pumps survive running dry, but
  the count will then overstate what's in the tank.
- At ~100 mL/min, a 2 L batch takes about 20 min, and so does the transfer.
