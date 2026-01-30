class_name FactionData
extends Resource

enum FactionID {
	RAIDERS,
	SYNDICATE,
	HIVE
}

@export var faction_id: FactionID = FactionID.RAIDERS
@export var faction_name: String = "Unknown"
@export var description: String = ""

@export_group("Colors")
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY
@export var glow_color: Color = Color.WHITE

@export_group("Behavior")
@export var aggression_level: float = 1.0  ## 0-2, affects attack frequency
@export var coordination_level: float = 1.0  ## 0-2, affects group tactics
@export var preferred_range: float = 300.0  ## Optimal combat distance

@export_group("Stats Modifiers")
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0

@export_group("Spawn Settings")
@export var min_group_size: int = 1
@export var max_group_size: int = 3
@export var spawn_weight: float = 1.0  ## Relative spawn chance


static func get_faction_display_name(id: FactionID) -> String:
	match id:
		FactionID.RAIDERS:
			return "Raiders"
		FactionID.SYNDICATE:
			return "Syndicate"
		FactionID.HIVE:
			return "Hive"
		_:
			return "Unknown"
