extends GutTest

var _manager: Node


func before_each() -> void:
	_manager = load("res://autoload/resource_manager.gd").new()
	add_child(_manager)


func after_each() -> void:
	_manager.free()


func test_add_and_remove_resources_clamp_invalid_amounts() -> void:
	assert_eq(_manager.add_resource(ResourceData.ResourceType.IRON, 3), 3)
	assert_eq(_manager.add_resource(ResourceData.ResourceType.IRON, -2), 3)
	assert_true(_manager.remove_resource(ResourceData.ResourceType.IRON, 2))
	assert_false(_manager.remove_resource(ResourceData.ResourceType.IRON, 5))
	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.IRON), 1)


func test_get_resources_returns_inventory_copy() -> void:
	_manager.add_resource(ResourceData.ResourceType.GOLD, 2)
	var resources: Dictionary = _manager.get_resources()
	resources[int(ResourceData.ResourceType.GOLD)] = 99

	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.GOLD), 2)


func test_save_data_round_trips_resources_without_credits() -> void:
	_manager.add_resource(ResourceData.ResourceType.CRYSTAL, 4)
	var data: Dictionary = _manager.get_save_data()

	assert_false(data.has("credits"))
	_manager.reset()
	_manager.load_save_data(data)

	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.CRYSTAL), 4)


func test_legacy_credit_key_is_ignored_on_load() -> void:
	_manager.load_save_data({
		"credits": 999,
		"resources": {
			int(ResourceData.ResourceType.SCRAP): 3
		}
	})

	var data: Dictionary = _manager.get_save_data()
	assert_false(data.has("credits"))
	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.SCRAP), 3)
