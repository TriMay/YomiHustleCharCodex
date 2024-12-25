extends MarginContainer


signal more_info_toggled(toggled)


const MAX_LABEL_WIDTH = 270


var char_path = ""
var codex_data
var achievement_list

var state_button_group : ButtonGroup = ButtonGroup.new()
var achievement_button_group : ButtonGroup = ButtonGroup.new()
var tab_button_group : ButtonGroup = ButtonGroup.new()

var selected_move_type : String = ""
var selected_stance : String = ""
var tag_mode : bool = false
var show_more_info : bool = false


var default_achievement_texture

var debug_settings = {
	"DebugAchievementID": false,
	"DebugHiddenAchievement": false,
	"DebugLockedAchievement": false,
	"DebugUnlockedAchievement": false
}


func _init():
	default_achievement_texture = load("res://ui/HUD/feint.png")


func _ready():
	for button in $"%Types".get_children():
		button.connect("toggled", self, "_type_button_toggled", [button.name])
	var basic_tab_buttons = [
		{ "button": $"%SummaryButton", "tab": $"%TabSummary" },
		{ "button": $"%MoveListButton", "tab": $"%TabMoveList" },
		{ "button": $"%StatsButton", "tab": $"%TabStats" },
		{ "button": $"%OptionsButton", "tab": $"%TabOptions" },
		{ "button": $"%AchievementsButton", "tab": $"%TabAchievements" },
	]
	for tab in basic_tab_buttons:
		tab.button.group = tab_button_group
		tab.button.connect("toggled", self, "_tab_button_toggled", [tab.tab])
	$"%StanceOption".connect("item_selected", self, "_stance_option_changed", [$"%StanceOption"])
	$"%MoreInfoButton".connect("toggled", self, "_more_info_button_toggled")
	$"%Summary".connect("meta_clicked", self, "_label_meta_clicked")
	$"%MoveDesc".connect("meta_clicked", self, "_label_meta_clicked")
	$"%Types/Attack".set_pressed(true)
	var has_preffered_tab = false
	var CodexHandler = get_node_or_null("/root/CharCodexLibrary")
	if CodexHandler != null:
		$"%MoreInfoButton".set_pressed(CodexHandler.prefers_more_info)
		match CodexHandler.preferred_tab:
			"TabSummary":
				if $"%SummaryButton".visible: # TOOD blank summary tab when has no tab
					$"%SummaryButton".set_pressed(true)
					has_preffered_tab = true
			"TabMoveList":
				if $"%MoveListButton".visible: # TOOD blank movelist tab when has no tab
					$"%MoveListButton".set_pressed(true)
					has_preffered_tab = true
			"TabStats":
				if $"%StatsButton".visible: # TOOD blank stats tab when has no tab
					$"%StatsButton".set_pressed(true)
					has_preffered_tab = true
			"TabOptions":
				$"%OptionsButton".set_pressed(true)
				has_preffered_tab = true
			"TabAchievements":
				$"%AchievementsButton".set_pressed(true)
				has_preffered_tab = true
	if not has_preffered_tab:
		var store_tab = CodexHandler.preferred_tab
		if $"%MoveListButton".visible: # TOOD blank movelist tab when has no tab
			$"%MoveListButton".set_pressed(true)
		CodexHandler.preferred_tab = store_tab
	if OS.is_debug_build():
		var settings_window = get_parent().owner
		if settings_window.has_method("get_debug_settings"):
			settings_window.connect("debug_setting_changed", self, "_on_debug_setting_changed")
			debug_settings = settings_window.get_debug_settings()
			for setting in debug_settings:
				_on_debug_setting_changed(setting, debug_settings[setting], true)


