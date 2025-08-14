extends Node

# TODO NEXT
signal achievement_unlocked(achievement_list, achievement_id)


var codex_cache = {}
var codex_save_data = {}
var codex_achievements = {}
var codex_has_options = {}

var prefers_more_info = false
var preferred_tab = ""

var fixed = FixedMath.new()

const SAVE_DIR = "user://cloud/codex_char_saves"
const LEGACY_SAVE_DIR = "user://codex_char_saves"
const CODEX_SETTINGS_SAVE_PATH = "user://cloud/codex_settings.json"

onready var BlankCodexScene = load("res://_tri_char_codex/CodexPage.tscn")

func _init():
	var user_dir : Directory = Directory.new()
	user_dir.open("user://")
	if not user_dir.dir_exists("codex_char_saves"):
		user_dir.make_dir("codex_char_saves")
	if not user_dir.dir_exists("cloud"):
		user_dir.make_dir("cloud")
	user_dir = Directory.new()
	user_dir.open("user://cloud/")
	if not user_dir.dir_exists("codex_char_saves"):
		user_dir.make_dir("codex_char_saves")


func _ready():
	name = "CharCodexLibrary"
	var main = get_node_or_null("/root/Main")
	if is_instance_valid(main):
		main.connect("game_started", self, "__on_game_started", [], CONNECT_DEFERRED)


func generate_node(char_path : String):
	if has_cached(char_path):
		return __generate_from_cache(char_path)
	elif can_generate(char_path):
		__analyze_and_cache(char_path)
		return __generate_from_cache(char_path)
	# Cannot anaylze characters that have not been loaded by charloader
	# And since codex will never call this function before trying charloader
	# This usually means charloader failed to load the character
	return __generate_error("Character cannot be loaded!")



func generate_options_node(char_path : String):
	if not can_generate(char_path):
		# Cannot anaylze characters that have not been loaded by charloader
		# And since codex will never call this function before trying charloader
		# This usually means charloader failed to load the character
		return __generate_error("Character cannot be loaded!")
	var options = load("res://_tri_char_codex/components/CharOptionsPage.gd").new()
	var override = __attempt_load_codex_script(char_path)
	if override != null:
		var params = {
			"char_path": char_path,
			"codex_library": self,
		}
		override.callv("setup_options", [options, params])
		if override is Node:
			options.add_child(override)
		elif override.has_method("queue_free"): # TODO don't?
			override.queue_free()
	return options



func has_cached(char_path : String) -> bool:
	return codex_cache.has(char_path)



func can_generate(char_path : String) -> bool:
	return Global.name_paths.values().has(char_path)



func char_has_options(char_path : String) -> bool:
	if codex_has_options.has(char_path):
		return bool(codex_has_options[char_path])
	if not can_generate(char_path):
		var f := File.new()
		var codex_script_file = __get_codex_script_path(char_path)
		if not f.file_exists(codex_script_file):
			return false
		f.open(codex_script_file, File.READ)
		var content = f.get_as_text()
		f.close()
		codex_has_options[char_path] = ("\nfunc setup_options(" in content)
		return codex_has_options[char_path]
	var codex_script = __attempt_load_codex_script(char_path)
	if codex_script == null:
		codex_has_options[char_path] = false
		return false
	var has_options = codex_script.has_method("setup_options")
	if codex_script.has_method("queue_free"):
		codex_script.queue_free()
	codex_has_options[char_path] = has_options
	return has_options


func load_all_char_options(fighter):
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(true):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return {}
	var data = raw_load_char_data(char_path, "_OPTIONS_")
	if data is Dictionary:
		return data
	return {}


func save_all_char_options(fighter, value):
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(true):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	return raw_save_char_data(char_path, "_OPTIONS_", value)


func save_codex_setting(key : String, value):
	return raw_save_char_data("_CODEX_", key, value)


func load_codex_setting(key : String):
	return raw_load_char_data("_CODEX_", key)


func __attempt_load_char_instance(char_path):
	var loader = ResourceLoader.load_interactive(char_path)
	loader.wait()
	var char_scene = loader.get_resource()
	if char_scene == null:
		return null
	if not (char_scene is PackedScene):
		if char_scene.has_method("queue_free"):
			char_scene.queue_free()
		return null
	var char_instance = char_scene.instance()
	if char_instance is Node:
		return char_instance
	if char_instance != null and char_instance.has_method("queue_free"):
		char_instance.queue_free()
	return null


func __attempt_load_codex_script(char_path):
	var codex_script_file = __get_codex_script_path(char_path)
	if not ResourceLoader.exists(codex_script_file):
		return null
	var codex_script = ResourceLoader.load(codex_script_file)
	if codex_script is GDScript:
		return codex_script.new()
	elif codex_script != null and codex_script.has_method("queue_free"):
		codex_script.queue_free()
	return null


func __get_codex_script_path(char_path : String) -> String:
	var mod_dir = char_path.rsplit("/", true, 1)[0]
	return mod_dir + '/Codex.gd'


func __analyze_and_cache(char_path : String):
	var codex_data : CodexData = CodexData.new(char_path)
	codex_data.codex_handler = self
	var char_instance = __attempt_load_char_instance(char_path)
	if char_instance == null:
		codex_data.error = "Unable to load character"
		codex_cache[char_path] = codex_data
		return
	codex_data.character_parsed = char_instance
	codex_data.parse_fighter(char_instance)
	__register_codex_override(codex_data)
	__parse_moveset_visibility(codex_data)
	codex_data.character_parsed = null
	char_instance.queue_free()
	
	codex_cache[char_path] = codex_data



func __register_codex_override(codex_data : CodexData):
	var override = __attempt_load_codex_script(codex_data.char_path)
	if override != null:
		if override.has_method("register"):
			override.callv("register", [codex_data])
		if override.has_method("queue_free"):
			override.queue_free()


static func __parse_instance_moveset(char_instance : Node) -> Dictionary:
	var parsed_moves = {}
	var parsed_stances = ["All", "Normal"]
	var parsed_interrupts = ["GroundedDefense", "AerialDefense", "GroundedGrab", "AerialGrab", "Wait", "Fall", "OffensiveBurst", "InstantCancel"]
	var state_machine = char_instance.get_node_or_null("StateMachine")
	if state_machine != null:
		for state in state_machine.get_children():
			if state is StateInterface:
				var parsed_state = CodexState.new(state)
				if state.interrupt_from_string == "" or (not state.show_in_menu) or (not state.selectable):
					parsed_state.visible = false
				else:
					if state.change_stance_to != "" and not state.change_stance_to in parsed_stances:
						parsed_stances.append(state.change_stance_to)
					for category in Utils.split_lines(state.interrupt_into_string):
						if not parsed_interrupts.has(category):
							parsed_interrupts.append(category)
					for category in Utils.split_lines(state.hit_cancel_into_string):
						if not parsed_interrupts.has(category):
							parsed_interrupts.append(category)
				parsed_moves[state.name] = parsed_state
	parsed_stances.erase("All")
	return { "moves": parsed_moves, "stances": parsed_stances, "interrupt_types": parsed_interrupts }



static func __parse_moveset_visibility(codex_data : CodexData):
	var stances = codex_data.stances.duplicate()
	stances.append("All")
	for move_id in codex_data.moveset:
		var move_data : CodexState = codex_data.moveset[move_id]
		__parse_hitbox_data_visibility(move_data)
		if move_data.visibility_set:
			continue
		if not array_has_any(stances, move_data.stances):
			move_data.visible = false
			continue
		if not array_has_any(codex_data.interrupt_types, move_data.interrupt_types):
			move_data.visible = false
			continue
		move_data.visible = true


