# Hydro Doser: build the scene from the exported part STLs, light it as a
# studio product shot, and render the explosion as a frame sequence for a
# scroll-driven page background.
#
#   Blender -b -P doser.py -- --frames 96 --samples 64 --out /path/frames [--test]
#
# Model coordinates are mm, z up. Blender is metres, z up, so parts are
# scaled 0.001 in place. Explode offsets and step windows mirror the viewer.
import bpy, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return type(default)(argv[argv.index(name) + 1]) if name in argv else default
FRAMES  = arg('--frames', 96)
SAMPLES = arg('--samples', 64)
OUT     = arg('--out', '/tmp/doser-frames')
TEST    = '--test' in argv
DEVICE  = arg('--device', 'METAL')          # METAL | HIP | CPU
PARTS   = arg('--parts', '/private/tmp/claude-501/-Users-seananderson-Development-homeassistant/6f282076-ec75-430c-8b5d-29f7ab08b6c4/scratchpad/viewer/parts')
os.makedirs(OUT, exist_ok=True)

# [file, material, explode offset (mm), step window (t0, t1)]
S = 0.001
PARTS_LIST = [
  ('tray_dock', 'green', (-60, 0, 0), (0.875, 1)), ('tray_col', 'green', (60, 0, 0), (0.875, 1)),
  *[(f'pump{k}_{sp}', m, (0, 0, 95), (0.75, 0.875)) for k in range(3) for sp, m in
    [('head', 'pump'), ('cover', 'clear'), ('rollers', 'grey'), ('flange', 'black'), ('motor', 'silver'), ('cap', 'black'), ('barbs', 'grey')]],
  *[(f'esp32_{sp}', m, (0, 0, 60), (0.625, 0.75)) for sp, m in [('pcb', 'pcb_dark'), ('can', 'silver'), ('usb', 'silver'), ('pins', 'black'), ('small', 'black')]],
  *[(f'uln{j}_{sp}', m, (0, 0, 60), (0.625, 0.75)) for j in (1,) for sp, m in
    [('pcb', 'pcb_green'), ('chip', 'black'), ('hdr', 'white'), ('pins', 'black'), ('leds', 'red'), ('res', 'beige')]],
  ('buck_body', 'black', (0, 0, 60), (0.625, 0.75)), ('buck_wire0', 'red', (0, 0, 60), (0.625, 0.75)), ('buck_wire1', 'black', (0, 0, 60), (0.625, 0.75)),
  ('dose', 'black', (0, -60, 0), (0.625, 0.75)), ('led', 'led', (0, -60, 0), (0.625, 0.75)), ('stop', 'black', (0, -60, 0), (0.625, 0.75)),
  ('dcjack', 'black', (0, 60, 0), (0.625, 0.75)), ('gx12', 'metal', (0, 60, 0), (0.625, 0.75)), ('grommet', 'rubber', (0, 60, 0), (0.625, 0.75)), ('bundle', 'braid', (0, 60, 0), (0.625, 0.75)),
  ('plate', 'green', (0, 0, 120), (0.5, 0.625)), ('column', 'green', (0, 0, 150), (0.5, 0.625)),
  ('bin0', 'pp', (0, 0, 300), (0.375, 0.5)), ('water0', 'water', (0, 0, 300), (0.375, 0.5)), ('lid0', 'lid', (0, 0, 380), (0.375, 0.5)),
  ('sleeve0', 'green', (0, 0, 350), (0.25, 0.375)), ('sleeve1', 'green', (0, 0, 350), (0.25, 0.375)),
  ('bottle0', 'amber', (0, 0, 480), (0.25, 0.375)), ('bottle1', 'white_pp', (0, 0, 480), (0.25, 0.375)),
  ('spout_at', 'green', (0, 80, 0), (0.125, 0.25)),
  ('cover0', 'matte_black', (0, -70, 0), (0, 0.125)), ('cover1', 'matte_black', (0, -70, 0), (0, 0.125)), ('cover2', 'matte_black', (0, -70, 0), (0, 0.125)),
]
TUBE_WIN = (0.125, 0.25)
ROUTES = [
  ((0.29, 0.55, 0.78), [[195,112,74],[195,112,262],[195,112,288],[212,112,322],[235,112,322],[235,112,303],[235,112,280],[235,112,66],[232,116,30],[225,110,19],[180,100,30],[100,60,46],[86,32,44],[84,22,54],[78,13,56],[71,13,49]]),
  ((0.29, 0.55, 0.78), [[60,13,59],[63,14,62],[72,22,60],[86,32,42],[110,60,26],[180,118,18],[225,110,13],[262,125,34],[310,195,34],[323,222,30],[323,290,30]]),
  ((0.70, 0.40, 0.16), [[285,54,313],[262,30,326],[244,13,324],[244,13,306],[244,13,66],[238,18,30],[225,20,14],[200,18,30],[175,16,44],[162,13,56],[155,13,49]]),
  ((0.70, 0.40, 0.16), [[144,13,59],[147,14,62],[156,22,60],[170,32,42],[190,60,22],[215,125,18],[225,130,16],[262,140,34],[310,200,34],[323,222,32],[323,290,32]]),
  ((0.79, 0.73, 0.54), [[285,171,313],[308,192,326],[326,212,324],[326,212,306],[326,212,66],[326,150,44],[314,32,44],[312,22,54],[306,13,56],[299,13,49]]),
  ((0.79, 0.73, 0.54), [[288,13,59],[291,14,62],[300,22,60],[314,32,42],[326,100,30],[324,200,30],[323,222,28],[323,290,28]]),
]

