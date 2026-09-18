extends WeaponBase
## ENERGY — sustained beam that sweeps onto the target and keeps burning.
## L3: burn DoT. L5: refracts off the first enemy into a second beam.

var _beam: WeaponFX.Beam = null
var _refract: WeaponFX.Beam = null
var _hit_this_tick: Array = []

func cooldown() -> float:
	return maxf(1.1, 2.6 - level * 0.2)

func _duration() -> float:
	return (0.65 + level * 0.09 + (0.25 if is_max() else 0.0)) * float(player.duration_mult)

func fire() -> void:
	var a := aim()
	if a[0] == null and not manual():
		timer = 0.2
		return
	var dir: Vector2 = a[1]
	var start: float = player.rotation - PI / 2.0 + randf_range(-0.9, 0.9)
	var reach: float = 520.0 + level * 45.0 + float(player.pierce) * 40.0
	var width := (7.0 + level * 1.6) * size_mult()
	sfx("laser", 1.0, -6.0)
	_beam = WeaponFX.beam(player, start, dir.angle(), reach, width, color(), _duration(), _on_beam_tick, 9.0 + level * 1.5, 0.09)
	_beam.set_meta("target", a[0])
	VFX.postfx_punch(0.15)
	player._notify_weapon_vfx("laser")

func _on_beam_tick(origin: Vector2, dir: Vector2) -> void:
	if _beam == null or not is_instance_valid(_beam):
		return
	# Track the target after the initial sweep.
	var t = _beam.get_meta("target")
	if is_instance_valid(t) and not manual():
		_beam.target_angle = (t.global_position - origin).angle()
	elif manual():
		_beam.target_angle = aim_dir().angle()
	var per_tick := dmg(0.32 + level * 0.06)
	var first: Node2D = null
	var first_d := INF
	for e in in_line(origin, dir, _beam.reach, _beam.width * 0.6):
		hit(e, per_tick)
		VFX.hit(e.global_position, false, Color(1.0, 0.35, 0.4, 0.9))
		if level >= 3 or player.burn_tier > 0:
			status(e, "burn", 1.6 + level * 0.2 + player.burn_tier * 0.4, dmg(0.10 + level * 0.02 + player.burn_tier * 0.04))
		var d := origin.distance_squared_to(e.global_position)
		if d < first_d:
			first_d = d
			first = e
	if is_max() and first != null:
		_refract_from(first, per_tick * 0.7)

func _refract_from(first: Node2D, per_tick: float) -> void:
	var second := nearest(260.0, [first], first.global_position)
	if second == null:
		return
	var a := first.global_position
	var b := second.global_position
	WeaponFX.bolt(a, b, Color(1.0, 0.5, 0.55), 5.0, 0.1)
	hit(second, per_tick)
	status(second, "burn", 1.5, dmg(0.1))
	VFX.hit(b, false, Color(1.0, 0.35, 0.4, 0.9))
