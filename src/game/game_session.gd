extends Node
## Autoloaded session state shared between menus and the game scene.

const SaveManager = preload("res://src/core/save_manager.gd")
const LevelCatalog = preload("res://src/core/level_catalog.gd")

var level_id: String = "w1_l01"
var save_manager: Variant
var catalog: Variant

func _ready() -> void:
	save_manager = SaveManager.new()
	catalog = LevelCatalog.load_catalog()
