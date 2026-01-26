extends Node

signal seeds_initialized
signal seeds_loaded_from_save

const SAVE_FILE_PATH := "user://game_seeds.save"

var master_seed: int = 0
var _map_seeds: Dictionary = {}
var _initialized: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func initialize_new_game() -> void:
	master_seed = _generate_random_seed()
	_map_seeds.clear()
	_initialized = true
	seeds_initialized.emit()
	print("[SeedManager] New game initialized with master seed: ", master_seed)


func initialize_from_save(saved_master_seed: int, saved_map_seeds: Dictionary = {}) -> void:
	master_seed = saved_master_seed
	_map_seeds = saved_map_seeds.duplicate()
	_initialized = true
	seeds_loaded_from_save.emit()
	print("[SeedManager] Loaded from save with master seed: ", master_seed)


func get_map_seed(map_id: String) -> int:
	if not _initialized:
		push_warning("[SeedManager] Seeds not initialized, initializing new game")
		initialize_new_game()
	
	if not _map_seeds.has(map_id):
		_map_seeds[map_id] = _derive_seed_for_map(map_id)
	
	return _map_seeds[map_id]


func get_layer_seed(map_id: String, layer_id: int) -> int:
	var map_seed := get_map_seed(map_id)
	return hash(Vector2i(map_seed, layer_id))


func get_chunk_seed(map_id: String, layer_id: int, chunk_key: Vector2i) -> int:
	var layer_seed := get_layer_seed(map_id, layer_id)
	return hash(Vector3i(chunk_key.x, chunk_key.y, layer_seed))


func get_entity_seed(map_id: String, entity_type: String, entity_index: int) -> int:
	var map_seed := get_map_seed(map_id)
	return hash(str(map_seed) + entity_type + str(entity_index))


func get_random_seed_for_purpose(purpose: String) -> int:
	if not _initialized:
		push_warning("[SeedManager] Seeds not initialized, initializing new game")
		initialize_new_game()
	
	return hash(str(master_seed) + purpose)


func _derive_seed_for_map(map_id: String) -> int:
	return hash(str(master_seed) + map_id)


func _generate_random_seed() -> int:
	randomize()
	return randi()


func get_save_data() -> Dictionary:
	return {
		"master_seed": master_seed,
		"map_seeds": _map_seeds.duplicate()
	}


func is_initialized() -> bool:
	return _initialized


func save_to_file() -> bool:
	var save_data := get_save_data()
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SeedManager] Failed to open save file for writing: ", FileAccess.get_open_error())
		return false
	
	file.store_var(save_data)
	file.close()
	print("[SeedManager] Seeds saved to file")
	return true


func load_from_file() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SeedManager] No save file found")
		return false
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SeedManager] Failed to open save file for reading: ", FileAccess.get_open_error())
		return false
	
	var save_data: Variant = file.get_var()
	file.close()
	
	if save_data is Dictionary and save_data.has("master_seed"):
		initialize_from_save(save_data.master_seed, save_data.get("map_seeds", {}))
		return true
	
	push_error("[SeedManager] Invalid save data format")
	return false


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[SeedManager] Save file cleared")
