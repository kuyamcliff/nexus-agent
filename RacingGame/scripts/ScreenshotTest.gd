extends Node3D
## Renders the real scene and saves a PNG so the visual result can be inspected
## rather than assumed. User args: `moving` to drive the car around first,
## `frame=N` to change when the shot is taken, `out=name.png`.

var frame := 0
var capture_frame := 90
var drive := false
var out_name := "screenshot.png"
var main: Node3D
var show_results := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "moving":
			drive = true
			capture_frame = 600
			out_name = "screenshot_moving.png"
		elif arg.begins_with("frame="):
			capture_frame = int(arg.split("=")[1])
		elif arg == "results":
			# Renders the end-of-race panel without simulating a full race - the
			# finish *logic* is covered by FinishTest, this checks the layout.
			show_results = true
			capture_frame = 120
			out_name = "screenshot_results.png"
		elif arg.begins_with("out="):
			out_name = arg.split("=")[1]
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	if show_results:
		main.player.best_lap = 37.983
		main.hud._on_finished(2, 117.449)


func _physics_process(_delta: float) -> void:
	if drive:
		AutoDriver.drive(main.player, main.track)


func _process(_delta: float) -> void:
	frame += 1
	if frame == capture_frame:
		var names := []
		for c in main.race.standings(): names.append("%s:%.3f" % [c.display_name, c.race_progress()])
		print("DIAG at capture: standings=", names, " player_pos=", main.race.player_position(),
			" state=", main.race.state, " countdown=%.2f" % main.race.countdown)
		get_viewport().get_texture().get_image().save_png("user://" + out_name)
		print("SCREENSHOT_SAVED ", out_name)
		get_tree().quit()
