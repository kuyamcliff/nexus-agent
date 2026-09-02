class_name AICar
extends RaceVehicle
## Opponent driver: aims at a point down the racing line and picks a target
## speed from how tight the track is about to get, so it actually brakes for
## corners instead of understeering into the barriers.

const LOOKAHEAD_MIN := 9.0
const LOOKAHEAD_PER_MS := 0.55   ## extra lookahead per m/s of speed
const CORNER_GRIP := 11.5        ## m/s^2 of lateral grip the AI believes it has
const STUCK_SPEED := 1.5
const STUCK_TIME := 2.5

## Per-driver personality so the field doesn't drive as one blob.
@export var skill := 1.0         ## scales cornering confidence and top speed
@export var line_offset := 0.0   ## metres left/right of the centreline

var _stuck_timer := 0.0


func _ready() -> void:
	super._ready()


func _update_controls(delta: float) -> void:
	if track == null or finished:
		throttle = 0.0
		steer = 0.0
		return

	var speed := forward_speed()
	var lookahead := LOOKAHEAD_MIN + speed * LOOKAHEAD_PER_MS
	var target := track.point_ahead(track_index, lookahead, line_offset)
	var local_target := to_local(target)

	# Local +X is the car's left (these models face +Z), so a positive x offset
	# means "target is left of us", which is also the sign convention `steering`
	# uses. No negation needed.
	steer = clampf(local_target.x / (lookahead * 0.5), -1.0, 1.0)

	var curvature := track.max_curvature_ahead(track_index, maxf(18.0, speed * 1.6))
	var target_speed := TOP_SPEED * skill
	if curvature > 0.0005:
		target_speed = minf(target_speed, sqrt((CORNER_GRIP * skill) / curvature))

	if speed < target_speed - 0.5:
		throttle = 1.0
	elif speed > target_speed + 1.5:
		throttle = -0.7
	else:
		throttle = 0.25

	# If it's wedged against something, reverse out; if that fails, respawn.
	if absf(speed) < STUCK_SPEED:
		_stuck_timer += delta
		if _stuck_timer > STUCK_TIME:
			throttle = -1.0
			steer = -steer
		if _stuck_timer > STUCK_TIME * 2.0:
			_stuck_timer = 0.0
			place_on_track(track_index, line_offset)
	else:
		_stuck_timer = 0.0
