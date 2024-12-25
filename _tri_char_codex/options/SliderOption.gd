extends HBoxContainer


signal data_changed()


var signal_disabled = false


func _ready():
	$HBoxContainer/SpinBox.share($HBoxContainer/HSlider)
	$HBoxContainer/SpinBox.connect("value_changed", self, "on_number_changed")
	$Debouncer.connect("timeout", self, "on_timer_finished")



func on_number_changed(value):
	if not signal_disabled:
		$Debouncer.start(0.2)


func on_timer_finished():
	emit_signal("data_changed")


func apply_params(params : Dictionary):
	var rounded = false
	var step = 1
	if params.has("min_value"): 
		var set_value = float(params.min_value) if params.min_value is String else params.min_value
		$HBoxContainer/SpinBox.set("min_value", params.min_value)
		rounded = set_value is int
	if params.has("max_value"):
		var set_value = float(params.max_value) if params.max_value is String else params.max_value
		$HBoxContainer/SpinBox.set("max_value", params.max_value)
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
		$HBoxContainer/SpinBox.set("allow_greater", params.allow_greater)
	if params.has("allow_lesser"):
		$HBoxContainer/SpinBox.set("allow_lesser", params.allow_lesser)
	$HBoxContainer/SpinBox.set("rounded", rounded)
	$HBoxContainer/HSlider.set("rounded", rounded)
	$HBoxContainer/SpinBox.set("step", step)
	$HBoxContainer/HSlider.set("step", step)


func set_value(value):
	signal_disabled = true
	$HBoxContainer/SpinBox.set("value", value)
	signal_disabled = false


func get_data():
	if $HBoxContainer/SpinBox.rounded:
		return int($HBoxContainer/SpinBox.value)
	return str($HBoxContainer/SpinBox.value)
