extends Node2D

var _star_fields: Array[ChunkedStarField] = []
var _nebula_fields: Array[NebulaField] = []
var _chunked_dust_fields: Array[ChunkedDustField] = []
var _galaxy_fields: Array[GalaxyField] = []
var _shader_galaxy_fields: Array[ShaderGalaxyField] = []
var _parallax_layers: Array[Parallax2D] = []
var _camera: Camera2D = null
var _current_map_id: String = ""
var _initialized_from_map: bool = false


func _ready() -> void:
	_collect_existing_child_fields()
	
	if MapManager.current_map_id != "":
		_build_from_map_data(MapManager.get_current_map())
	
	MapManager.map_changed.connect(_on_map_changed)


func _collect_existing_child_fields() -> void:
	for child in get_children():
		if child is Parallax2D:
			for subchild in child.get_children():
				if subchild is ChunkedStarField:
					_star_fields.append(subchild)
				elif subchild is NebulaField:
					_nebula_fields.append(subchild)
				elif subchild is ChunkedDustField:
					_chunked_dust_fields.append(subchild)
				elif subchild is GalaxyField:
					_galaxy_fields.append(subchild)
				elif subchild is ShaderGalaxyField:
					_shader_galaxy_fields.append(subchild)


func _on_map_changed(map_id: String) -> void:
	var map_data := MapManager.get_map_data(map_id)
	if map_data:
		_build_from_map_data(map_data)


func _build_from_map_data(map_data: MapData) -> void:
	if map_data == null:
		return
	
	_clear_all_layers()
	
	_current_map_id = map_data.map_id
	var map_seed := SeedManager.get_map_seed(map_data.map_id)
	
	for i in range(map_data.parallax_layers.size()):
		var layer_config: ParallaxLayerConfig = map_data.parallax_layers[i]
		var layer_seed := SeedManager.get_layer_seed(map_data.map_id, i)
		_create_layer_from_config(layer_config, layer_seed, i)
	
	_initialized_from_map = true
	print("[ParallaxBackground] Built from map: ", map_data.map_id, " with seed: ", map_seed)


func _clear_all_layers() -> void:
	for layer in _parallax_layers:
		if is_instance_valid(layer):
			layer.queue_free()
	
	_parallax_layers.clear()
	_star_fields.clear()
	_nebula_fields.clear()
	_chunked_dust_fields.clear()
	_galaxy_fields.clear()
	_shader_galaxy_fields.clear()


func _create_layer_from_config(config: ParallaxLayerConfig, layer_seed: int, layer_index: int) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = config.scroll_scale
	parallax.name = "Layer_" + str(layer_index)
	add_child(parallax)
	_parallax_layers.append(parallax)
	
	match config.layer_type:
		ParallaxLayerConfig.LayerType.STAR_FIELD:
			_create_star_field(parallax, config, layer_seed)
		ParallaxLayerConfig.LayerType.NEBULA_FIELD:
			_create_nebula_field(parallax, config, layer_seed)
		ParallaxLayerConfig.LayerType.GALAXY_FIELD:
			_create_galaxy_field(parallax, config, layer_seed)
		ParallaxLayerConfig.LayerType.SHADER_GALAXY_FIELD:
			_create_shader_galaxy_field(parallax, config, layer_seed)
		ParallaxLayerConfig.LayerType.DUST_FIELD:
			_create_dust_field(parallax, config, layer_seed)


func _create_star_field(parent: Parallax2D, config: ParallaxLayerConfig, layer_seed: int) -> void:
	var star_field := ChunkedStarField.new()
	star_field.max_stars = config.star_max_stars
	star_field.stars_per_chunk = config.star_per_chunk
	star_field.star_color = config.star_color
	star_field.base_size = config.star_base_size
	star_field.layer_id = config.layer_id
	star_field.session_seed = layer_seed
	parent.add_child(star_field)
	_star_fields.append(star_field)


func _create_nebula_field(parent: Parallax2D, config: ParallaxLayerConfig, layer_seed: int) -> void:
	var nebula := NebulaField.new()
	nebula.nebula_color = config.nebula_primary_color
	nebula.secondary_color = config.nebula_secondary_color
	nebula.accent_color = config.nebula_accent_color
	nebula.nebula_coverage = config.nebula_coverage
	nebula.min_blob_size = config.nebula_min_blob_size
	nebula.max_blob_size = config.nebula_max_blob_size
	nebula.session_seed = layer_seed
	parent.add_child(nebula)
	_nebula_fields.append(nebula)


