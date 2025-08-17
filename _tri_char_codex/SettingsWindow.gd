extends Window


signal debug_setting_changed(setting, value)


const USiNG_THREADS = true

onready var char_list_node = $"%CharList"
onready var search_node = $"%SearchLine"
onready var page_container = $"%Page"

onready var button_group = ButtonGroup.new()

var load_thread = null
var currently_loading = false

var try_setup_next_frame = false

var CodexHandler
var CharSelect

func _ready():
	hint_tooltip = ""
	#setup_library_menu()
	$"%Close".connect("pressed", self, "_close_clicked")
	$"%Settings".connect("pressed", self, "_settings_clicked")
	$"%CloseSettings".connect("pressed", self, "_close_settings")
	$"%WinLossMode".connect("item_selected", self, "_win_loss_mode_selected")
	$"%ChievoPopups".connect("toggled", self, "_chievo_popups_toggled")
	$"%MisclickProtection".connect("toggled", self, "_misclick_prevent_toggled")
	search_node.connect("text_changed", self, "_on_search_changed")
	connect("visibility_changed", self, "_on_visibility_changed")
	hide()
	
	$"%DebugLayer".visible = false
	$"%DebugWindow".hint_tooltip = ""
	for child in $"%DebugSettings".get_children():
		if child is CheckButton:
			child.connect("toggled", self, "_on_change_debug_setting", [child.name])


func _on_visibility_changed():
	$"%DebugLayer".visible = visible and OS.is_debug_build()


func _process(delta):
	if Input.is_action_just_pressed("pause"):
		_close_clicked()



func set_page_node(node):
	for child in page_container.get_children():
		child.queue_free() 
	page_container.add_child(node)


func _on_search_changed(text):
	for character in char_list_node.get_children():
		character.visible = text == "" or text.to_lower() in character.text.to_lower()


func _close_clicked():
	_close_settings()
	hide()


func _settings_clicked():
	var win_loss_mode = win_loss_modes.find(CodexHandler.load_codex_setting("win_loss_stats"))
	if win_loss_mode == -1:
		win_loss_mode = 1
	$"%WinLossMode".selected = win_loss_mode
	$"%ChievoPopups".set_pressed_no_signal(CodexHandler.load_codex_setting("no_fun_mode"))
	$"%MisclickProtection".set_pressed_no_signal(CodexHandler.load_codex_setting("misclick_prevent"))
	$SettingsWindow.visible = not $SettingsWindow.visible
	$SettingsCover.visible = $SettingsWindow.visible


var win_loss_modes = ['hide', 'wins_only', 'show']


func _close_settings():
	$SettingsWindow.visible = false
	$SettingsCover.visible = false


func _win_loss_mode_selected(index):
	print(win_loss_modes[index])
	CodexHandler.save_codex_setting("win_loss_stats", win_loss_modes[index])


func _chievo_popups_toggled(toggle):
	CodexHandler.save_codex_setting("no_fun_mode", toggle)


func _misclick_prevent_toggled(toggle):
	CodexHandler.save_codex_setting("misclick_prevent", toggle)



func _mainmenu_button_pressed():
	call_deferred("setup_library_menu")
	show()


func setup_library_menu():
	search_node.text = ""
	var current_handler = get_node_or_null("/root/CharCodexLibrary")
	if current_handler != null:
		CodexHandler = current_handler
	#	for codex in CodexHandler.codex_entries:
	#		pass
	CharSelect = get_node_or_null("/root/Main/%CharacterSelect")
	
	for child in char_list_node.get_children():
		char_list_node.remove_child(child)
		child.queue_free()
	
	for char_index in Global.name_paths:
		if not "__" in char_index:
			var vanilla_character = Global.name_paths[char_index]
			var button := create_button()
			button.text = char_index
			button.connect("toggled", self, "_on_char_button_toggled", [vanilla_character, -1])
			char_list_node.add_child(button)
	
	if CharSelect.get("loaded_mods") == false:
		if CharSelect.has_signal("mods_loaded"):
			if not CharSelect.is_connected("mods_loaded", self, "_reset_when_loaded"):
				CharSelect.connect("mods_loaded", self, "_reset_when_loaded")
		var label : Label = Label.new()
		label.rect_min_size = Vector2(30, 50)
		label.text = "LOADING MODS..."
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		char_list_node.add_child(label)
	else:
		if CharSelect.get("charList") is Array:
			for char_index in CharSelect.charList.size():
				var modded_character = CharSelect.charList[char_index]
				var button := create_button()
				button.text = modded_character[0]
				button.connect("toggled", self, "_on_char_button_toggled", [modded_character[1], char_index])
				char_list_node.add_child(button)


func _reset_when_loaded():
	yield(get_tree().create_timer(0.1), "timeout")
	call_deferred("setup_library_menu")


func create_button() -> Button:
	var button : Button = Button.new()
	button.rect_min_size = Vector2(30, 15)
	button.toggle_mode = true
	button.group = button_group
	return button


func _on_char_button_toggled(toggled, char_path, char_index):
	if toggled and not currently_loading:
		for child in page_container.get_children():
			child.queue_free()
		var loading_label = load("res://_tri_char_codex/components/PageLoading.tscn").instance()
		loading_label.easter_egg(char_path)
		page_container.add_child(loading_label)
		if CodexHandler.has_cached(char_path) or char_index < 0:
			call_deferred("set_page_node", CodexHandler.generate_node(char_path))
		else:
			try_to_clean_thread()
			if not is_instance_valid(CharSelect):
				return
			if CharSelect.currentlyLoading:
				return
			if USiNG_THREADS:
				load_thread = Thread.new()
				load_thread.start(self, "async_load_char_page", { "file":char_path, "index":char_index }, Thread.PRIORITY_HIGH)
			else:
				async_load_char_page({ "file":char_path, "index":char_index })


func async_load_char_page(char_data):
	currently_loading = true
	var codex = CodexHandler
	var cs = CharSelect
	if not codex.can_generate(char_data.file) and char_data.index > -1:
		cs.loadListChar(char_data.index)
		cs.loadingText = ""
		cs.currentlyLoading = false
	var generation = codex.generate_node(char_data.file)
	call_deferred("set_page_node", generation)
	currently_loading = false
	return


func try_to_clean_thread():
	# this memory leaks if the thread is not alive
	# because I could not figure out how to get godot to not freeze
	# when trying to tell it to finish early.
	
	# it just hangs forever...
	
	# if someone else knows why, please fix it
	# if not, don't waste your time like I did 3 hours of mine
	if load_thread is Thread:
		if not load_thread.is_alive():
			load_thread.wait_to_finish()
			load_thread = null


func _exit_tree():
	try_to_clean_thread()


func _on_change_debug_setting(toggled, setting):
	if toggled:
		if setting == "DebugLockedAchievement":
			$"%DebugUnlockedAchievement".set_pressed(false)
		if setting == "DebugUnlockedAchievement":
			$"%DebugLockedAchievement".set_pressed(false)
	emit_signal("debug_setting_changed", setting, toggled)


func get_debug_settings():
	var result = {}
	for child in $"%DebugSettings".get_children():
		if child is CheckButton:
			result[child.name] = child.pressed
	return result
