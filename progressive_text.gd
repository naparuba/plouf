extends Label

@export var total_time: float = 0.3 #3.0 # Durée totale d'affichage en secondes

var _full_text: String = ""
var _timer: float = 0.0
var _active: bool = false

var _is_slow_mode = false

func _ready() -> void:
	text = ""

func _process(delta: float) -> void:
	if not _active:
		return

	_timer += delta
	var ratio: float = clamp(_timer / total_time, 0.0, 1.0)
	var char_count: int = int(floor(ratio * _full_text.length()))
	text = ""
	if _is_slow_mode:
		text = "(Plouf va trop vite, il voit tout au ralentit!)\n"
	text = text + _full_text.substr(0, char_count)
		

	if ratio >= 1.0:
		text = _full_text
		_active = false

func set_fast_mode():
	_is_slow_mode = false
	total_time = 0.5
	
func set_slow_mode():
	total_time = 5
	_is_slow_mode = true

func reveal_text(new_text: String) -> void:
	_full_text = new_text
	_timer = 0.0
	text = ""
	_active = true
