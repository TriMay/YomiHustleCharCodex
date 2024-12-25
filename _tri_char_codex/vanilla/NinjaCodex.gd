extends Node



func register(codex):
	codex.banner_offset.x = 0
	codex.set_subtitle("The Stickman")



func setup_achievements(list):
	list.define("ACH_STERNUM_EXPLODER", {
		"title": Steam.getAchievementDisplayAttribute("ACH_STERNUM_EXPLODER", "name"),
		"desc": Steam.getAchievementDisplayAttribute("ACH_STERNUM_EXPLODER", "desc"),
		"icon": "res://_tri_char_codex/images/ACH_STERNUM_EXPLODER.png",
		"unlocked": Steam.getAchievement("ACH_STERNUM_EXPLODER")["achieved"]
	})
