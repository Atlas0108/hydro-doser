# Hydro Doser v3 firmware

ESPHome on an ESP32 DevKitC. A 0.96" OLED and a KY-040 knob on the
faceplate drive a menu, so it works without a phone: turn to choose, click
to open, click to run, hold to go back. Three 12 V peristaltic pumps
through a ULN2003. Home Assistant sees it as a device with three pump
switches, a Cancel button, a Status text, a flow-rate number per pump, and
`dose` and `cancel` actions. Whatever Home Assistant starts shows on the
screen the same as a knob-started run: the countdown and the cancel
button, or the manual page with a stop button.

## Setting it up

A unit built with its owner's networks in `secrets.yaml` joins them on
its own. Built with the secrets left empty, nothing is baked in: plug it
in, and the title band says "set up wifi" until it is on a network. Two
ways, both local, and they are also the fallback if the built-in network
is not found after a minute:

1. Open the Home Assistant app on a phone near it. It finds "Hydrohomie"
   over Bluetooth and asks for the Wi-Fi network and password.
2. Or join the open Wi-Fi network "Hydrohomie" the doser raises; a page
   pops up to enter the network and password.

Once it is on the network, Home Assistant lists it under Discovered on
the integrations page; click Add. No key to paste.

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
| Knob GND | GND | |
| Knob + | 3V3 | |
| Knob SW | GPIO23 | the push button, pulled up in firmware |
| Knob DT | GPIO19 | encoder B |
| Knob CLK | GPIO18 | encoder A |

If the knob turns the wrong way, swap CLK and DT, or swap `pin_a` and
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

## Flashing

```sh
esphome run hydro-doser-v3.yaml --device /dev/cu.usbserial-110    # over USB (the CH340 port on this Mac)
esphome run hydro-doser-v3.yaml --device hydro-doser-v3.local     # over the air after that
esphome logs hydro-doser-v3.yaml --device /dev/cu.usbserial-110   # watch it
```

`secrets.yaml` holds only the OTA password now, for `esphome run` over
the air; it is gitignored. Copy `secrets.yaml.example` and fill it in.

## The menu

```
  Hydrohomie  click ->   Dose A        click ->   Dose A, 25 ml
  > Dose A               > 5 ml                   12 s left
    B                      10 ml                  click to cancel
    C                      25 ml
    ABC                    50 ml
                           Manual       hold ->   A running
                                                  release to stop
```

Turn: move the highlight. Click: open the dose, then run the quantity,
and while it runs, click again to cancel; a run started from Home
Assistant shows the same pages and a click stops it too. On the
quantities, scroll up
past the first item to highlight the title band as Go back and
click it, or hold (0.8 s), to go back. On
Manual, the pump runs from the moment the button goes down until it is
released; on ABC's Manual all three run together. A timed ABC runs A,
then B, then C, each for the chosen quantity.
