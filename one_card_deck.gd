extends Sprite2D


var to_texture_character = null
var to_texture_background = null
var parent = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('I am a card of a deck')
	#flip_card()

func set_parent(p):
	if p:
		parent = p

func flip_card(texture_character: Texture2D, texture_background: Texture2D):
	self.to_texture_character = texture_character
	self.to_texture_background = texture_background
	var tween := create_tween()

	# Étape 1 : réduire scale.x à 0 (effet de repli)
	tween.tween_property(self, "scale:x", 0.0, 0.2)

	# Étape 2 : callback au milieu du flip (pour changer visuel si besoin)
	tween.tween_callback(Callable(self, "_on_half_flip"))

	# Étape 3 : remettre scale.x à 1.0 (retour de l'autre côté)
	tween.tween_property(self, "scale:x", 1.0, 0.2)

	# Étape 4 : callback à la fin
	tween.tween_callback(Callable(self, "_on_flip_done"))

func _on_half_flip():
	print("one-card:: flip texture")
	self.texture = to_texture_character
	self.material.set_shader_parameter('backTexture', to_texture_background)
	

func _on_flip_done():
	print("one-card:: Flip terminé !")
	if self.parent:
		self.parent.flip_top_deck_card_done()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
