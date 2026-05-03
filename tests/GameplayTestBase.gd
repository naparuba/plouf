extends GutTest

# Phase IDs in order (matches phases.json)
const PHASES = [
	"CHOOSE_CHRONIQUE_GAME",   # 0
	"PLAY_CHRONIQUE_GAME",     # 1
	"WRITE_CHRONIQUE",         # 2
	"REGISTER_VOICE",          # 3
	"DRAW_CHRONIQUE",          # 4
	"ANIMATE_CHRONIQUE",       # 5
	"MOUNT_CHRONIQUE_VIDEO",   # 6
	"UPLOAD_CHRONIQUE_VIDEO",  # 7
	"ANSWER_CHRONIQUE_COMMENTS", # 8
	"STREAM_POST_CHRONIQUE",   # 9
]

const STAT_INIT = 20
const MAX_STAT = 40
const KILL_LOW = -(STAT_INIT + 1)   # 20 + (-21) = -1 < 0
const KILL_HIGH = (MAX_STAT - STAT_INIT + 1)  # 20 + 21 = 41 > 40


# Build a minimal problem card. All stat impacts default to 0.
# Pass overrides to set specific fields, e.g. {"creativity_a": -21}
func _make_card(id: String, phase: String, overrides: Dictionary = {}) -> Dictionary:
	var card = {
		"problem_id": id,
		"phase_id_dep": phase,
		"problem_description": "Test " + id,
		"title": "Test",
		"choice_a": "Oui",
		"choice_b": "Non",
		"outcome_a": "OK",
		"outcome_b": "OK",
		"sound_a": "",
		"sound_b": "",
		"character_img_id": "PLOUF",
		"background_img_id": "FADED",
		"creativity_a": 0, "creativity_b": 0,
		"familly_life_a": 0, "familly_life_b": 0,
		"popularity_a": 0, "popularity_b": 0,
		"speed_a": 0, "speed_b": 0,
		"impact_multiplier": 1,
	}
	for key in overrides:
		card[key] = overrides[key]
	return card


# Instantiate Main.tscn with test flags set before _ready() fires.
# start_phase: if >= 0, starts at that phase index (skips earlier phases)
func _make_main(save_override: Dictionary, test_deck: Dictionary = {}, start_phase: int = 0) -> Node:
	var main = preload("res://Main.tscn").instantiate()
	main.DEBUG_DISABLE_INTRO = true
	main.DEBUG_SAVE_OVERRIDE = save_override
	main.DEBUG_START_PHASE_INDEX = start_phase
	if not test_deck.is_empty():
		main.DEBUG_TEST_DECK = test_deck
	add_child_autofree(main)
	await wait_seconds(2.0)  # wait for _ready() + stack_cards animation to complete
	return main


# Call on_swipe_choice directly, bypassing UI input so tests don't depend on animations
func _swipe(main: Node, direction: String = "A") -> void:
	main.on_swipe_choice(direction)
	await wait_frames(3)
