extends Camera2D

@export var zoom_level = 2.0
@export var map_right = 1150
@export var map_bottom = 660

func _ready():
	zoom = Vector2(zoom_level, zoom_level)
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_left = 0
	limit_top = 0
	limit_right = map_right
	limit_bottom = map_bottom
