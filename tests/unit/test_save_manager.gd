extends "res://tests/unit/test_base.gd"

const SaveManager = preload("res://src/core/save_manager.gd")

const TEST_PATH := "user://test_save.json"

func before_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

func test_fresh_save_is_empty() -> void:
	var manager = SaveManager.new(TEST_PATH)
	assert_eq(manager.stars_for("w1_l01"), 0)
	assert_eq(manager.total_stars(), 0)
	assert_eq(manager.completed_ids(), [])

func test_record_result() -> void:
	var manager = SaveManager.new(TEST_PATH)
	manager.record_result("w1_l01", 3, 1500)
	assert_eq(manager.stars_for("w1_l01"), 3)
	assert_eq(manager.score_for("w1_l01"), 1500)
	assert_eq(manager.completed_ids(), ["w1_l01"])

func test_record_keeps_best() -> void:
	var manager = SaveManager.new(TEST_PATH)
	manager.record_result("w1_l01", 3, 1400)
	manager.record_result("w1_l01", 1, 1500)
	assert_eq(manager.stars_for("w1_l01"), 3, "best stars kept")
	assert_eq(manager.score_for("w1_l01"), 1500, "best score kept")

func test_total_stars() -> void:
	var manager = SaveManager.new(TEST_PATH)
	manager.record_result("w1_l01", 3, 1500)
	manager.record_result("w1_l02", 2, 1400)
	assert_eq(manager.total_stars(), 5)

func test_persists_across_instances() -> void:
	var manager = SaveManager.new(TEST_PATH)
	manager.record_result("w1_l01", 2, 1200)
	var reloaded = SaveManager.new(TEST_PATH)
	assert_eq(reloaded.stars_for("w1_l01"), 2)
	assert_eq(reloaded.score_for("w1_l01"), 1200)

func test_corrupt_file_gives_fresh_save() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ not json !!")
	file.close()
	var manager = SaveManager.new(TEST_PATH)
	assert_eq(manager.total_stars(), 0)
	manager.record_result("w1_l01", 1, 1000)
	assert_eq(SaveManager.new(TEST_PATH).stars_for("w1_l01"), 1, "recovers and persists")