func generate(codex_data):
	self.codex_data = codex_data
	char_path = codex_data.char_path
	$"%Title".text = codex_data.title
	$"%Subtitle".text = codex_data.subtitle
	$"%MoveListButton".visible = not codex_data.has_no_moveset
	$"%StatsButton".visible = not codex_data.has_no_stats
	$"%Summary".bbcode_text = codex_data.summary
	if codex_data.summary != "":
		$"%SummaryButton".visible = true
	$"%Banner".texture = codex_data.banner
	$"%Banner".rect_position = codex_data.banner_offset
	$"%Banner".rect_scale = codex_data.banner_scale
	$"%Banner".rect_rotation = codex_data.banner_rotation
	var pop_up = $"%StanceOption".get_popup()
	var id = 0
	$"%StanceOption".clear()
	pop_up.add_separator("Stance", id)
	for stance in codex_data.stances:
		id += 1
		$"%StanceOption".add_item(stance, id)
		$"%StanceOption".set_item_metadata($"%StanceOption".get_item_index(id), { "is_tag":false, "name":stance })
	if codex_data.tags.size() > 0:
		id += 1
		pop_up.add_separator("Tag", id)
		for tag in codex_data.tags:
			id += 1
			$"%StanceOption".add_item(tag, id)
			$"%StanceOption".set_item_metadata($"%StanceOption".get_item_index(id), { "is_tag":true, "name":tag })
	id += 1
	# @TODO make sure this only shows moves with available stances before making this a feature
	# pop_up.add_separator("", id)
	# id += 1
	# $"%StanceOption".add_item("Show Everything!", id)
	# $"%StanceOption".set_item_metadata($"%StanceOption".get_item_index(id), { "is_tag":false, "name":"*" })
	$"%StanceOption".select(1)
	selected_stance = $"%StanceOption".get_selected_metadata().name
	$"%StanceOption".text = "Stance: " + $"%StanceOption".get_selected_metadata().name
	for move_id in codex_data.moveset:
		var move = codex_data.moveset[move_id]
		var button = create_new_move_button()
		button.hint_tooltip = move.title
		button.get_child(0).texture = move.icon
		button.connect("toggled", self, "_state_button_toggled", [move_id])
		button.name = move_id
		$"%Moves".add_child(button)
	var char_stats = codex_data.stats
	$"%MaxHPStat".text = str(char_stats.max_health * 10)
	$"%AirOptionDisplay".value = int(char_stats.air_options)
	$"%AirOptionDisplay".lose_one_in_neutral = bool(char_stats.lose_option_in_neutral) and int(char_stats.air_options) > 1
	$"%AirOptionDisplay".visible = not bool(char_stats.air_option_bar)
	$"%AirOptionBar".visible = bool(char_stats.air_option_bar)
	# TODO AIR OPTION BAR VALUE
	$"%FreeCancelDispay".value = int(char_stats.free_cancels)
	$"%AirOptionLabel".text = str(char_stats.air_option_name)
	$"%DamageModStat".text = str(char_stats.damage_taken * 100) + " %"
	$"%KnockbackModStat".text = str(char_stats.knockback_taken * 100) + " %"
	$"%DIModStat".text = str(char_stats.di_strength * 100) + " %"
	$"%GravityStat".text = "%0.1f px/f²" % char_stats.gravity
	$"%FrctionGroundStat".text = "Ground - %0.1f px/f²" % char_stats.friction_ground
	$"%FrctionAirStat".text = "Air - %0.1f px/f²" % char_stats.friction_air
	$"%SpeedGroundStat".text = "Ground - %0.1f px/f" % char_stats.max_speed_ground
	$"%SpeedAirStat".text = "Air - %0.1f px/f" % char_stats.max_speed_air
	$"%SpeedFallStat".text = "Fall - %0.1f px/f" % char_stats.max_speed_fall
	$"%IdleSprite".texture = char_stats.sprite_texture
	$"%IdleSprite".rect_position = char_stats.sprite_position * 2
	$"%IdleSprite".rect_scale = char_stats.sprite_scale * 2
	$"%Hurtbox".margin_left = (char_stats.hurtbox_x - char_stats.hurtbox_width)*2
	$"%Hurtbox".margin_right = (char_stats.hurtbox_x + char_stats.hurtbox_width)*2
	$"%Hurtbox".margin_top = (char_stats.hurtbox_y - char_stats.hurtbox_height)*2
	$"%Hurtbox".margin_bottom = (char_stats.hurtbox_y + char_stats.hurtbox_height)*2
	for tab in codex_data.custom_tabs:
		if tab is Dictionary:
			if not (tab.has("title") and tab.has("type") and tab.has("value")):
				continue
			if not tab.type in ["text", "scene"]:
				continue
			if tab.type == "text" and not tab.value is String:
				push_error("Custom Tab " + str(tab.title) + " is not a String")
				continue
			if tab.type == "scene" and not tab.value is PackedScene:
				push_error("Custom Tab " + str(tab.title) + " is not a PackedScene")
				continue
			var tab_button = create_new_tab_button(str(tab.title))
			var tab_container = create_new_tab(tab.type, tab.value)
			$"%TabContainer".add_child(tab_button)
			$"%Content".add_child(tab_container)
			tab_button.connect("toggled", self, "_tab_button_toggled", [tab_container])


