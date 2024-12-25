tool
extends Control


const LINE_WIDTH = 2.25

const OUTER = 1.0
const INNER = 0.5

const STAR = PoolVector2Array([
	Vector2(sin(PI*0.05) * OUTER,   cos(PI*0.05) * -OUTER),
	Vector2(sin(PI*0.25) * INNER,   cos(PI*0.25) * -INNER),
	Vector2(sin(PI*0.45) * OUTER,   cos(PI*0.45) * -OUTER),
	Vector2(sin(PI*0.65) * INNER,   cos(PI*0.65) * -INNER),
	Vector2(sin(PI*0.85) * OUTER,   cos(PI*0.85) * -OUTER),
	Vector2(sin(PI*1.05) * INNER,   cos(PI*1.05) * -INNER),
	Vector2(sin(PI*1.25) * OUTER,   cos(PI*1.25) * -OUTER),
	Vector2(sin(PI*1.45) * INNER,   cos(PI*1.45) * -INNER),
	Vector2(sin(PI*1.65) * OUTER,   cos(PI*1.65) * -OUTER),
	Vector2(sin(PI*1.85) * INNER,   cos(PI*1.85) * -INNER),
	Vector2(sin(PI*2.05) * OUTER,   cos(PI*2.05) * -OUTER),
])

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
	var shifted_star = PoolVector2Array()
	for point in STAR:
		shifted_star.append((point * 0.5 + Vector2(0.5, 0.5)) * size)
	draw_colored_polygon(shifted_star, fill_color)
	draw_polyline(shifted_star, line_color, LINE_WIDTH)
