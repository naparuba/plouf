extends Node2D

signal choice_made(direction: String)
signal choice_preview(direction: String)

@export var max_drag_distance := 75.0
@export var max_rotation_degrees := 15.0
@export var reject_threshold := 50.0

@onready var current_card := $CurrentCard

var dragging := false
var drag_start_pos := Vector2.ZERO
var last_preview_direction := "" # do not spam preview signal

@onready var choice_overlay = $CurrentCard/ChoiceOverlay
@onready var polygon  = $CurrentCard/ChoiceOverlay/Polygon
@onready var choice_label = $CurrentCard/ChoiceOverlay/Label

@onready var sprite_2d : Sprite2D = $CurrentCard/Sprite2D


var current_character_texture = null
var current_background_texture = null
var current_choice_a_txt = ''
var current_choice_b_txt = ''

var are_interaction_enabled = false

func _ready() -> void:
	# Overlay
	choice_overlay.visible = false
	choice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_overlay.anchor_left = 0.0
	choice_overlay.anchor_top = 0.0
	choice_overlay.anchor_right = 1.0
	choice_overlay.anchor_bottom = 0.0
	choice_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_overlay.size_flags_vertical = Control.SIZE_FILL
	choice_overlay.custom_minimum_size = Vector2(0, 50)  # Hauteur du bandeau
	
	# Label for text A/B
	choice_label.text = ""
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	choice_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	choice_label.anchor_left = 0.0
	choice_label.anchor_top = 0.0
	choice_label.anchor_right = 1.0
	choice_label.anchor_bottom = 1.0
	choice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Give myself to rush so to can callback myself
	$Rush.set_parent(self)
	
	# Let the deck know self so it can callback us
	_generate_deck_cards(3)

func _input(event):
	if not self.are_interaction_enabled:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start_pos = get_global_mouse_position()
			else:
				dragging = false
				handle_release()
	elif event is InputEventMouseMotion and dragging:
		var delta_x = get_global_mouse_position().x - drag_start_pos.x
		delta_x = clamp(delta_x, -max_drag_distance, max_drag_distance)
		
		# We are moving faster than the real move, like in the origina title
		delta_x *= 2

		current_card.position.x = delta_x
		current_card.rotation_degrees = (delta_x / max_drag_distance) * max_rotation_degrees
		
		_update_choice_overlay(delta_x)
		
		_handle_drag_preview(delta_x)


func _generate_deck_cards(count:int):
	var deck = $Deck
	# First clean Deck object to be sure it's void
	for child in deck.get_children():
		deck.remove_child(child)
		child.queue_free()
		
	# Charge la texture et le shader
	var tex = load("res://images/FADED.png")
	var shader = load("res://shaders/card_in_deck.gdshader")
	var script := load("res://one_card_deck.gd")

	# Crée les sprites en pile
	for i in count:
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.set_script(script)
		sprite.set_parent(self)  # so it can callback us when flip done
		
		# Position légèrement décalée pour l'effet "tas"
		sprite.position = Vector2(-(count-i-1) * 5, (count-i-1) * 5)  # décale chaque carte
		
		# Matériau avec shader
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("corner_radius_px", 20)
		sprite.material = mat
		
		deck.add_child(sprite)
	
func __get_top_deck_card():
	var deck = $Deck
	var card = null
	# First clean Deck object to be sure it's void
	for c in deck.get_children():
		card = c
	return card
	
func _flip_top_deck_card():
	var deck = $Deck
	var card = self.__get_top_deck_card()
	
	card.flip_card(current_character_texture, current_background_texture)
	
# the top deck card is flip, we can display the interactive one, and drop the top desk card
func flip_top_deck_card_done():  
	$CurrentCard.visible = true
	
	# drop the top card: the last one
	var card = __get_top_deck_card()
	if card:
		card.queue_free()
	
	
# At startup, during the tuto, we are disabling the interaction so the user don't skip tuto without reading
func enable_interaction():
	self.are_interaction_enabled = true
	

