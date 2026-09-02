extends CanvasLayer
## Race HUD: position, lap counter, lap times, speed, the countdown, and the
## end-of-race results panel. Builds its own controls so Main just instances it.

const FONT_BIG := 64
const FONT_MED := 30
const FONT_SMALL := 20

var race: RaceManager
var player: RaceVehicle

var _pos_label: Label
var _lap_label: Label
var _time_label: Label
var _best_label: Label
var _speed_label: Label
var _centre_label: Label
var _offtrack_label: Label
var _results: PanelContainer
var _results_text: Label
var _centre_fade := 0.0


func _ready() -> void:
	_pos_label = _make_label(FONT_MED, Color(1, 1, 1))
	_pos_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_pos_label.position = Vector2(28, 22)
	add_child(_pos_label)

	_lap_label = _make_label(FONT_MED, Color(1, 1, 1))
	_lap_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lap_label.position = Vector2(-210, 22)
	_lap_label.size = Vector2(180, 40)
	_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_lap_label)

	_time_label = _make_label(FONT_SMALL, Color(0.85, 0.95, 1))
	_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_label.position = Vector2(-210, 64)
	_time_label.size = Vector2(180, 26)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_time_label)

	_best_label = _make_label(FONT_SMALL, Color(0.7, 1.0, 0.7))
	_best_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_best_label.position = Vector2(-210, 90)
	_best_label.size = Vector2(180, 26)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_best_label)

	_speed_label = _make_label(FONT_BIG, Color(1, 1, 1))
	_speed_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_speed_label.position = Vector2(28, -110)
	add_child(_speed_label)

	_offtrack_label = _make_label(FONT_MED, Color(1, 0.75, 0.25))
	_offtrack_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_offtrack_label.position = Vector2(-140, -170)
	_offtrack_label.size = Vector2(280, 40)
	_offtrack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offtrack_label.text = "OFF TRACK"
	_offtrack_label.visible = false
	add_child(_offtrack_label)

	_centre_label = _make_label(120, Color(1, 1, 1))
	_centre_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_centre_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_centre_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_centre_label.text = ""
	add_child(_centre_label)

	_build_results()


func bind(race_manager: RaceManager, player_car: RaceVehicle) -> void:
	race = race_manager
	player = player_car
	race.countdown_tick.connect(_on_countdown)
	race.player_finished.connect(_on_finished)


func _make_label(size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, size / 8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_results() -> void:
	_results = PanelContainer.new()
	_results.set_anchors_preset(Control.PRESET_CENTER)
	_results.position = Vector2(-260, -170)
	_results.custom_minimum_size = Vector2(520, 340)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.92)
	style.border_color = Color(0.9, 0.9, 0.95, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	_results.add_theme_stylebox_override("panel", style)
	_results.visible = false

	_results_text = _make_label(FONT_MED, Color(1, 1, 1))
	_results_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results.add_child(_results_text)
	add_child(_results)


func _on_countdown(label: String) -> void:
	_centre_label.text = label
	_centre_fade = 1.0


func _on_finished(position: int, total_time: float) -> void:
	var suffix: String = ["st", "nd", "rd"][position - 1] if position <= 3 else "th"
	var lines := PackedStringArray()
	lines.append("FINISHED  %d%s" % [position, suffix])
	lines.append("")
	lines.append("Total    " + RaceManager.format_time(total_time))
	lines.append("Best lap " + RaceManager.format_time(player.best_lap))
	lines.append("")
	lines.append("— standings —")
	for i in range(race.standings().size()):
		var c := race.standings()[i]
		lines.append("%d. %s" % [i + 1, c.display_name])
	_results_text.text = "\n".join(lines)
	_results.visible = true


func _process(delta: float) -> void:
	if race == null or player == null:
		return

	_speed_label.text = "%d" % int(absf(player.get_speed_kmh()))
	_pos_label.text = "P%d/%d" % [race.player_position(), race.cars.size()]
	var lap := mini(player.laps_completed + 1, RaceManager.TOTAL_LAPS)
	_lap_label.text = "LAP %d/%d" % [lap, RaceManager.TOTAL_LAPS]
	_time_label.text = RaceManager.format_time(player.current_lap_time)
	_best_label.text = "BEST " + RaceManager.format_time(player.best_lap)
	_offtrack_label.visible = player.off_track and race.state == RaceManager.State.RACING

	if _centre_fade > 0.0:
		_centre_fade = maxf(0.0, _centre_fade - delta * 1.4)
		_centre_label.modulate.a = _centre_fade
		if _centre_fade <= 0.0:
			_centre_label.text = ""
