extends Node
## Lifecycle + pickup reliability tests (TEST A..E from the 3.16.1 bug pass).
## Run: godot --headless --path . res://tests/LifecycleTest.tscn
## Uses the REAL restart flow: UI._on_restart -> MainMenu -> MainMenu._launch -> Main.

var f := 0
var phase := "A1_start"
var run_no := 0
var fails := 0
var main: Node = null
var _phase_start := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# change_scene_to_file() would free this node if it stayed the current scene,
	# so the runner re-homes itself under the tree root.
	if get_tree().current_scene == self:
		var runner := Node.new()
		runner.name = "LifecycleRunner"
		runner.set_script(get_script())
		get_tree().root.call_deferred("add_child", runner)
		return
	GameManager.selected_character = "viper"
	_start_run()

func _start_run() -> void:
	run_no += 1
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	_go("A_wait_main")

func _go(p: String) -> void:
	phase = p
	_phase_start = f

func _since() -> int:
	return f - _phase_start

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS  ", msg)
	else:
		print("  FAIL  ", msg)
		fails += 1

func _count(grp: String, only_test_drops: bool = false) -> int:
	var n := 0
	for x in get_tree().get_nodes_in_group(grp):
		if is_instance_valid(x) and not x.is_queued_for_deletion():
			if only_test_drops and not x.has_meta("test_gem"):
				continue
			n += 1
	return n

func _spawn_gems(n: int, radius: float, scrap: bool = false) -> void:
	var p = GameManager.player
	var scene = load("res://scenes/ScrapPickup.tscn" if scrap else "res://scenes/XPGem.tscn")
	for i in range(n):
		var g = scene.instantiate()
		g.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(30.0, radius)
		g.set_meta("test_gem", true)
		GameManager.spawn(g)

func _spawn_enemies(n: int, radius: float) -> void:
	var p = GameManager.player
	var scene = load("res://scenes/Enemy.tscn")
	for i in range(n):
		var e = scene.instantiate()
		e.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(120.0, radius)
		e.set_meta("test_run", run_no)
		GameManager.spawn(e)

