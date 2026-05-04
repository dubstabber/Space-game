extends GutTest


func test_resource_data_static_tables_cover_known_types() -> void:
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.IRON), "iron")
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.GOLD), "gold")
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.CRYSTAL), "crystal")
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.ICE), "ice")
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.FUEL), "fuel")
	assert_eq(ResourceData.get_type_name(ResourceData.ResourceType.SCRAP), "scrap")
	assert_eq(ResourceData.get_base_value(ResourceData.ResourceType.CRYSTAL), 75)
	assert_gt(ResourceData.get_rarity_weight(ResourceData.ResourceType.IRON), ResourceData.get_rarity_weight(ResourceData.ResourceType.CRYSTAL))
	assert_eq(ResourceData.get_resource_color(ResourceData.ResourceType.FUEL), Color(0.2, 0.9, 0.4))


func test_enemy_and_faction_display_names_cover_known_enums() -> void:
	assert_eq(EnemyData.get_type_display_name(EnemyData.EnemyType.SCOUT), "Scout")
	assert_eq(EnemyData.get_type_display_name(EnemyData.EnemyType.FIGHTER), "Fighter")
	assert_eq(EnemyData.get_type_display_name(EnemyData.EnemyType.HEAVY), "Heavy")
	assert_eq(EnemyData.get_type_display_name(EnemyData.EnemyType.BOSS), "Boss")
	assert_eq(FactionData.get_faction_display_name(FactionData.FactionID.RAIDERS), "Raiders")
	assert_eq(FactionData.get_faction_display_name(FactionData.FactionID.SYNDICATE), "Syndicate")
	assert_eq(FactionData.get_faction_display_name(FactionData.FactionID.HIVE), "Hive")


func test_seeded_asteroid_generation_is_deterministic_and_bounded() -> void:
	var first := AsteroidGeometry.generate_asteroid_shape(40.0, 0.25, 12345)
	var second := AsteroidGeometry.generate_asteroid_shape(40.0, 0.25, 12345)

	assert_eq(first, second)
	assert_between(first.size(), AsteroidGeometry.MIN_VERTICES, AsteroidGeometry.MAX_VERTICES)

	for point in first:
		assert_between(point.length(), 30.0, 50.0)


func test_asteroid_detail_generation_returns_expected_shape_contract() -> void:
	var data := AsteroidGeometry.generate_asteroid_with_details(60.0, 0.2, 99)

	assert_true(data.has("outline"))
	assert_true(data.has("craters"))
	assert_true(data.has("base_radius"))
	assert_eq(data.base_radius, 60.0)
	assert_between(data.craters.size(), 0, 3)

	for crater in data.craters:
		assert_true(crater.has("position"))
		assert_true(crater.has("radius"))
		assert_between(crater.radius, 6.0, 15.0)


func test_enemy_geometry_shapes_have_stable_contracts() -> void:
	var scout := EnemyGeometry.generate_scout_shape(20.0, 7)
	var fighter := EnemyGeometry.generate_fighter_shape(20.0, 7)
	var heavy := EnemyGeometry.generate_heavy_shape(20.0, 7)
	var boss := EnemyGeometry.generate_boss_shape(40.0, 2, 7)

	assert_eq((scout.hull as PackedVector2Array).size(), 5)
	assert_eq((fighter.hull as PackedVector2Array).size(), 10)
	assert_eq((heavy.hull as PackedVector2Array).size(), 12)
	assert_eq((boss.hull as PackedVector2Array).size(), 16)
	assert_eq((boss.turrets as Array[Vector2]).size(), 4)


func test_enemy_outline_closes_hull_without_mutating_original() -> void:
	var hull := PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
	var outline := EnemyGeometry.create_outline_from_hull(hull)

	assert_eq(hull.size(), 3)
	assert_eq(outline.size(), 4)
	assert_eq(outline[0], outline[outline.size() - 1])


func test_hive_faction_routes_to_hive_geometry() -> void:
	var shape := EnemyGeometry.generate_shape_for_enemy(
		EnemyData.EnemyType.HEAVY,
		FactionData.FactionID.HIVE,
		20.0,
		3
	)

	assert_eq((shape.hull as PackedVector2Array).size(), 8)
