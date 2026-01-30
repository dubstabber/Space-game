class_name EnemyBase
extends CharacterBody2D

signal died(enemy: EnemyBase)
signal health_changed(current: int, maximum: int)

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE,
	STRAFE
}

@export var enemy_data: EnemyData
@export var faction_data: FactionData

var current_state: AIState = AIState.IDLE
var target: Node2D = null
var _shoot_timer: float = 0.0
var _state_timer: float = 0.0
var _strafe_direction: float = 1.0
var _patrol_direction: Vector2 = Vector2.ZERO
var _geometry_seed: int = 0
var _shield_active: bool = false
var _abilities: Array[AbilityBase] = []

@onready var hull: Polygon2D = $Hull
@onready var outline: Line2D = $Outline
@onready var details: Line2D = $Details
@onready var collision_shape: CollisionPolygon2D = $CollisionShape
@onready var health_component: HealthComponent = $HealthComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox
@onready var ability_container: Node = $Abilities

const Projectile = preload("res://scenes/entities/projectiles/projectile.tscn")


func _ready() -> void:
	add_to_group("enemies")
	_setup_from_data()
	_setup_geometry()
	_setup_abilities()
	_connect_signals()
	_start_patrol()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
	
	_update_state(delta)
	_update_behavior(delta)
	_update_shoot_timer(delta)
	_try_use_abilities()
	
	move_and_slide()
	_update_rotation(delta)


func initialize(data: EnemyData, faction: FactionData, seed_value: int = 0) -> void:
	enemy_data = data
	faction_data = faction
	_geometry_seed = seed_value if seed_value != 0 else randi()
	
	if is_inside_tree():
		_setup_from_data()
		_setup_geometry()
		_setup_abilities()


func _setup_from_data() -> void:
	if not enemy_data or not faction_data:
		return
	
	var hp := int(enemy_data.max_health * faction_data.health_multiplier)
	if health_component:
		health_component.set_max_health(hp, true)
	
	if detection_area and detection_area.has_node("CollisionShape2D"):
		var detection_shape := detection_area.get_node("CollisionShape2D") as CollisionShape2D
		if detection_shape and detection_shape.shape is CircleShape2D:
			(detection_shape.shape as CircleShape2D).radius = enemy_data.detection_range


func _setup_geometry() -> void:
	if not enemy_data or not faction_data:
		return
	
	var shape_data := EnemyGeometry.generate_shape_for_enemy(
		enemy_data.enemy_type,
		faction_data.faction_id,
		enemy_data.ship_size,
		_geometry_seed
	)
	
	var hull_points: PackedVector2Array = shape_data.get("hull", PackedVector2Array())
	var detail_points: PackedVector2Array = shape_data.get("details", PackedVector2Array())
	
	if hull and hull_points.size() > 0:
		hull.polygon = hull_points
		hull.color = faction_data.primary_color
	
	if outline and hull_points.size() > 0:
		outline.points = EnemyGeometry.create_outline_from_hull(hull_points)
		outline.default_color = faction_data.glow_color
		outline.width = 1.5
	
	if details and detail_points.size() > 0:
		details.points = detail_points
		details.default_color = faction_data.secondary_color
		details.width = 1.0
	
	if collision_shape and hull_points.size() > 0:
		collision_shape.polygon = hull_points
	
	if hitbox and hitbox.has_node("CollisionPolygon2D"):
		var hitbox_collision := hitbox.get_node("CollisionPolygon2D") as CollisionPolygon2D
		if hitbox_collision and hull_points.size() > 0:
			hitbox_collision.polygon = hull_points


func _setup_abilities() -> void:
	if not enemy_data or not ability_container:
		return
	
	for ability_id in enemy_data.abilities:
		var ability := _create_ability(ability_id)
		if ability:
			ability_container.add_child(ability)
			_abilities.append(ability)


func _create_ability(ability_id: String) -> AbilityBase:
	match ability_id:
		"shield":
			var ability := AbilityShield.new()
			if faction_data:
				ability.shield_color = faction_data.glow_color
				ability.shield_color.a = 0.5
			return ability
		"dash":
			return AbilityDash.new()
		"multi_shot":
			return AbilityMultiShot.new()
		_:
			return null


func _connect_signals() -> void:
	if health_component:
		health_component.died.connect(_on_died)
		health_component.health_changed.connect(_on_health_changed)
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)


func _start_patrol() -> void:
	current_state = AIState.PATROL
	_patrol_direction = Vector2.from_angle(randf() * TAU)
	_state_timer = randf_range(2.0, 5.0)


func _update_state(delta: float) -> void:
	_state_timer -= delta
	
	match current_state:
		AIState.IDLE:
			if _state_timer <= 0:
				_start_patrol()
		
		AIState.PATROL:
			if target:
				current_state = AIState.CHASE
			elif _state_timer <= 0:
				_patrol_direction = Vector2.from_angle(randf() * TAU)
				_state_timer = randf_range(2.0, 5.0)
		
		AIState.CHASE:
			if not target:
				_start_patrol()
			elif _get_distance_to_target() <= enemy_data.attack_range:
				current_state = AIState.ATTACK
				if enemy_data.strafe_enabled:
					_strafe_direction = 1.0 if randf() > 0.5 else -1.0
		
		AIState.ATTACK:
			if not target:
				_start_patrol()
			elif _get_distance_to_target() > enemy_data.attack_range * 1.2:
				current_state = AIState.CHASE
			elif enemy_data.strafe_enabled and _state_timer <= 0:
				current_state = AIState.STRAFE
				_state_timer = randf_range(1.0, 2.0)
				_strafe_direction *= -1.0
			
			_check_flee_condition()
		
		AIState.STRAFE:
			if not target:
				_start_patrol()
			elif _state_timer <= 0:
				current_state = AIState.ATTACK
				_state_timer = randf_range(1.5, 3.0)
			
			_check_flee_condition()
		
		AIState.FLEE:
			if not target or _get_distance_to_target() > enemy_data.detection_range:
				_start_patrol()