func _update_overlay_size():
	var sprite: Sprite2D = current_card.get_node("Sprite2D")
	if not sprite.texture:
		return
	
	var size = sprite.texture.get_size() * sprite.scale  # Taille après scaling
	var width = size.x
	var height = 50.0  # Hauteur du bandeau
	
	choice_overlay.position = Vector2(-width/2, -size.y/2)  # Coller en haut du sprite

	# Générer les points du trapèze de base (rectangle au départ)
	var points = [
		Vector2(0, 0),          # Haut gauche
		Vector2(width, 0),      # Haut droite
		Vector2(width, height), # Bas droite
		Vector2(0, height)      # Bas gauche
	]
	
	polygon.polygon = points
	polygon.color = Color(0, 0, 0, 0.8)  # Noir semi-transparent

	choice_label.position = Vector2(0, 0)
	choice_label.size = Vector2(width, height)

func _update_choice_overlay(delta_x: float) -> void:
	var threshold_show = 20.0  # Début d'apparition

	if abs(delta_x) > threshold_show:
		choice_overlay.visible = true
		choice_label.text = current_choice_b_txt if delta_x > 0 else current_choice_a_txt
				
		# Alpha is max at the middle of the max drag so it can be read early but still with a progressive look
		var alpha = clamp(2 * abs(delta_x) / max_drag_distance, 0.0, 1.0)
		choice_overlay.modulate.a = alpha
		
		# Let the label be horizontal
		choice_label.rotation_degrees = -current_card.rotation_degrees

		# Déformer le bas du polygone pour rester horizontal
		var sprite: Sprite2D = current_card.get_node("Sprite2D")
		var size = Vector2(100, 100)
		if sprite.texture:
			size = sprite.texture.get_size() * sprite.scale
		var width = size.x
		var height = 50.0
		
		var rotation_rad = deg_to_rad(current_card.rotation_degrees)
		var offset = tan(rotation_rad) * width
		var points = []
		if delta_x > 0:  # B => right
			# Points mis à jour
			points = [
				Vector2(0, 10),                # Haut gauche, rounded
				Vector2(10, 0),
				
				Vector2(width-10, 0),            # Haut droite rounded
				Vector2(width, 10),          
				
				Vector2(width , height), # Bas droite décalé
				Vector2(0, height + offset)         # Bas gauche décalé
			]
			
			# Update label on the good place
			choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice_label.position = Vector2(0, offset)  # En haut à droite
			choice_label.size = Vector2(width-10, height-20)
			
		else: # A => left
			points = [
				Vector2(0, 10),                # Haut gauche rounded
				Vector2(10, 0),
				
				Vector2(width-10, 0),            # Haut droite
				Vector2(width, 10),
				
				Vector2(width , height - offset), # Bas droite décalé
				Vector2(0, height)         # Bas gauche décalé
			]
			choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			choice_label.position = Vector2(10, 0)  # En haut à gauche
			choice_label.size = Vector2(width-20, height - 20)  #TODO: BUG HERE, do not offset?
		
		polygon.polygon = points
	else:
		choice_overlay.visible = false

func _handle_drag_preview(delta_x: float) -> void:
	var new_direction = ""
	if abs(delta_x) > reject_threshold * 0.5: # 🔥 Seuil pour commencer à preview
		new_direction = "B" if delta_x > 0 else "A"

	if new_direction != last_preview_direction:
		last_preview_direction = new_direction
		if new_direction != "":
			emit_signal("choice_preview", new_direction)
		else:
			emit_signal("choice_preview", "none") # 🔥 aucun choix clair (optionnel)

func handle_release():
	var delta_x = current_card.position.x
	if abs(delta_x) > reject_threshold:
		var direction = "B" if delta_x > 0 else "A"
		on_choice(direction)
	else:
		reset_card()
	choice_overlay.visible = false


