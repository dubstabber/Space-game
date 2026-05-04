extends Node

signal credits_changed(credits: int)
signal resource_changed(resource_type: ResourceData.ResourceType, amount: int)
signal inventory_changed

var credits: int = 0
var _resources: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func add_resource(resource_type: ResourceData.ResourceType, amount: int) -> int:
	if amount <= 0:
		return get_resource_amount(resource_type)
	var current := get_resource_amount(resource_type) + amount
	_resources[int(resource_type)] = current
	resource_changed.emit(resource_type, current)
	inventory_changed.emit()
	return current


func remove_resource(resource_type: ResourceData.ResourceType, amount: int) -> bool:
	if amount <= 0 or get_resource_amount(resource_type) < amount:
		return false
	var current := get_resource_amount(resource_type) - amount
	if current <= 0:
		_resources.erase(int(resource_type))
	else:
		_resources[int(resource_type)] = current
	resource_changed.emit(resource_type, current)
	inventory_changed.emit()
	return true


func get_resource_amount(resource_type: ResourceData.ResourceType) -> int:
	return int(_resources.get(int(resource_type), 0))


func get_resources() -> Dictionary:
	return _resources.duplicate()


func add_credits(amount: int) -> int:
	if amount <= 0:
		return credits
	credits += amount
	credits_changed.emit(credits)
	return credits


func spend_credits(amount: int) -> bool:
	if amount <= 0 or credits < amount:
		return false
	credits -= amount
	credits_changed.emit(credits)
	return true


func sell_resource(resource_type: ResourceData.ResourceType, amount: int) -> int:
	var sell_amount := mini(amount, get_resource_amount(resource_type))
	if sell_amount <= 0:
		return 0
	if not remove_resource(resource_type, sell_amount):
		return 0
	var value := sell_amount * ResourceData.get_base_value(resource_type)
	add_credits(value)
	return value


func sell_all_resources() -> int:
	var total := 0
	for key in _resources.keys():
		var resource_type := int(key) as ResourceData.ResourceType
		total += sell_resource(resource_type, get_resource_amount(resource_type))
	return total


func reset() -> void:
	credits = 0
	_resources.clear()
	credits_changed.emit(credits)
	inventory_changed.emit()


func get_save_data() -> Dictionary:
	return {
		"credits": credits,
		"resources": _resources.duplicate()
	}


func load_save_data(data: Dictionary) -> void:
	credits = maxi(0, int(data.get("credits", 0)))
	_resources.clear()
	var saved_resources: Dictionary = data.get("resources", {})
	for key in saved_resources.keys():
		var amount := maxi(0, int(saved_resources[key]))
		if amount > 0:
			_resources[int(key)] = amount
	credits_changed.emit(credits)
	inventory_changed.emit()
