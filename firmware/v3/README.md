# Hydro Doser v3 firmware

ESPHome on an ESP32 DevKitC. A 0.96" OLED and a KY-040 knob on the
faceplate drive a menu, so it works without a phone: turn to choose, click
to open, click to run, hold to go back. Three 12 V peristaltic pumps
through a ULN2003. Home Assistant sees it over the API as well.

This first cut is the menu only. The pumps are not wired in the firmware
yet: running a dose shows the page and logs.

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

Pumps, for the next step (the ULN2003's IN pins; its + and its jumper as
in the first design):

| From | To ESP32 |
|---|---|
| ULN2003 IN1 | GPIO25, pump 0, Nutrient A (right) |
| ULN2003 IN2 | GPIO26, pump 1, Water (middle) |
| ULN2003 IN3 | GPIO27, pump 2, Nutrient B (left) |
| ULN2003 - | GND |

## Flashing

```sh
esphome run hydro-doser-v3.yaml --device /dev/cu.usbserial-110    # over USB (the CH340 port on this Mac)
esphome run hydro-doser-v3.yaml --device hydro-doser-v3.local     # over the air after that
esphome logs hydro-doser-v3.yaml --device /dev/cu.usbserial-110   # watch it
```

`secrets.yaml` (Wi-Fi, API key, OTA password) is gitignored; copy
`secrets.yaml.example` and fill it in.

## The menu

```
  > Dose A          click ->   Dose A            click ->   Dose A
    Dose B                     click to run                 dosing...
    Dose C                     hold to go back              hold to stop
    Dose ABC
```

Turn: move the highlight. Click: open the item. Click again: run it.
Hold (0.8 s): back to the menu, and later, stop the pumps.