# ------------------------------------------------------------------ scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU' if DEVICE == 'CPU' else 'GPU'
if DEVICE != 'CPU':
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = DEVICE
        prefs.get_devices()
        for d in prefs.devices: d.use = True
        print('render devices:', [(d.name, d.type, d.use) for d in prefs.devices])
        if not any(d.type == DEVICE for d in prefs.devices):
            print('no', DEVICE, 'device found: falling back to CPU'); scene.cycles.device = 'CPU'
    except Exception as e:
        print('GPU setup failed, CPU:', e); scene.cycles.device = 'CPU'
scene.cycles.samples = SAMPLES
scene.cycles.use_denoising = True
scene.cycles.use_adaptive_sampling = True
scene.render.resolution_x, scene.render.resolution_y = (1600, 800)   # 2:1, so wide viewports crop little
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.render.image_settings.file_format = 'WEBP'
scene.render.image_settings.quality = 82
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'
scene.frame_start, scene.frame_end = 1, FRAMES

def principled(name, color, rough=0.5, metallic=0.0, transmission=0.0, alpha=1.0, emission=None, ior=1.45, coat=0.0, sheen=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*color, 1)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metallic
    b.inputs['Transmission Weight'].default_value = transmission
    b.inputs['IOR'].default_value = ior
    b.inputs['Coat Weight'].default_value = coat
    b.inputs['Sheen Weight'].default_value = sheen
    b.inputs['Alpha'].default_value = alpha
    if emission:
        b.inputs['Emission Color'].default_value = (*emission, 1); b.inputs['Emission Strength'].default_value = 4.0
    if alpha < 1: m.surface_render_method = 'BLENDED'
    return m

# Matte green PETG: a muted, slightly desaturated green with the faint
# sheen matte filament has, plus a very fine bump so it doesn't read as CG-smooth.
# Anycubic matte olive: sampled from the spool photo, sRGB #577544 on a lit face.
green = principled('green_petg', (0.027, 0.072, 0.015), rough=0.74, sheen=0.2)
nt = green.node_tree; b = nt.nodes['Principled BSDF']
noise = nt.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 900; noise.inputs['Detail'].default_value = 2; noise.inputs['Roughness'].default_value = 0.5
bump = nt.nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.06; bump.inputs['Distance'].default_value = 0.0004
nt.links.new(noise.outputs['Fac'], bump.inputs['Height']); nt.links.new(bump.outputs['Normal'], b.inputs['Normal'])

