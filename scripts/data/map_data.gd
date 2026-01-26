class_name MapData
extends Resource

@export var map_id: String = ""
@export var map_name: String = ""
@export var map_description: String = ""

@export_group("Visual Settings")
@export var background_color: Color = Color(0.02, 0.02, 0.05)
@export var parallax_layers: Array[ParallaxLayerConfig] = []

@export_group("Gameplay Settings")
@export var asteroid_density: float = 1.0
@export var enemy_spawn_rate: float = 1.0
@export var danger_level: int = 1
@export var resource_multiplier: float = 1.0

@export_group("Teleporter Connections")
@export var connected_map_ids: Array[String] = []

@export_group("Spawn Settings")
@export var player_spawn_position: Vector2 = Vector2.ZERO
@export var has_safe_zone: bool = false
@export var safe_zone_radius: float = 500.0


static func create_default_space() -> MapData:
	var map := MapData.new()
	map.map_id = "default_space"
	map.map_name = "Normal Space"
	map.map_description = "A standard sector of space."
	map.background_color = Color(0.02, 0.02, 0.05)
	
	map.parallax_layers = [
		ParallaxLayerConfig.create_nebula_layer(
			Vector2(0.05, 0.05),
			Color(0.4, 0.1, 0.6, 0.6),
			Color(0.667, 0.496, 0.0, 0.5),
			Color(0.1, 0.7, 0.9, 0.4),
			0.11
		),
		ParallaxLayerConfig.create_galaxy_layer(Vector2(0.08, 0.08), 0.43, true),
		ParallaxLayerConfig.create_shader_galaxy_layer(Vector2(0.04, 0.04), 0.245),
		ParallaxLayerConfig.create_star_layer(Vector2(0.1, 0.1), 0, 4000, 15, Color(1, 1, 1, 0.3), 1.0),
		ParallaxLayerConfig.create_star_layer(Vector2(0.2, 0.2), 1, 3000, 12, Color(1, 1, 1, 0.5), 1.5),
		ParallaxLayerConfig.create_star_layer(Vector2(0.3, 0.3), 2, 2000, 10, Color(1, 1, 1, 0.7), 2.0),
		ParallaxLayerConfig.create_star_layer(Vector2(0.5, 0.5), 3, 2000, 8, Color(1, 1, 1, 0.9), 2.5),
		ParallaxLayerConfig.create_dust_layer(Vector2(0.8, 0.8), Color(0.698, 0.749, 0.851, 0.141), 2000, 30),
	]
	
	map.asteroid_density = 1.0
	map.enemy_spawn_rate = 1.0
	map.danger_level = 1
	
	return map


static func create_hostile_sector() -> MapData:
	var map := MapData.new()
	map.map_id = "hostile_sector"
	map.map_name = "Hostile Sector"
	map.map_description = "A dangerous region filled with raiders and pirates."
	map.background_color = Color(0.05, 0.01, 0.02)
	
	map.parallax_layers = [
		ParallaxLayerConfig.create_nebula_layer(
			Vector2(0.05, 0.05),
			Color(0.6, 0.1, 0.1, 0.5),
			Color(0.8, 0.2, 0.0, 0.4),
			Color(1.0, 0.5, 0.2, 0.3),
			0.15
		),
		ParallaxLayerConfig.create_galaxy_layer(Vector2(0.08, 0.08), 0.2, true),
		ParallaxLayerConfig.create_star_layer(Vector2(0.1, 0.1), 0, 3000, 10, Color(1, 0.8, 0.7, 0.3), 1.0),
		ParallaxLayerConfig.create_star_layer(Vector2(0.2, 0.2), 1, 2500, 8, Color(1, 0.7, 0.6, 0.5), 1.5),
		ParallaxLayerConfig.create_star_layer(Vector2(0.4, 0.4), 2, 2000, 6, Color(1, 0.6, 0.5, 0.7), 2.0),
		ParallaxLayerConfig.create_dust_layer(Vector2(0.7, 0.7), Color(0.8, 0.4, 0.3, 0.12), 1500, 25),
	]
	
	map.asteroid_density = 2.0
	map.enemy_spawn_rate = 3.0
	map.danger_level = 3
	map.resource_multiplier = 1.5
	
	return map


