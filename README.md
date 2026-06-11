# Cross Over Strings

Cross Over Strings is a relaxing puzzle game built with Godot 4.x. Weave coloured strings between matching endpoints across increasingly complex boards — strings may only cross at the marked knots, and the most efficient weave earns the most stars.

## Product Requirements

The full Product Requirements Document is available at:

- [docs/PRD.md](docs/PRD.md)

## Running the Game

Requires [Godot 4.x](https://godotengine.org/).

```sh
godot --path .
```

Or open the project folder in the Godot editor and press Play.

## How to Play

- Press a coloured endpoint and drag to draw its string; release to stop.
- Connect every colour pair to complete the level.
- Strings cannot pass through obstacles (dark cells) or overlap each other.
- Strings may cross only at crossing cells (diamond markers), and both strings must pass straight through.
- Shorter weaves earn more stars: 3★ at or under par, 2★ within 25% of par, 1★ for any completion. Using a hint caps the level at 1★.

### Controls

| Input | Action |
| --- | --- |
| Left mouse drag | Draw a string from an endpoint (or its current head) |
| `Z` | Undo |
| `R` | Restart level |
| `H` | Hint (solves one colour, caps stars) |
| `Esc` | Back to level select |

## Campaign

50 levels across four worlds — Beginner (15), Intermediate (15), Advanced (10) and Expert (10). Later worlds unlock by completing the previous world and earning enough total stars. Progress is saved automatically to `user://save.json`.

## Development

### Running the Tests

```sh
godot --headless --path . --script res://tests/test_runner.gd
```

The runner discovers `tests/unit/test_*.gd`, runs every `test_*` method and exits non-zero on failure. The suite includes a validation test that replays every level's stored solution through the real game rules.

### Project Structure

```
src/core/      Pure game logic (level data, rules, scoring, saves, hints, catalog)
src/game/      Playable scene: board rendering, input, HUD, session autoload
src/ui/        Main menu and level select
levels/        catalog.json plus one JSON file per level
tests/         Headless test runner and unit tests
tools/         generate_levels.py — level authoring tool
```

### Level Format

Levels are JSON files (see `levels/w1/level_01.json`):

```json
{
  "id": "w1_l01",
  "name": "First Steps",
  "grid": { "width": 5, "height": 3 },
  "endpoints": [
    { "color": "red", "cells": [[0, 0], [4, 0]] }
  ],
  "obstacles": [[2, 1]],
  "crossings": [[3, 1]],
  "par_length": 8,
  "solution": { "red": [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]] }
}
```

`solution` is a worked solution used by the hint system and by the automated level validation; `par_length` is its total length and sets the 3★ threshold. The 50 campaign levels are produced by `tools/generate_levels.py`, which validates every level against the game rules before writing it.
