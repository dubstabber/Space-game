extends Node

signal universe_changed(universe_id: String)
signal universe_loading_started
signal universe_loading_finished

const DEFAULT_UNIVERSE := "normal"

var current_universe_id: String = DEFAULT_UNIVERSE
var current_universe_data: UniverseData = null
var _universes: Dictionary = {}


func _ready() -> void:
	_load_universe_definitions()


func _load_universe_definitions() -> void:
	var universe_dir := "res://resources/universe_types/"
	var dir := DirAccess.open(universe_dir)
	
	if dir == null:
		push_warning("Universe types directory not found, using defaults")
		_create_default_universes()
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path := universe_dir + file_name
			var universe_res := load(resource_path)
			if universe_res is UniverseData:
				_universes[universe_res.universe_id] = universe_res
		file_name = dir.get_next()
	
	if _universes.is_empty():
		_create_default_universes()


func _create_default_universes() -> void:
	var normal := UniverseData.new()
	normal.universe_id = "normal"
	normal.universe_name = "Normal Space"
	normal.background_color = Color(0.02, 0.02, 0.05)
	normal.star_density = 1.0
	normal.asteroid_density = 1.0
	normal.enemy_spawn_rate = 1.0
	normal.danger_level = 1
	_universes["normal"] = normal
	
	var hostile := UniverseData.new()
	hostile.universe_id = "hostile"
	hostile.universe_name = "Hostile Sector"
	hostile.background_color = Color(0.08, 0.02, 0.02)
	hostile.star_density = 0.5
	hostile.asteroid_density = 2.0
	hostile.enemy_spawn_rate = 3.0
	hostile.danger_level = 3
	_universes["hostile"] = hostile
	
	var rich := UniverseData.new()
	rich.universe_id = "resource_rich"
	rich.universe_name = "Resource Nebula"
	rich.background_color = Color(0.02, 0.05, 0.08)
	rich.star_density = 1.5
	rich.asteroid_density = 3.0
	rich.enemy_spawn_rate = 2.0
	rich.danger_level = 2
	_universes["resource_rich"] = rich


func get_universe_data(universe_id: String) -> UniverseData:
	return _universes.get(universe_id, _universes.get(DEFAULT_UNIVERSE))


func get_all_universes() -> Array[UniverseData]:
	var result: Array[UniverseData] = []
	for universe in _universes.values():
		result.append(universe)
	return result


func teleport_to_universe(universe_id: String) -> void:
	if universe_id == current_universe_id:
		return
	
	if not _universes.has(universe_id):
		push_error("Unknown universe: " + universe_id)
		return
	
	universe_loading_started.emit()
	
	current_universe_id = universe_id
	current_universe_data = _universes[universe_id]
	
	universe_changed.emit(universe_id)
	universe_loading_finished.emit()


func get_current_universe() -> UniverseData:
	if current_universe_data == null:
		current_universe_data = get_universe_data(current_universe_id)
	return current_universe_data
