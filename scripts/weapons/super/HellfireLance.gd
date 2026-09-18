extends SuperWeaponBase
## PLASMA LANCE + FLAMETHROWER: a wide flaming beam that sweeps a full circle, leaving fire pools.
var _beam: WeaponFX.Beam = null
var _angle := 0.0
var _pool_t := 0.0

func cooldown() -> float:
	return 0.05

func tick(delta: float) -> void:
	if _beam == null or not is_instance_valid(_beam):
		_angle = player.rotation - PI / 2.0
		_beam = WeaponFX.beam(player, _angle, _angle, 480.0 * area_mult(), 26.0 * size_mult(), Color(1.0, 0.4, 0.12), 999.0, _on_tick, 99.0, 0.08)
		_beam.set_meta("hell", true)
		sfx("laser", 0.6, -6.0)
	_angle += delta * 1.35
	_beam.target_angle = _angle
	_beam.angle = _angle
	_pool_t -= delta
	if _pool_t <= 0.0:
		_pool_t = 0.32
		var d := Vector2.from_angle(_angle)
		var pool := Node2D.new()
		pool.set_script(load("res://scripts/weapons/fx/FirePool.gd"))
		pool.global_position = player.global_position + d * randf_range(80.0, _beam.reach * 0.9)
		pool.weapon = self
		pool.radius = 34.0 * area_mult()
		pool.damage = dmg(0.14)
		pool.life = 2.2
		GameManager.spawn(pool)

func _on_tick(origin: Vector2, dir: Vector2) -> void:
	var per := dmg(0.36)
	for e in in_line(origin, dir, _beam.reach, _beam.width * 0.7):
		hit(e, per)
		status(e, "burn", 2.2, dmg(0.12))
		if randf() < 0.5:
			VFX.sparks(e.global_position, 3, Color(1.0, 0.6, 0.2), 90.0, 0.3)

func on_suppressed(_on: bool) -> void:
	pass

func _exit_tree() -> void:
	if is_instance_valid(_beam):
		_beam.queue_free()
