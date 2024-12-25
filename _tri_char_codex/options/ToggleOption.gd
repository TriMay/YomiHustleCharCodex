extends MarginContainer


signal data_changed()


func _ready():
	$CheckButton.connect("pressed", self, "emit_signal", ["data_changed"])


func apply_params(params : Dictionary):
	if params.has("group"):
		if params.group is ButtonGroup:
			$CheckButton.group = params.group
		else:
			var p = get_parent()
			if p.has_method("__get_named_button_group"):
				$CheckButton.group = p.__get_named_button_group(params.group)


func set_value(value):
	if value is bool or value is int or value is float:
		$CheckButton.set_pressed_no_signal(bool(value))


func get_data():
	return $CheckButton.pressed

