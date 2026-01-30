class_name AbilityShield
extends AbilityBase

@export var shield_strength: int = 50
@export var shield_color: Color = Color(0.3, 0.6, 1.0, 0.5)
@export var shield_radius: float = 40.0

var _shield_health: int = 0
var _shield_visual: Node2D


func _ready() -> void:
	super._ready()
	ability_id = "shield"
	cooldown = 8.0
	duration = 4.0


func _on_activate() -> void:
	_shield_health = shield_strength
	_create_shield_visual()
	
	if owner_enemy and owner_enemy.has_method("set_shield_active"):
		owner_enemy.set_shield_active(true)


func _on_deactivate() -> void:
	_remove_shield_visual()
	
	if owner_enemy and owner_enemy.has_method("set_shield_active"):
		owner_enemy.set_shield_active(false)


func absorb_damage(amount: int) -> int:
	if not _is_active or _shield_health <= 0:
		return amount
	
	var absorbed := mini(amount, _shield_health)
	_shield_health -= absorbed
	
	if _shield_health <= 0:
		force_end()
	else:
		_update_shield_visual()
	
	return amount - absorbed


func _create_shield_visual() -> void:
	if not owner_enemy:
		return
	
	_shield_visual = Node2D.new()
	_shield_visual.name = "ShieldVisual"
	_shield_visual.set_script(load("res://scenes/entities/enemies/abilities/shield_visual.gd"))
	_shield_visual.set("shield_color", shield_color)
	_shield_visual.set("shield_radius", shield_radius)
	owner_enemy.add_child(_shield_visual)


func _remove_shield_visual() -> void:
	if _shield_visual and is_instance_valid(_shield_visual):
		_shield_visual.queue_free()
		_shield_visual = null


func _update_shield_visual() -> void:
	if _shield_visual and is_instance_valid(_shield_visual):
		var alpha := float(_shield_health) / float(shield_strength) * 0.5
		_shield_visual.modulate.a = alpha
