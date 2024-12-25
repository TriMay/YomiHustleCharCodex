tool
extends Control

export var texture : Texture setget set_texture
export var draw_gap : float = 0 setget set_gap
export var value : int = 2 setget set_value
export var lose_one_in_neutral : bool = false  setget set_lose_one

var fighter:Fighter


func set_texture(val):
	texture = val
	minimum_size_changed()
	update()

func set_gap(val):
	draw_gap = val
	update()

func set_value(val):
	value = val
	update()

func set_lose_one(val):
	lose_one_in_neutral = val
	hint_tooltip = "+1 In Combo" if val == true else ""
	update()




func _get_minimum_size():
	if texture is Texture:
		return texture.get_size()
	return Vector2()


func _draw():
	if texture is Texture:
		var tex_size = texture.get_size()
		for i in value:
			var draw_pos = Vector2((tex_size.x + draw_gap) * i, 0)
			var modulate = Color(1,1,1,1)
			if lose_one_in_neutral and i == value -1:
				modulate = Color(0.8, 0.8, 1.0, 0.5)
			draw_texture(texture, draw_pos, modulate)
