extends RefCounted
## Static rule checks for string paths.
##
## Basic rules: stay inside the grid, avoid obstacles, move orthogonally,
## never revisit a cell, never touch another colour's endpoints, and only
## share cells with other strings at designated crossing cells.

## True when `color`'s path may be extended onto `cell` given current state.
static func can_extend(level: Variant, state: Variant, color: String, cell: Vector2i) -> bool:
	var path: Array = state.get_path(color)
	if path.is_empty():
		return false
	if not level.is_inside(cell) or level.is_obstacle(cell):
		return false
	if not _adjacent(path[path.size() - 1], cell):
		return false
	if cell in path:
		return false
	var endpoint_color: String = level.endpoint_color_at(cell)
	if endpoint_color != "" and endpoint_color != color:
		return false
	var others: Array = state.occupants_of(cell).filter(func(c: String) -> bool: return c != color)
	if others.is_empty():
		return true
	return false

static func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1
