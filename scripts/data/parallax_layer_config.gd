class_name ParallaxLayerConfig
extends Resource

enum LayerType {
	STAR_FIELD,
	NEBULA_FIELD,
	GALAXY_FIELD,
	SHADER_GALAXY_FIELD,
	DUST_FIELD
}

@export var layer_type: LayerType = LayerType.STAR_FIELD
@export var scroll_scale: Vector2 = Vector2(0.1, 0.1)
@export var layer_id: int = 0

@export_group("Star Field Settings")
@export var star_max_stars: int = 2000
@export var star_per_chunk: int = 15
@export var star_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var star_base_size: float = 1.0

@export_group("Nebula Field Settings")
@export var nebula_primary_color: Color = Color(0.4, 0.1, 0.6, 0.6)
@export var nebula_secondary_color: Color = Color(0.9, 0.2, 0.5, 0.5)
@export var nebula_accent_color: Color = Color(0.1, 0.7, 0.9, 0.4)
@export var nebula_coverage: float = 0.6
@export var nebula_min_blob_size: float = 200.0
@export var nebula_max_blob_size: float = 500.0

@export_group("Galaxy Field Settings")
@export var galaxy_spawn_chance: float = 0.08
@export var galaxy_stars_per_galaxy: Vector2i = Vector2i(120, 220)
@export var galaxy_min_radius: float = 150.0
@export var galaxy_max_radius: float = 300.0
@export var galaxy_base_alpha: float = 0.85
@export var galaxy_blackhole_enabled: bool = true
@export var galaxy_blackhole_chance: float = 0.6
@export var galaxy_glow_intensity: float = 1.2

@export_group("Shader Galaxy Settings")
@export var shader_galaxy_spawn_chance: float = 0.245
@export var shader_galaxy_min_size: float = 550.0
@export var shader_galaxy_max_size: float = 900.0
@export var shader_galaxy_base_alpha: float = 0.95

@export_group("Dust Field Settings")
@export var dust_max_particles: int = 2000
@export var dust_per_chunk: int = 30
@export var dust_color: Color = Color(0.7, 0.75, 0.85, 0.14)
@export var dust_base_size: float = 4.0
@export var dust_size_variation: float = 3.0
@export var dust_drift_speed: float = 0.8
@export var dust_turbulence: float = 0.25


static func create_star_layer(
	p_scroll_scale: Vector2,
	p_layer_id: int,
	p_max_stars: int = 2000,
	p_per_chunk: int = 15,
	p_color: Color = Color(1.0, 1.0, 1.0, 0.5),
	p_base_size: float = 1.0
) -> ParallaxLayerConfig:
	var config := ParallaxLayerConfig.new()
	config.layer_type = LayerType.STAR_FIELD
	config.scroll_scale = p_scroll_scale
	config.layer_id = p_layer_id
	config.star_max_stars = p_max_stars
	config.star_per_chunk = p_per_chunk
	config.star_color = p_color
	config.star_base_size = p_base_size
	return config


static func create_nebula_layer(
	p_scroll_scale: Vector2,
	p_primary: Color = Color(0.4, 0.1, 0.6, 0.6),
	p_secondary: Color = Color(0.9, 0.2, 0.5, 0.5),
	p_accent: Color = Color(0.1, 0.7, 0.9, 0.4),
	p_coverage: float = 0.6
) -> ParallaxLayerConfig:
	var config := ParallaxLayerConfig.new()
	config.layer_type = LayerType.NEBULA_FIELD
	config.scroll_scale = p_scroll_scale
	config.nebula_primary_color = p_primary
	config.nebula_secondary_color = p_secondary
	config.nebula_accent_color = p_accent
	config.nebula_coverage = p_coverage
	return config


static func create_galaxy_layer(
	p_scroll_scale: Vector2,
	p_spawn_chance: float = 0.08,
	p_blackhole_enabled: bool = true
) -> ParallaxLayerConfig:
	var config := ParallaxLayerConfig.new()
	config.layer_type = LayerType.GALAXY_FIELD
	config.scroll_scale = p_scroll_scale
	config.galaxy_spawn_chance = p_spawn_chance
	config.galaxy_blackhole_enabled = p_blackhole_enabled
	return config


static func create_shader_galaxy_layer(
	p_scroll_scale: Vector2,
	p_spawn_chance: float = 0.245
) -> ParallaxLayerConfig:
	var config := ParallaxLayerConfig.new()
	config.layer_type = LayerType.SHADER_GALAXY_FIELD
	config.scroll_scale = p_scroll_scale
	config.shader_galaxy_spawn_chance = p_spawn_chance
	return config


static func create_dust_layer(
	p_scroll_scale: Vector2,
	p_color: Color = Color(0.7, 0.75, 0.85, 0.14),
	p_max_particles: int = 2000,
	p_per_chunk: int = 30
) -> ParallaxLayerConfig:
	var config := ParallaxLayerConfig.new()
	config.layer_type = LayerType.DUST_FIELD
	config.scroll_scale = p_scroll_scale
	config.dust_color = p_color
	config.dust_max_particles = p_max_particles
	config.dust_per_chunk = p_per_chunk
	return config
