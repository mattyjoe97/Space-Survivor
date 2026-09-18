extends WeaponBase
## ENERGY — drops a stationary coil turret behind the ship that zaps enemies in range until it burns out.
## L3: zaps 2 targets. L4: 2 coils. L5: nearby coils link a lightning wall.

var _coils: Array = []

func cooldown() -> float:
	return maxf(2.2, 4.4 - level * 0.3)

func _max_coils() -> int:
	return (3 if level >= 5 else (2 if level >= 3 else 1)) + extra()

func fire() -> void:
	_coils = _coils.filter(func(c): return is_instance_valid(c))
	if _coils.size() >= _max_coils():
		# Redeploy: if every coil is out of the fight, the farthest one burns out early.
		var far: Node2D = null
		var far_d := 0.0
		for c in _coils:
			var dd: float = c.global_position.distance_to(player.global_position)
			if dd > far_d:
				far_d = dd; far = c
		if far and far_d > 420.0:
			far.uptime = 0.0
			_coils.erase(far)
		else:
			timer = 0.4
			return
	var back := -Vector2.from_angle(player.rotation - PI / 2.0)
	var pos: Vector2 = player.global_position + back * 40.0 + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	var c := Node2D.new()
	c.set_script(load("res://scripts/weapons/fx/TeslaTurret.gd"))
	c.global_position = pos
	c.weapon = self
	c.range_px = (200.0 + level * 20.0) * area_mult()
	c.uptime = (5.0 + level * 0.9) * float(player.duration_mult)
	c.zap_interval = maxf(0.2, 0.36 - level * 0.04)
	c.targets = 1 + level / 2
	c.damage = dmg(1.0 + level * 0.2)
	c.link = is_max()
	GameManager.spawn(c)
	_coils.append(c)
	sfx("tesla", 0.7, -5.0)
	VFX.smoke(pos, 4, Color(0.5, 0.6, 0.7, 0.3), 8.0)
	VFX.shockwave(pos, 40.0, Color(0.6, 0.9, 1.0, 0.8), 2.0, 0.25)

func linked_coils() -> Array:
	return _coils.filter(func(c): return is_instance_valid(c))
