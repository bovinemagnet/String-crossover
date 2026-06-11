extends "res://tests/unit/test_base.gd"

## Headless integration check: the game scene builds, wires the core
## systems together, and the win flow records progress.

const SAVE_PATH := "user://test_game_save.json"

func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func test_game_scene_loads_and_wins() -> void:
	var scene: PackedScene = load("res://src/game/game.tscn")
	assert_not_null(scene)
	var game: Node = scene.instantiate()
	var root: Window = Engine.get_main_loop().root
	root.add_child(game)

	assert_not_null(game.level, "level loaded")
	assert_not_null(game.state, "state created")
	assert_eq(game.level_id, "w1_l01")
	assert_false(game.win_panel.visible)

	game._on_hint()
	game._on_hint()
	assert_true(game.state.is_complete(), "two hints solve the two-colour level")
	assert_true(game.solved)
	assert_true(game.win_panel.visible)
	assert_eq(game.save_manager.stars_for("w1_l01"), 1, "hint-assisted win records 1 star")

	root.remove_child(game)
	game.free()

func test_board_view_cell_mapping() -> void:
	var scene: PackedScene = load("res://src/game/game.tscn")
	var game: Node = scene.instantiate()
	var root: Window = Engine.get_main_loop().root
	root.add_child(game)

	var board: Node2D = game.board
	var centre: Vector2 = board.cell_center(Vector2i(0, 0))
	assert_eq(board.cell_at(centre), Vector2i(0, 0))
	assert_eq(board.cell_at(Vector2(-1000, -1000)), Vector2i(-1, -1), "outside board")

	root.remove_child(game)
	game.free()
