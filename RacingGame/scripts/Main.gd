extends Node3D
## Assembles the race: circuit geometry, world, the field of cars, camera, HUD,
## and the race state machine. Everything is built in code from TrackGeometry so
## there's a single source of truth for where the track is.

const HUD_SCRIPT := preload("res://scripts/HUD.gd")
const CAMERA_SCRIPT := preload("res://scripts/CameraRig.gd")

## model, display name, skill (cornering confidence), preferred line offset
const FIELD := [
	{"model": "race-future.glb", "name": "NOVA", "skill": 0.98, "line": -1.6},
	{"model": "sedan-sports.glb", "name": "RYKER", "skill": 0.93, "line": 1.6},
	{"model": "hatchback-sports.glb", "name": "ORION", "skill": 0.89, "line": 0.0},
]

var track: TrackGeometry
var race: RaceManager
var player: PlayerCar
var cars: Array[RaceVehicle] = []
var hud: CanvasLayer


func _ready() -> void:
	_register_input()

	track = TrackGeometry.new(TrackGeometry.default_circuit())
	print("Track built: %.0f m, %d samples" % [track.total_length, track.sample_count()])

	_build_environment()
	TrackBuilder.new(track).build_into(self, 0.0)
	_spawn_field()
	_build_camera()

	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(HUD_SCRIPT)
	add_child(hud)

	race = RaceManager.new()
	race.name = "RaceManager"
	add_child(race)
	race.setup(cars, player)
	hud.bind(race, player)


## Registered in code rather than hand-authored into project.godot - the .cfg
## representation of InputEvents is long and easy to get subtly wrong, and this
## runs before any car reads input.
func _register_input() -> void:
	var bindings := {
		"accelerate": [KEY_UP, KEY_W],
		"brake": [KEY_DOWN, KEY_S],
		"steer_left": [KEY_LEFT, KEY_A],
		"steer_right": [KEY_RIGHT, KEY_D],
		"handbrake": [KEY_SPACE],
		"reset_car": [KEY_R],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load("res://assets/hdri/kloofendal_48d_partly_cloudy_puresky.hdr")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.5
	# Filmic tonemapping flattens the Kenney palette into pastels; a little
	# saturation and contrast puts the colour back without blowing highlights.
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.3
	environment.adjustment_contrast = 1.08
	env_node.environment = environment
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-46, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)


func _spawn_field() -> void:
	# Grid runs back from the line down the main straight, staggered left/right.
	# The player starts at the back so there's actually a race to win.
	var grid_gap := 9.0
	var slots := FIELD.size() + 1

	for i in range(FIELD.size()):
		var spec: Dictionary = FIELD[i]
		var ai := AICar.new()
		ai.name = "AI_%d" % i
		ai.model_path = "res://assets/models/" + spec["model"]
		ai.skill = spec["skill"]
		ai.line_offset = spec["line"]
		ai.display_name = spec["name"]
		ai.track = track
		add_child(ai)
		_place_on_grid(ai, i, grid_gap)
		cars.append(ai)

	player = PlayerCar.new()
	player.name = "Player"
	player.model_path = "res://assets/models/race.glb"
	player.track = track
	add_child(player)
	_place_on_grid(player, slots - 1, grid_gap)
	cars.append(player)


func _place_on_grid(car: RaceVehicle, slot: int, gap: float) -> void:
	var back_distance := 6.0 + gap * slot
	var index := track.index_at_distance(track.total_length - back_distance)
	var lateral := -2.4 if slot % 2 == 0 else 2.4
	car.place_on_track(index, lateral)


func _build_camera() -> void:
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(CAMERA_SCRIPT)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	# A near plane of 0.05 wastes most of the depth buffer up close and causes
	# z-fighting out at the horizon; 0.3 is still far closer than the chase
	# camera ever gets to the car.
	camera.near = 0.3
	camera.far = 900.0
	rig.add_child(camera)
	add_child(rig)
	rig.set_target(player)
