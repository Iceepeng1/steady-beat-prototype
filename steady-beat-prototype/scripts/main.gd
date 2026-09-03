extends Control
var tap_count: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap_beat"):
		_record_tap()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tap_button_pressed() -> void:
	_record_tap()
	

func _record_tap() -> void:
	tap_count += 1
	$TapButton.text = "TAPS: %d" % tap_count
