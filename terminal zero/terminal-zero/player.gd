extends CharacterBody2D

@export var speed = 150.0
@export var gun_distance = 22.0
@export var zoom_level = 2.0
@export var light_radius = 300.0
@export var base_energy = 1.8
@export var darkness = Color(0.03, 0.03, 0.05)
@export var music_path = "res://music.mp3"
@export var music_volume = -6.0

var bullet_scene = preload("res://bullet.tscn")
var facing = Vector2.RIGHT
var ammo = 30
var rescued = 0
var dead = false
var died_at = 0
var light = null
var time = 0.0

@onready var sprite = $Sprite2D

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player")
	RenderingServer.set_default_clear_color(Color(0, 0, 0))
	setup_camera()
	setup_horror()
	setup_music()

func setup_camera():
	var cam = find_child("Camera2D", true, false)
	if cam == null:
		cam = Camera2D.new()
		add_child(cam)
	cam.position = sprite.position
	cam.zoom = Vector2(zoom_level, zoom_level)
	cam.position_smoothing_enabled = false
	cam.drag_horizontal_enabled = false
	cam.drag_vertical_enabled = false
	cam.ignore_rotation = true
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.limit_left = -10000000
	cam.limit_top = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000
	cam.make_current()

func setup_music():
	if not ResourceLoader.exists(music_path):
		return
	var stream = load(music_path)
	if "loop" in stream:
		stream.loop = true
	var m = AudioStreamPlayer.new()
	m.stream = stream
	m.volume_db = music_volume
	add_child(m)
	m.play()

func setup_horror():
	var dark = CanvasModulate.new()
	dark.color = darkness
	add_child(dark)

	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 0.97, 0.9, 1.0),
		Color(0.85, 0.82, 0.78, 1.0),
		Color(0.25, 0.24, 0.22, 1.0),
		Color(0.0, 0.0, 0.0, 1.0)
	])
	var t = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 512
	t.height = 512

	light = PointLight2D.new()
	light.texture = t
	light.texture_scale = light_radius / 256.0
	light.energy = base_energy
	light.global_position = sprite.global_position
	add_child(light)

func _process(delta):
	time += delta
	if light:
		light.global_position = sprite.global_position
		light.rotation = 0.0
		light.energy = base_energy + sin(time * 9.0) * 0.04 + randf_range(-0.04, 0.04)
	if dead and Time.get_ticks_msec() - died_at > 1000:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().paused = false
			get_tree().reload_current_scene()

func _physics_process(delta):
	if dead:
		return
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * speed
	if dir != Vector2.ZERO:
		facing = dir.normalized()
		sprite.rotation = facing.angle()
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept") and ammo > 0:
		shoot()

func shoot():
	ammo -= 1
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = sprite.global_position + facing * gun_distance
	bullet.rotation = facing.angle()
	bullet.direction = facing
	get_tree().call_group("alien", "hear", global_position)

func die():
	if dead:
		return
	dead = true
	died_at = Time.get_ticks_msec()
	get_tree().paused = true

	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0, 0, 0.9)
	layer.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var label = Label.new()
	label.text = "YOU DIED\n\nZERO PROTOCOL ACTIVE\nPress SPACE to respawn"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.85, 0.05, 0.05))
	if ResourceLoader.exists("res://Ghastly Panic.ttf"):
		label.add_theme_font_override("font", load("res://Ghastly Panic.ttf"))
	layer.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
