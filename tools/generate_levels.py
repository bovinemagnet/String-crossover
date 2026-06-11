#!/usr/bin/env python3
"""Authoring tool for Cross Over Strings levels.

Builds the 50 campaign levels from deliberate weaving patterns (lanes,
crossings, combs and wraps), validates each against the game rules, and
writes the JSON files under levels/. Deterministic: re-running reproduces
identical files.
"""

import json
import os
import sys

COLORS = ["red", "blue", "green", "yellow", "orange", "purple"]
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "levels")


def hpath(row, x0, x1):
    """Horizontal path on `row` from x0 to x1 inclusive."""
    step = 1 if x1 >= x0 else -1
    return [(x, row) for x in range(x0, x1 + step, step)]


def vpath(col, y0, y1):
    """Vertical path on `col` from y0 to y1 inclusive."""
    step = 1 if y1 >= y0 else -1
    return [(col, y) for y in range(y0, y1 + step, step)]


def wrap_band(w, r0, c):
    """Two paths in rows r0..r0+2: one straight, one wrapping over it at column c."""
    over = hpath(r0, 0, c)[:-1] + vpath(c, r0, r0 + 2) + hpath(r0 + 2, c, w - 1)[1:]
    under = hpath(r0 + 1, 0, w - 1)
    return [over, under]


def comb(w, hrows, vcols, vy0, vy1):
    """Full-width horizontals at `hrows` crossed by verticals spanning vy0..vy1."""
    for r in hrows:
        if not (vy0 < r < vy1):
            raise ValueError("horizontal row %d must be strictly inside the vertical span" % r)
    return [hpath(r, 0, w - 1) for r in hrows] + [vpath(c, vy0, vy1) for c in vcols]


def lanes(w, rows):
    return [hpath(r, 0, w - 1) for r in rows]


def validate(level_id, w, h, paths):
    """Mirror of the in-game rules; raises on any violation."""
    occupancy = {}
    for color, path in paths.items():
        if len(path) < 2:
            raise ValueError("%s/%s: path too short" % (level_id, color))
        seen = set()
        for i, cell in enumerate(path):
            x, y = cell
            if not (0 <= x < w and 0 <= y < h):
                raise ValueError("%s/%s: %s outside grid" % (level_id, color, cell))
            if cell in seen:
                raise ValueError("%s/%s: revisits %s" % (level_id, color, cell))
            seen.add(cell)
            if i > 0:
                px, py = path[i - 1]
                if abs(x - px) + abs(y - py) != 1:
                    raise ValueError("%s/%s: non-orthogonal step at %s" % (level_id, color, cell))
            occupancy.setdefault(cell, []).append((color, i))

    crossings = []
    for cell, users in occupancy.items():
        if len(users) == 1:
            continue
        if len(users) > 2:
            raise ValueError("%s: %s used by %d strings" % (level_id, cell, len(users)))
        spans = []
        for color, i in users:
            path = paths[color]
            if i == 0 or i == len(path) - 1:
                raise ValueError("%s: endpoint of '%s' at shared cell %s" % (level_id, color, cell))
            dx = path[i + 1][0] - path[i - 1][0]
            dy = path[i + 1][1] - path[i - 1][1]
            if (abs(dx), abs(dy)) not in ((2, 0), (0, 2)):
                raise ValueError("%s: '%s' turns inside crossing %s" % (level_id, color, cell))
            spans.append((abs(dx), abs(dy)))
        if spans[0] == spans[1]:
            raise ValueError("%s: parallel strings overlap at %s" % (level_id, cell))
        crossings.append(cell)
    return sorted(crossings)


def pick_obstacles(w, h, paths, count):
    """Deterministically picks `count` unused cells, preferring central ones."""
    used = {cell for path in paths.values() for cell in path}
    free = [(x, y) for y in range(h) for x in range(w) if (x, y) not in used]
    centre = ((w - 1) / 2.0, (h - 1) / 2.0)
    free.sort(key=lambda c: (abs(c[0] - centre[0]) + abs(c[1] - centre[1]), c[1], c[0]))
    return sorted(free[:count])


