tool
extends Control


export var fill_color = Color(1.0,1.0,1.0) setget set_fill
export var back_color = Color(0.0,0.0,0.0) setget set_back
export var max_value = 100 setget set_max
export var current_value = 0 setget set_current


func set_fill(value):
	fill_color = value
	update()

func set_back(value):
	back_color = value
	update()
	
func set_max(value):
	max_value = value
	update()

func set_current(value):
	current_value = value
	update()



func _draw():
	var size = get_size()
	var rect_back = Rect2(0, 0, size.x, size.y)
	var progress = float(current_value) / (float(max_value) if max_value != 0 else 1.0)
	progress = clamp(progress, 0.0, 1.0)
	var rect_fill = Rect2(0, 0, size.x * progress, size.y)
	draw_rect(rect_back, back_color, true)
	draw_rect(rect_fill, fill_color, true)
