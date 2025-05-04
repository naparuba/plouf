extends Node2D

var call_count := 0
const MAX_CALLS := 5
var active := false

var timer: Timer

var g_parent = null

func _ready():
	# Crée dynamiquement un Timer si besoin
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func set_parent(parent):
	print('RUSH: get new parent ',parent)
	g_parent = parent

func start():
	self.visible = true
	call_count = 0
	active = true
	_print_remaining(MAX_CALLS)  # print the first one without wait for the first sleep
	timer.start()

func stop():
	self.visible = false
	active = false
	timer.stop()

func _print_remaining(t):
	$RichTextLabel.text = "Rush: Plus que [b][color=orange]%d secondes![/color][/b]" % t

func _on_timer_timeout():
	if not active:
		return

	call_count += 1
	print("Appel n°%d" % call_count)
	$RichTextLabel.text = "Plus que Appel n°%d" % call_count
	
	var remaining = MAX_CALLS - call_count
	if remaining > 0:
		_print_remaining(remaining)
		timer.start()  # relance pour la seconde suivante
	else:
		$RichTextLabel.text = "Rush: [b][color=red]Temps écoulé[/color][/b]"
		active = false
		print('CALLBACK FOR TIMEOUT')
		print('Parent: ', g_parent)
		g_parent.callback_rush_timeout()
