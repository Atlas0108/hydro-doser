#!/bin/zsh
# Every printed piece into stl/, each as it prints (as it stands, no supports).
# Print two sleeves (for the 125 mL bottles), three covers, one spout, two
# button caps. The
# column is also in stl/two-colour/ as its green floor and white towers.
cd "$(dirname "$0")"
mkdir -p stl
for p in tray_dock tray_col plate column sleeve cover spout panel_plate button_cap; do
  openscad -o stl/$p.stl -D "part=\"$p\"" hydro-doser.scad 2>&1 | grep -E "WARNING|ERROR" && exit 1
  echo "  stl/$p.stl"
done
mkdir -p stl/two-colour
for p in column_floor column_towers; do
  openscad -o stl/two-colour/$p.stl -D "part=\"$p\"" hydro-doser.scad 2>&1 | grep -E "WARNING|ERROR" && exit 1
  echo "  stl/two-colour/$p.stl"
done
openscad -o mockup.stl hydro-doser.scad 2>&1 | grep -E "WARNING|ERROR" && exit 1
echo "  mockup.stl (the whole unit, to look at)"
