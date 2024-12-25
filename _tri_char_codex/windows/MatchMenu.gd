extends Control


var CodexHandler = null



func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	$"%CodexCloseL".connect("pressed", self, "_on_close_codex_pressed")
	$"%CodexCloseR".connect("pressed", self, "_on_close_codex_pressed")



func _on_visibility_changed():
	for child in $"%Characters".get_children():
		child.visible = false
		child.queue_free()
	if is_visible_in_tree():
		$"%CodexLayer".set_visible(false)
		if CodexHandler == null:
			CodexHandler = get_node_or_null("/root/CharCodexLibrary")
			if CodexHandler == null:
				return
		var game = Global.current_game
		if not is_instance_valid(game):
			return
		if not game.match_data is Dictionary:
			return
		var match_data = game.match_data
		if not match_data.has("selected_characters"):
			return
		var chars = match_data.selected_characters
		if chars is Dictionary:
			chars = chars.values()
		elif not chars is Array:
			return
		for player in chars.size():
			var character = chars[player]
			if not character is Dictionary:
				return
			if not character.has("name"):
				continue
			if not character.name in Global.name_paths:
				continue
			var button := Button.new()
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.size_flags_vertical = SIZE_EXPAND_FILL
			var pretty_name = character.name if not "__" in character.name else character.name.split("__")[1]
			button.text = pretty_name
			button.connect("pressed", self, "_on_codex_button_pressed", [character.name, player+1])
			$"%Characters".add_child(button)



func _on_codex_button_pressed(char_name : String, player_id):
	if is_instance_valid(CodexHandler) and char_name in Global.name_paths:
		$"%CodexCloseL".visible = (player_id != 1)
		$"%CodexCloseR".visible = (player_id == 1)
		$"%CodexPanel".anchor_left = 1 if player_id != 1 else 0
		$"%CodexPanel".anchor_right = 1 if player_id != 1 else 0
		$"%CodexPanel".grow_horizontal = GROW_DIRECTION_BEGIN if player_id != 1 else GROW_DIRECTION_END
		$"%CodexPanel".margin_left = 0
		$"%CodexPanel".margin_right = 0
		$"../%PausePanel".visible = false
		for child in $"%CodexContainer".get_children():
			child.queue_free()
		$"%CodexContainer".add_child(CodexHandler.generate_node(Global.name_paths[char_name]))
		$"%CodexLayer".set_visible(true)



func _on_close_codex_pressed():
	$"%CodexLayer".set_visible(false)
	for child in $"%CodexContainer".get_children():
		child.queue_free()
