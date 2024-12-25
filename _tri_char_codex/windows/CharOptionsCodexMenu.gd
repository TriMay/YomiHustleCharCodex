extends VBoxContainer

signal close_request()
signal play_request()
signal window_entered()


func _ready():
	$"%SaveButton".connect("pressed", self, "emit_signal", ["close_request"])
	$"%OptionsContainer".connect("mouse_entered", self, "emit_signal", ["window_entered"])

