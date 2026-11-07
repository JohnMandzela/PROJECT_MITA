extends GutTest

# Проверки реестра флагов (scripts/flags.gd)


func before_each() -> void:
	GameManager.game_flags.clear()


func after_all() -> void:
	GameManager.game_flags.clear()


func test_every_constant_is_listed_in_all() -> void:
	var constants: Dictionary = load("res://scripts/flags.gd").get_script_constant_map()

	for constant_name in constants.keys():
		if constant_name == "ALL":
			continue

		assert_true(
			Flags.ALL.has(constants[constant_name]),
			"Флаг '%s' не добавлен в Flags.ALL" % constant_name
		)


func test_all_flags_are_unique() -> void:
	var seen := {}

	for flag_name in Flags.ALL:
		assert_false(seen.has(flag_name), "Флаг '%s' объявлен дважды" % flag_name)
		seen[flag_name] = true


func test_is_valid() -> void:
	assert_true(Flags.is_valid(Flags.BED_INTERACTED))
	assert_false(Flags.is_valid("nope"))


func test_flag_is_absent_by_default() -> void:
	assert_false(GameManager.get_flag(Flags.BED_INTERACTED))
	assert_false(GameManager.game_flags.has(Flags.BED_INTERACTED))


func test_set_flag_stores_only_true() -> void:
	GameManager.set_flag(Flags.BED_INTERACTED)

	assert_true(GameManager.get_flag(Flags.BED_INTERACTED))
	assert_eq(GameManager.game_flags, { Flags.BED_INTERACTED: true })

	GameManager.set_flag(Flags.BED_INTERACTED, false)

	assert_false(GameManager.get_flag(Flags.BED_INTERACTED))
	assert_false(GameManager.game_flags.has(Flags.BED_INTERACTED))


func test_flag_updated_signal_fires_once_per_change() -> void:
	watch_signals(GameManager)

	GameManager.set_flag(Flags.SHOWER_USED)
	GameManager.set_flag(Flags.SHOWER_USED)
	GameManager.set_flag(Flags.SHOWER_USED, false)

	assert_signal_emit_count(GameManager, "flag_updated", 2)


func test_set_unknown_flag_is_ignored() -> void:
	GameManager.set_flag("nope")

	assert_push_error("не объявлен в Flags")
	assert_false(GameManager.game_flags.has("nope"))
