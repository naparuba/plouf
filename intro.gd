extends Control


# Intro
@onready var intro_player = $player
@onready var audio_player = $audio_player


######### Intro:
func launch_intro():
	print(' LAUNCH INTRO')
	self.visible = true
	audio_player.stream = load("res://sounds/intro.ogg")
	audio_player.play()
	intro_player.play("intro")
	await intro_player.animation_finished
	print('INTRO FINISH')
	self.visible = false
	return audio_player.finished
