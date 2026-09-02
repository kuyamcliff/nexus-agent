extends Node3D
## Verification harness only: same as ScreenshotTest.gd but captures the
## frame after a few seconds of simulated driving, to show the car in
## motion (moving wheels, non-zero HUD speed) rather than at a standstill.
var frame_count := 0
const CAPTURE_FRAME := 240 # ~4s at 60fps

func _ready() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	add_child(main_scene.instantiate())
	Input.action_press("ui_up")

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count == CAPTURE_FRAME:
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://screenshot_moving.png")
		print("SCREENSHOT_SAVED")
		get_tree().quit()
