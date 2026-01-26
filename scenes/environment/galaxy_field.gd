class_name GalaxyField
extends Node2D

const CHUNK_SIZE := 2048.0
const CHUNK_MARGIN := 1
const MAX_GALAXIES := 20
const TEXTURE_PADDING := 4

@export_range(0.0, 1.0) var spawn_chance: float = 0.08
@export var stars_per_galaxy: Vector2i = Vector2i(120, 220)
@export var min_radius: float = 150.0
@export var max_radius: float = 300.0
@export var base_alpha: float = 0.85
@export var blackhole_enabled: bool = true
@export_range(0.0, 1.0) var blackhole_chance: float = 0.6
@export_range(0.02, 0.15) var blackhole_size_ratio: float = 0.08
@export_range(1.0, 4.0) var accretion_disk_ratio: float = 2.5
@export_range(0.5, 2.0) var glow_intensity: float = 1.2
var session_seed: int = 0

var _loaded_chunks: Dictionary = {}
var _visible_chunk_keys: Array[Vector2i] = []
var _galaxy_textures: Dictionary = {}
var _galaxy_rotations: Dictionary = {}
var _has_rotating_galaxies: bool = false
var _pending_chunks: Dictionary = {}
var _completed_chunks: Array = []
var _mutex := Mutex.new()


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_process_completed_chunks()
	
	if not _has_rotating_galaxies:
		return
	
	var any_rotating := false
	for chunk_key in _loaded_chunks:
		var galaxy: Dictionary = _loaded_chunks[chunk_key]
		if galaxy.is_empty():
			continue
		if absf(galaxy.rotation_speed) > 0.001:
			any_rotating = true
			_galaxy_rotations[chunk_key] += galaxy.rotation_speed * delta
	
	_has_rotating_galaxies = any_rotating
	if any_rotating:
		queue_redraw()


func _process_completed_chunks() -> void:
	_mutex.lock()
	var to_process := _completed_chunks.duplicate()
	_completed_chunks.clear()
	_mutex.unlock()
	
	for data in to_process:
		_finalize_chunk(data.chunk_key, data.texture, data.galaxy)
		queue_redraw()


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
			
			if not _loaded_chunks.has(chunk_key) and not _pending_chunks.has(chunk_key):
				_request_chunk(chunk_key)
				chunks_changed = true
	
	for old_key in _visible_chunk_keys:
		if old_key not in new_visible_keys:
			_unload_chunk(old_key)
			chunks_changed = true
	
	_visible_chunk_keys = new_visible_keys
	if chunks_changed:
		queue_redraw()


