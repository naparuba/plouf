extends CanvasLayer

@onready var card_deck := $CardDeck


var card_index = 0
var deck = []

# UI nodes
@onready var label_question = $LabelProblem
# DEBUG part
@onready var label_debug_question = $DEBUGProblem
@onready var label_debug_a = $DEBUGA
@onready var label_debug_b = $DEBUGB


# CRITERIA
var CRITERIA_FLOW = 'flow'
var CRITERIA_FAMILLY_LIFE = 'familly_life'
var CRITERIA_VISIBILITY = 'visibility'
var CRITERIA_RYTHM = 'rythm'

var MAX_STAT = 40

@onready var stat_bars = {
	CRITERIA_RYTHM: $Rythm/progress,
	CRITERIA_FLOW: $Flow/progress,
	CRITERIA_FAMILLY_LIFE: $FamillyLife/progress,
	CRITERIA_VISIBILITY: $Visibility/progress,
}
var stats = {
	CRITERIA_FLOW: 20,
	CRITERIA_VISIBILITY: 20,
	CRITERIA_FAMILLY_LIFE: 20,
	CRITERIA_RYTHM: 20,
}

@onready var label_game_over = $LabelGameOver
@onready var card = $Card

@onready var label_objective = $LabelObjective

# Possible Impact
@onready var label_possible_impact_visibility = $Visibility/PossibleImpact
@onready var label_possible_impact_flow = $Flow/PossibleImpact
@onready var label_possible_impact_rythm = $Rythm/PossibleImpact
@onready var label_possible_impact_familly_life = $FamillyLife/PossibleImpact


@onready var card_viewer = $CardViewer


var phases = [] # liste des phases, ex: ["CHOOSE_CHRONIQUE_GAME", ...]
var problems_by_phase = {} # Dictionnaire : phase_id => liste de problèmes
var seen_ids := {}
var current_phase_index = 0
var current_problem_index = 0
var current_problem_list = []
var current_problem = {}

var phases_display = {
	"CHOOSE_CHRONIQUE_GAME" : "choisir le jeu",
	"PLAY_CHRONIQUE_GAME" : "jouer au jeu",
	"WRITE_CHRONIQUE" : "écrire la chronique",
	"REGISTER_VOICE" : "enregistrer la voix",
	"DRAW_CHRONIQUE" : "dessiner la chronique",
	"ANIMATE_CHRONIQUE" : "faire les animations",
	"MOUNT_CHRONIQUE_VIDEO" : "monter la vidéo",
	"UPLOAD_CHRONIQUE_VIDEO" : "uploader sur YT",
	"ANSWER_CHRONIQUE_COMMENTS" : "commentaires YT",
	"STREAM_POST_CHRONIQUE" : "stream post-chronique",
}

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


func _ready():
	print("Chargement du jeu de Monsieur Plouf...")
	_load_phases()
	_load_problems()
	
	#_rotate_phases_randomly()   # Currently disabled, want to have the same overall logic progression
	
	current_phase_index = 0
	current_problem_index = 0
	seen_ids.clear()
	_load_next_phase()
	
	card_deck.choice_made.connect(on_swipe_choice)
	card_deck.choice_preview.connect(_on_card_preview)
	
	# We can update the deck display
	_update_current_card_deck()


