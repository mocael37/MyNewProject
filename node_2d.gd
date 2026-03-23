extends Node2D

var count = 0
const SAVE_PATH = "user://save.dat"

func _ready():
	load_data()
	$Label.text = str(count)

func _on_button_pressed():
	count += 1
	$Label.text = str(count)
	save_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(count)

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		count = file.get_var()
yeah
