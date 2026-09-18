extends WeaponBase
## ORDNANCE — volleys of missiles that swing wide on launch and then curve in.
## L3: warhead blast. L5: split into two micro-seekers on impact.

var _side := 1.0

func cooldown() -> float:
	return maxf(0.55, 1.7 - level * 0.16 - (0.15 if level >= 4 else 0.0))

func fire() -> void:
	var count: int = [2, 2, 3, 3, 4][clampi(level - 1, 0, 4)] + extra()
	var a := aim()
	var base: Vector2 = a[1]
	sfx("missile", 1.0, -6.0)
	for i in range(count):
		_side *= -1.0
		var swing: float = 0.75 + float(i) * 0.12
		var dir := base.rotated(swing * _side)
		var pos: Vector2 = player.global_position + Vector2(_side * 14.0, 6.0).rotated(player.rotation)
		var p: Area2D = player._spawn_proj(pos, dir, dmg(0.62 + level * 0.09), int(player.pierce), 1.2, id)
		if p == null:
			continue
		p.speed = player.projectile_speed * 0.72
		p.homing_enabled = true
		p.homing_range = 420.0 + level * 30.0
		p.homing_turn_rate = 3.6 + level * 0.5
		p.homing_target = a[0]
		p.lifetime = 3.2
		if level >= 3:
			p.explode = true
			p.explode_radius = (28.0 + level * 3.0) * area_mult()
			p.explode_damage = dmg(0.35) * player.explode_damage_mult
		if is_max():
			p.split_count = 1
		VFX.smoke(pos, 2, Color(0.6, 0.6, 0.65, 0.3), 5.0)
	player._notify_weapon_vfx("missile")
