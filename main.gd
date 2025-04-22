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


## GAMEOVER:
# "creativite":
# "Monsieur Plouf n’a plus d’idées… il chronique des menus d’options."
# "Monsieur Plouf s’exprime désormais uniquement en aquarelle."
#"sante_mentale":
#"Il a fusionné avec sa chaise de bureau."
#"Il est trop calme. Il fait peur."
#"vie_famille":
#"Sa fille le connaît comme 'l’homme du fond avec les écouteurs'."
#"Ils lancent une chaîne familiale : *Plouffamille Vlog*."
#"temps_jeu":
#"Il chronique les souvenirs de ses anciens let's play."
#"Il ne fait plus que jouer. OBS est parti."



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

func _ready():
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
