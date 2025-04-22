extends CanvasLayer

# Cartes simulées — tu pourras charger dynamiquement plus tard
#class_name CardData

class CardData:
	var question: String
	var left_text: String
	var right_text: String
	var left_effects: Dictionary
	var right_effects: Dictionary

# Statistiques de Plouf
var g_stats = {
	"creativite": 5,
	"sante_mentale": 5,
	"vie_famille": 5,
	"temps_jeu": 5
}

var current_card: CardData
var card_index = 0
var deck = []

# UI nodes
@onready var label_question = $LabelProblem
@onready var label_left = $LabelA
@onready var label_right = $LabelB
@onready var stat_bars = {
	"creativite": $Creativite/progress,
	"sante_mentale": $SanteMentale/progress,
	"vie_famille": $VieFamille/progress,
	"temps_jeu": $TempsJeu/progress,
}
@onready var label_game_over = $LabelGameOver
@onready var card = $Card

func _ready():
	load_deck()
	show_card(deck[card_index])
	
	__load_all_data()

func load_deck():
	# Exemple de 2 cartes — à remplacer par un système dynamique plus tard
	var c1 = CardData.new()
	c1.question = "Tu veux parler d’un jeu que t’as jamais lancé."
	c1.left_text = "Tu lances le jeu"
	c1.right_text = "Tu improvises la chronique"
	c1.left_effects = {"temps_jeu": +2, "creativite": +1}
	c1.right_effects = {"temps_jeu": -1, "sante_mentale": -2}
	
	var c2 = CardData.new()
	c2.question = "Ta fille veut jouer pendant que tu dessines."
	c2.left_text = "Tu joues avec elle"
	c2.right_text = "Tu termines ton dessin"
	c2.left_effects = {"vie_famille": +2, "creativite": -1}
	c2.right_effects = {"creativite": +1, "vie_famille": -2}

	deck = [c1, c2]

func show_card(card_data: CardData):
	current_card = card_data
	label_question.text = card_data.question
	label_left.text = "← " + card_data.left_text
	label_right.text = card_data.right_text + " →"

func _unhandled_input______disabled(event):
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		card.rotation_degrees = clamp(event.relative.x * 0.05, -10, 10)
		card.position.x += event.relative.x

	if event is InputEventScreenTouch and not event.pressed:
		process_card_swipe()
	if event is InputEventMouseButton and not event.pressed:
		process_card_swipe()

func process_card_swipe():
	if card.position.x > 100:
		apply_choice("right")
	elif card.position.x < -100:
		apply_choice("left")
	else:
		card.position = Vector2.ZERO
		card.rotation_degrees = 0

func apply_choice(direction: String):
	var effects = current_card.right_effects
	if direction == "left" :
		effects= current_card.left_effects
	apply_effects(effects)
	update_stats_ui()
	
	card.position = Vector2.ZERO
	card.rotation_degrees = 0
	
	card_index += 1
	if card_index >= deck.size():
		card_index = 0  # boucle pour test
	show_card(deck[card_index])

func apply_effects(effects: Dictionary):
	for stat in effects:
		g_stats[stat] = clamp(g_stats[stat] + effects[stat], 0, 10)
		if g_stats[stat] == 0 or g_stats[stat] == 10:
			trigger_game_over(stat, g_stats[stat])

func update_stats_ui():
	for key in stat_bars:
		stat_bars[key].value = g_stats[key]

func trigger_game_over(stat_name: String, value: int):
	var message := ""
	match stat_name:
		"creativite":
			if value == 0:
				message = "Monsieur Plouf n’a plus d’idées… il chronique des menus d’options."
			else:
				message = "Monsieur Plouf s’exprime désormais uniquement en aquarelle."
		
		"sante_mentale":
			if value == 0:
				message = "Il a fusionné avec sa chaise de bureau."
			else:
				message = "Il est trop calme. Il fait peur."

		"vie_famille":
			if value == 0:
				message = "Sa fille le connaît comme 'l’homme du fond avec les écouteurs'."
			else:
				message = "Ils lancent une chaîne familiale : *Plouffamille Vlog*."

		"temps_jeu":
			if value == 0:
				message = "Il chronique les souvenirs de ses anciens let's play."
			else:
				message = "Il ne fait plus que jouer. OBS est parti."

	label_game_over.text = "GAME OVER\n\n" + message
	label_game_over.visible = true
	get_tree().paused = true





