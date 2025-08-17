extends Node



func register(codex):
	codex.set_subtitle("Tome Slap Tome Slap Tome Slap Tome Slap Tome Slap")



func setup_achievements(list):
	list.define("ACH_SUGARCOAT", {
		"title": Steam.getAchievementDisplayAttribute("ACH_SUGARCOAT", "name"),
		"desc": Steam.getAchievementDisplayAttribute("ACH_SUGARCOAT", "desc"),
		"icon": "res://_tri_char_codex/images/ACH_SUGARCOAT.png",
		"unlocked": Steam.getAchievement("ACH_SUGARCOAT")["achieved"]
	})
	list.define("ACH_SPARK_JUMP", {
		"title": Steam.getAchievementDisplayAttribute("ACH_SPARK_JUMP", "name"),
		"desc": Steam.getAchievementDisplayAttribute("ACH_SPARK_JUMP", "desc"),
		"icon": "res://_tri_char_codex/images/ACH_SPARK_JUMP.png",
		"unlocked": Steam.getAchievement("ACH_SPARK_JUMP")["achieved"]
	})

