extends Node

signal map_changed(map_id: String)
signal map_loading_started(map_id: String)
signal map_loading_finished(map_id: String)
signal teleporter_registered(teleporter_id: String, destination_map_id: String)

const DEFAULT_MAP := "default_space"
const MAPS_RESOURCE_PATH := "res://resources/maps/"

var current_map_id: String = ""
var current_map_data: MapData = null
var _maps: Dictionary = {}
var _teleporter_registry: Dictionary = {}


func _ready() -> void:
	_load_map_definitions()


func _load_map_definitions() -> void:
	var dir := DirAccess.open(MAPS_RESOURCE_PATH)
	
	if dir == null:
		push_warning("[MapManager] Maps directory not found, using defaults")
		_create_default_maps()
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path := MAPS_RESOURCE_PATH + file_name
			var map_res := load(resource_path)
			if map_res is MapData:
				_maps[map_res.map_id] = map_res
				print("[MapManager] Loaded map: ", map_res.map_id)
		file_name = dir.get_next()
	
	if _maps.is_empty():
		_create_default_maps()


func _create_default_maps() -> void:
	var default_space := MapData.create_default_space()
	_maps[default_space.map_id] = default_space
	
	var hostile := MapData.create_hostile_sector()
	_maps[hostile.map_id] = hostile
	
	var resource := MapData.create_resource_nebula()
	_maps[resource.map_id] = resource
	
	var void_sector := MapData.create_void_sector()
	_maps[void_sector.map_id] = void_sector
	
	var home := MapData.create_home_base()
	_maps[home.map_id] = home
	
	_setup_default_connections()
	
	print("[MapManager] Created ", _maps.size(), " default maps")


func _setup_default_connections() -> void:
	if _maps.has("home_base"):
		var home_map := _maps["home_base"] as MapData
		if home_map:
			var ids_home: Array[String] = ["default_space"]
			home_map.connected_map_ids = ids_home
	
	if _maps.has("default_space"):
		var default_map := _maps["default_space"] as MapData
		if default_map:
			var ids_default: Array[String] = [
				"home_base",
				"hostile_sector",
				"resource_nebula",
				"void_sector"
			]
			default_map.connected_map_ids = ids_default
	
	if _maps.has("hostile_sector"):
		var hostile_map := _maps["hostile_sector"] as MapData
		if hostile_map:
			var ids_hostile: Array[String] = ["default_space"]
			hostile_map.connected_map_ids = ids_hostile
	
	if _maps.has("resource_nebula"):
		var resource_map := _maps["resource_nebula"] as MapData
		if resource_map:
			var ids_resource: Array[String] = ["default_space"]
			resource_map.connected_map_ids = ids_resource
	
	if _maps.has("void_sector"):
		var void_map := _maps["void_sector"] as MapData
		if void_map:
			var ids_void: Array[String] = ["default_space"]
			void_map.connected_map_ids = ids_void


func get_map_data(map_id: String) -> MapData:
	return _maps.get(map_id, _maps.get(DEFAULT_MAP))


func get_all_maps() -> Array[MapData]:
	var result: Array[MapData] = []
	for map in _maps.values():
		result.append(map)
	return result


func get_connected_maps(map_id: String) -> Array[MapData]:
	var result: Array[MapData] = []
	var map_data := get_map_data(map_id)
	if map_data == null:
		return result
	
	for connected_id in map_data.connected_map_ids:
		if _maps.has(connected_id):
			result.append(_maps[connected_id])
	
	return result


func teleport_to_map(map_id: String, spawn_position: Vector2 = Vector2.INF) -> void:
	if map_id == current_map_id:
		return
	
	if not _maps.has(map_id):
		push_error("[MapManager] Unknown map: " + map_id)
		return
	
	map_loading_started.emit(map_id)
	
	var previous_map := current_map_id
	current_map_id = map_id
	current_map_data = _maps[map_id]
	
	var _actual_spawn := spawn_position
	if spawn_position == Vector2.INF:
		_actual_spawn = current_map_data.player_spawn_position
	
	map_changed.emit(map_id)
	map_loading_finished.emit(map_id)
	
	print("[MapManager] Teleported from '", previous_map, "' to '", map_id, "'")


func get_current_map() -> MapData:
	if current_map_data == null and current_map_id != "":
		current_map_data = get_map_data(current_map_id)
	return current_map_data


func set_initial_map(map_id: String) -> void:
	if not _maps.has(map_id):
		push_warning("[MapManager] Initial map not found: ", map_id, ", using default")
		map_id = DEFAULT_MAP
	
	current_map_id = map_id
	current_map_data = _maps[map_id]
	print("[MapManager] Initial map set to: ", map_id)


func register_teleporter(teleporter_id: String, source_map_id: String, destination_map_id: String, destination_position: Vector2 = Vector2.ZERO) -> void:
	_teleporter_registry[teleporter_id] = {
		"source_map": source_map_id,
		"destination_map": destination_map_id,
		"destination_position": destination_position
	}
	teleporter_registered.emit(teleporter_id, destination_map_id)


func get_teleporter_destination(teleporter_id: String) -> Dictionary:
	return _teleporter_registry.get(teleporter_id, {})


func use_teleporter(teleporter_id: String) -> bool:
	var teleporter_data := get_teleporter_destination(teleporter_id)
	if teleporter_data.is_empty():
		push_error("[MapManager] Teleporter not found: ", teleporter_id)
		return false
	
	teleport_to_map(teleporter_data.destination_map, teleporter_data.destination_position)
	return true


func has_map(map_id: String) -> bool:
	return _maps.has(map_id)


func get_map_count() -> int:
	return _maps.size()


func add_map(map_data: MapData) -> void:
	if map_data == null or map_data.map_id.is_empty():
		push_error("[MapManager] Invalid map data")
		return
	
	_maps[map_data.map_id] = map_data
	print("[MapManager] Added map: ", map_data.map_id)


func get_save_data() -> Dictionary:
	return {
		"current_map_id": current_map_id,
		"teleporter_registry": _teleporter_registry.duplicate()
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("current_map_id"):
		set_initial_map(data.current_map_id)
	if data.has("teleporter_registry"):
		_teleporter_registry = data.teleporter_registry.duplicate()
