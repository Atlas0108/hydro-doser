# The tubes, the wires and the faceplate's heat-set inserts, as routes in
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
cup = [(69, 62), (133, 62)]; hole = [(25, 62), (177, 62)]; hole3 = (101, 165.5)
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
def outlet(k, first, mid, g):
    return P('pump', tip(k, +1), first) + P('body', *mid) + P('ports', g, (g[0], 200, g[2] - 0.6), (g[0], 230, g[2] - 3.6))

tubes.append({'name': 'A in',  'color': 'amber', 'pts': inlet(0, hole[0], cup[0], [(50, 90, 62), (30, 70, 60)])})
tubes.append({'name': 'A out', 'color': 'amber', 'pts': outlet(0, (71, 109, 52), [(78, 125, 62), (90, 155, 64)], (98.2, 176, 59.6))})
tubes.append({'name': 'B in',  'color': 'white', 'pts': inlet(2, hole[1], cup[1], [(183, 90, 66), (179, 72, 64)])})
tubes.append({'name': 'B out', 'color': 'white', 'pts': outlet(2, (193, 108, 51), [(185, 125, 62), (140, 155, 64)], (103.8, 176, 59.6))})
# water: pump 1's inlet rises through the third hole at the rear to the supply
tubes.append({'name': 'water in', 'color': 'water', 'pts':
  P('pump', tip(1, -1), tip(1, -1, 8)) + P('body', (118, 125, 66), (108, 150, 68)) + P('lid', (hole3[0], hole3[1], 70), (hole3[0], hole3[1], 85), (hole3[0], hole3[1], 130))})
tubes.append({'name': 'water out', 'color': 'water', 'pts': outlet(1, (133, 109, 52), [(128, 125, 60), (112, 150, 58)], (101, 176, 54.8))})

wires = []
# the pump leads: from each motor's back, down the back wall and along the
# floor by the right wall to the driver
for k, (z, x) in enumerate([(8.8, 12.5), (6.2, 10), (3.6, 7.5)]):
    wires.append({'name': f'pump {k} leads', 'color': 'lead', 'r': 1.2, 'pts':
      P('pump', (pump_x[k], 169, pump_z)) + P('body', (pump_x[k], 172.5, z + 2), (26, 172.5, z), (x, 168, z), (x, 100, z)) + P('board1', (19, 50 - 4 * k, 12 + 3 * k))})
wires.append({'name': 'driver to esp', 'color': 'ribbon', 'r': 1.6, 'pts': P('board1', (19, 40, 20)) + P('body', (28, 30, 20), (45, 25, 22)) + P('esp', (66, 24, 23))})
wires.append({'name': '12 V to driver', 'color': 'power', 'r': 1.2, 'pts': P('ports', jack) + P('body', (50, 172.5, 12), (14.5, 170, 11), (14.5, 100, 11)) + P('board1', (19, 62, 11))})
wires.append({'name': '12 V to buck', 'color': 'power', 'r': 1.2, 'pts': P('ports', jack) + P('body', (90, 172.5, 12), (190, 172.5, 8), (192, 120, 8)) + P('board2', (188, 76, 8))})
wires.append({'name': 'buck to esp', 'color': 'power', 'r': 1.2, 'pts': P('board2', (184, 40, 12)) + P('body', (170, 26, 14), (150, 22, 18)) + P('esp', (126, 24, 23))})
wires.append({'name': 'sensor to esp', 'color': 'ribbon', 'r': 1.6, 'pts': P('ports', gx12) + P('body', (132, 173, 14), (180, 173, 14), (192, 150, 14), (192, 120, 20), (190, 80, 24), (180, 40, 24), (160, 26, 30)) + P('esp', (128, 26, 46))})
wires.append({'name': 'esp to screen', 'color': 'ribbon', 'r': 1.6, 'pts': P('esp', (110, 24, 46)) + P('oled', (118, 18, 47), (124, 12, 49))})
wires.append({'name': 'esp to knob', 'color': 'ribbon', 'r': 1.6, 'pts': P('esp', (86, 24, 22)) + P('encoder', (86, 18, 22), (86, 12, 22))})

# M3 heat-set inserts, brass, in the band behind the wall at the plate's screw centres
inserts = [{'x': x, 'z': z, 'y0': 3, 'len': 5.5, 'd': 4.6} for x, z in pscrews]

print(json.dumps({'offsets': OFFSETS, 'tube_r': 2.5, 'tubes': tubes, 'wires': wires, 'inserts': inserts}))
