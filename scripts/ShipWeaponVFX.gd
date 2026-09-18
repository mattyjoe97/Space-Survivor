extends Node2D

## Modular ship weapon hardware and combat feedback.
## Procedural only: the ship grows new machinery as the player upgrades.

var bullet_flash: float = 0.0
var missile_flash: float = 0.0
var laser_charge: float = 0.0
var arc_charge: float = 0.0
var last_fire_time: float = 0.0

func _process(delta: float) -> void:
	bullet_flash = maxf(0.0, bullet_flash - delta * 7.0)
	missile_flash = maxf(0.0, missile_flash - delta * 4.5)
	laser_charge = maxf(0.0, laser_charge - delta * 1.7)
	arc_charge = maxf(0.0, arc_charge - delta * 2.8)
	queue_redraw()

func weapon_fired(kind: String) -> void:
	match kind:
		"bullet": bullet_flash = 1.0
		"missile": missile_flash = 1.0
		"laser": laser_charge = 1.0
		"arc": arc_charge = 1.0
	last_fire_time = Time.get_ticks_msec() * 0.001

func _draw() -> void:
	var ship = get_parent()
	if ship == null:
		return

	var t: float = Time.get_ticks_msec() * 0.001
	var pulse: float = 0.5 + 0.5 * sin(t * 5.0)
	var slow_pulse: float = 0.5 + 0.5 * sin(t * 2.2)

	var projectile_count: int = int(ship.get("projectile_count"))
	var side_guns: int = int(ship.get("side_guns"))
	var missile_level: int = int(ship.get("missile_level"))
	var laser_level: int = int(ship.get("laser_level"))
	var arc_level: int = int(ship.get("arc_level"))
	var bullet_hell: bool = bool(ship.get("evo_bullet_hell"))
	var homing: bool = bool(ship.get("evo_homing_array"))
	var plasma: bool = bool(ship.get("evo_plasma_cutter"))
	var chain: bool = bool(ship.get("evo_chain_reaction"))

	# Subtle mechanical rails make the modules feel mounted to the hull.
	if projectile_count > 1 or side_guns > 0 or bullet_hell:
		_draw_weapon_rail(Vector2(-16, 7), -1.0, 1.0)
		_draw_weapon_rail(Vector2(16, 7), 1.0, 1.0)

	# Primary gun battery: increasingly substantial hardpoints.
	var cannon_count: int = clampi(projectile_count - 1, 0, 7)
	if bullet_hell:
		cannon_count = mini(9, cannon_count + 3)
	for i in range(cannon_count):
		var x: float = 0.0
		if cannon_count > 1:
			x = lerpf(-18.0, 18.0, float(i) / float(cannon_count - 1))
		var y: float = 7.5 + absf(x) * 0.10
		_draw_cannon(Vector2(x, y), 0.86 + (0.10 if bullet_hell else 0.0), bullet_flash)

	for i in range(side_guns):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var row: float = float(i / 2)
		_draw_side_turret(Vector2(side * (18.0 + row * 6.0), 3.0 + row * 7.0), side, bullet_flash)

	# Missile system: armored launch racks, visible warheads and targeting fins.
	if missile_level > 0:
		var pods: int = 1 + int((missile_level - 1) / 2) + (1 if homing else 0)
		pods = mini(pods, 4)
		for i in range(pods):
			var side: float = -1.0 if i % 2 == 0 else 1.0
			var row: float = float(i / 2)
			var pos := Vector2(side * (15.0 + row * 8.0), -1.5 - row * 8.0)
			_draw_missile_rack(pos, side, missile_level, homing, pulse, missile_flash)

	# Plasma emitter: a proper focusing assembly rather than a simple rectangle.
	if laser_level > 0:
		_draw_plasma_emitter(laser_level, plasma, slow_pulse, laser_charge)

	# Arc hardware: capacitors + conductor bands around the ship.
	if arc_level > 0:
		var coil_count: int = mini(4, 2 + int(arc_level / 2) + (1 if chain else 0))
		for i in range(coil_count):
			var side: float = -1.0 if i % 2 == 0 else 1.0
			var row: float = float(i / 2)
			var pos := Vector2(side * (19.0 + row * 6.0), 3.0 - row * 8.0)
			_draw_arc_coil(pos, side, arc_level, chain, pulse, arc_charge)
		if chain:
			_draw_conductor_network(arc_charge, pulse)

