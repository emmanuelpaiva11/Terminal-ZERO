extends Area2D

var speed = 700.0
var direction = Vector2.RIGHT

func _ready():
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
	if body.has_method("hit"):
		body.hit()
	queue_free()
