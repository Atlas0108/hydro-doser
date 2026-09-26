# Hydro Doser v3: build the scene from the part STLs exported in assembly
# position, light it as a studio product shot, and render a basic explosion
# as a frame sequence.
#
#   blender -b -P doser-v3.py -- --parts DIR --out DIR [--frames 96] [--samples 64] [--width 1600] [--device CPU] [--test]
#
# Model coordinates are mm: x right->left, y front->back, z up from the
# body's bottom edge. Blender is metres, z up, so parts are scaled 0.001 in
# place. Every part slides straight out along one axis, all together, the
# same offsets as the exploded-view page; the wall boards stay put.
import bpy, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return type(default)(argv[argv.index(name) + 1]) if name in argv else default
FRAMES  = arg('--frames', 96)
SAMPLES = arg('--samples', 64)
OUT     = arg('--out', os.path.expanduser('~/doser-v3/frames'))
PARTS   = arg('--parts', os.path.expanduser('~/doser-v3/parts'))
DEVICE  = arg('--device', 'CPU')
WIDTH   = arg('--width', 1600)              # 2:1 frames; --width 2400 for the high-quality pass
TEST    = '--test' in argv
os.makedirs(OUT, exist_ok=True)

S = 0.001
# [file, material, where it sits exploded: an offset in model mm]
PARTS_LIST = [
  ('body', 'shell', (0, 0, 0)),
  ('feet', 'rubber', (0, 0, -60)),
  ('pump0', 'pump', (0, 0, 110)), ('pump1', 'pump', (0, 0, 110)), ('pump2', 'pump', (0, 0, 110)),
  ('board1', 'pcb_green', (0, 0, 0)), ('board2', 'black', (0, 0, 0)),
  ('ports', 'metal', (0, 80, 0)),
  ('plate', 'plate', (0, -120, 0)),
  ('oled', 'pcb_dark', (0, -100, 0)), ('encoder', 'pcb_green', (0, -70, 0)), ('board0', 'pcb_dark', (0, -50, 0)),
  ('screws', 'screw', (0, -170, 0)),
  ('knob', 'knob', (0, -210, 0)), ('cap', 'plate', (0, -210, 0)),
  ('lid', 'shell', (0, 0, 150)), ('deck', 'plate', (0, 0, 150)),
  ('bottle0', 'hdpe', (0, 0, 250)), ('bottle1', 'hdpe', (0, 0, 250)),
  ('capb0', 'cap', (0, 0, 250)), ('capb1', 'cap', (0, 0, 250)),
  ('label0', 'label_a', (0, 0, 250)), ('label1', 'label_b', (0, 0, 250)),
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
        if not any(d.type == DEVICE for d in prefs.devices):
            print('no', DEVICE, 'device found: falling back to CPU'); scene.cycles.device = 'CPU'
    except Exception as e:
        print('GPU setup failed, CPU:', e); scene.cycles.device = 'CPU'
scene.cycles.samples = SAMPLES
scene.cycles.use_denoising = True
scene.cycles.use_adaptive_sampling = True
scene.render.resolution_x, scene.render.resolution_y = (WIDTH, WIDTH // 2)
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.render.image_settings.file_format = 'WEBP'
scene.render.image_settings.quality = 82
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'
scene.frame_start, scene.frame_end = 1, FRAMES

def principled(name, color, rough=0.5, metallic=0.0, transmission=0.0, alpha=1.0, ior=1.45, coat=0.0, sheen=0.0):
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
    if alpha < 1: m.surface_render_method = 'BLENDED'
    return m

def grained(m, scale=900, strength=0.06):   # a very fine bump so printed plastic doesn't read as CG-smooth
    nt = m.node_tree; b = nt.nodes['Principled BSDF']
    noise = nt.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = scale; noise.inputs['Detail'].default_value = 2
    bump = nt.nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = strength; bump.inputs['Distance'].default_value = 0.0004
    nt.links.new(noise.outputs['Fac'], bump.inputs['Height']); nt.links.new(bump.outputs['Normal'], b.inputs['Normal'])
    return m

MAT = {
  'shell': grained(principled('shell', (0.027, 0.072, 0.015), rough=0.74, sheen=0.2)),      # Anycubic matte olive PETG
  'plate': grained(principled('plate', (0.003, 0.003, 0.003), rough=0.88), 700, 0.04),      # matte black PETG: the faceplate, the deck, the knob's cap
  'knob':  grained(principled('knob', (0.196, 0.027, 0.012), rough=0.62, sheen=0.2), 600),  # brown-red, #7a2e1e
  'pump': principled('pump', (0.88, 0.88, 0.86), rough=0.35, coat=0.3),
  'pcb_green': principled('pcb_green', (0.04, 0.22, 0.09), rough=0.35, coat=0.5),
  'pcb_dark': principled('pcb_dark', (0.03, 0.04, 0.06), rough=0.35, coat=0.4),
  'black': principled('black', (0.03, 0.03, 0.03), rough=0.45),
  'metal': principled('metal', (0.8, 0.8, 0.8), rough=0.3, metallic=1.0),
  'screw': principled('screw', (0.008, 0.008, 0.008), rough=0.6, metallic=0.2),   # black-oxide M3s, matte
  'rubber': principled('rubber', (0.06, 0.06, 0.06), rough=0.8),
  'amber': principled('amber', (0.55, 0.28, 0.08), rough=0.25, transmission=0.55, alpha=0.9, ior=1.5),
  'white_pp': principled('white_pp', (0.93, 0.93, 0.90), rough=0.3, transmission=0.2, alpha=0.95),
}

MAT.update({
  'amber_tube': principled('amber_tube', (0.85, 0.62, 0.35), rough=0.35, transmission=0.5, alpha=0.8, ior=1.41),
  'green_tube': principled('green_tube', (0.7, 0.88, 0.7), rough=0.35, transmission=0.5, alpha=0.8, ior=1.41),   # Sprout
  'blue_tube': principled('blue_tube', (0.68, 0.82, 0.92), rough=0.35, transmission=0.5, alpha=0.8, ior=1.41),    # Thrive
  'white_tube': principled('white_tube', (0.95, 0.95, 0.95), rough=0.35, transmission=0.55, alpha=0.75, ior=1.41),
  'water_tube': principled('water_tube', (0.62, 0.78, 0.9), rough=0.35, transmission=0.5, alpha=0.8, ior=1.41),
  'lead': principled('lead', (0.04, 0.04, 0.04), rough=0.8),
  'power': principled('power', (0.5, 0.04, 0.03), rough=0.7),
  'ribbon': principled('ribbon', (0.3, 0.3, 0.32), rough=0.75),
  'brass': principled('brass', (0.8, 0.6, 0.25), rough=0.4, metallic=1.0),
  'hdpe': principled('hdpe', (0.92, 0.92, 0.90), rough=0.45, transmission=0.15, alpha=0.97, sheen=0.3),   # white HDPE, faintly translucent
  'cap': principled('cap', (0.004, 0.004, 0.004), rough=0.75),   # the bottles' caps, matte black
  'label_a': principled('label_a', (0.13, 0.42, 0.14), rough=0.7),   # Sprout, green
  'label_b': principled('label_b', (0.05, 0.25, 0.42), rough=0.7),   # Thrive, blue
  'label_ink': principled('label_ink', (0.92, 0.92, 0.9), rough=0.7),
})

def ease(x):
    x = max(0.0, min(1.0, x)); return x * x * (3 - 2 * x)

# The model's x runs right to left. Everything in model coordinates hangs
# under this empty, mirrored in x, so the front view is the real front.
model = bpy.data.objects.new('model', None); bpy.context.collection.objects.link(model); model.scale = (-1, 1, 1)

# Tubes, wires and the inserts: routes.json beside the parts. Each route point
# rides with a part, so the tube stays attached as the parts spread.
import json
routes = json.load(open(os.path.join(PARTS, 'routes.json')))
ROFF = {k: Vector(v) * S for k, v in routes['offsets'].items()}
curves = []
for kind, r_default in (('tubes', routes['tube_r']), ('wires', None)):
    for rt in routes[kind]:
        cu = bpy.data.curves.new(rt['name'], 'CURVE'); cu.dimensions = '3D'
        cu.bevel_depth = (rt.get('r') or r_default) * S; cu.bevel_resolution = 6; cu.resolution_u = 12
        cu.use_fill_caps = True
        sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(rt['pts']) - 1)
        for bp in sp.bezier_points: bp.handle_left_type = bp.handle_right_type = 'AUTO'
        ob = bpy.data.objects.new(rt['name'], cu); bpy.context.collection.objects.link(ob); ob.parent = model
        ob.data.materials.append(MAT[rt['color'] + '_tube' if kind == 'tubes' else rt['color']])
        curves.append((sp, [(Vector(p[:3]) * S, ROFF[p[3]]) for p in rt['pts']]))
insert_obs = []
for ins in routes['inserts']:
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=ins['d'] / 2 * S, depth=ins['len'] * S, location=(0, 0, 0), rotation=(math.radians(90), 0, 0))
    ob = bpy.context.object; ob.name = 'insert'; ob.parent = model
    for p in ob.data.polygons: p.use_smooth = True
    ob.data.materials.append(MAT['brass'])
    insert_obs.append((ob, Vector((ins['x'], ins['y0'] + ins['len'] / 2, ins['z'])) * S, ROFF['inserts']))

