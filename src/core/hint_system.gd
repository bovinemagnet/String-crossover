extends RefCounted
## Reveals the stored solution path for one unsolved colour.
##
## The first unsolved colour (in level order) has its path replaced by the
## level's worked solution. Any other string blocking that solution is
## cleared; strings that merely cross it legally are left alone. Using a
## hint flags the attempt, which caps the star rating.

## Applies one hint. Returns the colour that was solved, or "" if the
## puzzle is already complete.
static func apply_hint(level: Variant, state: Variant) -> String:
	var target := ""
	for color in level.colors():
		if not state.is_color_complete(color):
			target = color
			break
	if target == "":
		return ""
	var solution: Array = level.solution.get(target, [])
	if solution.is_empty():
		push_error("Level %s has no solution for '%s'" % [level.id, target])
		return ""
	state.hint_used = true
	# Each failed replay clears the blocking string, so one extra attempt
	# per colour is always enough.
	for attempt in level.colors().size() + 1:
		if _replay(state, target, solution):
			return target
	push_error("Hint replay failed for '%s' in level %s" % [target, level.id])
	return target

static func _replay(state: Variant, color: String, solution: Array) -> bool:
	state.clear_path(color)
	if not state.begin_path(color, solution[0]):
		return false
	for i in range(1, solution.size()):
		var cell: Vector2i = solution[i]
		if not state.extend_path(color, cell):
			for other in state.occupants_of(cell):
				if other != color:
					state.clear_path(other)
			return false
	return true
