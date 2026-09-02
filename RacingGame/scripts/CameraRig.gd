extends Node3D
## Chase camera. Sits behind the car (these models face +Z, so "behind" is
## -basis.z - getting this backwards points the camera at the car's nose and
## makes it look like it's driving in reverse), and widens the FOV with speed so
## there's an actual sense of pace.

@export var target_path: NodePath
@export var follow_distance := 7.0
@export var follow_height := 3.0
@export var look_height := 1.0
@export var position_smoothing := 7.0
@export var rotation_smoothing := 9.0
@export var fov_base := 68.0
@export var fov_max := 88.0

var _target: RaceVehicle
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	if not target_path.is_empty():
		set_target(get_node_or_null(target_path))


## Preferred over `target_path` when the rig is built in code: the path can only
## be resolved once both nodes are in the tree, which is after _ready() has run.
func set_target(t: Node3D) -> void:
	_target = t
	if _target:
		_snap_behind()


func _snap_behind() -> void:
	var back: Vector3 = -_target.global_transform.basis.z
	global_position = _target.global_position + back * follow_distance + Vector3.UP * follow_height
	look_at(_target.global_position + Vector3.UP * look_height, Vector3.UP)


func _physics_process(delta: float) -> void:
	if _target == null:
		return

	var back: Vector3 = -_target.global_transform.basis.z
	back.y = 0.0
	if back.length_squared() < 0.001:
		return
	back = back.normalized()

	var desired: Vector3 = _target.global_position + back * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, 1.0 - exp(-position_smoothing * delta))

	var look_target: Vector3 = _target.global_position + Vector3.UP * look_height
	var wanted := global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(wanted, 1.0 - exp(-rotation_smoothing * delta))

	var t := clampf(_target.linear_velocity.length() / RaceVehicle.TOP_SPEED, 0.0, 1.0)
	_camera.fov = lerpf(_camera.fov, lerpf(fov_base, fov_max, t), 1.0 - exp(-3.0 * delta))
