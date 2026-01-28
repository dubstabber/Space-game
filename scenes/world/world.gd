extends Node2D

@onready var parallax_background: Node2D = $ParallaxBackground
@onready var player: CharacterBody2D = $Entities/Player
@onready var player_camera: Camera2D = $PlayerCamera
@onready var asteroid_spawner: Node2D = $AsteroidSpawner
@onready var portals_container: Node2D = $Portals

var _current_universe_data: UniverseData
var _current_map_data: MapData
var _minimap: Control = null
var _portal_slots: Array = []
var _world_map_size: Vector2 = Vector2(4000, 4000)

const PortalScene := preload("res://scenes/environment/portals/universe_portal.tscn")
const Minimap := preload("res://scenes/ui/hud/minimap.gd")
var _arrival_from_map: String = ""
var _arrival_to_map: String = ""
var _has_pending_arrival: bool = false


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
	
	if player:
		var placed := false
		# If we just arrived via teleport into this map, spawn near the return portal
		if _has_pending_arrival and MapManager.current_map_id == _arrival_to_map and _arrival_from_map != "":
			if portals_container:
				var return_portal_pos := Vector2.INF
				for portal in portals_container.get_children():
					# Universe portal exposes destination_map_id as exported var
					if portal.destination_map_id == _arrival_from_map:
						return_portal_pos = portal.global_position
						break
				if return_portal_pos != Vector2.INF:
					var rng := RandomNumberGenerator.new()
					rng.randomize()
					var angle := rng.randf_range(0.0, TAU)
					var min_radius := 120.0
					var max_radius := 150.0
					var radius := rng.randf_range(min_radius, max_radius)
					var spawn := return_portal_pos + Vector2(cos(angle), sin(angle)) * radius
					player.global_position = spawn
					# Snap camera to player position immediately
					if player_camera:
						player_camera.global_position = spawn
					placed = true
			_has_pending_arrival = false
			_arrival_from_map = ""
			_arrival_to_map = ""
		
		if not placed and _current_map_data.player_spawn_position != Vector2.ZERO:
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
		_update_minimap_portals([])
		return
	
	var rng := RandomNumberGenerator.new()
	rng.seed = SeedManager.get_entity_seed(MapManager.current_map_id, "portals", 0)
	
	_portal_slots = Minimap.get_random_portal_slots(portal_count, rng)
	
	var portal_positions: Array[Vector2] = []
	
	for i in range(portal_count):
		var destination := connected_maps[i]
		var slot: int = _portal_slots[i]
		var pos := _get_world_position_for_slot(slot)
		
		var portal := PortalScene.instantiate()
		portal.initialize("portal_%s_%s" % [MapManager.current_map_id, destination], destination)
		portals_container.add_child(portal)
		portal.global_position = pos
		# Capture teleport start to compute arrival spawn on the next map
		portal.teleport_started.connect(func(dest_map_id: String) -> void:
			_arrival_from_map = MapManager.current_map_id
			_arrival_to_map = dest_map_id
			_has_pending_arrival = true
		)
		portal_positions.append(pos)
		print("[World] Spawned portal to '%s' at %s" % [destination, pos])
	
	_update_minimap_portals(portal_positions)


func _get_world_position_for_slot(slot: int) -> Vector2:
	var padding_ratio := 0.15
	var half_world := _world_map_size / 2.0
	var padded_half := half_world * (1.0 - padding_ratio)
	
	var col := slot % 3
	var row := slot / 3
	
	var x := -padded_half.x + padded_half.x * col
	var y := -padded_half.y + padded_half.y * row
	
	return Vector2(x, y)


func _update_minimap_portals(world_positions: Array[Vector2]) -> void:
	if _minimap == null:
		return
	_minimap.set_portal_positions(world_positions)


func set_minimap(minimap: Control) -> void:
	_minimap = minimap
	_current_map_data = MapManager.get_current_map()
	
	if _current_map_data:
		_world_map_size = _current_map_data.world_map_size
	
	if _minimap:
		_minimap.set_world_map_size(_world_map_size)
		if player:
			_minimap.set_player(player)
	
	if asteroid_spawner:
		asteroid_spawner.set_world_bounds(_world_map_size)
	
	_spawn_portals()
