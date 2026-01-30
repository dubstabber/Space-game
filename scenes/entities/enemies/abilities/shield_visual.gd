extends Node2D

var shield_color: Color = Color(0.3, 0.6, 1.0, 0.5)
var shield_radius: float = 40.0

var _pulse_time: float = 0.0


func _process(delta: float) -> void:
	_pulse_time += delta * 3.0
	queue_redraw()


func _draw() -> void:
	var pulse := sin(_pulse_time) * 0.1 + 1.0
	var current_radius := shield_radius * pulse
	
	var segments := 24
	var points := PackedVector2Array()
	
	for i in range(segments + 1):
		var angle := (TAU / segments) * i
		points.append(Vector2(cos(angle) * current_radius, sin(angle) * current_radius))
	
	draw_polyline(points, shield_color, 2.0, true)
	
	var inner_color := shield_color
	inner_color.a *= 0.3
	draw_circle(Vector2.ZERO, current_radius * 0.95, inner_color)
