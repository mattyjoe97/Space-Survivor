extends Node
## Visual inspection harness. Renders real frames through Xvfb/Mesa and saves PNGs.
## Env vars: SHOT_WEAPONS="a:5,b:3"  SHOT_FRAMES="120,180,240"  SHOT_OUT="/tmp/shot"  SHOT_SHIP="viper"
## SHOT_RING=1 spawns an enemy ring; SHOT_ELITE=1 spawns elites; SHOT_SUPER=1 lets synergies trigger.

var f := 0
var main: Node = null
var frames: Array = []
var out := "/tmp/shot"
var weapons: Array = []
var respawn_ring := true

func _ready() -> void:
	out = OS.get_environment("SHOT_OUT") if OS.get_environment("SHOT_OUT") != "" else "/tmp/shot"
	for tok in OS.get_environment("SHOT_FRAMES").split(",", false):
		if tok.find("-") > 0:
			var rng = tok.split("-")
			var step_parts = rng[1].split(":")
			var step := int(step_parts[1]) if step_parts.size() > 1 else 4
			var fr := int(rng[0])
			while fr <= int(step_parts[0]):
				frames.append(fr)
				fr += step
		else:
			frames.append(int(tok))
	if frames.is_empty():
		frames = [150, 220]
	for tok in OS.get_environment("SHOT_WEAPONS").split(",", false):
		var parts = tok.split(":")
		weapons.append([parts[0], int(parts[1]) if parts.size() > 1 else 1])
	var ship := OS.get_environment("SHOT_SHIP")
	GameManager.selected_character = ship if ship != "" else "viper"
	GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.call_deferred("add_child", main)

func _spawn_ring(n: int, radius: float) -> void:
	var p = GameManager.player
	var scene = load("res://scenes/Enemy.tscn")
	var types = ["chaser", "swarmer", "armored", "leecher", "chaser", "sniper", "splitter", "void_spitter"]
	for i in range(n):
		var e = scene.instantiate()
		e.enemy_type = types[i % types.size()]
		e.max_hp = 600.0
		e.speed = 90.0 if OS.get_environment("SHOT_MOVING") == "1" else 0.0
		e.base_speed = e.speed
		e.global_position = p.global_position + Vector2.from_angle(float(i) / n * TAU) * radius
		get_tree().root.add_child(e)

