extends Area2D

signal collected(resource_type: ResourceData.ResourceType, amount: int)

@export var resource_type: ResourceData.ResourceType = ResourceData.ResourceType.IRON
@export var amount: int = 1
@export var attraction_speed: float = 300.0
@export var attraction_range: float = 150.0
@export var bob_speed: float = 2.0
@export var bob_amount: float = 3.0
@export var lifetime: float = 30.0

var _target: Node2D = null
var _base_position: Vector2
var _time: float = 0.0
var _lifetime_timer: float = 0.0

@onready var polygon: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D


func _ready() -> void:
	_base_position = position
	_lifetime_timer = lifetime
	_setup_geometry()
	
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_lifetime_timer -= delta
	
	if _lifetime_timer <= 0:
		queue_free()
		return
	
	if _target:
		var direction := (_target.global_position - global_position).normalized()
		var distance := global_position.distance_to(_target.global_position)
		var speed := attraction_speed * (1.0 + (attraction_range - distance) / attraction_range)
		global_position += direction * speed * delta
	else:
		position.y = _base_position.y + sin(_time * bob_speed) * bob_amount
	
	_update_fade()


func initialize(type: ResourceData.ResourceType, pickup_amount: int = 1) -> void:
	resource_type = type
	amount = pickup_amount
	
	if is_inside_tree():
		_setup_geometry()


func _setup_geometry() -> void:
	var color := ResourceData.get_resource_color(resource_type)
	var size := 8.0
	
	var points := PackedVector2Array([
		Vector2(0, -size),
		Vector2(size * 0.7, -size * 0.3),
		Vector2(size * 0.7, size * 0.3),
		Vector2(0, size),
		Vector2(-size * 0.7, size * 0.3),
		Vector2(-size * 0.7, -size * 0.3),
	])
	
	if polygon:
		polygon.polygon = points
		polygon.color = color
	
	if outline:
		var outline_points := points.duplicate()
		outline_points.append(points[0])
		outline.points = outline_points
		outline.default_color = color.lightened(0.4)
		outline.width = 1.5


func _update_fade() -> void:
	if _lifetime_timer < 5.0:
		var alpha := _lifetime_timer / 5.0
		modulate.a = alpha


func set_attraction_target(target: Node2D) -> void:
	_target = target


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)


func _collect(collector: Node2D) -> void:
	collected.emit(resource_type, amount)
	
	if collector.has_method("add_resource"):
		collector.add_resource(resource_type, amount)
	
	queue_free()