static func __parse_hitbox_data_visibility(state : CodexState):
	var unique_hitboxes = []
	for hitbox_id in state.hitbox_data:
		var hitbox = state.hitbox_data[hitbox_id]
		var found_unique = true
		for compared_id in unique_hitboxes:
			var compared = state.hitbox_data[compared_id]
			if hitbox.title != compared.title:
				continue
			if hitbox.color != compared.color:
				continue
			if hitbox.is_grab != compared.is_grab:
				continue
			if hitbox.is_hit_grab != compared.is_hit_grab:
				continue
			if hitbox.is_guard_break != compared.is_guard_break:
				continue
			if hitbox.damage != compared.damage:
				continue
			if hitbox.combo_damage != compared.combo_damage:
				continue
			if hitbox.minimum_damage != compared.minimum_damage:
				continue
			if hitbox.stun != compared.stun:
				continue
			if hitbox.combo_stun != compared.combo_stun:
				continue
			if hitbox.proration != compared.proration:
				continue
			if hitbox.combo_scaling != compared.combo_scaling:
				continue
			if hitbox.knockback != compared.knockback:
				continue
			if hitbox.knockback_x != compared.knockback_x:
				continue
			if hitbox.knockback_y != compared.knockback_y:
				continue
			if hitbox.height != compared.height:
				continue
			if hitbox.plus_frames != compared.plus_frames:
				continue
			if hitbox.start != compared.start:
				continue
			if hitbox.active != compared.active:
				continue
			if hitbox.always_on != compared.always_on:
				continue
			if hitbox.looping != compared.looping:
				continue
			if hitbox.loop_active != compared.loop_active:
				continue
			if hitbox.loop_inactive != compared.loop_inactive:
				continue
			if hitbox.hits_otg != compared.hits_otg:
				continue
			if hitbox.hits_standing != compared.hits_standing:
				continue
			if hitbox.hits_grounded != compared.hits_grounded:
				continue
			if hitbox.hits_aerial != compared.hits_aerial:
				continue
			if hitbox.hits_dizzy != compared.hits_dizzy:
				continue
			if hitbox.hits_projectiles != compared.hits_projectiles:
				continue
			if hitbox.di_modifier != compared.di_modifier:
				continue
			if hitbox.sdi_modifier != compared.sdi_modifier:
				continue
			if hitbox.pushback != compared.pushback:
				continue
			if hitbox.meter_gain_modifier != compared.meter_gain_modifier:
				continue
			if hitbox.followup != compared.followup:
				continue
			found_unique = false
			break
		hitbox.marked_as_duplicate = not found_unique
		if found_unique:
			unique_hitboxes.append(hitbox_id)

static func array_has_any(haystack : Array, needles : Array) -> bool:
	for search in needles:
		if haystack.has(search):
			return true
	return false



static func __parse_state_data(state : StateInterface, char_instance : Node = null) -> CodexState:
	return CodexState.new(state)



static func __parse_state_hitboxes(state : StateInterface, char_instance : Node) -> Dictionary:
	var hitbox_data = {}
	for hitbox in state.get_children():
		if hitbox is Hitbox:
			hitbox_data[hitbox.name] = __parse_hitbox_data(hitbox, char_instance)
	return hitbox_data



static func __parse_hitbox_data(hitbox : Hitbox, char_instance = null) -> CodexHitbox:
	return CodexHitbox.new(hitbox)



static func __parse_is_hit_grab(hitbox, char_instance : Node) -> bool:
	# TODO safeguard against Hitbox overrides
	if hitbox is ThrowBox:
		return false
	if hitbox.followup_state == "":
		return false
	var followup = char_instance.get_node_or_null("StateMachine/" + str(hitbox.followup_state))
	if followup is ThrowState:
		return true
	return false



static func __parse_state_script_source(state_data : CodexState, source_code : String):
	state_data.parse_source_script(source_code)


static func code_keyphrase_test(haystack : String, needle : String) -> bool:
	return CodexState.script_has_keyphrase(haystack, needle)


func __generate_from_cache(char_path : String):
	var cached_data = codex_cache[char_path]
	if cached_data.error != "":
		return __generate_error(cached_data.error)
	var page_node = BlankCodexScene.instance()
	page_node.generate(cached_data)
	var achievement_data = get_achievement_list(char_path)
	page_node.update_achievements(achievement_data)
	if char_has_options(char_path):
		page_node.setup_options(generate_options_node(char_path), load_all_char_options(char_path))
	__page_editor(page_node, char_path)
	return page_node




func __generate_error(text):
	var error_label = Label.new()
	error_label.text = text
	error_label.modulate = Color(1, 0.5, 0.5)
	error_label.align = Label.ALIGN_CENTER
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	error_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	error_label.autowrap = true
	return error_label



# @TODO make sure dictionary and array values are deep duplicated

func load_for_extra(fighter : Node, key = null, default = null, reload = false):
	#if not reload:
	#	fighter
	# @TODO screw it I'll do it later
	if fighter.can_unlock_achievements():
		var result = raw_load_char_data(fighter.filename, key, default)
		return result
	else:
		return default


func raw_load_char_data(char_path : String, key = null, default = null):
	if not codex_save_data.has(char_path):
		init_char_data(char_path)
	var result = default
	if key == null:
		result = codex_save_data[char_path]
	elif codex_save_data[char_path].has(key):
		result = codex_save_data[char_path][key]
	if result is Dictionary or result is Array:
		return result.duplicate(true)
	elif result is Object:
		return null
	return result


func raw_save_char_data(char_path : String, key, value):
	if not codex_save_data.has(char_path):
		init_char_data(char_path)
	if key == null:
		if value is Dictionary:
			codex_save_data[char_path] = value.duplicate(true)
	else:
		if value is Dictionary or value is Array:
			codex_save_data[char_path][key] = value.duplicate(true)
		elif not value is Object:
			codex_save_data[char_path][key] = value
	# @TODO save later rather than now to avoid corruption and lag
	var save_file : File = File.new()
	save_file.open(get_save_file_path(char_path), File.WRITE)
	save_file.store_string(JSON.print(codex_save_data[char_path], "\t"))
	save_file.close()
	return true


func init_char_data(char_path : String):
	var save_file : File = File.new()
	var data = null
	var file_text = null
	var file_path = get_save_file_path(char_path)
	if save_file.file_exists(file_path):
		save_file.open(file_path, File.READ)
		file_text = save_file.get_as_text()
		save_file.close()
	else:
		file_path = get_legacy_save_file_path(char_path)
		if save_file.file_exists(file_path):
			save_file.open(file_path, File.READ)
			file_text = save_file.get_as_text()
			save_file.close()
	if file_text != null:
		var json_parse : JSONParseResult = JSON.parse(file_text)
		if not json_parse.error:
			if json_parse.result is Dictionary:
				data = json_parse.result
		else:
			if OS.is_debug_build():
				print(json_parse.error_string)
	codex_save_data[char_path] = data if data is Dictionary else get_new_char_data(char_path)


func raw_reset_char_data(char_path : String):
	codex_save_data[char_path] = get_new_char_data(char_path)


func get_new_char_data(char_path : String):
	if char_path == "_CODEX_":
		return {
			"misclick_prevent": false
		}
	var new_save = null
	var override = __attempt_load_codex_script(char_path)
	if override != null:
		if override.has_method("new_save"):
			new_save = override.callv("new_save", [])
		if override.has_method("queue_free"):
			override.queue_free()
	if new_save is Dictionary:
		return new_save
	else:
		return {}


func get_save_file_path(char_path : String) -> String:
	if char_path == "_CODEX_":
		return CODEX_SETTINGS_SAVE_PATH
	var char_name = char_path.rsplit("/", true, 1)
	if char_name.size() < 2:
		char_name = ""
	else:
		char_name = char_name[1].split(".", true, 1)
		if char_name.size() == 0:
			char_name = ""
		else:
			char_name = char_name[0]
	return SAVE_DIR + "/" + ("%X" % char_path.hash()) + "_" + char_name + ".json"

func get_legacy_save_file_path(char_path : String) -> String:
	if char_path == "_CODEX_":
		return CODEX_SETTINGS_SAVE_PATH
	return LEGACY_SAVE_DIR + "/" + ("%X" % char_path.hash()) + ".json"