func update_achievements(list):
	achievement_list = list
	var counts = list.get_totals()
	$"%AchievementsButton".text = " " + str(counts.unlocked) + "/" + str(counts.visible) + "       "
	$"%AchievementsButton".visible = (counts.total > 0)
	if counts.all_visible_unlocked:
		$"%TextureStar".texture = load("res://_tri_char_codex/images/achievement_unlocked.png")
		$"%AchievementsButton".add_color_override("font_color", Color(0.9, 0.8, 0.0))
	var grid = $"%AchievementGrid"
	for child in grid.get_children():
		child.queue_free()
	for chievo in list.achievements:
		var unlocked = debug_settings.DebugUnlockedAchievement or (list.achievements[chievo].unlocked and not debug_settings.DebugLockedAchievement)
		var button = create_new_achievement_button()
		button.visible = debug_settings.DebugHiddenAchievement or (unlocked) or (not list.achievements[chievo].secret)
		button.get_child(0).texture = list.get_debug_icon(chievo, unlocked)
		button.connect("toggled", self, "_achievement_button_toggled", [chievo])
		if not unlocked:
			button.modulate = Color(1.0, 1.0, 1.0, 0.5)
		grid.add_child(button)


func setup_options(node, value):
	node.set_value(value)
	node.connect("data_changed", self, "_options_changed", [node])
	$"%TabOptions".add_child(node)
	$"%OptionsButton".visible = true


func _achievement_button_toggled(toggled, id):
	if toggled:
		var title
		var desc
		var icon
		var highlight
		if debug_settings.DebugUnlockedAchievement or debug_settings.DebugLockedAchievement:
			title = achievement_list.get_debug_title(id, debug_settings.DebugUnlockedAchievement)
			desc = achievement_list.get_debug_desc(id, debug_settings.DebugUnlockedAchievement)
			icon = achievement_list.get_debug_icon(id, debug_settings.DebugUnlockedAchievement)
			highlight = achievement_list.get_debug_highlight(id, debug_settings.DebugUnlockedAchievement)
		else:
			title = achievement_list.get_display_title(id)
			desc = achievement_list.get_display_desc(id)
			icon = achievement_list.get_display_icon(id)
			highlight = achievement_list.get_display_highlight(id)
		if debug_settings.DebugAchievementID:
			title = title + " [" + id + "]"
		var true_highlight = achievement_list.get_display_highlight(id, true)
		var counter_text = achievement_list.get_display_counter_text(id)
		var counter_value = achievement_list.get_display_counter_value(id)
		var counter_target = achievement_list.get_display_counter_target(id)
		var text = "[u]" + title + "[/u]\n" + desc
		$"%AchievementLabel".bbcode_text = text
		$"%AchievementIcon".texture = icon
		$"%AchievementHolder".line_color = highlight
		$"%IconHolder".line_color = highlight
		$"%AchievementProgressSection".visible = (counter_text != "")
		$"%AchievementProgressBar".fill_color = true_highlight
		$"%AchievementProgressBar".current_value = counter_value
		$"%AchievementProgressBar".max_value = counter_target
		$"%AchievementProgressText".text = counter_text
		$"%AchievementGotLabel".text = "SECRET" if achievement_list.is_secret(id) else "GOT!"
		$"%AchievementGotLabel".visible = (debug_settings.DebugUnlockedAchievement or (achievement_list.is_unlocked(id) and not debug_settings.DebugLockedAchievement))
		$"%AchievementGotLabel".modulate = true_highlight


