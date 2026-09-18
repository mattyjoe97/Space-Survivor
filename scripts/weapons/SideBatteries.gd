extends WeaponBase
## KINETIC — broadside cannons perpendicular to heading, alternating bursts.
## L3: heavy shells with knockback. L5: quad batteries on all four sides.

var _burst_left := 0
var _burst_side := 1.0
var _burst_timer := 0.0
var _turrets: Node2D = null

func on_level_changed(_old: int, new_lv: int) -> void:
	if new_lv > 0 and _turrets == null:
		_turrets = Node2D.new()
		_turrets.set_script(load("res://scripts/weapons/fx/BroadsideTurrets.gd"))
		_turrets.z_index = 3
		add_child(_turrets)
	if _turrets:
		_turrets.visible = new_lv > 0 and not suppressed
		_turrets.quad = is_max()

func on_suppressed(on: bool) -> void:
	if _turrets:
		_turrets.visible = not on

func cooldown() -> float:
	return maxf(0.7, 1.5 - level * 0.14)

func _burst_size() -> int:
	var b: int = [2, 3, 3, 4, 4][clampi(level - 1, 0, 4)]
	return b + extra()

func fire() -> void:
	_burst_left = _burst_size()
	_burst_side *= -1.0
	_burst_timer = 0.0

func tick(delta: float) -> void:
	if level <= 0 or suppressed:
		return
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = 0.07
			_burst_left -= 1
			_volley()
		return
	timer -= delta
	if timer <= 0.0:
		fire()
		timer = cooldown()

func _volley() -> void:
	var fwd := Vector2.from_angle(player.rotation - PI / 2.0)
	var right := Vector2(-fwd.y, fwd.x)
	var sides: Array = [right * _burst_side]
	if is_max():
		sides = [right, -right, fwd, -fwd]
	var heavy := level >= 3
	for s in sides:
		var d: Vector2 = s
		var off: float = 6.0 * (float(_burst_left % 2) - 0.5)
		var pos: Vector2 = player.global_position + d * 20.0 + fwd * off * 2.0
		var p: Area2D = player._spawn_proj(pos, d.rotated(randf_range(-0.06, 0.06)), dmg(0.6 + level * 0.11) * (1.3 if heavy else 1.0), int(player.pierce), (1.25 if heavy else 0.95), id)
		if p:
			p.speed = player.projectile_speed * 1.15
			p.lifetime = 1.1
			p.knockback = 22.0 if heavy else 0.0
			if player.explode_on_hit:
				p.explode = true
			if p.get_node_or_null("Polygon2D"):
				p.get_node("Polygon2D").color = Color(1.0, 0.85, 0.45)
				p.get_node("Glow").color = Color(1.0, 0.6, 0.2, 0.4)
		VFX.muzzle_flash(pos, d, Color(1.0, 0.8, 0.4), 1.1 if heavy else 0.8)
		if _turrets:
			_turrets.kick(d)
	sfx("shoot", 0.72, -6.0)
	VFX.screen_shake(0.8 if heavy else 0.4)
	player._notify_weapon_vfx("bullet")
