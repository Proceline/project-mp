extends RefCounted
class_name TestRunner

var failures: int = 0

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures += 1
		push_error("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func assert_true(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_suite(suite: Object) -> int:
	var before := failures
	for method_name in suite.get_method_list():
		var name := String(method_name.name)
		if name.begins_with("test_"):
			suite.call(name, self)
	return failures - before
