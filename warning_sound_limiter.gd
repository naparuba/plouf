# WarningSoundLimiter.gd
extends Node

class_name WarningSoundLimiter

var last_call := 0
var delay_ms := 1000  # 1s: délai minimal entre deux warning, pour ne pas spammer

func play_warning_sound():
	var now := Time.get_ticks_msec()
	if now - last_call < delay_ms:
		return
	last_call = now
	SoundManager.play_sound('warning', -12)  # -12db => /3
