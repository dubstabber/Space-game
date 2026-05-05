extends GutTest


const Minimap := preload("res://scenes/ui/hud/minimap.gd")


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


func test_resource_hud_renders_resources_without_credits() -> void:
	ResourceManager.reset()
	var hud: Control = load("res://scenes/ui/hud/resource_hud.tscn").instantiate()
	add_child(hud)
	await wait_idle_frames(1)

	var label: Label = hud.get_node("PanelContainer/MarginContainer/Label")
	assert_false(label.text.contains("Credit"))
	assert_eq(label.text, "Resources: none")

	ResourceManager.add_resource(ResourceData.ResourceType.ICE, 3)
	await wait_idle_frames(1)

	assert_false(label.text.contains("Credit"))
	assert_true(label.text.contains("Ice: 3"))
	hud.free()


func test_base_panel_repairs_with_scrap() -> void:
	ResourceManager.reset()
	ResourceManager.add_resource(ResourceData.ResourceType.SCRAP, 2)
	var player := RepairPlayer.new()
	player.add_to_group("player")
	add_child(player)
	var panel: Control = load("res://scenes/ui/base_ui/base_economy_panel.tscn").instantiate()
	add_child(panel)

	GameManager.change_state(GameManager.GameState.IN_BASE)
	await wait_idle_frames(1)
	panel._on_repair_pressed()

	assert_eq(player.current_health, player.max_health)
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.SCRAP), 0)
	GameManager.change_state(GameManager.GameState.PLAYING)
	panel.free()
	player.free()


func test_portal_slot_world_positions_stay_inside_minimap_world_bounds() -> void:
	var world: Node2D = load("res://scenes/world/world.gd").new()
	var world_size := Vector2(40000, 40000)
	world._world_map_size = world_size
	var half_world := world_size / 2.0
	var slots := [
		Minimap.PortalPosition.TOP_LEFT,
		Minimap.PortalPosition.TOP_MIDDLE,
		Minimap.PortalPosition.TOP_RIGHT,
		Minimap.PortalPosition.MIDDLE_LEFT,
		Minimap.PortalPosition.MIDDLE_RIGHT,
		Minimap.PortalPosition.BOTTOM_LEFT,
		Minimap.PortalPosition.BOTTOM_MIDDLE,
		Minimap.PortalPosition.BOTTOM_RIGHT,
	]

	for slot in slots:
		var pos: Vector2 = world._get_world_position_for_slot(slot)
		assert_between(pos.x, -half_world.x, half_world.x)
		assert_between(pos.y, -half_world.y, half_world.y)
	world.free()


func test_player_base_spawn_stays_inside_minimap_world_bounds() -> void:
	var target_seed := _find_seed_for_first_portal_slot(Minimap.PortalPosition.BOTTOM_RIGHT)
	assert_gt(target_seed, 0)
	SeedManager.initialize_from_save(target_seed, {})
	MapManager.set_initial_map("home_base")
	var base: Area2D = load("res://scenes/environment/base/player_base.tscn").instantiate()
	add_child(base)
	await wait_idle_frames(1)

	var map_data := MapManager.get_current_map()
	var half_world := map_data.world_map_size / 2.0
	assert_between(base.global_position.x, -half_world.x, half_world.x)
	assert_between(base.global_position.y, -half_world.y, half_world.y)
	assert_eq(map_data.player_spawn_position, base.global_position)
	base.free()
	MapManager.set_initial_map("default_space")


func test_enemy_spawn_controller_disables_safe_map_spawners() -> void:
	MapManager.set_initial_map("default_space")
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


func _find_seed_for_first_portal_slot(slot: Minimap.PortalPosition) -> int:
	for candidate_seed in range(1, 500):
		var rng := RandomNumberGenerator.new()
		var map_seed := hash(str(candidate_seed) + "home_base")
		rng.seed = hash(str(map_seed) + "portals" + str(0))
		var slots := Minimap.get_random_portal_slots(1, rng)
		if slots.size() == 1 and slots[0] == slot:
			return candidate_seed
	return -1


class DummySpawner:
	extends Node
	var enabled := true
	var clear_count := 0

	func clear_all_enemies() -> void:
		clear_count += 1


class RepairPlayer:
	extends CharacterBody2D
	var current_health := 11
	var max_health := 20

	func heal(amount: int) -> void:
		current_health = mini(max_health, current_health + amount)
