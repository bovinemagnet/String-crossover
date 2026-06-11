extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")

const VALID_JSON := """
{
  "id": "w1_l01",
  "name": "First Steps",
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

func test_parses_valid_level() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_not_null(level)
	assert_eq(level.id, "w1_l01")
	assert_eq(level.level_name, "First Steps")
	assert_eq(level.width, 5)
	assert_eq(level.height, 3)
	assert_eq(level.par_length, 8)

func test_parses_endpoints() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_eq(level.colors(), ["red", "blue"])
	assert_eq(level.endpoints["red"], [Vector2i(0, 0), Vector2i(4, 0)])
	assert_eq(level.endpoints["blue"], [Vector2i(0, 2), Vector2i(4, 2)])

func test_parses_obstacles_and_crossings() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_eq(level.obstacles, [Vector2i(2, 1)])
	assert_eq(level.crossings, [Vector2i(3, 1)])

func test_parses_solution() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_eq(level.solution["red"].size(), 5)
	assert_eq(level.solution["red"][0], Vector2i(0, 0))
	assert_eq(level.solution["blue"][4], Vector2i(4, 2))

func test_cell_queries() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_true(level.is_inside(Vector2i(0, 0)))
	assert_true(level.is_inside(Vector2i(4, 2)))
	assert_false(level.is_inside(Vector2i(5, 0)))
	assert_false(level.is_inside(Vector2i(-1, 0)))
	assert_true(level.is_obstacle(Vector2i(2, 1)))
	assert_false(level.is_obstacle(Vector2i(0, 0)))
	assert_true(level.is_crossing(Vector2i(3, 1)))
	assert_false(level.is_crossing(Vector2i(2, 1)))
	assert_eq(level.endpoint_color_at(Vector2i(0, 0)), "red")
	assert_eq(level.endpoint_color_at(Vector2i(4, 2)), "blue")
	assert_eq(level.endpoint_color_at(Vector2i(1, 1)), "")

func test_other_endpoint() -> void:
	var level = LevelData.from_json(VALID_JSON)
	assert_eq(level.other_endpoint("red", Vector2i(0, 0)), Vector2i(4, 0))
	assert_eq(level.other_endpoint("red", Vector2i(4, 0)), Vector2i(0, 0))

func test_invalid_json_returns_null() -> void:
	assert_null(LevelData.from_json("not json"))
	assert_true(LevelData.last_error != "")

func test_missing_grid_returns_null() -> void:
	assert_null(LevelData.from_json('{"id": "x", "endpoints": []}'))
	assert_true(LevelData.last_error != "")

func test_endpoint_needs_two_cells() -> void:
	var bad := '{"id":"x","name":"x","grid":{"width":3,"height":3},"endpoints":[{"color":"red","cells":[[0,0]]}],"obstacles":[],"crossings":[],"par_length":1,"solution":{"red":[[0,0]]}}'
	assert_null(LevelData.from_json(bad))
	assert_true(LevelData.last_error != "")

func test_loads_from_file() -> void:
	var level = LevelData.from_file("res://levels/w1/level_01.json")
	assert_not_null(level)
	assert_eq(level.id, "w1_l01")

func test_missing_file_returns_null() -> void:
	assert_null(LevelData.from_file("res://levels/does_not_exist.json"))
	assert_true(LevelData.last_error != "")
