class_name TrackBuilder
extends RefCounted
## Turns a TrackGeometry into actual world geometry: asphalt ribbon, kerbs,
## painted edge lines, a start/finish line, solid barrier walls (real collision,
## so you cannot simply drive off into the void), and trackside scenery built
## from the Kenney Racing Kit (CC0).

const PROPS := "res://assets/props/"

var track: TrackGeometry


func _init(t: TrackGeometry) -> void:
	track = t


func build_into(parent: Node3D, start_line_distance: float) -> void:
	parent.add_child(_build_ground_collision())
	parent.add_child(_build_grass())
	parent.add_child(_build_road())
	parent.add_child(_build_kerbs())
	parent.add_child(_build_barriers())
	parent.add_child(_build_start_line(start_line_distance))
	parent.add_child(_build_scenery())


func _asphalt_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/asphalt_diffuse.jpg")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/asphalt_normal.jpg")
	m.roughness = 0.95
	m.uv1_scale = Vector3(1.0, 1.0, 1.0)
	return m


func _flat_material(colour: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	return m


const GRASS_LEVEL := -0.12  ## grass sits this far below the asphalt


func _build_ground_collision() -> StaticBody3D:
	## Infinite floor at grass level, so a car that leaves the circuit lands on
	## the grass instead of falling out of the world. The road has its own
	## (higher) collision, built with the road mesh.
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var shape := CollisionShape3D.new()
	var plane := WorldBoundaryShape3D.new()
	plane.plane = Plane(Vector3.UP, GRASS_LEVEL)
	shape.shape = plane
	body.add_child(shape)
	return body


func _build_grass() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Grass"
	var plane := PlaneMesh.new()
	plane.size = Vector2(900, 900)
	mi.mesh = plane
	# Real vertical separation from the asphalt. At 2cm the grass z-fought with
	# the road across the whole circuit and won, so the track rendered as grass.
	mi.position = Vector3(48, GRASS_LEVEL, 20)
	var mat := _flat_material(Color(0.22, 0.34, 0.16))
	mat.uv1_scale = Vector3(120, 120, 1)
	mi.material_override = mat
	return mi


func _build_road() -> Node3D:
	## The surface is built as three side-by-side lateral bands - white line,
	## asphalt, white line - rather than painting decal strips on top of a single
	## ribbon. Coplanar overlapping geometry z-fights at distance no matter how
	## small the offset; non-overlapping bands cannot.
	var root := Node3D.new()
	root.name = "Road"
	var hw := TrackGeometry.HALF_WIDTH
	var line_w := 0.3

	var asphalt := SurfaceTool.new()
	var paint := SurfaceTool.new()
	asphalt.begin(Mesh.PRIMITIVE_TRIANGLES)
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)

	var bands := [
		{"st": paint, "from": -hw, "to": -hw + line_w},
		{"st": asphalt, "from": -hw + line_w, "to": hw - line_w},
		{"st": paint, "from": hw - line_w, "to": hw},
	]

	var count := track.sample_count()
	for i in range(count):
		var a := track.get_sample(i)
		var b := track.get_sample(i + 1)
		var av := float(a["dist"]) / 10.0
		var bv := float(b["dist"]) / 10.0
		if i == count - 1:
			bv = av + 0.2  # stop the UV snapping back to 0 on the closing quad
		for band in bands:
			var f: float = band["from"]
			var t: float = band["to"]
			var a_l: Vector3 = a["pos"] + a["right"] * f
			var a_r: Vector3 = a["pos"] + a["right"] * t
			var b_l: Vector3 = b["pos"] + b["right"] * f
			var b_r: Vector3 = b["pos"] + b["right"] * t
			_quad(band["st"], a_l, a_r, b_r, b_l,
				Vector2(0, av), Vector2(1, av), Vector2(1, bv), Vector2(0, bv))

	asphalt.generate_normals()
	asphalt.generate_tangents()
	paint.generate_normals()

	var mi := MeshInstance3D.new()
	mi.name = "RoadSurface"
	mi.mesh = asphalt.commit()
	mi.material_override = _asphalt_material()
	root.add_child(mi)
	# Real collision for the raised asphalt; the grass plane is lower.
	mi.create_trimesh_collision()

	var lines := MeshInstance3D.new()
	lines.name = "EdgeLines"
	lines.mesh = paint.commit()
	lines.material_override = _flat_material(Color(0.92, 0.92, 0.92), 0.7)
	root.add_child(lines)
	lines.create_trimesh_collision()
	return root


