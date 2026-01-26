class_name AsteroidSpawner
extends Node2D

signal asteroid_spawned(asteroid: Node2D)
signal asteroid_destroyed(position: Vector2, type: String)

@export var spawn_radius: float = 2000.0
@export var despawn_radius: float = 3000.0
@export var min_asteroid_distance: float = 100.0
@export var max_asteroids: int = 50
@export var spawn_check_interval: float = 1.0
@export var density_multiplier: float = 1.0

var _target: Node2D = null
var _spawn_timer: float = 0.0
var _asteroids: Array[Node2D] = []
var _rng: RandomNumberGenerator

const AsteroidScene := preload("res://scenes/entities/asteroids/asteroid.tscn")


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_initialize_seed()


func _process(delta: float) -> void:
	if _target == null:
		return
	
	_spawn_timer += delta
	if _spawn_timer >= spawn_check_interval:
		_spawn_timer = 0.0
		_manage_asteroids()


func set_target(target: Node2D) -> void:
	_target = target


func set_density(density: float) -> void:
	density_multiplier = density


func _initialize_seed() -> void:
	var map_id := MapManager.current_map_id
	if map_id.is_empty():
		map_id = "default_space"
	var seed_value := SeedManager.get_entity_seed(map_id, "asteroid_spawner", 0)
	_rng.seed = seed_value


func _manage_asteroids() -> void:
	_cleanup_despawned()
	_spawn_new_asteroids()


func _cleanup_despawned() -> void:
	if _target == null:
		return
	
	var i := _asteroids.size() - 1
	while i >= 0:
		var asteroid := _asteroids[i]
		var should_remove := false
		
		if not is_instance_valid(asteroid):
			should_remove = true
		else:
			var distance := asteroid.global_position.distance_to(_target.global_position)
			if distance > despawn_radius:
				asteroid.queue_free()
				should_remove = true
		
		if should_remove:
			_asteroids.remove_at(i)
		
		i -= 1


func _spawn_new_asteroids() -> void:
	if _target == null:
		return
	
	var target_count := int(max_asteroids * density_multiplier)
	var spawn_count := target_count - _asteroids.size()
	
	if spawn_count <= 0:
		return
	
	for i in range(spawn_count):
		var spawn_pos := _get_spawn_position()
		if spawn_pos == Vector2.INF:
			continue
		
		var asteroid := _create_asteroid(spawn_pos)
		if asteroid:
			_asteroids.append(asteroid)
			asteroid_spawned.emit(asteroid)


func _get_spawn_position() -> Vector2:
	if _target == null:
		return Vector2.INF
	
	var attempts := 10
	
	for _i in range(attempts):
		var angle := _rng.randf() * TAU
		var distance := _rng.randf_range(spawn_radius * 0.5, spawn_radius)
		var pos := _target.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		if _is_position_valid(pos):
			return pos
	
	return Vector2.INF


func _is_position_valid(pos: Vector2) -> bool:
	for asteroid in _asteroids:
		if not is_instance_valid(asteroid):
			continue
		if asteroid.global_position.distance_to(pos) < min_asteroid_distance:
			return false
	return true


func _create_asteroid(pos: Vector2) -> Node2D:
	var asteroid := AsteroidScene.instantiate()
	asteroid.global_position = pos
	
	var asteroid_type := _get_random_asteroid_type()
	var size := _get_random_size()
	var seed_value := _rng.randi()
	
	asteroid.initialize(asteroid_type, size, seed_value)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	
	add_child(asteroid)
	return asteroid


func _get_random_asteroid_type() -> String:
	var roll := _rng.randf()
	
	if roll < 0.6:
		return "iron"
	elif roll < 0.8:
		return "ice"
	elif roll < 0.92:
		return "gold"
	else:
		return "crystal"


func _get_random_size() -> int:
	var roll := _rng.randf()
	
	if roll < 0.5:
		return 1
	elif roll < 0.85:
		return 0
	else:
		return 2


func _on_asteroid_destroyed(pos: Vector2, asteroid_type: String, _size: float) -> void:
	asteroid_destroyed.emit(pos, asteroid_type)


func clear_all_asteroids() -> void:
	for asteroid in _asteroids:
		if is_instance_valid(asteroid):
			asteroid.queue_free()
	_asteroids.clear()


func get_asteroid_count() -> int:
	return _asteroids.size()


func spawn_asteroid_at(pos: Vector2, asteroid_type: String, size: int) -> Node2D:
	var asteroid := AsteroidScene.instantiate()
	asteroid.global_position = pos
	asteroid.initialize(asteroid_type, size, _rng.randi())
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	
	add_child(asteroid)
	_asteroids.append(asteroid)
	asteroid_spawned.emit(asteroid)
	
	return asteroid
