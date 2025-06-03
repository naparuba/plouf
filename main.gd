extends CanvasLayer

@onready var card_deck := $CardDeck

# Some debug flag for... the dev, me
var DEBUG_SKIP_TUTO = false
var DEBUG_FORCE_TUTO = false
var DEBUG_GAMEOVER = false
var DEBUG_WIN = false
var DEBUG_CRITERIA_EFFECTS = false

var DEBUG_DISABLE_INTRO = false


var card_index = 0
var deck = []

# UI nodes
@onready var label_question = $LabelProblem
# DEBUG part
@onready var label_debug_question = $DEBUGProblem
@onready var label_debug_a = $DEBUGA
@onready var label_debug_b = $DEBUGB


# Problem cards
var NB_CARDS_BY_PHASE = 5
var MULTIPLIER_HUGE_IMPACT = 10  # each phase will have a huge impact card with 10x !
var MULTIPLIER_IMPACT_HIGH = 3  # multiplier will be from 1->3

# CRITERIA
var CRITERIA_CREATIVITY = 'creativity'
var CRITERIA_FAMILLY_LIFE = 'familly_life'
var CRITERIA_POPULARITY = 'popularity'
var CRITERIA_SPEED = 'speed'

var MAX_STAT = 40
var CRITERIA_WARNING_THRESHOLD = 0.2  # 20% => warning!

@onready var stat_bars = {
	CRITERIA_SPEED: $Speed/progress,
	CRITERIA_CREATIVITY: $Creativity/progress,
	CRITERIA_FAMILLY_LIFE: $FamillyLife/progress,
	CRITERIA_POPULARITY: $Popularity/progress,
}
var stats = {
	CRITERIA_CREATIVITY: 20,
	CRITERIA_POPULARITY: 20,
	CRITERIA_FAMILLY_LIFE: 20,
	CRITERIA_SPEED: 20,
}

@onready var card = $Card

@onready var label_objective = $LabelObjective

# Possible Impact
@onready var label_possible_impact_popularity = $Popularity/PossibleImpact
@onready var label_possible_impact_creativity = $Creativity/PossibleImpact
@onready var label_possible_impact_speed = $Speed/PossibleImpact
@onready var label_possible_impact_familly_life = $FamillyLife/PossibleImpact

var impact_is_activated_creativity = false
var impact_is_activated_popularity = false
var impact_is_activated_speed = false
var impact_is_activated_familly_life = false

@onready var label_choice_impact = $LabelImpact
var label_choice_impact_tween: Tween = null
var label_choice_impact_timer: Timer = null
var LABEL_CHOICE_IMPACT_DISPLAY_DURATION = 10

@onready var card_viewer = $CardViewer


var phases = [] # liste des phases, ex: ["CHOOSE_CHRONIQUE_GAME", ...]
var problems_by_phase = {} # Dictionnaire : phase_id => liste de problèmes
var seen_ids := {}
var current_phase_index = 0
var current_problem_index = 0
var current_problem_list = []
var current_problem = {}
var g_remaining_current_problems = []

var g_game_over = false  # did we win or loose the game, if so, will just exit

# Play games
var played_games = []
var played_game = 'Paper Mario'

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

# Temporary panel display for impacts:
var impacts_message_queue: Array = []
var impacts_message_is_displaying_message := false
@onready var impacts_message_label = $LabelImpactEffects

@onready var intro = $intro

# Sounds
var warning_sound_limiter := WarningSoundLimiter.new()

# Save data
const SAVE_FILE_PATH = "user://save_data.json"
# What we want to save between runs
var save_data := {
	"has_reached_phase_5": false,
}


func _ready():
	print("Chargement du jeu de Monsieur Plouf...")
	intro.visible = false
	
	_load_game_data()  # we need the game data to know if we are skiping tuto
	print('HAVE REACH PHASE 5? ', self.save_data['has_reached_phase_5'])
	
	if not DEBUG_DISABLE_INTRO:
		intro.visible = true
		await intro.launch_intro()  # need to await, if not will launch the app that will read inputs
		print('INTRO FINISH in main')
	
	
	_load_phases()
	_load_play_games()
	_load_problems()
	_limit_problems_counts()  # don't have too much problems by phase
	_generate_impact_multiplier()  # dynamic set the impact levels
	_launch_impact_message_thread()
	
	current_phase_index = 0
	current_problem_index = 0
	seen_ids.clear()
	_initial_phase()
	
	card_deck.choice_made.connect(on_swipe_choice)
	card_deck.choice_preview.connect(on_card_preview)
	card_deck.global_message_read.connect(on_global_message_read)
	
	# We can update the deck display
	var next_huge_impact_card_index = __get_index_for_next_huge_impact_card()
	var stack_animation = card_deck.stack_cards(len(g_remaining_current_problems), next_huge_impact_card_index)
	await stack_animation.finished  # for the the stack to be in the good place
	_update_current_card_deck()

	# By default the problem text are printing fast
	label_question.set_fast_mode()
	
	
	
	# We can show the help/tuto
	$help_1.visible = true
	$help_2.visible = false
	$help_3.visible = false
	
	# don't show any result
	label_choice_impact.visible = false
	
	var is_experimented_user = self.save_data["has_reached_phase_5"]
	if not DEBUG_FORCE_TUTO and (DEBUG_SKIP_TUTO or is_experimented_user):
		$help_1.visible = false
		card_deck.enable_interaction()


