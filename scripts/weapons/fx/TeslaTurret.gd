extends Node2D
## Stationary tesla coil. Zaps enemies in range; at L5 links to other coils with a lightning wall.
var weapon: WeaponBase = null
var range_px := 180.0
var uptime := 6.0
var zap_interval := 0.35
var targets := 1
var damage := 8.0
var link := false
var _t := 0.0
var _zap := 0.0
var _wall_tick := 0.0
var _flash := 0.0

func _ready() -> void:
	z_index = 6
	add_to_group("tesla_coils")

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	_t += delta
	uptime -= delta
	_zap -= delta
	_flash = maxf(0.0, _flash - delta * 8.0)
	if uptime <= 0.0:
		VFX.sparks(global_position, 10, Color(0.6, 0.9, 1.0), 120.0, 0.4)
		VFX.smoke(global_position, 4, Color(0.4, 0.45, 0.5, 0.35), 10.0)
		queue_free()
		return
	if _zap <= 0.0 and weapon:
		_zap = zap_interval
		var n := 0
		var excl: Array = []
		for i in range(targets):
			var e := weapon.nearest(range_px, excl, global_position)
			if e == null:
				break
			excl.append(e)
			WeaponFX.bolt(global_position + Vector2(0, -18), e.global_position, Color(0.6, 0.92, 1.0), 3.0, 0.14)
			weapon.hit(e, damage)
			if "chill_timer" in e:
				e.chill_timer = 0.5; e.chill_factor = 0.7   # static: zapped enemies stutter
			VFX.hit(e.global_position, false, Color(0.6, 0.92, 1.0, 0.9))
			n += 1
		if n > 0:
			_flash = 1.0
			AudioManager.play("tesla", 1.0 + randf_range(-0.1, 0.1), -9.0)
	if link and weapon:
		_wall_tick -= delta
		if _wall_tick <= 0.0:
			_wall_tick = 0.25
			for other in weapon.linked_coils():
				if other == self or not is_instance_valid(other) or other.get_instance_id() < get_instance_id():
					continue
				var a: Vector2 = global_position + Vector2(0, -18)
				var b: Vector2 = other.global_position + Vector2(0, -18)
				if a.distance_to(b) > 420.0:
					continue
				WeaponFX.bolt(a, b, Color(0.7, 0.95, 1.0), 4.0, 0.22)
				var dir := (b - a).normalized()
				for e in weapon.in_line(a, dir, a.distance_to(b), 16.0):
					weapon.hit(e, damage * 0.8)
					VFX.hit(e.global_position, false, Color(0.7, 0.95, 1.0, 0.9))
	queue_redraw()

func _draw() -> void:
	var k := clampf(uptime / 1.5, 0.0, 1.0)
	# Range ring
	draw_arc(Vector2.ZERO, range_px, 0.0, TAU, 40, Color(0.6, 0.9, 1.0, 0.12 + _flash * 0.15), 1.0)
	# Base + tower
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 8), Vector2(12, 8), Vector2(8, 2), Vector2(-8, 2)]), Color(0.18, 0.22, 0.3))
	draw_line(Vector2(0, 2), Vector2(0, -16), Color(0.5, 0.6, 0.75), 4.0)
	for i in range(4):
		var y := -3.0 - i * 3.5
		draw_line(Vector2(-5, y), Vector2(5, y), Color(0.75, 0.9, 1.0, 0.8), 1.2)
	# Orb with crackle
	var orb := Vector2(0, -20)
	draw_circle(orb, 6.0 + _flash * 3.0, Color(0.85, 0.97, 1.0, 0.95 * (0.5 + 0.5 * k)))
	draw_circle(orb, 12.0 + sin(_t * 12.0) * 2.0, Color(0.6, 0.9, 1.0, 0.18 + _flash * 0.2))
	for i in range(3):
		var a := _t * 9.0 + i * TAU / 3.0
		draw_line(orb, orb + Vector2.from_angle(a) * (9.0 + randf() * 4.0), Color(0.8, 0.95, 1.0, 0.6), 1.0)
	# Uptime bar
	draw_rect(Rect2(Vector2(-10, 12), Vector2(20, 2)), Color(0.1, 0.12, 0.18))
	draw_rect(Rect2(Vector2(-10, 12), Vector2(20.0 * clampf(uptime / 8.0, 0.0, 1.0), 2)), Color(0.6, 0.9, 1.0))
