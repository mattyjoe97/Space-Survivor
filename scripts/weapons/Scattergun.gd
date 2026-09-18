extends WeaponBase
## KINETIC — close-range spray of photon pellets that ricochet into new targets.
## L5: double ricochet and a double-tap.

var _second_tap := false

func cooldown() -> float:
	return maxf(0.55, 1.25 - level * 0.12)

func _pellets() -> int:
	var n: int = [5, 6, 7, 8, 9][clampi(level - 1, 0, 4)]
	return n + extra() * 3

func fire() -> void:
	_blast()
	if is_max():
		get_tree().create_timer(0.14).timeout.connect(func():
			if is_instance_valid(self) and level > 0 and not suppressed:
				_second_tap = true
				_blast()
				_second_tap = false)

func _blast() -> void:
	var a := aim()
	var dir: Vector2 = a[1]
	var n := _pellets()
	var cone := 0.32 + level * 0.03
	sfx("scatter", 1.0 + randf_range(-0.08, 0.08), -4.0)
	VFX.muzzle_flash(player.global_position + dir * 20.0, dir, Color(1.0, 0.95, 0.5), 1.6)
	VFX.sparks(player.global_position + dir * 22.0, 8, Color(1.0, 0.95, 0.5), 220.0, 0.25, dir, 50.0)
	for i in range(n):
		var ang := dir.angle() + randf_range(-cone, cone)
		var p: Area2D = player._spawn_proj(player.global_position + dir * 16.0, Vector2.from_angle(ang), dmg(0.30 + level * 0.05) * (0.7 if _second_tap else 1.0), int(player.pierce), 0.65, id)
		if p == null:
			continue
		p.speed = player.projectile_speed * randf_range(1.3, 1.7)
		p.lifetime = 0.34 + level * 0.02
		p.ricochet = (2 if is_max() else (1 if level >= 3 else 0)) + int(player.pierce)
		if player.explode_on_hit:
			p.explode = true
			p.explode_radius = 28.0
		var poly: Polygon2D = p.get_node_or_null("Polygon2D")
		if poly:
			poly.polygon = PackedVector2Array([Vector2(5, 0), Vector2(0, -3), Vector2(-4, 0), Vector2(0, 3)])
			poly.color = Color(1.0, 0.95, 0.55)
			p.get_node("Glow").color = Color(1.0, 0.85, 0.3, 0.45)
	player.visual_recoil(dir, 3.0)
	VFX.screen_shake(1.6)
	player._notify_weapon_vfx("bullet")
