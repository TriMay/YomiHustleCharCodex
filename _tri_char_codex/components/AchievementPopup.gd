extends CanvasLayer


var display_time = 0.0


func _ready():
	var codex = get_node_or_null("/root/CharCodexLibrary")
	if is_instance_valid(codex):
		codex.connect("achievement_unlocked", self, "on_achievement")


func on_achievement(achievement_list, achievement_id):
	if achievement_list.uses_default_fanfare:
		$"%AchievementName".text = achievement_list.get_display_title(achievement_id)
		var highlight = achievement_list.get_display_highlight(achievement_id)
		$"%AchievementHolder".line_color = highlight
		$"%IconHolder".line_color = highlight
		$"%AchievementIcon".texture = achievement_list.get_display_icon(achievement_id)
		$"%AchievementHolder".visible = true
		display_time = 4.0
		$"%AchievementHolder".rect_position.y = -50
		if achievement_list.uses_default_sound:
			$"%AchievementSound".play()


func _process(delta):
	if display_time > 0.0:
		display_time -= delta
		$"%AchievementHolder".rect_position.y = ($"%AchievementHolder".rect_position.y * 2.0 + 10.0) / 3.0
		if display_time <= 0.0:
			$"%AchievementHolder".visible = false