func __cache_achievement_list(char_path : String):
	var chievo_list = CodexAchievementList.new()
	var override = __attempt_load_codex_script(char_path)
	if override != null:
		if override.has_method("setup_achievements"):
			override.callv("setup_achievements", [chievo_list])
		if override.has_method("setup_advanced_achievements"):
			var char_instance = __attempt_load_char_instance(char_path)
			var params = {
				"char_path": char_path,
				"character": char_instance,
				"codex_library": self,
			}
			override.callv("setup_advanced_achievements", [chievo_list, params])
			if char_instance != null and char_instance.has_method("queue_free"):
				char_instance.queue_free()
		if override.has_method("queue_free"):
			override.queue_free()
	codex_achievements[char_path] = chievo_list


func get_achievement_list(char_path : String) -> CodexAchievementList:
	if not codex_achievements.has(char_path):
		__cache_achievement_list(char_path)
	if not codex_achievements[char_path] is CodexAchievementList:
		return CodexAchievementList.new() # error case
	var save_data = raw_load_char_data(char_path, "_ACHIEVEMENTS_")
	if save_data is Dictionary:
		for item in save_data:
			if (item is String) and (save_data[item] is bool):
				codex_achievements[char_path].mark_unlocked(item, save_data[item])
	var counter_data = raw_load_char_data(char_path, "_COUNTERS_")
	if counter_data is Dictionary:
		for item in counter_data:
			if (item is String) and (counter_data[item] is int or counter_data[item] is float):
				codex_achievements[char_path].set_counter_value(item, int(counter_data[item]))
	# @TODO update achievements?
	return codex_achievements[char_path]


func unlock_achievement(fighter, achievement_id : String, multiplayer_only = false) -> bool:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(not multiplayer_only):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	var list = get_achievement_list(char_path)
	if not list.achievements.has(achievement_id):
		return false
	if list.is_unlocked(achievement_id):
		return false
	var save_data = raw_load_char_data(char_path, "_ACHIEVEMENTS_")
	if not (save_data is Dictionary):
		save_data = {}
	save_data[achievement_id] = true
	raw_save_char_data(char_path, "_ACHIEVEMENTS_", save_data)
	list.mark_unlocked(achievement_id)
	emit_signal("achievement_unlocked", list, achievement_id)
	return true


func relock_achievement(fighter, achievement_id : String, multiplayer_only = false) -> bool:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(not multiplayer_only):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	var list = get_achievement_list(char_path)
	if not list.achievements.has(achievement_id):
		return false
	var save_data = raw_load_char_data(char_path, "_ACHIEVEMENTS_")
	if not (save_data is Dictionary):
		save_data = {}
	save_data[achievement_id] = false
	raw_save_char_data(char_path, "_ACHIEVEMENTS_", save_data)
	list.mark_unlocked(achievement_id, false)
	return true


func is_achievement_unlocked(fighter, achievement_id : String) -> bool:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements():
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	var list = get_achievement_list(char_path)
	return list.is_unlocked(achievement_id)


func is_achievement_array_unlocked(fighter, achievements : Array) -> bool:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements():
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	var list = get_achievement_list(char_path)
	return list.is_array_unlocked(achievements)


func achievement_target_met(fighter, achievement_id) -> bool:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements():
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return false
	var list = get_achievement_list(char_path)
	return list.is_target_met(achievement_id)


func get_unlocked_achievements(fighter) -> Array:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements():
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return []
	var list = get_achievement_list(char_path)
	return list.get_unlocked_array()


func increment_counter(fighter, counter_id : String, by_amount : int = 1, multiplayer_only = false) -> int:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(not multiplayer_only):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return -1
	var list = get_achievement_list(char_path)
	var save_data = raw_load_char_data(char_path, "_COUNTERS_")
	if not (save_data is Dictionary):
		save_data = {}
	var count = list.get_counter_value(counter_id)
	count = count + by_amount
	save_data[counter_id] = count
	raw_save_char_data(char_path, "_COUNTERS_", save_data)
	list.set_counter_value(counter_id, count)
	return count


func set_counter(fighter, counter_id : String, to_amount : int = 1, multiplayer_only = false) -> int:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements() and fighter.is_you(not multiplayer_only):
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return -1
	var list = get_achievement_list(char_path)
	var save_data = raw_load_char_data(char_path, "_COUNTERS_")
	if not (save_data is Dictionary):
		save_data = {}
	save_data[counter_id] = to_amount
	raw_save_char_data(char_path, "_COUNTERS_", save_data)
	list.set_counter_value(counter_id, to_amount)
	return to_amount


func get_counter(fighter, counter_id : String) -> int:
	var char_path = ""
	if fighter is Node:
		if fighter.can_unlock_achievements():
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return -1
	var list = get_achievement_list(char_path)
	return list.get_counter_value(counter_id)


func __modify_style_data(char_path, style_data):
	# TODO don't force style_data to be a dictionary?
	var override = __attempt_load_codex_script(char_path)
	if override != null:
		if override.has_method("modify_style_data"):
			if not style_data is Dictionary:
				style_data = {}
			var new_style_data = style_data.duplicate(true)
			var params = {
				"char_path": char_path,
				"codex_library": self,
			}
			override.callv("modify_style_data", [new_style_data, params])
			if new_style_data is Dictionary:
				if new_style_data.empty():
					return null
				if not new_style_data.has("character_color"): new_style_data.character_color = null # TODO check type
				if not new_style_data.has("outline_color"): new_style_data.outline_color = null # TODO check type
				if not new_style_data.has("use_outline"): new_style_data.use_outline = false # TODO check type
				if not new_style_data.has("show_aura"): new_style_data.show_aura = false # TODO check type
				if not new_style_data.has("style_name"): new_style_data.style_name = "" # TODO check type
				style_data = new_style_data
		if override.has_method("queue_free"):
			override.queue_free()
	return style_data


func track_win(fighter):
	var char_path = ""
	if fighter is Node:
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return
	var all_wins = load_codex_setting("wins")
	if not (all_wins is Dictionary):
		all_wins = {}
	var count = all_wins.get(char_path, 0)
	if not (count is int or count is float):
		count = 0
	all_wins[char_path] = count + 1
	save_codex_setting("wins", all_wins)

func track_loss(fighter):
	var char_path = ""
	if fighter is Node:
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return
	var all_losses = load_codex_setting("losses")
	if not (all_losses is Dictionary):
		all_losses = {}
	var count = all_losses.get(char_path, 0)
	if not (count is int or count is float):
		count = 0
	all_losses[char_path] = count + 1
	save_codex_setting("losses", all_losses)


func num_wins(fighter) -> int:
	var char_path = ""
	if fighter is Node:
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return 0
	var all_wins = load_codex_setting("wins")
	if not (all_wins is Dictionary):
		return 0
	var count = all_wins.get(char_path, 0)
	if not (count is int or count is float):
		return 0
	return count


func num_losses(fighter) -> int:
	var char_path = ""
	if fighter is Node:
			char_path = fighter.filename
	elif fighter is String:
		char_path = fighter
	if char_path == "":
		return 0
	var all_losses = load_codex_setting("losses")
	if not (all_losses is Dictionary):
		return 0
	var count = all_losses.get(char_path, 0)
	if not (count is int or count is float):
		return 0
	return count

func __on_game_started():
	var game = Global.current_game
	if is_instance_valid(game):
		game.connect("game_won", self, "__on_game_won", [game])
		game.connect("forfeit_started", self, "__on_game_forfeit", [game])


func __on_game_won(winner, game):
	if not is_instance_valid(game):
		return
	if not Network.multiplayer_active:
		return
	if ReplayManager.playback or ReplayManager.replaying_ingame:
		return
	if SteamLobby.SPECTATING:
		return 
	if winner == Network.player_id:
		track_win(game.get_player(winner))
	else:
		track_loss(game.get_player(1 if winner == 2 else 2))


func __on_game_forfeit(loser, game):
	__on_game_won(2 if loser == 1 else 1, game)



#class PageInfo extends Reference:
#
#	var BGColor = Color("141414")
#
#	func _init(char_path : String):
#		self.char_path = char_path
#
#	func set_background(color = null, tex = null):
#		if tex == null:
#			var Box = StyleBoxFlat.new()
#			Box.bg_color = Color(color)
#		else:
#			var Box = StyleBoxTexture.new()
#			Box.texture = tex
#		#.add_theme_stylebox_override
#		pass




