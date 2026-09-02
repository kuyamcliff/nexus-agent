extends Node3D
## Verification harness only: renders the real Main scene and saves a PNG
## screenshot so the visual result can actually be inspected, not just
## trusted to work from code review.

var frame_count := 0
const CAPTURE_FRAME := 90

func _ready() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	add_child(main_scene.instantiate())

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count == CAPTURE_FRAME:
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://screenshot.png")
		print("SCREENSHOT_SAVED")
		get_tree().quit()