func _more_info_button_toggled(toggled):
	show_more_info = toggled
	var CodexHandler = get_node_or_null("/root/CharCodexLibrary")
	if CodexHandler != null:
		CodexHandler.prefers_more_info = toggled
	emit_signal("more_info_toggled", toggled)


func _tab_button_toggled(toggled, tab):
	if toggled:
		var CodexHandler = get_node_or_null("/root/CharCodexLibrary")
		if CodexHandler != null:
			CodexHandler.preferred_tab = tab.name
		for other_tab in $"%Content".get_children():
			other_tab.visible = false
		tab.visible = true


func _type_button_toggled(toggled, type):
	if toggled:
		selected_move_type = type
		update_visible_moves()


func _stance_option_changed(item, option_node : OptionButton):
	var metadata = option_node.get_selected_metadata()
	selected_stance = metadata.name
	tag_mode = metadata.is_tag
	if selected_stance == "*":
		option_node.text = "Full Moveset"
	else:
		option_node.text = ("Tag: " if tag_mode else "Stance: ") + selected_stance
	update_visible_moves()


func _options_changed(options):
	if not $"%TabOptions".visible:
		return
	print(options.get_data())
	var CodexHandler = get_node_or_null("/root/CharCodexLibrary")
	if CodexHandler	!= null:
		CodexHandler.save_all_char_options(char_path, options.get_data())


func update_visible_moves():
	var types_visible = {
		"Movement": false,
		"Attack": false,
		"Special": false,
		"Super": false,
		"Defense": false
	}
	for button in $"%Moves".get_children():
		var move = codex_data.moveset[button.name]
		var matched_array = move.tags if tag_mode else move.stances
		var move_usable = move.visible and (selected_stance == "*" or selected_stance in matched_array or "All" in matched_array)
		button.visible = move_usable and move.type == selected_move_type
		if move_usable:
			types_visible[move.type] = true
	for type in $"%Types".get_children():
		type.disabled = not types_visible[type.text]


func _label_meta_clicked(meta):
	handle_url_meta(meta)
	# @TODO consider allowing combining url meta's for showing a specific stance and move in that stance


func handle_url_meta(meta):
	if meta is String:
		var parsed_meta : String = meta.lstrip(" ").rstrip(" ")
		# move url
		if parsed_meta.begins_with("move:"):
			var target = parsed_meta.substr(5)
			var button = $"%Moves".get_node_or_null("%Moves/" + target)
			if button != null:
				button.set_pressed(true)
				$"%MoveListButton".set_pressed(true)
		# stance url
		if parsed_meta.begins_with("stance:"):
			var target = parsed_meta.substr(7)
			var button = $"%StanceOption"
			for id in button.get_item_count():
				var index = button.get_item_index(id+1)
				var option = button.get_item_metadata(index)
				if not option is Dictionary:
					continue
				var is_tag = option.get("is_tag", true)
				var name = option.get("name", "")
				if not is_tag and name == target:
					button.selected = index
					button.emit_signal("item_selected", index)
					$"%MoveListButton".set_pressed(true)
					break
				# stance url
		if parsed_meta.begins_with("tagged:"):
			var target = parsed_meta.substr(7)
			var button = $"%StanceOption"
			for id in button.get_item_count():
				var index = button.get_item_index(id+1)
				var option = button.get_item_metadata(index)
				if not option is Dictionary:
					continue
				var is_tag = option.get("is_tag", false)
				var name = option.get("name", "")
				if is_tag and name == target:
					button.selected = index
					button.emit_signal("item_selected", index)
					$"%MoveListButton".set_pressed(true)
					break
		# tab url
		if parsed_meta.begins_with("tab:"):
			var target = parsed_meta.substr(4)
			for button in $"%TabContainer".get_children():
				if button.text == target:
					button.set_pressed(true)
					break


