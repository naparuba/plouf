extends GutTest
# Tests pour les fonctions helper du jeu principal

# Référence vers le script main pour tester ses méthodes
var MainScript = preload("res://main.gd")

func before_each():
	# Appelé avant chaque test
	pass

func after_each():
	# Appelé après chaque test
	pass

# ===== TESTS DES CONSTANTES =====

func test_max_stat_value():
	# Vérifie que MAX_STAT est correctement défini
	var main_instance = autofree(MainScript.new())
	assert_eq(main_instance.MAX_STAT, 40, "MAX_STAT devrait être 40")

func test_criteria_names_are_defined():
	var main_instance = autofree(MainScript.new())
	assert_eq(main_instance.CRITERIA_CREATIVITY, 'creativity')
	assert_eq(main_instance.CRITERIA_FAMILLY_LIFE, 'familly_life')
	assert_eq(main_instance.CRITERIA_POPULARITY, 'popularity')
	assert_eq(main_instance.CRITERIA_SPEED, 'speed')

func test_cards_per_phase():
	var main_instance = autofree(MainScript.new())
	assert_eq(main_instance.NB_CARDS_BY_PHASE, 5, "Il devrait y avoir 5 cartes par phase")

func test_multipliers():
	var main_instance = autofree(MainScript.new())
	assert_eq(main_instance.MULTIPLIER_HUGE_IMPACT, 10, "Multiplicateur d'impact énorme devrait être 10")
	assert_eq(main_instance.MULTIPLIER_IMPACT_HIGH, 3, "Multiplicateur d'impact élevé devrait être 3")

# ===== TESTS DES STATS INITIALES =====

func test_initial_stats_are_balanced():
	var main_instance = autofree(MainScript.new())
	# Toutes les stats devraient commencer à 20 (la moitié de MAX_STAT)
	assert_eq(main_instance.stats[main_instance.CRITERIA_CREATIVITY], 20)
	assert_eq(main_instance.stats[main_instance.CRITERIA_POPULARITY], 20)
	assert_eq(main_instance.stats[main_instance.CRITERIA_FAMILLY_LIFE], 20)
	assert_eq(main_instance.stats[main_instance.CRITERIA_SPEED], 20)

# ===== TESTS DES PHASES =====

func test_phases_display_has_all_phases():
	var main_instance = autofree(MainScript.new())
	# Vérifie que toutes les clés des phases sont présentes
	var expected_phases = [
		"CHOOSE_CHRONIQUE_GAME",
		"PLAY_CHRONIQUE_GAME",
		"WRITE_CHRONIQUE",
		"REGISTER_VOICE",
		"DRAW_CHRONIQUE",
		"ANIMATE_CHRONIQUE",
		"MOUNT_CHRONIQUE_VIDEO",
		"UPLOAD_CHRONIQUE_VIDEO",
		"ANSWER_CHRONIQUE_COMMENTS",
		"STREAM_POST_CHRONIQUE"
	]

	for phase in expected_phases:
		assert_true(main_instance.phases_display.has(phase),
			"La phase %s devrait avoir un texte d'affichage" % phase)

# ===== TESTS DE LOGIQUE MÉTIER =====

func test_warning_threshold():
	var main_instance = autofree(MainScript.new())
	var threshold = main_instance.CRITERIA_WARNING_THRESHOLD
	assert_eq(threshold, 0.2, "Le seuil d'alerte devrait être à 20%")

	# Teste le calcul du seuil
	var warning_level = main_instance.MAX_STAT * threshold
	assert_eq(warning_level, 8, "Le niveau d'alerte devrait être à 8 (20% de 40)")

# ===== TESTS DE REMPLACEMENT DE TEXTE =====

func test_change_text_with_played_game():
	var main_instance = autofree(MainScript.new())
	main_instance.played_game = "Paper Mario"

	var text_with_placeholder = "Aujourd'hui Plouf joue à $GAME"
	var expected = "Aujourd'hui Plouf joue à Paper Mario"
	var result = main_instance._change_text_with_played_game(text_with_placeholder)

	assert_eq(result, expected, "Le placeholder $GAME devrait être remplacé par le jeu")

func test_change_text_without_placeholder():
	var main_instance = autofree(MainScript.new())
	main_instance.played_game = "Zelda"

	var text_without_placeholder = "Plouf est fatigué"
	var result = main_instance._change_text_with_played_game(text_without_placeholder)

	assert_eq(result, text_without_placeholder, "Le texte sans placeholder ne devrait pas changer")

# ===== TESTS DE SAVE DATA =====

func test_save_data_structure():
	var main_instance = autofree(MainScript.new())
	assert_true(main_instance.save_data.has("has_reached_phase_5"),
		"save_data devrait contenir la clé has_reached_phase_5")
	assert_false(main_instance.save_data["has_reached_phase_5"],
		"has_reached_phase_5 devrait être false par défaut")

# ===== TESTS DES FLAGS DEBUG =====

func test_debug_flags_are_false_by_default():
	var main_instance = autofree(MainScript.new())
	assert_false(main_instance.DEBUG_SKIP_TUTO, "DEBUG_SKIP_TUTO devrait être false par défaut")
	assert_false(main_instance.DEBUG_FORCE_TUTO, "DEBUG_FORCE_TUTO devrait être false par défaut")
	assert_false(main_instance.DEBUG_GAMEOVER, "DEBUG_GAMEOVER devrait être false par défaut")
	assert_false(main_instance.DEBUG_WIN, "DEBUG_WIN devrait être false par défaut")
	assert_false(main_instance.DEBUG_DISABLE_INTRO, "DEBUG_DISABLE_INTRO devrait être false par défaut")

# ===== TESTS DES COLLECTIONS =====

func test_initial_collections_are_empty():
	var main_instance = autofree(MainScript.new())
	assert_eq(main_instance.deck.size(), 0, "Le deck devrait être vide au départ")
	assert_eq(main_instance.seen_ids.size(), 0, "seen_ids devrait être vide au départ")
	assert_eq(main_instance.phases.size(), 0, "phases devrait être vide avant chargement")

func test_problems_by_phase_is_dictionary():
	var main_instance = autofree(MainScript.new())
	assert_true(main_instance.problems_by_phase is Dictionary,
		"problems_by_phase devrait être un Dictionary")

func test_played_games_list():
	var main_instance = autofree(MainScript.new())
	assert_true(main_instance.played_games is Array, "played_games devrait être un Array")
	assert_eq(main_instance.played_game, 'Paper Mario', "Le jeu par défaut devrait être Paper Mario")