func _draw_weapon_rail(pos: Vector2, side: float, scale_mult: float) -> void:
	var p := PackedVector2Array([
		pos + Vector2(0, -2),
		pos + Vector2(side * 17, -2),
		pos + Vector2(side * 20, 1),
		pos + Vector2(side * 2, 1)
	])
	draw_colored_polygon(p, Color(0.16, 0.30, 0.40, 0.9))
	draw_line(pos + Vector2(1 * side, -1), pos + Vector2(18 * side, -1), Color(0.45, 0.78, 0.92, 0.55), 1.2)

func _draw_cannon(pos: Vector2, scale_mult: float, flash: float) -> void:
	# Housing
	var housing := PackedVector2Array([
		pos + Vector2(-3.5, 3) * scale_mult,
		pos + Vector2(3.5, 3) * scale_mult,
		pos + Vector2(3, -1) * scale_mult,
		pos + Vector2(2, -5) * scale_mult,
		pos + Vector2(-2, -5) * scale_mult,
		pos + Vector2(-3, -1) * scale_mult
	])
	draw_colored_polygon(housing, Color(0.20, 0.34, 0.43, 1.0))
	draw_polyline(housing, Color(0.55, 0.82, 0.94, 0.75), 1.0)
	# Barrel
	draw_rect(Rect2(pos.x - 1.45 * scale_mult, pos.y - 10 * scale_mult, 2.9 * scale_mult, 7 * scale_mult), Color(0.72, 0.86, 0.92, 1.0))
	draw_circle(pos + Vector2(0, -10) * scale_mult, 2.2 * scale_mult, Color(0.35, 0.65, 0.78, 1.0))
	if flash > 0.0:
		var f: float = flash * (0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.05))
		draw_circle(pos + Vector2(0, -11) * scale_mult, (5.0 + 7.0 * f) * scale_mult, Color(1.0, 0.68, 0.24, 0.10 * f))
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-2, -11), pos + Vector2(2, -11), pos + Vector2(0, -18 - 8 * f)
		]), Color(1.0, 0.82, 0.42, 0.65 * f))

func _draw_side_turret(pos: Vector2, side: float, flash: float) -> void:
	draw_circle(pos, 5.0, Color(0.12, 0.23, 0.30, 1.0))
	draw_arc(pos, 5.0, 0.0, TAU, 12, Color(0.48, 0.78, 0.90, 0.9), 1.1)
	draw_line(pos, pos + Vector2(0, -9), Color(0.80, 0.91, 0.96, 1.0), 2.0)
	if flash > 0.0:
		draw_circle(pos + Vector2(0, -10), 4.0 + flash * 5.0, Color(1.0, 0.75, 0.35, flash * 0.20))

func _draw_missile_rack(pos: Vector2, side: float, level: int, evolved: bool, pulse: float, flash: float) -> void:
	var w: float = 5.0 + minf(float(level), 5.0) * 0.45
	var body := PackedVector2Array([
		pos + Vector2(-w, 3), pos + Vector2(w, 3),
		pos + Vector2(w - 1, -4), pos + Vector2(0, -8), pos + Vector2(-w + 1, -4)
	])
	draw_colored_polygon(body, Color(0.12, 0.30, 0.43, 1.0))
	draw_polyline(body, Color(0.32, 0.72, 0.92, 0.9), 1.1)
	# Twin missile silhouettes at higher investment.
	var missile_count: int = 1 if level < 3 else 2
	for m in range(missile_count):
		var mx: float = -2.0 if missile_count == 2 and m == 0 else (2.0 if missile_count == 2 else 0.0)
		draw_line(pos + Vector2(mx, -1), pos + Vector2(mx, -8), Color(0.76, 0.94, 1.0, 0.95), 1.6)
		draw_circle(pos + Vector2(mx, -8), 1.6, Color(0.35, 0.90, 1.0, 0.95))
	if evolved:
		draw_arc(pos + Vector2(0, -2), 9.0 + pulse * 1.5, PI * 0.10, PI * 0.90, 10, Color(0.35, 0.92, 1.0, 0.5), 1.2)
	if flash > 0.0:
		draw_circle(pos + Vector2(0, -9), 3.0 + flash * 6.0, Color(0.25, 0.90, 1.0, flash * 0.18))

