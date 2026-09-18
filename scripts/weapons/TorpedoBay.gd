extends WeaponBase
## ORDNANCE — slow heavy torpedoes that accelerate and detonate in a huge blast with knockback.
## L5: torpedoes burst into 3 cluster bomblets.

func cooldown() -> float:
	return maxf(1.5, 3.2 - level * 0.22)

func fire() -> void:
	var count: int = (2 if level >= 3 else 1) + extra()
	var a := aim()
	var dir: Vector2 = a[1]
	sfx("torpedo", 1.0, -3.0)
	for i in range(count):
		var off := (float(i) - float(count - 1) * 0.5) * 22.0
		var side := Vector2(-dir.y, dir.x) * off
		var t := Node2D.new()
		t.set_script(load("res://scripts/weapons/fx/Torpedo.gd"))
		t.global_position = player.global_position + dir * 24.0 + side
		t.direction = dir
		t.weapon = self
		t.target = a[0]
		t.blast_radius = (110.0 + level * 14.0) * area_mult()
		t.damage = dmg(2.6 + level * 0.45) * player.explode_damage_mult
		t.accel = 460.0 + level * 70.0 + (200.0 if level >= 4 else 0.0)
		t.set_meta("turn", 1.4 + player.homing_tier * 1.2)
		t.scale = Vector2.ONE * size_mult()
		t.cluster = level >= 4
		t.set_meta("bomblets", 3 if is_max() else 2)
		GameManager.spawn(t)
		VFX.smoke(t.global_position, 3, Color(0.6, 0.6, 0.65, 0.4), 8.0)
	VFX.screen_shake(1.5)
	player._notify_weapon_vfx("missile")
