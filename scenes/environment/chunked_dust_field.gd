class_name ChunkedDustField
extends Node2D

const CHUNK_SIZE := 512.0
const CHUNK_MARGIN := 1

@export var max_particles: int = 1500
@export var particles_per_chunk: int = 25
@export var dust_color: Color = Color(0.7, 0.75, 0.85, 0.15)
@export var base_size: float = 3.0
@export var size_variation: float = 2.5
@export var depth: float = 1.0
@export var layer_id: int = 0
@export var drift_speed: float = 1.0
@export var turbulence: float = 0.3
var density_multiplier: float = 1.0
var session_seed: int = 0

var _loaded_chunks: Dictionary = {}
var _visible_chunk_keys: Array[Vector2i] = []
var _multimesh_instance: MultiMeshInstance2D
var _multimesh: MultiMesh
var _shader_material: ShaderMaterial


func _ready() -> void:
	_setup_multimesh()
	_setup_dust_shader()


func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	_multimesh.mesh = _create_dust_mesh()
	_multimesh.instance_count = 0
	
	_multimesh_instance = MultiMeshInstance2D.new()
	_multimesh_instance.multimesh = _multimesh
	add_child(_multimesh_instance)


func _setup_dust_shader() -> void:
	var shader := load("res://scenes/environment/dust_drift.gdshader")
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("drift_speed", drift_speed)
	_shader_material.set_shader_parameter("turbulence", turbulence)
	_multimesh_instance.material = _shader_material


func _process(_delta: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)


func _create_dust_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var segments := 12
	
	vertices.append(Vector2.ZERO)
	colors.append(Color.WHITE)
	uvs.append(Vector2(0.5, 0.5))
	
	for i in range(segments + 1):
		var angle := (float(i) / segments) * TAU
		var point := Vector2(cos(angle), sin(angle))
		vertices.append(point)
		colors.append(Color(1, 1, 1, 0))
		uvs.append((point + Vector2.ONE) * 0.5)
	
	var indices := PackedInt32Array()
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2 if i + 2 <= segments else 1)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func update_visible_chunks(camera_pos: Vector2, viewport_size: Vector2) -> void:
	var half_viewport := viewport_size / 2.0 + Vector2(CHUNK_SIZE, CHUNK_SIZE) * CHUNK_MARGIN
	
	var min_chunk := Vector2i(
		floori((camera_pos.x - half_viewport.x) / CHUNK_SIZE),
		floori((camera_pos.y - half_viewport.y) / CHUNK_SIZE)
	)
	var max_chunk := Vector2i(
		floori((camera_pos.x + half_viewport.x) / CHUNK_SIZE),
		floori((camera_pos.y + half_viewport.y) / CHUNK_SIZE)
	)
	
	var new_visible_keys: Array[Vector2i] = []
	var chunks_changed := false
	
	for cx in range(min_chunk.x, max_chunk.x + 1):
		for cy in range(min_chunk.y, max_chunk.y + 1):
			var chunk_key := Vector2i(cx, cy)
			new_visible_keys.append(chunk_key)
			
			if not _loaded_chunks.has(chunk_key):
				_load_chunk(chunk_key)
				chunks_changed = true
	
	for old_key in _visible_chunk_keys:
		if old_key not in new_visible_keys:
			_unload_chunk(old_key)
			chunks_changed = true
	
	_visible_chunk_keys = new_visible_keys
	if chunks_changed:
		_rebuild_multimesh()


func _load_chunk(chunk_key: Vector2i) -> void:
	var chunk_seed := _get_chunk_seed(chunk_key)
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed
	
	var particles: Array[Dictionary] = []
	var actual_count := int(particles_per_chunk * density_multiplier)
	var chunk_origin := Vector2(chunk_key.x * CHUNK_SIZE, chunk_key.y * CHUNK_SIZE)
	
	for i in range(actual_count):
		var particle_type := rng.randf()
		var is_wispy := particle_type > 0.7
		
		var size_mult := 1.0
		var alpha_mult := 1.0
		if is_wispy:
			size_mult = rng.randf_range(2.0, 4.0)
			alpha_mult = rng.randf_range(0.3, 0.6)
		else:
			size_mult = rng.randf_range(0.5, 1.5)
			alpha_mult = rng.randf_range(0.6, 1.0)
		
		var particle := {
			"pos": chunk_origin + Vector2(
				rng.randf_range(0, CHUNK_SIZE),
				rng.randf_range(0, CHUNK_SIZE)
			),
			"size": (base_size + rng.randf_range(-size_variation, size_variation)) * size_mult,
			"alpha": alpha_mult,
			"drift_offset": rng.randf(),
			"drift_phase": rng.randf(),
			"rotation": rng.randf_range(0, TAU),
			"type": 1.0 if is_wispy else 0.0
		}
		particles.append(particle)
	
	_loaded_chunks[chunk_key] = particles


func _unload_chunk(chunk_key: Vector2i) -> void:
	_loaded_chunks.erase(chunk_key)


func _get_chunk_seed(chunk_key: Vector2i) -> int:
	return hash(Vector3i(chunk_key.x, chunk_key.y, session_seed + layer_id + 10000))


func _rebuild_multimesh() -> void:
	var all_particles: Array[Dictionary] = []
	for chunk_key in _visible_chunk_keys:
		if _loaded_chunks.has(chunk_key):
			all_particles.append_array(_loaded_chunks[chunk_key])
	
	var count := mini(all_particles.size(), max_particles)
	_multimesh.instance_count = count
	
	for i in range(count):
		var particle: Dictionary = all_particles[i]
		var t := Transform2D()
		t = t.rotated(particle.rotation)
		t = t.scaled(Vector2(particle.size, particle.size))
		t.origin = particle.pos
		_multimesh.set_instance_transform_2d(i, t)
		var color := Color(dust_color.r, dust_color.g, dust_color.b, dust_color.a * particle.alpha)
		_multimesh.set_instance_color(i, color)
		_multimesh.set_instance_custom_data(i, Color(particle.drift_offset, particle.drift_phase, particle.type, 0.0))
