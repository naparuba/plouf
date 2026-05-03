extends "res://tests/GameplayTestBase.gd"

const LAST_PHASE_INDEX = 9   # STREAM_POST_CHRONIQUE
const PHASE_5_INDEX = 4      # DRAW_CHRONIQUE — completing it sets current_phase_index to 5


# V-01: victoire complète — swiper la dernière carte de la dernière phase → win
func test_V01_victoire_complete():
	var deck = {
		PHASES[LAST_PHASE_INDEX]: [_make_card("WIN_CARD", PHASES[LAST_PHASE_INDEX])]
	}
	var main = await _make_main({"has_reached_phase_5": true}, deck, LAST_PHASE_INDEX)

	await _swipe(main, "A")

	assert_true(main.g_game_over,
		"g_game_over doit être true après la victoire")
	assert_eq(main.current_phase_index, main.phases.size(),
		"current_phase_index doit être égal au nombre de phases")


# P-01: has_reached_phase_5 est sauvegardé quand on finit la phase 4 (index 4)
# current_phase_index passe à 5, _jump_to_next_phase() écrit le flag
func test_P01_phase_5_sauvegardee():
	var deck = {
		PHASES[PHASE_5_INDEX]: [_make_card("P5_CARD", PHASES[PHASE_5_INDEX])]
	}
	var main = await _make_main({"has_reached_phase_5": false}, deck, PHASE_5_INDEX)

	assert_false(main.save_data["has_reached_phase_5"],
		"Le flag ne doit pas encore être set avant le swipe")

	await _swipe(main, "A")

	assert_true(main.save_data["has_reached_phase_5"],
		"Le flag doit être true après avoir complété la phase 4→5")


# P-02: une carte avec impact_multiplier=10 applique bien 10x l'impact
# creativity_a=1 × 10 = +10 → stats["creativity"] doit passer de 20 à 30
func test_P02_huge_impact_card():
	# 2 cartes pour que la phase ne se termine pas au premier swipe
	var deck = {
		PHASES[0]: [
			_make_card("HUGE", PHASES[0], {"creativity_a": 1, "impact_multiplier": 10}),
			_make_card("NEUTRAL", PHASES[0]),
		]
	}
	var main = await _make_main({"has_reached_phase_5": true}, deck, 0)

	var stat_before = main.stats["creativity"]
	await _swipe(main, "A")

	assert_eq(main.stats["creativity"], stat_before + 10,
		"L'impact multiplié par 10 doit donner +10 sur la créativité")


# W-01: stat tombe sous le seuil 20% (valeur < 8) → impact_is_activated_creativity
# 20 + (-13) = 7 → 7/40 = 17.5% < seuil 20%
func test_W01_warning_threshold_bas():
	var deck = {
		PHASES[0]: [
			_make_card("WARN_LOW", PHASES[0], {"creativity_a": -13}),
			_make_card("NEUTRAL", PHASES[0]),
		]
	}
	var main = await _make_main({"has_reached_phase_5": true}, deck, 0)

	await _swipe(main, "A")

	assert_true(main.impact_is_activated_creativity,
		"L'effet warning créativité doit s'activer sous 20%")
	assert_eq(main.stats["creativity"], 7,
		"La stat créativité doit être à 7 (20 - 13)")


# W-02: stat dépasse le seuil 80% (valeur > 32) → impact_is_activated_creativity
# 20 + 13 = 33 → 33/40 = 82.5% > seuil 80%
func test_W02_warning_threshold_haut():
	var deck = {
		PHASES[0]: [
			_make_card("WARN_HIGH", PHASES[0], {"creativity_a": 13}),
			_make_card("NEUTRAL", PHASES[0]),
		]
	}
	var main = await _make_main({"has_reached_phase_5": true}, deck, 0)

	await _swipe(main, "A")

	assert_true(main.impact_is_activated_creativity,
		"L'effet warning créativité doit s'activer au-dessus de 80%")
	assert_eq(main.stats["creativity"], 33,
		"La stat créativité doit être à 33 (20 + 13)")
