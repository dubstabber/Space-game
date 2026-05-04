extends GutTest


func test_map_factories_create_expected_ids_and_gameplay_settings() -> void:
	var default_space := MapData.create_default_space()
	var hostile := MapData.create_hostile_sector()
	var resource := MapData.create_resource_nebula()
	var void_sector := MapData.create_void_sector()
	var home := MapData.create_home_base()

	assert_eq(default_space.map_id, "default_space")
	assert_eq(hostile.map_id, "hostile_sector")
	assert_eq(resource.map_id, "resource_nebula")
	assert_eq(void_sector.map_id, "void_sector")
	assert_eq(home.map_id, "home_base")
	assert_gt(hostile.enemy_spawn_rate, default_space.enemy_spawn_rate)
	assert_gt(resource.resource_multiplier, default_space.resource_multiplier)
	assert_lt(void_sector.asteroid_density, default_space.asteroid_density)
	assert_true(home.has_safe_zone)
	assert_eq(home.danger_level, 0)


func test_map_factories_include_renderable_parallax_layers() -> void:
	var maps: Array[MapData] = [
		MapData.create_default_space(),
		MapData.create_hostile_sector(),
		MapData.create_resource_nebula(),
		MapData.create_void_sector(),
		MapData.create_home_base()
	]

	for map in maps:
		assert_false(map.parallax_layers.is_empty(), "%s should include background layers" % map.map_id)
		for layer in map.parallax_layers:
			assert_not_null(layer)
			assert_gt(layer.scroll_scale.length(), 0.0)


func test_parallax_layer_factory_methods_assign_layer_types() -> void:
	assert_eq(ParallaxLayerConfig.create_star_layer(Vector2.ONE, 4).layer_type, ParallaxLayerConfig.LayerType.STAR_FIELD)
	assert_eq(ParallaxLayerConfig.create_nebula_layer(Vector2.ONE).layer_type, ParallaxLayerConfig.LayerType.NEBULA_FIELD)
	assert_eq(ParallaxLayerConfig.create_galaxy_layer(Vector2.ONE).layer_type, ParallaxLayerConfig.LayerType.GALAXY_FIELD)
	assert_eq(ParallaxLayerConfig.create_shader_galaxy_layer(Vector2.ONE).layer_type, ParallaxLayerConfig.LayerType.SHADER_GALAXY_FIELD)
	assert_eq(ParallaxLayerConfig.create_dust_layer(Vector2.ONE).layer_type, ParallaxLayerConfig.LayerType.DUST_FIELD)
