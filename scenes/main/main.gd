extends Node

@onready var world: Node2D = $World
@onready var minimap: Control = $CanvasLayer/Minimap


func _ready() -> void:
	MapManager.set_initial_map(MapManager.DEFAULT_MAP)
	
	if world and minimap:
		world.set_minimap(minimap)
