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


func test_credit_spending_requires_available_balance() -> void:
	assert_eq(_manager.add_credits(20), 20)
	assert_false(_manager.spend_credits(25))
	assert_true(_manager.spend_credits(15))
	assert_eq(_manager.credits, 5)


func test_selling_resource_converts_stack_to_credits() -> void:
	_manager.add_resource(ResourceData.ResourceType.GOLD, 2)
	var gained: int = _manager.sell_resource(ResourceData.ResourceType.GOLD, 5)

	assert_eq(gained, ResourceData.get_base_value(ResourceData.ResourceType.GOLD) * 2)
	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.GOLD), 0)
	assert_eq(_manager.credits, gained)


func test_sell_all_resources_returns_combined_value() -> void:
	_manager.add_resource(ResourceData.ResourceType.IRON, 2)
	_manager.add_resource(ResourceData.ResourceType.SCRAP, 3)
	var gained: int = _manager.sell_all_resources()

	assert_eq(gained, 2 * ResourceData.get_base_value(ResourceData.ResourceType.IRON) + 3 * ResourceData.get_base_value(ResourceData.ResourceType.SCRAP))
	assert_eq(_manager.get_resources().size(), 0)


func test_save_data_round_trips_credits_and_resources() -> void:
	_manager.add_credits(42)
	_manager.add_resource(ResourceData.ResourceType.CRYSTAL, 4)
	var data: Dictionary = _manager.get_save_data()

	_manager.reset()
	_manager.load_save_data(data)

	assert_eq(_manager.credits, 42)
	assert_eq(_manager.get_resource_amount(ResourceData.ResourceType.CRYSTAL), 4)
