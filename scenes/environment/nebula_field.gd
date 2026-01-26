class_name NebulaField
extends Node2D

const CHUNK_SIZE := 1024.0
const CHUNK_MARGIN := 1
const BLOBS_PER_CHUNK := 5

@export var nebula_color: Color = Color(0.4, 0.1, 0.6, 0.6)
@export var secondary_color: Color = Color(0.9, 0.2, 0.5, 0.5)
@export var accent_color: Color = Color(0.1, 0.7, 0.9, 0.4)
@export var nebula_coverage: float = 0.6
@export var min_blob_size: float = 200.0
@export var max_blob_size: float = 500.0
@export var layer_id: int = 0
@export var use_shader: bool = true
@export var animation_speed: float = 0.02

var session_seed: int = 0

var _loaded_chunks: Dictionary = {}
var _visible_chunk_keys: Array[Vector2i] = []
var _blob_textures: Dictionary = {}
var _nebula_shader: Shader = null
var _time: float = 0.0
var _shared_materials: Dictionary = {}


func _ready() -> void:
	_load_shader()
	_setup_global_shader_params()
	_generate_shared_materials()
	_generate_blob_textures()
	_load_initial_chunks()


func _setup_global_shader_params() -> void:
	RenderingServer.global_shader_parameter_set("nebula_time", 0.0)


func _generate_shared_materials() -> void:
	if not use_shader or not _nebula_shader:
		return
	for density_idx in range(3):
		var mat := ShaderMaterial.new()
		mat.shader = _nebula_shader
		mat.set_shader_parameter("primary_color", nebula_color)
		mat.set_shader_parameter("secondary_color", secondary_color)
		mat.set_shader_parameter("accent_color", accent_color)
		mat.set_shader_parameter("density", 0.8 + density_idx * 0.2)
		mat.set_shader_parameter("detail_scale", 3.0 + density_idx * 1.5)
		mat.set_shader_parameter("wispy_intensity", 0.4 + density_idx * 0.2)
		mat.set_shader_parameter("brightness", 1.0 + density_idx * 0.2)
		mat.set_shader_parameter("world_offset", Vector2.ZERO)
		_shared_materials[density_idx] = mat


func _load_shader() -> void:
	if use_shader:
		_nebula_shader = load("res://scenes/environment/nebula.gdshader")


func _process(delta: float) -> void:
	if use_shader:
		_time += delta * animation_speed
		RenderingServer.global_shader_parameter_set("nebula_time", _time)


func _generate_blob_textures() -> void:
	var tex_size := 256
	for color_name in ["primary", "secondary", "accent"]:
		var color: Color
		match color_name:
			"primary": color = nebula_color
			"secondary": color = secondary_color
			"accent": color = accent_color
		for variant in range(3):
			var key: String = color_name + "_" + str(variant)
			_blob_textures[key] = _create_nebula_texture(color, tex_size, variant * 1000)


func _create_nebula_texture(color: Color, size: int, seed_offset: int = 0) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var max_dist := size / 2.0
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	noise.fractal_octaves = 4
	noise.seed = seed_offset
	
	var detail_noise := FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.08
	detail_noise.fractal_octaves = 2
	detail_noise.seed = seed_offset + 500
	
	for y in range(size):
		for x in range(size):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center)
			var t := clampf(dist / max_dist, 0.0, 1.0)
			
			var base_alpha := pow(1.0 - t, 1.5)
			
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var d := detail_noise.get_noise_2d(x * 2, y * 2) * 0.5 + 0.5
			
			var wispy := n * 0.6 + d * 0.4
			wispy = pow(wispy, 0.8)
			
			var edge_fade := smoothstep(0.7, 1.0, t)
			var alpha := base_alpha * wispy * (1.0 - edge_fade * 0.8) * color.a
			alpha = clampf(alpha, 0.0, color.a)
			
			var brightness := 1.0 + (1.0 - t) * 0.3 * n
			var r := clampf(color.r * brightness, 0.0, 1.0)
			var g := clampf(color.g * brightness, 0.0, 1.0)
			var b := clampf(color.b * brightness, 0.0, 1.0)
			
			image.set_pixel(x, y, Color(r, g, b, alpha))
	
	return ImageTexture.create_from_image(image)


