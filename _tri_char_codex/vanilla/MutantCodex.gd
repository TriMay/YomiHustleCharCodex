extends Node



func register(codex):
	codex.set_subtitle("Who's a good boy?")
#	codex.has_no_moveset = true
#	codex.has_no_stats = true
	#codex_data.set_summary("He's a ninja")
	#codex_data.set_move_desc("Slash", "Custom Move Description")
	#codex_data.set_move_desc("Chainsaw", "Custom Move Description")
	#codex_data.set_move_desc("Silly Move", "Custom Move Description")


#func test(origin, unset):
#	if origin.get_data() == true:
#		for el in unset:
#			el.set_value(false)


#func setup_options(options, params):
#	var group = ButtonGroup.new()
#	var a = options.add_toggle("a", "Hello Toggle")
#	var b = options.add_toggle("b", "Hello Toggle")
#	var c = options.add_toggle("c", "Hello Toggle")
#	a.connect("data_changed", self, "test", [a, [b,c]])
#	b.connect("data_changed", self, "test", [b, [a,c]])
#	c.connect("data_changed", self, "test", [c, [a,b]])
#	pass
#	options.add_label("Hello World")
#	options.add_seperator()
#	options.add_toggle("a", "Hello Toggle")
#	options.add_toggle("aa", "Hello Toggle")
#	options.add_toggle("aaa", "Hello Toggle")
#	options.add_toggle("aaaa", "Hello Toggle")
#	options.add_textline("b", "Hello Textline", "", {
#		"secret": true,
#		"max_length": 5,
#		"placeholder_text": "placeholder",
#	})
#	
#	var number_params = {
#		"min_value": -32,
#		"max_value": 32,
#		"step": 1,
#		#"rounded": true,
#	}
#	
#	options.add_number("c", "Hello Number", 69, number_params)
#	options.add_slider("d", "Hello Slider", 69, number_params)
#	
#	options.add_seperator("Seperator With Label")
#	var dropdown = options.add_dropdown("e", "Hello Dropdown", "two")
#	dropdown.add_seperator()
#	dropdown.add_item("Hello World")
#	dropdown.add_seperator("With Text")
#	dropdown.add_item("Hello World", "two")
#	options.add_color("f", "Hello Color", "00C0FF")
#	
#	options.add_custom_decor("res://ui/XYPlot/XYPlot.tscn")
#	options.add_custom_scene("hello", "res://ui/XYPlot/XYPlot.tscn")
#	options.add_scene("Hello World")
#	options.add_scene_decoration("Hello World")



#func modify_style_data(style, params):
#	#style.custom_thing_loaded = "randi-" + str(randi())
#	print(params)
#	var codex = params.codex_library
#	var test = codex.is_achievement_array_unlocked(params.char_path, ["Extra", "Hidden"])
#	print(style.custom_thing_loaded)
#
#
#func setup_advanced_achievements(list, params):
#	list.define("Extra", {
#		"title": "Hustle",
#		"desc": "Use Hustle 5 times",
#		"secret": true,
#		"counter_id": "hustles",
#		"counter_target": 5,
#		"highlight_color": Color(1.0, 0.0, 1.0),
#	})
#	list.define("Hidden", {
#		"title": "Hidden",
#		"desc": "Use Hustle 5 times",
#		"secret": true,
#		"counter_id": "hustles",
#		"counter_target": 5,
#		"highlight_color": Color(1.0, 0.0, 1.0),
#	})
#	list.define("Visible", {
#		"title": "Visible",
#		"desc": "Use Hustle 5 times",
#		"counter_id": "hustles",
#		"counter_target": 5,
#		"highlight_color": Color(1.0, 0.0, 1.0),
#	})
#	list.assign_counter("Extra", "hustle", 5)
#
#	var character = params.character
#
#	for child in character.get_node("StateMachine").get_children():
#		list.define(child.name, {
#			"title": child.name,
#			"icon": child.button_texture,
#			"unlocked": true,
#		})
