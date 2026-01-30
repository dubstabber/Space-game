extends Node2D

var trail_color: Color = Color.WHITE
var lifetime: float = 0.3

var _timer: float = 0.0


func _ready() -> void:
	_timer = lifetime


func _process(delta: float) -> void:
	_timer -= delta
	modulate.a = _timer / lifetime
	
	if _timer <= 0:
		queue_free()
	
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, trail_color)