func _state_button_toggled(toggled, state):
	if toggled:
		for child in $"%FrameData".get_children():
			$"%FrameData".remove_child(child)
			child.queue_free() 
		for child in $"%MoveStats".get_children():
			$"%MoveStats".remove_child(child)
			child.queue_free() 
		for child in $"%HitboxStats".get_children():
			$"%HitboxStats".remove_child(child)
			child.queue_free() 
		var FrameDataPill = load("res://_tri_char_codex/Pill.gd")
		var move = codex_data.moveset[state]
		$"%MoveTitle".text = move.title
		$"%MoveDesc".bbcode_text = move.desc
		var true_iasa = -1 if move.endless else (move.iasa if move.iasa >= 0 else move.length + move.iasa)
		var earliest_interrupt : int = true_iasa
		var in_armor : bool = false
		var in_invulnerability : bool = false
		var in_projectile_invuln : bool = false
		var in_grab_invuln : bool = false
		var in_aerial_invuln : bool = false
		var in_grounded_invuln : bool = false
		var num_pills = move.length
		if num_pills == -1 and move.endless:
			for tick_id in move.tick_data:
				if tick_id+6 > num_pills:
					num_pills = tick_id+6
			for hitbox_id in move.hitbox_data:
				var hitbox = move.hitbox_data[hitbox_id]
				var end_of = hitbox.start
				end_of += 5 if hitbox.always_on else hitbox.active + 4
				if end_of > num_pills:
					num_pills = end_of
		if num_pills > 200:
			num_pills = 200
		for frame in int(num_pills):
			var pill = FrameDataPill.new()
			pill.name = "F" + str(frame)
			pill.hint_tooltip = "Frame " + str(frame + 1)
			if frame == true_iasa:
				pill.add_color(Color(0.0, 1.0, 0.0))
				pill.hint_tooltip += "\nInterrupt"
			if move.tick_data.has(frame):
				for item in move.tick_data[frame]:
					match item:
						"Interrupt":
							earliest_interrupt = min(earliest_interrupt, frame)
							pill.add_color(Color(0.0, 1.0, 0.0))
							pill.hint_tooltip += "\nInterrupt"
						"Projectile":
							pill.add_color(Color(1.0, 1.0, 0.0))
							pill.hint_tooltip += "\nProjectile"
						"Start Armor":
							in_armor = true
						"Start Invulnerability":
							in_invulnerability = true
						"Start Projectile Invuln.":
							in_projectile_invuln = true
						"Start Grab Invuln.":
							in_grab_invuln = true
						"Start Aerial Invuln.":
							in_aerial_invuln = true
						"Start Grounded Invuln.":
							in_grounded_invuln = true
						"End Armor":
							in_armor = false
						"End Invulnerability":
							in_invulnerability = false
						"End Projectile Invuln.":
							in_projectile_invuln = false
						"End Grab Invuln.":
							in_grab_invuln = false
						"End Aerial Invuln.":
							in_aerial_invuln = false
						"End Grounded Invuln.":
							in_grounded_invuln = false
						_:
							if str(item).begins_with("_"):
								pill.set_label_text(str(item).substr(1))
								pill.hint_tooltip += "\n" + str(item).substr(1)
			if in_armor:
				pill.add_color(Color(0.0, 1.0, 1.0))
				pill.hint_tooltip += "\nArmor"
			if in_invulnerability:
				pill.add_color(Color(0.0, 0.0, 1.0))
				pill.hint_tooltip += "\nInvulnerable"
			if in_projectile_invuln:
				pill.add_color(Color(0.3, 0.3, 0.3))
				pill.hint_tooltip += "\nProjectile Invuln."
			if in_grab_invuln:
				pill.add_color(Color(0.3, 0.3, 0.3))
				pill.hint_tooltip += "\nGrab Invuln."
			if in_aerial_invuln:
				pill.add_color(Color(0.3, 0.3, 0.3))
				pill.hint_tooltip += "\nAerial Invuln."
			if in_grounded_invuln:
				pill.add_color(Color(0.3, 0.3, 0.3))
				pill.hint_tooltip += "\nGrounded Invuln."
			$"%FrameData".add_child(pill)
			if frame % 10 == 9:
				var seperator = Control.new()
				seperator.size_flags_horizontal = 0
				seperator.rect_min_size = Vector2(1, 0)
				$"%FrameData".add_child(seperator)
		if move.length > 200 or move.endless:
			# @TODO add blank control nodes to force this onto the next line if near end
			var control := Control.new()
			control.rect_min_size = Vector2(7, 12)
			var label := Label.new()
			if move.endless:
				label.text = "Endless"
			elif move.length > 200:
				label.text = "+" + str(move.length - 200)
			control.add_child(label)
			$"%FrameData".add_child(control)
		if move.tags.size() > 0:
			$"%MoveStats".add_child(create_move_stat_panel("Tags", move.tags))
		if move.stances.size() > 0:
			$"%MoveStats".add_child(create_move_stat_panel("Stances", move.stances))
		if move.change_stance != "":
			$"%MoveStats".add_child(create_move_stat_panel("Set Stance To", move.change_stance))
		if earliest_interrupt >= 0:
			$"%MoveStats".add_child(create_move_stat_panel("IASA", earliest_interrupt + 1))
		if move.super_req > 0:
			$"%MoveStats".add_child(create_move_stat_panel("Super Req." if move.super_cost >= 0 and move.super_cost != move.super_req else "Super", move.super_req))
		if move.super_cost >= 0 and move.super_cost != move.super_req:
			$"%MoveStats".add_child(create_move_stat_panel("Super Cost", move.super_cost))
		for stat in move.custom_stats:
			$"%MoveStats".add_child(create_move_stat_panel(stat, move.custom_stats[stat]))
		for hitbox_id in move.hitbox_data:
			var hitbox = move.hitbox_data[hitbox_id]
			if hitbox.marked_as_duplicate:
				continue
			var start = int(hitbox.start)
			var active = int(hitbox.active) if not hitbox.always_on else int(num_pills + 1) - start
			var title = hitbox.title
			if not title is String or title == "":
				title = ""
				if hitbox.is_grab:
					title = "Grab"
				else:
					if hitbox.is_guard_break:
						title += "Guard Break"
					if hitbox.is_hit_grab:
						title += "Hit Grab"
				if title == "":
					title = "Hitbox"
			var frame_data_color = hitbox.color
			if not frame_data_color is Color or frame_data_color.a <= 0.01:
				frame_data_color = Color(0.8, 0.2, 0.2)
				match str(title).to_lower().replace(" ", ""):
					"hitgrab":
						title = "Hit Grab"
						frame_data_color = Color(0.6, 0.0, 0.5)
					"grab":
						title = "Grab"
						frame_data_color = Color(1.0, 0.2, 1.0)
					"guardbreak":
						title = "Guard Break"
						frame_data_color = Color(0.9, 0.5, 0.0)
					"guardbreakgrab", "guardbreakhitgrab":
						title = "Guard Break Hit Grab"
						frame_data_color = Color(0.6, 0.3, 0.0)
			for f in int(max(active, 0)):
				var pill = get_node_or_null("%FrameData/F" + str(start + f - 1))
				if pill == null:
					break
				if hitbox.looping:
					var loop_tick = f % (hitbox.loop_active + hitbox.loop_inactive)
					var enabled = loop_tick < hitbox.loop_active
					if not enabled:
						continue
				pill.colors.append(frame_data_color)
				pill.hint_tooltip += "\n" + title
			
			var hitbox_info = load("res://_tri_char_codex/components/HitboxInfo.tscn").instance()
			
			hitbox_info.set_title(str(title))
			if hitbox.looping:
				hitbox_info.set_frames(start, -1 if move.endless and hitbox.always_on else active, hitbox.loop_active, hitbox.loop_inactive)
			else:
				hitbox_info.set_frames(start, -1 if move.endless and hitbox.always_on else active)
			
			hitbox_info.set_vs_grounded(hitbox.hits_grounded)
			hitbox_info.set_vs_aerial(hitbox.hits_aerial)
			hitbox_info.set_vs_standing(hitbox.hits_standing)
			hitbox_info.set_vs_otg(hitbox.hits_otg)
			hitbox_info.set_vs_dizzy(hitbox.hits_dizzy)
			hitbox_info.set_vs_projectiles(hitbox.hits_projectiles)
			
			var in_combo_damage = hitbox.damage if hitbox.combo_damage == -1 else hitbox.combo_damage
			var minimum_damage = hitbox.minimum_damage
			hitbox_info.add_damage_panel("Damage", hitbox.damage * 10, in_combo_damage * 10, minimum_damage * 10)
			var in_combo_stun = hitbox.stun if hitbox.combo_stun == -1 else hitbox.combo_stun
			var stun_panel = hitbox_info.add_stat_panel("Stun", hitbox.stun, "{" + str(in_combo_stun) + "}")
			stun_panel.get_node("%MoreValue").hint_tooltip = "Stun In Combo"
			hitbox_info.add_stat_panel("Knockback", { "amount":hitbox.knockback, "x":hitbox.knockback_x, "y":hitbox.knockback_y })
			hitbox_info.add_stat_panel("Height", hitbox.height)
			hitbox_info.add_stat_panel("Block Adv.", hitbox.plus_frames)
			
			hitbox_info.add_stat_panel("Combo Scale", "x" + str(hitbox.combo_scaling), "Proration: " + str(hitbox.proration), true)
			hitbox_info.add_stat_panel("DI Mod.", str(hitbox.di_modifier * 100) + "%", null, true)
			hitbox_info.add_stat_panel("SDI Mod.", str(hitbox.sdi_modifier * 100) + "%", null, true)
			hitbox_info.add_stat_panel("Pushback", str(hitbox.pushback * 100) + "%", null, true)
			hitbox_info.add_stat_panel("Meter Gain", str(hitbox.meter_gain_modifier * 100) + "%", null, true)
			
			# @TODO Show Followup
			
			hitbox_info.toggle_more_info(show_more_info)
			connect("more_info_toggled", hitbox_info, "toggle_more_info")
			$"%HitboxStats".add_child(hitbox_info)