func _draw_plasma_emitter(level: int, evolved: bool, pulse: float, charge: float) -> void:
	var size: float = 1.0 + float(level) * 0.10 + (0.35 if evolved else 0.0)
	# Reinforced focusing collar.
	draw_arc(Vector2(0, -17), 6.0 * size, PI * 0.12, PI * 0.88, 12, Color(0.45, 0.68, 0.78, 0.9), 2.0)
	draw_arc(Vector2(0, -17), 4.0 * size, PI * 1.12, PI * 1.88, 12, Color(0.45, 0.68, 0.78, 0.75), 1.4)
	# Energy core.
	var core_r: float = 2.2 + pulse * 1.1 + charge * 3.0
	draw_circle(Vector2(0, -17), core_r + 3.0, Color(1.0, 0.16, 0.34, 0.08 + charge * 0.10))
	draw_circle(Vector2(0, -17), core_r, Color(1.0, 0.30, 0.42, 0.95))
	if evolved:
		draw_arc(Vector2(0, -17), 9.0 + pulse * 2.0, 0, TAU, 18, Color(1.0, 0.20, 0.38, 0.32), 1.5)
	# Small focusing fins.
	var fin := PackedVector2Array([Vector2(-5, -14), Vector2(-2, -19), Vector2(-5, -21)])
	draw_colored_polygon(fin, Color(0.42, 0.56, 0.64, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(5, -14), Vector2(2, -19), Vector2(5, -21)]), Color(0.42, 0.56, 0.64, 1.0))
	if charge > 0.0:
		var reach: float = 10.0 + charge * 12.0
		draw_line(Vector2(0, -20), Vector2(0, -20 - reach), Color(1.0, 0.34, 0.46, charge * 0.65), 2.2 + charge * 2.0)

func _draw_arc_coil(pos: Vector2, side: float, level: int, evolved: bool, pulse: float, charge: float) -> void:
	var r: float = 5.0 + minf(float(level), 5.0) * 0.45
	draw_circle(pos, r + 3.0, Color(0.22, 0.62, 0.90, 0.08 + charge * 0.10))
	draw_circle(pos, r, Color(0.08, 0.20, 0.29, 1.0))
	draw_arc(pos, r, 0, TAU, 14, Color(0.38, 0.80, 1.0, 0.95), 1.8)
	draw_arc(pos, r - 2.0, -1.1, 1.1, 8, Color(0.75, 0.97, 1.0, 0.8), 1.1)
	draw_circle(pos, 1.8 + pulse + charge * 2.0, Color(0.65, 0.95, 1.0, 0.95))
	if evolved:
		draw_arc(pos, r + 4.0 + charge * 2.0, -1.0, 1.0, 10, Color(0.35, 0.92, 1.0, 0.55), 1.2)
	if charge > 0.0:
		var jitter: float = sin(Time.get_ticks_msec() * 0.08 + pos.x) * 2.0
		draw_line(pos + Vector2(side * r, 0), pos + Vector2(side * (r + 7), jitter), Color(0.65, 0.96, 1.0, charge * 0.75), 1.5)

func _draw_conductor_network(charge: float, pulse: float) -> void:
	var a := Vector2(-20, 2)
	var b := Vector2(-8, -4)
	var c := Vector2(0, -1)
	var d := Vector2(9, -4)
	var e := Vector2(20, 2)
	var col := Color(0.38, 0.90, 1.0, 0.22 + pulse * 0.10 + charge * 0.40)
	draw_polyline(PackedVector2Array([a, b, c, d, e]), col, 1.4 + charge * 1.2)
	if charge > 0.0:
		var jitter := sin(Time.get_ticks_msec() * 0.11) * 2.0
		draw_line(b, c + Vector2(0, jitter), Color(0.75, 1.0, 1.0, charge * 0.75), 2.0)
