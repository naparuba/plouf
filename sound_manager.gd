extends Node

@onready var active_players: Array[AudioStreamPlayer] = []
var is_active = true

var volume_db: float = 0.0:
	set = set_volume_db


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


# Joue un son (optionnel: volume, auto-free)
func play_sound(path: String, volume: float = 0.0, auto_free: bool = true, random_pitch:bool = false) -> AudioStreamPlayer:
	if not self.is_active:  # sorry, the sound is just cut
		return
	var stream := load("res://sounds/"+path+".ogg")
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	if random_pitch:  # if asking, put a random pitch to make sounds sounds a bit random, just a bit
		player.pitch_scale = randf_range(0.96, 1.04)
	add_child(player)
	player.play()

	if auto_free:
		player.finished.connect(_on_player_finished.bind(player))
		
	active_players.append(player)
	return player


func play_voice(path: String):
	var sound_file = "res://sounds/voices/"+path+".ogg"
	if not ResourceLoader.exists(sound_file):  # !! ResourceLoader and not FileAccess because we are using pck
		print('ERROR: the sound ', sound_file, ' is missing !!')
		return #path = 'JE-DETEST-CA'
	self.play_sound('voices/'+path, 0.0, true, true)  # random_pitch=true


func stop_all_sounds() -> void:
	if not is_active:
		return
	is_active = false
	_fade_out_all_sounds()


# Stoppe tous les sons en cours, mais dans 1s le temps que tout se lance
func _fade_out_all_sounds() -> void:
	await get_tree().create_timer(1.0).timeout  # Délai de 1s

	for player in active_players:
		if is_instance_valid(player):
			var tween := create_tween()
			tween.tween_property(player, "volume_db", -80.0, 1.0)
			tween.tween_callback(Callable(player, "stop"))
			tween.tween_callback(Callable(player, "queue_free"))

	active_players.clear()
	self.is_active = false
	
	
func reactivate_sounds():
	self.is_active = true


# Callback quand un son s'arrête
func _on_player_finished(player: AudioStreamPlayer) -> void:
	if active_players.has(player):
		active_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()


# Réglage du volume global
func set_volume_db(value: float) -> void:
	volume_db = value
	for player in active_players:
		if is_instance_valid(player):
			player.volume_db = value
