extends CharacterBody2D

signal health_changed(new_health: int, max_health: int)
signal died

@export var max_speed: float = 400.0
@export var acceleration: float = 800.0
@export var rotation_speed: float = 4.0
@export var friction: float = 0.98
@export var max_health: int = 100
@export var shoot_cooldown: float = 0.15

## Debug: multiplier applied to max_speed and acceleration when debug boost is active
@export var debug_speed_multiplier: float = 10.0

var current_health: int = max_health
var _debug_boost_active: bool = false
var _shoot_timer: float = 0.0
var _is_thrusting: bool = false

@onready var ship_body: Polygon2D = $ShipBody
@onready var ship_outline: Line2D = $ShipOutline
@onready var engine_glow: Polygon2D = $EngineGlow
@onready var collision_shape: CollisionPolygon2D = $CollisionShape
@onready var projectile_spawn: Marker2D = $ProjectileSpawn

var _shoot_sound_player: AudioStreamPlayer
var _shoot_sound: AudioStreamWAV

const Projectile = preload("res://scenes/entities/projectiles/projectile.tscn")


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_setup_ship_geometry()
	_setup_shoot_sound()


func _physics_process(delta: float) -> void:
	_handle_debug_input()
	_handle_input(delta)
	_update_shoot_timer(delta)
	_update_engine_glow()
	move_and_slide()


func _handle_debug_input() -> void:
	if Input.is_action_just_pressed("debug_speed_boost"):
		_debug_boost_active = not _debug_boost_active
		print("[DEBUG] Speed boost: ", "ON (x%s)" % debug_speed_multiplier if _debug_boost_active else "OFF")


func _handle_input(delta: float) -> void:
	var rotation_input := Input.get_axis("rotate_left", "rotate_right")
	rotation += rotation_input * rotation_speed * delta
	
	_is_thrusting = Input.is_action_pressed("thrust")
	if _is_thrusting:
		var direction := Vector2.from_angle(rotation - PI / 2)
		var current_accel := acceleration * (debug_speed_multiplier if _debug_boost_active else 1.0)
		var current_max_speed := max_speed * (debug_speed_multiplier if _debug_boost_active else 1.0)
		velocity += direction * current_accel * delta
		velocity = velocity.limit_length(current_max_speed)
	else:
		velocity *= friction
	
	if Input.is_action_pressed("shoot") and _shoot_timer <= 0:
		_shoot()


func _shoot() -> void:
	_shoot_timer = shoot_cooldown
	_play_shoot_sound()
	
	var projectile := Projectile.instantiate()
	projectile.global_position = projectile_spawn.global_position
	projectile.rotation = rotation
	projectile.set_owner_type(true)
	get_tree().current_scene.add_child(projectile)


func _update_shoot_timer(delta: float) -> void:
	if _shoot_timer > 0:
		_shoot_timer -= delta


func _update_engine_glow() -> void:
	if engine_glow:
		engine_glow.visible = _is_thrusting
		if _is_thrusting:
			var flicker := randf_range(0.7, 1.0)
			engine_glow.modulate.a = flicker


func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()


func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func _die() -> void:
	died.emit()
	queue_free()


func _setup_shoot_sound() -> void:
	_shoot_sound = AudioStreamWAV.new()
	_shoot_sound.mix_rate = 44100
	_shoot_sound.format = AudioStreamWAV.FORMAT_8_BITS
	_shoot_sound.stereo = false
	
	var duration := 0.12
	var sample_count := int(duration * _shoot_sound.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	
	var base_freq := 350.0
	var end_freq := 60.0
	var phase := 0.0
	
	for i in sample_count:
		var t := float(i) / sample_count
		# Exponential frequency drop for a "zap"
		var freq := lerpf(base_freq, end_freq, pow(t, 0.5))
		phase += freq / _shoot_sound.mix_rate
		
		# Sharper envelope
		var envelope := exp(-t * 8.0)
		
		# Base wave (sine with some saturation for grit)
		var signal_val := sin(phase * TAU)
		# Add some square-ish character
		if signal_val > 0.5: signal_val = 0.8
		elif signal_val < -0.5: signal_val = -0.8
		
		var wave := signal_val * 0.7
		# Add a sub-oscillator for body
		wave += sin(phase * TAU * 0.5) * 0.3
		# Add slight noise for texture
		wave += (randf() - 0.5) * 0.2 * envelope
		
		var sample := int((wave * envelope * 0.5 + 0.5) * 255.0)
		data[i] = clampi(sample, 0, 255)
	
	_shoot_sound.data = data
	
	_shoot_sound_player = AudioStreamPlayer.new()
	_shoot_sound_player.stream = _shoot_sound
	_shoot_sound_player.volume_db = -40.0
	add_child(_shoot_sound_player)


func _play_shoot_sound() -> void:
	if _shoot_sound_player:
		_shoot_sound_player.play()


func _setup_ship_geometry() -> void:
	var body_points := PackedVector2Array([
		Vector2(0, -20),
		Vector2(12, 15),
		Vector2(6, 10),
		Vector2(-6, 10),
		Vector2(-12, 15),
	])
	
	var outline_points := PackedVector2Array([
		Vector2(0, -20),
		Vector2(12, 15),
		Vector2(6, 10),
		Vector2(-6, 10),
		Vector2(-12, 15),
		Vector2(0, -20),
	])
	
	var engine_points := PackedVector2Array([
		Vector2(-4, 10),
		Vector2(0, 22),
		Vector2(4, 10),
	])
	
	if ship_body:
		ship_body.polygon = body_points
		ship_body.color = Color(0.15, 0.2, 0.3)
	
	if ship_outline:
		ship_outline.points = outline_points
		ship_outline.width = 2.0
		ship_outline.default_color = Color(0.4, 0.6, 0.9)
	
	if engine_glow:
		engine_glow.polygon = engine_points
		engine_glow.color = Color(1.0, 0.6, 0.2, 0.9)
		engine_glow.visible = false
	
	if collision_shape:
		collision_shape.polygon = body_points