# The screen: the menu as an emissive image in the window, just in front of
# the OLED's glass, riding with the OLED. screen.jpg beside the parts.
screen_ob = None
SCREEN = os.path.join(PARTS, 'screen.jpg')
if os.path.exists(SCREEN):
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, 0), rotation=(math.radians(90), 0, 0))
    screen_ob = bpy.context.object; screen_ob.name = 'screen'; screen_ob.parent = model
    screen_ob.scale = (-21.7 * S, 10.9 * S, 1)   # the active area; x negated to undo the parent's mirror on the picture
    sm = bpy.data.materials.new('screen'); sm.use_nodes = True; nt = sm.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = bpy.data.images.load(SCREEN); tex.interpolation = 'Cubic'
    em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value = 6.0
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(tex.outputs['Color'], em.inputs['Color']); nt.links.new(em.outputs['Emission'], out.inputs['Surface'])
    screen_ob.data.materials.append(sm)
    screen_base = Vector((124, 1.4, 37)) * S          # oled_x, 0.1 in front of the glass, ctl_z

# The labels' names, wrapped round each label on a circle, centred on the
# front. Built in Blender's own frame (the model's x negated), not under
# the mirrored parent, so the word reads left to right without tricks.
LABELS = [((69, 62), 'SPROUT'), ((133, 62), 'THRIVE')]
label_obs = []
for (cx, cy), word in LABELS:
    r = 24.55 * S   # 0.25 proud of the label
    fc = bpy.data.curves.new('lt', 'FONT'); fc.body = word; fc.size = 8.5 * S; fc.align_x = 'CENTER'; fc.extrude = 0.00012
    fc.space_character = 1.15
    tob = bpy.data.objects.new('lt', fc); bpy.context.collection.objects.link(tob)
    bpy.context.view_layer.objects.active = tob; tob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    # bend the flat word round the bottle by hand: x along the text becomes an angle
    # round the axis, x = 0 at the front (-y), +x toward the viewer's right (+x)
    for v in tob.data.vertices:
        x, depth, z = v.co.x, v.co.z, v.co.y            # the text lay flat: x along, y up (-> world z), z its extrusion
        a = x / r; rr = r + depth
        v.co = (rr * math.sin(a), -rr * math.cos(a), z)
    cob = tob   # no curve object any more; kept in the tuple for the pose loop
    tob.data.materials.clear(); tob.data.materials.append(MAT['label_ink'])
    tob.select_set(False)
    label_obs.append((cob, tob, Vector((-cx, cy, 47)) * S))
