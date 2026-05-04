extends GutTest


var _health: HealthComponent


func before_each() -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health._ready()


func after_each() -> void:
	if is_instance_valid(_health):
		_health.free()


func test_ready_initializes_current_health_to_max_health() -> void:
	_health.max_health = 150
	_health._ready()

	assert_eq(_health.current_health, 150)
	assert_true(_health.is_alive())
	assert_true(_health.is_full_health())


func test_take_damage_clamps_at_zero_and_emits_signals() -> void:
	watch_signals(_health)

	_health.take_damage(125)

	assert_eq(_health.current_health, 0)
	assert_signal_emitted(_health, "damaged")
	assert_signal_emitted(_health, "health_changed")
	assert_signal_emitted(_health, "died")
	assert_false(_health.is_alive())


func test_invincible_damage_is_ignored() -> void:
	watch_signals(_health)
	_health.invincible = true

	_health.take_damage(25)

	assert_eq(_health.current_health, 100)
	assert_signal_not_emitted(_health, "damaged")
	assert_signal_not_emitted(_health, "health_changed")


func test_heal_clamps_to_max_and_reports_actual_heal() -> void:
	watch_signals(_health)
	_health.take_damage(40)

	_health.heal(100)

	assert_eq(_health.current_health, 100)
	assert_signal_emitted(_health, "healed")
	assert_signal_emit_count(_health, "healed", 1)
	assert_true(_health.is_full_health())


func test_dead_component_cannot_be_healed_or_damaged_again() -> void:
	_health.take_damage(100)
	watch_signals(_health)

	_health.heal(50)
	_health.take_damage(10)

	assert_eq(_health.current_health, 0)
	assert_signal_not_emitted(_health, "healed")
	assert_signal_not_emitted(_health, "damaged")


func test_set_max_health_can_clamp_or_heal_to_full() -> void:
	_health.take_damage(70)

	_health.set_max_health(50)
	assert_eq(_health.current_health, 30)
	assert_eq(_health.max_health, 50)

	_health.set_max_health(120, true)
	assert_eq(_health.current_health, 120)
	assert_eq(_health.get_health_percent(), 1.0)


func test_health_percent_handles_invalid_max_health() -> void:
	_health.max_health = 0

	assert_eq(_health.get_health_percent(), 0.0)
