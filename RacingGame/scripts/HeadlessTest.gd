extends Node3D
## Regression test (not shipped). Loads the real Main scene and drives the
## player car around the circuit *through the real keyboard input path* - the
## test decides where to steer from the track geometry, then presses the same
## actions a human would, so the player control path is genuinely exercised
## rather than bypassed.
##
## Asserts the things that have actually broken during development: the car
## moving under power, staying upright and finite, not launching into the air,
## not falling through the world (the road was visual-only with no collider
## once), the AI field circulating instead of beaching itself, and laps
## actually being counted for both the player and the AI.

const TOTAL_FRAMES := 4200  # 70s at 60Hz

var main: Node3D
var frame := 0
var max_h := 0.0
var min_h := 999.0
var top_speed := 0.0


func _ready() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	print("TEST: track length=%.0fm samples=%d field=%d" % [
		main.track.total_length, main.track.sample_count(), main.cars.size()])


func _physics_process(_delta: float) -> void:
	frame += 1
	var player: RaceVehicle = main.player
	var pos := player.global_position
	max_h = maxf(max_h, pos.y)
	min_h = minf(min_h, pos.y)
	top_speed = maxf(top_speed, player.get_speed_kmh())

	AutoDriver.drive(player, main.track)

	if frame == TOTAL_FRAMES:
		_report(player)


func _report(player: RaceVehicle) -> void:
	var ok := true
	var pos := player.global_position
	var finite := is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z)
	var upright := player.global_transform.basis.y.dot(Vector3.UP) > 0.5

	print("TEST: player laps=%d best=%s top_speed=%.0f km/h" % [
		player.laps_completed, RaceManager.format_time(player.best_lap), top_speed])
	print("TEST: height range=[%.2f, %.2f] finite=%s upright=%s" % [min_h, max_h, finite, upright])
	for c in main.cars:
		print("TEST:   %-6s laps=%d progress=%.2f off_track=%s" % [
			c.display_name, c.laps_completed, c.track_progress(), c.off_track])

	if not finite:
		ok = false; print("TEST: FAIL non-finite position")
	if not upright:
		ok = false; print("TEST: FAIL car not upright")
	if top_speed < 60.0:
		ok = false; print("TEST: FAIL never reached a racing speed (%.0f km/h)" % top_speed)
	if max_h > 3.0:
		ok = false; print("TEST: FAIL car launched into the air (max y %.2f)" % max_h)
	if min_h < -2.0:
		ok = false; print("TEST: FAIL car fell through the world (min y %.1f)" % min_h)
	if player.laps_completed < 1:
		ok = false; print("TEST: FAIL player completed no laps")
	var ai_laps := 0
	for c in main.cars:
		if c != player:
			ai_laps += c.laps_completed
	if ai_laps < 3:
		ok = false; print("TEST: FAIL AI field barely moved (total AI laps %d)" % ai_laps)

	print("TEST: RESULT=", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
