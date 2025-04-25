extends Node2D

@export var max_drag_distance := 150.0
@export var max_rotation_degrees := 15.0
@export var reject_threshold := 100.0

@onready var current_card := $CurrentCard
@onready var next_card := $NextCard

var dragging := false
var drag_start_pos := Vector2.ZERO

var deck := []  # Liste de chemins d'images ou objets de données
var current_index := 0

func _ready():
	deck = [
		"res://images/PLOUF.png",
		"res://images/EDITOR.png",
		"res://images/MUFFIN.png",
	]
	load_card(current_card, deck[current_index])
	load_card(next_card, deck[(current_index + 1) % deck.size()])
	next_card.position = Vector2.ZERO
	next_card.scale = Vector2(0.95, 0.95)
	next_card.modulate.a = 0.6


func load_card(card_node: Node2D, image_path: String):
	var sprite := card_node.get_node("Sprite2D")
	sprite.texture = load(image_path)
	
	# Ajustement auto taille max 90% de l’écran sans déformation
	#var target_size = get_viewport_rect().size * 0.9
	var target_size = Vector2(100, 150)
	var img_size = sprite.texture.get_size()
	var scale_factor = min(target_size.x / img_size.x, target_size.y / img_size.y)
	card_node.scale = Vector2.ONE * scale_factor


func _input(event):
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

		current_card.position.x = delta_x
		current_card.rotation_degrees = (delta_x / max_drag_distance) * max_rotation_degrees


func handle_release():
	var delta_x = current_card.position.x
	if abs(delta_x) > reject_threshold:
		if delta_x > 0:
			on_choice("B")
		else:
			on_choice("A")
	else:
		reset_card()


func reset_card():
	var tween = create_tween()
	tween.tween_property(current_card, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(current_card, "rotation_degrees", 0, 0.25).set_trans(Tween.TRANS_BACK)


func on_choice(direction: String):
	print("🎯 Choix :", direction)

	var target_x = sign(current_card.position.x) * 800  # Rejet vers la droite ou gauche
	var tween = create_tween()
	tween.tween_property(current_card, "position:x", target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "next_card_transition"))


func next_card_transition():
	# Swap current / next
	current_index = (current_index + 1) % deck.size()
	var new_next = deck[(current_index + 1) % deck.size()]

	# Recharger cartes
	load_card(current_card, deck[current_index])
	load_card(next_card, new_next)

	# Reset visuel
	current_card.position = Vector2.ZERO
	current_card.rotation_degrees = 0
	current_card.scale = Vector2.ONE
	current_card.modulate.a = 1.0

	# Empile la nouvelle "next card"
	next_card.position = Vector2.ZERO
	next_card.scale = Vector2(0.95, 0.95)
	next_card.modulate.a = 0.6