func _input(event):
	# Quit on escape key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("Touche Échap pressée !")
		get_tree().quit()
		
	elif event is InputEventJoypadButton:
		if event.pressed and (event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_X):
			print('MAIN:: BUTTON A IS PRESSED')


func _save_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(save_data)
		file.store_string(json)
		file.close()
		print('SAVE GAME:: the game data are saved')
	else:
		print("Erreur d'accès fichier pour la sauvegarde.")


func _load_game_data():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return  # At first startup or web cache clean
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json_result = JSON.parse_string(json_str)
		if typeof(json_result) == TYPE_DICTIONARY:
			# IMPORTANT: key are the one in save_data, so beware if changing name in the future!
			for key in save_data.keys():
				if json_result.has(key):
					save_data[key] = json_result[key]
		file.close()

func _load_phases():
	var file = FileAccess.open("res://phases.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	phases = data["phases"]
	for phase in phases:
		problems_by_phase[phase] = []
	
	# Loading finish messages (to display when we are finishing a phase)
	file = FileAccess.open("res://phases_finish.json", FileAccess.READ)
	self.phases_finish_messages = JSON.parse_string(file.get_as_text())	
	print('Phase finish:', self.phases_finish_messages)


func _load_play_games():
	var file = FileAccess.open("res://possible_games.json", FileAccess.READ)
	self.played_games = JSON.parse_string(file.get_as_text())	
	print('Possible games:', self.played_games)
	# And we are alrady choosing a game, yes we are lying to the user that think
	# Plouf is choosing the game in the first phase, but eh, that's what games are about: magic ^^
	self.played_game = self.played_games[randi() % self.played_games.size()]
	print('In fact Plouf will choose '+self.played_game)
	

func _change_text_with_played_game(text:String):
	return text.replace('$GAME', self.played_game)

# to fill all phases, we need to get less fill ones, so it's uniform distributed
func _get_least_filled_phase() -> String:
	var min_count = null
	var least_filled = []

	for phase in phases:
		var count = 0
		if problems_by_phase.has(phase):
			count = problems_by_phase[phase].size()

		if min_count == null or count < min_count:
			min_count = count
			least_filled = [phase]
		elif count == min_count:
			least_filled.append(phase)

	if least_filled.size() > 0:
		var less_fill_phase = least_filled[randi() % least_filled.size()]
		print('LESS FILL PHASE: '+less_fill_phase)
		return less_fill_phase
	else:
		print('NO PHASE???')
		return ""


func _load_problems():
	var file = FileAccess.open("res://plouf_game_cards.csv", FileAccess.READ)
	var header = file.get_csv_line(";")
	while not file.eof_reached():
		var line = file.get_csv_line(";")
		
		if line.size() < header.size():
			print('Wrong line size '+str(line.size())+' was expected '+str(header.size()))
			continue
		var problem = {}
		for i in header.size():
			problem[header[i]] = line[i]
		# Protect \n for loading choice_X so it do not overload the card
		problem['choice_a'] = problem['choice_a'].replace("\\n", "\n")
		problem['choice_b'] = problem['choice_b'].replace("\\n", "\n")
		var phase_id = problem.get("phase_id_dep", "")
		if phase_id in problems_by_phase:
			problems_by_phase[phase_id].append(problem)
		else:
			var less_filled_phase = _get_least_filled_phase()  # is doing random if need
			problems_by_phase[less_filled_phase].append(problem)


func _limit_problems_counts():
	for phase_id in problems_by_phase.keys():
		var problems = problems_by_phase[phase_id]
		problems.shuffle() # Mélange les problèmes
		problems_by_phase[phase_id] = problems.slice(0, min(NB_CARDS_BY_PHASE, problems.size()))
		print('Limite problems: '+phase_id+ ' => '+str(len(problems_by_phase[phase_id])))


# For each phase:
# - one problem will be a huge impact one: will take a 10 multiplier
# - others will have a random multiplier from 1 to 3
func _generate_impact_multiplier():
	for phase_id in problems_by_phase.keys():
		var problems = problems_by_phase[phase_id].duplicate()  # copy so the order don't change
		problems.shuffle() # so the huge impact will be random
		var is_huge_impact_done = false
		for problem in problems:
			if not is_huge_impact_done:
				problem['impact_multiplier'] = MULTIPLIER_HUGE_IMPACT
				is_huge_impact_done= true
				#print(phase_id+ ' huge impact')
				continue
			problem['impact_multiplier'] = randi_range(1, MULTIPLIER_IMPACT_HIGH)
			#print(phase_id+ ' > ', problem['impact_multiplier'])


func __get_random_phase_finish_message(phase_id: String):
	var messages = self.phases_finish_messages[phase_id]
	var random_idx =  randi() % messages.size()
	var original_text = messages[random_idx]
	var with_game_text = _change_text_with_played_game(original_text)
	return with_game_text


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
	
	# If we did reach the phase 5 (middle of the game), then we are supposing the
	# user know how to play, so we will be able to skip tutos
	if current_phase_index == 5:
		self.save_data["has_reached_phase_5"] = true
		self._save_game_data()
	
	if current_phase_index >= phases.size() or DEBUG_WIN:
		__set_problem_text("🎉 Fin de la semaine de Monsieur Plouf !")
		self.g_game_over = true
		# Play vctory music
		SoundManager.play_sound('win')
		_switch_to_win_card("🎉 Chronique finie, fin de la semaine de Monsieur Plouf !\nFéliciation pour avoir passé une semaine dans la peau de Monsieur Plouf!\nJ'espère que vous vous êtes bien amusés :)\nN'hésitez pas à proposer des idées de cartes, le jeu est Open Source.", "ENDING")
		return
	
	# Play a success sond, great :)
	SoundManager.play_sound('success')
	# Get a message for the end of our phase
	var finish_phase_id = phases[current_phase_index-1]  # was incremented just before
	var finish_message = __get_random_phase_finish_message(finish_phase_id)
	_display_next_phase_message(finish_message)
	
	
func _display_problem_after_phase_change():
	print('_display_problem_after_phase_change:: gogogo')
	var phase_id = phases[current_phase_index]
	current_problem_list = problems_by_phase[phase_id]
	current_problem_index = 0
	seen_ids.clear()
	_load_next_problem() # load data
	
	# As we know how much cards are fremaining,we can show them
	var next_huge_impact_card_index = __get_index_for_next_huge_impact_card()
	var stack_animation = card_deck.stack_cards(len(g_remaining_current_problems), next_huge_impact_card_index)
	await stack_animation.finished  # for the the stack to be in the good place
	
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
		

func __refresh_remaining_problems():
	var unseens = []
	for p in current_problem_list:
		var pb_id = p["problem_id"]
		if seen_ids.has( pb_id ):
			continue
		unseens.append(p)
	g_remaining_current_problems = unseens
	return 


func __get_index_for_next_huge_impact_card():
	var idx = 0
	for problem in g_remaining_current_problems:
		if problem['impact_multiplier'] == MULTIPLIER_HUGE_IMPACT:
			return idx 
		idx += 1
	return -1

# validate the current problem, and return if we did change phase
func _load_next_problem() -> bool:
	print('_load_next_problem')
	if seen_ids.size() >= current_problem_list.size():
		print("✔ Phase ", phases[current_phase_index], " terminée")
		current_phase_index += 1
		_jump_to_next_phase()
		return true
	
	__refresh_remaining_problems()
	print('Remaining problems: ', len(g_remaining_current_problems), ' : ', g_remaining_current_problems)
	
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
	print('CURRENT PROBLEM ',problem)
	var problem_text = _change_text_with_played_game(problem["problem_description"])
	__set_problem_text(problem_text)
	label_debug_question.text = "🔸 %s - %s\n\n%s" % [problem["problem_id"], problem["title"]]
	label_debug_a.text = "A: %s\n=> %s" % [problem["choice_a"], problem["outcome_a"]]
	label_debug_b.text = "B: %s\n=> %s" % [problem["choice_b"], problem["outcome_b"]]


func __set_problem_text(txt):
	label_question.reveal_text(txt)

func _validate_stats():
	for stat in stats:
		if stats[stat] < 0:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return {'state':'too_low', 'stat':stat}
		if stats[stat] > MAX_STAT:
			print("⚠ Stat", stat, "est hors limites :", stats[stat])
			return {'state':'too_high', 'stat':stat}
	return {'state':'ok', 'stat':''}

# return if the phase did change
func _apply_choice(choice: String) -> bool:
	print("→ Choix :", choice)
	_apply_stats_consequences(choice)
	_reset_possible_impacts()  # hide the old impact if shown, as the choice did change
	_play_voice(choice)
	
	var r = _validate_stats()
	
	# To debug the gameover
	if DEBUG_GAMEOVER:
		r['state'] = 'too_high'
		r['stat'] = CRITERIA_CREATIVITY
		
	if r['state'] != 'ok':
		var _bad_stat = r['stat']
		var error = r['state']
		var _err = "💥 Game Over! "+_bad_stat+ " is "+error
		var img_path = ''
		match _bad_stat:
			CRITERIA_CREATIVITY: 
				if error == 'too_low':
					_err = "💥 [b]Page Blanche[/b]!\nIl regarde son écran depuis 7h, mais rien ne vient."
					img_path = 'CREATIVITY_TOO_LOW'
				else:
					_err = "💥 [b]Plouf en feu[/b]!\nSes idées l'ont dévoré. Il chronique les nuages et intérupteurs.\nIl ne dors plus, il [i]crée[/i]."
					img_path = 'CREATIVITY_TOO_HIGH'
			CRITERIA_FAMILLY_LIFE:
				if error == 'too_low':
					_err = "💥 [b]Papa, c'est qui lui?[/b]!\nSa fille ne le reconnait plus."
					img_path = 'FAMILLY_LIFE_TOO_LOW'
				else:
					_err = "💥 [b]PloufFamille VLog[/b]!\nIl a renommé sa chaine Youtube. Il ne parle désormais que de tuto pour faire des slimes."
					img_path = 'FAMILLY_LIFE_TOO_HIGH'
			CRITERIA_POPULARITY:
				if error == 'too_low':
					_err = "💥 [b]Le grand silence[/b]!\nMême l'algorithme de Youtube l'a oublié."
					img_path = 'POPULARITY_TOO_LOW'
				else:
					_err = "💥 [b]Influenceur[/b]!\nMacDo, Ubisoft et même [i]Konami[/i]: tout le monde veut sponsoriser Plouf!."
					img_path = 'POPULARITY_TOO_HIGH'
			CRITERIA_SPEED:
				if error == 'too_low':
					_err = "💥 [b]Plouf fusionne avec sa chaise[/b]!\nIl fait parti du fauteuil\nTwitch a mis le tag 'objet inanimé' sur son live."
					img_path = 'SPEED_TOO_LOW'
				else:
					_err = "💥 [b]Productivité terminale[/b]!\nUne vidéo toutes les heures. Il ne voit plus les saisons passer. Il [i]est[/i] le contenu."
					img_path = 'SPEED_TOO_HIGH'
		g_game_over = true
		_err = '[color=white]' + _err + '[/color]'
		# Play lost music, sorry :)
		SoundManager.play_sound('lost')
		_switch_to_gameover(_err, 'Arg, une autre semaine peut être...', img_path)
		return true  # simulate like if we did change state, as we move to the end game
	
	var did_change_phase = _load_next_problem()
	return did_change_phase


func _get_choice_stat(choice, stat):
	var suffix = "_a" if choice == "A" else "_b"
	var key = stat
	var impact = int(current_problem[key + suffix]) * current_problem['impact_multiplier']  # was loaded as string from csv
	return impact

func _get_choice_impact_text(choice):
	var suffix = "_a" if choice == "A" else "_b"
	var choice_impact = current_problem['outcome'+suffix]
	# change the $GAME into it
	choice_impact = _change_text_with_played_game(choice_impact)
	return choice_impact

func _reset_progress_sprite(sprite):
	var tween = create_tween()
	tween.parallel().tween_property(sprite.material, "shader_parameter/particle_amount", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	
func _change_progress_sprite(sprite, stat_pct_float_1):
	var tween = create_tween()
	tween.parallel().tween_property(sprite.material, 'shader_parameter/progress', stat_pct_float_1, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite.material, "shader_parameter/particle_amount",30, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Callback go reset when finish
	tween.tween_callback(Callable(self, "_reset_progress_sprite").bind(sprite))


# Based on the choice, will playbe the sound if there is one for this
func _play_voice(choice: String):
	var voice_path = current_problem['sound_'+choice.to_lower()]
	SoundManager.play_voice(voice_path)


func _apply_stats_consequences(choice):
	# first apply impacts stats
	for stat in stats.keys():
		var impact = _get_choice_stat(choice, stat)
		stats[stat] += impact
		
		var stat_pct = int(round((stats[stat] / 40.0) * 100))
		stat_pct = clamp(stat_pct, 1, 100)
		var stat_pct_float_1 = stat_pct / 100.0
		
		print('SPAWN CRITERIA PARTICLE:', choice, ' stat', stat, ' ',str(impact))
		_spawn_criteria_particle(choice, stat, impact)
		
		match stat:
			CRITERIA_SPEED:
				__manage_criteria_speed(stat_pct_float_1)
			CRITERIA_CREATIVITY:  
				__manage_criteria_creativity(stat_pct_float_1)
			CRITERIA_FAMILLY_LIFE:
				__manage_criteria_familly_life(stat_pct_float_1)
			CRITERIA_POPULARITY:
				__manage_criteria_popularity(stat_pct_float_1)
		
	print("📊 Stats :", stats)
	
	_display_choice_impact_text(choice)
	

# Display the result of the last card and hide it after 5s
func _display_choice_impact_text(choice: String):
	# Then display the problem text
	if self.label_choice_impact_tween and self.label_choice_impact_tween.is_running():
		self.label_choice_impact_tween.kill()  # if the previous animation was on, just stop it and reset
	if self.label_choice_impact_timer:
		self.label_choice_impact_timer.queue_free()
	label_choice_impact.text = 'Résultat: ' + _get_choice_impact_text(choice)
	label_choice_impact.visible = true
	label_choice_impact.visible_ratio = 0.0
	self.label_choice_impact_tween = create_tween()
	self.label_choice_impact_tween.tween_property(label_choice_impact, 'visible_ratio', 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# To not block this call, adding a callback to make disapear the text in 5s
	self.label_choice_impact_timer = Timer.new()
	self.label_choice_impact_timer.wait_time = LABEL_CHOICE_IMPACT_DISPLAY_DURATION - 0.2
	self.label_choice_impact_timer.one_shot = true
	self.label_choice_impact_timer.timeout.connect(_on_label_choice_impact_timeout)
	add_child(self.label_choice_impact_timer)
	self.label_choice_impact_timer.start()
	

# After 5s, we are fading the label choice impact text
func _on_label_choice_impact_timeout():
	self.label_choice_impact_tween = create_tween()
	self.label_choice_impact_tween.tween_property(label_choice_impact, 'visible_ratio', 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func __criteria_goes_low(stat_pct_float_1: float):
	return stat_pct_float_1 < CRITERIA_WARNING_THRESHOLD

func __criteria_goes_high(stat_pct_float_1: float):
	return stat_pct_float_1 > 1.0 - CRITERIA_WARNING_THRESHOLD

# The shader take one parameter: too_high=true=>red, and =false=>blue 
func __set_criteria_fire_as_red(fire):
	fire.material.set_shader_parameter('too_high', true)
func __set_criteria_fire_as_blue(fire):
	fire.material.set_shader_parameter('too_high', false)

# Speed :
# - low: timer of 10s for choosing
# - high: all is VERY slow
func __manage_criteria_speed(stat_pct_float_1: float):
	if DEBUG_CRITERIA_EFFECTS:
		#stat_pct_float_1 = randf_range(0.01, 0.3)
		stat_pct_float_1 = randf_range(0.01, 0.99)
	print('New SPEED: ', stat_pct_float_1)
	stat_bars[CRITERIA_SPEED].value = stat_pct_float_1 * 100
	var sprite = $Speed/ProgressSprite
	_change_progress_sprite(sprite, stat_pct_float_1)
	# Fire shader
	var fire = $Speed/fire
	
	var too_low = __criteria_goes_low(stat_pct_float_1)
	var too_high = __criteria_goes_high(stat_pct_float_1)
	
	if  (not (too_low or too_high)):
		if self.impact_is_activated_speed:  # no more activated
			print('SPEED: get back as normal')
			# no impact on shaders
			card_deck.unset_rush()
			
			label_question.set_fast_mode()
			fire.visible= false  # get back as normal, so hide the fire indicator
		return
		
	if self.impact_is_activated_speed: # already active
		return
		
	warning_sound_limiter.play_warning_sound()  # let the user know it's going wrong ^^
	self.impact_is_activated_speed = true
	fire.visible = true # let the user be eye attract by this problem
	if too_low:  # go brut
		print('SPEED: get too low')
		__set_criteria_fire_as_blue(fire)
		card_deck.set_rush()  # only 10s for choice
		self.stack_impact_message("[color=blue]Vitesse[/color]: Plouf n'a plus le temps, il rush tout!")
		
	if too_high:
		print('SPEED: get too high')
		__set_criteria_fire_as_red(fire)
		label_question.set_slow_mode()  # Plouf is too fast, he see the text as too slow ^^
		self.stack_impact_message("[color=red]Vitesse[/color]: Plouf va plus vite que Flash et Ploufman réunis, il risque le claquage!")
			

# Creativity:
# - low: going brut shader
# - high: activating spyche shader
func __manage_criteria_creativity(stat_pct_float_1: float):
	if DEBUG_CRITERIA_EFFECTS:
		#stat_pct_float_1 = randf_range(0.01, 0.3)
		stat_pct_float_1 = randf_range(0.01, 0.99)
	print('New CREATIVITY: ', stat_pct_float_1)
	stat_bars[CRITERIA_CREATIVITY].value = stat_pct_float_1 * 100
	var sprite = $Creativity/ProgressSprite
	_change_progress_sprite(sprite, stat_pct_float_1)
	# Fire shader
	var fire = $Creativity/fire
	
	var too_low = __criteria_goes_low(stat_pct_float_1)
	var too_high = __criteria_goes_high(stat_pct_float_1)
	
	var background_shader = $Background.material
	
	if  (not(too_low or too_high)):
		if self.impact_is_activated_creativity:  # no more activated
			print('CREATIVITY: get back as normal')
			var tween = create_tween()
			tween.parallel().tween_property(background_shader, 'shader_parameter/deform_strength', 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(background_shader, 'shader_parameter/pixel_size', 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			card_deck.unset_text_wobby()  # card text are stable again
			card_deck.unset_text_raw()  # no more text block
			fire.visible= false  # get back as normal, so hide the fire indicator
		return
		
	if self.impact_is_activated_creativity: # already active
		return
		
	warning_sound_limiter.play_warning_sound()  # let the user know it's going wrong ^^
	self.impact_is_activated_creativity = true
	fire.visible = true # let the user be eye attract by this problem
	if too_low:  # go brut
		print('CREATIVITY: get too low')
		var tween = create_tween()
		tween.parallel().tween_property(background_shader, 'shader_parameter/pixel_size', 32.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		card_deck.set_text_raw()  # text goes blocky
		__set_criteria_fire_as_blue(fire)
		self.stack_impact_message("[color=blue]Créativité[/color]: Plouf manque d'inspiration, tout lui semble brut")
		
	if too_high:
		print('CREATIVITY: get too high')
		var tween = create_tween()
		tween.parallel().tween_property(background_shader, 'shader_parameter/deform_strength', 0.5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		card_deck.set_text_wobby()  # text goes wobby, pshyche
		__set_criteria_fire_as_red(fire)
		self.stack_impact_message("[color=red]Créativité[/color]: Sa créativité débordante, Plouf commence à voir des choses qui n'existent pas")

# Popularity:
# - low: hiding UI for 1s every 5s
# - high: logo are bouncing every where
func __manage_criteria_popularity(stat_pct_float_1: float):
	if DEBUG_CRITERIA_EFFECTS:
		#stat_pct_float_1 = randf_range(0.05, 0.3)
		stat_pct_float_1 = randf_range(0.01, 0.99)
	print('New POPULARITY: ', stat_pct_float_1)
	stat_bars[CRITERIA_POPULARITY].value = stat_pct_float_1 * 100
	var sprite = $Popularity/ProgressSprite
	_change_progress_sprite(sprite, stat_pct_float_1)

	var too_low = __criteria_goes_low(stat_pct_float_1)
	var too_high = __criteria_goes_high(stat_pct_float_1)
	# Fire shader
	var fire = $Popularity/fire
	
	var logos_node = $Logos
	
	if  (not(too_low or too_high)):
		if self.impact_is_activated_popularity:  # no more activated
			print('POPULARITY: get back as normal')
			var tween = create_tween()
			tween.parallel().tween_property(logos_node, 'modulate:a', 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			$Background.material.set_shader_parameter('recurring_hide', false)
			fire.visible= false  # get back as normal, so hide the fire indicator
		return
		
	if self.impact_is_activated_popularity: # already active
		return
	
	warning_sound_limiter.play_warning_sound()  # let the user know it's going wrong ^^
	self.impact_is_activated_popularity = true
	fire.visible = true # let the user be eye attract by this problem
	if too_low:  # hiding UI for 1s every 5s
		print('POPULARITY: get too low')
		$Background.material.set_shader_parameter('recurring_hide', true)
		__set_criteria_fire_as_blue(fire)
		self.stack_impact_message("[color=blue]Popularité[/color]: Internet semble oublier Plouf. Le public en vient à se demander si Ploufman existe réélement")

	if too_high: # logo are bouncing every where
		print('POPULARITY: get too high')
		var tween = create_tween()
		tween.parallel().tween_property(logos_node, 'modulate:a', 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		__set_criteria_fire_as_red(fire)
		self.stack_impact_message("[color=red]Popularité[/color]: Plouf attire trop les regards. Ca atise la convoitise de \"certains\" ")


# Familly life:
# - low: goes grey, sad, no sound
# - high: familly invasion :)
func __manage_criteria_familly_life(stat_pct_float_1: float):
	if DEBUG_CRITERIA_EFFECTS:
		#stat_pct_float_1 = randf_range(0.01, 0.3)
		stat_pct_float_1 = randf_range(0.01, 0.99)
	print('New FAMILLY_LIFE: ', stat_pct_float_1)
	stat_bars[CRITERIA_FAMILLY_LIFE].value = stat_pct_float_1 * 100
	var sprite = $FamillyLife/ProgressSprite
	_change_progress_sprite(sprite, stat_pct_float_1)
	# Fire shader
	var fire = $FamillyLife/fire
	
	var too_low = __criteria_goes_low(stat_pct_float_1)
	var too_high = __criteria_goes_high(stat_pct_float_1)
	
	var background_shader = $Background.material
	var familly_invasion = $FamillyInvasion
	
	if (not(too_low or too_high)):
		if self.impact_is_activated_familly_life:  # no more activated
			print('FAMILLY_LIFE: get back as normal')
			var tween = create_tween()
			tween.parallel().tween_property(background_shader, 'shader_parameter/grayness_strength', 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(familly_invasion, 'modulate:a', 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			card_deck.unset_grey()  # no more grey for the card too
			fire.visible = false  # get back as normal, so hide the fire indicator
			SoundManager.reactivate_sounds()  # no more familly problem, get back as normal
		return
		
	if self.impact_is_activated_familly_life: # already active
		return
	
	warning_sound_limiter.play_warning_sound()  # let the user know it's going wrong ^^
	self.impact_is_activated_familly_life = true
	fire.visible = true # let the user be eye attract by this problem
	if too_low:  # goes grey, sad
		print('FAMILLY_LIFE: get too low')
		var tween = create_tween()
		tween.parallel().tween_property(background_shader, 'shader_parameter/grayness_strength', 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		card_deck.set_grey()  # go grey for the card too
		__set_criteria_fire_as_blue(fire)
		SoundManager.stop_all_sounds()  # no familly, no sounds
		self.stack_impact_message('[color=blue]Vie famille[/color]: sa famille manque à Plouf')
		
	if too_high: # familly invasion
		print('FAMILLY_LIFE: get too high')
		var tween = create_tween()
		tween.parallel().tween_property(familly_invasion, 'modulate:a', 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		__set_criteria_fire_as_red(fire)
		self.stack_impact_message('[color=red]Vie famille[/color]: Mme Plouf et sa fille squattent son bureau')

func _update_possible_impacts(choice):
	for stat in stats.keys():
		var impact = _get_choice_stat(choice, stat)
		var labels = {
			CRITERIA_SPEED: label_possible_impact_speed,
			CRITERIA_CREATIVITY: label_possible_impact_creativity,
			CRITERIA_FAMILLY_LIFE: label_possible_impact_familly_life,
			CRITERIA_POPULARITY: label_possible_impact_popularity,
		}
		impact =abs(impact)
		if impact == 0:
			continue
		var label = labels[stat]
		if impact <= 1:
			label.text = "▪"
		elif impact <= 2:
			label.text = "●"
		else:
			label.text = "⬤"
			

func _reset_possible_impacts():
	label_possible_impact_speed.text = ""
	label_possible_impact_creativity.text = ""
	label_possible_impact_familly_life.text = ""
	label_possible_impact_popularity.text = ""


func _display_next_phase_message(message:String):
	g_is_in_card_message = true
	print('Display message card: ', message)
	card_deck.display_next_phase_message(message)


func _switch_to_win_card(message:String, img_path : String):
	var img = load("res://images/"+img_path+".png")
	g_is_in_card_message = true
	print('Display message card: ', message)
	card_deck.display_win_message(message, img)


func _switch_to_gameover(message:String, swipe_message:String, img_path : String):
	var img = load("res://images/"+img_path+".png")
	g_is_in_card_message = true
	print('Display message card: ', message, 'with ', img_path, ' =>', img)
	card_deck.display_gameover_message(message, img)


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
	var did_change_phase = _apply_choice(direction)
	
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
	
	var is_huge_impact = current_problem['impact_multiplier'] == MULTIPLIER_HUGE_IMPACT
	var huge_warning_label = $LabelHugeImpactWarning
	if not is_huge_impact:
		huge_warning_label.visible = false
	else:
		huge_warning_label.visible = true
		huge_warning_label.visible_ratio = 0.0  # hide the text
		var tween = create_tween()
		tween.tween_property(huge_warning_label, "visible_ratio", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # and display it progressivly so the player can see it
	
	card_deck.set_card_data(character_texture,background_texture, choice_a_txt, choice_b_txt, "", false, is_huge_impact)

func on_card_preview(direction: String) -> void:
	if g_is_in_card_message:  # if we are just showing a message card, preview means nothing
		return
	if direction == "A":
		_update_possible_impacts("A")
	elif direction == "B":
		_update_possible_impacts("B")
	else:
		_reset_possible_impacts()


func on_global_message_read():
	print('on_global_message_read')
	g_is_in_card_message = false  # no more a message
	
	if g_game_over: # we did finish, just close the game currently
		OS.shell_open("https://www.youtube.com/@MonsieurPlouf")
		self.get_tree().quit()  # Bye bye
		return
	
	_display_problem_after_phase_change()
	return

func _on_help_1_pressed() -> void:
	$help_1.visible = false
	print('Help 1 was skip')
	$help_2.visible = true


func _on_help_2_pressed() -> void:
	$help_2.visible = false
	print('Help 2 was skip')
	$help_3.visible = true
	# note: during this tuto, the card deck is disabled to avoid the user to
	#       miss-click


func _on_help_3_pressed() -> void:
	$help_3.visible = false
	print('Help 3 was skip')
	# We can now enable the carddesk to move, so the user don't miss-click
	card_deck.enable_interaction()


############# Criteria particle
func _spawn_criteria_particle(choice: String, to_stat:String, impact:int):
	if impact == 0:
		return
	var nb_particle = abs(impact)
	var particle_img_path = 'particle_plus'
	if impact < 0:
		particle_img_path = 'particle_minus'
	var img = load('res://images/'+particle_img_path+'.png')
	var particle_emiter = $particle_emiter_a
	if choice == 'B':
		particle_emiter = $particle_emiter_b
	for i in nb_particle:
		var sprite = Sprite2D.new()
		sprite.texture = img
		sprite.scale = Vector2(0.3, 0.4)  # more thin that the basic sprite
		var random_offset = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		sprite.position = particle_emiter.position + random_offset
		$particles.add_child(sprite)
		
		var dests = {
			CRITERIA_FAMILLY_LIFE : $FamillyLife/ProgressSpriteBack.global_position,  # NOTE: global position and not jsut position
			CRITERIA_CREATIVITY : $Creativity/ProgressSpriteBack.global_position,
			CRITERIA_SPEED: $Speed/ProgressSpriteBack.global_position,
			CRITERIA_POPULARITY: $Popularity/ProgressSpriteBack.global_position,
		}
		
		var dest = dests.get(to_stat) + random_offset
		print('_spawn_criteria_particle', to_stat , ' =>', dest)
		var tween = create_tween()
		tween.tween_property(sprite, "position", dest, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(Callable(sprite, "queue_free"))  # don't forget to remove it after!
	

################ Impact message thread
# It's a panel that can display impact for the criteria, we are
# only displaying one at the same time, because it can be long.
# so display for 5s
func _launch_impact_message_thread():
	# Lance le timer de vérification
	var check_timer = Timer.new()
	check_timer.wait_time = 0.2
	check_timer.autostart = true
	check_timer.one_shot = false
	check_timer.timeout.connect(_process_next_impact_message)
	add_child(check_timer)
	
	
func stack_impact_message(msg: String):
	impacts_message_queue.append(msg)


func _process_next_impact_message():
	if impacts_message_is_displaying_message or impacts_message_queue.is_empty():
		return
	
	impacts_message_is_displaying_message = true
	var message = impacts_message_queue.pop_front()
	_display_impact_message(message)


func _display_impact_message(text: String):
	var tween = create_tween()
	impacts_message_label.text = text
	impacts_message_label.visible_ratio = 0.0
	impacts_message_label.visible = true
	
	# Affiche progressivement sur 0.3s
	tween.tween_property(impacts_message_label, "visible_ratio", 1.0, 0.3).set_trans(Tween.TRANS_LINEAR)
	
	# Attendre ensuite 5s puis effacer le texte
	tween.tween_interval(5.0)
	tween.tween_callback(Callable(self, "_on_impact_message_displayed"))


func _on_impact_message_displayed():
	var tween = create_tween()
	tween.tween_property(impacts_message_label, "visible_ratio", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	impacts_message_is_displaying_message = false
	
