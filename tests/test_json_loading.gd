extends GutTest
# Tests pour le chargement et la validation des fichiers JSON du projet

## Constantes pour les chemins des fichiers JSON
const CATEGORIES_PATH = "res://categories.json"
const PHASES_PATH = "res://phases.json"
const PHASES_FINISH_PATH = "res://phases_finish.json"
const POSSIBLE_GAMES_PATH = "res://possible_games.json"


# ===== SETUP & TEARDOWN =====

func before_all():
	# Appelé une fois avant tous les tests
	pass

func before_each():
	# Appelé avant chaque test
	pass

func after_each():
	# Appelé après chaque test
	pass


# ===== TESTS DE BASE - EXISTENCE DES FICHIERS =====

func test_categories_json_exists():
	# Vérifie que le fichier categories.json existe
	assert_true(FileAccess.file_exists(CATEGORIES_PATH),
		"Le fichier categories.json doit exister")

func test_phases_json_exists():
	# Vérifie que le fichier phases.json existe
	assert_true(FileAccess.file_exists(PHASES_PATH),
		"Le fichier phases.json doit exister")

func test_phases_finish_json_exists():
	# Vérifie que le fichier phases_finish.json existe
	assert_true(FileAccess.file_exists(PHASES_FINISH_PATH),
		"Le fichier phases_finish.json doit exister")

func test_possible_games_json_exists():
	# Vérifie que le fichier possible_games.json existe
	assert_true(FileAccess.file_exists(POSSIBLE_GAMES_PATH),
		"Le fichier possible_games.json doit exister")


# ===== TESTS DE CHARGEMENT JSON =====

func test_categories_json_loads():
	# Vérifie que categories.json peut être chargé sans erreur
	var file = FileAccess.open(CATEGORIES_PATH, FileAccess.READ)
	assert_not_null(file, "Le fichier categories.json doit pouvoir s'ouvrir")

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	assert_eq(error, OK, "categories.json doit être un JSON valide")

func test_phases_json_loads():
	# Vérifie que phases.json peut être chargé sans erreur
	var file = FileAccess.open(PHASES_PATH, FileAccess.READ)
	assert_not_null(file, "Le fichier phases.json doit pouvoir s'ouvrir")

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	assert_eq(error, OK, "phases.json doit être un JSON valide")

func test_possible_games_json_loads():
	# Vérifie que possible_games.json peut être chargé sans erreur
	var file = FileAccess.open(POSSIBLE_GAMES_PATH, FileAccess.READ)
	assert_not_null(file, "Le fichier possible_games.json doit pouvoir s'ouvrir")

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	assert_eq(error, OK, "possible_games.json doit être un JSON valide")


# ===== TESTS DE STRUCTURE - CATEGORIES.JSON =====

func test_categories_is_array():
	# Vérifie que categories.json contient un tableau
	var data = _load_json(CATEGORIES_PATH)
	assert_not_null(data, "Les données doivent être chargées")
	assert_true(data is Array, "categories.json doit contenir un tableau")

func test_categories_not_empty():
	# Vérifie que categories.json n'est pas vide
	var data = _load_json(CATEGORIES_PATH)
	assert_gt(data.size(), 0, "categories.json ne doit pas être vide")

func test_categories_have_required_fields():
	# Vérifie que chaque catégorie a les champs requis
	var data = _load_json(CATEGORIES_PATH)

	for category in data:
		assert_true(category.has("id"), "Chaque catégorie doit avoir un 'id'")
		assert_true(category.has("A"), "Chaque catégorie doit avoir un choix 'A'")
		assert_true(category.has("B"), "Chaque catégorie doit avoir un choix 'B'")

		# Vérifier que id n'est pas vide
		assert_ne(category["id"], "", "L'id de la catégorie ne doit pas être vide")

func test_categories_impacts_structure():
	# Vérifie la structure des impacts dans categories.json
	var data = _load_json(CATEGORIES_PATH)
	var valid_impact_categories = ["popularity", "creativity", "familly_life", "speed"]
	var valid_impact_signs = ["+", "-"]

	for category in data:
		# Vérifier les impacts A
		assert_true(category["A"] is Array, "Les impacts A doivent être un tableau")
		for impact in category["A"]:
			assert_true(impact.has("impact_category"), "Chaque impact doit avoir 'impact_category'")
			assert_true(impact.has("impact_sign"), "Chaque impact doit avoir 'impact_sign'")
			assert_true(impact["impact_category"] in valid_impact_categories,
				"impact_category doit être valide: " + str(impact["impact_category"]))
			assert_true(impact["impact_sign"] in valid_impact_signs,
				"impact_sign doit être + ou -")

		# Vérifier les impacts B (peuvent être vides)
		assert_true(category["B"] is Array, "Les impacts B doivent être un tableau")


# ===== TESTS DE STRUCTURE - PHASES.JSON =====

func test_phases_has_phases_key():
	# Vérifie que phases.json a la clé "phases"
	var data = _load_json(PHASES_PATH)
	assert_not_null(data, "Les données doivent être chargées")
	assert_true(data.has("phases"), "phases.json doit avoir une clé 'phases'")

