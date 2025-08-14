extends Node



func register(codex):
	codex.set_subtitle("The Sword Guy")
	#codex_data.set_summary("He"s a ninja")
	#codex_data.set_move_desc("Slash", "Custom Move Description")
	#codex_data.set_move_desc("Chainsaw", "Custom Move Description")
	#codex_data.set_move_desc("Silly Move", "Custom Move Description")



func setup_achievements(list):
	list.define("ACH_STERNUM_EXPLODER", {
		"title": Steam.getAchievementDisplayAttribute("ACH_TELEPORTS_BEHIND_YOU", "name"),
		"desc": Steam.getAchievementDisplayAttribute("ACH_TELEPORTS_BEHIND_YOU", "desc"),
		"icon": "res://_tri_char_codex/images/ACH_TELEPORTS_BEHIND_YOU.png",
		"unlocked": Steam.getAchievement("ACH_TELEPORTS_BEHIND_YOU")["achieved"]
	})


func modify_codex_page(page, params):
	page.get_node("BGColor").modulate = Color(1, 0, 0.937255)
