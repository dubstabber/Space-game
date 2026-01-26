class_name AsteroidGeometry
extends RefCounted

const MIN_VERTICES := 6
const MAX_VERTICES := 12


static func generate_asteroid_shape(base_radius: float, irregularity: float = 0.3, seed_value: int = 0) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else randi()
	
	var vertex_count := rng.randi_range(MIN_VERTICES, MAX_VERTICES)
	var points := PackedVector2Array()
	
	var angle_step := TAU / vertex_count
	
	for i in range(vertex_count):
		var angle := i * angle_step
		var radius_variation := rng.randf_range(1.0 - irregularity, 1.0 + irregularity)
		var radius := base_radius * radius_variation
		
		var point := Vector2(
			cos(angle) * radius,
			sin(angle) * radius
		)
		points.append(point)
	
	return points


static func generate_asteroid_with_details(base_radius: float, irregularity: float = 0.3, seed_value: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else randi()
	
	var outline := generate_asteroid_shape(base_radius, irregularity, seed_value)
	
	var crater_count := rng.randi_range(0, 3)
	var craters: Array[Dictionary] = []
	
	for i in range(crater_count):
		var crater_angle := rng.randf() * TAU
		var crater_distance := rng.randf_range(0.2, 0.6) * base_radius
		var crater_radius := rng.randf_range(0.1, 0.25) * base_radius
		
		craters.append({
			"position": Vector2(cos(crater_angle), sin(crater_angle)) * crater_distance,
			"radius": crater_radius
		})
	
	return {
		"outline": outline,
		"craters": craters,
		"base_radius": base_radius
	}


static func get_asteroid_color(asteroid_type: String) -> Color:
	match asteroid_type:
		"iron":
			return Color(0.45, 0.42, 0.4)
		"gold":
			return Color(0.7, 0.6, 0.2)
		"crystal":
			return Color(0.5, 0.7, 0.9)
		"ice":
			return Color(0.7, 0.85, 0.95)
		_:
			return Color(0.35, 0.32, 0.3)


static func get_outline_color(asteroid_type: String) -> Color:
	var base := get_asteroid_color(asteroid_type)
	return base.lightened(0.3)