func _build_kerbs() -> Node3D:
	## Red/white alternating kerbs, built as two meshes so each colour is one
	## draw call. Only laid on corners - kerbs down a straight look wrong.
	var root := Node3D.new()
	root.name = "Kerbs"
	var red := SurfaceTool.new()
	var white := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	white.begin(Mesh.PRIMITIVE_TRIANGLES)

	var count := track.sample_count()
	var hw := TrackGeometry.HALF_WIDTH
	for i in range(count):
		var a := track.get_sample(i)
		var b := track.get_sample(i + 1)
		if absf(float(a["curvature"])) < 0.006:
			continue  # effectively straight here
		var st: SurfaceTool = red if (int(float(a["dist"]) / 4.0) % 2 == 0) else white
		# Kerb goes on the outside of the corner; curvature sign gives the side.
		var side := -1.0 if float(a["curvature"]) > 0.0 else 1.0
		var o0 := side * hw
		var o1 := side * (hw + TrackGeometry.KERB_WIDTH)
		var a_i: Vector3 = a["pos"] + a["right"] * o0 + Vector3.UP * 0.02
		var a_o: Vector3 = a["pos"] + a["right"] * o1 + Vector3.UP * 0.06
		var b_i: Vector3 = b["pos"] + b["right"] * o0 + Vector3.UP * 0.02
		var b_o: Vector3 = b["pos"] + b["right"] * o1 + Vector3.UP * 0.06
		_quad(st, a_i, a_o, b_o, b_i, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))

	red.generate_normals()
	white.generate_normals()
	var mi_r := MeshInstance3D.new()
	mi_r.name = "KerbRed"
	mi_r.mesh = red.commit()
	mi_r.material_override = _flat_material(Color(0.75, 0.12, 0.12), 0.8)
	root.add_child(mi_r)
	var mi_w := MeshInstance3D.new()
	mi_w.name = "KerbWhite"
	mi_w.mesh = white.commit()
	mi_w.material_override = _flat_material(Color(0.9, 0.9, 0.9), 0.8)
	root.add_child(mi_w)
	return root


func _build_barriers() -> Node3D:
	## Visual barrier wall plus real box colliders, both sides, all the way
	## round. This is what stops the car leaving the circuit.
	var root := StaticBody3D.new()
	root.name = "Barriers"

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := track.sample_count()
	var hw := TrackGeometry.HALF_WIDTH + TrackGeometry.BARRIER_OFFSET
	var height := 1.4
	var step := 3  # one collider per 3 samples (~6m) keeps the shape count sane

	for side in [-1.0, 1.0]:
		for i in range(count):
			var a := track.get_sample(i)
			var b := track.get_sample(i + 1)
			var a_b: Vector3 = a["pos"] + a["right"] * (side * hw)
			var b_b: Vector3 = b["pos"] + b["right"] * (side * hw)
			var a_t := a_b + Vector3.UP * height
			var b_t := b_b + Vector3.UP * height
			# Face inward so the wall is lit from the track side.
			if side > 0.0:
				_quad(st, b_b, b_t, a_t, a_b, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0))
			else:
				_quad(st, a_b, a_t, b_t, b_b, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0))

		for i in range(0, count, step):
			var a := track.get_sample(i)
			var b := track.get_sample(i + step)
			var a_b: Vector3 = a["pos"] + a["right"] * (side * hw)
			var b_b: Vector3 = b["pos"] + b["right"] * (side * hw)
			var mid := (a_b + b_b) * 0.5 + Vector3.UP * (height * 0.5)
			var seg := b_b - a_b
			var length := seg.length()
			if length < 0.01:
				continue
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.4, height, length)
			shape.shape = box
			var basis := Basis.looking_at(seg.normalized(), Vector3.UP)
			shape.transform = Transform3D(basis, mid)
			root.add_child(shape)

	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "BarrierMesh"
	mi.mesh = st.commit()
	var mat := _flat_material(Color(0.85, 0.85, 0.88), 0.6)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	root.add_child(mi)
	return root


func _build_start_line(at_distance: float) -> Node3D:
	var root := Node3D.new()
	root.name = "StartLine"
	var idx := _index_at_distance(at_distance)
	var s := track.get_sample(idx)
	var hw := TrackGeometry.HALF_WIDTH

	# Checkered strip: alternating light/dark quads across the full width.
	var squares := 12
	var depth := 1.6
	for i in range(squares):
		for row in range(2):
			var mi := MeshInstance3D.new()
			var quad := BoxMesh.new()
			quad.size = Vector3((hw * 2.0) / squares, 0.02, depth * 0.5)
			mi.mesh = quad
			var lateral := -hw + (hw * 2.0 / squares) * (i + 0.5)
			var along: Vector3 = s["fwd"] * (depth * 0.25 if row == 0 else -depth * 0.25)
			mi.position = s["pos"] + s["right"] * lateral + along + Vector3.UP * 0.02
			mi.basis = Basis.looking_at(s["fwd"], Vector3.UP)
			var dark := (i + row) % 2 == 0
			mi.material_override = _flat_material(Color(0.06, 0.06, 0.06) if dark else Color(0.95, 0.95, 0.95), 0.7)
			root.add_child(mi)

	# Checkered flags either side of the line.
	var flag_scene := _try_load("flagCheckers")
	if flag_scene:
		for side in [-1.0, 1.0]:
			var f: Node3D = flag_scene.instantiate()
			f.position = s["pos"] + s["right"] * (side * (hw + 2.6))
			f.scale = Vector3.ONE * 4.0
			f.basis = Basis.looking_at(s["fwd"], Vector3.UP).scaled(Vector3.ONE * 4.0)
			root.add_child(f)
	return root


