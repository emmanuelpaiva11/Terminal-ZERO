extends Button

func _ready():
	pressed.connect(_go)

func _go():
	get_tree().change_scene_to_file("res://node_2d.tscn")
