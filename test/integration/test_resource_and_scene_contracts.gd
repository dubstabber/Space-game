extends GutTest


const SCENE_CONTRACTS := {
	"res://scenes/player/player_ship.tscn": [
		"ShipBody",
		"ShipOutline",
		"EngineGlow",
		"CollisionShape",
		"ProjectileSpawn",
		"HealthBar",
	],
	"res://scenes/entities/asteroids/asteroid.tscn": [
		"Polygon2D",
		"Line2D",
		"CollisionPolygon2D",
	],
	"res://scenes/entities/projectiles/projectile.tscn": [
		"Line2D",
		"CollisionShape2D",
	],
	"res://scenes/entities/enemies/enemy_base.tscn": [
		"Hull",
		"Outline",
		"Details",
		"CollisionShape",
		"HealthComponent",
		"DetectionArea",
		"Hitbox",
		"Abilities",
	],
	"res://scenes/entities/enemies/boss_base.tscn": [
		"Hull",
		"Outline",
		"Details",
		"CollisionShape",
		"HealthComponent",
		"DetectionArea",
		"Hitbox",
		"Abilities",
	],
	"res://scenes/environment/portals/universe_portal.tscn": [
		"CollisionShape2D",
	],
	"res://scenes/ui/hud/minimap.tscn": [],
}

const RESOURCE_PATHS := [
	"res://resources/enemies/enemy_scout.tres",
	"res://resources/enemies/enemy_fighter.tres",
	"res://resources/enemies/enemy_heavy.tres",
	"res://resources/enemies/enemy_boss.tres",
	"res://resources/factions/faction_raiders.tres",
	"res://resources/factions/faction_syndicate.tres",
	"res://resources/factions/faction_hive.tres",
]


func test_core_scenes_instantiate_and_keep_required_children() -> void:
	for scene_path in SCENE_CONTRACTS:
		var packed := load(scene_path)
		assert_not_null(packed, "%s should load" % scene_path)
		assert_true(packed is PackedScene, "%s should be a PackedScene" % scene_path)

		var node := (packed as PackedScene).instantiate()
		assert_not_null(node, "%s should instantiate" % scene_path)

		for child_path in SCENE_CONTRACTS[scene_path]:
			assert_not_null(node.get_node_or_null(child_path), "%s should contain %s" % [scene_path, child_path])

		node.free()


func test_committed_enemy_and_faction_resources_are_valid() -> void:
	for resource_path in RESOURCE_PATHS:
		var resource := load(resource_path)
		assert_not_null(resource, "%s should load" % resource_path)

		if resource is EnemyData:
			var enemy := resource as EnemyData
			assert_gt(enemy.max_health, 0, "%s should have health" % resource_path)
			assert_gt(enemy.move_speed, 0.0, "%s should have movement speed" % resource_path)
			assert_gt(enemy.attack_damage, 0, "%s should have attack damage" % resource_path)
			assert_gt(enemy.ship_size, 0.0, "%s should have a renderable ship size" % resource_path)
		elif resource is FactionData:
			var faction := resource as FactionData
			assert_false(faction.faction_name.is_empty(), "%s should have a display name" % resource_path)
			assert_gt(faction.aggression_level, 0.0, "%s should have aggression" % resource_path)
			assert_gt(faction.health_multiplier, 0.0, "%s should have health multiplier" % resource_path)
			assert_gt(faction.damage_multiplier, 0.0, "%s should have damage multiplier" % resource_path)
			assert_gt(faction.speed_multiplier, 0.0, "%s should have speed multiplier" % resource_path)
		else:
			fail_test("%s loaded an unexpected resource type" % resource_path)
