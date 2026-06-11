extends "res://tests/unit/test_base.gd"

const SaveManager = preload("res://src/core/save_manager.gd")

const SAVE_PATH := "user://test_menu_save.json"

func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_use_test_save()

## Points the GameSession autoload (when present) at a throwaway save so
## scene tests never touch the player's real progress.
func _use_test_save() -> void:
	var session: Node = Engine.get_main_loop().root.get_node_or_null("/root/GameSession")
	if session != null:
		session.save_manager = SaveManager.new(SAVE_PATH)

func test_main_menu_builds() -> void:
	var scene: PackedScene = load("res://src/ui/main_menu.tscn")
	assert_not_null(scene)
	var menu: Node = scene.instantiate()
	var root: Window = Engine.get_main_loop().root
	root.add_child(menu)
	assert_not_null(menu.play_button)
	assert_not_null(menu.quit_button)
	root.remove_child(menu)
	menu.free()

func test_level_select_lists_levels_with_lock_state() -> void:
	var scene: PackedScene = load("res://src/ui/level_select.tscn")
	assert_not_null(scene)
	var select: Node = scene.instantiate()
	var root: Window = Engine.get_main_loop().root
	root.add_child(select)

	assert_eq(select.level_buttons.size(), 50, "one button per level")
	assert_false(select.level_buttons["w1_l01"].disabled, "first world unlocked")
	assert_true(select.level_buttons["w2_l01"].disabled, "second world locked on fresh save")
	assert_true(select.level_buttons["w4_l10"].disabled, "last world locked on fresh save")

	root.remove_child(select)
	select.free()

func test_level_select_unlocks_after_progress() -> void:
	var scene: PackedScene = load("res://src/ui/level_select.tscn")
	var select: Node = scene.instantiate()
	# Pre-seed progress: complete all of world 1 with 2 stars each (30 stars).
	var seed_save = SaveManager.new(SAVE_PATH)
	for i in range(1, 16):
		seed_save.record_result("w1_l%02d" % i, 2, 1200)
	_use_test_save()
	var root: Window = Engine.get_main_loop().root
	root.add_child(select)
	assert_false(select.level_buttons["w2_l01"].disabled, "world 2 unlocked at 30 stars")
	assert_true(select.level_buttons["w3_l01"].disabled, "world 3 still locked")
	root.remove_child(select)
	select.free()
