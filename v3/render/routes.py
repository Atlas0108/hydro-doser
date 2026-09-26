# The tubes and the faceplate's heat-set inserts, as routes in
# model mm for the explosion (the Blender scene and the exploded-view page).
# Every point carries the part it rides with, so when the parts spread the
# tube or wire stays attached at both ends. Numbers are from the scad's
# echo: nozzle tips, board positions, ports, the plate's screw centres.
#
#   python3 routes.py > routes.json
import json, math

pump_x = [39, 101, 163]; pump_z = 28; tip_y = 107          # the nozzle tips' y: head face 99 + 8
ts = {+1: (28.6956, 19.9139), -1: (16.8053, 30.62)}          # tube_start(s): (dx, dz) from the pump's axis, 5 past the tip
nz = (math.sin(math.radians(42)), math.cos(math.radians(42)))   # the nozzles' direction, rolled 42
cup = [(69, 62), (133, 62)]; hole = [(25, 62), (177, 62)]; water_in = (101, 175, 8)   # the plain hole low in the back wall
grom = (101, 176, 58); jack = (70, 171, 28); gx12 = (132, 171, 28)
pscrews = [(60.85, 15.3), (141.15, 15.3), (141.15, 58.7), (60.85, 58.7)]

def tip(k, s, along=0):
    dx, dz = ts[s]
    return (pump_x[k] + dx + nz[0] * along, tip_y, pump_z + dz + nz[1] * along)

def P(tag, *pts): return [[*p, tag] for p in pts]

# the offsets each tag rides with (the exploded-view page's PARTS)
OFFSETS = {
  'body': (0, 0, 0), 'board1': (0, 0, 0), 'board2': (0, 0, 0),
  'pump': (0, 0, 110), 'lid': (0, 0, 150), 'bottle': (0, 0, 250), 'ports': (0, 80, 0),
  'esp': (0, -50, 0), 'oled': (0, -100, 0), 'encoder': (0, -70, 0), 'inserts': (0, -30, 0),
}

tubes = []
# Nutrient A: pump 0 (right) feeds the right bottle; its inlet comes down
# through the lid's right tube hole, its outlet goes out the grommet.
def inlet(k, h, c, mid):
    x0 = 1 if h[0] < c[0] else -1     # which way the arc over to the bottle goes
    return P('pump', tip(k, -1), tip(k, -1, 8)) + P('body', *mid) + \
           P('lid', (h[0], h[1], 70), (h[0], h[1], 85)) + \
           P('bottle', (h[0], h[1], 120), (h[0] + x0 * 10, h[1], 138), (c[0] - x0 * 11, c[1], 138), (c[0], c[1], 128), (c[0], c[1], 118), (c[0], c[1], 10))
def outlet(k, first, mid, g):   # g: where the tube sits in the grommet's bore
    return P('pump', tip(k, +1), first) + P('body', *mid, (g[0], 168, g[2]), (g[0], 174, g[2]), (g[0], 180, g[2])) + P('ports', (g[0], 190, g[2]), (g[0], 210, g[2] - 1), (g[0], 235, g[2] - 4))

tubes.append({'name': 'A in',  'color': 'green', 'pts': inlet(0, hole[0], cup[0], [(50, 90, 62), (30, 70, 60)])})
tubes.append({'name': 'A out', 'color': 'green', 'pts': outlet(0, (71, 109, 52), [(78, 125, 62), (90, 150, 64)], (98.2, 176, 59.6))})
tubes.append({'name': 'B in',  'color': 'blue', 'pts': inlet(2, hole[1], cup[1], [(183, 90, 66), (179, 72, 64)])})
tubes.append({'name': 'B out', 'color': 'blue', 'pts': outlet(2, (193, 108, 51), [(185, 125, 62), (140, 155, 64)], (103.8, 176, 59.6))})
# water: pump 1's inlet comes in through the hole low in the back wall, runs
# under the middle motor, up between the motors and over the bulkhead
tubes.append({'name': 'water in', 'color': 'water', 'pts':
  P('pump', tip(1, -1), tip(1, -1, 8)) + P('body', (122, 120, 62), (122, 133, 58), (122, 133, 10), (122, 150, 8), (106, 160, 8), (101, 168, 8), (101, 174, 8), (101, 180, 8)) + P('ports', (101, 190, 8), (101, 210, 8), (101, 235, 8))})
tubes.append({'name': 'water out', 'color': 'water', 'pts': outlet(1, (133, 109, 52), [(128, 125, 60), (112, 150, 58)], (101, 176, 54.8))})

wires = []   # no wiring in the explosion

# M3 heat-set inserts, brass, in the band behind the wall at the plate's screw centres
inserts = [{'x': x, 'z': z, 'y0': 3, 'len': 5.5, 'd': 4.6} for x, z in pscrews]

print(json.dumps({'offsets': OFFSETS, 'tube_r': 2.5, 'tubes': tubes, 'wires': wires, 'inserts': inserts}))