func test_phases_is_array():
	# Vérifie que la clé "phases" contient un tableau
	var data = _load_json(PHASES_PATH)
	assert_true(data["phases"] is Array, "La clé 'phases' doit contenir un tableau")

func test_phases_not_empty():
	# Vérifie que le tableau de phases n'est pas vide
	var data = _load_json(PHASES_PATH)
	assert_gt(data["phases"].size(), 0, "Le tableau de phases ne doit pas être vide")

func test_phases_are_strings():
	# Vérifie que toutes les phases sont des chaînes de caractères
	var data = _load_json(PHASES_PATH)

	for phase in data["phases"]:
		assert_true(phase is String, "Chaque phase doit être une chaîne de caractères")
		assert_ne(phase, "", "Une phase ne doit pas être vide")

func test_phases_expected_values():
	# Vérifie que les phases attendues sont présentes
	var data = _load_json(PHASES_PATH)
	var phases = data["phases"]

	# Vérifier quelques phases clés
	assert_true("CHOOSE_CHRONIQUE_GAME" in phases, "CHOOSE_CHRONIQUE_GAME doit être présent")
	assert_true("WRITE_CHRONIQUE" in phases, "WRITE_CHRONIQUE doit être présent")
	assert_true("UPLOAD_CHRONIQUE_VIDEO" in phases, "UPLOAD_CHRONIQUE_VIDEO doit être présent")


# ===== TESTS DE STRUCTURE - POSSIBLE_GAMES.JSON =====

func test_possible_games_is_array():
	# Vérifie que possible_games.json contient un tableau
	var data = _load_json(POSSIBLE_GAMES_PATH)
	assert_not_null(data, "Les données doivent être chargées")
	assert_true(data is Array, "possible_games.json doit contenir un tableau")

func test_possible_games_not_empty():
	# Vérifie que la liste des jeux n'est pas vide
	var data = _load_json(POSSIBLE_GAMES_PATH)
	assert_gt(data.size(), 0, "La liste des jeux ne doit pas être vide")

func test_possible_games_are_strings():
	# Vérifie que tous les jeux sont des chaînes de caractères
	var data = _load_json(POSSIBLE_GAMES_PATH)

	for game in data:
		assert_true(game is String, "Chaque jeu doit être une chaîne de caractères")
		assert_ne(game, "", "Le nom d'un jeu ne doit pas être vide")

func test_possible_games_no_duplicates():
	# Vérifie qu'il n'y a pas de doublons dans les jeux
	var data = _load_json(POSSIBLE_GAMES_PATH)
	var seen_games = {}

	for game in data:
		assert_false(seen_games.has(game), "Le jeu '" + game + "' est en double")
		seen_games[game] = true


# ===== TESTS D'INTÉGRITÉ =====

func test_all_json_files_parseable():
	# Vérifie que tous les fichiers JSON principaux sont parseables
	var json_files = [
		CATEGORIES_PATH,
		PHASES_PATH,
		POSSIBLE_GAMES_PATH
	]

	for json_path in json_files:
		var data = _load_json(json_path)
		assert_not_null(data, "Le fichier " + json_path + " doit être parseable")

func test_categories_ids_are_unique():
	# Vérifie que les IDs des catégories sont uniques
	var data = _load_json(CATEGORIES_PATH)
	var seen_ids = {}

	for category in data:
		var cat_id = category["id"]
		assert_false(seen_ids.has(cat_id), "L'ID de catégorie '" + cat_id + "' est en double")
		seen_ids[cat_id] = true


# ===== TESTS DE VALIDATION DES DONNÉES =====

func test_impact_categories_are_consistent():
	# Vérifie que les catégories d'impact utilisées sont cohérentes
	var data = _load_json(CATEGORIES_PATH)
	var used_categories = {}

	for category in data:
		for choice in ["A", "B"]:
			for impact in category[choice]:
				var impact_cat = impact["impact_category"]
				used_categories[impact_cat] = true

	# Vérifier que seules les catégories valides sont utilisées
	var valid_categories = ["popularity", "creativity", "familly_life", "speed"]
	for used_cat in used_categories.keys():
		assert_true(used_cat in valid_categories,
			"Catégorie d'impact inconnue: " + used_cat)

func test_phases_match_expected_count():
	# Vérifie que le nombre de phases est cohérent
	var data = _load_json(PHASES_PATH)
	var phase_count = data["phases"].size()

	# On s'attend à avoir environ 10 phases (ajustez selon vos besoins)
	assert_true(phase_count >= 5, "Il devrait y avoir au moins 5 phases, trouvé: " + str(phase_count))
	assert_true(phase_count <= 20, "Il ne devrait pas y avoir plus de 20 phases, trouvé: " + str(phase_count))


# ===== FONCTIONS HELPER =====

func _load_json(file_path: String):
	# Fonction utilitaire pour charger un fichier JSON
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return null

	return json.get_data()

