extends HBoxContainer


signal data_changed()


func _ready():
	$CustomColorPicker.connect("color_changed", self, "on_color_changed")
	$Debouncer.connect("timeout", self, "on_timer_finished")


func on_color_changed(value):
	$Debouncer.start(0.2)


func on_timer_finished():
	emit_signal("data_changed")


func apply_params(params : Dictionary):
	pass # TODO


func set_value(value):
	if not (value is Color):
		if value is String or value is int:
			value = Color(value)
		else:
			return
	$CustomColorPicker.set_color(value)
	$CustomColorPicker.current_color = value
	$CustomColorPicker.hex_edit.text = value.to_html(false)
	$CustomColorPicker.picker_rect.hide()


func get_data():
	return $CustomColorPicker.current_color.to_html(false)
