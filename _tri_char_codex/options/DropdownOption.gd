extends HBoxContainer


signal data_changed()


func _ready():
	$OptionButton.connect("item_selected", self, "on_item_selected")


func on_item_selected(index):
	emit_signal("data_changed")


func apply_params(params : Dictionary):
	pass # TODO


func set_value(value):
	var opt_but = $OptionButton
	for index in opt_but.get_item_count():
		if opt_but.get_item_metadata(index) == value:
			opt_but.select(index)
			return
	opt_but.select(-1)


func get_data():
	return $OptionButton.get_selected_metadata()


func add_item(text:String, value = null):
	var opt_but = $OptionButton
	opt_but.add_item(text)
	opt_but.set_item_metadata(opt_but.get_item_count()-1, text if value == null else value)


func add_seperator(text:String = ""):
	$OptionButton.get_popup().add_separator(text)
