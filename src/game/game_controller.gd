extends Node2D
## The playable puzzle scene: input handling, HUD and win flow.
##
## Controls — mouse: press an endpoint (or a string's head) and drag to
## draw; keyboard: Z/Ctrl+Z undo, R restart, H hint, Esc back to menu.

const LevelData = preload("res://src/core/level_data.gd")
const PuzzleState = preload("res://src/core/puzzle_state.gd")
const Scoring = preload("res://src/core/scoring.gd")
const HintSystem = preload("res://src/core/hint_system.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const LevelCatalog = preload("res://src/core/level_catalog.gd")
const BoardView = preload("res://src/game/board_view.gd")

const BACKGROUND := Color("1d2233")
const LEVEL_SELECT_SCENE := "res://src/ui/level_select.tscn"

var level: Variant
var state: Variant
var board: Node2D
var dragging: String = ""
var solved: bool = false

var save_manager: Variant
var catalog: Variant
var level_id: String = "w1_l01"

var name_label: Label
var info_label: Label
var win_panel: PanelContainer
var win_title: Label
var win_stars: Label
var win_score: Label

func _ready() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		level_id = session.level_id
		save_manager = session.save_manager
		catalog = session.catalog
	else:
		save_manager = SaveManager.new("user://test_game_save.json")
		catalog = LevelCatalog.load_catalog()

	level = LevelData.from_file(catalog.level_path(level_id))
	if level == null:
		push_error("Cannot load level %s: %s" % [level_id, LevelData.last_error])
		return
	state = PuzzleState.new(level)

	RenderingServer.set_default_clear_color(BACKGROUND)
	board = BoardView.new()
	add_child(board)
	var viewport_size := get_viewport_rect().size
	board.setup(level, state, Rect2(Vector2(24, 84), viewport_size - Vector2(48, 108)))
	_build_hud()
	_update_hud()

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.add_theme_constant_override("separation", 12)
	hud.add_child(top)

	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)

	info_label = Label.new()
	top.add_child(info_label)

	for entry in [["Undo (Z)", _on_undo], ["Restart (R)", _on_restart], ["Hint (H)", _on_hint], ["Menu (Esc)", _on_menu]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		top.add_child(button)

	win_panel = PanelContainer.new()
	win_panel.visible = false
	win_panel.set_anchors_preset(Control.PRESET_CENTER)
	hud.add_child(win_panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 10)
	win_panel.add_child(box)

	win_title = Label.new()
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(win_title)
	win_stars = Label.new()
	win_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(win_stars)
	win_score = Label.new()
	win_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(win_score)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	for entry in [["Next", _on_next], ["Replay", _on_restart], ["Menu", _on_menu]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		buttons.add_child(button)

func _update_hud() -> void:
	if level == null:
		return
	name_label.text = "%s — %s" % [level_id, level.level_name]
	info_label.text = "Length %d / Par %d   Crossings %d" % [state.total_length(), level.par_length, state.crossing_count()]

func _unhandled_input(event: InputEvent) -> void:
	if solved or state == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(board.cell_at(event.position))
		else:
			dragging = ""
	elif event is InputEventMouseMotion and dragging != "":
		var cell: Vector2i = board.cell_at(event.position)
		if cell != Vector2i(-1, -1):
			_drag_to(cell)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Z:
				_on_undo()
			KEY_R:
				_on_restart()
			KEY_H:
				_on_hint()
			KEY_ESCAPE:
				_on_menu()

func _start_drag(cell: Vector2i) -> void:
	if cell == Vector2i(-1, -1):
		return
	var endpoint_color: String = level.endpoint_color_at(cell)
	if endpoint_color != "" and not state.is_color_complete(endpoint_color):
		if state.begin_path(endpoint_color, cell):
			dragging = endpoint_color
			_after_change()
			return
	for color in level.colors():
		var path: Array = state.get_path(color)
		if not path.is_empty() and path[path.size() - 1] == cell and not state.is_color_complete(color):
			dragging = color
			return

## Walks the string head towards `target` one orthogonal step at a time.
func _drag_to(target: Vector2i) -> void:
	var guard := 0
	while dragging != "" and guard < 64:
		guard += 1
		var path: Array = state.get_path(dragging)
		if path.is_empty():
			break
		var head: Vector2i = path[path.size() - 1]
		if head == target:
			break
		var delta := target - head
		var step_x := Vector2i(signi(delta.x), 0)
		var step_y := Vector2i(0, signi(delta.y))
		var first := step_x if absi(delta.x) >= absi(delta.y) else step_y
		var second := step_y if first == step_x else step_x
		if first != Vector2i.ZERO and state.extend_path(dragging, head + first):
			continue
		if second != Vector2i.ZERO and state.extend_path(dragging, head + second):
			continue
		break
	_after_change()

func _after_change() -> void:
	board.refresh()
	_update_hud()
	_check_completion()

func _check_completion() -> void:
	if solved or state == null or not state.is_complete():
		return
	solved = true
	dragging = ""
	var stars: int = Scoring.stars(level, state)
	var score: int = Scoring.score(level, state)
	save_manager.record_result(level_id, stars, score)
	win_title.text = "Level Complete!"
	win_stars.text = "%s%s" % ["★".repeat(stars), "☆".repeat(3 - stars)]
	win_score.text = "Score: %d" % score
	win_panel.visible = true

func _on_undo() -> void:
	if solved:
		return
	if state.undo():
		dragging = ""
		_after_change()

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _on_hint() -> void:
	if solved:
		return
	if HintSystem.apply_hint(level, state) != "":
		dragging = ""
		_after_change()

func _on_next() -> void:
	var next_id: String = catalog.next_level_id(level_id)
	if next_id == "":
		_on_menu()
		return
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.level_id = next_id
	level_id = next_id
	get_tree().reload_current_scene()

func _on_menu() -> void:
	if ResourceLoader.exists(LEVEL_SELECT_SCENE):
		get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
