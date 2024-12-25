extends VBoxContainer


onready var CharSelect = get_node_or_null("/root/Main/%CharacterSelect")


var eggs = {
	"res://_wraith/Wraith.tscn": "You shouldn't have done that...",
}



func easter_egg(char_path):
	var label_text = "Please wait..."
	if char_path in eggs:
		label_text = eggs[char_path]
	else:
		match int(rand_range(0, 35)):
			1: label_text = "Trying my best..."
			2: label_text = "Please be patient..."
			3: label_text = "Loading..."
			4: label_text = "Working on it..."
			5: label_text = "Insert easter egg..."
	$PleaseWait.text = label_text



func _process(delta):
	if is_instance_valid(CharSelect):
		var loading_text = CharSelect.get("loadingText")
		$Label.text = "Generating..." if loading_text == "" or loading_text == null else loading_text