func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _load_initial_chunks() -> void:
	for cx in range(-3, 4):
		for cy in range(-3, 4):
			var chunk_key := Vector2i(cx, cy)
			if not _loaded_chunks.has(chunk_key):
				_load_chunk(chunk_key)
			_visible_chunk_keys.append(chunk_key)


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
	
	for cx in range(min_chunk.x, max_chunk.x + 1):
		for cy in range(min_chunk.y, max_chunk.y + 1):
			var chunk_key := Vector2i(cx, cy)
			new_visible_keys.append(chunk_key)
			
			if not _loaded_chunks.has(chunk_key):
				_load_chunk(chunk_key)
	
	for old_key in _visible_chunk_keys:
		if old_key not in new_visible_keys:
			_unload_chunk(old_key)
	
	_visible_chunk_keys = new_visible_keys


func _load_chunk(chunk_key: Vector2i) -> void:
	var chunk_seed := _get_chunk_seed(chunk_key)
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed
	
	var sprites: Array[Sprite2D] = []
	
	if rng.randf() > nebula_coverage:
		_loaded_chunks[chunk_key] = sprites
		return
	
	var chunk_origin := Vector2(chunk_key.x * CHUNK_SIZE, chunk_key.y * CHUNK_SIZE)
	var blob_count := rng.randi_range(2, BLOBS_PER_CHUNK)
	
	for i in range(blob_count):
		var sprite := _create_nebula_sprite(rng, chunk_origin)
		add_child(sprite)
		sprites.append(sprite)
	
	_loaded_chunks[chunk_key] = sprites


func _create_nebula_sprite(rng: RandomNumberGenerator, chunk_origin: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	
	var pos := chunk_origin + Vector2(
		rng.randf_range(0, CHUNK_SIZE),
		rng.randf_range(0, CHUNK_SIZE)
	)
	sprite.position = pos
	
	var size := rng.randf_range(min_blob_size, max_blob_size)
	var base_tex_size := 256.0
	sprite.scale = Vector2(size / base_tex_size, size / base_tex_size)
	
	sprite.rotation = rng.randf() * TAU
	
	var color_choice := rng.randf()
	var color_name: String
	var tint: Color
	if color_choice < 0.4:
		color_name = "primary"
		tint = _shift_color(nebula_color, rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.1))
	elif color_choice < 0.7:
		color_name = "secondary"
		tint = _shift_color(secondary_color, rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.1))
	else:
		color_name = "accent"
		tint = _shift_color(accent_color, rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.1))
	
	var variant := rng.randi_range(0, 2)
	var tex_key: String = color_name + "_" + str(variant)
	sprite.texture = _blob_textures[tex_key]
	
	if use_shader and _nebula_shader and _shared_materials.size() > 0:
		var mat_idx := rng.randi_range(0, 2)
		sprite.material = _shared_materials[mat_idx]
	else:
		sprite.modulate = tint
	
	return sprite


func _unload_chunk(chunk_key: Vector2i) -> void:
	if _loaded_chunks.has(chunk_key):
		var sprites: Array = _loaded_chunks[chunk_key]
		for sprite in sprites:
			if sprite and is_instance_valid(sprite):
				sprite.queue_free()
		_loaded_chunks.erase(chunk_key)


func _get_chunk_seed(chunk_key: Vector2i) -> int:
	return hash(Vector3i(chunk_key.x, chunk_key.y, session_seed + layer_id + 1000))


func _shift_color(base_color: Color, hue_shift: float, sat_shift: float) -> Color:
	var h := base_color.h + hue_shift
	h = fmod(h + 1.0, 1.0)
	var s := clampf(base_color.s + sat_shift, 0.0, 1.0)
	return Color.from_hsv(h, s, base_color.v, base_color.a)
