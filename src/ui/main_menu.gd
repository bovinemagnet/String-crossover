extends Control
## Title screen: play or quit.

const LEVEL_SELECT_SCENE := "res://src/ui/level_select.tscn"

var play_button: Button
var quit_button: Button

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("1d2233")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	var title := Label.new()
	title.text = "Cross Over Strings"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Weave every colour to its pair — cross only at the marked knots."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(1, 1, 1, 0.7)
	box.add_child(subtitle)

	play_button = Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(220, 48)
	play_button.pressed.connect(_on_play)
	box.add_child(play_button)

	quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(220, 40)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)

func _on_play() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