func _check_flee_condition() -> void:
	if enemy_data.flee_health_percent > 0 and health_component:
		if health_component.get_health_percent() <= enemy_data.flee_health_percent:
			current_state = AIState.FLEE


func _update_behavior(delta: float) -> void:
	if not enemy_data or not faction_data:
		return
	
	var speed := enemy_data.move_speed * faction_data.speed_multiplier
	
	match current_state:
		AIState.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
		
		AIState.PATROL:
			velocity = _patrol_direction * speed * 0.5
		
		AIState.CHASE:
			if target:
				var direction := (target.global_position - global_position).normalized()
				velocity = direction * speed
		
		AIState.ATTACK:
			if target:
				var distance := _get_distance_to_target()
				var preferred := faction_data.preferred_range
				
				if distance < preferred * 0.8:
					var direction := (global_position - target.global_position).normalized()
					velocity = direction * speed * 0.5
				elif distance > preferred * 1.2:
					var direction := (target.global_position - global_position).normalized()
					velocity = direction * speed * 0.5
				else:
					velocity = velocity.lerp(Vector2.ZERO, 0.1)
				
				_try_shoot()
		
		AIState.STRAFE:
			if target:
				var to_target := target.global_position - global_position
				var strafe_dir := to_target.rotated(PI / 2).normalized() * _strafe_direction
				velocity = strafe_dir * speed * 0.7
				_try_shoot()
		
		AIState.FLEE:
			if target:
				var direction := (global_position - target.global_position).normalized()
				velocity = direction * speed * 1.2


func _update_rotation(delta: float) -> void:
	if not enemy_data:
		return
	
	var target_rotation: float
	
	if target and current_state in [AIState.CHASE, AIState.ATTACK, AIState.STRAFE]:
		var direction := target.global_position - global_position
		target_rotation = direction.angle() + PI / 2
	elif velocity.length_squared() > 10:
		target_rotation = velocity.angle() + PI / 2
	else:
		return
	
	rotation = lerp_angle(rotation, target_rotation, enemy_data.rotation_speed * delta)


func _update_shoot_timer(delta: float) -> void:
	if _shoot_timer > 0:
		_shoot_timer -= delta


func _try_shoot() -> void:
	if not enemy_data or not faction_data:
		return
	if _shoot_timer > 0 or not target:
		return
	
	var cooldown := enemy_data.attack_cooldown / faction_data.aggression_level
	_shoot_timer = cooldown
	
	_spawn_projectile()


func _spawn_projectile() -> void:
	if not Projectile:
		return
	
	var projectile := Projectile.instantiate()
	projectile.global_position = global_position
	projectile.rotation = rotation
	projectile.damage = int(enemy_data.attack_damage * faction_data.damage_multiplier)
	projectile.speed = enemy_data.projectile_speed
	projectile.set_owner_type(false, get_faction_id())
	
	if faction_data:
		projectile.modulate = faction_data.glow_color
	
	get_tree().current_scene.add_child(projectile)


func _try_use_abilities() -> void:
	if not target:
		return
	
	for ability in _abilities:
		if not ability.can_activate():
			continue
		
		match ability.ability_id:
			"shield":
				if health_component and health_component.get_health_percent() < 0.5:
					ability.activate()
			"dash":
				var dash_ability := ability as AbilityDash
				if dash_ability and _get_distance_to_target() > enemy_data.attack_range * 1.5:
					dash_ability.activate_toward(target.global_position)
				elif dash_ability and health_component and health_component.get_health_percent() < 0.3:
					dash_ability.activate_away_from(target.global_position)
			"multi_shot":
				if _get_distance_to_target() <= enemy_data.attack_range * 0.8:
					ability.activate()


func _get_distance_to_target() -> float:
	if not target:
		return INF
	return global_position.distance_to(target.global_position)


func take_damage(amount: int) -> void:
	if _shield_active:
		for ability in _abilities:
			if ability is AbilityShield:
				amount = ability.absorb_damage(amount)
				break
	
	if amount > 0 and health_component:
		health_component.take_damage(amount)


func set_shield_active(active: bool) -> void:
	_shield_active = active


func _on_died() -> void:
	died.emit(self)
	_drop_rewards()
	queue_free()


func _on_health_changed(current: int, maximum: int) -> void:
	health_changed.emit(current, maximum)


func _on_detection_body_entered(body: Node2D) -> void:
	if not target:
		if body.is_in_group("player"):
			target = body
		elif _is_enemy_target(body):
			target = body


func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		_find_new_target()


func _is_enemy_target(body: Node2D) -> bool:
	if not body.is_in_group("enemies"):
		return false
	if not body.has_method("get_faction_id"):
		return false
	var other_faction_id: int = body.get_faction_id()
	var my_faction_id := get_faction_id()
	return other_faction_id != my_faction_id


func get_faction_id() -> int:
	if faction_data:
		return faction_data.faction_id
	return -1


func _find_new_target() -> void:
	if not detection_area:
		return
	for body in detection_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("player"):
			target = body
			return
		elif _is_enemy_target(body):
			target = body
			return


func _drop_rewards() -> void:
	if not enemy_data:
		return
	
	if randf() <= enemy_data.drop_chance:
		pass