MAT = {
  'green': green,
  'pump': principled('pump', (0.88, 0.88, 0.86), rough=0.35, coat=0.3),
  'pcb': principled('pcb', (0.05, 0.08, 0.16), rough=0.4),
  'pcb_green': principled('pcb_green', (0.04, 0.22, 0.09), rough=0.35, coat=0.5),
  'black': principled('black', (0.03, 0.03, 0.03), rough=0.45),
  'metal': principled('metal', (0.8, 0.8, 0.8), rough=0.3, metallic=1.0),
  'rubber': principled('rubber', (0.06, 0.06, 0.06), rough=0.8),
  'led': principled('led', (0.6, 0.95, 0.6), rough=0.3, transmission=0.6, emission=(0.35, 0.9, 0.4)),
  'pp': principled('pp', (0.90, 0.93, 0.94), rough=0.22, transmission=0.75, alpha=0.45, ior=1.49),   # frosted, like the Cambro
  'water': principled('water', (0.55, 0.78, 0.92), rough=0.05, transmission=1.0, alpha=0.5, ior=1.33),
  'lid': principled('lid', (0.94, 0.95, 0.93), rough=0.4, transmission=0.25, alpha=0.92, ior=1.49),
  'amber': principled('amber', (0.55, 0.28, 0.08), rough=0.25, transmission=0.55, alpha=0.9, ior=1.5),
  'white_pp': principled('white_pp', (0.93, 0.93, 0.90), rough=0.3, transmission=0.2, alpha=0.95),
  'tube': principled('tube', (0.95, 0.95, 0.95), rough=0.35, transmission=0.55, alpha=0.75, ior=1.41),
  'clear': principled('clear', (0.92, 0.94, 0.95), rough=0.15, transmission=0.8, alpha=0.5, ior=1.49),
  'silver': principled('silver', (0.75, 0.75, 0.74), rough=0.38, metallic=1.0),
  'pcb_dark': principled('pcb_dark', (0.03, 0.04, 0.06), rough=0.35, coat=0.4),
  'white': principled('white', (0.9, 0.9, 0.88), rough=0.45),
  'grey': principled('grey', (0.35, 0.35, 0.35), rough=0.5),
  'red': principled('red', (0.6, 0.05, 0.05), rough=0.6),
  'beige': principled('beige', (0.7, 0.62, 0.45), rough=0.6),
  'braid': principled('braid', (0.05, 0.05, 0.05), rough=0.85, sheen=0.5),
  'matte_black': principled('matte_black', (0.025, 0.025, 0.025), rough=0.8, sheen=0.15),   # the pump covers, printed in matte black
}

def ease(x):
    x = max(0.0, min(1.0, x)); return x * x * (3 - 2 * x)

# ----------------------------------------------------------------- screws
# Black countersunk M3s in the holes the model has: four in the dock plate,
# three in the column's floor plate, four in each pump cover. Each travels
# with its plate, then drives in along its own axis, spinning, during the
# last third of the plate's landing.
from mathutils import Quaternion, Matrix
screw_mat = principled('screw', (0.02, 0.02, 0.02), rough=0.42, metallic=0.7)
def make_screw(name):
    bpy.ops.mesh.primitive_cone_add(vertices=48, radius1=1.5 * S, radius2=3.0 * S, depth=1.7 * S, location=(0, 0, -0.85 * S))
    head = bpy.context.object
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.5 * S, depth=8 * S, location=(0, 0, -5.7 * S))
    shank = bpy.context.object
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=1.1 * S, depth=1.4 * S, location=(0, 0, -0.4 * S))
    hexr = bpy.context.object
    m = head.modifiers.new('hex', 'BOOLEAN'); m.operation = 'DIFFERENCE'; m.object = hexr
    bpy.context.view_layer.objects.active = head; bpy.ops.object.modifier_apply(modifier='hex')
    bpy.data.objects.remove(hexr)
    bpy.ops.object.select_all(action='DESELECT'); head.select_set(True); shank.select_set(True); bpy.context.view_layer.objects.active = head
    bpy.ops.object.join(); ob = bpy.context.object; ob.name = name
    for pg in ob.data.polygons: pg.use_smooth = True
    ob.data.materials.clear(); ob.data.materials.append(screw_mat)
    ob.rotation_mode = 'QUATERNION'
    return ob

