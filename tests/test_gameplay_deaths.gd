extends "res://tests/GameplayTestBase.gd"


# Shared setup: experimented user so no tuto, start at phase 0
func _death_main(card_overrides: Dictionary) -> Node:
	var deck = {PHASES[0]: [_make_card("DEATH_CARD", PHASES[0], card_overrides)]}
	return await _make_main({"has_reached_phase_5": true}, deck, 0)


# --- Creativity ---

# M-01: créativité trop basse → stats["creativity"] passe à -1
func test_M01_mort_creativity_trop_basse():
	var main = await _death_main({"creativity_a": KILL_LOW})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["creativity"] < 0,
		"La créativité doit être négative (état: " + str(main.stats["creativity"]) + ")")


# M-02: créativité trop haute → stats["creativity"] dépasse MAX_STAT
func test_M02_mort_creativity_trop_haute():
	var main = await _death_main({"creativity_a": KILL_HIGH})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["creativity"] > MAX_STAT,
		"La créativité doit dépasser MAX_STAT (état: " + str(main.stats["creativity"]) + ")")


# --- Vie de famille ---

# M-03: vie de famille trop basse
func test_M03_mort_familly_life_trop_basse():
	var main = await _death_main({"familly_life_a": KILL_LOW})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["familly_life"] < 0,
		"familly_life doit être négative (état: " + str(main.stats["familly_life"]) + ")")


# M-04: vie de famille trop haute
func test_M04_mort_familly_life_trop_haute():
	var main = await _death_main({"familly_life_a": KILL_HIGH})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["familly_life"] > MAX_STAT,
		"familly_life doit dépasser MAX_STAT (état: " + str(main.stats["familly_life"]) + ")")


# --- Popularité ---

# M-05: popularité trop basse
func test_M05_mort_popularity_trop_basse():
	var main = await _death_main({"popularity_a": KILL_LOW})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["popularity"] < 0,
		"popularity doit être négative (état: " + str(main.stats["popularity"]) + ")")


# M-06: popularité trop haute
func test_M06_mort_popularity_trop_haute():
	var main = await _death_main({"popularity_a": KILL_HIGH})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["popularity"] > MAX_STAT,
		"popularity doit dépasser MAX_STAT (état: " + str(main.stats["popularity"]) + ")")


# --- Vitesse ---

# M-07: vitesse trop basse
func test_M07_mort_speed_trop_basse():
	var main = await _death_main({"speed_a": KILL_LOW})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["speed"] < 0,
		"speed doit être négative (état: " + str(main.stats["speed"]) + ")")


# M-08: vitesse trop haute
func test_M08_mort_speed_trop_haute():
	var main = await _death_main({"speed_a": KILL_HIGH})
	await _swipe(main, "A")

	assert_true(main.g_game_over, "game_over doit être déclenché")
	assert_true(main.stats["speed"] > MAX_STAT,
		"speed doit dépasser MAX_STAT (état: " + str(main.stats["speed"]) + ")")
