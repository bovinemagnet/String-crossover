extends "res://tests/unit/test_base.gd"

const LevelCatalog = preload("res://src/core/level_catalog.gd")
const SaveManager = preload("res://src/core/save_manager.gd")

const SAVE_PATH := "user://test_catalog_save.json"

const SMALL_CATALOG := {
	"worlds": [
		{"id": "w1", "name": "One", "levels": ["w1_l01", "w1_l02"], "unlock_stars": 0},
		{"id": "w2", "name": "Two", "levels": ["w2_l01", "w2_l02"], "unlock_stars": 3},
	]
}

var catalog
var save

func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	catalog = LevelCatalog.from_dict(SMALL_CATALOG)
	save = SaveManager.new(SAVE_PATH)

func test_worlds_and_level_ids() -> void:
	assert_eq(catalog.worlds().size(), 2)
	assert_eq(catalog.worlds()[0]["name"], "One")
	assert_eq(catalog.level_ids("w1"), ["w1_l01", "w1_l02"])
	assert_eq(catalog.level_ids("missing"), [])

func test_level_path() -> void:
	assert_eq(catalog.level_path("w1_l01"), "res://levels/w1/level_01.json")
	assert_eq(catalog.level_path("w2_l02"), "res://levels/w2/level_02.json")

func test_first_world_always_unlocked() -> void:
	assert_true(catalog.is_world_unlocked("w1", save))

func test_world_locked_until_previous_completed() -> void:
	assert_false(catalog.is_world_unlocked("w2", save))
	save.record_result("w1_l01", 3, 1500)
	assert_false(catalog.is_world_unlocked("w2", save), "w1_l02 still incomplete")
	save.record_result("w1_l02", 1, 1000)
	assert_true(catalog.is_world_unlocked("w2", save), "4 stars >= 3 required")

func test_world_locked_below_star_threshold() -> void:
	var strict = LevelCatalog.from_dict({
		"worlds": [
			{"id": "w1", "name": "One", "levels": ["w1_l01", "w1_l02"], "unlock_stars": 0},
			{"id": "w2", "name": "Two", "levels": ["w2_l01"], "unlock_stars": 5},
		]
	})
	save.record_result("w1_l01", 1, 1000)
	save.record_result("w1_l02", 1, 1000)
	assert_false(strict.is_world_unlocked("w2", save), "2 stars < 5 required")

func test_next_level_id() -> void:
	assert_eq(catalog.next_level_id("w1_l01"), "w1_l02")
	assert_eq(catalog.next_level_id("w1_l02"), "w2_l01", "advances across worlds")
	assert_eq(catalog.next_level_id("w2_l02"), "", "no level after the last")

func test_real_catalog_has_four_worlds_and_fifty_levels() -> void:
	var real = LevelCatalog.load_catalog()
	assert_not_null(real)
	assert_eq(real.worlds().size(), 4)
	var all_ids := {}
	var count := 0
	for world in real.worlds():
		for level_id in world["levels"]:
			all_ids[level_id] = true
			count += 1
	assert_eq(count, 50)
	assert_eq(all_ids.size(), 50, "level ids are unique")
