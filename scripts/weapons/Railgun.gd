extends WeaponBase
## KINETIC — visible charge-up, then a hyper-velocity slug across the whole arena.
## L3: knockback. L5: second perpendicular cross-rail.

var _charging := false
var _charge_t := 0.0
var _charge_node: Node2D = null

func cooldown() -> float:
	return maxf(1.1, 2.8 - level * 0.22)

func _charge_time() -> float:
	return maxf(0.32, 0.6 - level * 0.05)

func fire() -> void:
	# Start charge; the actual shot happens after _charge_time() in tick().
	_charging = true
	_charge_t = 0.0
	_charge_node = Node2D.new()
	_charge_node.set_script(load("res://scripts/weapons/fx/RailCharge.gd"))
	_charge_node.duration = _charge_time()
	player.add_child(_charge_node)
	sfx("laser", 0.55, -9.0)

func tick(delta: float) -> void:
	if level <= 0 or suppressed:
		return
	if _charging:
		_charge_t += delta
		if _charge_t >= _charge_time():
			_charging = false
			if is_instance_valid(_charge_node):
				_charge_node.queue_free()
			_shoot()
		return
	timer -= delta
	if timer <= 0.0:
		fire()
		timer = cooldown()

func _shoot() -> void:
	var a := aim()
	var dir: Vector2 = a[1]
	# Precision targeting: in auto mode, line up on the toughest enemy in range.
	if not manual():
		var best: Node2D = null
		var best_hp := 0.0
		for e in in_radius(player.global_position, 720.0):
			var hp := float(e.get("current_hp")) if e.get("current_hp") != null else 0.0
			if e.is_in_group("elites") or e.is_in_group("boss"):
				hp *= 3.0
			if hp > best_hp:
				best_hp = hp
				best = e
		if best:
			dir = (best.global_position - player.global_position).normalized()
	var reach: float = 900.0 + level * 60.0 + float(player.pierce) * 80.0
	var width: float = (7.0 + level * 1.6) * size_mult()
	_rail(dir, reach, width, dmg(2.6 + level * 1.15))
	if is_max():
		var perp := Vector2(-dir.y, dir.x)
		_rail(perp, reach * 0.8, width * 0.8, dmg(2.5))
		_rail(-perp, reach * 0.8, width * 0.8, dmg(2.5))
	sfx("railgun", 1.0, -2.0)
	VFX.screen_shake(4.0 + level * 0.5)
	VFX.postfx_punch(0.45)
	# Recoil nudge
	player.visual_recoil(dir, 6.0)
	VFX.muzzle_flash(player.global_position + dir * 22.0, dir, Color(0.85, 0.92, 1.0), 1.8)
	VFX.shockwave(player.global_position + dir * 22.0, 70.0, Color(0.8, 0.9, 1.0, 0.8), 3.0, 0.3)

func _rail(dir: Vector2, reach: float, width: float, damage: float) -> void:
	var origin: Vector2 = player.global_position
	var n := Node2D.new()
	n.set_script(load("res://scripts/weapons/fx/RailShot.gd"))
	n.global_position = origin
	n.rotation = dir.angle()
	n.reach = reach
	n.width = width
	GameManager.spawn(n)
	for e in in_line(origin, dir, reach, width * 0.9):
		var d := damage
		if e.is_in_group("elites") or e.is_in_group("boss"):
			d *= 2.0   # armor-piercing slug
		hit(e, d, id, randf() < 0.3, true)
		VFX.hit(e.global_position, true, Color(0.9, 0.95, 1.0, 0.95))
		VFX.sparks(e.global_position, 8, Color(0.9, 0.95, 1.0), 200.0, 0.35, dir, 40.0)
		if level >= 3 and e is CharacterBody2D:
			e.global_position += dir * (18.0 + level * 4.0)