func _load_phases():
	var file = FileAccess.open("res://phases.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	phases = data["phases"]
	for phase in phases:
		problems_by_phase[phase] = []

func _load_problems():
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

func _rotate_phases_randomly():
	var index = randi() % phases.size()
	phases = phases.slice(index, phases.size()) + phases.slice(0, index)

# --- Gameplay
func _load_next_phase():
	if current_phase_index >= phases.size():
		label_question.text = "🎉 Fin de la semaine de Monsieur Plouf !"
		return
	
	var phase_id = phases[current_phase_index]
	current_problem_list = problems_by_phase[phase_id]
	current_problem_index = 0
	seen_ids.clear()
	_load_next_problem()
	
	_show_objective_progression()

func _show_objective_progression():
	var objectives_node = $Objectives
	
	for i in phases.size():
		var label = objectives_node.get_node(str(i+1))
		var phase_id = phases[i]
		var phase_display = phases_display[phase_id]
		var prefix = ''
		if i == current_phase_index:
			prefix = '[color=orange]→[/color]'
		elif i < current_phase_index:
			prefix = '[color=green]✔[/color]'
		else:
			prefix = '[color=red]Х[/color]'
		label.text = prefix + ' ' + phase_display
		


func _load_next_problem():
	if seen_ids.size() >= current_problem_list.size():
		print("✔ Phase ", phases[current_phase_index], " terminée")
		current_phase_index += 1
		_load_next_phase()
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
	label_question.text = problem["problem_description"]
	label_debug_question.text = "🔸 %s - %s\n\n%s" % [problem["problem_id"], problem["title"]]
	label_debug_a.text = "A: %s\n=> %s" % [problem["choice_a"], problem["outcome_a"]]
	label_debug_b.text = "B: %s\n=> %s" % [problem["choice_b"], problem["outcome_b"]]

func on_choice(choice: String):
	print("→ Choix :", choice)
	_apply_consequences(current_problem, choice)
	
	if not _validate_stats():
		label_game_over.text = "💥 Game Over! Stats invalides"
		label_game_over.visible = true
		return
	
	_load_next_problem()
	
	_reset_possible_impacts()  # hide the old impact if shown, as the choice did change


func _get_choice_stat(choice, stat):
	var suffix = "_a" if choice == "A" else "_b"
	var key = stat
	var impact = int(current_problem[key + suffix])
	return impact
	
func _reset_progress_sprite(sprite):
	var tween = create_tween()
	tween.parallel().tween_property(sprite.material, "shader_parameter/particle_amount", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
func _change_progress_sprite(sprite, stat_pct_float_1):
	var tween = create_tween()
	tween.parallel().tween_property(sprite.material, 'shader_parameter/progress', stat_pct_float_1, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite.material, "shader_parameter/particle_amount",30, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Callback go reset when finish
	tween.tween_callback(Callable(self, "_reset_progress_sprite").bind(sprite))

	
func _apply_consequences(problem, choice):
	for stat in stats.keys():
		var impact = _get_choice_stat(choice, stat)
		stats[stat] += impact
		
		var stat_pct = int(round((stats[stat] / 40.0) * 100))
		stat_pct = clamp(stat_pct, 1, 100)
		var stat_pct_float_1 = stat_pct / 100.0
		
		match stat:
			CRITERIA_RYTHM:     
				stat_bars[CRITERIA_RYTHM].value = stat_pct
				var sprite = $Rythm/ProgressSprite
				_change_progress_sprite(sprite, stat_pct_float_1)
				
			CRITERIA_FLOW:  
				stat_bars[CRITERIA_FLOW].value = stat_pct
				var sprite = $Flow/ProgressSprite
				_change_progress_sprite(sprite, stat_pct_float_1)
				
			CRITERIA_FAMILLY_LIFE:
				stat_bars[CRITERIA_FAMILLY_LIFE].value = stat_pct
				var sprite = $FamillyLife/ProgressSprite
				_change_progress_sprite(sprite, stat_pct_float_1)
				
			CRITERIA_VISIBILITY:   
				stat_bars[CRITERIA_VISIBILITY].value = stat_pct
				var sprite = $Visibility/ProgressSprite
				_change_progress_sprite(sprite, stat_pct_float_1)


	print("📊 Stats :", stats)


func _validate_stats():
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
			CRITERIA_RYTHM: label_possible_impact_rythm,
			CRITERIA_FLOW: label_possible_impact_flow,
			CRITERIA_FAMILLY_LIFE: label_possible_impact_familly_life,
			CRITERIA_VISIBILITY: label_possible_impact_visibility,
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
	label_possible_impact_rythm.text = ""
	label_possible_impact_flow.text = ""
	label_possible_impact_familly_life.text = ""
	label_possible_impact_visibility.text = ""


func _on_choice_a_mouse_entered() -> void:
	_update_possible_impacts("A")


func _on_choice_a_mouse_exited() -> void:
	_reset_possible_impacts()


func _on_choice_b_mouse_entered() -> void:
	_update_possible_impacts("B")


func _on_choice_b_mouse_exited() -> void:
	_reset_possible_impacts()


func _get_current_card_image() -> CompressedTexture2D:
	var img_path = current_problem.get("card_img_id", "PLOUF")+'.png'  # fallback
	var img = load("res://images/%s" % img_path)
	return img

func on_swipe_choice(direction: String):
	print("→ Swipe :", direction)
	on_choice(direction)  # ta logique existante
	
	_update_current_card_deck()  # we can show the new card

func _update_current_card_deck():
	# Recharge les visuels dans CardDeck
	var current_img = _get_current_card_image()
	
	var choice_a_txt = current_problem["choice_a"]
	var choice_b_txt = current_problem["choice_b"]
	
	card_deck.set_card_images(current_img, choice_a_txt, choice_b_txt)

func _on_card_preview(direction: String) -> void:
	if direction == "A":
		_update_possible_impacts("A")
	elif direction == "B":
		_update_possible_impacts("B")
	else:
		_reset_possible_impacts()