BOTTLE_OFF_W = Vector((-routes['offsets']['bottle'][0], routes['offsets']['bottle'][1], routes['offsets']['bottle'][2])) * S
def pose_labels(k):
    for cob, tob, base in label_obs:
        cob.location = base + BOTTLE_OFF_W * k; tob.location = base + BOTTLE_OFF_W * k

def pose_routes(k):
    pose_labels(k)
    if screen_ob: screen_ob.location = screen_base + ROFF['oled'] * k
    for sp, pts in curves:
        for bp, (base, off) in zip(sp.bezier_points, pts): bp.co = base + off * k
    for ob, base, off in insert_obs: ob.location = base + off * k

objects = []
for f, mat, off in PARTS_LIST:
    bpy.ops.wm.stl_import(filepath=os.path.join(PARTS, f + '.stl'), global_scale=S)
    ob = bpy.context.selected_objects[0]; ob.name = f
    for p in ob.data.polygons: p.use_smooth = True
    if hasattr(bpy.ops.object, 'shade_smooth_by_angle'): bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    ob.data.materials.append(MAT[mat])
    ob.parent = model
    objects.append((ob, Vector(off) * S))

# Studio: a charcoal floor and world, so the olive shell and the orange
# knob sit against something and the white bottle reads bright.
bpy.ops.mesh.primitive_plane_add(size=40, location=(-0.101, 0.089, -0.006))   # the feet's bottoms; it sinks with them as they drop
floor = bpy.context.object; floor.name = 'floor'
floor.data.materials.append(principled('backdrop', (0.035, 0.036, 0.034), rough=0.9))
scene.world = bpy.data.worlds.new('world'); scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.06, 0.06, 0.058, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.5
scene.view_settings.exposure = -0.55

