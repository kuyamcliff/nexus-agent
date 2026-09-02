extends Node3D
## Simple chase camera: stays behind and above the target, smoothed.

@export var target_path: NodePath
@export var follow_distance := 6.0
@export var follow_height := 2.5
@export var look_height := 0.8
@export var position_smoothing := 6.0
@export var rotation_smoothing := 4.0

var _target: Node3D
@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	_target = get_node_or_null(target_path)

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var back_dir: Vector3 = _target.global_transform.basis.z.normalized()
	var desired_pos: Vector3 = _target.global_position + back_dir * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired_pos, 1.0 - exp(-position_smoothing * delta))

	var look_target: Vector3 = _target.global_position + Vector3.UP * look_height
	var current_xform := global_transform
	current_xform = current_xform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(current_xform, 1.0 - exp(-rotation_smoothing * delta))
