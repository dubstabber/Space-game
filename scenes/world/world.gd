extends Node2D

@onready var parallax_background: Node2D = $ParallaxBackground
@onready var player: CharacterBody2D = $Entities/Player
@onready var player_camera: Camera2D = $PlayerCamera
@onready var asteroid_spawner: Node2D = $AsteroidSpawner
@onready var portals_container: Node2D = $Portals

var _current_universe_data: UniverseData
var _current_map_data: MapData

const PortalScene := preload("res://scenes/environment/portals/universe_portal.tscn")


func _ready() -> void:
	UniverseManager.universe_changed.connect(_on_universe_changed)
	MapManager.map_changed.connect(_on_map_changed)
	
	_apply_universe_settings(UniverseManager.get_current_universe())
	
	if player_camera and player:
		player_camera.set_target(player)
	
	if asteroid_spawner and player:
		asteroid_spawner.set_target(player)
	
	_setup_current_map()


func _on_universe_changed(_universe_id: String) -> void:
	_apply_universe_settings(UniverseManager.get_current_universe())


func _apply_universe_settings(universe_data: UniverseData) -> void:
	if universe_data == null:
		return
	
	_current_universe_data = universe_data
	
	if parallax_background:
		parallax_background.apply_universe_settings(universe_data)


func _on_map_changed(_map_id: String) -> void:
	_setup_current_map()


func _setup_current_map() -> void:
	_current_map_data = MapManager.get_current_map()
	if _current_map_data == null:
		return
	
	if asteroid_spawner:
		asteroid_spawner.set_density(_current_map_data.asteroid_density)
		asteroid_spawner.clear_all_asteroids()
	
	_spawn_portals()
	
	if player and _current_map_data.player_spawn_position != Vector2.ZERO:
		player.global_position = _current_map_data.player_spawn_position


func _spawn_portals() -> void:
	if portals_container == null:
		return
	
	for child in portals_container.get_children():
		child.queue_free()
	
	if _current_map_data == null:
		return
	
	var connected_maps := _current_map_data.connected_map_ids
	var portal_count := connected_maps.size()
	
	if portal_count == 0:
		return
	
	var rng := RandomNumberGenerator.new()
	rng.seed = SeedManager.get_entity_seed(MapManager.current_map_id, "portals", 0)
	
	for i in range(portal_count):
		var destination := connected_maps[i]
		var angle := (TAU / portal_count) * i + rng.randf_range(-0.2, 0.2)
		var distance := rng.randf_range(800.0, 1200.0)
		var pos := Vector2(cos(angle), sin(angle)) * distance
		
		var portal := PortalScene.instantiate()
		portal.global_position = pos
		portal.initialize("portal_%s_%s" % [MapManager.current_map_id, destination], destination)
		portals_container.add_child(portal)
