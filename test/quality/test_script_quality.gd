extends GutTest


const BASELINE_PATH := "res://test/quality/script_size_baselines.json"
const SCAN_ROOTS := ["res://autoload", "res://scenes", "res://scripts"]
const NEW_FILE_MAX_LINES := 220
const NEW_FILE_MAX_FUNCTIONS := 18
const NEW_FILE_MAX_FUNCTION_LINES := 45
const PURE_ROOTS := [
	"res://scripts/components",
	"res://scripts/data",
	"res://scripts/geometry",
]
const FORBIDDEN_PURE_DEPENDENCIES := [
	"res://scenes/",
	"GameManager",
	"MapManager",
	"SeedManager",
	"UniverseManager",
]


func test_existing_scripts_do_not_grow_past_committed_baseline() -> void:
	var baselines := _load_baselines()
	var current := _scan_scripts()

	assert_false(baselines.is_empty(), "Script size baseline should exist and contain entries")

	for path in current:
		var metrics: Dictionary = current[path]
		if baselines.has(path):
			var baseline: Dictionary = baselines[path]
			assert_lte(metrics.lines, int(baseline.lines), "%s grew past its line-count baseline" % path)
			assert_lte(metrics.functions, int(baseline.functions), "%s grew past its function-count baseline" % path)
			assert_lte(metrics.max_function_lines, int(baseline.max_function_lines), "%s grew past its largest-function baseline" % path)
		else:
			assert_lte(metrics.lines, NEW_FILE_MAX_LINES, "%s exceeds the new-file line cap" % path)
			assert_lte(metrics.functions, NEW_FILE_MAX_FUNCTIONS, "%s exceeds the new-file function cap" % path)
			assert_lte(metrics.max_function_lines, NEW_FILE_MAX_FUNCTION_LINES, "%s has a bloated function" % path)


func test_pure_script_roots_do_not_depend_on_scenes_or_autoloads() -> void:
	for path in _scan_scripts():
		if not _is_under_any(path, PURE_ROOTS):
			continue

		var text := _read_text(path)
		for dependency in FORBIDDEN_PURE_DEPENDENCIES:
			assert_false(text.contains(dependency), "%s should stay independent from %s" % [path, dependency])


func _load_baselines() -> Dictionary:
	var file := FileAccess.open(BASELINE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}


func _scan_scripts() -> Dictionary:
	var scripts := {}
	for root in SCAN_ROOTS:
		_scan_directory(root, scripts)
	return scripts


func _scan_directory(path: String, scripts: Dictionary) -> void:
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
			_scan_directory(child_path, scripts)
		elif item.ends_with(".gd"):
			scripts[child_path] = _measure_script(child_path)

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


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _is_under_any(path: String, roots: Array) -> bool:
	for root in roots:
		if path.begins_with(root + "/"):
			return true
	return false
