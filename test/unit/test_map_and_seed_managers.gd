extends GutTest


var _seed_manager: Node
var _map_manager: Node


func before_each() -> void:
	_seed_manager = load("res://autoload/seed_manager.gd").new()
	_map_manager = load("res://autoload/map_manager.gd").new()
	add_child(_seed_manager)
	add_child(_map_manager)
	_map_manager._create_default_maps()


func after_each() -> void:
	if is_instance_valid(_seed_manager):
		_seed_manager.free()
	if is_instance_valid(_map_manager):
		_map_manager.free()


func test_seed_manager_restores_and_derives_stable_seeds() -> void:
	_seed_manager.initialize_from_save(123456, {"home_base": 77})

	assert_true(_seed_manager.is_initialized())
	assert_eq(_seed_manager.get_map_seed("home_base"), 77)
	assert_eq(_seed_manager.get_map_seed("default_space"), _seed_manager.get_map_seed("default_space"))
	assert_eq(_seed_manager.get_layer_seed("default_space", 2), _seed_manager.get_layer_seed("default_space", 2))
	assert_eq(_seed_manager.get_chunk_seed("default_space", 2, Vector2i(5, -2)), _seed_manager.get_chunk_seed("default_space", 2, Vector2i(5, -2)))


func test_map_manager_default_maps_and_connections_are_created() -> void:
	assert_eq(_map_manager.get_map_count(), 5)
	assert_true(_map_manager.has_map("default_space"))
	assert_true(_map_manager.has_map("home_base"))
	assert_eq(_map_manager.get_connected_maps("default_space").size(), 4)
	assert_eq(_map_manager.get_connected_maps("home_base").size(), 1)


func test_map_lookup_falls_back_to_default_map() -> void:
	var fallback: MapData = _map_manager.get_map_data("missing_map")

	assert_not_null(fallback)
	assert_eq(fallback.map_id, "default_space")


func test_initial_map_falls_back_when_unknown() -> void:
	_map_manager.set_initial_map("not_real")

	assert_eq(_map_manager.current_map_id, "default_space")
	assert_eq(_map_manager.current_map_data.map_id, "default_space")


func test_teleport_to_valid_map_updates_state_and_signals() -> void:
	watch_signals(_map_manager)

	_map_manager.teleport_to_map("hostile_sector")

	assert_eq(_map_manager.current_map_id, "hostile_sector")
	assert_eq(_map_manager.current_map_data.map_id, "hostile_sector")
	assert_signal_emitted(_map_manager, "map_loading_started")
	assert_signal_emitted(_map_manager, "map_changed")
	assert_signal_emitted(_map_manager, "map_loading_finished")


func test_teleport_to_unknown_map_does_not_change_state() -> void:
	_map_manager.set_initial_map("default_space")

	_map_manager.teleport_to_map("not_real")

	assert_eq(_map_manager.current_map_id, "default_space")
	assert_eq(_map_manager.current_map_data.map_id, "default_space")
	assert_push_error("[MapManager] Unknown map: not_real")


func test_teleporter_registry_round_trips_destination_data() -> void:
	watch_signals(_map_manager)

	_map_manager.register_teleporter("portal_a", "default_space", "home_base", Vector2(10, 20))
	var data: Dictionary = _map_manager.get_teleporter_destination("portal_a")

	assert_eq(data.source_map, "default_space")
	assert_eq(data.destination_map, "home_base")
	assert_eq(data.destination_position, Vector2(10, 20))
	assert_signal_emitted(_map_manager, "teleporter_registered")
