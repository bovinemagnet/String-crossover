extends RefCounted
## Worlds, level ordering, file locations and unlock rules.
##
## Level ids follow "<world>_l<nn>", e.g. "w2_l07", which maps to the file
## res://levels/w2/level_07.json. A world unlocks once every level of the
## previous world is completed and the player's total stars reach the
## world's `unlock_stars`.

var _worlds: Array = []

static func load_catalog(path: String = "res://levels/catalog.json") -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Catalog not found: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Catalog is not valid JSON: %s" % path)
		return null
	return from_dict(parsed)

static func from_dict(data: Dictionary) -> Variant:
	if typeof(data.get("worlds")) != TYPE_ARRAY:
		return null
	var catalog := new()
	catalog._worlds = data["worlds"]
	return catalog

func worlds() -> Array:
	return _worlds

func level_ids(world_id: String) -> Array:
	for world in _worlds:
		if world["id"] == world_id:
			return world["levels"]
	return []

func level_path(level_id: String) -> String:
	var parts: PackedStringArray = level_id.split("_l")
	if parts.size() != 2:
		return ""
	return "res://levels/%s/level_%s.json" % [parts[0], parts[1]]

func is_world_unlocked(world_id: String, save: Variant) -> bool:
	var previous: Variant = null
	for world in _worlds:
		if world["id"] == world_id:
			if previous == null:
				return true
			for level_id in previous["levels"]:
				if save.stars_for(level_id) <= 0:
					return false
			return save.total_stars() >= int(world.get("unlock_stars", 0))
		previous = world
	return false

## The level after `level_id` in catalog order, crossing world boundaries.
## Returns "" after the final level.
func next_level_id(level_id: String) -> String:
	var flat: Array = []
	for world in _worlds:
		flat.append_array(world["levels"])
	var index: int = flat.find(level_id)
	if index < 0 or index + 1 >= flat.size():
		return ""
	return flat[index + 1]