func _create_galaxy_field(parent: Parallax2D, config: ParallaxLayerConfig, layer_seed: int) -> void:
	var galaxy := GalaxyField.new()
	galaxy.spawn_chance = config.galaxy_spawn_chance
	galaxy.stars_per_galaxy = config.galaxy_stars_per_galaxy
	galaxy.min_radius = config.galaxy_min_radius
	galaxy.max_radius = config.galaxy_max_radius
	galaxy.base_alpha = config.galaxy_base_alpha
	galaxy.blackhole_enabled = config.galaxy_blackhole_enabled
	galaxy.blackhole_chance = config.galaxy_blackhole_chance
	galaxy.glow_intensity = config.galaxy_glow_intensity
	galaxy.session_seed = layer_seed
	parent.add_child(galaxy)
	_galaxy_fields.append(galaxy)


func _create_shader_galaxy_field(parent: Parallax2D, config: ParallaxLayerConfig, layer_seed: int) -> void:
	var shader_galaxy := ShaderGalaxyField.new()
	shader_galaxy.spawn_chance = config.shader_galaxy_spawn_chance
	shader_galaxy.min_galaxy_size = config.shader_galaxy_min_size
	shader_galaxy.max_galaxy_size = config.shader_galaxy_max_size
	shader_galaxy.base_alpha = config.shader_galaxy_base_alpha
	shader_galaxy.session_seed = layer_seed
	parent.add_child(shader_galaxy)
	_shader_galaxy_fields.append(shader_galaxy)


func _create_dust_field(parent: Parallax2D, config: ParallaxLayerConfig, layer_seed: int) -> void:
	var dust := ChunkedDustField.new()
	dust.max_particles = config.dust_max_particles
	dust.particles_per_chunk = config.dust_per_chunk
	dust.dust_color = config.dust_color
	dust.base_size = config.dust_base_size
	dust.size_variation = config.dust_size_variation
	dust.drift_speed = config.dust_drift_speed
	dust.turbulence = config.dust_turbulence
	dust.session_seed = layer_seed
	parent.add_child(dust)
	_chunked_dust_fields.append(dust)


func _process(_delta: float) -> void:
	if _camera == null:
		_camera = get_viewport().get_camera_2d()
	
	if _camera:
		_update_chunked_fields()


func _update_chunked_fields() -> void:
	var camera_pos := _camera.global_position
	var viewport_size := get_viewport().get_visible_rect().size / _camera.zoom
	
	for star_field in _star_fields:
		var parallax_layer := star_field.get_parent() as Parallax2D
		if parallax_layer:
			var effective_camera_pos := camera_pos * parallax_layer.scroll_scale
			var effective_viewport := viewport_size / parallax_layer.scroll_scale
			star_field.update_visible_chunks(effective_camera_pos, effective_viewport)
	
	for galaxy_field in _galaxy_fields:
		var parallax_layer := galaxy_field.get_parent() as Parallax2D
		if parallax_layer:
			var effective_camera_pos := camera_pos * parallax_layer.scroll_scale
			var effective_viewport := viewport_size / parallax_layer.scroll_scale
			galaxy_field.update_visible_chunks(effective_camera_pos, effective_viewport)
	
	for nebula_field in _nebula_fields:
		var parallax_layer := nebula_field.get_parent() as Parallax2D
		if parallax_layer:
			var effective_camera_pos := camera_pos * parallax_layer.scroll_scale
			var effective_viewport := viewport_size / parallax_layer.scroll_scale
			nebula_field.update_visible_chunks(effective_camera_pos, effective_viewport)
	
	for dust_field in _chunked_dust_fields:
		var parallax_layer := dust_field.get_parent() as Parallax2D
		if parallax_layer:
			var effective_camera_pos := camera_pos * parallax_layer.scroll_scale
			var effective_viewport := viewport_size / parallax_layer.scroll_scale
			dust_field.update_visible_chunks(effective_camera_pos, effective_viewport)


func apply_map_data(map_data: MapData) -> void:
	_build_from_map_data(map_data)


func apply_universe_settings(universe_data: UniverseData) -> void:
	for star_field in _star_fields:
		star_field.density_multiplier = universe_data.star_density
	
	for nebula in _nebula_fields:
		nebula.nebula_color = universe_data.nebula_color
		nebula.visible = universe_data.has_nebula


func get_current_map_id() -> String:
	return _current_map_id
