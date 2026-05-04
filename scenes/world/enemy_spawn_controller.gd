extends Node

@export var spawner_root_path: NodePath = NodePath("..")

var _spawner_root: Node = null


func _ready() -> void:
	_spawner_root = get_node_or_null(spawner_root_path)
	MapManager.map_changed.connect(_on_map_changed)
	apply_map_data(MapManager.get_current_map())


func apply_map_data(map_data: MapData) -> void:
	if map_data == null:
		return
	_set_spawners_enabled(map_data.enemy_spawn_rate > 0.0)


func _set_spawners_enabled(enabled: bool) -> void:
	if _spawner_root == null:
		return
	for child in _spawner_root.get_children():
		_apply_to_node(child, enabled)


func _apply_to_node(node: Node, enabled: bool) -> void:
	if "enabled" in node:
		node.enabled = enabled
		if not enabled and node.has_method("clear_all_enemies"):
			node.clear_all_enemies()
	for child in node.get_children():
		_apply_to_node(child, enabled)


func _on_map_changed(_map_id: String) -> void:
	apply_map_data(MapManager.get_current_map())
