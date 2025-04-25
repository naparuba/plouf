extends Control

@onready var card = $Card
@onready var texture_rect = $Card/TextureRect


# Taille fixe de la carte (par exemple 600x800)
const CARD_SIZE = Vector2(600, 800)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.size = CARD_SIZE
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func load_card_image(filename: String):
	var image_path = "res://images/" + filename  # adapte ton chemin ici
	var texture = load(image_path)
	print('Loading texture for card '+image_path)
	if texture and texture is Texture2D:
		texture_rect.texture = texture
	else:
		print("⚠ Impossible de charger :", image_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
