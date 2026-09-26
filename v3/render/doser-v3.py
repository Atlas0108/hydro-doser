# Hydro Doser v3: build the scene from the part STLs exported in assembly
# position, light it as a studio product shot, and render a basic explosion
# as a frame sequence.
#
#   blender -b -P doser-v3.py -- --parts DIR --out DIR [--frames 96] [--samples 64] [--device CPU] [--test]
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
  ('knob', 'knob', (0, -210, 0)),
  ('lid', 'shell', (0, 0, 150)),
  ('bottle0', 'amber', (0, 0, 250)), ('bottle1', 'white_pp', (0, 0, 250)),
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
scene.render.resolution_x, scene.render.resolution_y = (1600, 800)
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
  'plate': grained(principled('plate', (0.012, 0.012, 0.012), rough=0.7, sheen=0.15)),      # matte black
  'knob':  grained(principled('knob', (0.394, 0.060, 0.010), rough=0.62, sheen=0.2), 600),  # burnt orange, #a8451a
  'pump': principled('pump', (0.88, 0.88, 0.86), rough=0.35, coat=0.3),
  'pcb_green': principled('pcb_green', (0.04, 0.22, 0.09), rough=0.35, coat=0.5),
  'pcb_dark': principled('pcb_dark', (0.03, 0.04, 0.06), rough=0.35, coat=0.4),
  'black': principled('black', (0.03, 0.03, 0.03), rough=0.45),
  'metal': principled('metal', (0.8, 0.8, 0.8), rough=0.3, metallic=1.0),
  'screw': principled('screw', (0.02, 0.02, 0.02), rough=0.42, metallic=0.7),
  'rubber': principled('rubber', (0.06, 0.06, 0.06), rough=0.8),
  'amber': principled('amber', (0.55, 0.28, 0.08), rough=0.25, transmission=0.55, alpha=0.9, ior=1.5),
  'white_pp': principled('white_pp', (0.93, 0.93, 0.90), rough=0.3, transmission=0.2, alpha=0.95),
}

def ease(x):
    x = max(0.0, min(1.0, x)); return x * x * (3 - 2 * x)

objects = []
for f, mat, off in PARTS_LIST:
    bpy.ops.wm.stl_import(filepath=os.path.join(PARTS, f + '.stl'), global_scale=S)
    ob = bpy.context.selected_objects[0]; ob.name = f
    for p in ob.data.polygons: p.use_smooth = True
    if hasattr(bpy.ops.object, 'shade_smooth_by_angle'): bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    ob.data.materials.append(MAT[mat])
    objects.append((ob, Vector(off) * S))

# Studio: a charcoal floor and world, so the olive shell and the orange
# knob sit against something and the white bottle reads bright.
bpy.ops.mesh.primitive_plane_add(size=40, location=(0.101, 0.089, -0.006))   # the feet's bottoms; it sinks with them as they drop
floor = bpy.context.object; floor.name = 'floor'
floor.data.materials.append(principled('backdrop', (0.035, 0.036, 0.034), rough=0.9))
scene.world = bpy.data.worlds.new('world'); scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.06, 0.06, 0.058, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.5
scene.view_settings.exposure = -0.1

def area(name, loc, target, size, energy, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, 'AREA'); l.energy = energy; l.size = size; l.color = color
    ob = bpy.data.objects.new(name, l); bpy.context.collection.objects.link(ob); ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    return ob
C = Vector((0.101, 0.089, 0.15))
area('key',  (1.4, -1.4, 1.6), C, 1.6, 170, (1.0, 0.96, 0.9))
area('fill', (-1.8, -1.0, 1.0), C, 2.5, 70, (0.92, 0.96, 1.0))
area('rim',  (0.4, 1.6, 1.4), C, 1.2, 200, (1.0, 1.0, 1.0))
area('top',  (0.2, 0.0, 2.6), C, 2.0, 60)
area('pool', (0.6, 1.2, 1.8), Vector((0.1, 0.9, 0.0)), 1.4, 90, (0.95, 0.97, 1.0))

# Camera: the exploded-view page's 3/4 view from the front left, above.
# It keeps that direction and only eases back as the parts spread, so the
# assembled unit fills the frame and the full explosion still fits.
cam = bpy.data.cameras.new('cam'); cam.lens = 60; cam.sensor_width = 36
camob = bpy.data.objects.new('cam', cam); bpy.context.collection.objects.link(camob); scene.camera = camob
DIR = Vector((600, -709, 460)).normalized()          # from the page: three (-700, 520, 620) looking at (-101, 60, -89)
def cam_at(t):
    k = ease(t)
    look = Vector((0.101, 0.089 - 0.045 * k, 0.045 + 0.125 * k))
    pos = look + DIR * (1.0 + 0.72 * k)
    camob.location = pos
    camob.rotation_euler = (look - pos).to_track_quat('-Z', 'Y').to_euler()

def pose(t):
    k = ease(t)
    for ob, off in objects: ob.location = off * k
    floor.location.z = -0.006 - 0.060 * k
    cam_at(t)

if TEST:
    for i, t in enumerate([0.0, 0.5, 1.0]):
        pose(t); scene.render.filepath = os.path.join(OUT, f'test_{i}.webp'); bpy.ops.render.render(write_still=True)
else:
    for fr in range(1, FRAMES + 1):
        pose((fr - 1) / (FRAMES - 1))
        scene.render.filepath = os.path.join(OUT, f'f{fr:03d}.webp'); bpy.ops.render.render(write_still=True)
    pose(0.0); scene.render.resolution_x, scene.render.resolution_y = (2400, 1200); scene.cycles.samples = SAMPLES * 2
    scene.render.filepath = os.path.join(OUT, 'hero.webp'); bpy.ops.render.render(write_still=True)
print('done')