func create_new_tab_button(title : String) -> Button:
	var btn := Button.new()
	btn.group = tab_button_group
	btn.toggle_mode = true
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.size_flags_vertical = SIZE_EXPAND_FILL
	btn.text = title
	return btn


func create_new_tab(type : String, value):
	var tab := MarginContainer.new()
	tab.size_flags_horizontal = SIZE_EXPAND_FILL
	tab.size_flags_vertical = SIZE_EXPAND_FILL
	match type:
		"text":
			var label = RichTextLabel.new()
			label.bbcode_enabled = true
			label.bbcode_text = str(value)
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.size_flags_vertical = SIZE_EXPAND_FILL
			label.connect("meta_clicked", self, "_label_meta_clicked")
			tab.add_child(label)
		"scene":
			var instance = value.instance()
			if "codex_data" in instance:
				instance.codex_data = codex_data
			tab.add_child(instance)
	tab.visible = false
	return tab


func create_new_move_button() -> Button:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.group = state_button_group
	btn.rect_min_size = Vector2(18, 17)
	btn.rect_size = btn.rect_min_size
	var tex := TextureRect.new()
	btn.add_child(tex)
	tex.anchor_right = 1.0
	tex.anchor_bottom = 1.0
	tex.margin_left = 1
	tex.margin_right = -1
	tex.margin_bottom = -1
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.expand = true
	return btn


