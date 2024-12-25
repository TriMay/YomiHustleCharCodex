extends "res://cl_port/Network.gd"



func select_character(character, style = null):
	var codex = get_node_or_null("/root/CharCodexLibrary")
	if is_instance_valid(codex):
		if character.get("name") in Global.name_paths:
			style = codex.__modify_style_data(Global.name_paths[character.name], style)
	.select_character(character, style)
