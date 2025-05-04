extends Node2D

@export var radius := 300.0 # Taille du mouvement global
@export var speed := 1.0    # Vitesse du déplacement
@export var offset := Vector2.ZERO # Décalage pour éviter la synchro entre logos

var t := 0.0
var screen_size := Vector2.ZERO
var center := Vector2.ZERO

func _ready():
	screen_size = Vector2(500, 1000)
	center = screen_size / 2.0
	t = randf() * TAU # phase aléatoire

func _process(delta):
	t += delta * speed
	var  x = sin(t * 1.2 + offset.x) * radius * 0.8 + sin(t * 2.5 + offset.x) * radius * 0.5
	var y = cos(t * 1.7 + offset.y) * radius * 0.8 + cos(t * 1.2 + offset.y) * radius * 0.6
	position = center + Vector2(x, y)
