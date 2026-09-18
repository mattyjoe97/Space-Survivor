extends Node

## Spawn simple polygon-based VFX in the current scene



static func pickup_collect(at: Vector2, kind: String = "xp", strength: float = 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	root.z_index = 12
	scene.add_child(root)
	var col := Color(0.35, 1.0, 0.65, 0.9)
	if kind == "scrap":
		col = Color(1.0, 0.78, 0.25, 0.95)
	elif kind == "heal":
		col = Color(0.3, 1.0, 0.5, 0.95)
	elif kind == "vacuum":
		col = Color(0.35, 0.85, 1.0, 0.95)
	var ring = Line2D.new()
	ring.width = 2.5
	ring.default_color = col
	var pts: PackedVector2Array = []
	for i in range(17):
		var a = float(i) / 16.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * (7.0 * strength))
	ring.points = pts
	root.add_child(ring)
	var core = Polygon2D.new()
	core.color = Color(1.0, 1.0, 0.9, 0.95)
	core.polygon = PackedVector2Array([Vector2(-3,-3),Vector2(3,-3),Vector2(3,3),Vector2(-3,3)])
	root.add_child(core)
	var tw = root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(2.8, 2.8), 0.24)
	tw.tween_property(ring, "modulate:a", 0.0, 0.24)
	tw.tween_property(core, "scale", Vector2(2.2, 2.2), 0.16)
	tw.tween_property(core, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(root.queue_free)

static func level_up_burst(at: Vector2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	root.z_index = 13
	scene.add_child(root)
	for i in range(8):
		var ray = Line2D.new()
		ray.width = 2.0
		ray.default_color = Color(0.55, 0.95, 1.0, 0.85)
		var a = float(i) / 8.0 * TAU
		ray.points = PackedVector2Array([Vector2.from_angle(a) * 8.0, Vector2.from_angle(a) * 34.0])
		root.add_child(ray)
	var tw = root.create_tween()
	tw.set_parallel(true)
	for child in root.get_children():
		tw.tween_property(child, "scale", Vector2(1.35, 1.35), 0.3)
		tw.tween_property(child, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(root.queue_free)

static func hit(at: Vector2, heavy: bool = false, col: Color = Color(0.45, 0.9, 1.0, 0.85)) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	root.z_index = 8
	scene.add_child(root)
	var r = 7.0 if not heavy else 11.0
	var ring = Line2D.new()
	ring.width = 2.0 if not heavy else 3.0
	ring.default_color = col
	var pts: PackedVector2Array = []
	for i in range(9):
		var a = float(i) / 8.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * r)
	ring.points = pts
	root.add_child(ring)
	var core = Polygon2D.new()
	core.color = Color(1.0, 0.95, 0.78, 0.95)
	core.polygon = PackedVector2Array([Vector2(-r*0.45,0),Vector2(0,-r*0.45),Vector2(r*0.45,0),Vector2(0,r*0.45)])
	root.add_child(core)
	var tw = root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(1.8 if not heavy else 2.4, 1.8 if not heavy else 2.4), 0.16)
	tw.tween_property(ring, "modulate:a", 0.0, 0.16)
	tw.tween_property(core, "scale", Vector2(2.0, 2.0), 0.12)
	tw.tween_property(core, "modulate:a", 0.0, 0.12)
	# Spark streaks (cheap Line2D, no particles) so hits feel physical.
	var streaks := 3 if not heavy else 6
	for i in range(streaks):
		var st := Line2D.new()
		st.width = 1.6 if not heavy else 2.2
		st.default_color = Color(1.0, 0.95, 0.8, 0.95)
		var a := randf() * TAU
		st.points = PackedVector2Array([Vector2.from_angle(a) * 3.0, Vector2.from_angle(a) * (7.0 if not heavy else 10.0)])
		root.add_child(st)
		var d := Vector2.from_angle(a) * randf_range(16.0, 30.0) * (1.0 if not heavy else 1.6)
		tw.tween_property(st, "position", d, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(st, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(root.queue_free)
	if heavy:
		screen_shake(2.5)

static func death_burst(at: Vector2, radius: float = 34.0, col: Color = Color(1.0, 0.45, 0.18, 0.8)) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	root.z_index = 7
	scene.add_child(root)
	var ring = Polygon2D.new()
	ring.color = col
	var pts: PackedVector2Array = []
	for i in range(12):
		var a = float(i) / 12.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.24)
	ring.polygon = pts
	root.add_child(ring)
	var core = Polygon2D.new()
	core.color = Color(1.0, 0.95, 0.72, 0.95)
	core.polygon = PackedVector2Array([Vector2(-5,-5),Vector2(5,-5),Vector2(5,5),Vector2(-5,5)])
	root.add_child(core)
	var tw = root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(3.2,3.2), 0.24)
	tw.tween_property(ring, "modulate:a", 0.0, 0.24)
	tw.tween_property(core, "scale", Vector2(3.0,3.0), 0.18)
	tw.tween_property(core, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(root.queue_free)

## Chromatic-aberration punch on the PostFX layer (no-op if the layer isn't present).
static func postfx_punch(amount: float = 0.6) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.get_nodes_in_group("postfx"):
		if n.has_method("punch"):
			n.punch(amount)

static func screen_shake(amount: float = 3.0) -> void:
	if not SettingsManager.screen_shake:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var camera: Node = null
	if is_instance_valid(GameManager.player):
		camera = GameManager.player.get_node_or_null("Camera2D")
	if camera == null:
		camera = tree.root.get_node_or_null("Main/Player/Camera2D")
	if not camera:
		return
	# Decaying multi-step shake reads better than a single offset snap.
	var steps := 4 if amount >= 5.0 else 3
	var tw = camera.create_tween()
	for i in range(steps):
		var a: float = amount * (1.0 - float(i) / float(steps))
		tw.tween_property(camera, "offset", Vector2(randf_range(-a, a), randf_range(-a, a)), 0.035)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.06)

## Full-screen tinted flash for impactful moments (taking damage, big pickups, phase changes).
## Reuses a single overlay node across calls so rapid hits don't stack dozens of ColorRects.
static func screen_flash(col: Color = Color(1.0, 0.2, 0.25, 0.28), duration: float = 0.22) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var ui: Node = tree.root.get_node_or_null("Main/UI")
	if ui == null:
		return
	var overlay: ColorRect = ui.get_node_or_null("ScreenFlash")
	if overlay == null:
		overlay = ColorRect.new()
		overlay.name = "ScreenFlash"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(col.r, col.g, col.b, 0.0)
		overlay.z_index = 500
		ui.add_child(overlay)
	overlay.color = col
	var tw = overlay.create_tween()
	tw.tween_property(overlay, "color:a", 0.0, duration)

## Player-facing damage feedback bundle: brief red screen tint + camera punch + a hit spark.
static func player_hit_feedback(at: Vector2, heavy: bool = false) -> void:
	screen_flash(Color(1.0, 0.15, 0.2, 0.32 if heavy else 0.2), 0.28 if heavy else 0.18)
	postfx_punch(0.9 if heavy else 0.5)
	sparks(at, 10 if heavy else 6, Color(1.0, 0.6, 0.45), 150.0, 0.35)
	screen_shake(4.5 if heavy else 2.4)
	hit(at, heavy, Color(1.0, 0.35, 0.35, 0.9))

## Ship destruction: bright core blast + several polygonal hull/wing fragments that
## fly outward, spin, and fade. Used when the player dies.
static func ship_breakup(at: Vector2, ship_rotation: float = 0.0, accent: Color = Color(0.35, 0.85, 1.0)) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	root.z_index = 20
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(root)

	# Core flash + expanding rings
	var core = Polygon2D.new()
	core.color = Color(1.0, 0.95, 0.7, 1.0)
	core.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	root.add_child(core)
	var ring = Line2D.new()
	ring.width = 3.5
	ring.default_color = Color(accent.r, accent.g, accent.b, 0.9)
	var rpts: PackedVector2Array = []
	for i in range(17):
		var a = float(i) / 16.0 * TAU
		rpts.append(Vector2(cos(a), sin(a)) * 18.0)
	ring.points = rpts
	root.add_child(ring)
	var outer = Line2D.new()
	outer.width = 2.0
	outer.default_color = Color(1.0, 0.55, 0.2, 0.75)
	var opts: PackedVector2Array = []
	for i in range(17):
		var a = float(i) / 16.0 * TAU
		opts.append(Vector2(cos(a), sin(a)) * 28.0)
	outer.points = opts
	root.add_child(outer)

	var flash_tw = root.create_tween()
	flash_tw.set_parallel(true)
	flash_tw.tween_property(core, "scale", Vector2(4.5, 4.5), 0.22)
	flash_tw.tween_property(core, "modulate:a", 0.0, 0.22)
	flash_tw.tween_property(ring, "scale", Vector2(5.0, 5.0), 0.35)
	flash_tw.tween_property(ring, "modulate:a", 0.0, 0.35)
	flash_tw.tween_property(outer, "scale", Vector2(4.2, 4.2), 0.42)
	flash_tw.tween_property(outer, "modulate:a", 0.0, 0.42)

	# Debris piece shapes (hull / wing / engine fragments)
	var piece_polys: Array = [
		PackedVector2Array([Vector2(0, -14), Vector2(8, 2), Vector2(4, 10), Vector2(-4, 10), Vector2(-8, 2)]),  # nose
		PackedVector2Array([Vector2(-2, -2), Vector2(-18, 4), Vector2(-14, 12), Vector2(-2, 6)]),  # left wing
		PackedVector2Array([Vector2(2, -2), Vector2(18, 4), Vector2(14, 12), Vector2(2, 6)]),  # right wing
		PackedVector2Array([Vector2(-6, -4), Vector2(6, -4), Vector2(5, 8), Vector2(-5, 8)]),  # body plate
		PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(3, 12), Vector2(-3, 12)]),  # engine
		PackedVector2Array([Vector2(-5, -6), Vector2(5, -6), Vector2(7, 2), Vector2(0, 6), Vector2(-7, 2)]),  # cockpit shard
		PackedVector2Array([Vector2(-3, -5), Vector2(9, -2), Vector2(6, 8), Vector2(-4, 4)]),  # panel
		PackedVector2Array([Vector2(-8, -3), Vector2(2, -6), Vector2(4, 5), Vector2(-6, 7)]),  # scrap
	]
	var hull_col := Color(0.22, 0.30, 0.40)
	var panel_col := Color(0.35, 0.50, 0.62)
	var colors: Array = [
		accent, panel_col, accent.lerp(Color(1, 1, 1), 0.3), hull_col,
		Color(0.3, 0.75, 1.0, 0.9), Color(0.7, 0.92, 1.0), panel_col, hull_col
	]

	for i in range(piece_polys.size()):
		var piece_root = Node2D.new()
		piece_root.rotation = ship_rotation
		root.add_child(piece_root)
		var poly = Polygon2D.new()
		poly.polygon = piece_polys[i]
		poly.color = colors[i]
		piece_root.add_child(poly)
		# Slight random offset so pieces don't all start stacked
		piece_root.position = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		var angle = float(i) / float(piece_polys.size()) * TAU + randf_range(-0.35, 0.35)
		var dist = randf_range(90.0, 175.0)
		var end_pos = Vector2.from_angle(angle) * dist
		var spin = randf_range(-4.5, 4.5)
		var dur = randf_range(0.55, 0.95)
		var ptw = piece_root.create_tween()
		ptw.set_parallel(true)
		ptw.tween_property(piece_root, "position", end_pos, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ptw.tween_property(piece_root, "rotation", piece_root.rotation + spin, dur)
		ptw.tween_property(piece_root, "modulate:a", 0.0, dur).set_delay(dur * 0.35)
		ptw.tween_property(piece_root, "scale", Vector2(0.55, 0.55), dur)

	# Sparks
	for i in range(10):
		var spark = Polygon2D.new()
		spark.color = Color(1.0, 0.85, 0.4, 0.95)
		var s = randf_range(1.5, 3.5)
		spark.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
		root.add_child(spark)
		var sa = randf() * TAU
		var sd = randf_range(40.0, 130.0)
		var stw = spark.create_tween()
		stw.set_parallel(true)
		stw.tween_property(spark, "position", Vector2.from_angle(sa) * sd, randf_range(0.25, 0.5))
		stw.tween_property(spark, "modulate:a", 0.0, 0.45)
		stw.tween_property(spark, "scale", Vector2(0.2, 0.2), 0.45)

	# Clean up root after longest debris finishes
	var clean = root.create_tween()
	clean.tween_interval(1.05)
	clean.tween_callback(root.queue_free)

static func explosion(at: Vector2, radius: float = 60.0, col: Color = Color(1.0, 0.5, 0.15, 0.85)) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	scene.add_child(root)

	# Expanding ring
	var ring = Polygon2D.new()
	ring.color = col
	var pts: PackedVector2Array = []
	for i in range(12):
		var a = float(i) / 12.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.25)
	ring.polygon = pts
	root.add_child(ring)

	# Core flash
	var core = Polygon2D.new()
	core.color = Color(1, 0.95, 0.6, 0.9)
	var cpts: PackedVector2Array = []
	for i in range(8):
		var a = float(i) / 8.0 * TAU
		cpts.append(Vector2(cos(a), sin(a)) * radius * 0.12)
	core.polygon = cpts
	root.add_child(core)

	var tw = root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(2.8, 2.8), 0.28)
	tw.tween_property(ring, "modulate:a", 0.0, 0.28)
	tw.tween_property(core, "scale", Vector2(2.0, 2.0), 0.2)
	tw.tween_property(core, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(root.queue_free)
	# Layered extras: shockwave, sparks, a little smoke.
	shockwave(at, radius * 1.15, Color(col.r, col.g, col.b, 0.8), 2.5, 0.32)
	sparks(at, clampi(int(radius * 0.18), 6, 22), col.lerp(Color(1, 1, 0.85), 0.5), radius * 2.6, 0.42)
	if radius >= 70.0:
		smoke(at, 5, Color(0.4, 0.38, 0.42, 0.3), radius * 0.2)

static func singularity(at: Vector2, radius: float = 200.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	scene.add_child(root)

	var col = Color(0.45, 0.2, 1.0, 0.55)
	var ring = Polygon2D.new()
	ring.color = col
	var pts: PackedVector2Array = []
	for i in range(16):
		var a = float(i) / 16.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.35)
	ring.polygon = pts
	root.add_child(ring)

	var core = Polygon2D.new()
	core.color = Color(0.15, 0.05, 0.3, 0.85)
	var cpts: PackedVector2Array = []
	for i in range(10):
		var a = float(i) / 10.0 * TAU
		cpts.append(Vector2(cos(a), sin(a)) * 18.0)
	core.polygon = cpts
	root.add_child(core)

	var outer = Polygon2D.new()
	outer.color = Color(0.6, 0.35, 1.0, 0.25)
	var opts: PackedVector2Array = []
	for i in range(16):
		var a = float(i) / 16.0 * TAU
		opts.append(Vector2(cos(a), sin(a)) * radius * 0.55)
	outer.polygon = opts
	root.add_child(outer)

	var tw = root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.45)
	tw.tween_property(ring, "modulate:a", 0.0, 0.45)
	tw.tween_property(outer, "scale", Vector2(1.3, 1.3), 0.5)
	tw.tween_property(outer, "modulate:a", 0.0, 0.5)
	tw.tween_property(core, "scale", Vector2(0.3, 0.3), 0.5)
	tw.tween_property(core, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(root.queue_free)

static func radiation_pulse(at: Vector2, radius: float = 100.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	scene.add_child(root)
	var ring = Polygon2D.new()
	ring.color = Color(0.35, 1.0, 0.4, 0.35)
	var pts: PackedVector2Array = []
	for i in range(14):
		var a = float(i) / 14.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.4)
	ring.polygon = pts
	root.add_child(ring)
	var tw = root.create_tween()
	tw.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.35)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tw.tween_callback(root.queue_free)


