extends Node



func register(codex):
	codex.set_subtitle("Death Grip Machine")
	#codex_data.set_summary("He's a ninja")
	#codex_data.set_move_desc("Slash", "Custom Move Description")
	#codex_data.set_move_desc("Chainsaw", "Custom Move Description")
	#codex_data.set_move_desc("Silly Move", "Custom Move Description")



func setup_achievements(list):
	list.define("ACH_STERNUM_EXPLODER", {
		"title": Steam.getAchievementDisplayAttribute("ACH_GRATUITOUS", "name"),
		"desc": Steam.getAchievementDisplayAttribute("ACH_GRATUITOUS", "desc"),
		"icon": "res://_tri_char_codex/images/ACH_GRATUITOUS.png",
		"unlocked": Steam.getAchievement("ACH_GRATUITOUS")["achieved"]
	})
