extends "res://tests/unit/test_base.gd"

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")
const LevelCatalog = preload("res://src/core/level_catalog.gd")

## Every level in the catalog must load, be well-formed, and have a stored
## solution that replays cleanly through the real game rules.
func test_all_levels_valid() -> void:
	var catalog = LevelCatalog.load_catalog()
	assert_not_null(catalog, "catalog loads")
	for world in catalog.worlds():
		for level_id in world["levels"]:
			_check_level(catalog, level_id)

func _check_level(catalog: Variant, level_id: String) -> void:
	var file_path: String = catalog.level_path(level_id)
	var level = LevelData.from_file(file_path)
	assertions += 1
	if level == null:
		_fail("%s: cannot load (%s)" % [level_id, LevelData.last_error])
		return
	assert_eq(level.id, level_id, "id matches catalog")

	for cell in level.obstacles:
		assert_true(level.is_inside(cell), "%s: obstacle %s inside grid" % [level_id, cell])
		assert_eq(level.endpoint_color_at(cell), "", "%s: obstacle %s not on endpoint" % [level_id, cell])
	for cell in level.crossings:
		assert_true(level.is_inside(cell), "%s: crossing %s inside grid" % [level_id, cell])
		assert_false(level.is_obstacle(cell), "%s: crossing %s not an obstacle" % [level_id, cell])
		assert_eq(level.endpoint_color_at(cell), "", "%s: crossing %s not on endpoint" % [level_id, cell])
	for color in level.colors():
		for cell in level.endpoints[color]:
			assert_true(level.is_inside(cell), "%s: endpoint %s inside grid" % [level_id, cell])

	var state = PuzzleState.new(level)
	for color in level.colors():
		assertions += 1
		if not level.solution.has(color):
			_fail("%s: no solution for '%s'" % [level_id, color])
			return
		var sol: Array = level.solution[color]
		assertions += 1
		if not state.begin_path(color, sol[0]):
			_fail("%s: solution for '%s' does not start on an endpoint" % [level_id, color])
			return
		for i in range(1, sol.size()):
			assertions += 1
			if not state.extend_path(color, sol[i]):
				_fail("%s: solution for '%s' is illegal at %s (step %d)" % [level_id, color, sol[i], i])
				return
		assert_true(state.is_color_complete(color), "%s: solution completes '%s'" % [level_id, color])

	assert_true(state.is_complete(), "%s: all colours complete" % level_id)
	assert_eq(state.total_length(), level.par_length, "%s: par_length matches solution" % level_id)