static func ring_burst(at: Vector2, radius: float = 50.0, col: Color = Color(1.0, 0.35, 0.55, 0.7)) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at
	scene.add_child(root)
	var ring = Polygon2D.new()
	ring.color = col
	var pts: PackedVector2Array = []
	for i in range(20):
		var a = float(i) / 20.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.32)
	ring.polygon = pts
	root.add_child(ring)
	var tw = root.create_tween()
	tw.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.32)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.32)
	tw.tween_callback(root.queue_free)

static func dash_burst(at: Vector2, direction: Vector2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene: Node = GameManager.world_root()
	var root = Node2D.new()
	root.global_position = at - direction.normalized() * 10.0
	root.rotation = direction.angle()
	scene.add_child(root)
	var trail = Polygon2D.new()
	trail.color = Color(0.35, 0.85, 1.0, 0.42)
	trail.polygon = PackedVector2Array([
		Vector2(-4, -6), Vector2(-52, -14), Vector2(-72, 0),
		Vector2(-52, 14), Vector2(-4, 6)
	])
	root.add_child(trail)
	var tw = root.create_tween()
	tw.tween_property(trail, "scale", Vector2(0.35, 1.0), 0.18)
	tw.parallel().tween_property(trail, "modulate:a", 0.0, 0.18)
	tw.tween_callback(root.queue_free)

# ===========================================================================
# 3.15 VFX additions: particles, shockwaves, debris, muzzle flashes, ghosts
# ===========================================================================

static func _root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return GameManager.world_root()

static func _ring_points(r: float, n: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := float(i) / float(n) * TAU
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

## One-shot spark burst using CPUParticles2D (no shaders required).
static func sparks(at: Vector2, count: int = 12, col: Color = Color(1.0, 0.85, 0.4), speed: float = 160.0, life: float = 0.45, dir: Vector2 = Vector2.ZERO, spread_deg: float = 180.0, gravity: float = 0.0) -> void:
	var scene := _root()
	if scene == null:
		return
	var p := CPUParticles2D.new()
	p.global_position = at
	p.z_index = 14
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(1, count)
	p.lifetime = life
	p.lifetime_randomness = 0.45
	p.direction = dir if dir != Vector2.ZERO else Vector2.RIGHT
	p.spread = spread_deg if dir != Vector2.ZERO else 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.damping_min = speed * 0.9
	p.damping_max = speed * 1.6
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.6
	p.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	scene.add_child(p)
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(life * 1.6 + 0.1)
	tw.tween_callback(p.queue_free)

## Soft smoke puffs that drift and expand.
static func smoke(at: Vector2, count: int = 6, col: Color = Color(0.45, 0.45, 0.5, 0.35), radius: float = 10.0) -> void:
	var scene := _root()
	if scene == null:
		return
	var root := Node2D.new()
	root.global_position = at
	root.z_index = 6
	scene.add_child(root)
	for i in range(count):
		var puff := Polygon2D.new()
		puff.polygon = _ring_points(1.0, 10)
		puff.color = col
		var r := radius * randf_range(0.5, 1.0)
		puff.scale = Vector2(r, r) * 0.4
		puff.position = Vector2(randf_range(-4, 4), randf_range(-4, 4))
		root.add_child(puff)
		var drift := Vector2.from_angle(randf() * TAU) * randf_range(18.0, 46.0)
		var dur := randf_range(0.5, 0.9)
		var tw := puff.create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "position", puff.position + drift, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "scale", Vector2(r, r), dur)
		tw.tween_property(puff, "modulate:a", 0.0, dur).set_delay(dur * 0.25)
	var clean := root.create_tween()
	clean.tween_interval(1.0)
	clean.tween_callback(root.queue_free)

## Thin expanding shockwave ring with ease-out.
static func shockwave(at: Vector2, radius: float = 80.0, col: Color = Color(1, 1, 1, 0.8), width: float = 3.0, duration: float = 0.35) -> void:
	var scene := _root()
	if scene == null:
		return
	var root := Node2D.new()
	root.global_position = at
	root.z_index = 9
	scene.add_child(root)
	var ring := Line2D.new()
	ring.width = width
	ring.default_color = col
	ring.points = _ring_points(radius * 0.15, 40)
	root.add_child(ring)
	var tw := root.create_tween()
	tw.set_parallel(true)
	# Regenerate points instead of scaling the node so the stroke width stays constant.
	tw.tween_method(func(r: float): ring.points = _ring_points(r, 40), radius * 0.15, radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "width", maxf(0.5, width * 0.3), duration)
	tw.tween_property(ring, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(root.queue_free)

## Tumbling polygon shards for enemy / structure destruction.
static func debris(at: Vector2, col: Color, count: int = 6, force: float = 110.0, size: float = 6.0) -> void:
	var scene := _root()
	if scene == null:
		return
	var root := Node2D.new()
	root.global_position = at
	root.z_index = 8
	scene.add_child(root)
	for i in range(count):
		var poly := Polygon2D.new()
		var s := size * randf_range(0.5, 1.2)
		var verts := randi_range(3, 5)
		var pts := PackedVector2Array()
		for v in range(verts):
			var a := float(v) / float(verts) * TAU + randf_range(-0.3, 0.3)
			pts.append(Vector2.from_angle(a) * s * randf_range(0.55, 1.0))
		poly.polygon = pts
		poly.color = col.lerp(Color(1, 1, 1), randf_range(0.0, 0.35)) if i % 3 == 0 else col.darkened(randf_range(0.0, 0.4))
		root.add_child(poly)
		var ang := randf() * TAU
		var dist := force * randf_range(0.45, 1.0)
		var dur := randf_range(0.4, 0.75)
		var tw := poly.create_tween()
		tw.set_parallel(true)
		tw.tween_property(poly, "position", Vector2.from_angle(ang) * dist, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(poly, "rotation", randf_range(-6.0, 6.0), dur)
		tw.tween_property(poly, "scale", Vector2(0.3, 0.3), dur)
		tw.tween_property(poly, "modulate:a", 0.0, dur).set_delay(dur * 0.4)
	var clean := root.create_tween()
	clean.tween_interval(0.85)
	clean.tween_callback(root.queue_free)

## Short muzzle flash cone + bright core at a gun barrel.
static func muzzle_flash(at: Vector2, dir: Vector2, col: Color = Color(1.0, 0.9, 0.55), size: float = 1.0) -> void:
	var scene := _root()
	if scene == null:
		return
	var root := Node2D.new()
	root.global_position = at
	root.rotation = dir.angle()
	root.z_index = 11
	scene.add_child(root)
	var cone := Polygon2D.new()
	cone.color = Color(col.r, col.g, col.b, 0.75)
	cone.polygon = PackedVector2Array([Vector2(0, -3), Vector2(14, -7), Vector2(20, 0), Vector2(14, 7), Vector2(0, 3)])
	cone.scale = Vector2(size, size)
	root.add_child(cone)
	var core := Polygon2D.new()
	core.color = Color(1, 1, 0.95, 0.95)
	core.polygon = _ring_points(4.0 * size, 8)
	root.add_child(core)
	var tw := root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(cone, "scale", Vector2(size * 1.5, size * 0.4), 0.08)
	tw.tween_property(cone, "modulate:a", 0.0, 0.09)
	tw.tween_property(core, "scale", Vector2(0.2, 0.2), 0.08)
	tw.tween_property(core, "modulate:a", 0.0, 0.08)
	tw.chain().tween_callback(root.queue_free)

## Full enemy destruction package: flash, shockwave, sparks, shards, smoke.
static func enemy_death(at: Vector2, col: Color, big: bool = false) -> void:
	var m := 1.6 if big else 1.0
	death_burst(at, 34.0 * m, col)
	shockwave(at, 46.0 * m, Color(col.r, col.g, col.b, 0.7), 2.5 * m, 0.3)
	sparks(at, 14 if big else 8, col.lerp(Color(1, 1, 0.8), 0.4), 190.0 * m, 0.4)
	debris(at, col, 7 if big else 4, 120.0 * m, 6.0 * m)
	if big:
		smoke(at, 6, Color(0.4, 0.38, 0.45, 0.32), 14.0)
		screen_shake(3.0)

## Translucent afterimage of the player's ship (used during dash).
static func ship_ghost(ship: Node2D, accent: Color) -> void:
	var scene := _root()
	if scene == null or not is_instance_valid(ship):
		return
	var art: Node = ship.get_node_or_null("ShipArt")
	if art == null:
		return
	var ghost := Node2D.new()
	ghost.global_position = ship.global_position
	ghost.rotation = ship.rotation
	ghost.z_index = 0
	ghost.modulate = Color(accent.r, accent.g, accent.b, 0.55)
	scene.add_child(ghost)
	var copy: Node = art.duplicate()
	copy.set_process(false)
	ghost.add_child(copy)
	var tw := ghost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tw.tween_property(ghost, "scale", Vector2(0.86, 0.86), 0.28)
	tw.chain().tween_callback(ghost.queue_free)

## Big cinematic blast for boss/elite deaths.
static func mega_explosion(at: Vector2, col: Color = Color(1.0, 0.5, 0.2)) -> void:
	explosion(at, 140.0, Color(col.r, col.g, col.b, 0.85))
	shockwave(at, 260.0, Color(1, 1, 1, 0.9), 5.0, 0.55)
	shockwave(at, 180.0, Color(col.r, col.g, col.b, 0.8), 3.0, 0.45)
	sparks(at, 40, Color(1.0, 0.9, 0.6), 320.0, 0.8)
	debris(at, col, 16, 220.0, 12.0)
	smoke(at, 12, Color(0.35, 0.32, 0.4, 0.4), 26.0)
	screen_shake(10.0)
	screen_flash(Color(1.0, 0.85, 0.6, 0.45), 0.4)
	postfx_punch(1.0)
	var scene := _root()
	if scene == null:
		return
	# Delayed secondary pops.
	for i in range(4):
		var t := scene.create_tween()
		t.tween_interval(0.12 * (i + 1))
		var off := Vector2.from_angle(randf() * TAU) * randf_range(20.0, 70.0)
		t.tween_callback(func():
			explosion(at + off, 50.0, Color(col.r, col.g, col.b, 0.7))
			sparks(at + off, 10, Color(1.0, 0.85, 0.5), 160.0, 0.4)
		)


# ===========================================================================
# Weapon-system VFX (3.16)
# ===========================================================================

## Full-screen superweapon activation: giant ring, spark storm, flash, shake, punch.
static func superweapon_activation(at: Vector2, col: Color) -> void:
	shockwave(at, 420.0, Color(1, 1, 1, 0.9), 6.0, 0.7)
	shockwave(at, 300.0, Color(col.r, col.g, col.b, 0.9), 4.0, 0.55)
	shockwave(at, 180.0, Color(col.r, col.g, col.b, 0.7), 8.0, 0.4)
	sparks(at, 60, col.lerp(Color(1, 1, 1), 0.4), 420.0, 0.9)
	sparks(at, 30, Color(1, 1, 1), 250.0, 0.6)
	screen_flash(Color(col.r, col.g, col.b, 0.5), 0.6)
	screen_shake(12.0)
	postfx_punch(1.0)
	var scene := _root()
	if scene == null:
		return
	# Rotating rays
	var root := Node2D.new()
	root.global_position = at
	root.z_index = 30
	scene.add_child(root)
	for i in range(12):
		var ray := Line2D.new()
		ray.width = 4.0
		ray.default_color = Color(col.r, col.g, col.b, 0.85)
		var a := float(i) / 12.0 * TAU
		ray.points = PackedVector2Array([Vector2.from_angle(a) * 20.0, Vector2.from_angle(a) * 90.0])
		root.add_child(ray)
	var tw := root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(root, "scale", Vector2(5.0, 5.0), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "rotation", 1.2, 0.8)
	tw.tween_property(root, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(root.queue_free)

## Lingering radioactive cloud that ticks damage on anything inside.
static func fallout_cloud(at: Vector2, radius: float, dps: float, duration: float, src: String = "radiation") -> void:
	var scene := _root()
	if scene == null:
		return
	var n := Node2D.new()
	n.global_position = at
	n.z_index = 4
	n.set_script(load("res://scripts/weapons/fx/FalloutCloud.gd"))
	n.radius = radius
	n.dps = dps
	n.life = duration
	n.src = src
	scene.call_deferred("add_child", n)

## Ice shatter burst: shards + pale ring.
static func shatter_burst(at: Vector2, radius: float = 90.0) -> void:
	shockwave(at, radius, Color(0.8, 0.97, 1.0, 0.9), 3.0, 0.3)
	sparks(at, 18, Color(0.85, 0.98, 1.0), 220.0, 0.45)
	debris(at, Color(0.75, 0.92, 1.0), 8, 120.0, 5.0)
	AudioManager.play("freeze", 0.8, -4.0)
