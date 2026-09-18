extends Node2D

var phase := 0.0
var objects: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var dust: Array[Dictionary] = []

func _ready() -> void:
	z_index = -7
	var rng := RandomNumberGenerator.new()
	rng.seed = 240024
	for i in range(9):
		objects.append({
			"pos": Vector2(rng.randf_range(-2300.0, 2300.0), rng.randf_range(-2300.0, 2300.0)),
			"radius": rng.randf_range(35.0, 110.0),
			"type": rng.randi_range(0, 2),
			"alpha": rng.randf_range(0.16, 0.32),
			"rot": rng.randf_range(0.0, TAU)
		})
	for i in range(65):
		debris.append({
			"pos": Vector2(rng.randf_range(-2200.0, 2200.0), rng.randf_range(-2200.0, 2200.0)),
			"size": rng.randf_range(3.0, 13.0),
			"rot": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.03, 0.12)
		})
	for i in range(120):
		dust.append({
			"pos": Vector2(rng.randf_range(-1900.0, 1900.0), rng.randf_range(-1900.0, 1900.0)),
			"size": rng.randf_range(0.5, 2.2),
			"alpha": rng.randf_range(0.08, 0.22)
		})
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	# Extremely subtle deep-space dust layer.
	for d in dust:
		var p: Vector2 = d["pos"]
		draw_circle(p, float(d["size"]), Color(0.45, 0.72, 0.9, float(d["alpha"])))

	# Distant celestial bodies provide scale and landmarks without cluttering combat.
	for obj in objects:
		_draw_celestial(obj)

	# Sparse drifting wreckage / asteroid fragments.
	for item in debris:
		var p: Vector2 = item["pos"]
		var s: float = item["size"]
		var rot: float = item["rot"] + phase * float(item["speed"])
		var pts := PackedVector2Array([
			Vector2(-s, -s * 0.35), Vector2(-s * 0.25, -s * 0.9),
			Vector2(s * 0.8, -s * 0.45), Vector2(s, s * 0.45),
			Vector2(-s * 0.35, s * 0.75)
		])
		var tr := Transform2D(rot, p)
		var world_pts := PackedVector2Array()
		for q in pts:
			world_pts.append(tr * q)
		draw_colored_polygon(world_pts, Color(0.18, 0.25, 0.34, 0.28))
		draw_polyline(world_pts + PackedVector2Array([world_pts[0]]), Color(0.38, 0.55, 0.68, 0.18), 1.0)

func _draw_celestial(obj: Dictionary) -> void:
	var p: Vector2 = obj["pos"]
	var r: float = obj["radius"]
	var kind: int = obj["type"]
	var a: float = obj["alpha"]
	var pulse := 1.0 + sin(phase * 0.35 + p.x * 0.001) * 0.025
	r *= pulse

	if kind == 0:
		# Ice/rock planet.
		draw_circle(p, r * 1.35, Color(0.12, 0.2, 0.32, a * 0.22))
		draw_circle(p, r, Color(0.15, 0.28, 0.42, a))
		draw_arc(p, r * 0.92, -2.7, 1.0, 32, Color(0.42, 0.72, 0.86, a * 0.8), 2.0)
		draw_arc(p, r * 0.66, 0.25, 2.1, 24, Color(0.07, 0.13, 0.22, a * 0.75), 4.0)
	elif kind == 1:
		# Gas giant with rings.
		draw_circle(p, r * 1.3, Color(0.32, 0.12, 0.36, a * 0.16))
		draw_circle(p, r, Color(0.28, 0.15, 0.34, a))
		for j in range(3):
			var rr := r * (0.45 + j * 0.17)
			draw_arc(p, rr, 0.15, PI - 0.15, 32, Color(0.66, 0.43, 0.75, a * 0.45), 1.2)
			draw_arc(p, rr, PI + 0.15, TAU - 0.15, 32, Color(0.08, 0.06, 0.15, a * 0.35), 1.2)
	else:
		# Distant star / flare.
		var glow := Color(0.3, 0.8, 1.0, a * 0.18)
		draw_circle(p, r * 1.7, glow)
		draw_circle(p, r * 0.75, Color(0.72, 0.9, 1.0, a * 0.9))
		draw_line(p - Vector2(r * 2.5, 0), p + Vector2(r * 2.5, 0), Color(0.42, 0.82, 1.0, a * 0.35), 1.0)
		draw_line(p - Vector2(0, r * 2.5), p + Vector2(0, r * 2.5), Color(0.42, 0.82, 1.0, a * 0.25), 1.0)
