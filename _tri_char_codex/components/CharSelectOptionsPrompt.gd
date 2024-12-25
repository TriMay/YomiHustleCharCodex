extends Control


signal button_entered()
signal options_pressed()
signal play_pressed()


var char_select = null
var button = null


func setup(char_select, button):
	self.button = button
	self.char_select = char_select
	var ui_options_node = $OptionsButton
	var ui_play_node = $PlayButton
	ui_options_node.connect("mouse_entered", self, "_on_button_entered")
	ui_play_node.connect("mouse_entered", self, "_on_button_entered")
	if char_select.__tri_char_codex__button_has_options(button):
		ui_options_node.connect("pressed", self, "_on_options_pressed")
	else:
		ui_options_node.disabled = true
	ui_play_node.connect("pressed", self, "_on_play_pressed")



func _on_button_entered():
	emit_signal("button_entered")


func _on_options_pressed():
	emit_signal("options_pressed")


func _on_play_pressed():
	emit_signal("play_pressed")
