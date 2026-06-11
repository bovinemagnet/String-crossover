extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")
const Scoring = preload("res://src/core/scoring.gd")

## Same crossing fixture as the validator tests: par_length 8.
## 2-star threshold = ceil(8 * 1.25) = 10.
const FIXTURE := """
{
  "id": "fixture_score",
  "name": "Scoring Fixture",
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

const RED_PAR := [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2]]
const RED_LEN_6 := [[0, 2], [0, 1], [1, 1], [1, 2], [2, 2], [3, 2], [4, 2]]
const RED_LEN_8 := [[0, 2], [0, 3], [1, 3], [1, 2], [2, 2], [3, 2], [3, 3], [4, 3], [4, 2]]
const BLUE_PAR := [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]]

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

func test_incomplete_scores_zero_stars_and_points() -> void:
	_route("red", RED_PAR)
	assert_eq(Scoring.stars(level, state), 0)
	assert_eq(Scoring.score(level, state), 0)

func test_three_stars_at_par() -> void:
	assert_true(_route("red", RED_PAR))
	assert_true(_route("blue", BLUE_PAR))
	assert_eq(state.total_length(), 8)
	assert_eq(Scoring.stars(level, state), 3)

func test_two_stars_within_125_percent_of_par() -> void:
	assert_true(_route("red", RED_LEN_6))
	assert_true(_route("blue", BLUE_PAR))
	assert_eq(state.total_length(), 10)
	assert_eq(Scoring.stars(level, state), 2)

func test_one_star_above_threshold() -> void:
	assert_true(_route("red", RED_LEN_8))
	assert_true(_route("blue", BLUE_PAR))
	assert_eq(state.total_length(), 12)
	assert_eq(Scoring.stars(level, state), 1)

func test_hint_caps_at_one_star_even_at_par() -> void:
	_route("red", RED_PAR)
	_route("blue", BLUE_PAR)
	state.hint_used = true
	assert_eq(Scoring.stars(level, state), 1)

func test_score_at_par() -> void:
	_route("red", RED_PAR)
	_route("blue", BLUE_PAR)
	assert_eq(Scoring.score(level, state), 1500)

func test_score_above_par() -> void:
	_route("red", RED_LEN_8)
	_route("blue", BLUE_PAR)
	assert_eq(Scoring.score(level, state), 1333)

func test_hint_penalty() -> void:
	_route("red", RED_PAR)
	_route("blue", BLUE_PAR)
	state.hint_used = true
	assert_eq(Scoring.score(level, state), 1250)
