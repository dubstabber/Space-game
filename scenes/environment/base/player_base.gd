extends Area2D

@export var base_radius: float = 220.0
@export var dock_radius: float = 120.0

var _player: CharacterBody2D = null
var _player_inside: bool = false
var _active: bool = false

@onready var hull: Polygon2D = $Hull
@onready var ring: Line2D = $DockRing
@onready var core: Polygon2D = $Core
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	MapManager.map_changed.connect(_on_map_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_setup_geometry()
	_apply_map_state()


func _process(_delta: float) -> void:
	if _active and _player_inside and Input.is_action_just_pressed("interact"):
		GameManager.enter_base()


func _setup_geometry() -> void:
	var hull_points := PackedVector2Array([
		Vector2(0, -base_radius),
		Vector2(base_radius * 0.72, -base_radius * 0.72),
		Vector2(base_radius, 0),
		Vector2(base_radius * 0.72, base_radius * 0.72),
		Vector2(0, base_radius),
		Vector2(-base_radius * 0.72, base_radius * 0.72),
		Vector2(-base_radius, 0),
		Vector2(-base_radius * 0.72, -base_radius * 0.72),
	])
	if hull:
		hull.polygon = hull_points
		hull.color = Color(0.12, 0.16, 0.24, 0.85)
	if ring:
		ring.points = _make_ring_points(dock_radius, 40)
		ring.default_color = Color(0.3, 0.85, 0.65, 0.9)
		ring.width = 3.0
	if core:
		core.polygon = _make_ring_points(base_radius * 0.32, 8)
		core.color = Color(0.25, 0.45, 0.7, 0.9)
	if collision_shape:
		var shape := CircleShape2D.new()
		shape.radius = dock_radius
		collision_shape.shape = shape


func _make_ring_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		points.append(Vector2.from_angle(TAU * float(i) / float(segments)) * radius)
	return points


func _apply_map_state() -> void:
	var map_data := MapManager.get_current_map()
	_active = map_data != null and map_data.has_safe_zone
	visible = _active
	monitoring = _active
	if collision_shape:
		collision_shape.disabled = not _active
	if not _active:
		_player_inside = false
		_unfreeze_player()


func _freeze_player() -> void:
	if _player == null:
		return
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)


func _unfreeze_player() -> void:
	if _player and is_instance_valid(_player):
		_player.set_physics_process(true)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body as CharacterBody2D
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player_inside = false
		if not GameManager.is_in_base():
			_player = null


func _on_map_changed(_map_id: String) -> void:
	_apply_map_state()


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.IN_BASE:
		_freeze_player()
	elif new_state == GameManager.GameState.PLAYING:
		_unfreeze_player()