func reset_card():
	var tween = create_tween()
	# Parallel: both tween are in the same time
	tween.parallel().tween_property(current_card, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(current_card, "rotation_degrees", 0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func on_choice(direction: String):
		# Calculer la direction à partir de la position de la carte
	var target_x = current_card.position.x
	var target_y = 600  # Ajouter un mouvement vers le bas pour donner l'effet de chute
	var rotation_angle = 120  # La carte tournera de 60 degrés
	
	# Based on direction, we must rotate in a oposite way
	if direction == "A":
		rotation_angle *= -1

	# Créer une référence au shader
	var sprite: Sprite2D = current_card.get_node("Sprite2D")
	var shader_material = sprite.material as ShaderMaterial


	# Créer un tween pour animer la carte
	var tween = create_tween()
	
	# Burning effect, stop at the middle, but quickly
	tween.parallel().tween_property(sprite_2d.material, 'shader_parameter/radius', 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# To the bottom and rotating, like a droping card
	tween.parallel().tween_property(current_card, "position", Vector2(target_x, target_y), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(current_card, "rotation_degrees", rotation_angle, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Callback pour signaler que le choix a été effectué
	tween.tween_callback(Callable(self, "_emit_choice").bind(direction))
	

func _emit_choice(direction):
	emit_signal("choice_made", direction)


func _resize_sprite_to_fit(sprite: Sprite2D) -> void:
	if not sprite.texture:
		return
	
	var max_width = 300.0
	var max_height = 300.0
	var tex_size = sprite.texture.get_size()

	var scale_factor = min(max_width / tex_size.x, max_height / tex_size.y)

	sprite.scale = Vector2(scale_factor, scale_factor)


# Main call from Main.gd
func set_card_data(character_texture: Texture2D, background_texture:Texture2D, choice_a_txt: String, choice_b_txt: String, global_message: String, is_ending_message: bool):
	var sprite_current := current_card.get_node("Sprite2D")
	
	current_card.visible = false  # will be shown when top card flip will be done
	
	if not is_ending_message:
		$CurrentCard/GlobalMessage.text = global_message
	else:
		$CurrentCard/GlobalMessage.text = ""
		$CurrentCard/EndingMessage.text = global_message
	
	print('CARD_DECK:: set_card_images:: '+ choice_a_txt)
	
	if character_texture != null:
		sprite_current.texture = character_texture
	else:  # message card, don't care about sprite_texture
		sprite_current.texture = background_texture
	
	current_character_texture = character_texture
	current_background_texture = background_texture
	
	print('Give backtexture ', background_texture)
	sprite_2d.material.set_shader_parameter('backTexture', background_texture)
	
	# Reset the burning shader
	sprite_2d.material.set_shader_parameter('radius', 0.0)
	# Make the bruning starting point random
	sprite_2d.material.set_shader_parameter('position', Vector2(randf(), randf()))
	
	# Redimensionner les sprites
	_resize_sprite_to_fit(sprite_current)
	
	_update_overlay_size()	# Let the choice overlay be the same size

	current_card.position = Vector2.ZERO
	current_card.rotation_degrees = 0
	current_card.scale = Vector2.ONE
	current_card.modulate.a = 1.0
	
	# Update text
	current_choice_a_txt = choice_a_txt
	current_choice_b_txt = choice_b_txt
	
	_generate_deck_cards(3)
	
	_flip_top_deck_card()


### Impacts:
func set_grey():
	print('set_grey')
	var tween = create_tween()
	tween.parallel().tween_property(sprite_2d.material, 'shader_parameter/grayness_strength', 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
func unset_grey():
	print('unset_grey')
	var tween = create_tween()
	tween.parallel().tween_property(sprite_2d.material, 'shader_parameter/grayness_strength', 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func set_text_wobby():
	print('set_text_wobby')
	var tween = create_tween()
	tween.parallel().tween_property(choice_label.material, 'shader_parameter/deform_strength', 0.5, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
func unset_text_wobby():
	print('unset_text_wobby')
	var tween = create_tween()
	tween.parallel().tween_property(choice_label.material, 'shader_parameter/deform_strength', 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
func set_text_raw():
	print('set_text_raw')
	var tween = create_tween()
	tween.parallel().tween_property(choice_label.material, 'shader_parameter/pixel_size', 150, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
func unset_text_raw():
	print('unset_text_raw')
	var tween = create_tween()
	tween.parallel().tween_property(choice_label.material, 'shader_parameter/pixel_size', 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
func set_text_blink():
	print('set_text_blink')
	#choice_label.material.set_shader_parameter('recurring_hide', true)

func unset_text_blink():
	print('unset_text_blink')
	#choice_label.material.set_shader_parameter('recurring_hide', false)

func set_rush():
	$Rush.start()
	
func unset_rush():
	$Rush.stop()

func callback_rush_timeout():
	current_choice_a_txt = 'RUSH! Plus le temps de réfléchir!'
	current_choice_b_txt = current_choice_a_txt
	choice_label.text = current_choice_a_txt
