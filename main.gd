extends CanvasLayer


# Statistiques de Plouf
var g_stats = {
	"creativite": 5,
	"sante_mentale": 5,
	"vie_famille": 5,
	"temps_jeu": 5
}


var MAX_STAT = 40

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
@onready var button_a = $ChoiceA
@onready var button_b = $ChoiceB

@onready var label_objective = $LabelObjective

# Possible Impact
@onready var label_possible_impact_temps_jeu = $LabelTempsJeuPossibleImpact
@onready var label_possible_impact_sante_mentale = $LabelSanteMentalePossibleImpact
@onready var label_possible_impact_creativite = $LabelCreativitePossibleImpact
@onready var label_possible_impact_vie_famille = $LabelVieFamillePossibleImpact


@onready var progress_vie_famille = $ProgressVieFamille
@onready var progress_creativite = $ProgressCreativite
@onready var progress_sante_mentale = $ProgressSanteMentale
@onready var progress_temps_jeu = $ProgressTempsJeu

@onready var card_viewer = $CardViewer


var phases = [] # liste des phases, ex: ["CHOOSE_CHRONIQUE_GAME", ...]
var problems_by_phase = {} # Dictionnaire : phase_id => liste de problèmes
var seen_ids := {}
var current_phase_index = 0
var current_problem_index = 0
var current_problem_list = []
var current_problem = {}

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



func _ready():
	print("Chargement du jeu de Monsieur Plouf...")
	load_phases()
	load_problems()
	rotate_phases_randomly()
	current_phase_index = 0
	current_problem_index = 0
	seen_ids.clear()
	button_a.pressed.connect(func(): on_choice("A"))
	button_b.pressed.connect(func(): on_choice("B"))
	load_next_phase()
	
	card_viewer.load_card_image("PLOUF.png")

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

# --- Gameplay
func load_next_phase():
	if current_phase_index >= phases.size():
		label_question.text = "🎉 Fin de la semaine de Monsieur Plouf !"
		button_a.visible = false
		button_b.visible = false
		return
	
	var phase_id = phases[current_phase_index]
	current_problem_list = problems_by_phase[phase_id]
	current_problem_index = 0
	seen_ids.clear()
	load_next_problem()
	
	label_objective.text = "Objectif actuel: " + phase_id

		
		

func load_next_problem():
	if seen_ids.size() >= current_problem_list.size():
		print("✔ Phase ", phases[current_phase_index], " terminée")
		current_phase_index += 1
		load_next_phase()
		return
	
	# Prendre le prochain problème non vu
	while true:
		var p = current_problem_list[current_problem_index % current_problem_list.size()]
		current_problem_index += 1
		if not seen_ids.has(p["problem_id"]):
			current_problem = p
			seen_ids[p["problem_id"]] = true
			display_problem(p)
			break

func display_problem(problem):
	label_question.text = "🔸 %s - %s\n\n%s" % [
		problem["problem_id"], problem["title"], problem["problem_description"]
	]
	label_left.text = "A: %s\n=> %s" % [problem["choice_a"], problem["outcome_a"]]
	label_right.text = "B: %s\n=> %s" % [problem["choice_b"], problem["outcome_b"]]

func on_choice(choice: String):
	print("→ Choix :", choice)
	apply_consequences(current_problem, choice)
	
	if not validate_stats():
		label_game_over.text = "💥 Game Over! Stats invalides"
		label_game_over.visible = true
		button_a.disabled = true
		button_b.disabled = true
		return
	
	load_next_problem()
	
	_reset_possible_impacts()  # hide the old impact if shown, as the choice did change


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

func _get_choice_stat(choice, stat):
	var suffix = "_a" if choice == "A" else "_b"
	var key = {
			"Créativité": "creativity",
			"Santé mentale": "mental_health",
			"Vie de famille": "family_life",
			"Temps de jeu": "game_time"
		}[stat]
	var impact = int(current_problem[key + suffix])
	return impact
	
func apply_consequences(problem, choice):
	#var suffix = "_a" if choice == "A" else "_b"
	for stat in stats.keys():
		#var key = {
		#	"Créativité": "creativity",
		#	"Santé mentale": "mental_health",
		#	"Vie de famille": "family_life",
		#	"Temps de jeu": "game_time"
		#}[stat]
		#var impact = int(problem[key + suffix])
		var impact = _get_choice_stat(choice, stat)
		stats[stat] += impact
		
		var stat_pct = int(round((stats[stat] / 40.0) * 100))
		stat_pct = clamp(stat_pct, 1, 100)
		
		match stat:
			"Créativité":     
				stat_bars["creativite"].value = stat_pct
				progress_creativite.value = stat_pct
			"Santé mentale":  
				stat_bars["sante_mentale"].value = stat_pct
				progress_sante_mentale.value = stat_pct
			"Vie de famille": 
				stat_bars["vie_famille"].value = stat_pct
				progress_vie_famille.value = stat_pct
			"Temps de jeu":   
				stat_bars["temps_jeu"].value = stat_pct
				progress_temps_jeu.value = stat_pct


	print("📊 Stats :", stats)

func validate_stats():
	for stat in stats:
		if stats[stat] < 0 or stats[stat] > MAX_STAT:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return false
	return true



func _update_possible_impacts(choice):
	# """"
	for stat in stats.keys():
		var impact = _get_choice_stat(choice, stat)
		var labels = {
			"Créativité": label_possible_impact_creativite,
			"Santé mentale": label_possible_impact_sante_mentale,
			"Vie de famille": label_possible_impact_vie_famille,
			"Temps de jeu": label_possible_impact_temps_jeu,
		}
		impact =abs(impact)
		if impact == 0:
			continue
		var label = labels[stat]
		if impact <= 1:
			label.text = "🞄"
		elif impact <= 2:
			label.text = "●"
		else:
			label.text = "⬤"
			
		
			

func _reset_possible_impacts():
	label_possible_impact_creativite.text = ""
	label_possible_impact_sante_mentale.text = ""
	label_possible_impact_vie_famille.text = ""
	label_possible_impact_temps_jeu.text = ""



func _on_choice_a_mouse_entered() -> void:
	_update_possible_impacts("A")


func _on_choice_a_mouse_exited() -> void:
	_reset_possible_impacts()


func _on_choice_b_mouse_entered() -> void:
	_update_possible_impacts("B")


func _on_choice_b_mouse_exited() -> void:
	_reset_possible_impacts()