static func create_resource_nebula() -> MapData:
	var map := MapData.new()
	map.map_id = "resource_nebula"
	map.map_name = "Resource Nebula"
	map.map_description = "A rich nebula abundant with valuable minerals."
	map.background_color = Color(0.01, 0.03, 0.06)
	
	map.parallax_layers = [
		ParallaxLayerConfig.create_nebula_layer(
			Vector2(0.05, 0.05),
			Color(0.1, 0.3, 0.6, 0.7),
			Color(0.0, 0.5, 0.7, 0.5),
			Color(0.2, 0.8, 1.0, 0.4),
			0.25
		),
		ParallaxLayerConfig.create_shader_galaxy_layer(Vector2(0.04, 0.04), 0.15),
		ParallaxLayerConfig.create_star_layer(Vector2(0.1, 0.1), 0, 5000, 20, Color(0.8, 0.9, 1.0, 0.3), 1.0),
		ParallaxLayerConfig.create_star_layer(Vector2(0.2, 0.2), 1, 4000, 15, Color(0.7, 0.9, 1.0, 0.5), 1.5),
		ParallaxLayerConfig.create_star_layer(Vector2(0.35, 0.35), 2, 3000, 12, Color(0.6, 0.85, 1.0, 0.7), 2.0),
		ParallaxLayerConfig.create_dust_layer(Vector2(0.75, 0.75), Color(0.4, 0.6, 0.9, 0.18), 2500, 40),
	]
	
	map.asteroid_density = 3.0
	map.enemy_spawn_rate = 2.0
	map.danger_level = 2
	map.resource_multiplier = 2.5
	
	return map


static func create_void_sector() -> MapData:
	var map := MapData.new()
	map.map_id = "void_sector"
	map.map_name = "The Void"
	map.map_description = "An eerily empty region of space with sparse star coverage."
	map.background_color = Color(0.005, 0.005, 0.01)
	
	map.parallax_layers = [
		ParallaxLayerConfig.create_shader_galaxy_layer(Vector2(0.03, 0.03), 0.05),
		ParallaxLayerConfig.create_star_layer(Vector2(0.1, 0.1), 0, 1500, 5, Color(0.9, 0.9, 1.0, 0.2), 0.8),
		ParallaxLayerConfig.create_star_layer(Vector2(0.25, 0.25), 1, 1000, 4, Color(0.8, 0.8, 1.0, 0.4), 1.2),
		ParallaxLayerConfig.create_star_layer(Vector2(0.5, 0.5), 2, 800, 3, Color(0.7, 0.7, 1.0, 0.6), 1.8),
	]
	
	map.asteroid_density = 0.3
	map.enemy_spawn_rate = 0.5
	map.danger_level = 1
	map.resource_multiplier = 0.5
	
	return map


static func create_home_base() -> MapData:
	var map := MapData.new()
	map.map_id = "home_base"
	map.map_name = "Home Station"
	map.map_description = "Your home base. A safe haven for trading and repairs."
	map.background_color = Color(0.02, 0.02, 0.04)
	
	map.parallax_layers = [
		ParallaxLayerConfig.create_nebula_layer(
			Vector2(0.05, 0.05),
			Color(0.2, 0.15, 0.4, 0.4),
			Color(0.3, 0.2, 0.5, 0.3),
			Color(0.4, 0.3, 0.6, 0.2),
			0.08
		),
		ParallaxLayerConfig.create_galaxy_layer(Vector2(0.08, 0.08), 0.3, false),
		ParallaxLayerConfig.create_star_layer(Vector2(0.1, 0.1), 0, 4000, 18, Color(1, 1, 0.95, 0.35), 1.0),
		ParallaxLayerConfig.create_star_layer(Vector2(0.2, 0.2), 1, 3500, 14, Color(1, 1, 0.9, 0.55), 1.4),
		ParallaxLayerConfig.create_star_layer(Vector2(0.35, 0.35), 2, 2500, 10, Color(1, 1, 0.85, 0.75), 1.9),
		ParallaxLayerConfig.create_dust_layer(Vector2(0.8, 0.8), Color(0.6, 0.6, 0.75, 0.1), 1800, 25),
	]
	
	map.asteroid_density = 0.5
	map.enemy_spawn_rate = 0.0
	map.danger_level = 0
	map.has_safe_zone = true
	map.safe_zone_radius = 2000.0
	
	return map
