class_name ShaderGalaxyField
extends Node2D

enum GalaxyType {SPIRAL, ELLIPTICAL, IRREGULAR}

const GALAXY_PRESETS := {
	"blue_spiral": {
		"type": GalaxyType.SPIRAL,
		"core_color": Color(1.0, 0.98, 0.9, 1.0),
		"arm_color": Color(0.3, 0.5, 1.0, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.4
	},
	"purple_spiral": {
		"type": GalaxyType.SPIRAL,
		"core_color": Color(1.0, 0.9, 0.95, 1.0),
		"arm_color": Color(0.6, 0.3, 0.9, 1.0),
		"arm_count": 3.0,
		"arm_tightness": 0.35
	},
	"golden_spiral": {
		"type": GalaxyType.SPIRAL,
		"core_color": Color(1.0, 1.0, 0.85, 1.0),
		"arm_color": Color(1.0, 0.7, 0.3, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.5
	},
	"pink_spiral": {
		"type": GalaxyType.SPIRAL,
		"core_color": Color(1.0, 0.95, 0.95, 1.0),
		"arm_color": Color(1.0, 0.4, 0.6, 1.0),
		"arm_count": 4.0,
		"arm_tightness": 0.3
	},
	"red_elliptical": {
		"type": GalaxyType.ELLIPTICAL,
		"core_color": Color(1.0, 0.85, 0.7, 1.0),
		"arm_color": Color(0.9, 0.4, 0.3, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.4
	},
	"yellow_elliptical": {
		"type": GalaxyType.ELLIPTICAL,
		"core_color": Color(1.0, 1.0, 0.9, 1.0),
		"arm_color": Color(1.0, 0.9, 0.5, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.4
	},
	"cyan_irregular": {
		"type": GalaxyType.IRREGULAR,
		"core_color": Color(0.9, 1.0, 1.0, 1.0),
		"arm_color": Color(0.3, 0.8, 0.9, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.4
	},
	"magenta_irregular": {
		"type": GalaxyType.IRREGULAR,
		"core_color": Color(1.0, 0.9, 1.0, 1.0),
		"arm_color": Color(0.8, 0.3, 0.7, 1.0),
		"arm_count": 2.0,
		"arm_tightness": 0.4
	}
}

@export var field_size: Vector2 = Vector2(8192, 8192)
@export_range(0.0, 1.0) var spawn_chance: float = 0.08
const CHUNK_SIZE := 2048.0
@export var min_galaxy_size: float = 150.0
@export var max_galaxy_size: float = 400.0
@export var base_alpha: float = 0.25
var session_seed: int = 0

var _galaxies: Array[Dictionary] = []
var _galaxy_sprites: Array[Sprite2D] = []
var _shader: Shader
var _rng: RandomNumberGenerator


func _ready() -> void:
	_shader = load("res://scenes/environment/galaxy.gdshader")
	_generate_galaxies()


func _generate_galaxies() -> void:
	_clear_galaxies()
	
	_rng = RandomNumberGenerator.new()
	_rng.seed = session_seed if session_seed != 0 else randi()
	
	var preset_names := GALAXY_PRESETS.keys()
	
	var chunks_x := int(ceil(field_size.x / CHUNK_SIZE))
	var chunks_y := int(ceil(field_size.y / CHUNK_SIZE))
	
	for cx in range(-chunks_x / 2.0, chunks_x / 2.0 + 1):
		for cy in range(-chunks_y / 2.0, chunks_y / 2.0 + 1):
			var chunk_seed := hash(Vector3i(cx, cy, session_seed))
			_rng.seed = chunk_seed
			
			if _rng.randf() > spawn_chance:
				continue
			
			var chunk_origin := Vector2(cx * CHUNK_SIZE, cy * CHUNK_SIZE)
			var preset_name: String = preset_names[_rng.randi() % preset_names.size()]
			var preset: Dictionary = GALAXY_PRESETS[preset_name]
			
			var galaxy_size := _rng.randf_range(min_galaxy_size, max_galaxy_size)
			var galaxy := {
				"position": chunk_origin + Vector2(
					_rng.randf_range(galaxy_size, CHUNK_SIZE - galaxy_size),
					_rng.randf_range(galaxy_size, CHUNK_SIZE - galaxy_size)
				),
				"size": galaxy_size,
				"rotation": _rng.randf_range(0, TAU),
				"rotation_speed": _rng.randf_range(0.01, 0.03) * (1.0 if _rng.randf() > 0.5 else -1.0),
				"type": preset.type,
				"core_color": preset.core_color,
				"arm_color": preset.arm_color,
				"arm_count": preset.arm_count,
				"arm_tightness": preset.arm_tightness,
				"brightness": _rng.randf_range(0.6, 1.0),
				"core_size": _rng.randf_range(0.1, 0.2)
			}
			_galaxies.append(galaxy)
			_create_galaxy_sprite(galaxy)


func _clear_galaxies() -> void:
	for sprite in _galaxy_sprites:
		sprite.queue_free()
	_galaxy_sprites.clear()
	_galaxies.clear()


func _create_galaxy_sprite(galaxy: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _create_galaxy_texture(int(galaxy.size))
	sprite.position = galaxy.position
	sprite.rotation = galaxy.rotation
	sprite.modulate.a = base_alpha * galaxy.brightness
	
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _shader
	shader_mat.set_shader_parameter("galaxy_type", galaxy.type)
	shader_mat.set_shader_parameter("core_color", galaxy.core_color)
	shader_mat.set_shader_parameter("arm_color", galaxy.arm_color)
	shader_mat.set_shader_parameter("arm_count", galaxy.arm_count)
	shader_mat.set_shader_parameter("arm_tightness", galaxy.arm_tightness)
	shader_mat.set_shader_parameter("brightness", galaxy.brightness)
	shader_mat.set_shader_parameter("core_size", galaxy.core_size)
	shader_mat.set_shader_parameter("rotation_speed", galaxy.rotation_speed)
	
	sprite.material = shader_mat
	add_child(sprite)
	_galaxy_sprites.append(sprite)


func _create_galaxy_texture(size: int) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	texture.gradient = gradient
	
	return texture


func _process(_delta: float) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	for sprite in _galaxy_sprites:
		var mat := sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("time", current_time)


func regenerate() -> void:
	_generate_galaxies()


func set_session_seed(new_seed: int) -> void:
	session_seed = new_seed
	_generate_galaxies()
