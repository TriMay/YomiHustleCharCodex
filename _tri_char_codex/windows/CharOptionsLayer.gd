extends CanvasLayer


signal play_request()
signal window_entered()


const USiNG_THREADS = true

onready var page_container = $Window/VBoxContainer/Contents

var load_thread = null
var currently_loading = false

var used_context = "CharSelect"
var char_path = ""

var CodexHandler
var CharSelect


func _ready():
	$Window.hint_tooltip = ""
	$Window.connect("mouse_entered", self, "emit_signal", ["window_entered"])
	page_container.connect("mouse_entered", self, "emit_signal", ["window_entered"])


func set_char_name(value):
	$Window/VBoxContainer/TitleBar/Title.text = "Character Options (" + value + ")"


func setup(char_path, char_index):
	self.char_path = char_path
	if not currently_loading:
		var loading_label = load("res://_tri_char_codex/components/PageLoading.tscn").instance()
		loading_label.easter_egg(char_path)
		page_container.add_child(loading_label)
		if CodexHandler.has_cached(char_path) or char_index < 0:
			var generation = setup_options_node(CodexHandler.generate_options_node(char_path))
			call_deferred("set_page_node", generation)
		else:
			try_to_clean_thread()
			if not is_instance_valid(CharSelect):
				_close()
				return
			if CharSelect.currentlyLoading:
				_close()
				return
			if USiNG_THREADS:
				load_thread = Thread.new()
				load_thread.start(self, "async_load_char_page", { "file":char_path, "index":char_index }, Thread.PRIORITY_HIGH)
			else:
				async_load_char_page({ "file":char_path, "index":char_index })



func _close(force = false):
	if force:
		visible = false
	if not currently_loading:
		queue_free()
		return true
	return false



func _play():
	emit_signal("play_request")
	_close()



func _process(delta):
	if Input.is_action_just_pressed("pause"):
		_close()



func set_page_node(node):
	for child in page_container.get_children():
		child.queue_free() 
	page_container.add_child(node)
	if not visible:
		queue_free()



func setup_options_node(inner_node):
	var result = inner_node
	match used_context:
		"CharSelect":
			var container = load("res://_tri_char_codex/windows/CharOptionsCharSelect.tscn").instance()
			container.get_node("%OptionsContainer").add_child(result)
			container.connect("close_request", self, "_close")
			container.connect("play_request", self, "_play")
			container.connect("window_entered", self, "emit_signal", ["window_entered"])
			result = container
		"CodexMenu", _:
			var container = load("res://_tri_char_codex/windows/CharOptionsCodexMenu.tscn").instance()
			container.get_node("%OptionsContainer").add_child(result)
			container.connect("close_request", self, "_close")
			container.connect("window_entered", self, "emit_signal", ["window_entered"])
			result = container
	inner_node.connect("data_changed", self, "on_data_changed", [inner_node])
	inner_node.set_value(CodexHandler.load_all_char_options(char_path))
	return result



func on_data_changed(options):
	call_deferred("data_changed_deferred", options)



func data_changed_deferred(options):
	print(options.get_data())
	CodexHandler.save_all_char_options(char_path, options.get_data())



func async_load_char_page(char_data):
	currently_loading = true
	var codex = CodexHandler
	var cs = CharSelect
	if not codex.can_generate(char_data.file) and char_data.index > -1:
		cs.loadListChar(char_data.index)
		cs.loadingText = ""
		cs.currentlyLoading = false
	var generation = setup_options_node(codex.generate_options_node(char_data.file))
	call_deferred("set_page_node", generation)
	currently_loading = false
	return


func try_to_clean_thread():
	# see rant in res://_tri_char_codex/SettingsWindow.gd
	if load_thread is Thread:
		if not load_thread.is_alive():
			load_thread.wait_to_finish()
			load_thread = null


func _exit_tree():
	try_to_clean_thread()
