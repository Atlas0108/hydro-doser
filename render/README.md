# Renders and pages

Source for the exploded-view page, the product page and the Blender
explosion. Frames, part STLs for the viewer and the MP4 are outputs and are
not kept here; regenerate them.

| File | What |
|---|---|
| `doser.py` | Blender 5.2 scene: imports the part STLs (each bought part as its own pieces), matte olive PETG, a dark studio, animated screws, and renders the explosion as a 96-frame WebP sequence plus a hero still. `--device CPU\|METAL\|HIP`, `--test` renders four check frames. |
| `encode.py` | Blender's FFmpeg: frames → MP4, forward, hold, reverse, hold. |
| `viewer.html` | The interactive exploded view (three.js). Expects `parts/<name>.txt`: base64 binary STLs, one per part instance. |
| `product.html` | The product page. Expects `frames/f001..f096.webp` and `frames/hero.webp`. |

```sh
# part STLs for the viewer / Blender, one per instance (see the scad's output section)
openscad -o parts/column.stl --export-format=binstl -D 'part="piece"' -D 'idx=3' ../hydro-doser.scad
# full render on node-01 (32-thread CPU, ~40 s a frame at 64 samples)
blender -b -P doser.py -- --device CPU --frames 96 --samples 64 --parts parts --out frames
blender -b -P encode.py -- frames hydro-doser-explosion.mp4
```
