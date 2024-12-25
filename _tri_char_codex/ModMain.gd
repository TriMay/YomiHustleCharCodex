extends Node


func _init(modLoader = ModLoader):
	modLoader.installScriptExtension("res://_tri_char_codex/UIHook.gd")
	modLoader.installScriptExtension("res://_tri_char_codex/MLMainHook.gd")
	modLoader.installScriptExtension("res://_tri_char_codex/CharSelect.gd")
	
	install_script_extension("res://_tri_char_codex/Network.gd")
	reload_script_override(Network)
	
	replace_path("res://_tri_char_codex/vanilla/NinjaCodex.gd", "res://characters/stickman/Codex.gd")
	replace_path("res://_tri_char_codex/vanilla/CowboyCodex.gd", "res://characters/swordandgun/Codex.gd")
	replace_path("res://_tri_char_codex/vanilla/WizardCodex.gd", "res://characters/wizard/Codex.gd")
	replace_path("res://_tri_char_codex/vanilla/RobotCodex.gd", "res://characters/robo/Codex.gd")
	replace_path("res://_tri_char_codex/vanilla/MutantCodex.gd", "res://characters/mutant/Codex.gd")



func _ready():
	if has_node("/root/CharCodexLibrary"):
		get_node("/root/CharCodexLibrary").name = "NoYoureNot"
	var codex_handler = load("res://_tri_char_codex/CodexHandler.gd").new()
	codex_handler.name = "CharCodexLibrary"
	get_node("/root").call_deferred("add_child", codex_handler)



func install_script_extension(childScriptPath:String):
	var childScript = ResourceLoader.load(childScriptPath)
	childScript.new()
	var parentScript = childScript.get_base_script()
	var parentScriptPath = parentScript.resource_path
	childScript.take_over_path(parentScriptPath)


func replace_path(true_path, target_path):
	var childScript = ResourceLoader.load(true_path)
	childScript.new()
	childScript.take_over_path(target_path)


func reload_script_override(object):
	object.set_script(load(object.get_script().resource_path))
