class_name AutoDriver
extends RefCounted
## Drives a PlayerCar around the circuit by pressing the same input actions a
## human would, so test harnesses exercise the real control path instead of
## writing to the vehicle's internals. Shared by the headless regression test
## and the screenshot harness.

static func drive(player: RaceVehicle, track: TrackGeometry, target_top := 40.0) -> void:
	var speed := player.forward_speed()
	var lookahead := 10.0 + speed * 0.5
	var local := player.to_local(track.point_ahead(player.track_index, lookahead))
	# Local +X is the car's left for these models.
	_hold("steer_left", local.x > 1.0)
	_hold("steer_right", local.x < -1.0)

	var curvature := track.max_curvature_ahead(player.track_index, maxf(18.0, speed * 1.6))
	var target_speed := target_top
	if curvature > 0.0005:
		target_speed = minf(target_speed, sqrt(11.0 / curvature))
	_hold("accelerate", speed < target_speed)
	_hold("brake", speed > target_speed + 3.0)


static func _hold(action: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)
