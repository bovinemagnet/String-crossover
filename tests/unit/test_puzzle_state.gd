extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")

## 5x3 grid. Red endpoints across the top row, blue across the bottom.
## Obstacle at (2,1), crossing cell at (3,1).
const FIXTURE := """
{
  "id": "fixture",
  "name": "Fixture",
  "grid": { "width": 5, "height": 3 },
  "endpoints": [
    { "color": "red",  "cells": [[0, 0], [4, 0]] },
    { "color": "blue", "cells": [[0, 2], [4, 2]] }
  ],
  "obstacles": [[2, 1]],
  "crossings": [[3, 1]],
  "par_length": 8,
  "solution": {
    "red":  [[0,0],[1,0],[2,0],[3,0],[4,0]],
    "blue": [[0,2],[1,2],[2,2],[3,2],[4,2]]
  }
}
"""

var level
var state

func before_each() -> void:
	level = LevelData.from_json(FIXTURE)
	state = PuzzleState.new(level)

func _route(color: String, cells: Array) -> bool:
	if not state.begin_path(color, Vector2i(cells[0][0], cells[0][1])):
		return false
	for i in range(1, cells.size()):
		if not state.extend_path(color, Vector2i(cells[i][0], cells[i][1])):
			return false
	return true

func test_begin_path_on_endpoint() -> void:
	assert_true(state.begin_path("red", Vector2i(0, 0)))
	assert_eq(state.get_path("red"), [Vector2i(0, 0)])

func test_begin_path_on_either_endpoint() -> void:
	assert_true(state.begin_path("red", Vector2i(4, 0)))

func test_begin_path_rejects_non_endpoint() -> void:
	assert_false(state.begin_path("red", Vector2i(1, 0)))
	assert_false(state.begin_path("red", Vector2i(0, 2)), "blue endpoint is not red's")
	assert_eq(state.get_path("red"), [])

func test_extend_to_adjacent_free_cell() -> void:
	state.begin_path("red", Vector2i(0, 0))
	assert_true(state.extend_path("red", Vector2i(1, 0)))
	assert_eq(state.get_path("red"), [Vector2i(0, 0), Vector2i(1, 0)])

func test_extend_rejects_non_adjacent() -> void:
	state.begin_path("red", Vector2i(0, 0))
	assert_false(state.extend_path("red", Vector2i(2, 0)))
	assert_false(state.extend_path("red", Vector2i(1, 1)), "diagonal is not adjacent")

func test_extend_rejects_obstacle() -> void:
	state.begin_path("red", Vector2i(0, 0))
	state.extend_path("red", Vector2i(0, 1))
	state.extend_path("red", Vector2i(1, 1))
	assert_false(state.extend_path("red", Vector2i(2, 1)))

func test_extend_rejects_outside_grid() -> void:
	state.begin_path("red", Vector2i(0, 0))
	assert_false(state.extend_path("red", Vector2i(-1, 0)))

func test_extend_rejects_own_path_cell() -> void:
	state.begin_path("red", Vector2i(0, 0))
	state.extend_path("red", Vector2i(0, 1))
	state.extend_path("red", Vector2i(1, 1))
	state.extend_path("red", Vector2i(1, 0))
	assert_false(state.extend_path("red", Vector2i(0, 0)), "would re-enter start endpoint")

func test_extend_rejects_other_color_endpoint() -> void:
	state.begin_path("red", Vector2i(0, 0))
	state.extend_path("red", Vector2i(0, 1))
	assert_false(state.extend_path("red", Vector2i(0, 2)), "blue endpoint")

func test_extend_rejects_cell_occupied_by_other_string() -> void:
	_route("blue", [[0, 2], [1, 2], [1, 1]])
	state.begin_path("red", Vector2i(0, 0))
	state.extend_path("red", Vector2i(1, 0))
	assert_false(state.extend_path("red", Vector2i(1, 1)))

func test_backtrack_shortens_path() -> void:
	state.begin_path("red", Vector2i(0, 0))
	state.extend_path("red", Vector2i(1, 0))
	state.extend_path("red", Vector2i(1, 1))
	assert_true(state.extend_path("red", Vector2i(1, 0)), "re-entering previous cell backtracks")
	assert_eq(state.get_path("red"), [Vector2i(0, 0), Vector2i(1, 0)])

func test_color_complete_when_reaching_pair() -> void:
	assert_true(_route("red", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]))
	assert_true(state.is_color_complete("red"))
	assert_false(state.is_complete(), "blue not routed yet")

func test_extend_rejected_after_complete() -> void:
	_route("red", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]])
	assert_false(state.extend_path("red", Vector2i(4, 1)))

func test_is_complete_when_all_colors_routed() -> void:
	_route("red", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]])
	_route("blue", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]])
	assert_true(state.is_complete())

func test_begin_path_clears_existing_path() -> void:
	_route("red", [[0, 0], [1, 0]])
	state.begin_path("red", Vector2i(4, 0))
	assert_eq(state.get_path("red"), [Vector2i(4, 0)])

func test_clear_path() -> void:
	_route("red", [[0, 0], [1, 0]])
	state.clear_path("red")
	assert_eq(state.get_path("red"), [])

func test_undo_restores_previous_snapshot() -> void:
	_route("red", [[0, 0], [1, 0], [2, 0]])
	_route("blue", [[0, 2], [1, 2]])
	assert_true(state.undo(), "undo removes blue's drag")
	assert_eq(state.get_path("blue"), [])
	assert_eq(state.get_path("red"), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	assert_true(state.undo(), "undo removes red's drag")
	assert_eq(state.get_path("red"), [])
	assert_false(state.undo(), "nothing left to undo")

func test_total_length() -> void:
	_route("red", [[0, 0], [1, 0], [2, 0]])
	_route("blue", [[0, 2], [1, 2]])
	assert_eq(state.total_length(), 3)

func test_occupants_of() -> void:
	_route("red", [[0, 0], [1, 0]])
	assert_eq(state.occupants_of(Vector2i(1, 0)), ["red"])
	assert_eq(state.occupants_of(Vector2i(2, 2)), [])

func test_crossing_count_zero_when_unused() -> void:
	_route("red", [[0, 0], [1, 0], [2, 0]])
	assert_eq(state.crossing_count(), 0)

func test_hint_used_defaults_false() -> void:
	assert_false(state.hint_used)
