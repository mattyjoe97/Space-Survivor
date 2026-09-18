extends WeaponBase
## ENERGY — chain lightning that leaps between enemies.
## L3: micro-stun per jump. L5: overcharge node at the chain end re-arcs.

func cooldown() -> float:
	# Discharge rate scales with the Fire Rate stat (base interval 0.32 s).
	return maxf(0.4, (1.6 - level * 0.16) * clampf(float(player.fire_rate) / 0.32, 0.5, 1.2))

func _jumps() -> int:
	var j: int = [3, 4, 5, 6, 7][clampi(level - 1, 0, 4)]
	if GameManager.selected_character == "tempest":
		j += int(player.level) / 5
	return j

func fire() -> void:
	var a := aim()
	var first: Node2D = a[0]
	if first == null:
		if manual():
			# Manual mode with nothing under the cursor: fire a short visible pulse.
			WeaponFX.bolt(player.global_position, player.global_position + a[1] * 160.0, color(), 2.5, 0.1)
		timer = 0.25
		return
	sfx("arc_zap", 1.0 + randf_range(-0.1, 0.1), -7.0)
	var hops := _jumps()
	var reach := 170.0 + level * 18.0
	var visited: Array = []
	var from: Vector2 = player.global_position
	var cur: Node2D = first
	var damage := dmg(1.2 + level * 0.3)
	for i in range(hops):
		if cur == null or not is_instance_valid(cur):
			break
		WeaponFX.bolt(from, cur.global_position, color(), 4.6 - i * 0.3, 0.28)
		VFX.sparks(cur.global_position, 4, Color(0.75, 0.95, 1.0), 110.0, 0.25)
		hit(cur, damage * pow(0.94, i))
		if player.burn_tier > 0:
			status(cur, "burn", 1.5 + player.burn_tier * 0.4, dmg(0.06 + player.burn_tier * 0.04))
		VFX.hit(cur.global_position, i == 0, Color(0.55, 0.85, 1.0, 0.95))
		if level >= 3 and "frozen_timer" in cur:
			cur.frozen_timer = maxf(float(cur.frozen_timer), 0.14)
		visited.append(cur)
		from = cur.global_position
		cur = nearest(reach, visited, from)
	if is_max() and visited.size() > 0:
		_plant_overcharge(visited[visited.size() - 1].global_position, damage * 0.6)
	player._notify_weapon_vfx("arc")

func _plant_overcharge(at: Vector2, damage: float) -> void:
	var node := world_node(at, 12)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)])
	poly.color = Color(0.7, 0.95, 1.0, 0.95)
	node.add_child(poly)
	var tw := node.create_tween()
	tw.tween_property(poly, "scale", Vector2(1.8, 1.8), 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		WeaponFX.pulse(at, 8.0, 150.0, Color(0.6, 0.9, 1.0), 0.3, 6.0)
		AudioManager.play("arc_zap", 1.3, -8.0)
		var n := 0
		for e in in_radius(at, 150.0):
			if n >= 3:
				break
			WeaponFX.bolt(at, e.global_position, Color(0.7, 0.95, 1.0), 2.5, 0.15)
			hit(e, damage)
			n += 1
		node.queue_free()
	)