class CodexData extends Reference:
	
	var char_path : String = ""
	var banner : Texture = null
	var banner_offset : Vector2 = Vector2(32, 32)
	var banner_scale : Vector2 = Vector2(1, 1)
	var banner_rotation : float = 0
	var title : String = "" setget set_title, get_title
	var subtitle : String = "" setget set_subtitle, get_subtitle
	var summary : String = "" setget set_summary, get_summary
	var moveset : Dictionary = {}
	var stances : Array = []
	var tags : Array = []
	var interrupt_types : Array = []
	var custom_tabs : Array = []
	var stats : CodexStats = null
	var has_no_moveset = false
	var has_no_stats = false
	
	var character_parsed = null
	
	var error : String = ""
	
	var codex_handler : Node = null
	
	
	func _init(char_path : String):
		self.char_path = char_path
		self.stats = CodexStats.new()
	
	
	func parse_fighter(char_instance : Node):
		if "__" in char_instance.name:
			title = char_instance.name.split("__", true, 1)[1]
		else:
			title = char_instance.name
		if char_instance.get("character_portrait2") is Texture:
			banner = char_instance.character_portrait2
		elif char_instance.get("character_portrait") is Texture:
			banner = char_instance.character_portrait
		var parsed = codex_handler.__parse_instance_moveset(char_instance)
		moveset = parsed.moves
		stances = parsed.stances
		interrupt_types = parsed.interrupt_types
		stats.parse_fighter(char_instance)
	
	
	func set_title(value : String):
		title = value
	
	func get_title() -> String:
		return title
	
	func set_summary(value : String):
		summary = value
	
	func get_summary() -> String:
		return summary
	
	func set_subtitle(value : String):
		subtitle = value
	
	func get_subtitle() -> String:
		return subtitle
	
	
	func add_custom_text_tab(tab_title : String, text : String):
		custom_tabs.append({
			"title": tab_title,
			"type": "text",
			"value": text,
		})
	
	
	func add_custom_scene_tab(tab_title : String, scene):
		if scene is String:
			if not ResourceLoader.exists(scene):
				if OS.is_debug_build():
					printerr("CODEX ERROR: failed to add tab ", tab_title,", ", scene ," does not exist!")
				return null
			scene = load(scene)
		if not (scene is PackedScene):
			if OS.is_debug_build():
				printerr("CODEX ERROR: failed to add tab ", tab_title,", ", scene ," is not a scene!")
			return null
		custom_tabs.append({
			"title": tab_title,
			"type": "scene",
			"value": scene,
		})
	
	
	func define_state(name : String, data, force_new : bool = false):
		var state = null
		if not force_new:
			state = moveset.get(name, null)
		if state == null:
			state = CodexState.new()
		state.define(data)
		moveset[name] = state
	
	
	func tag_moves(tag : String, moves):
		if not tag in tags:
			tags.append(tag)
		if moves is String:
			moves = [moves]
		if not moves is Array:
			return
		for entry in moves:
			if not entry is String:
				continue
			var codex_move = moveset.get(entry, null)
			if not codex_move is CodexState:
				continue
			if not tag in codex_move.tags:
				codex_move.tags.append(tag)
	
	
	func load_char_data(key = null, default = null):
		return codex_handler.raw_load_char_data(char_path, key, default)
	
	
	func save_char_data(key = null, value = null):
		return codex_handler.raw_save_char_data(char_path, key, value)
	
	
	func reset_char_data():
		return codex_handler.raw_reset_char_data(char_path)
	
	
	# @TODO Move Corrections
	# @TODO Move Hitbox Corrections
	# @TODO Move Hurtbox Corrections
	# @TODO Move Projectile Corrections








class CodexStats extends Reference:
	
	var max_health : int = 1000
	var air_options : int = 2
	var lose_option_in_neutral : bool = true
	var air_option_bar : bool = false
	var air_option_name : String = "Air Options"
	var free_cancels : int = 2
	var damage_taken : float = 1.0
	var knockback_taken : float = 1.0
	var di_strength : float = 1.0
	var gravity : float = 0.5
	var friction_ground : float = 2.5
	var friction_air : float = 0.2
	var max_speed_ground : float = 15.0
	var max_speed_air : float = 13.0
	var max_speed_fall : float = 8.0
	var hurtbox_x : int = 0
	var hurtbox_y : int = -16
	var hurtbox_width : int = 14
	var hurtbox_height : int = 16
	var sprite_position : Vector2 = Vector2()
	var sprite_scale : Vector2 = Vector2()
	var sprite_texture : Texture = null
	# @NOTE_TO_SELF: remember to add new variables to copy_to() and parse_dictionary()
	
	
	func _init(data = null):
		define(data)
	
	
	func define(data = null):
		if data is Node:
			parse_fighter(data)
		if data is CodexStats:
			data.copy_to(self)
		if data is Dictionary:
			parse_dictionary(data)
	
	
	func duplicate() -> CodexStats:
		var copy = CodexStats.new()
		copy_to(copy)
		return copy
	
	
	func copy_to(copy):
		copy.max_health = max_health
		copy.air_options = air_options
		copy.lose_option_in_neutral = lose_option_in_neutral
		copy.air_option_bar = air_option_bar
		copy.air_option_name = air_option_name
		copy.free_cancels = free_cancels
		copy.damage_taken = damage_taken
		copy.knockback_taken = knockback_taken
		copy.di_strength = di_strength
		copy.gravity = gravity
		copy.friction_ground = friction_ground
		copy.friction_air = friction_air
		copy.max_speed_ground = max_speed_ground
		copy.max_speed_air = max_speed_air
		copy.max_speed_fall = max_speed_fall
		copy.hurtbox_x = hurtbox_x
		copy.hurtbox_y = hurtbox_y
		copy.hurtbox_width = hurtbox_width
		copy.hurtbox_height = hurtbox_height
		copy.sprite_position = sprite_position
		copy.sprite_scale = sprite_scale
		copy.sprite_texture = sprite_texture.duplicate()
	
	
	func parse_fighter(char_instance : Node):
		if "MAX_HEALTH" in char_instance:
			max_health = int(char_instance.MAX_HEALTH)
		if "num_air_movements" in char_instance:
			air_options = int(char_instance.num_air_movements)
		if "lose_one_air_option_in_neutral" in char_instance:
			lose_option_in_neutral = bool(char_instance.lose_one_air_option_in_neutral)
		if "use_air_option_bar" in char_instance:
			air_option_bar = bool(char_instance.use_air_option_bar)
		if "air_option_bar_name" in char_instance:
			air_option_name = char_instance.air_option_bar_name
		if "num_feints" in char_instance:
			free_cancels = int(char_instance.num_feints)
		if "damage_taken_modifier" in char_instance:
			damage_taken = float(char_instance.damage_taken_modifier)
		if "knockback_taken_modifier" in char_instance:
			knockback_taken = float(char_instance.knockback_taken_modifier)
		if "di_modifier" in char_instance:
			di_strength = float(char_instance.di_modifier)
		if "gravity" in char_instance:
			gravity = float(char_instance.gravity)
		if "ground_friction" in char_instance:
			friction_ground = float(char_instance.ground_friction)
		if "air_friction" in char_instance:
			friction_air = float(char_instance.air_friction)
		if "max_ground_speed" in char_instance:
			max_speed_ground = float(char_instance.max_ground_speed)
		if "max_air_speed" in char_instance:
			max_speed_air = float(char_instance.max_air_speed)
		if "max_fall_speed" in char_instance:
			max_speed_fall = float(char_instance.max_fall_speed)
		var hurtbox = char_instance.get_node_or_null("Hurtbox")
		if hurtbox != null:
			hurtbox_x = hurtbox.x
			hurtbox_y = hurtbox.y
			hurtbox_width = hurtbox.width
			hurtbox_height = hurtbox.height
		var sprite = char_instance.get_node_or_null("Flip/Sprite")
		if sprite != null:
			sprite_position = sprite.position + sprite.offset
			sprite_scale = sprite.scale
			sprite_texture = sprite.frames.get_frame("Wait", 0)
		
		var script = char_instance.get_script()
		if not script.resource_path.begins_with("res://characters/"):
			var search_start = script.source_code.find("\nfunc init(")
			if search_start >= 0:
				search_start += 11
				var search_end = script.source_code.find("\nfunc", search_start)
				var search_string = script.source_code.substr(search_start, search_end - search_start)
				var regex := RegEx.new()
				regex.compile("\\tMAX_HEALTH\\s*=\\s*([0-9]+)")
				var result := regex.search(search_string)
				if result != null:
					max_health = int(result.get_string(1))
		# @TODO get from Wait anim name
		# @TODO make sure animation exists
	
	
	func parse_dictionary(data : Dictionary):
		var expected_keys = {
			"max_health" : "int",
			"air_options" : "int",
			"lose_option_in_neutral" : "bool",
			"air_option_bar" : "bool",
			"air_option_name" : "String",
			"free_cancels" : "int",
			"damage_taken" : "float",
			"knockback_taken" : "float",
			"di_strength" : "float",
			"gravity" : "float",
			"friction_ground" : "float",
			"friction_air" : "float",
			"max_speed_ground" : "float",
			"max_speed_air" : "float",
			"max_speed_fall" : "float",
			"hurtbox_x" : "int",
			"hurtbox_y" : "int",
			"hurtbox_width" : "int",
			"hurtbox_height" : "int",
			"sprite_position" : "Vector2",
			"sprite_scale" : "Vector2",
			"sprite_texture" : "Texture",
		}
		for key in expected_keys:
			var type = expected_keys[key]
			var input = data.get(key)
			match type:
				"int":
					if input is int or input is float or input is String:
						set(key, int(input))
				"float":
					if input is int or input is float or input is String:
						set(key, float(input))
				"bool":
					if input != null:
						set(key, bool(input))
				"String":
					if input != null:
						set(key, str(input))
				"Vector2":
					if input is Vector2:
						set(key, input)
					elif input is Dictionary:
						if input.has("x") and input.has("y"):
							set(key, Vector2(float(input.x), float(input.y)))
					elif input is Array:
						if input.size >= 2:
							set(key, Vector2(float(input[0]), float(input[1])))
				"Texture":
					if input is Texture:
						set(key, input.duplicate())








