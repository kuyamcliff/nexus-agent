extends Node3D
## Builds the whole prototype scene at runtime: lighting/sky, a drivable
## asphalt ground plane (the real collision surface), a decorative track
## loop made from Kenney Racing Kit tiles (CC0, visual only - the flat
## ground underneath is what the car actually drives on, so tile seams
## being imperfect doesn't affect gameplay), the player car, chase camera,
## and a speed HUD.

const GROUND_HALF_SIZE := 80.0
const TRACK_HALF_EXTENT := 60.0
const CAR_SCENE_SCRIPT := preload("res://scripts/Car.gd")
const CAMERA_RIG_SCRIPT := preload("res://scripts/CameraRig.gd")
const HUD_SCRIPT := preload("res://scripts/HUD.gd")

var car: VehicleBody3D

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_track_decoration()
	car = _build_car()
	_build_camera(car)
	_build_hud(car)

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load("res://assets/hdri/kloofendal_48d_partly_cloudy_puresky.hdr")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.5
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	add_child(sun)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GROUND_HALF_SIZE * 2.0, 0.2, GROUND_HALF_SIZE * 2.0)
	shape.shape = box
	shape.position = Vector3(0, -0.1, 0)
	body.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GROUND_HALF_SIZE * 2.0, GROUND_HALF_SIZE * 2.0)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/asphalt_diffuse.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/asphalt_normal.jpg")
	mat.uv1_scale = Vector3(GROUND_HALF_SIZE, GROUND_HALF_SIZE, 1.0)
	mesh_instance.material_override = mat
	plane.material = mat
	mesh_instance.mesh = plane
	body.add_child(mesh_instance)

	add_child(body)

func _build_track_decoration() -> void:
	var straight_scene: PackedScene = load("res://assets/models/roadStraight.glb")
	var curved_scene: PackedScene = load("res://assets/models/roadCurved.glb")
	var container := Node3D.new()
	container.name = "TrackDecoration"
	add_child(container)

	var e := TRACK_HALF_EXTENT
	var tiles_per_edge := int(e * 2.0) - 2 # leave room for a corner piece each end

	# Bottom edge (running along X at Z = -e), top edge (Z = +e)
	for i in range(tiles_per_edge):
		var x: float = -e + 1.0 + i
		for z in [-e, e]:
			var inst: Node3D = straight_scene.instantiate()
			inst.position = Vector3(x, 0, z)
			inst.rotation_degrees.y = 90
			container.add_child(inst)

	# Left edge (running along Z at X = -e), right edge (X = +e)
	for i in range(tiles_per_edge):
		var z: float = -e + 1.0 + i
		for x in [-e, e]:
			var inst: Node3D = straight_scene.instantiate()
			inst.position = Vector3(x, 0, z)
			container.add_child(inst)

	# Four corners, best-effort rotation per corner (decorative only).
	var corners := [
		{"pos": Vector3(-e, 0, -e), "rot": 0.0},
		{"pos": Vector3(e, 0, -e), "rot": 90.0},
		{"pos": Vector3(e, 0, e), "rot": 180.0},
		{"pos": Vector3(-e, 0, e), "rot": 270.0},
	]
	for c in corners:
		var inst: Node3D = curved_scene.instantiate()
		inst.position = c["pos"]
		inst.rotation_degrees.y = c["rot"]
		container.add_child(inst)

func _build_car() -> VehicleBody3D:
	var body := VehicleBody3D.new()
	body.name = "Car"
	body.set_script(CAR_SCENE_SCRIPT)

	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 0.6, 2.56)
	collision.shape = box
	collision.position = Vector3(0, 0.4, 0)
	body.add_child(collision)

	body.position = Vector3(0, 0.6, 0.0)
	add_child(body)
	return body

func _build_camera(target: Node3D) -> void:
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(CAMERA_RIG_SCRIPT)
	rig.set("target_path", NodePath("../Car"))

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	rig.add_child(camera)

	add_child(rig)
	rig.global_position = target.global_position + Vector3(0, 2.5, 6.0)

func _build_hud(target: Node) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(HUD_SCRIPT)
	hud.set("car_path", NodePath("../Car"))

	var label := Label.new()
	label.name = "SpeedLabel"
	label.position = Vector2(24, 24)
	hud.add_child(label)

	add_child(hud)
