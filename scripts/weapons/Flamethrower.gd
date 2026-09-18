extends WeaponBase
## ENERGY (close range) — continuous plasma cone in the aim direction. Stacks burn.
## L5: flames leave burning pools.

var _cone: Node2D = null
var _pool_timer := 0.0

func on_level_changed(_old: int, new_lv: int) -> void:
	if new_lv > 0 and _cone == null:
		_cone = Node2D.new()
		_cone.set_script(load("res://scripts/weapons/fx/FlameCone.gd"))
		_cone.z_index = 7
		add_child(_cone)
	if _cone:
		_cone.visible = new_lv > 0 and not suppressed

func on_suppressed(on: bool) -> void:
	if _cone:
		_cone.visible = not on

func reach() -> float:
	return (150.0 + level * 22.0) * area_mult()

func half_angle() -> float:
	return 0.30 + level * 0.035 + (0.08 if level >= 4 else 0.0)

func cooldown() -> float:
	return maxf(0.08, 0.14 - level * 0.012)

func tick(delta: float) -> void:
	if level <= 0 or suppressed:
		return
	var a := aim()
	var dir: Vector2 = a[1]
	if _cone:
		_cone.global_position = player.global_position
		_cone.rotation = dir.angle()
		_cone.reach = reach()
		_cone.half_angle = half_angle()
		_cone.active = a[0] != null or manual()
	if a[0] == null and not manual():
		return
	super.tick(delta)

func fire() -> void:
	var a := aim()
	var dir: Vector2 = a[1]
	var r := reach()
	var ha := half_angle()
	var per := dmg(0.16 + level * 0.03)
	var any := false
	for e in in_radius(player.global_position, r):
		var rel: Vector2 = e.global_position - player.global_position
		if absf(wrapf(rel.angle() - dir.angle(), -PI, PI)) > ha:
			continue
		any = true
		hit(e, per, id, false, false)
		status(e, "burn", 2.0 + level * 0.2, dmg(0.09 + level * 0.025))
		if randf() < 0.35:
			VFX.sparks(e.global_position, 3, Color(1.0, 0.6, 0.2), 90.0, 0.3, -dir, 60.0)
	if randf() < 0.3:
		sfx("flame", 1.0 + randf_range(-0.1, 0.1), -12.0)
	if is_max():
		_pool_timer -= 0.1
		if _pool_timer <= 0.0 and any:
			_pool_timer = 0.55
			var at: Vector2 = player.global_position + dir * randf_range(r * 0.45, r * 0.9)
			var pool := Node2D.new()
			pool.set_script(load("res://scripts/weapons/fx/FirePool.gd"))
			pool.global_position = at
			pool.weapon = self
			pool.radius = 42.0 * area_mult()
			pool.damage = dmg(0.12)
			pool.life = 2.6 * float(player.duration_mult)
			GameManager.spawn(pool)