class CodexState extends Reference:
	
	var icon : Texture = null
	var title : String = ""
	var desc : String = ""
	var visible : bool = true setget set_visible, get_visible
	var visibility_set : bool = false
	var type : String = ""
	var air_type : String = ""
	var length : int = -1
	var endless : bool = false
	var iasa : int = -1
	var anim_name : String = ""
	var interrupt_types : Array = []
	var stances : Array = []
	var tags : Array = []
	var change_stance : String = ""
	var super_req : int = 0
	var super_cost : int = 0
	var hitbox_data : Dictionary = {}
	var tick_data : Dictionary = {}
	var custom_stats : Dictionary = {}
	# @NOTE_TO_SELF: remember to add new variables to copy_to() and define()
	
	
	func _init(state = null):
		if state != null:
			define(state)
	
	
	func define(data = null):
		if data is StateInterface:
			parse_state(data)
		if data is CodexState:
			data.copy_to(self)
		if data is Dictionary:
			parse_dictionary(data)
	
	
	func duplicate() -> CodexState:
		var copy = CodexState.new()
		copy_to(copy)
		return copy
	
	
	func copy_to(copy):
		copy.icon = icon.duplicate()
		copy.title = title
		copy.desc = desc
		copy.visible = visible
		copy.visibility_set = visibility_set
		copy.type = type
		copy.air_type = air_type
		copy.length = length
		copy.endless = endless
		copy.iasa = iasa
		copy.anim_name = anim_name
		copy.interrupt_types = interrupt_types.duplicate()
		copy.stances = stances.duplicate()
		copy.tags = tags.duplicate()
		copy.change_stance = change_stance
		copy.super_req = super_req
		copy.super_cost = super_cost
		copy.hitbox_data = duplicate_all_hitbox_data()
		copy.tick_data = tick_data.duplicate(true)
		copy.custom_stats = custom_stats.duplicate(true)
	
	
	func duplicate_all_hitbox_data() -> Dictionary:
		var copy = {}
		for hitbox in hitbox_data:
			copy[hitbox] = hitbox_data[hitbox].duplicate()
		return copy
	
	
	func parse_state(state : StateInterface):
		title = state.title if state.title != "" else state.name
		if state.get("button_texture") is Texture:
			icon = state.button_texture
		if state.get("type") is int:
			type = CharacterState.ActionType.keys()[state.type % CharacterState.ActionType.keys().size()]
		if state.get("air_type") is int:
			air_type = CharacterState.AirType.keys()[state.air_type % CharacterState.AirType.keys().size()]
		if state.get("endless") is bool:
			endless = state.endless
		var parsed_anim_length : int = 0 if not state.get("anim_length") is int else state.anim_length
		var parsed_iasa_at : int = -1 if not state.get("iasa_at") is int else state.iasa_at
		var is_next_state_on_hold = state.get("next_state_on_hold")
		var first_iasa
		# i hate my life
		length = -1 if endless else parsed_anim_length
		iasa = parsed_iasa_at
		var true_iasa = iasa if iasa >= 0 else parsed_anim_length + iasa if not endless else -1
		if is_next_state_on_hold and length > true_iasa+1:
			length = true_iasa+1
		var parsed_sprite_animation : String = "" if not state.get("sprite_animation") is String else state.sprite_animation
		anim_name = state.name if parsed_sprite_animation == "" else parsed_sprite_animation
		if state.get("interrupt_from_string") is String:
			interrupt_types = Utils.split_lines(state.interrupt_from_string)
		if state.get("allowed_stances_string") is String:
			stances = Utils.split_lines(state.allowed_stances_string)
		if state.get("change_stance_to") is String:
			change_stance = state.change_stance_to
		if state is SuperMove:
			super_req = state.super_level
			super_cost = state.supers_used
		else:
			if state.get("super_level_") is int:
				super_req = state.super_level_
			if state.get("supers_used_") is int:
				super_cost = state.supers_used_
		if state.get("interrupt_frames") is Array:
			for frame in state.interrupt_frames:
				if is_next_state_on_hold and length > frame+1:
					length = frame+1
				set_interrupt_tick(frame)
		if state.get("projectile_scene") is PackedScene and state.get("projectile_tick") is int:
			if state.projectile_scene != null:
				set_projectile_tick(state.projectile_tick)
		hitbox_data = {}
		for hitbox in state.get_children():
			if hitbox is Hitbox:
				hitbox_data[hitbox.name] = CodexHitbox.new(hitbox)
		var script = state.get_script()
		if script != null:
			if not script.resource_path.begins_with("res://characters/"):
				parse_source_script(script.source_code)
			else:
				apply_known_script(script.resource_path, state)
		# @TODO iasa on hit?
		# @TODO interruptable on opponent turn?
		# @TODO combo only?
		# @TODO neutral only?
		# @TODO list interrupt and cancel intos?
	
	
	func parse_dictionary(data : Dictionary):
		var expected_keys = {
			"icon" : "Texture",
			"title" : "String",
			"desc" : "String",
			"visible" : "bool",
			"visibility_set" : "bool",
			"type" : "String",
			"air_type" : "String",
			"length" : "int",
			"endless" : "bool",
			"iasa" : "int",
			"anim_name" : "String",
			"interrupt_types" : "Array",
			"stances" : "Array",
			"tags" : "Array",
			"change_stance" : "String",
			"super_req" : "int",
			"super_cost" : "int",
			"hitbox_data" : "hitbox_data",
			#"tick_data" : "tick_data",
		}
		for key in expected_keys:
			var type = expected_keys[key]
			var input = data.get(key)
			match type:
				"int":
					if input is int or input is float or input is String:
						set(key, int(input))
				"float":
					if input is int or input is float or input is String:
						set(key, float(input))
				"bool":
					if input != null:
						set(key, bool(input))
				"String":
					if input != null:
						set(key, str(input))
				"Array":
					if input is Array:
						set(key, input.duplicate())
				"Texture":
					if input is Texture:
						set(key, input.duplicate())
				"hitbox_data":
					if input is Dictionary:
						for box_name in input:
							define_hitbox(str(box_name), input[box_name])
					elif input is Array:
						var count = 0
						for box_name in input:
							while hitbox_data.has(str(count)):
								count += 1
							define_hitbox(str(count), input[box_name])
				# @TODO tick_data. I'll figure this out how this should work later :/
	
	
	func define_hitbox(name : String, data, force_new : bool = false):
		var hitbox = null
		if not force_new:
			hitbox = hitbox_data.get(name, null)
		if hitbox == null:
			hitbox = CodexHitbox.new()
		hitbox.define(data)
		hitbox_data[name] = hitbox
	
	
	func set_visible(value : bool):
		visible = value
		visibility_set = true
	
	func get_visible() -> bool:
		return visible
	
	
	func set_interrupt_tick(tick : int): set_tick_item(tick, "Interrupt")
	func unset_interrupt_tick(tick : int): unset_tick_item(tick, "Interrupt")
	
	func set_projectile_tick(tick : int): set_tick_item(tick, "Projectile")
	func unset_projectile_tick(tick : int): unset_tick_item(tick, "Projectile")
	
	func set_start_armor_tick(tick : int): set_tick_item(tick, "Start Armor")
	func unset_start_armor_tick(tick : int): unset_tick_item(tick, "Start Armor")
	func set_end_armor_tick(tick : int): set_tick_item(tick, "End Armor")
	func unset_end_armor_tick(tick : int): unset_tick_item(tick, "End Armor")
	
	func set_start_invulnerability_tick(tick : int): set_tick_item(tick, "Start Invulnerability")
	func unset_start_invulnerability_tick(tick : int): unset_tick_item(tick, "Start Invulnerability")
	func set_end_invulnerability_tick(tick : int): set_tick_item(tick, "End Invulnerability")
	func unset_end_invulnerability_tick(tick : int): unset_tick_item(tick, "End Invulnerability")
	
	func set_start_projectile_invuln_tick(tick : int): set_tick_item(tick, "Start Projectile Invuln.")
	func unset_start_projectile_invuln_tick(tick : int): unset_tick_item(tick, "Start Projectile Invuln.")
	func set_end_projectile_invuln_tick(tick : int): set_tick_item(tick, "End Projectile Invuln.")
	func unset_end_projectile_invuln_tick(tick : int): unset_tick_item(tick, "End Projectile Invuln.")
	
	func set_start_grab_invuln_tick(tick : int): set_tick_item(tick, "Start Grab Invuln.")
	func unset_start_grab_invuln_tick(tick : int): unset_tick_item(tick, "Start Grab Invuln.")
	func set_end_grab_invuln_tick(tick : int): set_tick_item(tick, "End Grab Invuln.")
	func unset_end_grab_invuln_tick(tick : int): unset_tick_item(tick, "End Grab Invuln.")
	
	func set_start_aerial_invuln_tick(tick : int): set_tick_item(tick, "Start Aerial Invuln.")
	func unset_start_aerial_invuln_tick(tick : int): unset_tick_item(tick, "Start Aerial Invuln.")
	func set_end_aerial_invuln_tick(tick : int): set_tick_item(tick, "End Aerial Invuln.")
	func unset_end_aerial_invuln_tick(tick : int): unset_tick_item(tick, "End Aerial Invuln.")
	
	func set_start_grounded_invuln_tick(tick : int): set_tick_item(tick, "Start Grounded Invuln.")
	func unset_start_grounded_invuln_tick(tick : int): unset_tick_item(tick, "Start Grounded Invuln.")
	func set_end_grounded_invuln_tick(tick : int): set_tick_item(tick, "End Grounded Invuln.")
	func unset_end_grounded_invuln_tick(tick : int): unset_tick_item(tick, "End Grounded Invuln.")
	
	func set_gimmick_tick(tick : int, text : String): set_tick_item(tick, "_" + text)
	func unset_gimmick_tick(tick : int, text : String): set_tick_item(tick, "_" + text)
	
	func set_gimmick_tick_range(start : int, end : int, text : String):
		if start > end:
			var temp = start
			start = end
			end = temp
		for i in end + 1 - start:
			set_gimmick_tick(start + i, text)
	
	
	func set_tick_item(tick : int, type : String):
		if not tick_data.has(tick):
			tick_data[tick] = []
		if not tick_data.has(type):
			tick_data[tick].append(type)
	
	func unset_tick_item(tick : int, type : String):
		if tick_data.has(tick):
			tick_data[tick].erase(type)
	
	
	func parse_source_script(source_code : String):
		var text_blocks = source_code.split("\nfunc ", false)
		var first = true
		for block in text_blocks:
			if first:
				first = false
				continue
			if not block.begins_with("_frame_"):
				continue
			var frame_number = block.substr(7, block.find("(")).to_int()
			if script_has_keyphrase(block, "host.start_invulnerability"):
				set_start_invulnerability_tick(frame_number)
			if script_has_keyphrase(block, "host.start_throw_invulnerability"):
				set_start_grab_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.start_projectile_invulnerability"):
				set_start_projectile_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.start_aerial_attack_invulnerability"):
				set_start_aerial_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.start_grounded_attack_invulnerability"):
				set_start_grounded_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.end_invulnerability"):
				set_end_invulnerability_tick(frame_number)
			if script_has_keyphrase(block, "host.end_throw_invulnerability"):
				set_end_grab_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.end_projectile_invulnerability"):
				set_end_projectile_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.end_aerial_attack_invulnerability"):
				set_end_aerial_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.end_grounded_attack_invulnerability"):
				set_end_grounded_invuln_tick(frame_number)
			if script_has_keyphrase(block, "host.has_hyper_armor = true"):
				set_start_armor_tick(frame_number)
			if script_has_keyphrase(block, "host.has_hyper_armor = false"):
				set_end_armor_tick(frame_number)
			if script_has_keyphrase(block, "host.spawn_object"):
				set_projectile_tick(frame_number)
	
	
	func apply_known_script(path : String, state):
		if path == "res://characters/states/Jump.gd":
			if "super_jump" in state and state.super_jump:
				length = 13
				tick_data = {}
		if path == "res://characters/states/ChargeDash.gd":
			length = 22
			endless = false
			# TODO append followup state instead of hard coded 22
	
	
	static func script_has_keyphrase(haystack : String, needle : String) -> bool:
		var index = 0
		var last_index = 0
		while index != -1:
			index = haystack.find(needle, index)
			if index == -1:
				return false
			var start_of_line = haystack.substr(last_index, index-last_index).find_last("\n")
			if not "#" in haystack.substr(start_of_line, index-start_of_line):
				return true
			last_index = index
			index += 1
		return false








