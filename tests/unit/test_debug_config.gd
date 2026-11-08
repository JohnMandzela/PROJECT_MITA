extends GutTest

# Проверки отладочных переключателей из .env (DebugConfig)


func test_parse_bool_true_values() -> void:
	for raw in ["1", "true", "TRUE", "yes", "on", " true "]:
		assert_true(DebugConfig.parse_bool(raw), "ожидалось true для '%s'" % raw)


func test_parse_bool_false_values() -> void:
	for raw in ["0", "false", "no", "off", ""]:
		assert_false(DebugConfig.parse_bool(raw), "ожидалось false для '%s'" % raw)


func test_parse_bool_unknown_uses_default() -> void:
	assert_true(DebugConfig.parse_bool("maybe", true))
	assert_false(DebugConfig.parse_bool("maybe", false))


func test_skip_intro_reads_environment() -> void:
	var original := OS.get_environment("SKIP_INTRO")

	OS.set_environment("SKIP_INTRO", "true")
	DebugConfig.reload()
	assert_true(DebugConfig.skip_intro)

	OS.set_environment("SKIP_INTRO", original)
	DebugConfig.reload()
	assert_eq(DebugConfig.skip_intro, DebugConfig.parse_bool(original, false))
