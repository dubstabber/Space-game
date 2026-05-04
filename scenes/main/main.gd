extends Node

@onready var world: Node2D = $World
@onready var minimap: Control = $CanvasLayer/Minimap


func _ready() -> void:
	MapManager.set_initial_map("home_base")
	
	if world and minimap:
		world.set_minimap(minimap)
