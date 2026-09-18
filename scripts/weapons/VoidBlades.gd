extends WeaponBase
## VOID — persistent orbiting blades; always on. L3: faster spin. L5: periodic outward lash.

var _rig: Node2D = null
var _angle := 0.0
var _hit_cd: Dictionary = {}
var _lash_timer := 0.0
var _lash := 0.0     # 0..1 extension amount
var _t := 0.0

func on_level_changed(_old: int, new_lv: int) -> void:
	if new_lv > 0 and _rig == null:
		_rig = Node2D.new()
		_rig.top_level = true
		_rig.z_index = 6
		_rig.set_script(load("res://scripts/weapons/fx/BladeRig.gd"))
		add_child(_rig)
	if _rig:
		_rig.visible = new_lv > 0 and not suppressed
		_rig.blade_count = _count()
		_rig.blade_len = _len()
		_rig.color = color()

func on_suppressed(on: bool) -> void:
	if _rig:
		_rig.visible = not on

func _count() -> int:
	var c: int = [2, 3, 3, 4, 4][clampi(level - 1, 0, 4)]
	return c + extra()

func _radius() -> float:
	# L2: orbit coverage step.
	return (46.0 + level * 6.0 + (10.0 if level >= 2 else 0.0)) * area_mult()

func _len() -> float:
	return 17.0 + level * 3.0 + (6.0 if level >= 4 else 0.0)

func _spin() -> float:
	# L3: sweep frequency step. (Fire Rate does not drive the spin, so no physics spam.)
	return 3.2 + level * 0.45 + (1.6 if level >= 3 else 0.0)

func tick(delta: float) -> void:
	if level <= 0 or suppressed or _rig == null:
		return
	_t += delta
	var before := _angle
	_angle += delta * _spin()
	if is_max() and int(before / TAU) != int(_angle / TAU) and int(_angle / TAU) % 2 == 0:
		_void_shockwave()
	_rig.global_position = player.global_position
	_rig.rotation = _angle
	_rig.blade_count = _count()
	if is_max():
		_lash_timer -= delta
		if _lash_timer <= 0.0:
			_lash_timer = 2.4
			_lash = 1.0
			sfx("blade", 0.8, -4.0)
			WeaponFX.pulse(player.global_position, _radius(), _radius() * 2.2, color(), 0.35, 8.0)
		_lash = maxf(0.0, _lash - delta * 1.8 / float(player.duration_mult))
	var reach: float = _radius() * (1.0 + _lash * 1.1)
	_rig.orbit = reach
	_rig.lash = _lash
	# Contact damage: enemies near any blade sweep.
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.1
	var n := _count()
	var blade_dmg := dmg(0.34 + level * 0.08) * (1.6 if _lash > 0.2 else 1.0)
	for e in in_radius(player.global_position, reach + _len() + 14.0):
		var rel: Vector2 = e.global_position - player.global_position
		var d := rel.length()
		var ea := rel.angle()
		var hit_any := false
		# Inside the orbit the blades sweep across a wide arc (the disc), so a swarm pressed
		# against the hull is shredded too; on the ring itself the band is narrow.
		var inside: bool = d < reach - _len() * 0.7
		var window: float = 1.15 if inside else 0.42
		for i in range(n):
			var ba := _angle + float(i) * TAU / float(n)
			if absf(wrapf(ea - ba, -PI, PI)) < window:
				hit_any = true
				break
		if not hit_any:
			continue
		var key: int = e.get_instance_id()
		if _hit_cd.has(key) and _t - float(_hit_cd[key]) < 0.22:
			continue
		_hit_cd[key] = _t
		hit(e, blade_dmg)
		VFX.hit(e.global_position, false, Color(0.7, 0.38, 1.0, 0.95))
		# Void control: light shove outward along the blade sweep; elites stagger, bosses never move.
		var out_dir: Vector2 = rel.normalized() if d > 1.0 else Vector2.RIGHT
		var kb: float = (1.0 if level < 3 else 1.3) * (0.85 if d < reach - _len() * 0.7 else 1.0)
		player.apply_control(e, out_dir, 34.0 * kb, 20.0 * kb, 5.0, 0.28 if level >= 3 else 0.2)
		# L4: void wake — a second, weaker tick for enemies caught behind the sweep.
		if level >= 4 and randf() < 0.5:
			var wake := world_node(e.global_position, 4)
			wake.set_script(load("res://scripts/weapons/fx/VoidWake.gd"))
			wake.weapon = self
			wake.damage = blade_dmg * 0.4
		if randf() < 0.3:
			sfx("blade", 1.0 + randf_range(-0.1, 0.1), -12.0)


## L5: every second full sweep detonates a short-range Void Shockwave around the ship.
func _void_shockwave() -> void:
	var r: float = _radius() * 1.7
	WeaponFX.pulse(player.global_position, _radius() * 0.6, r, Color(0.75, 0.4, 1.0), 0.4, 14.0)
	VFX.shockwave(player.global_position, r, Color(0.9, 0.7, 1.0, 0.8), 3.0, 0.35)
	sfx("phase", 0.7, -6.0)
	var d := dmg(1.2 + level * 0.1)
	for e in in_radius(player.global_position, r):
		hit(e, d)
		var out_dir: Vector2 = (e.global_position - player.global_position).normalized()
		player.apply_control(e, out_dir, 40.0, 26.0, 6.0, 0.3)
