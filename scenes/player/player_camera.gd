extends Camera2D

@export var follow_speed: float = 5.0
@export var look_ahead_distance: float = 100.0
@export var look_ahead_speed: float = 3.0

var _target: Node2D = null
var _look_ahead_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	make_current()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	
	var target_velocity := Vector2.ZERO
	if _target is CharacterBody2D:
		target_velocity = (_target as CharacterBody2D).velocity
	
	var desired_look_ahead := target_velocity.normalized() * look_ahead_distance
	_look_ahead_offset = _look_ahead_offset.lerp(desired_look_ahead, look_ahead_speed * delta)
	
	var target_position := _target.global_position + _look_ahead_offset
	global_position = global_position.lerp(target_position, follow_speed * delta)


func set_target(target: Node2D) -> void:
	_target = target
	if _target:
		global_position = _target.global_position