def area(name, loc, target, size, energy, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, 'AREA'); l.energy = energy; l.size = size; l.color = color
    ob = bpy.data.objects.new(name, l); bpy.context.collection.objects.link(ob); ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    return ob
C = Vector((-0.101, 0.089, 0.15))   # the lights and the camera live in Blender's frame: the model's x negated
# the key from the front right and high, so the face and the top carry the
# light; a soft fill from the front left; the rim behind only an edge accent
area('key',  (0.9, -1.7, 1.6), C, 1.6, 120, (1.0, 0.96, 0.9))
area('fill', (-1.8, -1.2, 0.9), C, 2.5, 45, (0.92, 0.96, 1.0))
area('rim',  (-0.4, 1.6, 1.4), C, 1.2, 60, (1.0, 1.0, 1.0))
area('top',  (-0.2, -0.3, 2.6), C, 2.0, 30)
area('pool', (-0.6, 1.2, 1.8), Vector((-0.1, 0.9, 0.0)), 1.4, 55, (0.95, 0.97, 1.0))

# Camera: the exploded-view page's 3/4 view from the front left, above.
# It keeps that direction and only eases back as the parts spread, so the
# assembled unit fills the frame and the full explosion still fits.
cam = bpy.data.cameras.new('cam'); cam.lens = 60; cam.sensor_width = 36
camob = bpy.data.objects.new('cam', cam); bpy.context.collection.objects.link(camob); scene.camera = camob
DIR = Vector((-600, -709, 460)).normalized()         # from the page: three (-700, 520, 620) looking at (-101, 60, -89); x negated for Blender's frame
def cam_at(t):
    k = ease(t)
    look = Vector((-0.101, 0.089 - 0.045 * k, 0.045 + 0.125 * k))
    pos = look + DIR * (1.0 + 0.72 * k)
    camob.location = pos
    camob.rotation_euler = (look - pos).to_track_quat('-Z', 'Y').to_euler()

def pose(t):
    k = ease(t)
    for ob, off in objects: ob.location = off * k
    pose_routes(k)
    floor.location.z = -0.006 - 0.060 * k
    cam_at(t)

if TEST:
    for i, t in enumerate([0.0, 0.5, 1.0]):
        pose(t); scene.render.filepath = os.path.join(OUT, f'test_{i}.webp'); bpy.ops.render.render(write_still=True)
    # a close-up of the bottles, exploded, from the front
    pose(1.0); look = Vector((-0.101, 0.062, 0.31)); pos = look + Vector((0.05, -0.36, 0.1))
    camob.location = pos; camob.rotation_euler = (look - pos).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = os.path.join(OUT, 'test_3.webp'); bpy.ops.render.render(write_still=True)
else:
    for fr in range(1, FRAMES + 1):
        pose((fr - 1) / (FRAMES - 1))
        scene.render.filepath = os.path.join(OUT, f'f{fr:03d}.webp'); bpy.ops.render.render(write_still=True)
    pose(0.0); scene.render.resolution_x, scene.render.resolution_y = (max(WIDTH, 2400), max(WIDTH, 2400) // 2); scene.cycles.samples = SAMPLES * 2
    scene.render.filepath = os.path.join(OUT, 'hero.webp'); bpy.ops.render.render(write_still=True)
print('done')
