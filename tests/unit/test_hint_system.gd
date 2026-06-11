extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")
const HintSystem = preload("res://src/core/hint_system.gd")

const FIXTURE := """
{
  "id": "fixture_hint",
  "name": "Hint Fixture",
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

func test_hint_completes_first_unsolved_color() -> void:
	assert_eq(HintSystem.apply_hint(level, state), "red")
	assert_true(state.is_color_complete("red"))
	assert_eq(state.get_path("red"), [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)])

func test_hint_sets_hint_used() -> void:
	HintSystem.apply_hint(level, state)
	assert_true(state.hint_used)

func test_hint_skips_completed_colors() -> void:
	_route("red", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]])
	assert_eq(HintSystem.apply_hint(level, state), "blue")
	assert_true(state.is_color_complete("blue"))

func test_hint_clears_conflicting_partial_path() -> void:
	assert_true(_route("blue", [[2, 0], [1, 0], [1, 1], [1, 2]]))
	assert_eq(HintSystem.apply_hint(level, state), "red")
	assert_true(state.is_color_complete("red"))
	assert_eq(state.get_path("blue"), [], "blue's blocking path was cleared")

func test_hint_preserves_legal_crossing() -> void:
	assert_true(_route("blue", [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]]))
	assert_eq(HintSystem.apply_hint(level, state), "red")
	assert_true(state.is_complete(), "red crosses blue legally, both intact")

func test_hint_returns_empty_when_solved() -> void:
	_route("red", [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]])
	_route("blue", [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]])
	assert_eq(HintSystem.apply_hint(level, state), "")
	assert_false(state.hint_used, "no hint consumed when already solved")
