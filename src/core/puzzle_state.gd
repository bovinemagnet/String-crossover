extends RefCounted
## Mutable in-play state: one path per colour, plus undo history.
##
## A path is an Array of Vector2i cells from one endpoint towards its pair.
## Legality of each extension is delegated to PathValidator; backtracking
## (re-entering the previous cell) shortens the path instead.

const PathValidator = preload("res://src/core/path_validator.gd")

var level
var hint_used: bool = false
var paths: Dictionary = {}
var _undo_stack: Array[Dictionary] = []

func _init(_level: Variant) -> void:
	level = _level

func begin_path(color: String, cell: Vector2i) -> bool:
	if not level.endpoints.has(color):
		return false
	if not (cell in level.endpoints[color]):
		return false
	_push_undo()
	paths[color] = [cell]
	return true

func extend_path(color: String, cell: Vector2i) -> bool:
	var path: Array = paths.get(color, [])
	if path.is_empty() or is_color_complete(color):
		return false
	if path.size() >= 2 and cell == path[path.size() - 2]:
		path.pop_back()
		return true
	if not PathValidator.can_extend(level, self, color, cell):
		return false
	path.append(cell)
	return true

func clear_path(color: String) -> void:
	if not paths.get(color, []).is_empty():
		_push_undo()
		paths.erase(color)

func get_path(color: String) -> Array:
	return paths.get(color, [])

## Colours whose string occupies `cell`, in catalog order.
func occupants_of(cell: Vector2i) -> Array:
	var result: Array = []
	for color in level.colors():
		if cell in paths.get(color, []):
			result.append(color)
	return result

func is_color_complete(color: String) -> bool:
	var path: Array = paths.get(color, [])
	if path.size() < 2:
		return false
	var ends: Array = level.endpoints[color]
	var first: Vector2i = path[0]
	var last: Vector2i = path[path.size() - 1]
	return first in ends and last in ends and first != last

func is_complete() -> bool:
	for color in level.colors():
		if not is_color_complete(color):
			return false
	return true

func total_length() -> int:
	var length := 0
	for color in paths:
		length += maxi(paths[color].size() - 1, 0)
	return length

## Number of crossing cells currently used by two strings.
func crossing_count() -> int:
	var count := 0
	for cell in level.crossings:
		if occupants_of(cell).size() == 2:
			count += 1
	return count

func undo() -> bool:
	if _undo_stack.is_empty():
		return false
	paths = _undo_stack.pop_back()
	return true

func _push_undo() -> void:
	var snapshot: Dictionary = {}
	for color in paths:
		snapshot[color] = paths[color].duplicate()
	_undo_stack.append(snapshot)
