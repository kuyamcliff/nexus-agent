class_name RaceVehicle
extends VehicleBody3D
## Shared vehicle for the player and the AI.
##
## Wheel placement is read from the model itself at load time - every Kenney Car
## Kit vehicle names its wheels `wheel-front-left` / `wheel-back-right` / etc, so
## swapping in a different car needs no hand-measured numbers. The visual wheel
## meshes get re-parented onto the physics wheels so they steer and roll with the
## simulation.
##
## Subclasses drive the car by overriding `_update_controls()` and writing to
## `throttle`, `steer`, and `handbrake`.

const WHEEL_NAMES := {
	"wheel-front-left": [true, false],   # [steers, driven]
	"wheel-front-right": [true, false],
	"wheel-back-left": [false, true],
	"wheel-back-right": [false, true],
}

const MAX_ENGINE_FORCE := 2600.0
const MAX_BRAKE := 45.0
const TOP_SPEED := 42.0            ## m/s (~150 km/h)
const STEER_LOW_SPEED := deg_to_rad(32.0)
const STEER_HIGH_SPEED := deg_to_rad(11.0)
const STEER_RATE := 4.5
const OFF_TRACK_POWER := 0.45
const OFF_TRACK_DRAG := 3.2

@export var model_path := "res://assets/models/race.glb"

var throttle := 0.0    ## -1 (reverse/brake) .. 1
var steer := 0.0       ## -1 (right) .. 1 (left)
var handbrake := false
var controls_locked := true   ## released by the RaceManager when the lights go out

var track: TrackGeometry
var track_index := 0
var lateral := 0.0
var off_track := false

var display_name := "CAR"
var best_lap := 0.0
var current_lap_time := 0.0
var finished := false
var finish_time := 0.0

## Continuous lap counter: -1 on the grid (behind the line), 0 once the car has
## crossed the start line and is on lap 1, 1 after a full lap, and so on.
## Lap-relative progress wraps 0.99 -> 0.02 at the line, so ordering the field by
## raw progress puts a car that has just crossed the line *behind* one that
## hasn't - this counter is what makes standings monotonic.
var laps_travelled := -1
var total_progress := -1.0
var _prev_progress := 0.0
var _progress_synced := false
var _wheels: Array[VehicleWheel3D] = []
var _base_friction := 3.2


func _ready() -> void:
	mass = 400.0
	center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.05, 0)

	var instance: Node3D = load(model_path).instantiate()
	add_child(instance)
	_build_wheels_from_model(instance)
	_build_collision()


func _build_wheels_from_model(instance: Node3D) -> void:
	var front_z := 0.0
	var back_z := 0.0
	for wheel_name in WHEEL_NAMES:
		var mesh_node := instance.find_child(wheel_name, true, false) as Node3D
		if mesh_node == null:
			push_warning("%s: model has no node named %s" % [name, wheel_name])
			continue
		var local_pos: Vector3 = mesh_node.position
		var flags: Array = WHEEL_NAMES[wheel_name]

		var wheel := VehicleWheel3D.new()
		wheel.name = "VW_" + wheel_name
		wheel.use_as_steering = flags[0]
		wheel.use_as_traction = flags[1]
		wheel.wheel_radius = maxf(0.18, local_pos.y)
		wheel.wheel_rest_length = 0.3
		wheel.suspension_stiffness = 34.0
		wheel.suspension_travel = 0.45
		wheel.damping_compression = 0.75
		wheel.damping_relaxation = 0.9
		wheel.suspension_max_force = 9000.0
		wheel.wheel_friction_slip = _base_friction
		wheel.transform.origin = local_pos
		add_child(wheel)
		_wheels.append(wheel)

		mesh_node.reparent(wheel)
		if flags[0]:
			front_z = local_pos.z
		else:
			back_z = local_pos.z

	# These models face +Z (front wheels sit at greater Z than the rears). If a
	# future model is authored the other way round this flips the drive
	# direction rather than silently driving backwards.
	if front_z < back_z:
		push_warning("%s: model appears to face -Z; check drive direction" % name)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 0.5, 2.3)
	shape.shape = box
	shape.position = Vector3(0, 0.42, 0)
	add_child(shape)


