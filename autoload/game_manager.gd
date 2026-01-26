extends Node

signal game_paused
signal game_resumed
signal game_state_changed(new_state: GameState)
signal new_game_started
signal game_loaded

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	IN_BASE,
	TRANSITIONING
}

var current_state: GameState = GameState.MENU
var _previous_state: GameState = GameState.MENU


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state in [GameState.PLAYING, GameState.PAUSED]:
		toggle_pause()


func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	
	_previous_state = current_state
	current_state = new_state
	game_state_changed.emit(new_state)
	
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			game_paused.emit()
		GameState.PLAYING, GameState.IN_BASE:
			get_tree().paused = false
			game_resumed.emit()


func toggle_pause() -> void:
	if current_state == GameState.PAUSED:
		change_state(_previous_state)
	elif current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)


func start_new_game(initial_map_id: String = "default_space") -> void:
	SeedManager.initialize_new_game()
	MapManager.set_initial_map(initial_map_id)
	change_state(GameState.PLAYING)
	new_game_started.emit()
	print("[GameManager] New game started on map: ", initial_map_id)


func start_game() -> void:
	if not SeedManager.is_initialized():
		start_new_game()
	else:
		change_state(GameState.PLAYING)


func load_game() -> bool:
	if not SeedManager.load_from_file():
		push_warning("[GameManager] No save found, starting new game")
		start_new_game()
		return false
	
	MapManager.set_initial_map(MapManager.current_map_id)
	change_state(GameState.PLAYING)
	game_loaded.emit()
	print("[GameManager] Game loaded")
	return true


func save_game() -> bool:
	var success := SeedManager.save_to_file()
	if success:
		print("[GameManager] Game saved")
	return success


func enter_base() -> void:
	change_state(GameState.IN_BASE)


func exit_base() -> void:
	change_state(GameState.PLAYING)


func return_to_menu() -> void:
	change_state(GameState.MENU)


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_in_base() -> bool:
	return current_state == GameState.IN_BASE


func get_full_save_data() -> Dictionary:
	return {
		"seed_data": SeedManager.get_save_data(),
		"map_data": MapManager.get_save_data(),
		"game_state": {
			"current_state": current_state
		}
	}


func load_full_save_data(data: Dictionary) -> void:
	if data.has("seed_data"):
		var seed_data: Dictionary = data.seed_data
		SeedManager.initialize_from_save(
			seed_data.get("master_seed", 0),
			seed_data.get("map_seeds", {})
		)
	
	if data.has("map_data"):
		MapManager.load_save_data(data.map_data)
