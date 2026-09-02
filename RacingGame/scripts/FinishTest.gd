extends Node3D
## Regression test (not shipped): drives a full 3-lap race to completion and
## checks the finish flow actually fires - lap counting all the way to the
## chequered flag, the player_finished signal, a sane finishing position, and
## a best-lap time being recorded. Everything up to this point only ever tested
## the first lap.

const FRAME_CAP := 12000  # ~200s of sim; a clean 3-lap race is ~120s

var main: Node3D
var frame := 0
var finished_pos := -1
var finished_time := 0.0
var lap_events := 0


func _ready() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	main.race.player_finished.connect(_on_finished)


func _on_finished(position: int, total_time: float) -> void:
	finished_pos = position
	finished_time = total_time


func _physics_process(_delta: float) -> void:
	frame += 1
	AutoDriver.drive(main.player, main.track)

	if finished_pos > 0 or frame >= FRAME_CAP:
		_report()


func _report() -> void:
	var ok := true
	var p: RaceVehicle = main.player
	print("TEST: finished_pos=%d total=%s best_lap=%s laps=%d frames=%d" % [
		finished_pos, RaceManager.format_time(finished_time),
		RaceManager.format_time(p.best_lap), p.laps_completed, frame])
	for c in main.race.standings():
		print("TEST:   %-6s laps=%d finished=%s time=%s" % [
			c.display_name, c.laps_completed, c.finished,
			RaceManager.format_time(c.finish_time)])

	if finished_pos < 1:
		ok = false
		print("TEST: FAIL player never finished the race")
	if finished_pos > main.cars.size():
		ok = false
		print("TEST: FAIL nonsense finishing position")
	if p.laps_completed != RaceManager.TOTAL_LAPS:
		ok = false
		print("TEST: FAIL finished on %d laps, expected %d" % [p.laps_completed, RaceManager.TOTAL_LAPS])
	if p.best_lap <= 5.0:
		ok = false
		print("TEST: FAIL implausible best lap %.2f" % p.best_lap)
	if main.race.state != RaceManager.State.FINISHED:
		ok = false
		print("TEST: FAIL race state not FINISHED")

	print("TEST: RESULT=", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
