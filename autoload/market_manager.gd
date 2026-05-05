extends Node

signal market_changed(market_cycle: int)

const BUY_MARKUP := 1.1
const SELL_MARKDOWN := 0.9
const MIN_PRICE_FACTOR := 0.6
const MAX_PRICE_FACTOR := 1.6
const RESOURCE_TYPES := [
	ResourceData.ResourceType.IRON,
	ResourceData.ResourceType.GOLD,
	ResourceData.ResourceType.CRYSTAL,
	ResourceData.ResourceType.ICE,
	ResourceData.ResourceType.FUEL,
	ResourceData.ResourceType.SCRAP,
]

var market_cycle: int = 0
var _last_map_id: String = ""
var _has_seen_map: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MapManager.map_changed.connect(_on_map_changed)


func reset() -> void:
	market_cycle = 0
	_last_map_id = ""
	_has_seen_map = false
	market_changed.emit(market_cycle)


func sync_current_map() -> void:
	_last_map_id = MapManager.current_map_id
	_has_seen_map = not _last_map_id.is_empty()


func advance_market_cycle() -> int:
	market_cycle += 1
	market_changed.emit(market_cycle)
	return market_cycle


func get_unit_price(resource_type: ResourceData.ResourceType) -> int:
	var base_value := ResourceData.get_base_value(resource_type)
	return maxi(1, int(round(float(base_value) * _get_price_factor(resource_type))))


func quote_buy(target_type: ResourceData.ResourceType, payment_type: ResourceData.ResourceType, amount: int = 1) -> int:
	if not _is_valid_resource_pair(target_type, payment_type) or amount <= 0:
		return 0
	var target_value := float(get_unit_price(target_type) * amount) * BUY_MARKUP
	return maxi(1, int(ceil(target_value / float(get_unit_price(payment_type)))))


func quote_sell(sold_type: ResourceData.ResourceType, payout_type: ResourceData.ResourceType, amount: int = 1) -> int:
	if not _is_valid_resource_pair(sold_type, payout_type) or amount <= 0:
		return 0
	var sold_value := float(get_unit_price(sold_type) * amount) * SELL_MARKDOWN
	return maxi(0, int(floor(sold_value / float(get_unit_price(payout_type)))))


func can_buy_resource(target_type: ResourceData.ResourceType, payment_type: ResourceData.ResourceType, amount: int = 1) -> bool:
	var cost := quote_buy(target_type, payment_type, amount)
	return cost > 0 and ResourceManager.get_resource_amount(payment_type) >= cost


func can_sell_resource(sold_type: ResourceData.ResourceType, payout_type: ResourceData.ResourceType, amount: int = 1) -> bool:
	return quote_sell(sold_type, payout_type, amount) > 0 and ResourceManager.get_resource_amount(sold_type) >= amount


func buy_resource(target_type: ResourceData.ResourceType, payment_type: ResourceData.ResourceType, amount: int = 1) -> bool:
	var cost := quote_buy(target_type, payment_type, amount)
	if cost <= 0 or ResourceManager.get_resource_amount(payment_type) < cost:
		return false
	if not ResourceManager.remove_resource(payment_type, cost):
		return false
	ResourceManager.add_resource(target_type, amount)
	market_changed.emit(market_cycle)
	return true


func sell_resource(sold_type: ResourceData.ResourceType, payout_type: ResourceData.ResourceType, amount: int = 1) -> bool:
	var payout := quote_sell(sold_type, payout_type, amount)
	if payout <= 0 or ResourceManager.get_resource_amount(sold_type) < amount:
		return false
	if not ResourceManager.remove_resource(sold_type, amount):
		return false
	ResourceManager.add_resource(payout_type, payout)
	market_changed.emit(market_cycle)
	return true


func get_save_data() -> Dictionary:
	return {
		"market_cycle": market_cycle
	}


func load_save_data(data: Dictionary) -> void:
	market_cycle = maxi(0, int(data.get("market_cycle", 0)))
	sync_current_map()
	market_changed.emit(market_cycle)


func _on_map_changed(map_id: String) -> void:
	if not _has_seen_map:
		_has_seen_map = true
		_last_map_id = map_id
		return
	if map_id != _last_map_id:
		_last_map_id = map_id
		advance_market_cycle()


func _is_valid_resource_pair(first_type: ResourceData.ResourceType, second_type: ResourceData.ResourceType) -> bool:
	return RESOURCE_TYPES.has(first_type) and RESOURCE_TYPES.has(second_type) and first_type != second_type


func _get_price_factor(resource_type: ResourceData.ResourceType) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_market_seed(resource_type)
	return rng.randf_range(MIN_PRICE_FACTOR, MAX_PRICE_FACTOR)


func _get_market_seed(resource_type: ResourceData.ResourceType) -> int:
	return hash("%s:%s:%s:%s" % [
		SeedManager.master_seed,
		MapManager.current_map_id,
		int(resource_type),
		market_cycle
	])
