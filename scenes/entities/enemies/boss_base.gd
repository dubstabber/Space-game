class_name BossBase
extends CharacterBody2D

signal phase_changed(new_phase: int, total_phases: int)
signal died(boss: BossBase)
signal health_changed(current: int, maximum: int)

enum BossState {
	IDLE,
	CHASE,
	ATTACK,
	SPECIAL_ATTACK,
	TRANSITION
}

@export var enemy_data: EnemyData
@export var faction_data: FactionData
@export var total_phases: int = 3
@export var phase_health_thresholds: Array[float] = [0.66, 0.33, 0.0]

var current_phase: int = 1
var current_state: BossState = BossState.IDLE
var target: Node2D = null
var _shoot_timer: float = 0.0
var _special_timer: float = 0.0
var _state_timer: float = 0.0
var _geometry_seed: int = 0
var _transitioning: bool = false
var _abilities: Array[AbilityBase] = []
var _turret_positions: Array[Vector2] = []

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
	add_to_group("bosses")
	_setup_from_data()
	_setup_geometry()
	_setup_phase_abilities()
	_connect_signals()


func _physics_process(delta: float) -> void:
	if _transitioning:
		return
	
	if not is_instance_valid(target):
		target = _find_player()
	
	_update_state(delta)
	_update_behavior(delta)
	_update_shoot_timer(delta)
	_update_special_timer(delta)
	
	move_and_slide()
	_update_rotation(delta)


func initialize(data: EnemyData, faction: FactionData, seed_value: int = 0) -> void:
	enemy_data = data
	faction_data = faction
	_geometry_seed = seed_value if seed_value != 0 else randi()
	
	if is_inside_tree():
		_setup_from_data()
		_setup_geometry()
		_setup_phase_abilities()


func _setup_from_data() -> void:
	if not enemy_data or not faction_data:
		return
	
	var hp := int(enemy_data.max_health * faction_data.health_multiplier * 3.0)
	if health_component:
		health_component.set_max_health(hp, true)
	
	if detection_area and detection_area.has_node("CollisionShape2D"):
		var detection_shape := detection_area.get_node("CollisionShape2D") as CollisionShape2D
		if detection_shape and detection_shape.shape is CircleShape2D:
			(detection_shape.shape as CircleShape2D).radius = enemy_data.detection_range * 1.5


func _setup_geometry() -> void:
	if not enemy_data or not faction_data:
		return
	
	var boss_size := enemy_data.ship_size * 2.5
	var shape_data := EnemyGeometry.generate_boss_shape(boss_size, current_phase - 1, _geometry_seed)
	
	var hull_points: PackedVector2Array = shape_data.get("hull", PackedVector2Array())
	var detail_points: PackedVector2Array = shape_data.get("details", PackedVector2Array())
	_turret_positions = shape_data.get("turrets", [])
	
	if hull and hull_points.size() > 0:
		hull.polygon = hull_points
		hull.color = faction_data.primary_color
	
	if outline and hull_points.size() > 0:
		outline.points = EnemyGeometry.create_outline_from_hull(hull_points)
		outline.default_color = faction_data.glow_color
		outline.width = 2.5
	
	if details and detail_points.size() > 0:
		details.points = detail_points
		details.default_color = faction_data.secondary_color
		details.width = 1.5
	
	if collision_shape and hull_points.size() > 0:
		collision_shape.polygon = hull_points
	
	if hitbox and hitbox.has_node("CollisionPolygon2D"):
		var hitbox_collision := hitbox.get_node("CollisionPolygon2D") as CollisionPolygon2D
		if hitbox_collision and hull_points.size() > 0:
			hitbox_collision.polygon = hull_points


func _setup_phase_abilities() -> void:
	for child in ability_container.get_children():
		child.queue_free()
	_abilities.clear()
	
	var shield := AbilityShield.new()
	shield.shield_strength = 100 * current_phase
	shield.cooldown = 10.0 - current_phase
	if faction_data:
		shield.shield_color = faction_data.glow_color
		shield.shield_color.a = 0.5
	ability_container.add_child(shield)
	_abilities.append(shield)
	
	if current_phase >= 2:
		var multi_shot := AbilityMultiShot.new()
		multi_shot.projectile_count = 5 + current_phase * 2
		multi_shot.cooldown = 4.0
		ability_container.add_child(multi_shot)
		_abilities.append(multi_shot)
	
	if current_phase >= 3:
		var dash := AbilityDash.new()
		dash.dash_speed = 600.0
		dash.cooldown = 6.0
		ability_container.add_child(dash)
		_abilities.append(dash)


func _connect_signals() -> void:
	if health_component:
		health_component.died.connect(_on_died)
		health_component.health_changed.connect(_on_health_changed)
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)


func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null


func _update_state(delta: float) -> void:
	_state_timer -= delta
	
	match current_state:
		BossState.IDLE:
			if target:
				current_state = BossState.CHASE
		
		BossState.CHASE:
			if not target:
				current_state = BossState.IDLE
			elif _get_distance_to_target() <= enemy_data.attack_range * 1.5:
				current_state = BossState.ATTACK
				_state_timer = randf_range(3.0, 6.0)
		
		BossState.ATTACK:
			if not target:
				current_state = BossState.IDLE
			elif _get_distance_to_target() > enemy_data.attack_range * 2.0:
				current_state = BossState.CHASE
			elif _state_timer <= 0 and _special_timer <= 0:
				current_state = BossState.SPECIAL_ATTACK
				_state_timer = 2.0
		
		BossState.SPECIAL_ATTACK:
			if _state_timer <= 0:
				_perform_special_attack()
				current_state = BossState.ATTACK
				_state_timer = randf_range(4.0, 8.0) / current_phase
				_special_timer = 5.0 / current_phase


