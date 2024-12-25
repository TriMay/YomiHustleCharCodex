tool
extends Control


const LINE_WIDTH = 2.25

const BEZEL = 4.0

export var fill_color = Color(0.0,0.0,0.0) setget set_fill, get_fill
export var line_color = Color(1.0,1.0,1.0) setget set_line, get_line


func set_fill(value):
	fill_color = value
	update()

func set_line(value):
	line_color = value
	update()

func get_fill():
	return fill_color

func get_line():
	return line_color



func _draw():
	var size = get_size()
	var line = PoolVector2Array([
		Vector2(0, BEZEL),
		Vector2(BEZEL, 0),
		Vector2(size.x-BEZEL, 0),
		Vector2(size.x, BEZEL),
		Vector2(size.x, size.y-BEZEL),
		Vector2(size.x-BEZEL, size.y),
		Vector2(BEZEL, size.y),
		Vector2(0, size.y-BEZEL),
		Vector2(0, BEZEL)
	])
	draw_colored_polygon(line, fill_color)
	draw_polyline(line, line_color, LINE_WIDTH)
