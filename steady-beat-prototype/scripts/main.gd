extends Control

@export_range(40.0, 200.0, 1.0) var bpm: float = 80.0
@export_range(1, 32, 1) var total_beats: int = 8

var round_start_time: float = 0.0
var target_interval: float = 0.0 
var tap_times: Array[float] = []
var last_visulized_beat: int = -1
var pulse_tween: Tween
var round_active: bool = false

#debugging 
var tap_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	target_interval = 60/bpm
	$TapButton.disabled = true
	round_start_time = Time.get_ticks_usec() / 1_000_000.0

	print("Tempo: ", bpm, " BPM")
	print("Target interval: ", target_interval, " seconds")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not round_active:
		return

	var current_time: float = Time.get_ticks_usec() / 1_000_000.0
	var elapsed_time: float = current_time - round_start_time
	var beat_index: int = floori(elapsed_time / target_interval)

	if beat_index >= total_beats:
		_finish_round()
		return

	if beat_index > last_visulized_beat:
		last_visulized_beat = beat_index
		_show_target_beat()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap_beat"):
		_record_tap()

func _on_tap_button_pressed() -> void:
	_record_tap()


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

func _show_target_beat() -> void:
	if pulse_tween:
		pulse_tween.kill()

	$TapButton.modulate = Color(1.0, 0.65, 0.2)

	pulse_tween = create_tween()
	pulse_tween.tween_property(
			$TapButton,
			"modulate",
			Color.WHITE,
			0.25
	)
	
func _on_start_button_pressed() -> void:
	tap_times.clear()
	round_start_time = Time.get_ticks_usec() / 1_000_000.0
	last_visulized_beat = -1
	round_active = true

	$TapButton.disabled = false
	$TapButton.text = "TAP"

	print("New round started")

func _finish_round() -> void:
	round_active = false
	$TapButton.disabled = true
	$TapButton.text = "ROUND COMPLETE!"

	print("Round complete")
	print("Recorded tap times ", tap_times)
