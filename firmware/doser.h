#pragma once
// Pump indexes, shared by every lambda in hydro-doser.yaml. The order is the
// order of the outputs array those lambdas build: out_sprout, out_thrive,
// out_water, out_transfer.
#include <string>

static const int PUMP_SPROUT = 0;
static const int PUMP_THRIVE = 1;
static const int PUMP_WATER = 2;
static const int PUMP_TRANSFER = 3;

static const char *const PUMP_NAMES[4] = {"Nutrient A", "Nutrient B", "Water", "Transfer"};

// Longest single pump run. A mix-tank fill needing more than this is refused
// rather than cut short, since cutting it short would throw off the ratio.
// A transfer is clamped instead. At 100 mL/min, 45 min is 4.5 L.
static const uint32_t MAX_RUN_MS = 45UL * 60UL * 1000UL;

// "sprout" / "Nutrient B" / "water" / "transfer" -> index, or -1.
static int pump_index(const std::string &name) {
  for (int i = 0; i < 4; i++) {
    const char *a = PUMP_NAMES[i];
    const char *b = name.c_str();
    while (*a && *b && tolower(*a) == tolower(*b)) { a++; b++; }
    if (!*a && !*b) return i;
  }
  return -1;
}
