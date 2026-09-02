extends Node3D
## Verification harness only (not part of the shipped game): loads the real
## Main scene, simulates holding the accelerator for a few seconds of
## physics ticks, and prints the car's actual position/speed so we can
## confirm the vehicle simulation genuinely moves the car - not just that
## the scene loads without errors.

var main: Node3D
var frame_count := 0
const STEER_START_FRAME := 300
const TOTAL_FRAMES := 600 # 10s at 60fps
var heading_at_steer_start := 0.0
var max_height := 0.0

func _ready() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	main = main_scene.instantiate()
	add_child(main)
	print("HEADLESS_TEST: scene instanced OK, nodes=", main.get_child_count())
	Input.action_press("ui_up")

func _physics_process(_delta: float) -> void:
	frame_count += 1
	var car = main.get_node_or_null("Car")
	if frame_count == 1:
		print("HEADLESS_TEST: car found=", car != null)
		if car:
			print("HEADLESS_TEST: car start pos=", car.global_position)
			print("HEADLESS_TEST: car wheel count=", car.get_children().filter(func(c): return c is VehicleWheel3D).size())
	if car:
		max_height = max(max_height, car.global_position.y)
	if frame_count == STEER_START_FRAME and car:
		heading_at_steer_start = car.rotation.y
		Input.action_press("ui_left")
		print("HEADLESS_TEST: applying steer at frame ", frame_count, " speed=", car.get_speed_kmh())
	if frame_count == TOTAL_FRAMES:
		if car:
			var pos: Vector3 = car.global_position
			var speed: float = car.get_speed_kmh()
			var heading_change: float = rad_to_deg(car.rotation.y - heading_at_steer_start)
			var is_finite: bool = is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z) and is_finite(speed)
			var upright: bool = car.global_transform.basis.y.dot(Vector3.UP) > 0.5
			print("HEADLESS_TEST: car end pos=", pos)
			print("HEADLESS_TEST: car speed kmh=", speed)
			print("HEADLESS_TEST: heading change since steer=", heading_change, " deg")
			print("HEADLESS_TEST: finite=", is_finite, " upright=", upright)
			print("HEADLESS_TEST: max height reached=", max_height)
			var pass_result: bool = is_finite and upright and abs(heading_change) > 5.0 and speed > 5.0 and max_height < 2.0
			print("HEADLESS_TEST: RESULT=", "PASS" if pass_result else "FAIL")
		else:
			print("HEADLESS_TEST: RESULT=FAIL (no car)")
		get_tree().quit()