def build(level_id, name, w, h, path_list, n_obstacles=0):
    paths = {COLORS[i]: path for i, path in enumerate(path_list)}
    crossings = validate(level_id, w, h, paths)
    obstacles = pick_obstacles(w, h, paths, n_obstacles)
    return {
        "id": level_id,
        "name": name,
        "grid": {"width": w, "height": h},
        "endpoints": [
            {"color": color, "cells": [list(paths[color][0]), list(paths[color][-1])]}
            for color in paths
        ],
        "obstacles": [list(c) for c in obstacles],
        "crossings": [list(c) for c in crossings],
        "par_length": sum(len(p) - 1 for p in paths.values()),
        "solution": {color: [list(c) for c in paths[color]] for color in paths},
    }


def world1():
    return [
        build("w1_l01", "First Steps", 5, 3, lanes(5, [0, 2])),
        build("w1_l02", "Three Lanes", 5, 5, lanes(5, [0, 2, 4])),
        build("w1_l03", "Around the Block", 6, 5, lanes(6, [0, 2, 4]), 3),
        build("w1_l04", "First Crossing", 5, 5, comb(5, [2], [2], 0, 4)),
        build("w1_l05", "Cross and Lane", 6, 5, lanes(6, [0]) + comb(6, [2], [3], 1, 4), 1),
        build("w1_l06", "Wider Cross", 7, 5, comb(7, [2], [3], 0, 4), 2),
        build("w1_l07", "Over and Under", 5, 5, wrap_band(5, 1, 2)),
        build("w1_l08", "Weave Around", 6, 5, wrap_band(6, 1, 2), 2),
        build("w1_l09", "Two Needles", 7, 5, comb(7, [2], [2, 4], 0, 4)),
        build("w1_l10", "Needles and Knots", 7, 5, comb(7, [2], [2, 4], 0, 4), 3),
        build("w1_l11", "Wrap and Lane", 6, 6, wrap_band(6, 0, 2) + lanes(6, [4]), 2),
        build("w1_l12", "Loom Practice", 7, 6, comb(7, [2, 3], [3], 0, 5)),
        build("w1_l13", "Double Stitch", 7, 7, comb(7, [2, 4], [3], 0, 6), 2),
        build("w1_l14", "Triple Needle", 7, 7, comb(7, [3], [1, 3, 5], 0, 6)),
        build("w1_l15", "Beginner's Loom", 7, 7, comb(7, [2, 4], [2, 4], 0, 6)),
    ]


def world2():
    return [
        build("w2_l01", "Twin Wraps", 6, 7, wrap_band(6, 0, 2) + wrap_band(6, 4, 3)),
        build("w2_l02", "Knotted Lanes", 7, 6, lanes(7, [0]) + comb(7, [2, 4], [3], 1, 5), 2),
        build("w2_l03", "The Loom", 7, 7, comb(7, [2, 4], [2, 4], 0, 6), 3),
        build("w2_l04", "Detour", 7, 6, wrap_band(7, 1, 3) + lanes(7, [5]), 4),
        build("w2_l05", "Crossfire", 7, 7, comb(7, [3], [1, 3, 5], 0, 6), 3),
        build("w2_l06", "Braided", 7, 7, wrap_band(7, 0, 2) + wrap_band(7, 4, 4), 2),
        build("w2_l07", "Compass", 7, 7, comb(7, [1, 3, 5], [3], 0, 6)),
        build("w2_l08", "Thicket", 7, 7, comb(7, [3], [2, 4], 0, 6), 5),
        build("w2_l09", "Switchback", 7, 7, lanes(7, [0, 6]) + wrap_band(7, 2, 3), 2),
        build("w2_l10", "Crosshatch", 7, 7, comb(7, [2, 4], [2, 4], 0, 6), 5),
        build("w2_l11", "Four Posts", 7, 7, comb(7, [1, 5], [1, 5], 0, 6), 2),
        build("w2_l12", "Long Weave", 8, 6, lanes(8, [0]) + comb(8, [3], [2, 5], 1, 5), 3),
        build("w2_l13", "Tight Knit", 7, 7, comb(7, [2, 3, 4], [3], 0, 6), 2),
        build("w2_l14", "Interchange", 7, 7, wrap_band(7, 0, 4) + wrap_band(7, 4, 2), 4),
        build("w2_l15", "Journeyman", 7, 7, comb(7, [2, 4], [2, 4], 0, 6), 6),
    ]


