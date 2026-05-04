extends GutTest


func test_resource_pickup_collection_updates_resource_manager() -> void:
	ResourceManager.reset()
	var pickup: Node = load("res://scenes/entities/pickups/resource_pickup.tscn").instantiate()
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	add_child(pickup)
	add_child(player)

	pickup.initialize(ResourceData.ResourceType.ICE, 3)
	pickup._collect(player)
	await wait_idle_frames(1)

	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.ICE), 3)
	player.free()


func test_phase5_scenes_instantiate() -> void:
	var paths := [
		"res://scenes/environment/base/player_base.tscn",
		"res://scenes/ui/hud/resource_hud.tscn",
		"res://scenes/ui/base_ui/base_economy_panel.tscn",
	]
	for path in paths:
		var scene := load(path)
		assert_not_null(scene, "%s should load" % path)
		var node: Node = scene.instantiate()
		assert_not_null(node, "%s should instantiate" % path)
		node.free()


func test_enemy_spawn_controller_disables_safe_map_spawners() -> void:
	var controller: Node = load("res://scenes/world/enemy_spawn_controller.gd").new()
	var root := Node.new()
	var spawner := DummySpawner.new()
	root.name = "Root"
	controller.add_child(root)
	root.add_child(spawner)
	controller.spawner_root_path = NodePath("Root")
	add_child(controller)

	controller.apply_map_data(MapData.create_home_base())
	assert_false(spawner.enabled)
	assert_eq(spawner.clear_count, 1)

	controller.apply_map_data(MapData.create_default_space())
	assert_true(spawner.enabled)
	controller.free()


class DummySpawner:
	extends Node
	var enabled := true
	var clear_count := 0

	func clear_all_enemies() -> void:
		clear_count += 1
