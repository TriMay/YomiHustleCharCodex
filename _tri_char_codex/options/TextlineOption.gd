extends HBoxContainer


signal data_changed()


func _ready():
	$LineEdit.connect("text_changed", self, "on_text_changed")


func on_text_changed(value):
	emit_signal("data_changed")


func apply_params(params : Dictionary):
	if params.has("secret"): 
		$LineEdit.set("secret", params.secret)
	if params.has("max_length"):
		$LineEdit.set("max_length", params.max_length)
	if params.has("placeholder_text"):
		$LineEdit.set("placeholder_text", params.placeholder_text)


func set_value(value):
	$LineEdit.text = str(value)


func get_data():
	return $LineEdit.text
