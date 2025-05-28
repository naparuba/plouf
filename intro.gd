extends Control


# Intro
@onready var intro_player = $player
@onready var audio_player = $audio_player

signal intro_ended

# Skip button : hold for 1.0s for skip
@onready var skip_bar = $skip  # ou autre chemin
var is_skipping := false
var skip_hold_time := 1.0  # durée en secondes
var skip_timer := 0.0

# Called at the end of the animation by the player
func _on_intro_finished():
	emit_signal("intro_ended")

######### Intro:
func launch_intro():
	print(' LAUNCH INTRO')
	self.visible = true
	audio_player.stream = load("res://sounds/intro.ogg")
	audio_player.play()
	intro_player.play("intro")
	await intro_ended   #  can be both from a skip or with a real animation finish
	print('INTRO FINISH')
	self.visible = false
	return audio_player.finished  #is raised even if skip


func _process(delta):
	if is_skipping:
		skip_timer += delta
		skip_bar.value = skip_timer / skip_hold_time * 100.0
		if skip_timer >= skip_hold_time:
			_end_intro()

func _input(event):
	if event is InputEventMouseButton or event is InputEventKey:
		if event.pressed:
			_start_skip()
		else:
			_cancel_skip()


func _start_skip():
	is_skipping = true
	skip_timer = 0.0
	skip_bar.value = 0.0

func _cancel_skip():
	is_skipping = false
	skip_timer = 0.0
	skip_bar.value = 0.0

func _end_intro():
	print('SKIP INTRO')
	self.visible = false
	audio_player.stop()
	intro_player.stop()
	is_skipping = false
	emit_signal("intro_ended")
