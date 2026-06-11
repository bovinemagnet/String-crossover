extends Node2D
## Renders the puzzle board: grid cells, obstacles, crossings, endpoints
## and the strings themselves (one Line2D per colour).

const PALETTE := {
	"red": Color("e05b5b"),
	"blue": Color("4d9be6"),
	"green": Color("58c474"),
	"yellow": Color("e6c84d"),
	"orange": Color("e08c3a"),
	"purple": Color("9b6dd6"),
}
const CELL_COLOR := Color("2d3450")
const OBSTACLE_COLOR := Color("141724")
const CROSSING_COLOR := Color("8892b8")

var level: Variant
var state: Variant
var cell_size: float = 64.0
var origin: Vector2 = Vector2.ZERO
var _lines: Dictionary = {}

## Lays the board out inside `rect` and creates one Line2D per colour.
func setup(_level: Variant, _state: Variant, rect: Rect2) -> void:
	level = _level
	state = _state
	cell_size = minf(rect.size.x / level.width, rect.size.y / level.height)
	var board_px := Vector2(level.width, level.height) * cell_size
	origin = rect.position + (rect.size - board_px) / 2.0
	for line in _lines.values():
		line.queue_free()
	_lines.clear()
	for color in level.colors():
		var line := Line2D.new()
		line.width = cell_size * 0.32
		line.default_color = PALETTE.get(color, Color.WHITE)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = true
		add_child(line)
		_lines[color] = line
	refresh()

## Syncs the string lines with the puzzle state and redraws the board.
func refresh() -> void:
	if level == null:
		return
	for color in _lines:
		var points := PackedVector2Array()
		var path: Array = state.get_path(color)
		if path.size() >= 2:
			for cell in path:
				points.append(cell_center(cell))
		_lines[color].points = points
	queue_redraw()

func cell_center(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size

## The cell under a viewport position, or (-1,-1) when outside the board.
func cell_at(position_px: Vector2) -> Vector2i:
	var local := (position_px - origin) / cell_size
	var cell := Vector2i(floori(local.x), floori(local.y))
	if level != null and level.is_inside(cell):
		return cell
	return Vector2i(-1, -1)

func color_of(color: String) -> Color:
	return PALETTE.get(color, Color.WHITE)

func _draw() -> void:
	if level == null:
		return
	var inset := cell_size * 0.04
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * cell_size + Vector2(inset, inset),
					Vector2(cell_size - inset * 2.0, cell_size - inset * 2.0))
			var color := OBSTACLE_COLOR if level.is_obstacle(cell) else CELL_COLOR
			draw_rect(rect, color)
	for cell in level.crossings:
		var centre := cell_center(cell)
		var r := cell_size * 0.38
		var diamond := PackedVector2Array([
			centre + Vector2(0, -r), centre + Vector2(r, 0),
			centre + Vector2(0, r), centre + Vector2(-r, 0), centre + Vector2(0, -r),
		])
		draw_polyline(diamond, CROSSING_COLOR, maxf(cell_size * 0.05, 1.0), true)
	for color in level.colors():
		for cell in level.endpoints[color]:
			var centre := cell_center(cell)
			draw_circle(centre, cell_size * 0.34, color_of(color))
			draw_circle(centre, cell_size * 0.12, Color(1, 1, 1, 0.85))
