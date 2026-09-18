extends Node2D
## Frozen Singularity body: pull + freeze + tick, collapse every 5s.
var weapon: WeaponBase = null
var radius := 240.0
var _t := 0.0
var _tick := 0.0
var _cycle := 0.0
var _collapse := 0.0
var _debris: Array = []

func _ready() -> void:
	z_index = 6
	for i in range(30):
		_debris.append([randf() * TAU, randf_range(0.3, 1.0), randf_range(0.6, 1.6)])

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	_t += delta
	_cycle += delta
	_tick -= delta
	var strength := 170.0 + (1.0 if _collapse > 0.0 else 0.0) * 400.0
	if weapon:
		for e in weapon.in_radius(global_position, radius):
			if e is CharacterBody2D:
				var d := global_position.distance_to(e.global_position)
				if d > 14.0:
					PullSafety.pull(e, global_position, strength, delta, 0.4 + 0.6 * (1.0 - d / radius))
			if "chill_timer" in e:
				e.chill_timer = 0.5
				e.chill_factor = 0.4
		if _tick <= 0.0:
			_tick = 0.35
			for e in weapon.in_radius(global_position, radius * 0.7):
				weapon.hit(e, weapon.dmg(0.35), weapon.id, false, false)
				if e.has_method("apply_freeze_progress"):
					e.apply_freeze_progress(0.8, 1.6)
				weapon.status(e, "chilled", 1.0, 0.35)
	if _collapse > 0.0:
		_collapse -= delta
		if _collapse <= 0.0:
			_shatter()
	elif _cycle >= 5.0:
		_cycle = 0.0
		_collapse = 0.6
		AudioManager.play("mine", 0.5, -4.0)
	queue_redraw()

func _shatter() -> void:
	VFX.shatter_burst(global_position, radius * 0.9)
	VFX.shockwave(global_position, radius * 1.4, Color(0.8, 0.95, 1.0, 0.9), 5.0, 0.5)
	VFX.screen_shake(7.0)
	VFX.postfx_punch(0.7)
	AudioManager.play("big_boom", 1.4, -4.0)
	if weapon:
		for e in weapon.in_radius(global_position, radius):
			var frozen: bool = "frozen_timer" in e and float(e.frozen_timer) > 0.0
			weapon.hit(e, weapon.dmg(3.2) * (1.6 if frozen else 1.0))
			if e is CharacterBody2D:
				e.global_position += (e.global_position - global_position).normalized() * 80.0

func _draw() -> void:
	var k := clampf(_collapse / 0.6, 0.0, 1.0) if _collapse > 0.0 else 0.0
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.8, 1.0, 0.05))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.7, 0.95, 1.0, 0.35), 1.5)
	# Accretion debris spiralling in
	for d in _debris:
		var prog: float = fmod(float(d[1]) - _t * 0.18 * float(d[2]), 1.0)
		if prog < 0.0:
			prog += 1.0
		var ang: float = float(d[0]) + (1.0 - prog) * 5.0 + _t * 0.6
		var p := Vector2.from_angle(ang) * radius * (0.12 + prog * 0.85)
		draw_circle(p, 1.5 + (1.0 - prog) * 2.5, Color(0.8, 0.95, 1.0, 0.5 + (1.0 - prog) * 0.4))
	# Rings + core
	var core_r := 26.0 * (1.0 - k * 0.6)
	for i in range(3):
		var rr := core_r + 12.0 + i * 10.0 + sin(_t * 3.0 + i) * 2.0
		draw_arc(Vector2.ZERO, rr, _t * (1.5 + i * 0.4), _t * (1.5 + i * 0.4) + 4.0, 32, Color(0.75, 0.9, 1.0, 0.55 - i * 0.12), 2.0)
	draw_circle(Vector2.ZERO, core_r + 6.0, Color(0.5, 0.85, 1.0, 0.35 + k * 0.4))
	draw_circle(Vector2.ZERO, core_r, Color(0.01, 0.01, 0.04, 1.0))
	# Frost crystals on the horizon
	for i in range(8):
		var a := i * TAU / 8.0 + _t * 0.3
		var p := Vector2.from_angle(a) * (core_r + 3.0)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2.from_angle(a + 0.35) * 8.0, p + Vector2.from_angle(a) * 12.0, p + Vector2.from_angle(a - 0.35) * 8.0]), Color(0.85, 0.97, 1.0, 0.8))
