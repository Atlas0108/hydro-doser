# Encode the rendered frames as an MP4 with Blender's own FFmpeg: forward,
# hold, reverse, hold. 24 fps, H.264 high quality, at the frames' own size.
import bpy, os, sys
argv = sys.argv[sys.argv.index('--') + 1:]
FR, OUT = argv[0], argv[1]
files = sorted(f for f in os.listdir(FR) if f.startswith('f') and f.endswith('.webp'))
N, HOLD, FPS = len(files), 24, 24
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
first = bpy.data.images.load(os.path.join(FR, files[0]))   # the frames' own size
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = first.size[0], first.size[1], 100
sc.render.fps = FPS
sc.sequence_editor_create()
seq = sc.sequence_editor
def strip(name, names, start, length=None):
    st = seq.strips.new_image(name=name, filepath=os.path.join(FR, names[0]), channel=1, frame_start=start) if hasattr(seq, 'strips') else seq.sequences.new_image(name=name, filepath=os.path.join(FR, names[0]), channel=1, frame_start=start)
    for n in names[1:]: st.elements.append(n)
    if length: st.frame_final_duration = length
    return st
strip('fwd', files, 1)
strip('hold1', [files[-1]], N + 1, HOLD)
strip('rev', list(reversed(files)), N + HOLD + 1)
strip('hold0', [files[0]], 2 * N + HOLD + 1, HOLD)
sc.frame_start, sc.frame_end = 1, 2 * N + 2 * HOLD
sc.render.image_settings.media_type = 'VIDEO'; sc.render.image_settings.file_format = 'FFMPEG'
sc.render.ffmpeg.format = 'MPEG4'; sc.render.ffmpeg.codec = 'H264'
sc.render.ffmpeg.constant_rate_factor = 'HIGH'; sc.render.ffmpeg.ffmpeg_preset = 'GOOD'
sc.render.ffmpeg.gopsize = 12
sc.render.filepath = OUT
bpy.ops.render.render(animation=True)
print('encoded', sc.frame_end, 'frames')
