class_name DustField
extends Node2D

@export var dust_count: int = 50
@export var dust_color: Color = Color(0.6, 0.6, 0.7, 0.2)
@export var field_size: Vector2 = Vector2(1024, 1024)
var _particles: Array[Dictionary] = []


func _ready() -> void:
	_generate_dust()


func _generate_dust() -> void:
	_particles.clear()
	
	for i in range(dust_count):
		var particle := {
			"pos": Vector2(
				randf_range(-field_size.x / 2, field_size.x / 2),
				randf_range(-field_size.y / 2, field_size.y / 2)
			),
			"size": randf_range(1.0, 3.0),
			"alpha": randf_range(0.1, 0.3)
		}
		_particles.append(particle)


func _draw() -> void:
	for particle in _particles:
		var color := Color(dust_color.r, dust_color.g, dust_color.b, particle.alpha)
		draw_circle(particle.pos, particle.size, color)