##### Load data
var stats = {
	"Créativité": 20,
	"Santé mentale": 20,
	"Vie de famille": 20,
	"Temps de jeu": 20,
}

var phases = [] # liste des phases, ex: ["CHOOSE_CHRONIQUE_GAME", ...]
var problems_by_phase = {} # Dictionnaire : phase_id => liste de problèmes

var current_phase_index = 0
var seen_ids := {}

func __load_all_data():
	print("Chargement du jeu de Monsieur Plouf...")
	load_phases()
	load_problems()
	rotate_phases_randomly()
	start_game()

func load_phases():
	var file = FileAccess.open("res://phases.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	phases = data["phases"]
	for phase in phases:
		problems_by_phase[phase] = []

func load_problems():
	var file = FileAccess.open("res://plouf_game_50_original_cards.csv", FileAccess.READ)
	var header = file.get_csv_line(";")
	while not file.eof_reached():
		var line = file.get_csv_line(";")
		if line.size() < header.size():
			continue
		var problem = {}
		for i in header.size():
			problem[header[i]] = line[i]
		var phase_id = problem.get("phase_id_dep", "")
		if phase_id in problems_by_phase:
			problems_by_phase[phase_id].append(problem)
		else:
			var random_phase = phases[randi() % phases.size()]
			problems_by_phase[random_phase].append(problem)

func rotate_phases_randomly():
	var index = randi() % phases.size()
	phases = phases.slice(index, phases.size()) + phases.slice(0, index)

func start_game():
	for phase_id in phases:
		var problems = problems_by_phase[phase_id]
		print("\n===== Phase :", phase_id, " (", problems.size(), "problèmes) =====")
		seen_ids.clear()

		while seen_ids.size() < problems.size():
			var problem = problems[randi() % problems.size()]
			if seen_ids.has(problem["problem_id"]):
				continue
			seen_ids[problem["problem_id"]] = true

			print_problem(problem)
			var choice = choose("A", "B")
			apply_consequences(problem, choice)

			if not validate_stats():
				print("\n💥 Game Over! Stats invalides.")
				label_game_over.text = "💥 Game Over! Stats invalides"
				label_game_over.visible = true
				#get_tree().quit()

		print("✔ Phase", phase_id, "terminée !")

	print("\n🎉 Tous les problèmes ont été résolus ! Semaine de Monsieur Plouf terminée.")

func print_problem(problem):
	print("🔸 Problème :", problem["problem_id"], "-", problem["title"])
	print(problem["problem_description"])
	label_question.text = "🔸 Problème :"+ problem["problem_id"]+ "-"+ problem["title"]+ " " + problem["problem_description"]
	
	print("🔹 A :", problem["choice_a"], "=>", problem["outcome_a"])
	print("Impact : C ", problem["creativity_a"], "/ S ",problem["mental_health_a"],  "/ F ",problem["family_life_a"], " / G ", problem["game_time_a"])
	label_left.text = problem["choice_a"]+ "=>"+ problem["outcome_a"]
	
	print("🔹 B :", problem["choice_b"], "=>", problem["outcome_b"])
	print("Impact : C ", problem["creativity_b"], "/ S ",problem["mental_health_b"],  "/ F ",problem["family_life_b"], " / G ", problem["game_time_b"])
	label_right.text = problem["choice_b"]+ "=>"+ problem["outcome_b"]
	
func choose(option1, option2):
	# Pour l’instant, choisit aléatoirement
	var choice = [option1, option2][randi() % 2]
	print("→ Choix :", choice)
	return choice

func apply_consequences(problem, choice):
	var suffix = "_a" if choice == "A" else "_b"
	for stat in stats.keys():
		var key = {
			"Créativité": "creativity",
			"Santé mentale": "mental_health",
			"Vie de famille": "family_life",
			"Temps de jeu": "game_time"
		}[stat]
		var impact = int(problem[key + suffix])
		stats[stat] += impact
		
		if stat == 'Créativité':
			stat_bars["creativite"].value = stats[stat]
		if stat == 'Santé mentale':
			stat_bars["sante_mentale"].value = stats[stat]
		if stat == 'Vie de famille':
			stat_bars["vie_famille"].value = stats[stat]
		if stat == 'Temps de jeu':
			stat_bars["temps_jeu"].value = stats[stat]

	print("📊 Stats après choix :", stats)

func validate_stats():
	for stat in stats:
		if stats[stat] < 0 or stats[stat] > 40:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return false
	return true
