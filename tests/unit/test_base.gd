extends RefCounted
## Base class for unit tests. Test scripts extend this and define test_* methods.

var failures: Array[String] = []
var assertions: int = 0
var _current_test: String = ""

func assert_true(condition: bool, message: String = "") -> void:
	assertions += 1
	if not condition:
		_fail("expected true. %s" % message)

func assert_false(condition: bool, message: String = "") -> void:
	assertions += 1
	if condition:
		_fail("expected false. %s" % message)

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if actual != expected:
		_fail("expected %s, got %s. %s" % [str(expected), str(actual), message])

func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertions += 1
	if actual == unexpected:
		_fail("did not expect %s. %s" % [str(unexpected), message])

func assert_null(value: Variant, message: String = "") -> void:
	assertions += 1
	if value != null:
		_fail("expected null, got %s. %s" % [str(value), message])

func assert_not_null(value: Variant, message: String = "") -> void:
	assertions += 1
	if value == null:
		_fail("expected non-null. %s" % message)

func _fail(detail: String) -> void:
	failures.append("%s: %s" % [_current_test, detail])

## Optional per-test setup hook, overridden by subclasses.
func before_each() -> void:
	pass
