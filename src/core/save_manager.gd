extends RefCounted
## Persistent player progress: best stars and score per level.
## Stored as JSON at `save_path` (default user://save.json) and written
## on every recorded result. A missing or corrupt file yields a fresh save.

var save_path: String
var _levels: Dictionary = {}

func _init(_path: String = "user://save.json") -> void:
	save_path = _path
	_load()

## Records a finished level, keeping the best stars and best score seen.
func record_result(level_id: String, stars: int, score: int) -> void:
	var entry: Dictionary = _levels.get(level_id, {"stars": 0, "score": 0})
	entry["stars"] = maxi(int(entry["stars"]), stars)
	entry["score"] = maxi(int(entry["score"]), score)
	_levels[level_id] = entry
	_save()

func stars_for(level_id: String) -> int:
	return int(_levels.get(level_id, {}).get("stars", 0))

func score_for(level_id: String) -> int:
	return int(_levels.get(level_id, {}).get("score", 0))

func total_stars() -> int:
	var total := 0
	for level_id in _levels:
		total += int(_levels[level_id]["stars"])
	return total

func completed_ids() -> Array:
	var ids: Array = _levels.keys()
	ids.sort()
	return ids

func _load() -> void:
	_levels = {}
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("levels")) != TYPE_DICTIONARY:
		return
	for level_id in parsed["levels"]:
		var entry: Variant = parsed["levels"][level_id]
		if typeof(entry) == TYPE_DICTIONARY:
			_levels[level_id] = {"stars": int(entry.get("stars", 0)), "score": int(entry.get("score", 0))}

func _save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save file: %s" % save_path)
		return
	file.store_string(JSON.stringify({"levels": _levels}, "  "))
