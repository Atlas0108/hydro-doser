#pragma once
// The three pumps as the menu numbers them: 0 A (Nutrient A, IN1), 1 B
// (Nutrient B, IN3), 2 C (Water, IN2). Included by hydro-doser-v3.yaml.
#include "esphome.h"

// out_a, out_b, out_c are the yaml's outputs: main.cpp declares them before it includes this.

static void pump_on(int p, bool on) {
  esphome::gpio::GPIOBinaryOutput *const outs[3] = {out_a, out_b, out_c};
  if (p < 0 || p > 2) return;
  if (on) outs[p]->turn_on(); else outs[p]->turn_off();
}

// which: 0..2 one pump, 3 all three (Manual on ABC runs them together)
static void pumps_on(int which, bool on) {
  if (which == 3) { for (int p = 0; p < 3; p++) pump_on(p, on); }
  else pump_on(which, on);
}
