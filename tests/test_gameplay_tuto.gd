extends "res://tests/GameplayTestBase.gd"


func _neutral_deck() -> Dictionary:
	return {
		PHASES[0]: [_make_card("TUTO_NEUTRAL", PHASES[0])]
	}


# T-01: nouveau joueur — le tuto doit s'afficher et bloquer le deck
func test_T01_tuto_premier_lancement():
	var main = await _make_main({"has_reached_phase_5": false}, _neutral_deck())

	assert_true(main.get_node("help_1").visible,
		"help_1 doit être visible au premier lancement")
	assert_false(main.get_node("help_2").visible,
		"help_2 doit être caché au départ")
	assert_false(main.get_node("help_3").visible,
		"help_3 doit être caché au départ")


# T-02: joueur expérimenté (a atteint la phase 5) — le tuto est skippé
func test_T02_tuto_joueur_experimente():
	var main = await _make_main({"has_reached_phase_5": true}, _neutral_deck())

	assert_false(main.get_node("help_1").visible,
		"help_1 doit être caché pour un joueur expérimenté")
	assert_false(main.get_node("help_2").visible,
		"help_2 doit être caché")
	assert_false(main.get_node("help_3").visible,
		"help_3 doit être caché")
	assert_true(main.card_deck.are_interaction_enabled,
		"Le deck doit être actif sans tuto")
