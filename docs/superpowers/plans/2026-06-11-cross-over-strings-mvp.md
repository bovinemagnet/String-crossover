# Cross Over Strings MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MVP of Cross Over Strings — a Godot 4.x grid puzzle game where players route coloured strings between matching endpoints, crossing only at designated crossing cells — covering all PRD "Must Have" items: 50 levels, basic connections, crossing mechanics, star scoring, save/load, and a hint system.

**Architecture:** A pure-logic GDScript core (`src/core/`) with no scene dependencies, fully unit-tested via a headless custom test runner (`godot --headless --script res://tests/test_runner.gd`). A thin scene layer (`src/ui/`, `src/game/`) renders the board with `Line2D` strings and handles drag input. Levels are JSON files under `levels/`, each carrying its own solution (used for hints and for automated validation of all 50 levels).

**Tech Stack:** Godot 4.6 (GDScript), JSON level data, custom headless test runner. No external addons.

---

## Game Model (locked-in design decisions)

- **Grid-cell routing (Flow-Free style).** A string is an ordered list of orthogonally adjacent cells starting at one endpoint of a colour and ending at the other.
- **Cell occupancy rules:**
  - Obstacle cells can never be entered.
  - A normal cell may be occupied by at most one string, at most once (no overlap, no self-intersection).
  - A **crossing cell** may be occupied by at most two *different* strings, and each must pass **straight through** (enter and exit on opposite sides). A single string passes through a crossing cell like a normal cell (straight or turning) when it is the only occupant — but a turn in a crossing cell blocks the cross, which is legal but wasteful.
  - Endpoint cells belong to their colour only; a path must start/end on its own endpoints and may not pass through any endpoint mid-path (its own or another colour's).
- **Completion:** every colour pair connected with all rules satisfied. Filling the whole board is NOT required.
- **Stars** (no time pressure in MVP): 1★ = completed; 2★ = total length ≤ ceil(par × 1.25) and no hint used; 3★ = total length ≤ par and no hint used.
- **Score** = 1000 base + efficiency bonus (par/length scaled) − 250 per hint.
- **Hints:** reveal the stored solution path for one unsolved colour; flags the attempt as hint-assisted.
- **Worlds/unlocks:** 4 worlds (Beginner w1: 15 levels, Intermediate w2: 15, Advanced w3: 10, Expert w4: 10 → 50 total). World N+1 unlocks when all of world N is completed AND total stars ≥ threshold in `levels/catalog.json`.
- **Save:** JSON at `user://save.json` — per-level best stars/score plus settings.

## File Structure

```
project.godot
icon.svg
src/core/level_data.gd        # Parse/hold one level's JSON (grid, endpoints, obstacles, crossings, par, solution)
src/core/puzzle_state.gd      # Mutable in-play state: paths per colour, add/remove, occupancy queries
src/core/path_validator.gd    # Static rule checks: step legality, path legality, crossing rules, completion
src/core/scoring.gd           # Stars + score from state vs level par
src/core/save_manager.gd      # Load/save user progress JSON
src/core/hint_system.gd       # Apply solution path for one unsolved colour
src/core/level_catalog.gd     # Worlds, level lists, unlock logic (reads levels/catalog.json)
src/game/game_controller.gd   # Game scene script: input → puzzle_state, win detection, HUD
src/game/board_view.gd        # Draw grid, endpoints, obstacles, crossings, Line2D strings
src/ui/main_menu.gd/.tscn
src/ui/level_select.gd/.tscn
src/game/game.tscn
levels/catalog.json
levels/w1/level_01.json ... levels/w4/level_10.json   # 50 levels
tests/test_runner.gd          # Headless runner: discovers tests/unit/test_*.gd
tests/unit/test_*.gd
```

---

### Task 1: Project scaffold + headless test runner

**Files:** Create `project.godot`, `icon.svg`, `tests/test_runner.gd`, `tests/unit/test_smoke.gd`.

- [ ] Create a minimal Godot 4 `project.godot` (name "Cross Over Strings", main scene `res://src/ui/main_menu.tscn` added later; leave run/main_scene unset for now).
- [ ] Write `tests/test_runner.gd` — a `SceneTree` script that loads every `tests/unit/test_*.gd`, instantiates it, calls every `test_*` method, counts failures via an `assert_eq/assert_true` helper base class (`tests/unit/test_base.gd`), prints a summary, and quits with exit code 1 on any failure.
- [ ] Write `tests/unit/test_smoke.gd` with one passing test.
- [ ] Run: `godot --headless --path . --script res://tests/test_runner.gd` → expect `0 failures`, exit 0.
- [ ] Commit.

### Task 2: LevelData (JSON parsing)

**Files:** Create `src/core/level_data.gd`, `tests/unit/test_level_data.gd`, `levels/w1/level_01.json`.

Level JSON schema (canonical example — this exact file becomes w1/level_01):

```json
{
  "id": "w1_l01",
  "name": "First Steps",
  "grid": { "width": 5, "height": 3 },
  "endpoints": [
    { "color": "red",  "cells": [[0, 0], [4, 0]] },
    { "color": "blue", "cells": [[0, 2], [4, 2]] }
  ],
  "obstacles": [],
  "crossings": [],
  "par_length": 10,
  "solution": {
    "red":  [[0,0],[1,0],[2,0],[3,0],[4,0]],
    "blue": [[0,2],[1,2],[2,2],[3,2],[4,2]]
  }
}
```

- [ ] Failing tests: parse from JSON string → width/height, endpoint colours and cells as `Vector2i`, obstacles/crossings as `Vector2i` arrays, par_length, solution paths; error on missing/invalid fields (`from_json` returns null and `last_error` set); helper queries `is_inside(cell)`, `is_obstacle(cell)`, `is_crossing(cell)`, `endpoint_color_at(cell)`.
- [ ] Run tests → fail. Implement `level_data.gd`. Run tests → pass. Commit.

### Task 3: PuzzleState (paths + occupancy)

**Files:** Create `src/core/puzzle_state.gd`, `tests/unit/test_puzzle_state.gd`.

API: `PuzzleState.new(level)`; `begin_path(color, cell) -> bool` (must be that colour's endpoint; clears existing path for colour); `extend_path(color, cell) -> bool` (delegates legality to PathValidator, supports backtracking by re-entering the previous cell); `clear_path(color)`; `get_path(color) -> Array[Vector2i]`; `occupants_of(cell) -> Array[String]`; `is_color_complete(color)`; `is_complete()`; `total_length()`; `crossing_count()`; `undo()` (undo stack of path snapshots); `hint_used` flag.

- [ ] Failing tests covering: begin on endpoint vs non-endpoint, extend to adjacent free cell, reject non-adjacent, backtrack shortens path, complete when reaching paired endpoint, clear, undo restores, total_length sums segments (cells−1 per path), crossing_count counts crossing cells with two occupants.
- [ ] Run → fail. Implement. Run → pass. Commit.

### Task 4: PathValidator (rules)

**Files:** Create `src/core/path_validator.gd`, `tests/unit/test_path_validator.gd`.

Static funcs: `can_extend(level, state, color, cell) -> bool` and `is_path_complete(level, color, path) -> bool`, plus `validate_full_path(level, occupied_by_others, color, path) -> bool` used by tests and level validation. Rules enforced:
1. cell inside grid, not an obstacle;
2. orthogonally adjacent to current path head;
3. not already in own path (no self-intersection) — except immediate backtrack handled by PuzzleState;
4. no other-colour endpoint, and own endpoint only as terminal;
5. normal cell: free of other strings; crossing cell: at most one other string, and after entry both strings must be straight-through (entry/exit on opposite sides) — a path may not END on a crossing cell occupied by another string, and a turning string blocks a second occupant.

- [ ] Failing tests: each rule above with a small fixture level (5×5, one obstacle, one crossing, red/blue endpoints), including: two straight strings legally crossing at the crossing cell; second string rejected at a non-crossing occupied cell; second string rejected when first string turns inside the crossing cell; second string rejected when it would have to turn in the occupied crossing cell.
- [ ] Run → fail. Implement. Run → pass. Commit.

### Task 5: Scoring

**Files:** Create `src/core/scoring.gd`, `tests/unit/test_scoring.gd`.

`Scoring.stars(level, state) -> int` (0 if not complete; thresholds per the locked-in design, hint caps at 1★? — no: hint disallows 2★/3★, completed always ≥1★). `Scoring.score(level, state) -> int` = `1000 + int(500.0 * level.par_length / max(state.total_length(), 1)) - (250 if state.hint_used else 0)`, floor 0.

- [ ] Failing tests: incomplete → 0 stars; complete at par → 3★; complete at ceil(par×1.25) → 2★; above → 1★; hint → 1★ even at par; score formula exact values.
- [ ] Run → fail. Implement. Run → pass. Commit.

### Task 6: SaveManager

**Files:** Create `src/core/save_manager.gd`, `tests/unit/test_save_manager.gd`.

Instance class with injectable path (default `user://save.json`; tests use `user://test_save.json` and delete after). API: `load_save()`, `record_result(level_id, stars, score)` (keeps best), `stars_for(level_id)`, `total_stars()`, `completed_ids()`, `save()` writes JSON, survives reload; corrupt file → fresh save.

- [ ] Failing tests for the above. Run → fail. Implement. Run → pass. Commit.

### Task 7: HintSystem

**Files:** Create `src/core/hint_system.gd`, `tests/unit/test_hint_system.gd`.

`HintSystem.apply_hint(level, state) -> String` — pick the first colour (catalog order) that is not complete, clear its current path, replay the solution path through `begin_path`/`extend_path` (clearing any colliding other-colour paths first by checking solution cells vs `occupants_of`), set `state.hint_used = true`, return the colour hinted ("" if all complete).

- [ ] Failing tests: hint completes one colour; hint sets `hint_used`; hint clears a conflicting partial path of another colour; returns "" when solved.
- [ ] Run → fail. Implement. Run → pass. Commit.

### Task 8: LevelCatalog + unlocks

**Files:** Create `src/core/level_catalog.gd`, `levels/catalog.json`, `tests/unit/test_level_catalog.gd`.

`levels/catalog.json`:

```json
{
  "worlds": [
    { "id": "w1", "name": "Beginner",     "levels": ["w1_l01", "..."], "unlock_stars": 0 },
    { "id": "w2", "name": "Intermediate", "levels": ["..."],           "unlock_stars": 20 },
    { "id": "w3", "name": "Advanced",     "levels": ["..."],           "unlock_stars": 45 },
    { "id": "w4", "name": "Expert",       "levels": ["..."],           "unlock_stars": 70 }
  ]
}
```

API: `load_catalog()`, `worlds()`, `level_ids(world_id)`, `level_path(level_id)` (= `res://levels/<world>/level_<nn>.json`), `is_world_unlocked(world_id, save)` (previous world fully completed AND `save.total_stars() >= unlock_stars`), `next_level_id(level_id)`.

- [ ] Failing tests with a small injected catalog dictionary (not the real file): unlock logic both gates, next-level sequencing across worlds. Plus one test that loads the real `levels/catalog.json` and asserts 4 worlds / 50 level ids.
- [ ] Run → fail (catalog file can list only w1_l01 initially — write the full 50-id catalog in this task). Implement. Run → pass. Commit.

### Task 9: 50 levels + automated validation

**Files:** Create `levels/w1/level_01..15.json`, `levels/w2/level_01..15.json`, `levels/w3/level_01..10.json`, `levels/w4/level_01..10.json`, `tests/unit/test_levels_valid.gd`.

Difficulty ramp: w1 = 2–3 colours, 5×5, no/one crossing; w2 = 3–4 colours, 6×6–7×7, obstacles + crossings; w3 = 4–5 colours, 7×7–8×8, multiple crossings + crossing-heavy layouts; w4 = 5–6 colours, 8×8–9×9, dense weaves. Each level hand-authored as JSON with a worked solution; `par_length` = solution total length.

- [ ] Write `tests/unit/test_levels_valid.gd`: for every level id in the catalog — file loads via LevelData; every colour has exactly 2 endpoints; solution exists for every colour; replaying every solution through PuzzleState/PathValidator completes the level; `par_length` equals solution total length; all solution/obstacle/crossing/endpoint cells inside grid.
- [ ] Author the 50 level files (this test is the safety net — any broken hand-authored level fails CI).
- [ ] Run → pass for all 50. Commit (levels may be committed in world-sized batches).

### Task 10: Board view + game scene (rendering & input)

**Files:** Create `src/game/board_view.gd`, `src/game/game_controller.gd`, `src/game/game.tscn`.

- BoardView (`Node2D`): given a LevelData + PuzzleState, computes cell size/offsets; `_draw()` renders grid lines, obstacle squares, crossing diamonds, endpoint circles (colour map incl. colour-blind-distinct palette), and strings as `Line2D` children (rounded joints/caps, width ~cell/3); converts mouse position ↔ cell.
- GameController (`game.tscn` root): loads level by id (passed via a static `GameSession.level_id`), mouse handling — press on endpoint/path-head begins/resumes drag, motion extends via `extend_path` (greedy per-cell), release ends drag; keyboard: `Z`/`Ctrl+Z` undo, `R` restart, `H` hint, `Esc` back; HUD labels (level name, length vs par, crossings); on `is_complete()` → compute stars/score, `save_manager.record_result`, show win panel with star count + Next/Replay/Menu buttons.

- [ ] Build scene + scripts; verify headless project load has no script errors: `godot --headless --path . --quit` (and unit suite still green).
- [ ] Manual/scripted smoke: run `godot --path .` briefly to confirm scene loads (visual check optional in autonomous mode — rely on `--quit-after` + no errors).
- [ ] Commit.

### Task 11: Menus + flow wiring

**Files:** Create `src/ui/main_menu.tscn/.gd`, `src/ui/level_select.tscn/.gd`, `src/game/game_session.gd` (autoload holding `level_id`, shared SaveManager/LevelCatalog), set `run/main_scene` in `project.godot`.

- Main menu: title + Play + Quit.
- Level select: world tabs/sections; level buttons show stars earned; locked worlds greyed with star requirement label; clicking a level sets `GameSession.level_id` and changes scene to `game.tscn`; win panel "Next" advances via `next_level_id`.

- [ ] Build scenes/scripts; `godot --headless --path . --quit` clean; unit suite green.
- [ ] Commit.

### Task 12: Final verification + docs

- [ ] Full test run: `godot --headless --path . --script res://tests/test_runner.gd` → 0 failures.
- [ ] Project boots headless without errors: `godot --headless --path . --quit-after 60`.
- [ ] Update `README.md`: how to run the game, run tests, level JSON format, controls.
- [ ] Commit.

## Self-Review Notes

- PRD MVP Must-Haves → tasks: 50 levels (T9), basic connections (T3/T4/T10), crossing mechanics (T4), star scoring (T5), save/load (T6), hint system (T7). Menus/unlocks (T8/T11) support the game loop ("unlock next level").
- Out of MVP scope intentionally: daily puzzles, leaderboards, achievements, string types, tension, layers, audio, monetisation, controller support (PRD lists these as Nice-to-Have/Future or post-MVP polish).
- Types consistent: cells are `Vector2i` everywhere; colours are lowercase strings; paths are `Array[Vector2i]`.
