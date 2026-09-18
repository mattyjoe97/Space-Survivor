extends SuperWeaponBase
## RAILGUN + PHOTON SCATTERGUN: long charge, colossal rail that sprays photon shrapnel sideways.
var _charging := false
var _charge_t := 0.0
var _charge_node: Node2D = null

func cooldown() -> float:
	return 3.4

func fire() -> void:
	_charging = true
	_charge_t = 0.0
	_charge_node = Node2D.new()
	_charge_node.set_script(load("res://scripts/weapons/fx/RailCharge.gd"))
	_charge_node.duration = 1.0
	_charge_node.scale = Vector2(1.8, 1.8)
	player.add_child(_charge_node)
	sfx("laser", 0.4, -6.0)

func tick(delta: float) -> void:
	if _charging:
		_charge_t += delta
		if _charge_t >= 1.0:
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
	var origin: Vector2 = player.global_position
	var reach := 1500.0
	var width := 22.0 * size_mult()
	var n := Node2D.new()
	n.set_script(load("res://scripts/weapons/fx/RailShot.gd"))
	n.global_position = origin
	n.rotation = dir.angle()
	n.reach = reach
	n.width = width
	n.life = 0.8
	GameManager.spawn(n)
	sfx("railgun", 0.7, 0.0)
	sfx("big_boom", 1.2, -4.0)
	VFX.screen_shake(9.0)
	VFX.postfx_punch(1.0)
	VFX.screen_flash(Color(1.0, 0.98, 0.85, 0.35), 0.35)
	player.visual_recoil(dir, 14.0)
	var perp := Vector2(-dir.y, dir.x)
	# Shrapnel bursts along the rail: at every hit enemy and at fixed intervals.
	# Performance (3.19): shrapnel origins are capped. Every enemy on the rail still takes the
	# hit; shrapnel/sparks spawn from at most 6 impact points (nearest first) + 3 fixed points,
	# 3 pellets per side each, with one spark burst per point. Worst case ~54 pellets instead of
	# several hundred, which was the frame hitch in dense swarms.
	var points: Array = []
	var hits: Array = in_line(origin, dir, reach, width)
	hits.sort_custom(func(a, b): return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	for e in hits:
		hit(e, dmg(4.5), id, true)
		if e is CharacterBody2D:
			e.global_position += dir * 30.0
		if points.size() < 6:
			points.append(e.global_position)
	for k in [2, 4, 6]:
		points.append(origin + dir * (k * 180.0))
	for pt in points:
		VFX.sparks(pt, 6, Color(1.0, 0.95, 0.6), 240.0, 0.4)
		for sgn: float in [-1.0, 1.0]:
			for i in range(3):
				var pd: Vector2 = (perp * sgn).rotated(randf_range(-0.35, 0.35))
				var p: Area2D = player._spawn_proj(pt, pd, dmg(0.7), 1, 0.7, id)
				if p:
					p.speed = player.projectile_speed * 1.5
					p.lifetime = 0.7
					p.ricochet = 1
					var poly: Polygon2D = p.get_node_or_null("Polygon2D")
					if poly:
						poly.color = Color(1.0, 0.95, 0.6)
						p.get_node("Glow").color = Color(1.0, 0.85, 0.3, 0.45)
