class_name AbilityMultiShot
extends AbilityBase

@export var projectile_count: int = 5
@export var spread_angle: float = PI / 3 ## Total spread in radians
@export var damage_per_projectile: int = 5

var _projectile_scene: PackedScene


func _ready() -> void:
	super._ready()
	ability_id = "multi_shot"
	cooldown = 6.0
	duration = 0.0
	
	_projectile_scene = load("res://scenes/entities/projectiles/projectile.tscn")


func _on_activate() -> void:
	if not owner_enemy or not _projectile_scene:
		return
	
	var target := _get_target()
	if not target:
		return
	
	var base_direction := (target.global_position - owner_enemy.global_position).normalized()
	var base_angle := base_direction.angle()
	
	var start_angle := base_angle - spread_angle / 2
	var angle_step = spread_angle / (projectile_count - 1) if projectile_count > 1 else 0
	
	for i in range(projectile_count):
		var angle = start_angle + angle_step * i
		_spawn_projectile(angle)


func _spawn_projectile(angle: float) -> void:
	var projectile := _projectile_scene.instantiate()
	projectile.global_position = owner_enemy.global_position
	projectile.rotation = angle + PI / 2
	projectile.damage = damage_per_projectile
	var faction_id: int = owner_enemy.get_faction_id() if owner_enemy.has_method("get_faction_id") else -1
	projectile.set_owner_type(false, faction_id)
	
	get_tree().current_scene.add_child(projectile)


func _get_target() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
