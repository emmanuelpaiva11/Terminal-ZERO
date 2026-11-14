extends Marker2D

var bullet_scene = preload("res://bullet.tscn")

func fire(direction):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.rotation = direction.angle()
	bullet.direction = direction
	get_tree().current_scene.add_child(bullet)
