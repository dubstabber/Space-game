extends GutTest


func before_each() -> void:
	ResourceManager.reset()
	SeedManager.initialize_from_save(123456, {})
	MarketManager.reset()
	MapManager.set_initial_map("home_base")


func after_each() -> void:
	ResourceManager.reset()
	MarketManager.reset()


func test_prices_are_deterministic_for_same_seed_map_and_cycle() -> void:
	var first_price := MarketManager.get_unit_price(ResourceData.ResourceType.GOLD)

	MarketManager.reset()
	MapManager.set_initial_map("home_base")
	var second_price := MarketManager.get_unit_price(ResourceData.ResourceType.GOLD)

	assert_eq(second_price, first_price)


func test_market_cycle_advances_on_sector_travel() -> void:
	var before_prices := _capture_prices()

	MapManager.teleport_to_map("default_space")

	assert_eq(MarketManager.market_cycle, 1)
	assert_ne(_capture_prices(), before_prices)


func test_invalid_and_self_trades_are_rejected() -> void:
	assert_eq(MarketManager.quote_buy(ResourceData.ResourceType.IRON, ResourceData.ResourceType.IRON), 0)
	assert_eq(MarketManager.quote_sell(ResourceData.ResourceType.IRON, ResourceData.ResourceType.IRON), 0)
	assert_false(MarketManager.buy_resource(ResourceData.ResourceType.IRON, ResourceData.ResourceType.IRON))
	assert_false(MarketManager.sell_resource(ResourceData.ResourceType.IRON, ResourceData.ResourceType.IRON))


func test_buy_requires_available_payment_resource() -> void:
	var cost := MarketManager.quote_buy(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP)

	assert_gt(cost, 0)
	assert_false(MarketManager.buy_resource(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP))
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.GOLD), 0)


func test_buy_converts_payment_resource_to_target_resource_atomically() -> void:
	var cost := MarketManager.quote_buy(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP)
	ResourceManager.add_resource(ResourceData.ResourceType.SCRAP, cost)

	assert_true(MarketManager.buy_resource(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP))
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.SCRAP), 0)
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.GOLD), 1)


func test_sell_converts_sold_resource_to_payout_resource_atomically() -> void:
	var payout := MarketManager.quote_sell(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP)
	ResourceManager.add_resource(ResourceData.ResourceType.GOLD, 1)

	assert_gt(payout, 0)
	assert_true(MarketManager.sell_resource(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP))
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.GOLD), 0)
	assert_eq(ResourceManager.get_resource_amount(ResourceData.ResourceType.SCRAP), payout)


func test_quotes_apply_buy_markup_and_sell_markdown() -> void:
	var gold_price := MarketManager.get_unit_price(ResourceData.ResourceType.GOLD)
	var scrap_price := MarketManager.get_unit_price(ResourceData.ResourceType.SCRAP)
	var expected_buy := int(ceil((float(gold_price) * 1.1) / float(scrap_price)))
	var expected_sell := int(floor((float(gold_price) * 0.9) / float(scrap_price)))

	assert_eq(MarketManager.quote_buy(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP), expected_buy)
	assert_eq(MarketManager.quote_sell(ResourceData.ResourceType.GOLD, ResourceData.ResourceType.SCRAP), expected_sell)


func test_market_cycle_save_data_round_trips() -> void:
	MapManager.teleport_to_map("default_space")
	var data := MarketManager.get_save_data()

	MarketManager.reset()
	MarketManager.load_save_data(data)

	assert_eq(MarketManager.market_cycle, 1)


func _capture_prices() -> Dictionary:
	var prices := {}
	for resource_type in MarketManager.RESOURCE_TYPES:
		prices[int(resource_type)] = MarketManager.get_unit_price(resource_type)
	return prices
