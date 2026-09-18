extends WeaponBase
## ORDNANCE — deploys drifting mines that arm, drag enemies in, then detonate.
## L5: mines collapse into a brief singularity before detonating.

func cooldown() -> float:
	return maxf(1.4, 3.0 - level * 0.22)

func fire() -> void:
	var count: int = [2, 2, 3, 3, 4][clampi(level - 1, 0, 4)] + extra()
	var a := aim()
	var base: Vector2 = a[1]
	sfx("mine", 1.0, -6.0)
	for i in range(count):
		var spread := (float(i) - float(count - 1) * 0.5) * 0.55
		var dir := base.rotated(spread)
		var m := Node2D.new()
		m.set_script(load("res://scripts/weapons/fx/GravMine.gd"))
		m.global_position = player.global_position + dir * 30.0
		m.velocity = dir * (230.0 + level * 16.0)
		m.weapon = self
		m.pull_radius = (100.0 + level * 10.0) * area_mult()
		m.blast_radius = (75.0 + level * 9.0) * area_mult()
		m.pull_strength = (120.0 + level * 30.0) * area_mult()
		m.arm_time = maxf(0.3, 0.55 - level * 0.06)
		m.pull_time = (1.1 + level * 0.1) * float(player.duration_mult)
		m.damage = dmg(1.5 + level * 0.25) * player.explode_damage_mult
		m.singularity = is_max()
		m.color = color()
		GameManager.spawn(m)
		VFX.muzzle_flash(player.global_position + dir * 14.0, dir, Color(0.75, 0.5, 1.0), 0.7)
