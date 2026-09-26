# Render

The Blender explosion of v3. Frames, the part STLs and the MP4 are
outputs and are not kept here; regenerate them.

| File | What |
|---|---|
| `doser-v3.py` | Blender 5.2 scene: imports the parts exported in assembly position, matte olive PETG, a black plate, the burnt-orange knob, a dark studio, and renders a basic explosion (every part slides straight out, together, the wall boards staying put) as a 96-frame WebP sequence plus a hero still. `--device CPU\|METAL\|HIP`, `--test` renders three check frames. |
| `routes.py` | The tubes and the faceplate's heat-set inserts as routes in model mm, each point riding with the part it is attached to; `python3 routes.py > routes.json`. The scene and the exploded-view page both read `routes.json`. |
| `encode.py` | Blender's FFmpeg: frames to MP4, forward, hold, reverse, hold, 24 fps. |

```sh
# the parts, one STL each in assembly position
for p in body_at:body lid_at:lid deck:deck plate_at:plate knob_at:knob cap:cap feet:feet screws:screws encoder:encoder oled:oled ports:ports; do
  openscad -o parts/${p#*:}.stl --export-format binstl -D "part=\"${p%:*}\"" ../hydro-doser-v3.scad; done
for i in 0 1 2; do for p in pump board; do openscad -o parts/$p$i.stl --export-format binstl -D "part=\"$p\"" -D "idx=$i" ../hydro-doser-v3.scad; done; done
for i in 0 1; do openscad -o parts/bottle$i.stl --export-format binstl -D 'part="bottle"' -D "idx=$i" ../hydro-doser-v3.scad; done
# on node-01 (32 threads, about 8 s a frame at 64 samples)
python3 routes.py > parts/routes.json
blender -b -P doser-v3.py -- --device CPU --frames 96 --samples 64 --parts parts --out frames
blender -b -P encode.py -- frames hydro-doser-v3-explosion.mp4
```
