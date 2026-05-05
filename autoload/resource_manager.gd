extends Node

signal resource_changed(resource_type: ResourceData.ResourceType, amount: int)
signal inventory_changed

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


func reset() -> void:
	_resources.clear()
	inventory_changed.emit()


func get_save_data() -> Dictionary:
	return {
		"resources": _resources.duplicate()
	}


func load_save_data(data: Dictionary) -> void:
	_resources.clear()
	var saved_resources: Dictionary = data.get("resources", {})
	for key in saved_resources.keys():
		var amount := maxi(0, int(saved_resources[key]))
		if amount > 0:
			_resources[int(key)] = amount
	inventory_changed.emit()
