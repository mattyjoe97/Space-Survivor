extends SuperWeaponBase
## VOID BLADES + PHASE DISRUPTOR: two huge phase scythes orbit at range; every cut opens a rift.
var _rig: Node2D = null
var _angle := 0.0
var _hit_cd: Dictionary = {}
var _t := 0.0

func on_activated() -> void:
	_rig = Node2D.new()
	_rig.set_script(load("res://scripts/weapons/fx/BladeRig.gd"))
	_rig.top_level = true
	_rig.z_index = 7
	_rig.blade_count = 2
	_rig.blade_len = 62.0
	_rig.color = Color(0.8, 0.4, 1.0)
	add_child(_rig)

func _orbit() -> float:
	return 150.0 * area_mult()

func tick(delta: float) -> void:
	if _rig == null:
		on_activated()
	_t += delta
	_angle += delta * 2.4
	_rig.global_position = player.global_position
	_rig.rotation = _angle
	_rig.orbit = _orbit()
	_rig.lash = 0.3 + 0.2 * sin(_t * 3.0)
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.1
	for e in in_radius(player.global_position, _orbit() + 80.0):
		var rel: Vector2 = e.global_position - player.global_position
		if rel.length() < _orbit() - 70.0:
			continue
		var ea := rel.angle()
		var close := false
		for i in range(2):
			if absf(wrapf(ea - (_angle + i * PI), -PI, PI)) < 0.5:
				close = true
		if not close:
			continue
		var key: int = e.get_instance_id()
		if _hit_cd.has(key) and _t - float(_hit_cd[key]) < 0.35:
			continue
		_hit_cd[key] = _t
		hit(e, dmg(1.3))
		status(e, "phased", 3.0, 0.25)
		VFX.hit(e.global_position, true, Color(0.85, 0.45, 1.0, 0.95))
		# One rift per enemy per 1.2 s (rifts on every cut were the stacking outlier).
		VoidReticle.try_place(e, self, dmg(0.9), 80.0, 0.5, 34.0)
		if randf() < 0.4:
			sfx("blade", 0.7, -8.0)
