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

var g_game_over = false  # did we win or loose the game, if so, will just exit

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

# Messages to display when we are finishing a phase
var phases_finish_messages = {}

# Card message: when going to messag card, we don't care about the result, it just means the
#               user did read it, and we can go in the next problem
var g_is_in_card_message : bool = false


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
	
	current_phase_index = 0
	current_problem_index = 0
	seen_ids.clear()
	_initial_phase()
	
	card_deck.choice_made.connect(on_swipe_choice)
	card_deck.choice_preview.connect(on_card_preview)
	
	# We can update the deck display
	_update_current_card_deck()


func _load_phases():
	var file = FileAccess.open("res://phases.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	phases = data["phases"]
	for phase in phases:
		problems_by_phase[phase] = []
	
	# Loading finish messages (to display when we are finishing a phase)
	file = FileAccess.open("res://phases_finish.json", FileAccess.READ)
	phases_finish_messages = JSON.parse_string(file.get_as_text())	
	print('Phase finish:', phases_finish_messages)

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

func __get_random_phase_finish_message(phase_id: String):
	var messages = phases_finish_messages[phase_id]
	var random_idx =  randi() % messages.size()
	return messages[random_idx]


# --- Gameplay
func _initial_phase():  # only at _ready
	var phase_id = phases[current_phase_index]
	current_problem_list = problems_by_phase[phase_id]
	current_problem_index = 0
	seen_ids.clear()
	_load_next_problem()
	_show_objective_progression()


# When finish the last problem of a phase:
# * if no more phases: you fnish, congrats!
# * load next phase
#   - display a message card
#   - when the message card finish: we will display the next problem 
func _jump_to_next_phase():
	print('JUMP TO NEXT PHASE')
	_show_objective_progression()
	
	if current_phase_index >= phases.size():
		label_question.text = "🎉 Fin de la semaine de Monsieur Plouf !"
		self.g_game_over = true
		_switch_to_message_card("🎉 Fin de la semaine de Monsieur Plouf !\nFéliciation pour avoir passé une semaine dans la peau de Monsieur Plouf!\nVous pouvez relancer une partie pour voir de nouvelles cartes.")
		return
	
	# Get a message for the end of our phase
	var finish_phase_id = phases[current_phase_index-1]  # was incremented just before
	var finish_message = __get_random_phase_finish_message(finish_phase_id)
	var message = '[bgcolor=grey][color=black]'+finish_message+'[/color][/bgcolor]'
	_switch_to_message_card(message)
	
	
func _display_problem_after_phase_change():
	print('_display_problem_after_phase_change:: gogogo')
	var phase_id = phases[current_phase_index]
	current_problem_list = problems_by_phase[phase_id]
	current_problem_index = 0
	seen_ids.clear()
	_load_next_problem() # load data
	_update_current_card_deck() # show problem card

func _show_objective_progression():
	var objectives_node = $Objectives
	
	for i in phases.size():
		var label = objectives_node.get_node(str(i+1))
		var phase_id = phases[i]
		var phase_display = phases_display[phase_id]
		var prefix = ''
		var txt_color = 'black'
		if i == current_phase_index:
			prefix = '[color=orange]→[/color]'
			txt_color= 'orange'
		elif i < current_phase_index:
			prefix = '[color=green]✓[/color]'
		else:
			prefix = '[color=red]Х[/color]'
		label.text = prefix + ' [color=black]' + phase_display +' [/color]'
		

# validate the current problem, and return if we did change phase
func _load_next_problem() -> bool:
	print('_load_next_problem')
	if seen_ids.size() >= current_problem_list.size():
		print("✔ Phase ", phases[current_phase_index], " terminée")
		current_phase_index += 1
		_jump_to_next_phase()
		return true
	
	# Prendre le prochain problème non vu
	while true:
		var p = current_problem_list[current_problem_index % current_problem_list.size()]
		current_problem_index += 1
		if not seen_ids.has(p["problem_id"]):
			current_problem = p
			seen_ids[p["problem_id"]] = true
			_display_problem(p)
			break
	return false

func _display_problem(problem):
	label_question.text = problem["problem_description"]
	label_debug_question.text = "🔸 %s - %s\n\n%s" % [problem["problem_id"], problem["title"]]
	label_debug_a.text = "A: %s\n=> %s" % [problem["choice_a"], problem["outcome_a"]]
	label_debug_b.text = "B: %s\n=> %s" % [problem["choice_b"], problem["outcome_b"]]


func _validate_stats():
	for stat in stats:
		if stats[stat] < 0:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return {'state':'too_low', 'stat':stat}
		if stats[stat] > MAX_STAT or true:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return {'state':'too_high', 'stat':stat}
	return {'state':'ok', 'stat':''}

# return if the phase did change
func _apply_choice(choice: String) -> bool:
	print("→ Choix :", choice)
	_apply_stats_consequences(current_problem, choice)
	_reset_possible_impacts()  # hide the old impact if shown, as the choice did change
	
	var r = _validate_stats()
	if r['state'] != 'ok':
		var _bad_stat = r['stat']
		var error = r['state']
		var _err = "💥 Game Over! "+_bad_stat+ " is "+error
		var img_path = ''
		match _bad_stat:
			CRITERIA_FLOW: 
				if error == 'too_low':
					_err = "💥 [b]Page Blanche[/b]!\nIl regarde son écran depuis 7h, mais rien ne vient."
					img_path = 'FLOW_TOO_LOW'
				else:
					_err = "💥 [b]Plouf en feu[/b]!\nSes idées l'ont dévoré. Il chronique les nuages et intérupteurs.\nIl ne dors plus, il [i]crée[/i]."
					img_path = 'FLOW_TOO_HIGH'
			CRITERIA_FAMILLY_LIFE:
				if error == 'too_low':
					_err = "💥 [b]Papa, c'est qui lui?[/b]!\nSa fille ne le reconnait plus."
					img_path = 'FAMILLY_LIFE_TOO_LOW'
				else:
					_err = "💥 [b]PloufFamille VLog[/b]!\nIl a renommé sa chaine Youtube. Il ne parle désormais que de tuto pour faire des slimes."
					img_path = 'FAMILLY_LIFE_TOO_HIGH'
			CRITERIA_VISIBILITY:
				if error == 'too_low':
					_err = "💥 [b]Le grand silence[/b]!\nMême l'algorithme de Youtube l'a oublié."
					img_path = 'VISIBILITY_TOO_LOW'
				else:
					_err = "💥 [b]Influenceur[/b]!\nMacDo, Nike et même [i]UbiSoft[/i]: tout le monde veut sponsoriser Plouf!."
					img_path = 'VISIBILITY_TOO_HIGH'
			CRITERIA_RYTHM:
				if error == 'too_low':
					_err = "💥 [b]Plouf fusionne avec sa chaise[/b]!\nIl fait parti du fauteuil\nTwitch a mis le tag 'objet inanimé' sur son live."
					img_path = 'RYTHM_TOO_LOW'
				else:
					_err = "💥 [b]Productivité terminale[/b]!\nUne vidéo toutes les heures. Il ne voit plus les saisons passer. Il [i]est[/i] le contenu."
					img_path = 'RYTHM_TOO_HIGH'
		g_game_over = true
		_err = '[bgcolor=grey][color=black]' + _err + '[/color][/bgcolor]'
		_switch_to_gameover_card(_err, 'Arg, une autre semaine peut être...', img_path)
		return true  # simulate like if we did change state, as we move to the end game
	
	var did_change_phase = _load_next_problem()
	return did_change_phase


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

	
func _apply_stats_consequences(problem, choice):
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





func _update_possible_impacts(choice):
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


func _switch_to_message_card(message:String):
	var img = load("res://images/FADED.png")
	g_is_in_card_message = true
	print('Display message card: ', message)
	card_deck.set_card_data(null, img, "OK", "OK", message)
	

func _switch_to_gameover_card(message:String, swipe_message:String, img_path : String):
	var img = load("res://images/"+img_path+".png")
	g_is_in_card_message = true
	print('Display message card: ', message)
	card_deck.set_card_data(null, img, swipe_message, swipe_message, message)

func _get_current_card_textures() -> Dictionary:
	var character_path = current_problem.get("character_img_id", "PLOUF")+'.png'  # fallback
	var character_texture = load("res://images/%s" % character_path)
	var background_path = current_problem.get("background_img_id", "FADED")+'.png'  # fallback
	print('LOADING BACKGROUND texture ', background_path)
	var background_texture = load("res://images/%s" % background_path)
	return {'character':character_texture, 'background':background_texture}


func on_swipe_choice(direction: String):
	if g_is_in_card_message:  # we have a return from a message card, just show the next problem
		g_is_in_card_message = false  # no more a message
		
		if g_game_over: # we did finish, just close the game currently
			OS.shell_open("https://www.youtube.com/@MonsieurPlouf")
			self.get_tree().quit()  # Bye bye
			return
		
		_display_problem_after_phase_change()
		return
	
	print("→ Swipe :", direction)
	var did_change_phase = _apply_choice(direction)  # ta logique existante
	
	# if we are in the same phase, we can directly show the new problem
	if not did_change_phase:
		_update_current_card_deck()  # we can show the new card

func _update_current_card_deck():
	# Recharge les visuels dans CardDeck
	var textures = _get_current_card_textures()
	var character_texture = textures['character']
	var background_texture = textures['background']
	
	var choice_a_txt = current_problem["choice_a"]
	var choice_b_txt = current_problem["choice_b"]
	
	card_deck.set_card_data(character_texture,background_texture, choice_a_txt, choice_b_txt, "")

func on_card_preview(direction: String) -> void:
	if g_is_in_card_message:  # if we are just showing a message card, preview means nothing
		return
	if direction == "A":
		_update_possible_impacts("A")
	elif direction == "B":
		_update_possible_impacts("B")
	else:
		_reset_possible_impacts()
