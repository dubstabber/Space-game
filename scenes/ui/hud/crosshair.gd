extends Control

@export var radius: float = 6.0
@export var dot_radius: float = 1.75
@export var line_width: float = 1.5
@export var crosshair_color: Color = Color(0.82, 0.95, 1.0, 0.95)

var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_mouse_position = get_local_mouse_position()
	queue_redraw()


func _exit_tree() -> void:
	Input.mouse_mode = _previous_mouse_mode


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_position = event.position
		queue_redraw()


func _draw() -> void:
	draw_circle(_mouse_position, radius, crosshair_color, false, line_width, true)
	draw_circle(_mouse_position, dot_radius, crosshair_color)
