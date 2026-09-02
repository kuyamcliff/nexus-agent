class_name TrackGeometry
extends RefCounted
## Closed-circuit centreline: a Catmull-Rom spline through hand-placed control
## points, densely sampled into a ribbon of (position, forward, right) frames.
## Everything else in the game derives from this - the road mesh, the barriers,
## the AI racing line, lap progress, and the off-track test - so there is exactly
## one definition of "where the track is".

const HALF_WIDTH := 6.0      ## drivable half-width in metres
const KERB_WIDTH := 1.2
const BARRIER_OFFSET := 2.0  ## barrier centre, measured out from the track edge

var samples: Array[Dictionary] = []  ## {pos, fwd, right, dist, curvature}
var total_length := 0.0

var _control_points: Array[Vector3] = []


func _init(control_points: Array[Vector3], step := 2.0) -> void:
	_control_points = control_points
	_build(step)


static func default_circuit() -> Array[Vector3]:
	## A ~900m circuit: long main straight, fast right sweeper, a pair of kinks,
	## a bottom straight, a left hairpin, and a 90-degree final corner onto the
	## straight. Laid out so no two sections come within barrier distance of
	## each other.
	##
	## Point 0 is deliberately the start/finish line, so distance-along-track 0
	## and lap-progress 0 both land exactly on the painted line - the lap counter
	## and the thing the player sees then agree by construction.
	var pts_2d := [
		Vector2(0, 10), Vector2(0, 55), Vector2(5, 98), Vector2(30, 136),
		Vector2(78, 162), Vector2(130, 157), Vector2(168, 123), Vector2(175, 73),
		Vector2(148, 33), Vector2(155, -15), Vector2(133, -58), Vector2(92, -88),
		Vector2(40, -100), Vector2(-15, -100), Vector2(-55, -85), Vector2(-78, -62),
		Vector2(-58, -48), Vector2(-25, -46), Vector2(0, -40),
	]
	var out: Array[Vector3] = []
	for p in pts_2d:
		out.append(Vector3(p.x, 0.0, p.y))
	return out


func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


func _build(step: float) -> void:
	var n := _control_points.size()
	var raw: Array[Vector3] = []
	for i in range(n):
		var p0 := _control_points[(i - 1 + n) % n]
		var p1 := _control_points[i]
		var p2 := _control_points[(i + 1) % n]
		var p3 := _control_points[(i + 2) % n]
		# Subdivide each segment by approximate chord length so sample spacing
		# stays roughly uniform whether the segment is a straight or a corner.
		var steps := maxi(2, int(p1.distance_to(p2) / step))
		for s in range(steps):
			raw.append(_catmull(p0, p1, p2, p3, float(s) / float(steps)))

	var count := raw.size()
	var dist := 0.0
	for i in range(count):
		var pos := raw[i]
		var nxt := raw[(i + 1) % count]
		var prv := raw[(i - 1 + count) % count]
		var fwd := (nxt - prv)
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		samples.append({
			"pos": pos,
			"fwd": fwd,
			"right": right,
			"dist": dist,
			"curvature": 0.0,
		})
		dist += pos.distance_to(nxt)
	total_length = dist

	# Curvature: signed heading change per metre (1/radius). Measured over an
	# 8-sample (~16m) baseline rather than 2 samples - a short baseline picks up
	# spline wiggle as if it were a hairpin, which had the AI crawling through
	# fast sweepers.
	const BASELINE := 8
	for i in range(count):
		var a: Vector3 = samples[i]["fwd"]
		var b: Vector3 = samples[(i + BASELINE) % count]["fwd"]
		var ang := a.signed_angle_to(b, Vector3.UP)
		var seg_len := maxf(0.001, _dist_between(i, (i + BASELINE) % count))
		samples[i]["curvature"] = ang / seg_len

	# Light smoothing pass so a single noisy sample can't trigger heavy braking.
	var raw_curv: Array[float] = []
	for i in range(count):
		raw_curv.append(samples[i]["curvature"])
	for i in range(count):
		var sum := 0.0
		for k in range(-2, 3):
			sum += raw_curv[(i + k + count) % count]
		samples[i]["curvature"] = sum / 5.0


func _dist_between(i: int, j: int) -> float:
	var d: float = samples[j]["dist"] - samples[i]["dist"]
	if d < 0.0:
		d += total_length
	return d


func sample_count() -> int:
	return samples.size()


## First sample at or past `d` metres along the lap (wraps).
func index_at_distance(d: float) -> int:
	var count := samples.size()
	var target := fposmod(d, total_length)
	for i in range(count):
		if float(samples[i]["dist"]) >= target:
			return i
	return 0


func get_sample(i: int) -> Dictionary:
	return samples[i % samples.size()]


## Nearest centreline sample to a world position. `hint` restricts the search to
## a window around the last known index, which keeps per-frame cost flat as the
## sample count grows; pass -1 for a full search.
func closest_index(pos: Vector3, hint := -1, window := 40) -> int:
	var count := samples.size()
	var best := 0
	var best_d := INF
	if hint >= 0:
		for k in range(-window, window + 1):
			var i := (hint + k + count) % count
			var d: float = pos.distance_squared_to(samples[i]["pos"])
			if d < best_d:
				best_d = d
				best = i
		return best
	for i in range(count):
		var d: float = pos.distance_squared_to(samples[i]["pos"])
		if d < best_d:
			best_d = d
			best = i
	return best


## Signed lateral offset from the centreline (+ve = right of the racing
## direction). |offset| > HALF_WIDTH means the car has left the track.
func lateral_offset(pos: Vector3, index: int) -> float:
	var s := samples[index]
	return (pos - s["pos"]).dot(s["right"])


## Progress around the lap, 0..1.
func progress(index: int) -> float:
	if total_length <= 0.0:
		return 0.0
	return float(samples[index]["dist"]) / total_length


## Point on the centreline `metres` further along from `index`, plus a lateral
## offset - the AI's target point.
func point_ahead(index: int, metres: float, lateral := 0.0) -> Vector3:
	var count := samples.size()
	var i := index
	var travelled := 0.0
	while travelled < metres:
		var nxt := (i + 1) % count
		travelled += samples[i]["pos"].distance_to(samples[nxt]["pos"])
		i = nxt
	var s := samples[i]
	return s["pos"] + s["right"] * lateral


## Worst (largest magnitude) curvature over the next `metres` - lets the AI brake
## for a corner before it reaches it.
func max_curvature_ahead(index: int, metres: float) -> float:
	var count := samples.size()
	var i := index
	var travelled := 0.0
	var worst := 0.0
	while travelled < metres:
		var nxt := (i + 1) % count
		travelled += samples[i]["pos"].distance_to(samples[nxt]["pos"])
		i = nxt
		worst = maxf(worst, absf(samples[i]["curvature"]))
	return worst
