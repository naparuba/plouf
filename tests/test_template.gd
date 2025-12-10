extends GutTest
# Template de test pour GUT (Godot Unit Test)
# Copiez ce fichier et renommez-le en test_votre_feature.gd

# ===== IMPORTS / PRELOAD =====

# Exemple : Précharger un script à tester
# var MyScript = preload("res://my_script.gd")
# var MyScene = preload("res://my_scene.tscn")


# ===== SETUP & TEARDOWN =====

func before_all():
	# Appelé UNE FOIS avant tous les tests de cette classe
	# Utilisé pour setup global (fichiers, configuration, etc.)
	pass

func before_each():
	# Appelé AVANT CHAQUE test
	# Utilisé pour réinitialiser l'état entre les tests
	pass

func after_each():
	# Appelé APRÈS CHAQUE test
	# Utilisé pour nettoyer (libérer ressources, etc.)
	pass

func after_all():
	# Appelé UNE FOIS après tous les tests
	# Utilisé pour cleanup global
	pass


# ===== TESTS BASIQUES =====

func test_example_assertion():
	# Test simple avec une assertion
	var expected = 42
	var actual = 42
	assert_eq(actual, expected, "Les valeurs devraient être égales")

func test_example_with_autofree():
	# ⚠️ IMPORTANT : Toujours utiliser autofree() avec .new()
	# pour éviter les fuites mémoire !
	var instance = autofree(Node.new())
	assert_not_null(instance, "L'instance devrait être créée")


# ===== ASSERTIONS DISPONIBLES =====

func test_all_assertions():
	# Égalité
	assert_eq(1, 1, "Valeurs égales")
	assert_ne(1, 2, "Valeurs différentes")

	# Booléens
	assert_true(true, "Devrait être vrai")
	assert_false(false, "Devrait être faux")

	# Null
	assert_null(null, "Devrait être null")
	assert_not_null("not null", "Ne devrait pas être null")

	# Comparaisons numériques
	assert_gt(5, 3, "5 est plus grand que 3")
	assert_lt(3, 5, "3 est plus petit que 5")

	# Approximations (pour floats)
	assert_almost_eq(1.0, 1.0001, 0.001, "Valeurs presque égales")

	# Strings (utiliser les fonctions built-in de String)
	assert_true("Hello World".contains("World"), "Devrait contenir 'World'")
	assert_true("Hello".begins_with("Hel"), "Devrait commencer par 'Hel'")
	assert_true("Hello".ends_with("lo"), "Devrait finir par 'lo'")

	# Types
	assert_typeof(42, TYPE_INT, "Devrait être un int")
	assert_typeof("text", TYPE_STRING, "Devrait être un string")


# ===== TESTS AVEC NODES =====

func test_node_creation():
	# Créer un node et l'ajouter à l'arbre de test
	var node = autofree(Node2D.new())
	assert_not_null(node, "Le node devrait être créé")
	assert_true(node is Node2D, "Devrait être un Node2D")

func test_node_with_children():
	# Tester une hiérarchie de nodes
	var parent = autofree(Node.new())
	var child = Node.new()
	parent.add_child(child)

	assert_eq(parent.get_child_count(), 1, "Le parent devrait avoir 1 enfant")
	assert_eq(child.get_parent(), parent, "L'enfant devrait avoir le bon parent")


# ===== TESTS AVEC SCENES =====

func test_scene_instantiation():
	# Exemple : Instancier une scène préchargée
	# var scene = autofree(MyScene.instantiate())
	# assert_not_null(scene, "La scène devrait être instanciée")
	pass


# ===== TESTS AVEC SIGNAUX =====

func test_signal_emission():
	# Créer un objet qui émet un signal
	var emitter = autofree(Node.new())

	# Watcher de GUT pour surveiller les signaux
	watch_signals(emitter)

	# Émettre un signal
	emitter.emit_signal("tree_entered")

	# Vérifier que le signal a été émis
	assert_signal_emitted(emitter, "tree_entered", "Le signal devrait être émis")


# ===== TESTS ASYNCHRONES =====

func test_async_with_yield():
	# Pour tester du code asynchrone, utilisez await
	# var timer = Timer.new()
	# add_child(timer)
	# timer.start(0.1)
	# await timer.timeout
	# assert_true(true, "Le timer a expiré")
	pass


# ===== TESTS AVEC PARAMÈTRES =====

func test_with_parameters(params = use_parameters([
	[1, 2, 3],
	[10, 20, 30],
	[100, 200, 300]
])):
	# Test paramétré : sera exécuté 3 fois avec différentes valeurs
	var a = params[0]
	var b = params[1]
	var sum = params[2]
	assert_eq(a + b, sum, "La somme devrait être correcte")


# ===== TESTS À IGNORER =====

func test_not_implemented():
	# Utiliser pending() pour marquer un test comme non implémenté
	pending("Ce test n'est pas encore implémenté")

func test_skip_this():
	# Pour sauter un test conditionnel, utilisez un return early
	if OS.get_name() == "Windows":
		pending("Ce test ne fonctionne pas sous Windows")
		return
	assert_true(true)


# ===== TESTS DE PERFORMANCE =====

func test_performance():
	# Mesurer le temps d'exécution
	var start_time = Time.get_ticks_msec()

	# Code à tester
	for i in range(1000):
		var _x = i * 2  # _ pour indiquer que c'est intentionnel

	var elapsed = Time.get_ticks_msec() - start_time
	assert_true(elapsed < 100, "Devrait prendre moins de 100ms")


# ===== HELPERS (fonctions utilitaires) =====

func _create_test_node() -> Node:
	# Fonction helper pour créer un node de test
	var node = Node.new()
	node.name = "TestNode"
	return node

func _assert_stats_valid(stats: Dictionary):
	# Fonction helper pour valider une structure de données
	assert_true(stats.has("health"), "Stats devrait avoir 'health'")
	assert_true(stats.has("mana"), "Stats devrait avoir 'mana'")


# ===== NOTES IMPORTANTES =====

# 1. ⚠️ Toujours utiliser autofree() avec .new() pour éviter les fuites mémoire
#    ✅ var obj = autofree(MyScript.new())
#    ❌ var obj = MyScript.new()

# 2. Les fonctions de test doivent commencer par "test_"
#    func test_mon_test():  ✅
#    func mon_test():       ❌

# 3. Utilisez des messages descriptifs dans les assertions
#    assert_eq(x, 5, "X devrait être 5")  ✅
#    assert_eq(x, 5)                      ⚠️ (moins clair)

# 4. Un test = une chose à tester
#    Ne testez pas trop de choses dans un seul test

# 5. Nommez vos tests de façon descriptive
#    func test_player_takes_damage_when_hit():  ✅
#    func test1():                              ❌

# 6. Organisez vos tests en sections avec des commentaires
#    # ===== TESTS DE COMBAT =====
#    # ===== TESTS D'INVENTAIRE =====

