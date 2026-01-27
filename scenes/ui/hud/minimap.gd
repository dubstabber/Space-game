extends Control

signal portal_positions_updated(positions: Array[Vector2])

@export var map_size: Vector2 = Vector2(200, 200)
@export var map_margin: Vector2 = Vector2(15, 15)
@export var border_width: float = 2.0
@export var border_color: Color = Color(0.4, 0.4, 0.5, 0.8)
@export var background_color: Color = Color(0.02, 0.02, 0.05, 0.85)

@export_group("Player Indicator")
@export var player_dot_radius: float = 4.0
@export var player_color: Color = Color(0.2, 1.0, 0.3)
@export var arrow_size: float = 8.0

@export_group("Portal Indicator")
@export var portal_icon_size: float = 6.0
@export var portal_color: Color = Color(0.4, 0.7, 1.0)

enum PortalPosition {
	TOP_LEFT,
	TOP_MIDDLE,
	TOP_RIGHT,
	MIDDLE_LEFT,
	MIDDLE,
	MIDDLE_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_MIDDLE,
	BOTTOM_RIGHT
}

var _player: Node2D = null
var _portal_world_positions: Array[Vector2] = []
var _world_map_size: Vector2 = Vector2(40000, 40000)

func _ready() -> void:
	custom_minimum_size = map_size
	size = map_size
	
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	
	offset_left = map_margin.x
	offset_top = - map_size.y - map_margin.y
	offset_right = map_margin.x + map_size.x
	offset_bottom = - map_margin.y


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_background()
	_draw_border()
	_draw_portals()
	_draw_player()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), background_color)


func _draw_border() -> void:
	var half_border := border_width / 2.0
	var points: PackedVector2Array = [
		Vector2(half_border, half_border),
		Vector2(map_size.x - half_border, half_border),
		Vector2(map_size.x - half_border, map_size.y - half_border),
		Vector2(half_border, map_size.y - half_border),
		Vector2(half_border, half_border)
	]
	draw_polyline(points, border_color, border_width)


func _draw_player() -> void:
	if _player == null:
		return
	
	var player_world_pos := _player.global_position
	var map_pos := _world_to_map(player_world_pos)
	
	var map_rect := Rect2(Vector2.ZERO, map_size)
	
	if map_rect.has_point(map_pos):
		draw_circle(map_pos, player_dot_radius, player_color)
	else:
		_draw_player_arrow(player_world_pos, map_pos)


func _draw_player_arrow(world_pos: Vector2, _map_pos: Vector2) -> void:
	var direction := (world_pos).normalized()
	
	var arrow_pos := _get_edge_position(direction)
	
	var arrow_angle := direction.angle()
	var arrow_points: PackedVector2Array = [
		arrow_pos + Vector2(arrow_size, 0).rotated(arrow_angle),
		arrow_pos + Vector2(-arrow_size * 0.5, -arrow_size * 0.6).rotated(arrow_angle),
		arrow_pos + Vector2(-arrow_size * 0.5, arrow_size * 0.6).rotated(arrow_angle)
	]
	
	draw_colored_polygon(arrow_points, player_color)


func _get_edge_position(direction: Vector2) -> Vector2:
	var center := map_size / 2.0
	var border_offset := border_width
	
	var t_values: Array[float] = []
	
	if direction.x > 0:
		t_values.append((map_size.x - border_offset - center.x) / direction.x)
	elif direction.x < 0:
		t_values.append((border_offset - center.x) / direction.x)
	
	if direction.y > 0:
		t_values.append((map_size.y - border_offset - center.y) / direction.y)
	elif direction.y < 0:
		t_values.append((border_offset - center.y) / direction.y)
	
	var t_min := INF
	for t in t_values:
		if t > 0 and t < t_min:
			t_min = t
	
	if t_min == INF:
		return center
	
	return center + direction * t_min


func _draw_portals() -> void:
	for i in range(_portal_world_positions.size()):
		var world_pos := _portal_world_positions[i]
		var portal_map_pos := _world_to_map(world_pos)
		_draw_portal_icon(portal_map_pos)


func _draw_portal_icon(pos: Vector2) -> void:
	var s := portal_icon_size
	var points: PackedVector2Array = [
		pos + Vector2(0, -s),
		pos + Vector2(s * 0.866, s * 0.5),
		pos + Vector2(-s * 0.866, s * 0.5)
	]
	draw_colored_polygon(points, portal_color)
	
	var outline_points := points.duplicate()
	outline_points.append(points[0])
	draw_polyline(outline_points, portal_color.lightened(0.3), 1.5)


func _world_to_map(world_pos: Vector2) -> Vector2:
	var half_world := _world_map_size / 2.0
	
	var normalized_x := (world_pos.x + half_world.x) / _world_map_size.x
	var normalized_y := (world_pos.y + half_world.y) / _world_map_size.y
	
	return Vector2(
		normalized_x * map_size.x,
		normalized_y * map_size.y
	)


func set_player(player: Node2D) -> void:
	_player = player


func set_portal_positions(world_positions: Array[Vector2]) -> void:
	_portal_world_positions = world_positions
	portal_positions_updated.emit(world_positions)


func get_portal_world_positions() -> Array[Vector2]:
	return _portal_world_positions


func set_world_map_size(size_value: Vector2) -> void:
	_world_map_size = size_value


static func get_random_portal_slots(count: int, rng: RandomNumberGenerator) -> Array[PortalPosition]:
	var all_slots: Array[PortalPosition] = [
		PortalPosition.TOP_LEFT,
		PortalPosition.TOP_MIDDLE,
		PortalPosition.TOP_RIGHT,
		PortalPosition.MIDDLE_LEFT,
		PortalPosition.MIDDLE,
		PortalPosition.MIDDLE_RIGHT,
		PortalPosition.BOTTOM_LEFT,
		PortalPosition.BOTTOM_MIDDLE,
		PortalPosition.BOTTOM_RIGHT
	]
	
	var available: Array[int] = []
	for i in range(all_slots.size()):
		available.append(i)
	
	var result: Array[PortalPosition] = []
	var pick_count := mini(count, all_slots.size())
	
	for _i in range(pick_count):
		var idx := rng.randi_range(0, available.size() - 1)
		result.append(all_slots[available[idx]])
		available.remove_at(idx)
	
	return result