class CodexHitbox extends Reference:
	
	var title : String = ""
	var color : Color = Color(0,0,0,0)
	var is_grab : bool = false
	var is_hit_grab : bool = false
	var is_guard_break : bool = false
	var damage : int = 0
	var combo_damage : int = -1
	var minimum_damage : int = 0
	var stun : int = 0
	var combo_stun : int = -1
	var proration : int = 0
	var combo_scaling : int = 0
	var knockback : float = 0.0
	var knockback_x : float = 0.0
	var knockback_y : float = 0.0
	var height : String = "Mid"
	var plus_frames : int = 0
	var start : int = 0
	var active : int = 0
	var always_on : bool = false
	var looping : bool = false
	var loop_active : int = 0
	var loop_inactive : int = 0
	var hits_otg : bool = false
	var hits_standing : bool = false
	var hits_grounded : bool = false
	var hits_aerial : bool = false
	var hits_dizzy : bool = false
	var hits_projectiles : bool = false
	var di_modifier : float = 0.0
	var sdi_modifier : float = 0.0
	var pushback : float = 0.0
	var meter_gain_modifier : float = 0.0
	var followup : String = ""
	var marked_as_duplicate : bool = false
	var knockdown : bool = false
	var knockdown_extends_hitstun : bool = false
	var hard_knockdown : bool = false
	var ground_bounce : bool = false
	var air_ground_bounce : bool = false
	# @NOTE_TO_SELF: remember to add new variables to copy_to() and define()
	
	
	func _init(hitbox = null):
		if hitbox != null:
			define(hitbox)
	
	
	func define(data):
		if data is Hitbox:
			parse_hitbox(data)
		if data is CodexHitbox:
			data.copy_to(self)
		if data is Dictionary:
			parse_dictionary(data)
	
	
	func duplicate() -> CodexHitbox:
		var copy = CodexHitbox.new()
		copy_to(copy)
		return copy
	
	
	func copy_to(copy):
		copy.title = title
		copy.color = color
		copy.is_grab = is_grab
		copy.is_hit_grab = is_hit_grab
		copy.is_guard_break = is_guard_break
		copy.damage = damage
		copy.combo_damage = combo_damage
		copy.minimum_damage = minimum_damage
		copy.stun = stun
		copy.combo_stun = combo_stun
		copy.proration = proration
		copy.combo_scaling = combo_scaling
		copy.knockback = knockback
		copy.knockback_x = knockback_x
		copy.knockback_y = knockback_y
		copy.height = height
		copy.plus_frames = plus_frames
		copy.start = start
		copy.active = active
		copy.always_on = always_on
		copy.looping = looping
		copy.loop_active = loop_active
		copy.loop_inactive = loop_inactive
		copy.hits_otg = hits_otg
		copy.hits_standing = hits_standing
		copy.hits_grounded = hits_grounded
		copy.hits_aerial = hits_aerial
		copy.hits_dizzy = hits_dizzy
		copy.hits_projectiles = hits_projectiles
		copy.di_modifier = di_modifier
		copy.sdi_modifier = sdi_modifier
		copy.pushback = pushback
		copy.meter_gain_modifier = meter_gain_modifier
		copy.followup = followup
		copy.marked_as_duplicate = marked_as_duplicate
		copy.knockdown = knockdown
		copy.knockdown_extends_hitstun = knockdown_extends_hitstun
		copy.hard_knockdown = hard_knockdown
		copy.ground_bounce = ground_bounce
		copy.air_ground_bounce = air_ground_bounce
	
	
	func parse_hitbox(hitbox):
		# TODO safeguard against Hitbox overrides
		is_grab = hitbox is ThrowBox
		if not is_grab:
			if hitbox.followup_state != "":
				var state_machine = hitbox.find_parent("StateMachine")
				if state_machine != null:
					var followup_state = state_machine.get_node_or_null(str(hitbox.followup_state))
					if followup_state is ThrowState:
						is_hit_grab = true
		is_guard_break = hitbox.guard_break
		damage = hitbox.damage
		combo_damage = hitbox.damage_in_combo
		minimum_damage = hitbox.minimum_damage
		stun = hitbox.hitstun_ticks
		combo_stun = hitbox.combo_hitstun_ticks
		proration = hitbox.damage_proration
		combo_scaling = hitbox.combo_scaling_amount if hitbox.scale_combo else 0
		knockback = float(hitbox.knockback)
		knockback_x = float(hitbox.dir_x)
		knockback_y = float(hitbox.dir_y)
		height = Hitbox.HitHeight.keys()[hitbox.hit_height]
		plus_frames = hitbox.plus_frames
		start = hitbox.start_tick
		active = hitbox.active_ticks
		always_on = hitbox.always_on
		looping = hitbox.looping
		loop_active = hitbox.loop_active_ticks
		loop_inactive = hitbox.loop_inactive_ticks
		hits_otg = hitbox.hits_otg
		hits_standing = hitbox.hits_vs_standing
		hits_grounded = hitbox.hits_vs_grounded
		hits_aerial = hitbox.hits_vs_aerial
		hits_dizzy = hitbox.hits_vs_dizzy
		hits_projectiles = hitbox.hits_projectiles
		di_modifier = float(hitbox.di_modifier)
		sdi_modifier = float(hitbox.sdi_modifier)
		pushback = float(hitbox.pushback_x)
		meter_gain_modifier = float(hitbox.meter_gain_modifier)
		knockdown = hitbox.knockdown
		knockdown_extends_hitstun = hitbox.knockdown_extends_hitstun
		hard_knockdown = hitbox.hard_knockdown
		ground_bounce = hitbox.ground_bounce
		air_ground_bounce = hitbox.air_ground_bounce
		followup = hitbox.followup_state if not hitbox is ThrowBox else hitbox.throw_state
		# @TODO release data, if possible
	
	
	func parse_dictionary(data : Dictionary):
		var expected_keys = {
			"title" : "String",
			"color" : "Color",
			"is_grab" : "bool",
			"is_hit_grab" : "bool",
			"is_guard_break" : "bool",
			"damage" : "int",
			"combo_damage" : "int",
			"minimum_damage" : "int",
			"stun" : "int",
			"combo_stun" : "int",
			"proration" : "int",
			"combo_scaling" : "int",
			"knockback" : "float",
			"knockback_x" : "float",
			"knockback_y" : "float",
			"height" : "String",
			"plus_frames" : "int",
			"start" : "int",
			"active" : "int",
			"always_on" : "bool",
			"looping" : "bool",
			"loop_active" : "int",
			"loop_inactive" : "int",
			"hits_otg" : "bool",
			"hits_standing" : "bool",
			"hits_grounded" : "bool",
			"hits_aerial" : "bool",
			"hits_dizzy" : "bool",
			"hits_projectiles" : "bool",
			"di_modifier" : "float",
			"sdi_modifier" : "float",
			"pushback" : "float",
			"meter_gain_modifier" : "float",
			"followup" : "String",
		}
		for key in expected_keys:
			var type = expected_keys[key]
			var input = data.get(key)
			match type:
				"int":
					if input is int or input is float or input is String:
						set(key, int(input))
				"float":
					if input is int or input is float or input is String:
						set(key, float(input))
				"bool":
					if input != null:
						set(key, bool(input))
				"String":
					if input != null:
						set(key, str(input))
				"Color":
					if input is Color:
						set(key, input)








