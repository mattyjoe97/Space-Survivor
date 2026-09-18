class_name WeaponFX
extends RefCounted

## Reusable animated effect nodes for weapons (lightning, beams, cones, rings).

static func _root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return GameManager.world_root() if tree else null

## Jagged, flickering lightning bolt between two world points.
class LightningBolt extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var col := Color(0.55, 0.85, 1.0)
	var width := 3.0
	var life := 0.18
	var max_life := 0.18
	var _pts := PackedVector2Array()
	var _jit := 0.0
	func _ready() -> void:
		z_index = 40
		_regen()
	func _regen() -> void:
		_pts.clear()
		var segs: int = clampi(int(a.distance_to(b) / 18.0), 3, 16)
		var n := (b - a).normalized()
		var p := Vector2(-n.y, n.x)
		for i in range(segs + 1):
			var t := float(i) / float(segs)
			var off := 0.0 if (i == 0 or i == segs) else randf_range(-1.0, 1.0) * 10.0 * sin(t * PI)
			_pts.append(a.lerp(b, t) + p * off)
	func _process(delta: float) -> void:
		life -= delta
		_jit -= delta
		if _jit <= 0.0:
			_jit = 0.03
			_regen()
		if life <= 0.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var f := clampf(life / max_life, 0.0, 1.0)
		var local := PackedVector2Array()
		for q in _pts:
			local.append(to_local(q))
		draw_polyline(local, Color(col.r, col.g, col.b, 0.25 * f), width * 3.0)
		draw_polyline(local, Color(col.r, col.g, col.b, 0.9 * f), width)
		draw_polyline(local, Color(1, 1, 1, 0.9 * f), width * 0.35)

static func bolt(a: Vector2, b: Vector2, col: Color, width: float = 3.0, life: float = 0.18) -> void:
	var r := _root()
	if r == null:
		return
	var n := LightningBolt.new()
	n.a = a; n.b = b; n.col = col; n.width = width; n.life = life; n.max_life = life
	n.global_position = a
	r.add_child(n)

## Persistent beam that follows an origin node and slews toward a target angle.
class Beam extends Node2D:
	var origin_node: Node2D = null
	var angle := 0.0
	var target_angle := 0.0
	var slew := 9.0            # rad/s
	var reach := 600.0
	var width := 10.0
	var col := Color(1.0, 0.25, 0.35)
	var life := 0.7
	var max_life := 0.7
	var on_tick: Callable       # (origin: Vector2, dir: Vector2) called every tick_interval
	var tick_interval := 0.1
	var _tick := 0.0
	var _t := 0.0
	var fade_in := 0.08
	func _ready() -> void:
		z_index = 45
		top_level = true
	func _process(delta: float) -> void:
		if not is_instance_valid(origin_node):
			queue_free(); return
		_t += delta
		life -= delta
		var d := wrapf(target_angle - angle, -PI, PI)
		angle += clampf(d, -slew * delta, slew * delta)
		global_position = origin_node.global_position
		_tick -= delta
		if _tick <= 0.0:
			_tick = tick_interval
			if on_tick.is_valid():
				on_tick.call(global_position, Vector2.from_angle(angle))
		if life <= 0.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var f: float = clampf(life / 0.15, 0.0, 1.0) * clampf(_t / fade_in, 0.0, 1.0)
		var d := Vector2.from_angle(angle)
		var end := d * reach
		var w := width * (0.9 + 0.1 * sin(_t * 40.0))
		draw_line(Vector2.ZERO, end, Color(col.r, col.g, col.b, 0.18 * f), w * 3.2)
		draw_line(Vector2.ZERO, end, Color(col.r, col.g, col.b, 0.75 * f), w)
		draw_line(Vector2.ZERO, end, Color(1, 0.95, 0.95, 0.95 * f), w * 0.3)
		draw_circle(Vector2.ZERO, w * 1.2, Color(1, 1, 1, 0.8 * f))
		draw_circle(end, w * 0.9, Color(col.r, col.g, col.b, 0.6 * f))
		# travelling energy pulses
		for i in range(4):
			var s := fmod(_t * 2.2 + i * 0.25, 1.0)
			draw_circle(d * reach * s, w * 0.55, Color(1, 1, 1, 0.35 * f * (1.0 - s)))

static func beam(origin: Node2D, angle: float, target_angle: float, reach: float, width: float, col: Color, life: float, on_tick: Callable, slew: float = 9.0, tick_interval: float = 0.1) -> Beam:
	var r := _root()
	if r == null:
		return null
	var b := Beam.new()
	b.origin_node = origin
	b.angle = angle
	b.target_angle = target_angle
	b.reach = reach
	b.width = width
	b.col = col
	b.life = life
	b.max_life = life
	b.on_tick = on_tick
	b.slew = slew
	b.tick_interval = tick_interval
	r.add_child(b)
	return b

## Expanding translucent shock ring drawn as a polygon annulus.
class PulseRing extends Node2D:
	var r0 := 10.0
	var r1 := 120.0
	var col := Color(0.4, 0.9, 1.0)
	var life := 0.35
	var max_life := 0.35
	var thickness := 12.0
	func _ready() -> void:
		z_index = 9
	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var t := 1.0 - clampf(life / max_life, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - t, 2.5)
		var r := lerpf(r0, r1, e)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.55 * (1.0 - t)), thickness * (1.0 - t * 0.7))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1, 1, 1, 0.5 * (1.0 - t)), 1.5)

static func pulse(at: Vector2, r0: float, r1: float, col: Color, life: float = 0.35, thickness: float = 12.0) -> void:
	var r := _root()
	if r == null:
		return
	var n := PulseRing.new()
	n.global_position = at
	n.r0 = r0; n.r1 = r1; n.col = col; n.life = life; n.max_life = life; n.thickness = thickness
	r.add_child(n)