def world3():
    return [
        build("w3_l01", "Triple Loom", 8, 7, comb(8, [2, 4], [2, 5], 0, 6), 3),
        build("w3_l02", "Five Threads", 8, 8, lanes(8, [0]) + comb(8, [2, 5], [2, 5], 1, 7), 2),
        build("w3_l03", "Dense Weave", 8, 8, comb(8, [3, 5], [1, 4, 6], 0, 7)),
        build("w3_l04", "Wrapped Loom", 8, 8, wrap_band(8, 0, 3) + comb(8, [5], [1, 6], 4, 7), 2),
        build("w3_l05", "The Net", 8, 8, comb(8, [2, 4, 6], [3, 5], 0, 7), 2),
        build("w3_l06", "Obstacle Course", 8, 8, lanes(8, [0, 7]) + comb(8, [3], [4], 1, 6), 8),
        build("w3_l07", "Twin Wraps and a Lane", 8, 7, wrap_band(8, 0, 2) + wrap_band(8, 4, 5) + lanes(8, [3]), 3),
        build("w3_l08", "Lattice", 8, 8, comb(8, [2, 5], [2, 4, 6], 0, 7), 1),
        build("w3_l09", "Crowded Loom", 8, 8, comb(8, [1, 3, 5], [3, 6], 0, 7), 3),
        build("w3_l10", "Master's Net", 8, 8, comb(8, [2, 4, 6], [2, 5], 0, 7), 4),
    ]


def world4():
    return [
        build("w4_l01", "Grand Loom", 9, 9, comb(9, [2, 4, 6], [3, 6], 0, 8), 3),
        build("w4_l02", "Six Strings", 9, 9, comb(9, [2, 4, 6], [2, 5, 7], 0, 8)),
        build("w4_l03", "Tangle Town", 9, 8, lanes(9, [0]) + comb(9, [2, 5], [2, 4, 6], 1, 7), 3),
        build("w4_l04", "Wrapped Net", 9, 9, wrap_band(9, 0, 4) + comb(9, [5, 7], [2, 6], 4, 8), 2),
        build("w4_l05", "The Gauntlet", 9, 9, lanes(9, [0, 8]) + comb(9, [4], [2, 4, 6], 1, 7), 8),
        build("w4_l06", "Interlock", 9, 9, wrap_band(9, 0, 3) + wrap_band(9, 4, 5) + lanes(9, [8]), 5),
        build("w4_l07", "Dense Lattice", 9, 9, comb(9, [1, 3, 5, 7], [2, 6], 0, 8), 2),
        build("w4_l08", "Stormfront", 8, 9, comb(8, [2, 4, 6], [3, 5], 0, 8), 6),
        build("w4_l09", "The Great Weave", 9, 9, comb(9, [2, 4, 6], [1, 5, 7], 0, 8), 1),
        build("w4_l10", "Mastery", 9, 9, comb(9, [1, 4, 7], [2, 4, 6], 0, 8), 4),
    ]


def main():
    levels = world1() + world2() + world3() + world4()
    if len(levels) != 50:
        sys.exit("expected 50 levels, built %d" % len(levels))
    for level in levels:
        world, num = level["id"].split("_l")
        path = os.path.join(OUT_DIR, world, "level_%s.json" % num)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(level, f, indent=2)
            f.write("\n")
    print("wrote %d levels" % len(levels))


if __name__ == "__main__":
    main()
