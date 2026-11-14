extends CharacterBody2D

@export var chase_speed = 250.0
@export var roam_speed = 120.0
@export var search_speed = 160.0
@export var lunge_speed = 380.0
@export var lunge_range = 140.0
@export var stun_time = 30.0
@export var kill_distance = 16.0
@export var grace_time = 4.0
@export var sight_range = 450.0
@export var hearing_range = 750.0
@export var feeler = 44.0
@export var glow_radius = 90.0

var state = "roam"
var stun_left = 0.0
var grace_left = 0.0
var player = null
var roam_dir = Vector2.RIGHT
var roam_timer = 0.0
var target = Vector2.ZERO
var search_left = 0.0
var stuck_check = 0.0
var stuck_time = 0.0
var last_pos = Vector2.ZERO
var dodge_left = 0.0
var dodge_dir = Vector2.ZERO
var lunge_left = 0.0
var lunge_cd = 0.0

@onready var sprite = get_node_or_null("Sprite2D")

func _ready():
	add_to_group("alien")
	grace_left = grace_time
	last_pos = global_position
	randomize()
	make_glow()

func make_glow():
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.1, 0.1, 1.0), Color(0.0, 0.0, 0.0, 1.0)])
	var t = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 256
	t.height = 256
	var l = PointLight2D.new()
	l.texture = t
	l.texture_scale = glow_radius / 128.0
	l.energy = 1.1
	add_child(l)

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	if grace_left > 0.0:
		grace_left -= delta
		return

	if stun_left > 0.0:
		stun_left -= delta
		velocity = Vector2.ZERO
		if sprite:
			sprite.modulate = Color(0.5, 0.6, 1.0)
		return

	if sprite:
		sprite.modulate = Color(1, 1, 1)

	lunge_cd -= delta
	var dist = global_position.distance_to(player.global_position)
	var sees = can_see_player()

	if sees:
		state = "chase"
		target = player.global_position
	elif state == "chase":
		state = "investigate"

	var dir = Vector2.ZERO
	var speed = roam_speed

	if state == "chase":
		dir = (target - global_position).normalized()
		speed = chase_speed
		if dist < lunge_range and lunge_cd <= 0.0:
			lunge_left = 0.4
			lunge_cd = 4.0
		if lunge_left > 0.0:
			lunge_left -= delta
			speed = lunge_speed
	elif state == "investigate":
		dir = (target - global_position).normalized()
		speed = search_speed
		if global_position.distance_to(target) < 24.0:
			state = "search"
			search_left = 4.0
	elif state == "search":
		search_left -= delta
		if sprite:
			sprite.rotation += delta * 3.0
		if search_left <= 0.0:
			state = "roam"
	else:
		roam_timer -= delta
		if roam_timer <= 0.0 or is_on_wall():
			roam_dir = Vector2.from_angle(randf() * TAU)
			roam_timer = randf_range(1.5, 3.5)
		dir = roam_dir

	stuck_check += delta
	if stuck_check >= 0.4:
		var moved = global_position.distance_to(last_pos)
		last_pos = global_position
		stuck_check = 0.0
		if state != "search" and moved < 6.0:
			stuck_time += 0.4
		else:
			stuck_time = 0.0
		if stuck_time >= 0.8:
			stuck_time = 0.0
			dodge_left = 0.6
			dodge_dir = dir.rotated((PI / 2.0) * (1.0 if randf() > 0.5 else -1.0))
			roam_timer = 0.0
			if state == "investigate":
				state = "roam"

	if dodge_left > 0.0:
		dodge_left -= delta
		dir = dodge_dir

	if dir != Vector2.ZERO:
		dir = steer(dir)
	velocity = dir * speed
	move_and_slide()

	if sprite and state != "search" and velocity.length() > 1.0:
		sprite.rotation = velocity.angle()

	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == player:
			player.die()
			return

	if global_position.distance_to(player.global_position) < kill_distance:
		player.die()

func hear(pos):
	if stun_left > 0.0 or grace_left > 0.0 or state == "chase":
		return
	if global_position.distance_to(pos) < hearing_range:
		state = "investigate"
		target = pos

func blocked(dir):
	var q = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * feeler)
	q.exclude = [get_rid()]
	var r = get_world_2d().direct_space_state.intersect_ray(q)
	return r.size() > 0 and r.collider != player

func steer(dir):
	if not blocked(dir):
		return dir
	for a in [0.5, -0.5, 1.0, -1.0, 1.5, -1.5, 2.2, -2.2]:
		var d = dir.rotated(a)
		if not blocked(d):
			return d
	return -dir

func can_see_player():
	var to_player = player.global_position - global_position
	if to_player.length() > sight_range:
		return false
	var q = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	q.exclude = [get_rid()]
	var r = get_world_2d().direct_space_state.intersect_ray(q)
	return r.size() == 0 or r.collider == player

func hit():
	stun_time_start()

func stun_time_start():
	stun_left = stun_time