func _update_behavior(delta: float) -> void:
	if not enemy_data or not faction_data:
		return
	
	var speed := enemy_data.move_speed * faction_data.speed_multiplier * 0.7
	
	match current_state:
		BossState.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
		
		BossState.CHASE:
			if target:
				var direction := (target.global_position - global_position).normalized()
				velocity = direction * speed
		
		BossState.ATTACK:
			if target:
				var distance := _get_distance_to_target()
				var preferred := faction_data.preferred_range * 1.5
				
				if distance < preferred * 0.7:
					var direction := (global_position - target.global_position).normalized()
					velocity = direction * speed * 0.4
				elif distance > preferred * 1.3:
					var direction := (target.global_position - global_position).normalized()
					velocity = direction * speed * 0.4
				else:
					var orbit := (target.global_position - global_position).rotated(PI / 2).normalized()
					velocity = orbit * speed * 0.3
				
				_try_shoot()
		
		BossState.SPECIAL_ATTACK:
			velocity = velocity.lerp(Vector2.ZERO, 0.2)


func _update_rotation(delta: float) -> void:
	if not enemy_data or not target:
		return
	
	var direction := target.global_position - global_position
	var target_rotation := direction.angle() + PI / 2
	rotation = lerp_angle(rotation, target_rotation, enemy_data.rotation_speed * 0.5 * delta)


func _update_shoot_timer(delta: float) -> void:
	if _shoot_timer > 0:
		_shoot_timer -= delta


func _update_special_timer(delta: float) -> void:
	if _special_timer > 0:
		_special_timer -= delta


func _try_shoot() -> void:
	if not enemy_data or not faction_data:
		return
	if _shoot_timer > 0 or not target:
		return
	
	var cooldown := enemy_data.attack_cooldown / (faction_data.aggression_level * current_phase * 0.5)
	_shoot_timer = cooldown
	
	_spawn_main_projectile()
	
	if _turret_positions.size() > 0:
		_spawn_turret_projectiles()


func _spawn_main_projectile() -> void:
	if not Projectile:
		return
	
	var projectile := Projectile.instantiate()
	projectile.global_position = global_position
	projectile.rotation = rotation
	projectile.damage = int(enemy_data.attack_damage * faction_data.damage_multiplier * 1.5)
	projectile.speed = enemy_data.projectile_speed
	projectile.set_owner_type(false, get_faction_id())
	
	if faction_data:
		projectile.modulate = faction_data.glow_color
	
	get_tree().current_scene.add_child(projectile)


func _spawn_turret_projectiles() -> void:
	if not Projectile or not target:
		return
	
	for turret_pos in _turret_positions:
		var world_pos := global_position + turret_pos.rotated(rotation)
		var direction := (target.global_position - world_pos).normalized()
		
		var projectile := Projectile.instantiate()
		projectile.global_position = world_pos
		projectile.rotation = direction.angle() + PI / 2
		projectile.damage = int(enemy_data.attack_damage * faction_data.damage_multiplier * 0.5)
		projectile.speed = enemy_data.projectile_speed * 0.8
		projectile.set_owner_type(false, get_faction_id())
		
		if faction_data:
			projectile.modulate = faction_data.glow_color
			projectile.modulate.a = 0.8
		
		get_tree().current_scene.add_child(projectile)


func _perform_special_attack() -> void:
	match current_phase:
		1:
			_spiral_attack()
		2:
			_burst_attack()
		3:
			_barrage_attack()


func _spiral_attack() -> void:
	if not Projectile:
		return
	
	var projectile_count := 12
	for i in range(projectile_count):
		var angle := (TAU / projectile_count) * i
		var projectile := Projectile.instantiate()
		projectile.global_position = global_position
		projectile.rotation = angle + PI / 2
		projectile.damage = int(enemy_data.attack_damage * faction_data.damage_multiplier)
		projectile.speed = enemy_data.projectile_speed * 0.6
		projectile.set_owner_type(false, get_faction_id())
		
		if faction_data:
			projectile.modulate = faction_data.glow_color
		
		get_tree().current_scene.add_child(projectile)


func _burst_attack() -> void:
	for ability in _abilities:
		if ability is AbilityMultiShot and ability.can_activate():
			ability.activate()
			break


func _barrage_attack() -> void:
	_spiral_attack()
	
	for ability in _abilities:
		if ability is AbilityMultiShot and ability.can_activate():
			ability.activate()
			break


func _check_phase_transition() -> void:
	if not health_component or _transitioning:
		return
	
	var health_percent := health_component.get_health_percent()
	
	for i in range(phase_health_thresholds.size()):
		var phase := i + 1
		if phase > current_phase and health_percent <= phase_health_thresholds[i]:
			_transition_to_phase(phase)
			break


func _transition_to_phase(new_phase: int) -> void:
	if new_phase <= current_phase or new_phase > total_phases:
		return
	
	_transitioning = true
	current_phase = new_phase
	phase_changed.emit(current_phase, total_phases)
	
	_setup_geometry()
	_setup_phase_abilities()
	
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE * 2.0, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_callback(func(): _transitioning = false)


func _get_distance_to_target() -> float:
	if not target:
		return INF
	return global_position.distance_to(target.global_position)


func take_damage(amount: int) -> void:
	if _transitioning:
		return
	
	for ability in _abilities:
		if ability is AbilityShield and ability.is_active():
			amount = ability.absorb_damage(amount)
			break
	
	if amount > 0 and health_component:
		health_component.take_damage(amount)
		_check_phase_transition()


func _on_died() -> void:
	died.emit(self)
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
