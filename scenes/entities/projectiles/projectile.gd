extends Area2D

const HitEffect = preload("res://scenes/entities/projectiles/hit_effect.tscn")

@export var speed: float = 800.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var _direction: Vector2 = Vector2.UP
var _is_player_projectile: bool = true
var _lifetime_timer: float = 0.0


func _ready() -> void:
	_direction = Vector2.from_angle(rotation - PI / 2)
	_lifetime_timer = lifetime
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	_setup_geometry()


func _physics_process(delta: float) -> void:
	position += _direction * speed * delta
	
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()


func set_owner_type(is_player: bool) -> void:
	_is_player_projectile = is_player
	
	if is_player:
		collision_layer = 1 << 3
		collision_mask = (1 << 1) | (1 << 2)
	else:
		collision_layer = 1 << 4
		collision_mask = 1 << 0


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_spawn_hit_effect()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	_spawn_hit_effect()
	queue_free()


func _spawn_hit_effect() -> void:
	var effect := HitEffect.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)


func _setup_geometry() -> void:
	var line := $Line2D as Line2D
	if line:
		line.points = PackedVector2Array([
			Vector2(0, 8),
			Vector2(0, -8),
		])
		line.width = 3.0
		
		if _is_player_projectile:
			line.default_color = Color(0.3, 0.8, 1.0)
		else:
			line.default_color = Color(1.0, 0.3, 0.3)
