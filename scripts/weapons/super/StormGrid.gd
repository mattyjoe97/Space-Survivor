extends SuperWeaponBase
## ARC COIL + TESLA COIL: four tesla nodes orbit the ship linked by lightning walls.
var _rig: Node2D = null
var _angle := 0.0
var _wall_t := 0.0
var _zap_t := 0.0

func on_activated() -> void:
	_rig = Node2D.new()
	_rig.set_script(load("res://scripts/weapons/fx/StormRig.gd"))
	_rig.top_level = true
	_rig.z_index = 7
	add_child(_rig)

func _radius() -> float:
	return 165.0 * area_mult()

func _nodes() -> Array:
	var out: Array = []
	for i in range(4):
		out.append(player.global_position + Vector2.from_angle(_angle + i * TAU / 4.0) * _radius())
	return out

func tick(delta: float) -> void:
	if _rig == null:
		on_activated()
	_angle += delta * 0.9
	_rig.global_position = player.global_position
	_rig.rotation = _angle
	_rig.radius = _radius()
	var nodes := _nodes()
	_wall_t -= delta
	_zap_t -= delta
	if _wall_t <= 0.0:
		_wall_t = 0.13
		for i in range(4):
			var a: Vector2 = nodes[i]
			var b: Vector2 = nodes[(i + 1) % 4]
			WeaponFX.bolt(a, b, Color(0.6, 0.9, 1.0), 3.5, 0.26)
			var dir := (b - a).normalized()
			for e in in_line(a, dir, a.distance_to(b), 18.0):
				hit(e, dmg(0.55))
				if "frozen_timer" in e:
					e.frozen_timer = maxf(float(e.frozen_timer), 0.18)
				VFX.hit(e.global_position, false, Color(0.7, 0.95, 1.0, 0.9))
	if _zap_t <= 0.0:
		_zap_t = 0.42
		var any := false
		for n in nodes:
			var e := nearest(210.0, [], n)
			if e:
				WeaponFX.bolt(n, e.global_position, Color(0.55, 0.85, 1.0), 3.0, 0.15)
				hit(e, dmg(0.9))
				any = true
		if any:
			sfx("tesla", 1.0 + randf() * 0.2, -9.0)
