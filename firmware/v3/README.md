# Hydro Doser v3 firmware

ESPHome on an ESP32 DevKitC. A 0.96" OLED and a KY-040 knob on the
faceplate drive a menu, so it works without a phone: turn to choose, click
to open, click to run, turn up past the top to go back. Three 12 V peristaltic pumps
through a ULN2003. Home Assistant sees it as a device with three pump
switches, a Cancel button, a Status text, a flow-rate number per pump, and
`dose` and `cancel` actions. Whatever Home Assistant starts shows on the
screen the same as a knob-started run: the countdown and the cancel
button, or the manual page with a stop button.

## Setting it up

Nothing is baked in: no network, no password, no key. Plug it in and
set it up on a network. Two ways,
both local:

1. Open the Home Assistant app on a phone near it, with Bluetooth
   allowed. It finds "hydro-doser-v3" over Bluetooth (Improv) and asks
   for the Wi-Fi network and password. Any Improv client works the same
   way; the unit here was set up from a Mac with a 40-line Python script.
2. Or join the open Wi-Fi network "Hydrohomie" the doser raises; a page
   pops up to enter the network and password.

Once it is on the network it remembers it, and Home Assistant lists it
under Discovered on the integrations page; click Add. No key to paste.
If Home Assistant runs in Docker on a Mac with port mapping, as on the
iMac here, it cannot see mDNS and will not discover anything: add the
ESPHome integration by hand with the host `hydro-doser-v3.local` (or its
address) and port 6053. To make a unit forget its network, erase the
`nvs` partition (`esptool erase_region 0x390000 0x70000`) or hold no
network: the set-up modes come back.

A dose's time is ml divided by the pump's flow rate. The rates default to
100 mL/min; calibrate each pump (run 50 ml into a measuring cup, adjust
the number in Home Assistant) before trusting the quantities.

## Wiring

Everything on the faceplate's back. The OLED's four pins face into the
box; the knob's five pins point down.

| From | To ESP32 | Notes |
|---|---|---|
| OLED GND | GND | |
| OLED VCC | 3V3 | the 0.96" SSD1306 boards run on 3.3 V |
| OLED SCL | GPIO22 | I2C clock |
| OLED SDA | GPIO21 | I2C data |
| Knob CLK | GPIO19 (D19) | encoder |
| Knob DT | GPIO18 (D18) | encoder |
| Knob SW | GPIO5 (D5) | the push button, pulled up in firmware |
| Knob + | GPIO17 (TX2) | driven high at boot: its 3.3 V |
| Knob GND | GPIO16 (RX2) | driven low: its ground |

The knob's five pins, CLK, DT, SW, + and GND, land on D19, D18, D5, TX2
and RX2, which sit side by side on the DevKit V1's header, so its plug
goes on in one piece with CLK on D19. The two pins at the end power it;
it draws about 1 mA. If it turns the wrong way, swap `pin_a` and
`pin_b` in the yaml. The OLED's address is 0x3C; if the screen stays dark
and the log says no device at 0x3C, it is the 0x3D kind: change `address`.

Pumps, through the ULN2003 (its + and its jumper as in the first
design). The menu's A, B, C are Nutrient A, Nutrient B, Water:

| From | To ESP32 | Menu |
|---|---|---|
| ULN2003 IN1 | GPIO25 | A, Nutrient A, the right pump |
| ULN2003 IN2 | GPIO26 | C, Water, the middle pump |
| ULN2003 IN3 | GPIO27 | B, Nutrient B, the left pump |
| ULN2003 - | GND | |

The Gravity TDS (or pH V2) signal board, on its 3-pin plug. Its three
wires go on three neighbouring header pins, so the plug stays in one
piece: the two pins beside the signal pin are driven as the board's
supply and ground (it draws a few mA). The pins are all 3.3 V, and
GPIO35 is on ADC1, which reads with Wi-Fi on.

| TDS board | To ESP32 | Notes |
|---|---|---|
| A (signal) | GPIO35 | analog in, 0 to 2.3 V |
| + | GPIO32 | driven high at boot: 3.3 V |
| - | GPIO33 | driven low: ground |

On the 30-pin DevKit V1 these three sit together on the header, VN
side: ... D34, **D35, D32, D33**, D25 ... Plug the lead so its A wire lands
on D35.

The pH board (the common PH-4502C type, 42 × 32, the one sold with a BNC
probe) needs 5 V, and its Po output reaches about 5 V at the acid end:
too much for an ESP32 input. So Po goes through a divider, 10 kΩ from Po
to GPIO34 and 20 kΩ from GPIO34 to ground, which scales 5 V to 3.3 V;
the firmware multiplies back by 1.5.

