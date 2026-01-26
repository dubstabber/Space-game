extends Label

@export var update_interval: float = 0.5

var _timer: float = 0.0


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		text = "FPS: %d" % Engine.get_frames_per_second()
