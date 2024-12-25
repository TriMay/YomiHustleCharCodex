tool
extends Control


export var colors : Array = [] setget set_colors, get_colors
var label_text = ""



func set_colors(value : Array):
	colors = value
	update()


func get_colors() -> Array:
	update()
	return colors


func add_color(col : Color):
	colors.append(col)
	update()


func set_label_text(value : String):
	label_text = value.left(1).to_upper()
	get_child(0).text = label_text


func _init():
	colors = colors.duplicate()
	rect_min_size = Vector2(7, 12)
	var label = Label.new()
	add_child(label)
	label.anchor_bottom = 1.0
	label.anchor_right = 1.0
	label.margin_bottom = 0
	label.margin_right = 0
	label.clip_text = true
	label.align = Label.ALIGN_CENTER
	label.modulate = Color(0.7, 0.7, 0.7)
	mouse_default_cursor_shape = Control.CURSOR_HELP
	update()


func _ready():
	update()


func _draw():
	var rect = Rect2(Vector2(), get_size())
	draw_rect(rect, Color(0.8, 0.8, 0.8), true)
	for index in colors.size():
		var col = colors[index]
		if col is Color:
			var sub_rect = Rect2(0, (rect.size.y / colors.size()) * index, rect.size.x, rect.size.y / colors.size())
			draw_rect(sub_rect, col, true)