# [hole (mm), axis the screw drives along, parent explode offset (mm), parent window]
PLATE_WIN, COL_WIN, COVER_WIN = (0.5, 0.625), (0.5, 0.625), (0, 0.125)
SCREWS = []
for x, y in [(8, 8), (217, 8), (8, 217), (217, 217)]:          SCREWS.append(((x, y, 70), (0, 0, -1), (0, 0, 120), PLATE_WIN))
for x, y in [(337, 8), (233, 217), (337, 112.5)]:              SCREWS.append(((x, y, 70), (0, 0, -1), (0, 0, 150), COL_WIN))
for px in (46, 130, 274):
    for sx in (-29, 29):
        for sz in (-26, 26):                                    SCREWS.append(((px + sx, -2, 32 + sz), (0, 1, 0), (0, -70, 0), COVER_WIN))
screw_objs = []
for i, (hole, axis, off, win) in enumerate(SCREWS):
    ob = make_screw(f'screw{i}')
    base_q = Vector((0, 0, -1)).rotation_difference(Vector(axis))
    screw_objs.append((ob, Vector(hole) * S, Vector(axis), Vector(off) * S, win, base_q))

def pose_screws(t):
    for ob, hole, axis, off, (a, b), base_q in screw_objs:
        k = ease((t - a) / (b - a))          # the plate's explode fraction
        sdrive = ease(min(1.0, k / 0.35))    # 0 = seated, 1 = lifted 40 mm along its axis
        ob.location = hole + off * k - axis * (40 * S) * sdrive
        ob.rotation_quaternion = base_q @ Quaternion((0, 0, 1), 6 * 2 * math.pi * sdrive)

objects = []
for f, mat, off, win in PARTS_LIST:
    path = os.path.join(PARTS, f + '.stl')
    bpy.ops.wm.stl_import(filepath=path, global_scale=S)
    ob = bpy.context.selected_objects[0]; ob.name = f
    for p in ob.data.polygons: p.use_smooth = True
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35)) if hasattr(bpy.ops.object, 'shade_smooth_by_angle') else None
    ob.data.materials.append(MAT[mat])
    objects.append((ob, Vector(off) * S, win))

