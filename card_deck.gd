extends Node2D

signal choice_made(direction: String)
signal choice_preview(direction: String)

@export var max_drag_distance := 150.0
@export var max_rotation_degrees := 15.0
@export var reject_threshold := 100.0

@onready var current_card := $CurrentCard
@onready var next_card := $NextCard

var dragging := false
var drag_start_pos := Vector2.ZERO
var last_preview_direction := "" # do not spam preview signal

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
		
		handle_drag_preview(delta_x)


func handle_drag_preview(delta_x: float) -> void:
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


func reset_card():
	var tween = create_tween()
	tween.tween_property(current_card, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(current_card, "rotation_degrees", 0, 0.25).set_trans(Tween.TRANS_BACK)


func on_choice(direction: String):
	var target_x = sign(current_card.position.x) * 800
	var tween = create_tween()
	tween.tween_property(current_card, "position:x", target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_emit_choice").bind(direction))


func _emit_choice(direction):
	emit_signal("choice_made", direction)


func _resize_sprite_to_fit(sprite: Sprite2D) -> void:
	if not sprite.texture:
		return
	
	var max_width = 300.0
	var max_height = 200.0
	var tex_size = sprite.texture.get_size()

	var scale_factor = min(max_width / tex_size.x, max_height / tex_size.y)

	sprite.scale = Vector2(scale_factor, scale_factor)

# Méthode appelée depuis Main.gd
func set_card_images(current_image: Texture2D, next_image: Texture2D):
	var sprite_current := current_card.get_node("Sprite2D")	
	var sprite_next := next_card.get_node("Sprite2D")

	sprite_current.texture = current_image
	sprite_next.texture = next_image

	# Redimensionner les sprites
	_resize_sprite_to_fit(sprite_current)
	_resize_sprite_to_fit(sprite_next)

	current_card.position = Vector2.ZERO
	current_card.rotation_degrees = 0
	current_card.scale = Vector2.ONE
	current_card.modulate.a = 1.0

	next_card.position = Vector2.ZERO
	next_card.scale = Vector2(0.95, 0.95)
	next_card.modulate.a = 0.6
