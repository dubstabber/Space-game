extends Area2D

signal player_entered(portal: Node2D)
signal teleport_started(destination_map_id: String)
signal teleport_completed(destination_map_id: String)

@export var portal_id: String = ""
@export var destination_map_id: String = ""
@export var destination_position: Vector2 = Vector2.ZERO
@export var portal_radius: float = 60.0
@export var pulse_speed: float = 2.0
@export var rotation_speed: float = 1.0
@export var activation_delay: float = 0.5

var _time: float = 0.0
var _is_active: bool = true
var _player_inside: bool = false
var _activation_timer: float = 0.0

@onready var outer_ring: Line2D = $OuterRing
@onready var inner_ring: Line2D = $InnerRing
@onready var center_glow: Polygon2D = $CenterGlow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_setup_geometry()
	_register_with_manager()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	_animate_portal(delta)
	
	if _player_inside and _is_active:
		_activation_timer += delta
		if _activation_timer >= activation_delay:
			_teleport_player()


func initialize(id: String, destination: String, dest_pos: Vector2 = Vector2.ZERO) -> void:
	portal_id = id
	destination_map_id = destination
	destination_position = dest_pos
	
	if is_inside_tree():
		_register_with_manager()


func _setup_geometry() -> void:
	var outer_points := _generate_ring_points(portal_radius, 32)
	var inner_points := _generate_ring_points(portal_radius * 0.6, 24)
	var center_points := _generate_ring_points(portal_radius * 0.3, 16)
	
	if outer_ring:
		outer_ring.points = outer_points
		outer_ring.width = 3.0
		outer_ring.default_color = _get_portal_color().lightened(0.2)
	
	if inner_ring:
		inner_ring.points = inner_points
		inner_ring.width = 2.0
		inner_ring.default_color = _get_portal_color()
	
	if center_glow:
		center_glow.polygon = center_points
		center_glow.color = _get_portal_color().darkened(0.3)
		center_glow.color.a = 0.5
	
	if collision_shape:
		var shape := CircleShape2D.new()
		shape.radius = portal_radius * 0.8
		collision_shape.shape = shape


func _generate_ring_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var angle_step := TAU / segments
	
	for i in range(segments + 1):
		var angle := i * angle_step
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	return points


func _get_portal_color() -> Color:
	var map_data := MapManager.get_map_data(destination_map_id)
	if map_data:
		match map_data.danger_level:
			0:
				return Color(0.3, 0.8, 0.4)
			1:
				return Color(0.4, 0.6, 1.0)
			2:
				return Color(0.8, 0.6, 0.2)
			3:
				return Color(1.0, 0.3, 0.3)
	
	return Color(0.5, 0.5, 1.0)


func _animate_portal(delta: float) -> void:
	var pulse := (sin(_time * pulse_speed) + 1.0) * 0.5
	var alpha := 0.4 + pulse * 0.4
	
	if outer_ring:
		outer_ring.rotation += rotation_speed * delta
		outer_ring.modulate.a = alpha
	
	if inner_ring:
		inner_ring.rotation -= rotation_speed * 1.5 * delta
		inner_ring.modulate.a = alpha * 0.8
	
	if center_glow:
		var scale_factor := 0.9 + pulse * 0.2
		center_glow.scale = Vector2(scale_factor, scale_factor)
	
	if _player_inside:
		var activation_progress := _activation_timer / activation_delay
		if center_glow:
			center_glow.modulate = Color(1.0 + activation_progress, 1.0 + activation_progress, 1.0 + activation_progress)


func _register_with_manager() -> void:
	if portal_id.is_empty():
		portal_id = "portal_%d" % get_instance_id()
	
	var source_map := MapManager.current_map_id
	if source_map.is_empty():
		source_map = "default_space"
	
	MapManager.register_teleporter(portal_id, source_map, destination_map_id, destination_position)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_activation_timer = 0.0
		player_entered.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_activation_timer = 0.0


func _teleport_player() -> void:
	if not _is_active or destination_map_id.is_empty():
		return
	
	_is_active = false
	teleport_started.emit(destination_map_id)
	
	MapManager.teleport_to_map(destination_map_id, destination_position)
	
	teleport_completed.emit(destination_map_id)
	
	await get_tree().create_timer(1.0).timeout
	_is_active = true


func set_active(active: bool) -> void:
	_is_active = active
	visible = active
	
	if collision_shape:
		collision_shape.disabled = not active


func get_destination_name() -> String:
	var map_data := MapManager.get_map_data(destination_map_id)
	if map_data:
		return map_data.map_name
	return destination_map_id
