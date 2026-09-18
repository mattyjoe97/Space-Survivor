extends WeaponBase
## VOID — fires an expanding phase wave that passes through enemies, marking them "phased".
## Phased enemies take extra damage from everything. L3: shoved back. L5: marks collapse into rifts.

func cooldown() -> float:
	return maxf(1.4, 2.8 - level * 0.2)

func bonus() -> float:
	var b: float = [0.15, 0.20, 0.20, 0.25, 0.30][clampi(level - 1, 0, 4)]
	return b

func fire() -> void:
	var a := aim()
	var dir: Vector2 = a[1]
	sfx("phase", 1.0, -4.0)
	var w := Node2D.new()
	w.set_script(load("res://scripts/weapons/fx/PhaseWave.gd"))
	w.global_position = player.global_position + dir * 18.0
	w.direction = dir
	w.weapon = self
	w.half_width = (34.0 + level * 8.0) * area_mult()
	w.reach = 520.0 + level * 40.0 + float(player.pierce) * 60.0
	w.damage = dmg(0.9 + level * 0.15)
	w.mark_time = (3.0 + level * 0.4) * float(player.duration_mult)
	w.mark_bonus = bonus()
	w.shove = 46.0 if level >= 3 else 0.0
	w.rift = is_max()
	GameManager.spawn(w)
	VFX.postfx_punch(0.2)
	VFX.shockwave(player.global_position, 40.0, Color(0.85, 0.45, 1.0, 0.8), 2.0, 0.2)