# Tubes as bevelled curves through the route points. Liquid colour is faint
# inside a clear silicone tube.
for i, (col, pts) in enumerate(ROUTES):
    cu = bpy.data.curves.new(f'tube{i}', 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = 2.5 * S; cu.bevel_resolution = 6; cu.resolution_u = 12
    sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
    for bp, p in zip(sp.bezier_points, pts):
        bp.co = Vector(p) * S; bp.handle_left_type = bp.handle_right_type = 'AUTO'
    ob = bpy.data.objects.new(f'tube{i}', cu); bpy.context.collection.objects.link(ob)
    m = MAT['tube'].copy(); m.name = f'tube{i}'
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (col[0]*0.5+0.45, col[1]*0.5+0.45, col[2]*0.5+0.45, 1)
    ob.data.materials.append(m)
    objects.append((ob, Vector((0, 0, 0)), TUBE_WIN))
    ob['is_tube'] = True

# Studio: a big warm off-white floor fading into a world of the same tone.
bpy.ops.mesh.primitive_plane_add(size=40, location=(0.17, 0.11, 0))
floor = bpy.context.object; floor.name = 'floor'
# Dark studio: charcoal floor and world, so the frosted tank and the white
# lid read as bright objects and the olive green sits against something.
floor.data.materials.append(principled('backdrop', (0.035, 0.036, 0.034), rough=0.9))
scene.world = bpy.data.worlds.new('world'); scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.06, 0.06, 0.058, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.5
scene.view_settings.exposure = -0.1

def area(name, loc, target, size, energy, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, 'AREA'); l.energy = energy; l.size = size; l.color = color
    ob = bpy.data.objects.new(name, l); bpy.context.collection.objects.link(ob); ob.location = loc
    d = Vector(target) - Vector(loc); ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    return ob
C = Vector((0.172, 0.112, 0.20))
area('key',  (1.4, -1.4, 1.6), C, 1.6, 170, (1.0, 0.96, 0.9))
area('fill', (-1.8, -1.0, 1.0), C, 2.5, 70, (0.92, 0.96, 1.0))
area('rim',  (0.4, 1.6, 1.4), C, 1.2, 200, (1.0, 1.0, 1.0))
area('top',  (0.2, 0.0, 2.6), C, 2.0, 60)
# a soft pool of light on the floor behind the unit, so it isn't a void
area('pool', (0.6, 1.2, 1.8), Vector((0.2, 0.9, 0.0)), 1.4, 90, (0.95, 0.97, 1.0))

# Camera: a 3/4 view from the front right, slightly above, that eases back
# as the parts spread out and drifts a few degrees around the unit.
cam = bpy.data.cameras.new('cam'); cam.lens = 60; cam.sensor_width = 36
camob = bpy.data.objects.new('cam', cam); bpy.context.collection.objects.link(camob); scene.camera = camob
def cam_at(t):
    ang = math.radians(-38 + 14 * t)
    dist = 1.75 + 1.75 * ease(t)
    height = 0.70 + 1.10 * ease(t)
    look = Vector((0.172, 0.112, 0.15 + 0.26 * ease(t)))
    pos = look + Vector((dist * math.sin(ang), -dist * math.cos(ang), height - look.z))
    camob.location = pos
    camob.rotation_euler = (look - pos).to_track_quat('-Z', 'Y').to_euler()

def pose(t):
    for ob, off, (a, b) in objects:
        k = ease((t - a) / (b - a))
        if ob.get('is_tube'):
            ob.hide_render = k > 0.5; ob.hide_viewport = ob.hide_render
        else:
            ob.location = off * k
    pose_screws(t)
    cam_at(t)

if TEST:
    for i, t in enumerate([0.0, 0.52, 1.0] if '--full-test' in argv else [0.0, 1.0]):
        pose(t); scene.render.filepath = os.path.join(OUT, f'test_{i}.webp'); bpy.ops.render.render(write_still=True)
    # a close-up of the base with the pumps and boards lifted out
    pose(0.05)
    look = Vector((0.26, 0.12, 0.09)); pos = Vector((0.62, -0.30, 0.34))
    camob.location = pos; camob.rotation_euler = (look - pos).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = os.path.join(OUT, 'test_3.webp'); bpy.ops.render.render(write_still=True)
else:
    for fr in range(1, FRAMES + 1):
        t = (fr - 1) / (FRAMES - 1)
        pose(t); scene.render.filepath = os.path.join(OUT, f'f{fr:03d}.webp'); bpy.ops.render.render(write_still=True)
    # a hero still, assembled, wider
    pose(0.0); scene.render.resolution_x, scene.render.resolution_y = (2400, 1200); scene.cycles.samples = SAMPLES * 2
    scene.render.filepath = os.path.join(OUT, 'hero.webp'); bpy.ops.render.render(write_still=True)
print('done')
