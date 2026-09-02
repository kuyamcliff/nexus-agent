extends VehicleBody3D
## Drivable car built from the Kenney Car Kit "race.glb" model (CC0).
## Wheel offsets below were measured directly from the source mesh
## (Blender bounding-box inspection), not guessed:
##   wheel-front-left  glTF(+0.350, 0.300, +0.640)
##   wheel-front-right glTF(-0.350, 0.300, +0.640)
##   wheel-back-left   glTF(+0.350, 0.300, -0.880)
##   wheel-back-right  glTF(-0.350, 0.300, -0.880)
## "Front" here means the geometry named front-left/front-right in the
## source file; the car's forward direction is +Z in its local space
## because that's where the front wheels sit relative to the rear ones.

const CAR_SCENE_PATH := "res://assets/models/race.glb"
const WHEEL_RADIUS := 0.3
const MAX_ENGINE_FORCE := 900.0
const MAX_BRAKE_FORCE := 60.0
const MAX_STEER_ANGLE := deg_to_rad(28.0)
const STEER_SPEED := 3.0

var _steer_target := 0.0

func _ready() -> void:
	mass = 900.0
	center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.15, 0)

	var body_scene: PackedScene = load(CAR_SCENE_PATH)
	var instance: Node3D = body_scene.instantiate()
	add_child(instance)

	var wheel_defs := {
		"wheel-front-left": {"pos": Vector3(0.350, WHEEL_RADIUS, 0.640), "steer": true, "traction": false},
		"wheel-front-right": {"pos": Vector3(-0.350, WHEEL_RADIUS, 0.640), "steer": true, "traction": false},
		"wheel-back-left": {"pos": Vector3(0.350, WHEEL_RADIUS, -0.880), "steer": false, "traction": true},
		"wheel-back-right": {"pos": Vector3(-0.350, WHEEL_RADIUS, -0.880), "steer": false, "traction": true},
	}

	for wheel_name in wheel_defs.keys():
		var def = wheel_defs[wheel_name]
		var wheel := VehicleWheel3D.new()
		wheel.name = "VW_" + wheel_name
		wheel.use_as_steering = def["steer"]
		wheel.use_as_traction = def["traction"]
		wheel.wheel_radius = WHEEL_RADIUS
		wheel.wheel_rest_length = 0.3
		wheel.suspension_stiffness = 30.0
		wheel.suspension_travel = 0.5
		wheel.damping_compression = 0.6
		wheel.damping_relaxation = 0.8
		wheel.wheel_friction_slip = 1.6
		wheel.transform.origin = def["pos"]
		add_child(wheel)

		# Re-parent the matching visual mesh from the imported glb onto the
		# physics wheel node so it actually rolls/steers with the simulation
		# instead of sitting static.
		var mesh_node := instance.find_child(wheel_name, true, false)
		if mesh_node:
			mesh_node.reparent(wheel) # keep_global_transform defaults to true

func _physics_process(delta: float) -> void:
	var throttle_input := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var steer_input := Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")

	if throttle_input > 0.0:
		engine_force = throttle_input * MAX_ENGINE_FORCE
		brake = 0.0
	elif throttle_input < 0.0:
		# Braking if moving forward, reversing once stopped.
		var forward_speed := -global_transform.basis.z.dot(linear_velocity)
		if forward_speed > 0.5:
			engine_force = 0.0
			brake = -throttle_input * MAX_BRAKE_FORCE
		else:
			engine_force = throttle_input * MAX_ENGINE_FORCE * 0.5
			brake = 0.0
	else:
		engine_force = 0.0
		brake = 1.0

	if Input.is_action_pressed("ui_select"):
		brake = MAX_BRAKE_FORCE

	_steer_target = steer_input * MAX_STEER_ANGLE
	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6
