class_name AbilityBase
extends Node

signal ability_started
signal ability_ended
signal cooldown_finished

@export var ability_id: String = "base"
@export var cooldown: float = 5.0
@export var duration: float = 0.0  ## 0 = instant

var _cooldown_timer: float = 0.0
var _active_timer: float = 0.0
var _is_active: bool = false
var _is_on_cooldown: bool = false

var owner_enemy: Node2D


func _ready() -> void:
	owner_enemy = get_parent().get_parent() if get_parent() else null


func _process(delta: float) -> void:
	if _is_on_cooldown:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0:
			_is_on_cooldown = false
			cooldown_finished.emit()
	
	if _is_active and duration > 0:
		_active_timer -= delta
		if _active_timer <= 0:
			end_ability()


func can_activate() -> bool:
	return not _is_active and not _is_on_cooldown


func activate() -> bool:
	if not can_activate():
		return false
	
	_is_active = true
	_active_timer = duration
	ability_started.emit()
	_on_activate()
	
	if duration <= 0:
		end_ability()
	
	return true


func end_ability() -> void:
	if not _is_active:
		return
	
	_is_active = false
	_is_on_cooldown = true
	_cooldown_timer = cooldown
	ability_ended.emit()
	_on_deactivate()


func force_end() -> void:
	if _is_active:
		end_ability()


func get_cooldown_percent() -> float:
	if not _is_on_cooldown:
		return 1.0
	return 1.0 - (_cooldown_timer / cooldown)


func is_active() -> bool:
	return _is_active


func _on_activate() -> void:
	pass


func _on_deactivate() -> void:
	pass
