extends "res://ui/CSS/CharacterSelect.gd"




var __tri_char_codex__options_prompt = null
var __tri_char_codex__options_layer = null


func _ready():
	connect("visibility_changed", self, "__tri_char_codex__on_visibility_changed")



func get_match_data():
	var data = .get_match_data()
	
	if singleplayer:
		# TODO make sure selected_characters and selected_styles match size
		var codex = get_node_or_null("/root/CharCodexLibrary")
		if is_instance_valid(codex):
			for player_id in data.selected_characters:
				var char_name = data.selected_characters[player_id].get("name")
				var style = data.selected_styles[player_id]
				if char_name in Global.name_paths:
					var char_path = Global.name_paths[char_name]
					data.selected_styles[player_id] = codex.__modify_style_data(char_path, style)
	
	return data



func _on_button_pressed(button, no_options_check = false):
	if not __tri_char_codex__clean_options_layer():
		return
	if no_options_check:
		__tri_char_codex__clean_options_prompt()
		._on_button_pressed(button)
		return
	button.set_pressed_no_signal(false)
	if btt_disableTimer > 0 or currentlyLoading:
		return
	var codex = get_node_or_null("/root/CharCodexLibrary")
	var misclick_prevention = false
	if codex != null:
		misclick_prevention = codex.load_codex_setting("misclick_prevent")
	if misclick_prevention or __tri_char_codex__button_has_options(button):
		__tri_char_codex__show_options_ui(button)
	else:
		__tri_char_codex__clean_options_prompt()
		._on_button_pressed(button)



func __tri_char_codex__clean_options_prompt():
	if is_instance_valid(__tri_char_codex__options_prompt):
		__tri_char_codex__options_prompt.queue_free()


func __tri_char_codex__clean_options_layer(force = false):
	if is_instance_valid(__tri_char_codex__options_layer):
		return __tri_char_codex__options_layer._close(force)
	return true


func __tri_char_codex__show_options_ui(button):
	if not __tri_char_codex__clean_options_layer():
		return
	__tri_char_codex__clean_options_prompt()
	var new_ui = load("res://_tri_char_codex/components/CharSelectOptionsPrompt.tscn").instance()
	__tri_char_codex__options_prompt = new_ui
	button.add_child(new_ui)
	new_ui.setup(self, button)
	new_ui.connect("button_entered", self, "_on_button_mouse_entered", [button])
	new_ui.connect("options_pressed", self, "__tri_char_codex__select_options", [button])
	new_ui.connect("play_pressed", self, "_on_button_pressed", [button, true])
	new_ui.connect("options_pressed", $ButtonSoundPlayer, "_button_selected")
	new_ui.connect("play_pressed", $ButtonSoundPlayer, "_button_selected")



func __tri_char_codex__on_visibility_changed():
	__tri_char_codex__clean_options_prompt()
	__tri_char_codex__clean_options_layer(true)



func __tri_char_codex__button_has_options(button):
	var codex = get_node_or_null("/root/CharCodexLibrary")
	if not is_instance_valid(codex):
		return false
	var char_path = __tri_char_codex__get_button_char_path(button)
	return codex.char_has_options(char_path)



func __tri_char_codex__select_options(button):
	__tri_char_codex__clean_options_prompt()
	var new_ui = load("res://_tri_char_codex/windows/CharOptionsLayer.tscn").instance()
	__tri_char_codex__options_layer = new_ui
	add_child(new_ui)
	new_ui.CharSelect = self
	new_ui.used_context = "CharSelect"
	new_ui.CodexHandler = get_node_or_null("/root/CharCodexLibrary")
	new_ui.set_char_name(button.text)
	new_ui.connect("play_request", self, "_on_button_pressed", [button, true])
	new_ui.connect("window_entered", self, "_on_button_mouse_entered", [button])
	new_ui.setup(__tri_char_codex__get_button_char_path(button), __tri_char_codex__get_button_index(button))


func __tri_char_codex__get_button_char_path(button):
	if isCustomChar(button.name):
		return charList[name_to_index[button.name]][1]
	return Global.name_paths[button.text]


func __tri_char_codex__get_button_index(button):
	if isCustomChar(button.name):
		return name_to_index[button.name]
	return -1
