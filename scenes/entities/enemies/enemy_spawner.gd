class_name EnemySpawner
extends Node2D

signal enemy_spawned(enemy: Node2D)
signal wave_completed(wave_number: int)
signal boss_spawned(boss: Node2D)

@export var enabled: bool = true
@export var spawn_radius_min: float = 800.0
@export var spawn_radius_max: float = 1200.0
@export var max_enemies: int = 10
@export var spawn_interval: float = 5.0
@export var difficulty_scale: float = 1.0

@export_group("Faction Settings")
@export var allowed_factions: Array[FactionData] = []
@export var faction_weights: Array[float] = []

@export_group("Enemy Type Weights")
@export var scout_weight: float = 0.5
@export var fighter_weight: float = 0.35
@export var heavy_weight: float = 0.15

@export_group("Boss Settings")
@export var boss_enabled: bool = false
@export var boss_spawn_interval: float = 300.0
@export var boss_data: EnemyData

var _spawn_timer: float = 0.0
var _boss_timer: float = 0.0
var _active_enemies: Array[Node2D] = []
var _player: Node2D = null

var _scout_data: EnemyData
var _fighter_data: EnemyData
var _heavy_data: EnemyData

const EnemyBaseScene = preload("res://scenes/entities/enemies/enemy_base.tscn")
const BossBaseScene = preload("res://scenes/entities/enemies/boss_base.tscn")


func _ready() -> void:
	_load_enemy_data()
	_spawn_timer = spawn_interval * 0.5


func _process(delta: float) -> void:
	if not enabled:
		return
	
	_cleanup_dead_enemies()
	_find_player()
	
	_spawn_timer -= delta
	if _spawn_timer <= 0 and _can_spawn():
		_spawn_enemy_group()
		_spawn_timer = spawn_interval / difficulty_scale
	
	if boss_enabled:
		_boss_timer -= delta
		if _boss_timer <= 0:
			_spawn_boss()
			_boss_timer = boss_spawn_interval


func _load_enemy_data() -> void:
	_scout_data = load("res://resources/enemies/enemy_scout.tres") as EnemyData
	_fighter_data = load("res://resources/enemies/enemy_fighter.tres") as EnemyData
	_heavy_data = load("res://resources/enemies/enemy_heavy.tres") as EnemyData


func _find_player() -> void:
	if _player and is_instance_valid(_player):
		return
	
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node2D


func _cleanup_dead_enemies() -> void:
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e))


func _can_spawn() -> bool:
	return _player != null and _active_enemies.size() < max_enemies


func _spawn_enemy_group() -> void:
	if allowed_factions.is_empty():
		return
	
	var faction := _select_faction()
	if not faction:
		return
	
	var group_size := randi_range(faction.min_group_size, faction.max_group_size)
	var base_position := _get_spawn_position()
	
	for i in range(group_size):
		if _active_enemies.size() >= max_enemies:
			break
		
		var offset := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var spawn_pos := base_position + offset
		
		var enemy_data := _select_enemy_type()
		var enemy := _spawn_single_enemy(enemy_data, faction, spawn_pos)
		
		if enemy:
			_active_enemies.append(enemy)
			enemy_spawned.emit(enemy)


func _select_faction() -> FactionData:
	if allowed_factions.is_empty():
		return null
	
	var total_weight := 0.0
	for i in range(allowed_factions.size()):
		var weight := faction_weights[i] if i < faction_weights.size() else 1.0
		total_weight += weight
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	
	for i in range(allowed_factions.size()):
		var weight := faction_weights[i] if i < faction_weights.size() else 1.0
		cumulative += weight
		if roll <= cumulative:
			return allowed_factions[i]
	
	return allowed_factions[0]


func _select_enemy_type() -> EnemyData:
	var total := scout_weight + fighter_weight + heavy_weight
	var roll := randf() * total
	
	if roll < scout_weight:
		return _scout_data
	elif roll < scout_weight + fighter_weight:
		return _fighter_data
	else:
		return _heavy_data


func _get_spawn_position() -> Vector2:
	if not _player:
		return global_position
	
	var angle := randf() * TAU
	var distance := randf_range(spawn_radius_min, spawn_radius_max)
	return _player.global_position + Vector2(cos(angle), sin(angle)) * distance


func _spawn_single_enemy(enemy_data: EnemyData, faction: FactionData, pos: Vector2) -> Node2D:
	if not EnemyBaseScene or not enemy_data or not faction:
		return null
	
	var enemy := EnemyBaseScene.instantiate() as EnemyBase
	if not enemy:
		return null
	
	enemy.global_position = pos
	enemy.initialize(enemy_data, faction, randi())
	enemy.died.connect(_on_enemy_died.bind(enemy))
	
	get_tree().current_scene.add_child(enemy)
	return enemy


func _spawn_boss() -> void:
	if not boss_enabled or not boss_data or allowed_factions.is_empty():
		return
	
	var faction := _select_faction()
	if not faction:
		return
	
	var spawn_pos := _get_spawn_position()
	spawn_pos = spawn_pos.normalized() * spawn_radius_max * 1.5 + _player.global_position
	
	var boss := BossBaseScene.instantiate() as BossBase
	if not boss:
		return
	
	boss.global_position = spawn_pos
	boss.initialize(boss_data, faction, randi())
	boss.died.connect(_on_boss_died.bind(boss))
	
	get_tree().current_scene.add_child(boss)
	_active_enemies.append(boss)
	boss_spawned.emit(boss)


func _on_enemy_died(_emitter: Node2D, enemy: Node2D) -> void:
	_active_enemies.erase(enemy)


func _on_boss_died(_emitter: Node2D, boss: Node2D) -> void:
	_active_enemies.erase(boss)


func set_difficulty(scale: float) -> void:
	difficulty_scale = clampf(scale, 0.5, 3.0)


func force_spawn_enemy(enemy_type: EnemyData.EnemyType, faction_index: int = 0) -> Node2D:
	if allowed_factions.is_empty():
		return null
	
	var faction := allowed_factions[clampi(faction_index, 0, allowed_factions.size() - 1)]
	var enemy_data: EnemyData
	
	match enemy_type:
		EnemyData.EnemyType.SCOUT:
			enemy_data = _scout_data
		EnemyData.EnemyType.FIGHTER:
			enemy_data = _fighter_data
		EnemyData.EnemyType.HEAVY:
			enemy_data = _heavy_data
		_:
			enemy_data = _fighter_data
	
	var spawn_pos := _get_spawn_position()
	var enemy := _spawn_single_enemy(enemy_data, faction, spawn_pos)
	
	if enemy:
		_active_enemies.append(enemy)
		enemy_spawned.emit(enemy)
	
	return enemy


func force_spawn_boss() -> Node2D:
	if not boss_data or allowed_factions.is_empty():
		return null
	
	_spawn_boss()
	return _active_enemies.back() if not _active_enemies.is_empty() else null


func get_active_enemy_count() -> int:
	return _active_enemies.size()


func clear_all_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()
