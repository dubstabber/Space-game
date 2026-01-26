extends StaticBody2D

signal destroyed(position: Vector2, asteroid_type: String, size: float)

enum AsteroidSize {SMALL, MEDIUM, LARGE}

@export var asteroid_type: String = "iron"
@export var size_category: AsteroidSize = AsteroidSize.MEDIUM
@export var base_radius: float = 30.0
@export var health_per_size: int = 20
@export var rotation_speed: float = 0.5
@export var resource_drop_count: Vector2i = Vector2i(1, 3)

var _geometry_seed: int = 0
var _rotation_direction: float = 1.0

@onready var polygon: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	_setup_asteroid()
	health_component.died.connect(_on_died)
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _process(delta: float) -> void:
	rotation += rotation_speed * _rotation_direction * delta


func initialize(type: String, size: AsteroidSize, seed_value: int = 0) -> void:
	asteroid_type = type
	size_category = size
	_geometry_seed = seed_value if seed_value != 0 else randi()
	
	if is_inside_tree():
		_setup_asteroid()


func _setup_asteroid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _geometry_seed if _geometry_seed != 0 else randi()
	
	_rotation_direction = 1.0 if rng.randf() > 0.5 else -1.0
	rotation_speed = rng.randf_range(0.2, 0.8)
	
	var size_multiplier := _get_size_multiplier()
	var actual_radius := base_radius * size_multiplier
	
	var points := AsteroidGeometry.generate_asteroid_shape(actual_radius, 0.35, _geometry_seed)
	
	if polygon:
		polygon.polygon = points
		polygon.color = AsteroidGeometry.get_asteroid_color(asteroid_type)
	
	if outline:
		var outline_points := points.duplicate()
		outline_points.append(points[0])
		outline.points = outline_points
		outline.default_color = AsteroidGeometry.get_outline_color(asteroid_type)
		outline.width = 1.5
	
	if collision_shape:
		collision_shape.polygon = points
	
	if hitbox and hitbox.has_node("CollisionPolygon2D"):
		var hitbox_collision := hitbox.get_node("CollisionPolygon2D") as CollisionPolygon2D
		if hitbox_collision:
			hitbox_collision.polygon = points
	
	var max_hp := health_per_size * (int(size_category) + 1)
	if health_component:
		health_component.set_max_health(max_hp, true)


func _get_size_multiplier() -> float:
	match size_category:
		AsteroidSize.SMALL:
			return 0.5
		AsteroidSize.MEDIUM:
			return 1.0
		AsteroidSize.LARGE:
			return 1.8
		_:
			return 1.0


func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)


func _on_hitbox_area_entered(_area: Area2D) -> void:
	pass


func _on_died() -> void:
	var size_mult := _get_size_multiplier()
	destroyed.emit(global_position, asteroid_type, size_mult)
	_spawn_resource_pickups()
	_spawn_child_asteroids()
	queue_free()


func _spawn_resource_pickups() -> void:
	var pickup_scene := load("res://scenes/entities/pickups/resource_pickup.tscn") as PackedScene
	if pickup_scene == null:
		return
	
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	
	var count := rng.randi_range(resource_drop_count.x, resource_drop_count.y)
	count = int(count * (int(size_category) + 1) * 0.5)
	count = maxi(1, count)
	
	for i in range(count):
		var pickup := pickup_scene.instantiate()
		var offset := Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		pickup.global_position = global_position + offset
		pickup.initialize(_get_resource_type_from_asteroid())
		
		var parent := get_parent()
		if parent:
			parent.call_deferred("add_child", pickup)


func _get_resource_type_from_asteroid() -> ResourceData.ResourceType:
	match asteroid_type:
		"iron":
			return ResourceData.ResourceType.IRON
		"gold":
			return ResourceData.ResourceType.GOLD
		"crystal":
			return ResourceData.ResourceType.CRYSTAL
		"ice":
			return ResourceData.ResourceType.ICE
		_:
			return ResourceData.ResourceType.SCRAP


func _spawn_child_asteroids() -> void:
	if size_category == AsteroidSize.SMALL:
		return
	
	var asteroid_scene := load("res://scenes/entities/asteroids/asteroid.tscn") as PackedScene
	if asteroid_scene == null:
		return
	
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position) + 1
	
	var child_count := rng.randi_range(2, 3)
	var child_size: AsteroidSize
	
	match size_category:
		AsteroidSize.LARGE:
			child_size = AsteroidSize.MEDIUM
		AsteroidSize.MEDIUM:
			child_size = AsteroidSize.SMALL
		_:
			return
	
	for i in range(child_count):
		var child := asteroid_scene.instantiate()
		var angle := (TAU / child_count) * i + rng.randf_range(-0.3, 0.3)
		var offset := Vector2(cos(angle), sin(angle)) * (base_radius * 0.5)
		child.global_position = global_position + offset
		child.initialize(asteroid_type, child_size, rng.randi())
		
		var parent := get_parent()
		if parent:
			parent.call_deferred("add_child", child)
