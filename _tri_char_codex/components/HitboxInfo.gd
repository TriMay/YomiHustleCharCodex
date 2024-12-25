extends VBoxContainer


signal more_info_toggled(toggled)


var show_more_info = false


const HITS_TRUE_COLOR = Color(0.3, 1.0, 0.3)
const HITS_FALSE_COLOR = Color(0.3, 0.3, 0.3)


func set_title(title : String):
	$"%Title".text = title


func set_frames(start, active, loop_active = -1, loop_inactive = -1):
	var active_text = str(start)
	if active == -1:
		active_text += "+"
	elif active > 1:
		active_text += " - " + str(start + active - 1)
	if loop_active > 0 and loop_inactive > 0:
		$"%Frames".text = " F " + active_text + " (Loops " + str(loop_active) + " : " + str(loop_inactive) + ")"
	else:
		$"%Frames".text = " Frame " + active_text


func toggle_more_info(toggle : bool):
	show_more_info = toggle
	$"%Dizzy".visible = show_more_info
	$"%Projectiles".visible = show_more_info
	emit_signal("more_info_toggled", toggle)


func set_vs_grounded(hits : bool):
	$"%Grounded".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%Grounded".hint_tooltip = ("Hits" if hits else "Misses") + " VS Grounded"

func set_vs_aerial(hits : bool):
	$"%Aerial".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%Aerial".hint_tooltip = ("Hits" if hits else "Misses") + " VS Aerial"

func set_vs_standing(hits : bool):
	$"%Standing".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%Standing".hint_tooltip = ("Hits" if hits else "Misses") + " VS Standing"

func set_vs_otg(hits : bool):
	$"%OTG".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%OTG".hint_tooltip = ("Hits" if hits else "Misses") + " VS Knockdown"

func set_vs_dizzy(hits : bool):
	$"%Dizzy".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%Dizzy".hint_tooltip = ("Hits" if hits else "Misses") + " VS Dizzy"

func set_vs_projectiles(hits : bool):
	$"%Projectiles".modulate = HITS_TRUE_COLOR if hits else HITS_FALSE_COLOR
	$"%Projectiles".hint_tooltip = ("Hits" if hits else "Misses") + " VS Projectiles"


func add_stat_panel(stat, value, more_value = null, hidden_info = false):
	var panel = load("res://_tri_char_codex/components/StatPanel.tscn").instance()
	panel.set_label(stat)
	panel.set_value(value)
	panel.set_more_value(more_value)
	panel.is_more_info = hidden_info
	panel.toggle_more_info(show_more_info)
	connect("more_info_toggled", panel, "toggle_more_info")
	$"%Stats".add_child(panel)
	return panel



func add_damage_panel(stat, value, more_value, minimum_value):
	var panel = load("res://_tri_char_codex/components/StatPanel.tscn").instance()
	panel.set_label(stat)
	panel.set_value(value)
	panel.set_more_value("{" + str(more_value) + "}")
	panel.set_minimum_value(">" + str(minimum_value))
	panel.get_node("%MoreValue").hint_tooltip = "Damage In Combo"
	panel.get_node("%MinValue").hint_tooltip = "Minimum Damage"
	panel.is_more_info = false
	panel.toggle_more_info(show_more_info)
	connect("more_info_toggled", panel, "toggle_more_info")
	$"%Stats".add_child(panel)
	return panel
