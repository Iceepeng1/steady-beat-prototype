extends Control

@export_range(40.0, 200.0, 1.0) var bpm: float = 80.0

var round_start_time: float = 0.0
var target_interval: float = 0.0 
var tap_times: Array[float] = []

#debugging 
var tap_count: int = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	target_interval = 60/bpm
	round_start_time = Time.get_ticks_usec() / 1_000_000.0

	print("Tempo: ", bpm, " BPM")
	print("Target interval: ", target_interval, " seconds")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap_beat"):
		_record_tap()

func _on_tap_button_pressed() -> void:
	_record_tap()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	

func _record_tap() -> void:
	var current_time: float = Time.get_ticks_usec() / 1_000_000.0
	var tap_time: float = current_time - round_start_time

	tap_times.append(tap_time)
	$TapButton.text="TAPS: %d" % tap_times.size()

	print("Tap recorded at ", tap_time, " seconds")

	if tap_times.size() > 1:
		var previous_tap: float = tap_times[-2]
		var tap_interval: float = tap_time - previous_tap
		var interval_error: float = absf(tap_interval- target_interval)

		print("Time since previous tap: ", snappedf(tap_interval, 0.001), " seconds")
		print("Difference from target: ", snappedf(interval_error, 0.001), " seconds")

	tap_count += 1
	$TapButton.text = "TAPS: %d" % tap_count