func create_new_achievement_button() -> Button:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.group = achievement_button_group
	btn.rect_min_size = Vector2(34, 33)
	btn.rect_size = btn.rect_min_size
	var tex := TextureRect.new()
	btn.add_child(tex)
	tex.anchor_right = 1.0
	tex.anchor_bottom = 1.0
	tex.margin_left = 1
	tex.margin_right = -1
	tex.margin_bottom = -1
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.expand = true
	return btn


func create_move_stat_panel(stat, value):
	var label = Label.new()
	label.size_flags_vertical = SIZE_FILL
	if value is Array:
		value = ", ".join(value)
	label.text = "[" + str(stat) + "] " + str(value)
	if get_theme_default_font().get_string_size(label.text).x > MAX_LABEL_WIDTH:
		label.rect_min_size.x = MAX_LABEL_WIDTH
		label.autowrap = true
	return label



# DEBUG SETTINGS
func _on_debug_setting_changed(setting, value, first_set = false):
	debug_settings[setting] = value
	match setting:
		"DebugAchievementID":
			pass #breakpoint
		"DebugHiddenAchievement":
			update_achievements(achievement_list)
		"DebugLockedAchievement":
			update_achievements(achievement_list)
		"DebugUnlockedAchievement":
			update_achievements(achievement_list)