func _process(_d: float) -> void:
	f += 1
	if f > 6000:
		print("WATCHDOG: stuck in phase ", phase)
		get_tree().quit(2)
	var p = GameManager.player
	match phase:
		"A_wait_main":
			if _since() > 10 and is_instance_valid(p):
				main = get_tree().current_scene
				print("\n=== RUN %d started (frame %d) ===" % [run_no, f])
				_check(p.current_xp == 0.0 and p.level == 1, "run %d: XP starts at 0 / level 1" % run_no)
				_check(_count("xp_gems") == 0, "run %d: no XP gems from previous run (%d)" % [run_no, _count("xp_gems")])
				_check(_count("tesla_coils") == 0, "run %d: no Tesla coils from previous run" % run_no)
				var old_enemies := 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and e.has_meta("test_run") and int(e.get_meta("test_run")) != run_no:
						old_enemies += 1
				_check(old_enemies == 0, "run %d: no enemies from previous run (%d stale)" % [run_no, old_enemies])
				_check(_count("projectiles") == 0 and _count("enemy_bullets") == 0, "run %d: no projectiles from previous run" % run_no)
				_check(_count("pickups") == 0 and _count("scrap_pickups") == 0, "run %d: no drops from previous run" % run_no)
				_check(GameManager.active_synergies.is_empty(), "run %d: no superweapons carried over" % run_no)
				var lv := 0
				for w in GameManager.WEAPON_UPGRADES:
					lv += GameManager.get_upgrade_level(w)
				_check(lv == 1, "run %d: only the signature weapon is levelled (total levels=%d)" % [run_no, lv])
				_check(p.vacuum_timer <= 0.0 and not p.magnet_elite, "run %d: no magnet state carried over" % run_no)
				_check(GameManager.damage_by_weapon.is_empty() and GameManager.run_kills == 0, "run %d: run stats clean" % run_no)
				var strays := 0
				for c in get_tree().root.get_children():
					if c.is_in_group("run_entity"):
						strays += 1
				_check(strays == 0, "run %d: no run entities parented to the tree root (%d)" % [run_no, strays])
				var weapons_node = p.get_node_or_null("Weapons")
				_check(weapons_node != null and weapons_node.supers.is_empty(), "run %d: WeaponManager has no active supers" % run_no)
				if run_no >= 3:
					# Pickup tests must not be interrupted by level-up pauses.
					p.xp_to_next = 1.0e12
					_go("B_setup")
				else:
					_go("A_dirty")
		"A_dirty":
			# Make the run messy: XP, weapons, tesla coil, enemies, drops, projectiles, magnet.
			p.xp_to_next = 1000.0
			p.add_xp(40.0)
			for w in ["tesla_coil", "missile_system", "railgun", "torpedo_bay"]:
				for i in range(3):
					GameManager.upgrade_levels[w] = i
					p.apply_upgrade(w, 1)
			GameManager.upgrade_levels["missile_system"] = 4; p.apply_upgrade("missile_system", 1)
			GameManager.upgrade_levels["torpedo_bay"] = 4; p.apply_upgrade("torpedo_bay", 1)
			GameManager._check_weapon_synergies()
			_spawn_enemies(25, 500.0)
			_spawn_gems(60, 700.0)
			_spawn_gems(20, 700.0, true)
			var mg = load("res://scenes/Pickup.tscn").instantiate()
			mg.pickup_type = 1; mg.elite = true
			mg.global_position = p.global_position + Vector2(600, 0)
			GameManager.spawn(mg)
			p.activate_vacuum(30.0, false)
			_go("A_messy_wait")
		"A_messy_wait":
			if _since() == 120:
				print("  dirty state: gems=%d scrap=%d enemies=%d coils=%d supers=%s xp=%.0f" % [_count("xp_gems"), _count("scrap_pickups"), _count("enemies"), _count("tesla_coils"), str(GameManager.active_synergies), p.current_xp])
				_check(_count("tesla_coils") > 0, "run %d: tesla coil exists before death" % run_no)
				# Die
				p.invuln_timer = 0.0
				p.take_damage(1.0e9)
				_go("A_dead")
		"A_dead":
			if _since() == 90:
				# Real restart path: game-over panel restart button.
				var ui = main.get_node_or_null("UI")
				ui._on_restart()
				_go("A_menu")
		"A_menu":
			if _since() == 30:
				var menu = get_tree().current_scene
				_check(menu != null and menu.name == "MainMenu", "restart reached MainMenu")
				run_no += 1
				menu._launch()
				_go("A_wait_main")
		"B_setup":
			print("\n=== TEST B: normal pickup range, 300 gems + 100 scrap ===")
			get_tree().paused = false
			GameManager.is_paused = false
			var ui = main.get_node_or_null("UI")
			if ui and ui.get("levelup_panel") != null:
				ui.levelup_panel.visible = false
			p.xp_to_next = 1.0e12
			_spawn_gems(300, 380.0)
			_spawn_gems(100, 380.0, true)
			_go("B_wait")
		"B_wait":
			if _since() == 240:
				var inside := 0
				var total := 0
				for grp in ["xp_gems", "scrap_pickups"]:
					for g in get_tree().get_nodes_in_group(grp):
						if not is_instance_valid(g) or g.is_queued_for_deletion():
							continue
						total += 1
						if g.global_position.distance_to(p.global_position) <= p.xp_magnet_range:
							inside += 1
				_check(inside == 0, "TEST B: nothing left inside pickup range %.0f (left inside=%d, outside=%d)" % [p.xp_magnet_range, inside, total])
				_go("C_setup")
		"C_setup":
			print("\n=== TEST C: magnet with 400 scattered drops, player moving ===")
			for g in get_tree().get_nodes_in_group("xp_gems"): g.queue_free()
			for g in get_tree().get_nodes_in_group("scrap_pickups"): g.queue_free()
			_go("C_spawn")
		"C_spawn":
			if _since() == 2:
				_spawn_gems(300, 900.0)
				_spawn_gems(100, 900.0, true)
				p.activate_vacuum(5.0, false)
				_go("C_wait")
		"C_wait":
			# Move the player in a circle while the magnet runs.
			p.global_position += Vector2.from_angle(float(_since()) * 0.05) * 4.0
			if _since() == 60:
				_check(p.vacuum_timer > 0.0 and is_instance_valid(p._magnet_fx), "TEST C: magnet active with FX")
			if _since() == 420:
				var left := _count("xp_gems", true) + _count("scrap_pickups", true)
				for grp in ["xp_gems", "scrap_pickups"]:
					for g in get_tree().get_nodes_in_group(grp):
						if is_instance_valid(g) and not g.is_queued_for_deletion():
							print("    leftover ", grp, " dist=", g.global_position.distance_to(p.global_position), " attracting=", g.attracting, " boosted=", g.boosted, " target_valid=", is_instance_valid(g.target), " speed=", g.speed)
				_check(left == 0, "TEST C: all 400 drops collected after magnet (left=%d)" % left)
				_go("D_setup")
		"D_setup":
			print("\n=== TEST D: elite magnet drop ===")
			_spawn_gems(80, 500.0)
			var mg = load("res://scenes/Pickup.tscn").instantiate()
			mg.pickup_type = 1; mg.elite = true
			mg.global_position = p.global_position + Vector2(150, 0)
			mg.set_meta("test_gem", true)
			GameManager.spawn(mg)
			_check(mg.interact_radius() > 150.0, "TEST D: elite magnet interaction radius %.0f > normal 110" % mg.interact_radius())
			_go("D_wait")
		"D_wait":
			if _since() == 90:
				_check(_count("pickups", true) == 0, "TEST D: elite magnet drifted in and was collected")
				_check(p.vacuum_timer > 0.0 and p.magnet_elite, "TEST D: elite magnet activated (timer=%.1f elite=%s)" % [p.vacuum_timer, str(p.magnet_elite)])
			if _since() == 420:
				_check(_count("xp_gems", true) == 0, "TEST D: all 80 gems collected by elite magnet (left=%d)" % _count("xp_gems", true))
				_go("E_setup")
		"E_setup":
			print("\n=== TEST E: heavy density — 80 enemies + 600 drops + magnet ===")
			_spawn_enemies(80, 450.0)
			_spawn_gems(450, 800.0)
			_spawn_gems(150, 800.0, true)
			p.invuln_timer = 9999.0
			_go("E_spawn")
		"E_spawn":
			if _since() == 30:
				p.activate_vacuum(5.0, false)
				_go("E_wait")
		"E_wait":
			p.global_position += Vector2.from_angle(float(_since()) * 0.03) * 3.0
			if _since() == 420:
				var left := _count("xp_gems", true) + _count("scrap_pickups", true)
				_check(left == 0, "TEST E: all 600 drops collected under heavy density (left=%d, enemies=%d)" % [left, _count("enemies")])
				_go("F_setup")
		"F_setup":
			print("\n=== TEST F: elite killed by many hits in one frame drops exactly one magnet ===")
			for x in get_tree().get_nodes_in_group("pickups"): x.queue_free()
			for x in get_tree().get_nodes_in_group("enemies"): x.queue_free()
			_go("F_kill")
		"F_kill":
			if _since() == 3:
				var before_elites := GameManager.elites_killed
				var before_scrap := GameManager.scrap
				for scene_path in ["res://scenes/EliteRammer.tscn", "res://scenes/EliteSpitter.tscn"]:
					var el = load(scene_path).instantiate()
					el.global_position = p.global_position + Vector2(700, 0)
					GameManager.spawn(el)
					el.max_hp = 10.0; el.current_hp = 10.0
					for i in range(40):
						el.take_damage(50.0)
				set_meta("f_elites", before_elites)
				set_meta("f_scrap", before_scrap)
			if _since() == 6:
				var mags := 0
				var elite_mags := 0
				for x in get_tree().get_nodes_in_group("pickups"):
					if is_instance_valid(x) and not x.is_queued_for_deletion() and x.pickup_type == 1:
						mags += 1
						if x.elite:
							elite_mags += 1
				_check(elite_mags == 2, "TEST F: 2 elites x 40 same-frame hits -> exactly 2 elite magnets (got %d)" % elite_mags)
				_check(GameManager.elites_killed - int(get_meta("f_elites")) == 2, "TEST F: elite kill counted once per elite")
				_check(GameManager.scrap - int(get_meta("f_scrap")) == 28, "TEST F: elite scrap awarded once per elite (+%d)" % (GameManager.scrap - int(get_meta("f_scrap"))))
				# Normal enemy: same guard
				var e = load("res://scenes/Enemy.tscn").instantiate()
				e.global_position = p.global_position + Vector2(700, 200)
				e.enemy_type = "armored"
				GameManager.spawn(e)
				e.max_hp = 5.0; e.current_hp = 5.0
				var gems_before := _count("xp_gems")
				for i in range(30):
					e.take_damage(50.0)
				set_meta("f_gems", gems_before)
			if _since() == 9:
				var gained := _count("xp_gems") - int(get_meta("f_gems"))
				_check(gained <= 1, "TEST F: normal enemy hit 30x in one frame drops one gem (gained %d)" % gained)
				_go("G_setup")
		"G_setup":
			print("\n=== TEST G: magnet pulls heal/magnet pickups (the larger green/blue nodes) ===")
			for x in get_tree().get_nodes_in_group("pickups"): x.queue_free()
			_go("G_spawn")
		"G_spawn":
			if _since() == 3:
				for i in range(12):
					var h = load("res://scenes/Pickup.tscn").instantiate()
					h.pickup_type = 0
					h.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 700.0)
					h.set_meta("test_gem", true)
					GameManager.spawn(h)
				for i in range(3):
					var m = load("res://scenes/Pickup.tscn").instantiate()
					m.pickup_type = 1
					m.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 700.0)
					m.set_meta("test_gem", true)
					GameManager.spawn(m)
				p.current_hp = 10.0
				p.activate_vacuum(5.0, false)
			if _since() == 360:
				_check(_count("pickups", true) == 0, "TEST G: all 15 heal/magnet pickups collected by magnet (left=%d)" % _count("pickups", true))
				print("\n=== DONE: %d failure(s) ===" % fails)
				get_tree().quit(1 if fails > 0 else 0)
