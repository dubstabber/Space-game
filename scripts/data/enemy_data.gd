class_name EnemyData
extends Resource

enum EnemyType {
	SCOUT,
	FIGHTER,
	HEAVY,
	BOSS
}

@export var enemy_type: EnemyType = EnemyType.FIGHTER
@export var display_name: String = "Enemy"
@export var faction_id: FactionData.FactionID = FactionData.FactionID.RAIDERS

@export_group("Stats")
@export var max_health: int = 50
@export var move_speed: float = 150.0
@export var rotation_speed: float = 3.0
@export var collision_damage: int = 10

@export_group("Combat")
@export var attack_damage: int = 5
@export var attack_range: float = 400.0
@export var attack_cooldown: float = 1.0
@export var projectile_speed: float = 500.0

@export_group("Geometry")
@export var ship_size: float = 20.0
@export var ship_style: int = 0  ## Varies geometry generation

@export_group("AI Behavior")
@export var detection_range: float = 600.0
@export var flee_health_percent: float = 0.0  ## 0 = never flee
@export var preferred_distance: float = 250.0
@export var strafe_enabled: bool = false

@export_group("Abilities")
@export var abilities: Array[String] = []  ## Ability IDs

@export_group("Rewards")
@export var xp_reward: int = 10
@export var credit_reward_min: int = 5
@export var credit_reward_max: int = 15
@export var drop_chance: float = 0.1


static func get_type_display_name(type: EnemyType) -> String:
	match type:
		EnemyType.SCOUT:
			return "Scout"
		EnemyType.FIGHTER:
			return "Fighter"
		EnemyType.HEAVY:
			return "Heavy"
		EnemyType.BOSS:
			return "Boss"
		_:
			return "Unknown"
