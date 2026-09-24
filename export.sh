#!/bin/zsh
# Every printed piece into stl/, each as it prints (as it stands, no supports).
# Print two sleeves (for the 125 mL bottles), three covers, one spout.
cd "$(dirname "$0")"
mkdir -p stl
for p in tray_dock tray_col plate column sleeve cover spout; do
  openscad -o stl/$p.stl -D "part=\"$p\"" hydro-doser.scad 2>&1 | grep -E "WARNING|ERROR" && exit 1
  echo "  stl/$p.stl"
done
openscad -o mockup.stl hydro-doser.scad 2>&1 | grep -E "WARNING|ERROR" && exit 1
echo "  mockup.stl (the whole unit, to look at)"
