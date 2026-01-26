class_name ResourceData
extends Resource

enum ResourceType {
	IRON,
	GOLD,
	CRYSTAL,
	ICE,
	FUEL,
	SCRAP
}

@export var resource_type: ResourceType = ResourceType.IRON
@export var display_name: String = "Iron"
@export var base_value: int = 10
@export var color: Color = Color(0.6, 0.55, 0.5)
@export var rarity_weight: float = 1.0


static func get_type_name(type: ResourceType) -> String:
	match type:
		ResourceType.IRON:
			return "iron"
		ResourceType.GOLD:
			return "gold"
		ResourceType.CRYSTAL:
			return "crystal"
		ResourceType.ICE:
			return "ice"
		ResourceType.FUEL:
			return "fuel"
		ResourceType.SCRAP:
			return "scrap"
		_:
			return "unknown"


static func get_resource_color(type: ResourceType) -> Color:
	match type:
		ResourceType.IRON:
			return Color(0.6, 0.55, 0.5)
		ResourceType.GOLD:
			return Color(1.0, 0.85, 0.3)
		ResourceType.CRYSTAL:
			return Color(0.6, 0.8, 1.0)
		ResourceType.ICE:
			return Color(0.8, 0.95, 1.0)
		ResourceType.FUEL:
			return Color(0.2, 0.9, 0.4)
		ResourceType.SCRAP:
			return Color(0.5, 0.5, 0.5)
		_:
			return Color.WHITE


static func get_base_value(type: ResourceType) -> int:
	match type:
		ResourceType.IRON:
			return 10
		ResourceType.GOLD:
			return 50
		ResourceType.CRYSTAL:
			return 75
		ResourceType.ICE:
			return 15
		ResourceType.FUEL:
			return 25
		ResourceType.SCRAP:
			return 5
		_:
			return 1


static func get_rarity_weight(type: ResourceType) -> float:
	match type:
		ResourceType.IRON:
			return 1.0
		ResourceType.GOLD:
			return 0.15
		ResourceType.CRYSTAL:
			return 0.1
		ResourceType.ICE:
			return 0.5
		ResourceType.FUEL:
			return 0.3
		ResourceType.SCRAP:
			return 0.8
		_:
			return 1.0
