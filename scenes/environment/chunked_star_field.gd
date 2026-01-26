class_name ChunkedStarField
extends Node2D

const CHUNK_SIZE := 512.0
const CHUNK_MARGIN := 1

@export var max_stars: int = 2000
@export var stars_per_chunk: int = 20
@export var star_color: Color = Color.WHITE
@export var base_size: float = 1.0
@export var depth: float = 1.0
@export var layer_id: int = 0
var density_multiplier: float = 1.0
var session_seed: int = 0

var _loaded_chunks: Dictionary = {}
var _visible_chunk_keys: Array[Vector2i] = []
var _multimesh_instance: MultiMeshInstance2D
var _multimesh: MultiMesh
var _shader_material: ShaderMaterial


func _ready() -> void:
	_setup_multimesh()
	_setup_twinkle_shader()


func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	_multimesh.mesh = _create_star_mesh()
	_multimesh.instance_count = 0
	
	_multimesh_instance = MultiMeshInstance2D.new()
	_multimesh_instance.multimesh = _multimesh
	add_child(_multimesh_instance)


func _setup_twinkle_shader() -> void:
	var shader := load("res://scenes/environment/star_twinkle.gdshader")
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_multimesh_instance.material = _shader_material


func _process(_delta: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)


func _create_star_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var segments := 6
	
	vertices.append(Vector2.ZERO)
	colors.append(Color.WHITE)
	
	for i in range(segments + 1):
		var angle := (float(i) / segments) * TAU
		vertices.append(Vector2(cos(angle), sin(angle)))
		colors.append(Color.WHITE)
	
	var indices := PackedInt32Array()
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2 if i + 2 <= segments else 1)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
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
	
	var stars: Array[Dictionary] = []
	var actual_count := int(stars_per_chunk * density_multiplier)
	var chunk_origin := Vector2(chunk_key.x * CHUNK_SIZE, chunk_key.y * CHUNK_SIZE)
	
	for i in range(actual_count):
		var star := {
			"pos": chunk_origin + Vector2(
				rng.randf_range(0, CHUNK_SIZE),
				rng.randf_range(0, CHUNK_SIZE)
			),
			"size": rng.randf_range(0.5, 1.5) * base_size,
			"brightness": rng.randf_range(0.5, 1.0),
			"twinkle_offset": rng.randf(),
			"twinkle_speed": rng.randf()
		}
		stars.append(star)
	
	_loaded_chunks[chunk_key] = stars


func _unload_chunk(chunk_key: Vector2i) -> void:
	_loaded_chunks.erase(chunk_key)


func _get_chunk_seed(chunk_key: Vector2i) -> int:
	return hash(Vector3i(chunk_key.x, chunk_key.y, session_seed + layer_id))


func _rebuild_multimesh() -> void:
	var all_stars: Array[Dictionary] = []
	for chunk_key in _visible_chunk_keys:
		if _loaded_chunks.has(chunk_key):
			all_stars.append_array(_loaded_chunks[chunk_key])
	
	var count := mini(all_stars.size(), max_stars)
	_multimesh.instance_count = count
	
	for i in range(count):
		var star: Dictionary = all_stars[i]
		var t := Transform2D()
		t = t.scaled(Vector2(star.size, star.size))
		t.origin = star.pos
		_multimesh.set_instance_transform_2d(i, t)
		var color := Color(star_color.r, star_color.g, star_color.b, star_color.a * star.brightness)
		_multimesh.set_instance_color(i, color)
		_multimesh.set_instance_custom_data(i, Color(star.twinkle_offset, star.twinkle_speed, 0.0, 0.0))
