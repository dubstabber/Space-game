class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var invincible: bool = false

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int, source: Node = null) -> void:
	if invincible or current_health <= 0:
		return
	
	current_health = maxi(0, current_health - amount)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()


func heal(amount: int) -> void:
	if current_health <= 0:
		return
	
	var old_health := current_health
	current_health = mini(max_health, current_health + amount)
	
	var actual_heal := current_health - old_health
	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)


func set_max_health(value: int, heal_to_full: bool = false) -> void:
	max_health = value
	if heal_to_full:
		current_health = max_health
	else:
		current_health = mini(current_health, max_health)
	health_changed.emit(current_health, max_health)


func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


func is_alive() -> bool:
	return current_health > 0


func is_full_health() -> bool:
	return current_health >= max_health
