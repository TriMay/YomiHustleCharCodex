extends VBoxContainer

signal close_request()
signal play_request()
signal window_entered()


func _ready():
	$"%CancelButton".connect("pressed", self, "emit_signal", ["close_request"])
	$"%PlayButton".connect("pressed", self, "emit_signal", ["play_request"])
	$"%OptionsContainer".connect("mouse_entered", self, "emit_signal", ["window_entered"])
