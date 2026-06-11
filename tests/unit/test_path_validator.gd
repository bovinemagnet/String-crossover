extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")
const PathValidator = preload("res://src/core/path_validator.gd")

## 5x5 grid. Red runs horizontally (row 2), blue vertically (column 2).
## Their natural routes meet at the crossing cell (2,2).
const FIXTURE := """
{
  "id": "fixture_cross",
  "name": "Crossing Fixture",
  "grid": { "width": 5, "height": 5 },
  "endpoints": [
    { "color": "red",  "cells": [[0, 2], [4, 2]] },
    { "color": "blue", "cells": [[2, 0], [2, 4]] }
  ],
  "obstacles": [],
  "crossings": [[2, 2]],
  "par_length": 8,
  "solution": {
    "red":  [[0,2],[1,2],[2,2],[3,2],[4,2]],
    "blue": [[2,0],[2,1],[2,2],[2,3],[2,4]]
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

func test_two_straight_strings_cross_legally() -> void:
	assert_true(_route("red", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]]))
	assert_true(_route("blue", [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]]))
	assert_true(state.is_complete())
	assert_eq(state.crossing_count(), 1)

func test_second_string_rejected_at_occupied_non_crossing_cell() -> void:
	_route("red", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]])
	state.begin_path("blue", Vector2i(2, 0))
	state.extend_path("blue", Vector2i(1, 0))
	state.extend_path("blue", Vector2i(1, 1))
	assert_false(state.extend_path("blue", Vector2i(1, 2)), "(1,2) is red's and not a crossing")

func test_rejected_when_first_string_turns_inside_crossing() -> void:
	assert_true(_route("red", [[0, 2], [1, 2], [2, 2], [2, 3], [3, 3], [4, 3], [4, 2]]))
	state.begin_path("blue", Vector2i(2, 0))
	state.extend_path("blue", Vector2i(2, 1))
	assert_false(state.extend_path("blue", Vector2i(2, 2)), "red turns inside the crossing cell")

func test_rejected_when_first_string_head_rests_on_crossing() -> void:
	state.begin_path("red", Vector2i(0, 2))
	state.extend_path("red", Vector2i(1, 2))
	state.extend_path("red", Vector2i(2, 2))
	state.begin_path("blue", Vector2i(2, 0))
	state.extend_path("blue", Vector2i(2, 1))
	assert_false(state.extend_path("blue", Vector2i(2, 2)), "red has not passed through yet")

func test_crossed_string_cannot_turn_onto_other_string() -> void:
	_route("red", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]])
	_route("blue", [[2, 0], [2, 1], [2, 2]])
	assert_false(state.extend_path("blue", Vector2i(3, 2)), "turning at the crossing lands on red")
	assert_true(state.extend_path("blue", Vector2i(2, 3)), "straight through is allowed")

func test_can_extend_rejects_empty_path() -> void:
	assert_false(PathValidator.can_extend(level, state, "red", Vector2i(1, 2)))