func _build_scenery() -> Node3D:
	## Trackside dressing. This is what gives a sense of speed - a bare plane
	## reads as standing still no matter how fast you are actually going.
	var root := Node3D.new()
	root.name = "Scenery"
	var count := track.sample_count()
	var hw := TrackGeometry.HALF_WIDTH + TrackGeometry.BARRIER_OFFSET

	var barrier := _try_load("barrierRed")
	var tree := _try_load("treeLarge")
	var stand := _try_load("grandStand")
	var light := _try_load("lightPostLarge")
	var pylon := _try_load("pylon")

	for i in range(count):
		var s := track.get_sample(i)
		var d := float(s["dist"])

		# Barrier blocks against the wall itself, both sides. These sit outside
		# the barrier line, not on the track edge - at 8x scale they are wider
		# than the car and were overhanging the racing surface.
		if barrier and i % 4 == 0:
			for side in [-1.0, 1.0]:
				var b: Node3D = barrier.instantiate()
				b.position = s["pos"] + s["right"] * (side * (hw + 0.55))
				b.basis = Basis.looking_at(s["fwd"], Vector3.UP).scaled(Vector3.ONE * 5.0)
				root.add_child(b)

		# Trees, set well back - the chase camera swings wide over the grass on
		# corners and will clip straight through anything closer in.
		if tree and i % 11 == 0:
			var t: Node3D = tree.instantiate()
			var side_t := 1.0 if (i / 11) % 2 == 0 else -1.0
			t.position = s["pos"] + s["right"] * (side_t * (hw + 16.0 + float(i % 6)))
			t.scale = Vector3.ONE * (4.5 + float(i % 3))
			root.add_child(t)

		# Light posts at regular intervals.
		if light and i % 23 == 0:
			var l: Node3D = light.instantiate()
			l.position = s["pos"] + s["right"] * (hw + 3.2)
			l.basis = Basis.looking_at(s["fwd"], Vector3.UP).scaled(Vector3.ONE * 6.0)
			root.add_child(l)

		# Cones marking the inside edge of tight corners - just off the racing
		# surface, not standing in the middle of the driving line.
		if pylon and absf(float(s["curvature"])) > 0.012 and i % 5 == 0:
			var p: Node3D = pylon.instantiate()
			var inner := 1.0 if float(s["curvature"]) > 0.0 else -1.0
			p.position = s["pos"] + s["right"] * (inner * (TrackGeometry.HALF_WIDTH + 0.6))
			p.scale = Vector3.ONE * 4.0
			root.add_child(p)

		# Grandstands along the main straight only.
		if stand and d > 15.0 and d < 110.0 and i % 9 == 0:
			var g: Node3D = stand.instantiate()
			g.position = s["pos"] + s["right"] * (hw + 12.0)
			g.basis = Basis.looking_at(-s["right"], Vector3.UP).scaled(Vector3.ONE * 12.0)
			root.add_child(g)

	return root


func _index_at_distance(d: float) -> int:
	var count := track.sample_count()
	for i in range(count):
		if float(track.get_sample(i)["dist"]) >= d:
			return i
	return 0


func _try_load(prop_name: String) -> PackedScene:
	var path := PROPS + prop_name + ".glb"
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Track prop missing: " + path)
	return null


## Emits v0-v1-v2-v3 as two triangles. The winding is reversed relative to the
## obvious right-hand-rule order: Godot treats clockwise-as-seen-from-the-front
## as the front face, and getting this backwards makes every surface face away
## from the camera and vanish behind backface culling (which is exactly what
## happened to the road - all 2520 of its normals pointed straight down).
func _quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3,
		uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2) -> void:
	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv2); st.add_vertex(v2)
	st.set_uv(uv1); st.add_vertex(v1)
	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv3); st.add_vertex(v3)
	st.set_uv(uv2); st.add_vertex(v2)