class CodexAchievementList extends Reference:
	
	var achievements : Dictionary = {}
	var counters : Dictionary = {}
	var default_locked_title : String = ""
	var default_locked_desc : String = ""
	var default_locked_icon = null
	var default_unlocked_icon = null
	var uses_default_fanfare = true
	var uses_default_sound = true
	
	
	func define(achievement_id : String, data : Dictionary):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		var title = data.get("title")
		var desc = data.get("desc")
		var icon = data.get("icon")
		var locked_title = data.get("locked_title")
		var locked_desc = data.get("locked_desc")
		var locked_icon = data.get("locked_icon")
		var highlight_color = data.get("highlight_color")
		var secret = data.get("secret")
		var unlocked = data.get("unlocked")
		var counter_id = data.get("counter_id")
		var counter_target = data.get("counter_target")
		var counter_limit = data.get("counter_limit")
		if title is String: achievements[achievement_id].title = title
		if desc is String: achievements[achievement_id].desc = desc
		if icon != null: achievements[achievement_id].icon = icon
		if locked_title is String: achievements[achievement_id].locked_title = locked_title
		if locked_desc is String: achievements[achievement_id].locked_desc = locked_desc
		if locked_icon != null: achievements[achievement_id].locked_icon = locked_icon
		if highlight_color is Color: achievements[achievement_id].highlight_color = highlight_color
		if secret is bool: achievements[achievement_id].secret = secret
		if unlocked is bool: achievements[achievement_id].unlocked = unlocked
		if counter_id is String: achievements[achievement_id].counter_id = counter_id
		if counter_target is int: achievements[achievement_id].counter_target = counter_target
		if counter_limit is bool: achievements[achievement_id].counter_limit = counter_limit
	
	
	func set_title(achievement_id : String, title : String):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].title = title
	
	func set_desc(achievement_id : String, desc : String):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].desc = desc
	
	func set_icon(achievement_id : String, icon):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].icon = icon
	
	
	func set_locked_title(achievement_id : String, title : String):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].locked_title = title
	
	func set_locked_desc(achievement_id : String, desc : String):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].locked_desc = desc
	
	func set_locked_icon(achievement_id : String, icon):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].locked_icon = icon
	
	
	func set_default_locked_title(title : String):
		default_locked_title = title
	
	func set_default_locked_desc(desc : String):
		default_locked_desc = desc
	
	func set_default_locked_icon(icon):
		default_locked_icon = icon
	
	
	func mark_secret(achievement_id : String, secret : bool = true):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].secret = secret
	
	
	func mark_unlocked(achievement_id : String, unlocked : bool = true):
		if not achievements.has(achievement_id):
			return
		achievements[achievement_id].unlocked = unlocked
	
	
	func is_secret(achievement_id : String) -> bool:
		if not achievements.has(achievement_id):
			return false
		return achievements[achievement_id].secret
	
	
	func is_unlocked(achievement_id : String) -> bool:
		if not achievements.has(achievement_id):
			return false
		return achievements[achievement_id].unlocked
	
	
	func is_array_unlocked(achievements : Array) -> bool:
		for id in achievements:
			if not is_unlocked(id):
				return false
		return true
	
	
	func assign_counter(achievement_id : String, counter_id : String, target_value : int = -1):
		if not achievements.has(achievement_id):
			achievements[achievement_id] = CodexAchievement.new()
		achievements[achievement_id].counter_id = counter_id
		achievements[achievement_id].counter_target = target_value
		 
	
	func get_counter_value(counter_id : String) -> int:
		return counters.get(counter_id, 0)
	
	func set_counter_value(counter_id : String, value : int):
		counters[counter_id] = value
	
	
	func is_target_met(achievement_id : String) -> bool:
		if not achievements.has(achievement_id):
			return false
		return get_counter_value(achievements[achievement_id].counter_id) >= achievements[achievement_id].counter_target
	
	
	func get_totals() -> Dictionary:
		var data = {
			"total": achievements.size(),
			"visible": 0,
			"secret": 0,
			"unlocked": 0,
			"unlocked_visible": 0,
			"unlocked_secret": 0,
		}
		for id in achievements:
			var secret = achievements[id].secret
			data["secret" if secret else "visible"] += 1
			if achievements[id].unlocked:
				data["unlocked_secret" if secret else "unlocked_visible"] += 1
				data.unlocked += 1
		data.all_unlocked = (data.unlocked >= data.total)
		data.all_visible_unlocked = (data.unlocked_visible >= data.visible)
		data.all_secret_unlocked = (data.unlocked_secret >= data.secret)
		return data
	
	
	func get_unlocked_array() -> Array:
		var result = []
		for id in achievements:
			if achievements[id].unlocked:
				result.append(id)
		return result
	
	
	func get_display_title(achievement_id : String) -> String:
		if not achievements.has(achievement_id):
			return ""
		var chievo = achievements[achievement_id]
		if chievo.unlocked:
			return chievo.title if chievo.title != "" else achievement_id
		if chievo.locked_title != "":
			return chievo.locked_title
		if default_locked_title != "":
			return default_locked_title
		return chievo.title if chievo.title != "" else achievement_id
	
	
	func get_display_desc(achievement_id : String) -> String:
		if not achievements.has(achievement_id):
			return ""
		var chievo = achievements[achievement_id]
		if chievo.unlocked:
			return chievo.desc
		if chievo.locked_desc != "":
			return chievo.locked_desc
		if default_locked_desc != "":
			return default_locked_desc
		return chievo.desc
	
	
	func get_display_icon(achievement_id : String):
		if not achievements.has(achievement_id):
			return null
		var chievo = achievements[achievement_id]
		var result = null
		if chievo.unlocked:
			result = __parse_to_texture(chievo.icon)
			if result == null:
				result = __parse_to_texture(default_unlocked_icon)
			if result == null:
				result = load("res://_tri_char_codex/images/trophy_gold.png")
			return result
		result = __parse_to_texture(chievo.locked_icon)
		if result == null:
			result = __parse_to_texture(default_locked_icon)
		if result == null:
			result = load("res://_tri_char_codex/images/trophy_empty.png")
		return result
	
	
	func get_display_highlight(achievement_id : String, ignore_locked_check = false) -> Color:
		if not achievements.has(achievement_id):
			return Color(0.25, 0.25, 0.25)
		var chievo = achievements[achievement_id]
		if chievo.unlocked or ignore_locked_check:
			return chievo.highlight_color
		return Color(0.25, 0.25, 0.25)
	
	
	func get_debug_title(achievement_id : String, as_unlocked : bool = true) -> String:
		if not achievements.has(achievement_id):
			return ""
		var chievo = achievements[achievement_id]
		if as_unlocked:
			return chievo.title if chievo.title != "" else achievement_id
		if chievo.locked_title != "":
			return chievo.locked_title
		if default_locked_title != "":
			return default_locked_title
		return chievo.title if chievo.title != "" else achievement_id
	
	
	func get_debug_desc(achievement_id : String, as_unlocked : bool = true) -> String:
		if not achievements.has(achievement_id):
			return ""
		var chievo = achievements[achievement_id]
		if as_unlocked:
			return chievo.desc
		if chievo.locked_desc != "":
			return chievo.locked_desc
		if default_locked_desc != "":
			return default_locked_desc
		return chievo.desc
	
	
	func get_debug_icon(achievement_id : String, as_unlocked : bool = true):
		if not achievements.has(achievement_id):
			return null
		var chievo = achievements[achievement_id]
		var result = null
		if as_unlocked:
			result = __parse_to_texture(chievo.icon)
			if result == null:
				result = __parse_to_texture(default_unlocked_icon)
			if result == null:
				result = load("res://_tri_char_codex/images/trophy_gold.png")
			return result
		result = __parse_to_texture(chievo.locked_icon)
		if result == null:
			result = __parse_to_texture(default_locked_icon)
		if result == null:
			result = load("res://_tri_char_codex/images/trophy_empty.png")
		return result
	
	
	func get_debug_highlight(achievement_id : String, as_unlocked : bool = true) -> Color:
		if not achievements.has(achievement_id):
			return Color(0.25, 0.25, 0.25)
		var chievo = achievements[achievement_id]
		if as_unlocked:
			return chievo.highlight_color
		return Color(0.25, 0.25, 0.25)
	
	
	func get_display_counter_value(achievement_id : String) -> int:
		if not achievements.has(achievement_id):
			return -1
		var chievo = achievements[achievement_id]
		if chievo.counter_id == "":
			return -1
		return get_counter_value(chievo.counter_id)
	
	
	func get_display_counter_target(achievement_id : String) -> int:
		if not achievements.has(achievement_id):
			return -1
		var chievo = achievements[achievement_id]
		if chievo.counter_id == "":
			return -1
		return chievo.counter_target
	
	func get_display_counter_text(achievement_id : String) -> String:
		if not achievements.has(achievement_id):
			return ""
		var chievo = achievements[achievement_id]
		if chievo.counter_id == "":
			return ""
		var value = get_counter_value(chievo.counter_id)
		if chievo.counter_target > 0:
			if (chievo.counter_limit and value > chievo.counter_target):
				value = chievo.counter_target
			return str(value) + "/" + str(chievo.counter_target)
		return str(value)
	
	
	func __parse_to_texture(input):
		if input == null:
			return null
		if input is Texture:
			return input
		if ResourceLoader.exists(input, "Texture"):
			var tex = load(input)
			if tex is Texture:
				return tex
		return null

func __page_editor(page, char_path : String):
	var override = __attempt_load_codex_script(char_path)
	if override != null:
		if override.has_method("modify_codex_page"):
			var codex_page = page
			var char_instance = __attempt_load_char_instance(char_path)
			var params = {
				"char_path": char_path,
				"character": char_instance,
				"codex_library": self,
			}
			override.callv("modify_codex_page", [codex_page, params])
		if override.has_method("queue_free"):
			override.queue_free()


class CodexAchievement extends Reference:
	
	var title : String = ""
	var desc : String = ""
	var icon = null
	var locked_title : String = ""
	var locked_desc : String = ""
	var locked_icon = null
	var secret : bool = false
	var unlocked : bool = false
	var highlight_color : Color = Color(1.0, 1.0, 1.0)
	var counter_id : String = ""
	var counter_target : int = -1
	var counter_limit : bool = false