func _request_chunk(chunk_key: Vector2i) -> void:
	var chunk_seed := _get_chunk_seed(chunk_key)
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed
	
	if rng.randf() > spawn_chance:
		_loaded_chunks[chunk_key] = {}
		return
	
	var chunk_origin := Vector2(chunk_key.x * CHUNK_SIZE, chunk_key.y * CHUNK_SIZE)
	var radius: float = rng.randf_range(min_radius, max_radius)
	var center := chunk_origin + Vector2(
		rng.randf_range(radius, CHUNK_SIZE - radius),
		rng.randf_range(radius, CHUNK_SIZE - radius)
	)
	
	var star_count := rng.randi_range(stars_per_galaxy.x, stars_per_galaxy.y)
	
	var base_color := Color.from_hsv(
		rng.randf(),
		rng.randf_range(0.2, 0.5),
		1.0
	)
	
	var color_core: Color = base_color.lightened(0.4)
	var color_edge: Color = base_color.darkened(0.3)
	var arm_tightness: float = rng.randf_range(0.03, 0.06)
	var arms: int = rng.randi_range(2, 5)
	var rotation_speed: float = rng.randf_range(-0.03, 0.03)
	var initial_rotation: float = rng.randf() * TAU
	
	var stars: Array[Dictionary] = []
	for s in range(star_count):
		var arm: int = rng.randi() % arms
		var dist: float = rng.randf() * radius
		var angle: float = (float(arm) / float(arms)) * TAU
		angle += dist * arm_tightness
		angle += rng.randf_range(-0.15, 0.15)
		
		var t: float = dist / radius
		var star_color: Color = color_core.lerp(color_edge, t)
		star_color *= rng.randf_range(0.7, 1.0)
		star_color.a = base_alpha
		
		stars.append({
			"angle": angle,
			"distance": dist,
			"size": rng.randf_range(0.8, 1.6),
			"color": star_color,
			"rotation_factor": 1.0 - t
		})
	
	var has_blackhole := blackhole_enabled and rng.randf() < blackhole_chance
	var blackhole_radius := radius * blackhole_size_ratio if has_blackhole else 0.0
	var accretion_radius := blackhole_radius * accretion_disk_ratio if has_blackhole else 0.0
	var blackhole_color := base_color.lightened(0.6) if has_blackhole else Color.WHITE
	
	var galaxy := {
		"center": center,
		"radius": radius,
		"rotation_speed": rotation_speed,
		"stars": stars,
		"has_blackhole": has_blackhole,
		"blackhole_radius": blackhole_radius,
		"accretion_radius": accretion_radius,
		"blackhole_color": blackhole_color,
		"initial_rotation": initial_rotation
	}
	
	_pending_chunks[chunk_key] = true
	var task_data := {
		"chunk_key": chunk_key,
		"galaxy": galaxy,
		"glow_intensity": glow_intensity,
		"base_alpha": base_alpha
	}
	WorkerThreadPool.add_task(_generate_galaxy_texture_async.bind(task_data))


func _generate_galaxy_texture_async(task_data: Dictionary) -> void:
	var chunk_key: Vector2i = task_data.chunk_key
	var galaxy: Dictionary = task_data.galaxy
	var glow: float = task_data.glow_intensity
	var alpha: float = task_data.base_alpha
	
	var texture := _create_galaxy_texture(galaxy, glow, alpha)
	
	_mutex.lock()
	_completed_chunks.append({
		"chunk_key": chunk_key,
		"texture": texture,
		"galaxy": galaxy
	})
	_mutex.unlock()


func _finalize_chunk(chunk_key: Vector2i, texture: ImageTexture, galaxy: Dictionary) -> void:
	_pending_chunks.erase(chunk_key)
	
	_loaded_chunks[chunk_key] = galaxy
	_galaxy_rotations[chunk_key] = galaxy.initial_rotation
	_galaxy_textures[chunk_key] = texture
	
	if absf(galaxy.rotation_speed) > 0.001:
		_has_rotating_galaxies = true


func _create_galaxy_texture(galaxy: Dictionary, glow: float, alpha: float) -> ImageTexture:
	var radius: float = galaxy.radius
	var tex_size: int = int(ceil(radius * 2)) + TEXTURE_PADDING * 2
	var center_offset := Vector2(radius + TEXTURE_PADDING, radius + TEXTURE_PADDING)
	
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	if galaxy.has_blackhole:
		_draw_blackhole_to_image(image, center_offset, galaxy.blackhole_radius, galaxy.accretion_radius, galaxy.blackhole_color, glow, alpha)
	
	for s in galaxy.stars:
		var angle: float = s.angle
		var dist: float = s.distance
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var pos: Vector2 = center_offset + offset
		var size: float = s.size
		var color: Color = s.color
		
		_draw_circle_to_image(image, pos, size, color)
	
	return ImageTexture.create_from_image(image)


