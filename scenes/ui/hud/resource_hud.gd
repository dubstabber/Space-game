extends Control

const RESOURCE_TYPES := [
	ResourceData.ResourceType.IRON,
	ResourceData.ResourceType.GOLD,
	ResourceData.ResourceType.CRYSTAL,
	ResourceData.ResourceType.ICE,
	ResourceData.ResourceType.FUEL,
	ResourceData.ResourceType.SCRAP,
]

@onready var label: Label = $PanelContainer/MarginContainer/Label


func _ready() -> void:
	ResourceManager.inventory_changed.connect(_on_inventory_changed)
	_update_text()


func _on_inventory_changed(_value = null) -> void:
	_update_text()


func _update_text() -> void:
	var parts: Array[String] = []
	for resource_type in RESOURCE_TYPES:
		var amount := ResourceManager.get_resource_amount(resource_type)
		if amount > 0:
			parts.append("%s: %d" % [ResourceData.get_type_name(resource_type).capitalize(), amount])
	label.text = "Resources: none" if parts.is_empty() else "  ".join(parts)
