extends SceneTree
## Headless unit test runner.
## Usage: godot --headless --path . --script res://tests/test_runner.gd
## Discovers tests/unit/test_*.gd (excluding test_base.gd), runs every
## test_* method, prints a summary, exits 1 on any failure.

const TEST_DIR := "res://tests/unit/"

func _initialize() -> void:
	# Defer to the first processed frame so the root window is live and
	# scene instantiation (add_child -> _ready) behaves normally.
	process_frame.connect(_run_all, CONNECT_ONE_SHOT)

func _run_all() -> void:
	var total_tests := 0
	var total_assertions := 0
	var all_failures: Array[String] = []

	for script_path in _discover_test_scripts():
		var script: GDScript = load(script_path)
		if script == null or not script.can_instantiate():
			all_failures.append("%s: failed to load/compile" % script_path)
			continue
		var instance: Object = script.new()
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total_tests += 1
			instance._current_test = "%s::%s" % [script_path.get_file(), method_name]
			instance.before_each()
			var assertions_before: int = instance.assertions
			instance.call(method_name)
			if instance.assertions == assertions_before:
				instance.failures.append("%s: made no assertions (runtime error?)" % instance._current_test)
		total_assertions += instance.assertions
		all_failures.append_array(instance.failures)

	print("")
	print("==== Test summary ====")
	print("tests: %d, assertions: %d, failures: %d" % [total_tests, total_assertions, all_failures.size()])
	for failure in all_failures:
		printerr("FAIL %s" % failure)
	if all_failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		quit(1)

func _discover_test_scripts() -> Array[String]:
	var scripts: Array[String] = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		printerr("Cannot open test directory %s" % TEST_DIR)
		return scripts
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_base.gd":
			scripts.append(TEST_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	scripts.sort()
	return scripts
