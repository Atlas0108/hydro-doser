#!/bin/zsh
# Writes each piece into stl/ in its print orientation, and mockup.stl of the unit.
set -e
cd "$(dirname "$0")"
mkdir -p stl
setopt nullglob; rm -f stl/*.stl
for p in body lid plate knob foot spout; do
  echo "  $p"; openscad -q -o stl/$p.stl --export-format binstl -D "part=\"$p\"" hydro-doser-v3.scad
done
echo "  fuzz (a slicer modifier, not a print)"; openscad -q -o stl/fuzz-modifier.stl --export-format binstl -D 'part="fuzz"' hydro-doser-v3.scad
echo "  mockup"; openscad -q -o mockup.stl --export-format binstl -D 'part="all"' -D '$fn=32' hydro-doser-v3.scad
