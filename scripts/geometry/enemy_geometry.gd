class_name EnemyGeometry
extends RefCounted


static func generate_scout_shape(size: float, style: int = 0) -> Dictionary:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = style
	
	var variation := rng.randf_range(0.9, 1.1)
	var s := size * variation
	
	points.append(Vector2(0, -s * 1.2))
	points.append(Vector2(s * 0.6, s * 0.3))
	points.append(Vector2(s * 0.3, s * 0.5))
	points.append(Vector2(-s * 0.3, s * 0.5))
	points.append(Vector2(-s * 0.6, s * 0.3))
	
	var detail_points := PackedVector2Array()
	detail_points.append(Vector2(0, -s * 0.8))
	detail_points.append(Vector2(s * 0.2, s * 0.1))
	detail_points.append(Vector2(-s * 0.2, s * 0.1))
	detail_points.append(Vector2(0, -s * 0.8))
	
	return {"hull": points, "details": detail_points}


static func generate_fighter_shape(size: float, style: int = 0) -> Dictionary:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = style
	
	var variation := rng.randf_range(0.9, 1.1)
	var s := size * variation
	
	points.append(Vector2(0, -s * 1.0))
	points.append(Vector2(s * 0.4, -s * 0.3))
	points.append(Vector2(s * 0.8, s * 0.2))
	points.append(Vector2(s * 0.5, s * 0.6))
	points.append(Vector2(s * 0.2, s * 0.5))
	points.append(Vector2(0, s * 0.7))
	points.append(Vector2(-s * 0.2, s * 0.5))
	points.append(Vector2(-s * 0.5, s * 0.6))
	points.append(Vector2(-s * 0.8, s * 0.2))
	points.append(Vector2(-s * 0.4, -s * 0.3))
	
	var detail_points := PackedVector2Array()
	detail_points.append(Vector2(0, -s * 0.6))
	detail_points.append(Vector2(s * 0.25, s * 0.2))
	detail_points.append(Vector2(0, s * 0.4))
	detail_points.append(Vector2(-s * 0.25, s * 0.2))
	detail_points.append(Vector2(0, -s * 0.6))
	
	return {"hull": points, "details": detail_points}


static func generate_heavy_shape(size: float, style: int = 0) -> Dictionary:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = style
	
	var variation := rng.randf_range(0.9, 1.1)
	var s := size * variation
	
	points.append(Vector2(0, -s * 0.9))
	points.append(Vector2(s * 0.5, -s * 0.5))
	points.append(Vector2(s * 0.7, -s * 0.2))
	points.append(Vector2(s * 0.9, s * 0.3))
	points.append(Vector2(s * 0.7, s * 0.7))
	points.append(Vector2(s * 0.3, s * 0.8))
	points.append(Vector2(0, s * 0.6))
	points.append(Vector2(-s * 0.3, s * 0.8))
	points.append(Vector2(-s * 0.7, s * 0.7))
	points.append(Vector2(-s * 0.9, s * 0.3))
	points.append(Vector2(-s * 0.7, -s * 0.2))
	points.append(Vector2(-s * 0.5, -s * 0.5))
	
	var detail_points := PackedVector2Array()
	detail_points.append(Vector2(-s * 0.4, 0))
	detail_points.append(Vector2(0, -s * 0.5))
	detail_points.append(Vector2(s * 0.4, 0))
	detail_points.append(Vector2(0, s * 0.3))
	detail_points.append(Vector2(-s * 0.4, 0))
	
	return {"hull": points, "details": detail_points}


static func generate_hive_shape(size: float, enemy_type: EnemyData.EnemyType, style: int = 0) -> Dictionary:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = style
	
	var s := size * rng.randf_range(0.9, 1.1)
	var segments: int
	
	match enemy_type:
		EnemyData.EnemyType.SCOUT:
			segments = 5
		EnemyData.EnemyType.FIGHTER:
			segments = 6
		EnemyData.EnemyType.HEAVY:
			segments = 8
		_:
			segments = 6
	
	for i in range(segments):
		var angle := (TAU / segments) * i - PI / 2
		var radius := s * (0.8 + rng.randf_range(-0.15, 0.15))
		if i % 2 == 1:
			radius *= 0.7
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	var detail_points := PackedVector2Array()
	var inner_segments := segments / 2 + 1
	for i in range(inner_segments):
		var angle := (TAU / inner_segments) * i - PI / 2
		var radius := s * 0.4
		detail_points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	detail_points.append(detail_points[0])
	
	return {"hull": points, "details": detail_points}


static func generate_boss_shape(size: float, phase: int = 0, style: int = 0) -> Dictionary:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = style + phase * 1000
	
	var s := size * rng.randf_range(0.95, 1.05)
	var base_segments := 12 + phase * 2
	
	for i in range(base_segments):
		var angle := (TAU / base_segments) * i - PI / 2
		var radius := s
		
		if i % 3 == 0:
			radius *= 1.3
		elif i % 3 == 1:
			radius *= 0.9
		
		radius += rng.randf_range(-s * 0.1, s * 0.1)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	var detail_points := PackedVector2Array()
	var inner_segments := 6
	for i in range(inner_segments + 1):
		var angle := (TAU / inner_segments) * i - PI / 2
		var radius := s * 0.5
		detail_points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	var turret_positions: Array[Vector2] = []
	var turret_count := 2 + phase
	for i in range(turret_count):
		var angle := (TAU / turret_count) * i
		turret_positions.append(Vector2(cos(angle) * s * 0.6, sin(angle) * s * 0.6))
	
	return {
		"hull": points,
		"details": detail_points,
		"turrets": turret_positions
	}


static func generate_shape_for_enemy(enemy_type: EnemyData.EnemyType, faction_id: FactionData.FactionID, size: float, style: int = 0) -> Dictionary:
	if faction_id == FactionData.FactionID.HIVE:
		return generate_hive_shape(size, enemy_type, style)
	
	match enemy_type:
		EnemyData.EnemyType.SCOUT:
			return generate_scout_shape(size, style)
		EnemyData.EnemyType.FIGHTER:
			return generate_fighter_shape(size, style)
		EnemyData.EnemyType.HEAVY:
			return generate_heavy_shape(size, style)
		EnemyData.EnemyType.BOSS:
			return generate_boss_shape(size, 0, style)
		_:
			return generate_fighter_shape(size, style)


static func create_outline_from_hull(hull: PackedVector2Array) -> PackedVector2Array:
	var outline := hull.duplicate()
	if outline.size() > 0:
		outline.append(outline[0])
	return outline
