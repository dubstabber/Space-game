extends SceneTree


const OUTPUT_PATH := "res://test/quality/script_size_baselines.json"
const SCAN_ROOTS := ["res://autoload", "res://scenes", "res://scripts"]


func _init() -> void:
	var baselines := {}
	for root in SCAN_ROOTS:
		_scan_directory(root, baselines)

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % OUTPUT_PATH)
		quit(1)
		return

	file.store_string(JSON.stringify(baselines, "\t", false, true))
	file.close()
	print("Updated %s with %d scripts" % [OUTPUT_PATH, baselines.size()])
	quit(0)


func _scan_directory(path: String, baselines: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item.begins_with("."):
			item = dir.get_next()
			continue

		var child_path := path.path_join(item)
		if dir.current_is_dir():
			_scan_directory(child_path, baselines)
		elif item.ends_with(".gd"):
			baselines[child_path] = _measure_script(child_path)

		item = dir.get_next()


func _measure_script(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"lines": 0,
			"functions": 0,
			"max_function_lines": 0
		}

	var line_count := 0
	var function_count := 0
	var max_function_lines := 0
	var current_function_lines := 0
	var inside_function := false

	while not file.eof_reached():
		var line := file.get_line()
		line_count += 1
		var stripped := line.strip_edges()

		if stripped.begins_with("func "):
			if inside_function:
				max_function_lines = maxi(max_function_lines, current_function_lines)
			inside_function = true
			function_count += 1
			current_function_lines = 1
		elif inside_function and not stripped.is_empty() and not stripped.begins_with("#"):
			current_function_lines += 1

	if inside_function:
		max_function_lines = maxi(max_function_lines, current_function_lines)

	file.close()
	return {
		"lines": line_count,
		"functions": function_count,
		"max_function_lines": max_function_lines
	}
