extends Control
## World and level picker. Shows earned stars and world lock state.

const SaveManager = preload("res://src/core/save_manager.gd")
const LevelCatalog = preload("res://src/core/level_catalog.gd")

const GAME_SCENE := "res://src/game/game.tscn"
const MAIN_MENU_SCENE := "res://src/ui/main_menu.tscn"

var save_manager: Variant
var catalog: Variant
var level_buttons: Dictionary = {}

func _ready() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		save_manager = session.save_manager
		catalog = session.catalog
	else:
		save_manager = SaveManager.new("user://test_menu_save.json")
		catalog = LevelCatalog.load_catalog()
	_build_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("1d2233")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Select Level"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var stars_label := Label.new()
	stars_label.text = "Total: %d ★" % save_manager.total_stars()
	header.add_child(stars_label)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	header.add_child(back)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var worlds_box := VBoxContainer.new()
	worlds_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	worlds_box.add_theme_constant_override("separation", 16)
	scroll.add_child(worlds_box)

	for world in catalog.worlds():
		var unlocked: bool = catalog.is_world_unlocked(world["id"], save_manager)
		var world_label := Label.new()
		world_label.add_theme_font_size_override("font_size", 22)
		if unlocked:
			world_label.text = "%s" % world["name"]
		else:
			world_label.text = "%s — locked (complete the previous world and earn %d ★)" % [world["name"], int(world.get("unlock_stars", 0))]
			world_label.modulate = Color(1, 1, 1, 0.5)
		worlds_box.add_child(world_label)

		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		worlds_box.add_child(grid)
		for level_id in world["levels"]:
			var button := Button.new()
			var number: String = level_id.split("_l")[1]
			var stars: int = save_manager.stars_for(level_id)
			button.text = "%s\n%s%s" % [number, "★".repeat(stars), "☆".repeat(3 - stars)]
			button.custom_minimum_size = Vector2(96, 56)
			button.disabled = not unlocked
			button.pressed.connect(_on_level_pressed.bind(level_id))
			grid.add_child(button)
			level_buttons[level_id] = button

func _on_level_pressed(level_id: String) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.level_id = level_id
	get_tree().change_scene_to_file(GAME_SCENE)