## Overridden by the player and AI subclasses.
func _update_controls(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_update_track_state()
	_update_controls(delta)

	if controls_locked:
		engine_force = 0.0
		brake = MAX_BRAKE
		steering = 0.0
		return

	var speed := forward_speed()
	var power := MAX_ENGINE_FORCE
	if off_track:
		power *= OFF_TRACK_POWER

	if throttle > 0.0:
		# Taper power towards the top speed instead of hard-clamping it.
		var falloff := clampf(1.0 - speed / TOP_SPEED, 0.0, 1.0)
		engine_force = throttle * power * falloff
		brake = 0.0
	elif throttle < 0.0:
		if speed > 1.0:
			engine_force = 0.0
			brake = -throttle * MAX_BRAKE
		else:
			engine_force = throttle * power * 0.4
			brake = 0.0
	else:
		engine_force = 0.0
		brake = 2.0

	if handbrake:
		engine_force = 0.0
		brake = MAX_BRAKE

	# Off-track surfaces are slippery and draggy.
	var friction := _base_friction * (0.55 if off_track else 1.0)
	for w in _wheels:
		w.wheel_friction_slip = friction
	if off_track and linear_velocity.length() > 0.5:
		apply_central_force(-linear_velocity.normalized() * OFF_TRACK_DRAG * mass * 0.1)

	# Less steering lock the faster you go, or the car is undriveable at speed.
	var t := clampf(speed / TOP_SPEED, 0.0, 1.0)
	var max_steer := lerpf(STEER_LOW_SPEED, STEER_HIGH_SPEED, t)
	steering = move_toward(steering, steer * max_steer, STEER_RATE * delta)


func _update_track_state() -> void:
	if track == null:
		return
	track_index = track.closest_index(global_position, track_index)
	lateral = track.lateral_offset(global_position, track_index)
	off_track = absf(lateral) > TrackGeometry.HALF_WIDTH


func forward_speed() -> float:
	return global_transform.basis.z.dot(linear_velocity)


func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6


func track_progress() -> float:
	if track == null:
		return 0.0
	return track.progress(track_index)


## Completed laps, never negative (the grid sits at -1).
var laps_completed: int:
	get:
		return maxi(0, laps_travelled)


## Monotonic race progress used for ordering the field.
func race_progress() -> float:
	return total_progress


## Called every frame by the RaceManager while the race is running. Returns true
## on the frame a full lap is completed.
func update_lap(delta: float) -> bool:
	if finished:
		return false
	current_lap_time += delta

	var p := track_progress()
	if not _progress_synced:
		_prev_progress = p
		_progress_synced = true

	var completed := false
	var delta_p := p - _prev_progress
	if delta_p < -0.5:
		# Wrapped forwards over the start line.
		laps_travelled += 1
		if laps_travelled >= 1:
			if best_lap <= 0.0 or current_lap_time < best_lap:
				best_lap = current_lap_time
			completed = true
		current_lap_time = 0.0
	elif delta_p > 0.5:
		# Wrapped backwards - reversing over the line shouldn't gain a lap.
		laps_travelled -= 1

	_prev_progress = p
	total_progress = float(laps_travelled) + p
	return completed


## Drop the car back onto the centreline facing the right way - used for the
## grid, and for the player's "stuck" reset.
func place_on_track(index: int, lateral_offset := 0.0, height := 0.6) -> void:
	var s := track.get_sample(index)
	var pos: Vector3 = s["pos"] + s["right"] * lateral_offset + Vector3.UP * height
	var look: Vector3 = s["fwd"]
	# The models face +Z, and Basis.looking_at() aims -Z at the target, so aim it
	# at the point behind us to end up facing forwards.
	var b := Basis.looking_at(-look, Vector3.UP)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = Transform3D(b, pos)
	track_index = index
	# Re-sync next frame so the jump in position isn't read as a lap wrap.
	_progress_synced = false