func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p):
		return
	if f == 5:
		var sp = main.get_node_or_null("EnemySpawner")
		if sp:
			sp.set_process(false); sp.set_physics_process(false)
		for e in GameManager.get_enemies():
			if is_instance_valid(e): e.queue_free()
		p.invuln_timer = 99999.0
		p.max_hp = 99999.0; p.current_hp = 99999.0
		if OS.get_environment("SHOT_RING") != "0":
			_spawn_ring(12, 300.0)
		if OS.get_environment("SHOT_ELITE") == "1":
			var el = load("res://scenes/EliteRammer.tscn").instantiate()
			el.global_position = p.global_position + Vector2(320, -120)
			get_tree().root.add_child(el)
	if f == 20 and OS.get_environment("SHOT_KEEP_SIGNATURE") != "1":
		# Clear the ship's signature weapon so only the requested weapons show.
		for wid in GameManager.WEAPON_UPGRADES:
			GameManager.upgrade_levels[wid] = 0
		p.weapons.sync_levels()
	if f == 20:
		for w in weapons:
			for i in range(int(w[1])):
				GameManager.upgrade_levels[w[0]] = i  # apply_upgrade increments
				p.apply_upgrade(w[0], 1)
		p.xp_to_next = 1.0e12
		if OS.get_environment("SHOT_CRIT") == "1":
			p.crit_chance = 1.0
		if OS.get_environment("SHOT_NONUM") == "1":
			SettingsManager.damage_numbers = false
		if OS.get_environment("SHOT_SUPER") == "1":
			GameManager._check_weapon_synergies()
	if f > 20 and f % 60 == 0 and OS.get_environment("SHOT_RING") != "0":
		if GameManager.get_enemies().size() < 6:
			_spawn_ring(12, 300.0)
	# Enemies stay parked so the weapon shapes are readable.
	for e in GameManager.get_enemies():
		if OS.get_environment("SHOT_MOVING") == "1":
			break
		if OS.get_environment("SHOT_RANGED") == "1" and e.get("enemy_type") != "chaser":
			continue
		if is_instance_valid(e) and "speed" in e:
			e.speed = 0.0
			e.base_speed = 0.0
	if f == 30 and OS.get_environment("SHOT_RANGED") == "1":
		var scene = load("res://scenes/Enemy.tscn")
		for i in range(18):
			var e = scene.instantiate()
			e.enemy_type = "void_spitter" if i % 3 != 0 else "sniper"
			e.max_hp = 5000.0
			e.global_position = p.global_position + Vector2.from_angle(float(i) / 18.0 * TAU) * randf_range(220.0, 420.0)
			GameManager.spawn(e)
		for i in range(30):
			var c = scene.instantiate()
			c.enemy_type = "chaser"
			c.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(200.0, 500.0)
			GameManager.spawn(c)
		var el = load("res://scenes/EliteSpitter.tscn").instantiate()
		el.global_position = p.global_position + Vector2(-330, 140)
		GameManager.spawn(el)
	if f == 30 and OS.get_environment("SHOT_PICKUPS") == "1":
		var base: Vector2 = p.global_position + Vector2(-260, -150)
		for i in range(4):
			var g = load("res://scenes/XPGem.tscn").instantiate()
			g.global_position = base + Vector2(0, i * 60)
			GameManager.spawn(g)
			var sc = load("res://scenes/ScrapPickup.tscn").instantiate()
			sc.global_position = base + Vector2(120, i * 60)
			GameManager.spawn(sc)
		var hl = load("res://scenes/Pickup.tscn").instantiate()
		hl.pickup_type = 0
		hl.global_position = base + Vector2(260, 60)
		GameManager.spawn(hl)
		var mg = load("res://scenes/Pickup.tscn").instantiate()
		mg.pickup_type = 1
		mg.global_position = base + Vector2(400, 60)
		GameManager.spawn(mg)
		var em = load("res://scenes/Pickup.tscn").instantiate()
		em.pickup_type = 1
		em.elite = true
		em.global_position = base + Vector2(540, 60)
		GameManager.spawn(em)
	if f == 30 and OS.get_environment("SHOT_MAGNET") == "1":
		for i in range(120):
			var g = load("res://scenes/XPGem.tscn").instantiate()
			g.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(140.0, 520.0)
			GameManager.spawn(g)
		for i in range(40):
			var sc = load("res://scenes/ScrapPickup.tscn").instantiate()
			sc.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(140.0, 520.0)
			GameManager.spawn(sc)
		var mg = load("res://scenes/Pickup.tscn").instantiate()
		mg.pickup_type = 1
		mg.elite = true
		mg.global_position = p.global_position + Vector2(150, -40)
		GameManager.spawn(mg)
		var hl = load("res://scenes/Pickup.tscn").instantiate()
		hl.pickup_type = 1
		hl.global_position = p.global_position + Vector2(-230, 80)
		GameManager.spawn(hl)
	if f == 30 and OS.get_environment("SHOT_MERCHANT") == "1":
		GameManager.scrap = 600
		var m = load("res://scenes/Merchant.tscn").instantiate()
		m.global_position = p.global_position + Vector2(40, 0)
		GameManager.spawn(m)
	if f == 40 and OS.get_environment("SHOT_LEVELUP") == "1":
		p.xp_to_next = 1.0
		p.add_xp(5.0)
	if OS.get_environment("SHOT_PULLCHECK") == "2" and f == 40:
		# Worst case: a mine sitting exactly on the ship pulling a ring of enemies inward.
		var m = Node2D.new()
		m.set_script(load("res://scripts/weapons/fx/GravMine.gd"))
		m.global_position = p.global_position
		m.weapon = p.weapons.get_weapon("graviton_mines")
		m.pull_radius = 420.0; m.pull_time = 6.0; m.pull_strength = 300.0; m.arm_time = 0.05; m.damage = 0.0
		GameManager.spawn(m)
	if OS.get_environment("SHOT_PULLCHECK") != "" and f > 30:
		# Pull-safety audit: release the parked enemies so the pull can move them, then log the
		# closest approach to the ship (must stay outside PullSafety.SAFE_RADIUS).
		var mind := INF
		for e in GameManager.get_enemies():
			if is_instance_valid(e):
				mind = minf(mind, e.global_position.distance_to(p.global_position))
		if f % 30 == 0:
			print("[pull f=%d] closest_enemy=%.1f safe=%.0f enemies=%d" % [f, mind, PullSafety.SAFE_RADIUS, GameManager.get_enemies().size()])
	if f in frames:
		# Damage-number audit: how many normal/crit numbers exist and where they are relative to enemies.
		var normal := 0
		var crits := 0
		var far := 0
		for n in get_tree().get_nodes_in_group("damage_numbers"):
			if not is_instance_valid(n): continue
			if n.critical: crits += 1
			else: normal += 1
			var best := INF
			for e in GameManager.get_enemies():
				if is_instance_valid(e): best = minf(best, e.global_position.distance_to(n.global_position))
			if best > 80.0: far += 1
		print("[dmgnum f=%d] normal=%d crit=%d far_from_any_enemy=%d setting=%s" % [f, normal, crits, far, str(SettingsManager.damage_numbers)])
		var total := 0.0
		for k in GameManager.damage_by_weapon: total += float(GameManager.damage_by_weapon[k])
		print("[dps f=%d t=%.1f] total=%.0f per_s=%.1f by=%s hp=%.0f/%.0f" % [f, GameManager.game_time, total, total / maxf(1.0, GameManager.game_time - 0.33), str(GameManager.damage_by_weapon), p.current_hp, p.max_hp])
		await RenderingServer.frame_post_draw
		var img = get_viewport().get_texture().get_image()
		var path = "%s_%d.png" % [out, f]
		img.save_png(path)
		print("[shot] ", path)
	if f > frames.max() + 5:
		get_tree().quit()