func _draw_blackhole_to_image(image: Image, center: Vector2, core_radius: float, accretion_radius: float, glow_color: Color, glow: float, alpha: float) -> void:
	var outer_glow_radius := accretion_radius * 1.8
	var min_x := int(max(0, center.x - outer_glow_radius - 1))
	var max_x := int(min(image.get_width() - 1, center.x + outer_glow_radius + 1))
	var min_y := int(max(0, center.y - outer_glow_radius - 1))
	var max_y := int(min(image.get_height() - 1, center.y + outer_glow_radius + 1))
	
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dist := Vector2(x, y).distance_to(center)
			
			if dist <= core_radius * 0.6:
				image.set_pixel(x, y, Color(0, 0, 0, 1.0))
			elif dist <= core_radius:
				var t := (dist - core_radius * 0.6) / (core_radius * 0.4)
				var edge_glow := glow_color * 0.3 * (1.0 - t)
				edge_glow.a = 0.8 + 0.2 * (1.0 - t)
				var blended := Color(0, 0, 0, 1.0).lerp(edge_glow, t * 0.5)
				blended.a = 1.0
				image.set_pixel(x, y, blended)
			elif dist <= accretion_radius:
				var t := (dist - core_radius) / (accretion_radius - core_radius)
				var ring_intensity := sin(t * PI) * glow
				var ring_color := glow_color * ring_intensity
				ring_color.a = (1.0 - t * 0.5) * alpha * ring_intensity
				var existing := image.get_pixel(x, y)
				var blended := _blend_additive(existing, ring_color)
				image.set_pixel(x, y, blended)
			elif dist <= outer_glow_radius:
				var t := (dist - accretion_radius) / (outer_glow_radius - accretion_radius)
				var falloff := pow(1.0 - t, 2.0) * 0.4 * glow
				var outer_color := glow_color * falloff
				outer_color.a = falloff * alpha
				var existing := image.get_pixel(x, y)
				var blended := _blend_additive(existing, outer_color)
				image.set_pixel(x, y, blended)


func _blend_additive(base_color: Color, add_color: Color) -> Color:
	return Color(
		minf(base_color.r + add_color.r * add_color.a, 1.0),
		minf(base_color.g + add_color.g * add_color.a, 1.0),
		minf(base_color.b + add_color.b * add_color.a, 1.0),
		minf(base_color.a + add_color.a * (1.0 - base_color.a), 1.0)
	)


func _draw_circle_to_image(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var min_x := int(max(0, center.x - radius - 1))
	var max_x := int(min(image.get_width() - 1, center.x + radius + 1))
	var min_y := int(max(0, center.y - radius - 1))
	var max_y := int(min(image.get_height() - 1, center.y + radius + 1))
	
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha := 1.0 - (dist / radius) * 0.3
				var final_color := color
				final_color.a *= alpha
				var existing := image.get_pixel(x, y)
				var blended := Color(
					existing.r + final_color.r * final_color.a * (1.0 - existing.a),
					existing.g + final_color.g * final_color.a * (1.0 - existing.a),
					existing.b + final_color.b * final_color.a * (1.0 - existing.a),
					existing.a + final_color.a * (1.0 - existing.a)
				)
				image.set_pixel(x, y, blended)


func _unload_chunk(chunk_key: Vector2i) -> void:
	_loaded_chunks.erase(chunk_key)
	_galaxy_textures.erase(chunk_key)
	_galaxy_rotations.erase(chunk_key)
	_pending_chunks.erase(chunk_key)


func _get_chunk_seed(chunk_key: Vector2i) -> int:
	return hash(Vector3i(chunk_key.x, chunk_key.y, session_seed))


func _draw() -> void:
	for chunk_key in _visible_chunk_keys:
		if not _loaded_chunks.has(chunk_key):
			continue
		var galaxy: Dictionary = _loaded_chunks[chunk_key]
		if galaxy.is_empty():
			continue
		if not _galaxy_textures.has(chunk_key):
			continue
		
		var texture: ImageTexture = _galaxy_textures[chunk_key]
		var center: Vector2 = galaxy.center
		var galaxy_rotation: float = _galaxy_rotations.get(chunk_key, 0.0)
		var tex_size := Vector2(texture.get_width(), texture.get_height())
		
		draw_set_transform(center, galaxy_rotation, Vector2.ONE)
		draw_texture(texture, -tex_size / 2.0)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
