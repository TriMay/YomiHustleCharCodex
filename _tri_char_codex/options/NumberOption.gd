extends HBoxContainer


signal data_changed()


var signal_disabled = false


func _ready():
	$SpinBox.connect("value_changed", self, "on_number_changed")


func on_number_changed(value):
	if not signal_disabled:
		emit_signal("data_changed")


func apply_params(params : Dictionary):
	var rounded = false
	var step = 1
	if params.has("min_value"): 
		var set_value = float(params.min_value) if params.min_value is String else params.min_value
		$SpinBox.set("min_value", params.min_value)
		$SpinBox.allow_lesser = false
		rounded = set_value is int
	if params.has("max_value"):
		var set_value = float(params.max_value) if params.max_value is String else params.max_value
		$SpinBox.set("max_value", params.max_value)
		$SpinBox.allow_greater = false
		rounded = set_value is int
	if params.has("step"):
		var set_value = float(params.step) if params.step is String else params.step
		step = set_value
		rounded = set_value is int
	else:
		step = 1 if rounded else 0.1
	if params.has("rounded"):
		rounded = params.rounded
	if params.has("allow_greater"):
		$SpinBox.set("allow_greater", params.allow_greater)
	if params.has("allow_lesser"):
		$SpinBox.set("allow_lesser", params.allow_lesser)
	$SpinBox.set("rounded", rounded)
	$SpinBox.set("step", step)


func set_value(value):
	signal_disabled = true
	$SpinBox.set("value", value)
	signal_disabled = false


func get_data():
	if $SpinBox.rounded:
		return int($SpinBox.value)
	return str($SpinBox.value)
