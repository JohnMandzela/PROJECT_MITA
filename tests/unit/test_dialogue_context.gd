extends GutTest

# Проверки DialogueContext: локальные переменные и утилитарные вызовы диалогов

var context: DialogueContext


func before_each() -> void:
	context = DialogueContext.new()
	add_child_autofree(context)


func after_each() -> void:
	GameManager.is_skipping_cutscene = false


func test_locals_is_empty_by_default() -> void:
	assert_eq(context.locals, {})


func test_locals_can_be_written() -> void:
	context.locals["some_flag"] = true

	assert_true(context.locals.has("some_flag"))
	assert_true(context.locals["some_flag"])


func test_wait_respects_the_given_time() -> void:
	var started := Time.get_ticks_msec()
	await context.wait(0.05)
	var elapsed := Time.get_ticks_msec() - started

	assert_true(elapsed >= 40, "wait(0.05) вернулся слишком рано: %d мс" % elapsed)


func test_play_sound_returns_immediately_when_skipping_cutscene() -> void:
	GameManager.is_skipping_cutscene = true
	var started := Time.get_ticks_msec()

	await context.play_sound(Sounds.ITEM_PICKUP)

	assert_true(
		Time.get_ticks_msec() - started < 100,
		"play_sound не должен ждать звук при пропуске катсцены"
	)
