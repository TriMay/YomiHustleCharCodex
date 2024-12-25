extends "res://modloader/MLMainHook.gd"


func _ready():
	# add the main menu codex screen
	var menu = load("res://_tri_char_codex/SettingsWindow.tscn").instance()
	var uilayer = $"%OptionsContainer/.."
	uilayer.add_child_below_node($"%OptionsContainer", menu, true)
	
	var btn:Node = addMainMenuButton("Codex")
	btn.connect("pressed", menu, "_mainmenu_button_pressed")
	
	# add the pause menu codex screen
	var mid_match_menu = load("res://_tri_char_codex/windows/MatchMenu.tscn").instance()
	var pause_panel = $"%PausePanel"
	var pause_container = pause_panel.get_node("VBoxContainer")
	pause_container.add_child(mid_match_menu, true)
	pause_container.move_child(mid_match_menu, 0)
	
	var pause_parent = pause_panel.get_parent()
	pause_parent.move_child(pause_panel, pause_parent.get_child_count())
	
	# add the achievement fanfare
	var achievement_popup = load("res://_tri_char_codex/components/AchievementPopup.tscn").instance()
	var main = get_node("/root/Main")
	main.call_deferred("add_child", achievement_popup)
