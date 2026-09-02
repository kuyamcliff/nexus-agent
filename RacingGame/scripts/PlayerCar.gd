class_name PlayerCar
extends RaceVehicle
## Player-controlled car. Arrows/WASD to drive, Space for handbrake, R to
## un-stick yourself if you end up beached on a barrier.

const RESET_HOLD_TIME := 0.35

var _reset_held := 0.0


func _ready() -> void:
	super._ready()
	display_name = "YOU"


func _update_controls(delta: float) -> void:
	throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	handbrake = Input.is_action_pressed("handbrake")

	# Hold R briefly to respawn on the racing line - a tap shouldn't do it.
	if Input.is_action_pressed("reset_car") and not controls_locked:
		_reset_held += delta
		if _reset_held >= RESET_HOLD_TIME:
			_reset_held = 0.0
			place_on_track(track_index)
	else:
		_reset_held = 0.0
