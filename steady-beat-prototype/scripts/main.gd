extends Control

@export_group("Timesignature")
@export_range(40.0, 200.0, 1.0) var bpm: float = 80.0
@export_range(1, 8, 1) var count_in_beats: int = 4
@export_range(1, 12, 1) var beats_per_measure: int = 4
@export_range(1, 32, 1) var total_beats: int = 8
@export_range(0.05, 0.50, 0.01) var hit_window_seconds: float = 0.20

@export_group("Metronome Volume")
@export_range(-40.0, 0.0, 1.0) var count_in_volume_db: float = -3.0
@export_range(-40.0, 0.0, 1.0) var quiet_cue_volume_db: float = -20.0
@export_range(-40.0, 0.0, 1.0) var accent_volume_db: float = -3.0
@export_range(-40.0, 0.0, 1.0) var regular_volume_db: float = -8.0

var round_start_time: float = 0.0
var target_interval: float = 0.0 
var tap_times: Array[float] = []
var last_visualized_beat: int = -1
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
	
	var final_beat_time: float = (
			count_in_beats * target_interval
		+ (total_beats - 1) * target_interval
	)
	var response_window: float = minf(
		hit_window_seconds,
		target_interval * 0.5
	)
	var round_end_time: float = final_beat_time + response_window

	if elapsed_time >= round_end_time:
		_finish_round()
		return

	if beat_index > last_visualized_beat:
		last_visualized_beat = beat_index
		_show_target_beat(beat_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap_beat"):
		_record_tap()

func _on_tap_button_pressed() -> void:
	_record_tap()


func _record_tap() -> void:
	if not round_active:
		return

	var current_time: float = Time.get_ticks_usec() / 1_000_000.0
	var round_time: float = current_time - round_start_time
	var count_in_duration: float = count_in_beats * target_interval
	var scored_time: float = round_time - count_in_duration
	var final_scored_beat_time: float = (total_beats - 1) * target_interval
	var response_window: float = minf(
		hit_window_seconds,
		target_interval * 0.5
	)

	if scored_time < 0.0:
		return

	if scored_time > final_scored_beat_time + response_window:
		return

	tap_times.append(scored_time)
	$TapButton.text = "TAPS: %d" % tap_times.size()

	print("Scored tap recorded at ", scored_time, " seconds")

	if tap_times.size() > 1:
		var previous_tap: float = tap_times[-2]
		var tap_interval: float = scored_time - previous_tap
		var interval_error: float = absf(tap_interval - target_interval)

		print("Time since previous tap: ", snappedf(tap_interval, 0.001), " seconds")
		print("Difference from target: ", snappedf(interval_error, 0.001), " seconds")

func _show_target_beat(beat_index: int) -> void:
	if beat_index < count_in_beats:
		var beats_remaining: int = count_in_beats - beat_index
		$TapButton.disabled = true
		$TapButton.text = "GET READY: %d" % beats_remaining

		if beat_index == count_in_beats - 1:
			$MetronomePlayer.volume_db = quiet_cue_volume_db
		else:
			$MetronomePlayer.volume_db = count_in_volume_db
	
	else:
		var scored_beat_index: int = beat_index - count_in_beats
		var beat_in_measure: int = scored_beat_index % beats_per_measure

		if scored_beat_index == 0:
			$TapButton.disabled = false
			$TapButton.text = "TAP"
		if beat_in_measure == 0:
			$MetronomePlayer.volume_db = accent_volume_db
		else:
			$MetronomePlayer.volume_db = regular_volume_db

	$MetronomePlayer.play()

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
	last_visualized_beat = -1
	round_active = true

	$TapButton.disabled = true
	$TapButton.text = "GET READY"

	print("New round started")

func _finish_round() -> void:
	round_active = false
	$TapButton.disabled = true
	$TapButton.text = "ROUND COMPLETE!"

	print("Round complete")
	print("Recorded tap times ", tap_times)
