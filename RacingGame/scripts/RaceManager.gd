class_name RaceManager
extends Node
## Race state machine: lights-out countdown, lap counting, live standings, and
## the chequered flag.

signal countdown_tick(label: String)
signal race_started
signal player_finished(position: int, total_time: float)

enum State { COUNTDOWN, RACING, FINISHED }

const TOTAL_LAPS := 3
const COUNTDOWN_TIME := 4.0

var state: State = State.COUNTDOWN
var countdown := COUNTDOWN_TIME
var race_time := 0.0
var cars: Array[RaceVehicle] = []
var player: RaceVehicle

var _last_countdown_label := ""
var _finish_order: Array[RaceVehicle] = []


func setup(all_cars: Array[RaceVehicle], player_car: RaceVehicle) -> void:
	cars = all_cars
	player = player_car
	for c in cars:
		c.controls_locked = true


func _physics_process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_tick_countdown(delta)
		State.RACING:
			_tick_race(delta)
		State.FINISHED:
			_tick_race(delta)  # AI keep circulating after the player is done


func _tick_countdown(delta: float) -> void:
	countdown -= delta
	var label := "GO!"
	if countdown > 3.0:
		label = "3"
	elif countdown > 2.0:
		label = "2"
	elif countdown > 1.0:
		label = "1"
	if label != _last_countdown_label:
		_last_countdown_label = label
		countdown_tick.emit(label)
	if countdown <= 0.0:
		state = State.RACING
		for c in cars:
			c.controls_locked = false
		race_started.emit()


func _tick_race(delta: float) -> void:
	if state == State.RACING:
		race_time += delta
	for c in cars:
		if c.finished:
			continue
		if c.update_lap(delta) and c.laps_completed >= TOTAL_LAPS:
			c.finished = true
			c.finish_time = race_time
			_finish_order.append(c)
			if c == player:
				state = State.FINISHED
				player.controls_locked = true
				player_finished.emit(_finish_order.size(), race_time)


## Live standings, leader first.
func standings() -> Array[RaceVehicle]:
	var sorted := cars.duplicate()
	sorted.sort_custom(func(a: RaceVehicle, b: RaceVehicle) -> bool:
		if a.finished != b.finished:
			return a.finished
		if a.finished and b.finished:
			return a.finish_time < b.finish_time
		return a.race_progress() > b.race_progress())
	return sorted


func player_position() -> int:
	var order := standings()
	for i in range(order.size()):
		if order[i] == player:
			return i + 1
	return order.size()


static func format_time(seconds: float) -> String:
	if seconds <= 0.0:
		return "--:--.---"
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	var ms := int((seconds - floorf(seconds)) * 1000.0)
	return "%d:%02d.%03d" % [m, s, ms]
