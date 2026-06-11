extends RefCounted
## Immutable data for one puzzle level, parsed from JSON.
##
## Cells are Vector2i grid coordinates (x = column, y = row, origin top-left).
## `endpoints` maps colour name -> [Vector2i, Vector2i].
## `solution` maps colour name -> Array[Vector2i] (a valid worked solution,
## used by the hint system and by automated level validation).

static var last_error: String = ""

var id: String = ""
var level_name: String = ""
var width: int = 0
var height: int = 0
var endpoints: Dictionary = {}
var endpoint_order: Array[String] = []
var obstacles: Array[Vector2i] = []
var crossings: Array[Vector2i] = []
var par_length: int = 0
var solution: Dictionary = {}

static func from_json(text: String) -> Variant:
	last_error = ""
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		last_error = "invalid JSON"
		return null
	return _from_dict(parsed)

static func from_file(path: String) -> Variant:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "file not found: %s" % path
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "cannot open file: %s" % path
		return null
	return from_json(file.get_as_text())

static func _from_dict(data: Dictionary) -> Variant:
	for key in ["id", "name", "grid", "endpoints", "par_length", "solution"]:
		if not data.has(key):
			last_error = "missing field: %s" % key
			return null
	var grid: Variant = data["grid"]
	if typeof(grid) != TYPE_DICTIONARY or not grid.has("width") or not grid.has("height"):
		last_error = "grid must have width and height"
		return null

	var level := new()
	level.id = str(data["id"])
	level.level_name = str(data["name"])
	level.width = int(grid["width"])
	level.height = int(grid["height"])
	level.par_length = int(data["par_length"])
	if level.width <= 0 or level.height <= 0:
		last_error = "grid dimensions must be positive"
		return null

	for entry in data["endpoints"]:
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("color") or not entry.has("cells"):
			last_error = "endpoint entries need color and cells"
			return null
		var color := str(entry["color"])
		var cells: Variant = _to_cells(entry["cells"])
		if cells == null or cells.size() != 2:
			last_error = "endpoint '%s' must have exactly 2 cells" % color
			return null
		level.endpoints[color] = cells
		level.endpoint_order.append(color)

	if level.endpoint_order.is_empty():
		last_error = "level needs at least one endpoint pair"
		return null

	var obstacle_cells: Variant = _to_cells(data.get("obstacles", []))
	var crossing_cells: Variant = _to_cells(data.get("crossings", []))
	if obstacle_cells == null or crossing_cells == null:
		last_error = "obstacles/crossings must be arrays of [x, y]"
		return null
	level.obstacles.assign(obstacle_cells)
	level.crossings.assign(crossing_cells)

	for color in data["solution"]:
		var path: Variant = _to_cells(data["solution"][color])
		if path == null:
			last_error = "solution for '%s' must be an array of [x, y]" % color
			return null
		level.solution[color] = path
	return level

## Converts an array of [x, y] pairs to Array[Vector2i]; null on bad input.
static func _to_cells(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_ARRAY:
		return null
	var cells: Array[Vector2i] = []
	for pair in raw:
		if typeof(pair) != TYPE_ARRAY or pair.size() != 2:
			return null
		cells.append(Vector2i(int(pair[0]), int(pair[1])))
	return cells

func colors() -> Array[String]:
	return endpoint_order

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func is_obstacle(cell: Vector2i) -> bool:
	return cell in obstacles

func is_crossing(cell: Vector2i) -> bool:
	return cell in crossings

## Returns the colour whose endpoint occupies `cell`, or "" if none.
func endpoint_color_at(cell: Vector2i) -> String:
	for color in endpoint_order:
		if cell in endpoints[color]:
			return color
	return ""

func other_endpoint(color: String, cell: Vector2i) -> Vector2i:
	var pair: Array[Vector2i] = endpoints[color]
	return pair[1] if cell == pair[0] else pair[0]
