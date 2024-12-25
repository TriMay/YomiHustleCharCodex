extends PanelContainer


var is_more_info = false
var show_more_info = false
var has_more_info = false
var has_min_info = false


func _ready():
	toggle_more_info(show_more_info)


func toggle_more_info(toggle):
	show_more_info = toggle
	visible = show_more_info or not is_more_info
	$"%MoreValue".visible = has_more_info and show_more_info
	$"%MinValue".visible = has_min_info and show_more_info


func set_label(text):
	$"%Label".text = str(text)


func set_value(value):
	if value is Dictionary:
		$"%DirContainer".visible = false
		if value.has("x") and value.has("y"):
			var vec = Vector2(float(value.x), float(value.y)).normalized()
			$"%DirContainer".visible = true
			$"%DirContainer".hint_tooltip = str(round(rad2deg(vec.angle()))) + " deg"
			$"%Dir".point_to = vec
		$"%ValueList".visible = false
		if value.has("list") and value.list is Array:
			$"%ValueList".visible = true
			for sub_value in value.list:
				var label = Label.new()
				label.text = sub_value
				label.mouse_filter = MOUSE_FILTER_STOP
				$"%ValueList".add_child(label)
			if value.has("list_hints") and value.list_hints is Array:
				for index in value.list_hints.size():
					$"%ValueList".get_child(index).hint_tooltip = str(value.list_hints[index])
			if value.has("list_truths") and value.list_truths is Array:
				for index in value.list_truths.size():
					$"%ValueList".get_child(index).modulate = Color(0.3, 1.0, 0.3) if value.list_truths[index] else Color(0.3, 0.3, 0.3)
		if value.has("amount"):
			value = value.amount
		else:
			value = ""
	$"%Value".text = str(value)
	$"%MainRow".visible = (str(value) != "")


func set_more_value(value):
	has_more_info = (value != null and str(value) != "")
	$"%MoreValue".text = str(value)


func set_minimum_value(value):
	has_min_info = (value != null and str(value) != "")
	$"%MinValue".text = str(value)

