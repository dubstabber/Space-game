class_name AbilityDash
extends AbilityBase

@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.3
@export var invincible_during_dash: bool = true

var _dash_direction: Vector2 = Vector2.ZERO
var _original_invincibility: bool = false


func _ready() -> void:
	super._ready()
	ability_id = "dash"
	cooldown = 4.0
	duration = dash_duration


func _process(delta: float) -> void:
	super._process(delta)
	
	if _is_active and owner_enemy:
		owner_enemy.global_position += _dash_direction * dash_speed * delta


func activate_toward(target_position: Vector2) -> bool:
	if not can_activate() or not owner_enemy:
		return false
	
	_dash_direction = (target_position - owner_enemy.global_position).normalized()
	return activate()


func activate_away_from(threat_position: Vector2) -> bool:
	if not can_activate() or not owner_enemy:
		return false
	
	_dash_direction = (owner_enemy.global_position - threat_position).normalized()
	return activate()


func _on_activate() -> void:
	if owner_enemy and owner_enemy.has_node("HealthComponent"):
		var health_comp := owner_enemy.get_node("HealthComponent") as HealthComponent
		if health_comp and invincible_during_dash:
			_original_invincibility = health_comp.invincible
			health_comp.invincible = true
	
	_create_dash_trail()


func _on_deactivate() -> void:
	_dash_direction = Vector2.ZERO
	
	if owner_enemy and owner_enemy.has_node("HealthComponent"):
		var health_comp := owner_enemy.get_node("HealthComponent") as HealthComponent
		if health_comp and invincible_during_dash:
			health_comp.invincible = _original_invincibility


func _create_dash_trail() -> void:
	if not owner_enemy:
		return
	
	var trail := Node2D.new()
	trail.name = "DashTrail"
	trail.global_position = owner_enemy.global_position
	trail.set_script(load("res://scenes/entities/enemies/abilities/dash_trail.gd"))
	trail.set("trail_color", owner_enemy.get("faction_data").glow_color if owner_enemy.get("faction_data") else Color.WHITE)
	get_tree().current_scene.add_child(trail)
