extends VBoxContainer


signal data_changed()


var option_values = {}
var tracked_option_nodes = {}
var button_groups = {}


func _ready():
	add_constant_override("separation", 4)
	for id in tracked_option_nodes:
		tracked_option_nodes[id].set_value(option_values[id])


func add_label(label:String, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/LabelOption.tscn").instance()
	__add_decoration_node(node, params)
	node.bbcode_text = label
	return node



func add_seperator(label:String="", params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/SeperatorOption.tscn").instance()
	__add_decoration_node(node, params)
	node.get_node("Label").text = label
	return node



func add_toggle(id:String, label:String, default:bool = false, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/ToggleOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("CheckButton").text = label
	return node



func add_textline(id:String, label:String, default:String = "", params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/TextlineOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("Label").text = label
	return node



func add_number(id:String, label:String, default = 0, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/NumberOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("Label").text = label
	return node



func add_slider(id:String, label:String, default = 0, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/SliderOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("Label").text = label
	return node



func add_dropdown(id:String, label:String, default = null, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/DropdownOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("Label").text = label
	return node



func add_color(id:String, label:String, default = null, params:Dictionary = {}):
	var node = load("res://_tri_char_codex/options/ColorOption.tscn").instance()
	__add_tracked_node(id, node, default, params)
	node.get_node("Label").text = label
	return node



func add_custom_scene(id:String, scene, default = null, params:Dictionary = {}):
	scene = __parse_as_scene(scene)
	if scene == null:
		return
	var error = false
	if not scene.has_method("set_value"):
		printerr("CODEX CHAR OPTIONS ERROR: \"", id ,"\" scene missing required func set_value(value)")
		error = true
	if not scene.has_method("get_data"):
		printerr("CODEX CHAR OPTIONS ERROR: \"", id ,"\" scene missing required func get_data()")
		error = true
	if not scene.has_signal("data_changed"):
		printerr("CODEX CHAR OPTIONS ERROR: \"", id ,"\" scene missing required signal data_changed()")
		error = true
	if error:
		scene.queue_free()
		return null
	__add_tracked_node(id, scene, default, params)
	return scene



func add_custom_decor(scene, params:Dictionary = {}):
	scene = __parse_as_scene(scene)
	if scene == null:
		return
	__add_decoration_node(scene, params)
	return scene



func __parse_as_scene(scene):
	if scene is String:
		if not ResourceLoader.exists(scene):
			printerr("CODEX CHAR OPTIONS ERROR: ", scene ," does not exist!")
			return null
		scene = load(scene)
	if scene is PackedScene:
		scene = scene.instance()
	if not (scene is Node):
		printerr("CODEX CHAR OPTIONS ERROR: scene is not a node!")
		return null
	return scene



func __add_tracked_node(id:String, node:Node, default = null, params:Dictionary = {}):
	if tracked_option_nodes.has(id):
		printerr("CODEX CHAR OPTIONS ERROR: Cannot have two options with the same id (", id ,")")
		return
	node.name = "Option" + id
	add_child(node)
	if node.has_method("apply_params"):
		node.apply_params(params)
	node.connect("data_changed", self, "emit_signal", ["data_changed"])
	option_values[id] = default
	tracked_option_nodes[id] = node


func __add_decoration_node(node:Node, params:Dictionary = {}):
	node.name = "UntrackedDecorationNode"
	add_child(node)
	if node.has_method("apply_params"):
		node.apply_params(params)


func __get_named_button_group(group_name):
	if not button_groups.has(group_name):
		button_groups[group_name] = ButtonGroup.new()
	return button_groups[group_name]


func set_value(value):
	if value is Dictionary:
		for id in value:
			option_values[id] = value[id]
	# TODO late set


func get_data():
	var result = {}
	for id in tracked_option_nodes:
		result[id] = tracked_option_nodes[id].get_data()
	return result