| pH board | To | Notes |
|---|---|---|
| Po | 10 kΩ, then GPIO34 | 20 kΩ from GPIO34 to GND |
| V+ | 5 V (VIN, or the buck's OUT+) | |
| G | GND | either G |
| Do, To | — | unused |

The float switch goes between GPIO14 and GND; the firmware pulls GPIO14
up. **Mount it so its contact is closed while the water is up at the
float** (flip the float on its stem to change which way it works). Then
an open contact, from low water or a broken or unplugged lead, reads
**Reservoir low**, so dosing can be blocked on it safely.

The TDS probe and the float come in through the GX12-6 in the back
wall. Cut the TDS probe's plug off and wire the board's probe input to
the GX12 socket instead:

| GX12 pin | Wire | Goes to |
|---|---|---|
| 1 | green | TDS board's probe input (either way round with pin 2) |
| 2 | yellow | TDS board's probe input |
| 3 | white | unused |
| 4 | blue | unused |
| 5 | none recorded | float switch: GPIO14 |
| 6 | black | float switch: GND |

Pin numbers are as seen on the connector's front (mating face), key at
the top: pin 1 at the bottom right, 2 to 5 running anticlockwise round
the ring, 6 in the centre. Wire colours recorded 2026-09-27, before the
pins were buzzed through.

The pH probe keeps its stock cable, uncut. It comes in through its own
hole in the back wall, beside the GX12, and its BNC plugs straight into
the pH board. The pH board is no longer on the faceplate; keep it and
the cable away from the pump wires, since the probe's signal is very
high impedance.

The probes share the reservoir, and the TDS board's excitation current
upsets the pH probe. So the doser reads them in turn, every 30 s: TDS
first, then it switches the TDS board off (it is powered from two GPIOs
for exactly this), waits 3 s, reads pH, and switches the TDS board back
on to settle before its next reading. Both readings update every 30 s.

pH is two-point calibrated. Put the probe in pH 7 buffer and press
**Calibrate pH 7**; rinse it, put it in pH 4 buffer and press
**Calibrate pH 4**; each button takes a fresh reading, with the TDS
board off, before it saves. The two settings, pH 7 voltage and pH slope, can
also be set by hand.

Home Assistant gets TDS in ppm, the raw TDS voltage (diagnostic), and
two settings: Water temperature, which the reading is compensated to
25 °C with (there is no temperature probe yet, so set it), and TDS
calibration, a factor to trim the reading against a known solution.
The conversion is DFRobot's: the voltage over 1 + 0.02 × (T - 25), then
(133.42 v³ - 255.86 v² + 857.39 v) × 0.5 × the factor.

**Nutrient level** reads Low, Nominal or High against a reading marked
as nominal: the Rise reservoir dosed to spec read 592 ppm on
2026-09-26, and that is the default. It goes Low below nominal minus
the **TDS band** (10 % by default) and High above nominal plus it, with
2 % of hysteresis so it doesn't flicker at the edge. After a fresh fill
dosed to spec, press **Mark TDS nominal** to take the current reading
as the new nominal. When the probe reads 0 (dry or unplugged) the level
is "No reading", so an auto-doser built on it never doses on a dead
probe.

## Flashing

```sh
esphome run hydro-doser-v3.yaml --device /dev/cu.usbserial-110    # over USB (the CH340 port on this Mac)
esphome run hydro-doser-v3.yaml --device hydro-doser-v3.local     # over the air after that
esphome logs hydro-doser-v3.yaml --device /dev/cu.usbserial-110   # watch it
```

There is no `secrets.yaml`: the firmware has no secrets.

## In a dashboard

`dashboard-section.yaml` is a ready-made section for a Home Assistant
sections dashboard: Status, Cancel, the dose buttons at 5, 10, 25 and
50 ml for A, B, C and ABC, the manual pump switches and the flow rates.

## The menu

Home lists Dose A, Dose B, Dose C, Dose ABC and Settings.

```
  Hydrohomie  click ->   Dose A        click ->   Dose A, 25 ml
  > Dose A               > 5 ml                   12 s left
    B                      10 ml                  click to cancel
    C                      25 ml
    ABC                    50 ml
                           Manual       hold ->   A running
                                                  release to stop
```

Settings holds PIN, Autolock and Reset. PIN sets a four-digit PIN: turn
to pick each digit, click to move on; 0000 clears it. Autolock (Off,
1 min, 5 min) locks the screen after that long without a touch, and needs
a PIN first: chosen without one it says "Set a PIN first". A locked
screen asks for the PIN before the menu is usable; Home Assistant is not
affected. Reset, after a confirmation, forgets the network, the PIN and
the settings and reboots into set-up.

Turn: move the highlight. Click: open the dose, then run the quantity,
and while it runs, click again to cancel; a run started from Home
Assistant shows the same pages and a click stops it too. To go
back from any menu, turn up past the first item to highlight the title
band as Go back and click it; on PIN entry, turn back past 0 on the
first digit. Holding the button never goes back. On Manual, the pump
runs from the moment the button goes down until it is released; on
ABC's Manual all three run together. On the home screen, a 3 s hold
turns the screen off; a click turns it back on and does nothing else,
and the knob does nothing while it is off. The doser keeps working with
the screen off, and a dose started from Home Assistant turns it back on
to show the countdown, then off again when the run ends or is cancelled
(unless the knob was touched meanwhile). A hold anywhere else does nothing. A timed ABC runs A,
then B, then C, each for the chosen quantity.
