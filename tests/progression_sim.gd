extends Node
## Progression simulation: plays a run with a simple pilot AI at accelerated time and
## prints a metrics snapshot at 1/3/5/7 minutes (and on death).
## Run: godot --headless --path . res://tests/ProgressionSim.tscn
## Env: SIM_SHIP=viper SIM_SEED=1 SIM_MINUTES=7 SIM_POLICY=balanced|weapons|stats|random SIM_SPEED=6

var main: Node = null
var f := 0
var snapshots := [60.0, 180.0, 300.0, 420.0]
var snap_idx := 0
var policy := "balanced"
var minutes := 7.0
var dmg_at_last := 0.0
var time_at_last := 0.0
var merchant_buys := 0
var rerolls_used := 0
var picks: Dictionary = {}      # rarity -> count
var picked_ids: Array = []
var super_times: Array = []
var dead_at := -1.0
var levelups := 0
var hp_samples: Array = []
var enemy_samples: Array = []
var _steer_t := 0.0
var _steer := Vector2.ZERO
var merchant_visited := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_tree().current_scene == self:
		var runner := Node.new()
		runner.name = "SimRunner"
		runner.set_script(get_script())
		get_tree().root.call_deferred("add_child", runner)
		return
	var seed_s := OS.get_environment("SIM_SEED")
	seed(int(seed_s) if seed_s != "" else 1)
	policy = OS.get_environment("SIM_POLICY") if OS.get_environment("SIM_POLICY") != "" else "balanced"
	if OS.get_environment("SIM_MINUTES") != "":
		minutes = float(OS.get_environment("SIM_MINUTES"))
	var speed := 6.0
	if OS.get_environment("SIM_SPEED") != "":
		speed = float(OS.get_environment("SIM_SPEED"))
	Engine.physics_ticks_per_second = int(60 * speed)
	Engine.max_physics_steps_per_frame = int(8 * speed)
	Engine.time_scale = speed
	GameManager.selected_character = OS.get_environment("SIM_SHIP") if OS.get_environment("SIM_SHIP") != "" else "viper"
	log_line("[dbg] runner ready, policy=%s speed=%.0f" % [policy, speed])
	GameManager.reset()
	GameManager.player_leveled_up.connect(func(_l): levelups += 1)
	GameManager.synergy_activated.connect(func(sid): super_times.append([sid, snapf(GameManager.game_time)]))
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

var _log: FileAccess = null
func log_line(msg: String) -> void:
	if _log == null:
		_log = FileAccess.open(OS.get_environment("SIM_LOG") if OS.get_environment("SIM_LOG") != "" else "/tmp/sim_log.txt", FileAccess.WRITE)
	_log.store_line(msg)
	_log.flush()
	printerr(msg)

func snapf(x: float) -> float:
	return round(x * 10.0) / 10.0

func _process(delta: float) -> void:
	f += 1
	if f % 3000 == 0:
		log_line("[dbg] process f=%d real=%.1f t=%.2f paused=%s lvl=%s" % [f, Time.get_ticks_msec() / 1000.0, GameManager.game_time, str(get_tree().paused), str(GameManager.player.level if is_instance_valid(GameManager.player) else -1)])
	var p = GameManager.player
	if f % 120 == 0 and not is_instance_valid(p):
		log_line("[dbg] no player yet f=%d paused=%s" % [f, str(get_tree().paused)])
	if not is_instance_valid(p):
		return
	if main == null:
		main = get_tree().current_scene
	var ui = main.get_node_or_null("UI")
	var t: float = GameManager.game_time
	# --- decisions while paused ---
	if ui and ui.levelup_panel.visible:
		_pick_levelup(ui)
		return
	if ui and ui.merchant_panel.visible:
		_shop(ui)
		return
	if GameManager.is_game_over:
		if dead_at < 0.0:
			dead_at = t
			_snapshot("DEATH @ %.0fs" % t)
			_finish()
		return
	# --- pilot ---
	_pilot(p, delta)
	# --- sampling ---
	if f % 30 == 0:
		hp_samples.append(float(p.current_hp) / maxf(1.0, float(p.max_hp)))
		enemy_samples.append(GameManager.get_enemies().size())
	# --- merchant: walk to it if it exists ---
	if snap_idx < snapshots.size() and t >= snapshots[snap_idx]:
		_snapshot("%d:00" % int(snapshots[snap_idx] / 60.0))
		snap_idx += 1
	if t >= minutes * 60.0:
		_finish()

func _pilot(p: Node2D, delta: float) -> void:
	_steer_t -= delta
	if _steer_t > 0.0:
		return
	_steer_t = 0.05
	var pos: Vector2 = p.global_position
	var away := Vector2.ZERO
	var nearest_d := INF
	for e in GameManager.get_enemies():
		if not is_instance_valid(e):
			continue
		var rel: Vector2 = pos - e.global_position
		var d := rel.length()
		if d < 260.0 and d > 1.0:
			away += rel.normalized() * (260.0 - d) / 260.0
		nearest_d = minf(nearest_d, d)
	var toward := Vector2.ZERO
	var best := 9999.0
	for grp in ["xp_gems", "scrap_pickups", "pickups"]:
		for g in get_tree().get_nodes_in_group(grp):
			if not is_instance_valid(g):
				continue
			var d2 := pos.distance_to(g.global_position)
			if d2 < best:
				best = d2
				toward = (g.global_position - pos).normalized()
	var merchant: Node2D = null
	for m in get_tree().get_nodes_in_group("merchants"):
		if is_instance_valid(m):
			merchant = m
	var steer := away * 2.2 + toward * 0.9
	if merchant and not merchant_visited and nearest_d > 120.0:
		steer += (merchant.global_position - pos).normalized() * 1.6
	if steer.length() < 0.05:
		steer = Vector2.from_angle(float(f) * 0.01)
	_steer = steer.normalized()
	# Feed input via Input actions (the player reads move_* actions).
	Input.action_release("move_left"); Input.action_release("move_right"); Input.action_release("move_up"); Input.action_release("move_down")
	if _steer.x < -0.3: Input.action_press("move_left")
	if _steer.x > 0.3: Input.action_press("move_right")
	if _steer.y < -0.3: Input.action_press("move_up")
	if _steer.y > 0.3: Input.action_press("move_down")

func _pick_levelup(ui: Node) -> void:
	var cards: Array = []
	for c in ui.upgrade_container.get_children():
		if c is VBoxContainer:
			cards.append(c)
	if cards.is_empty() or cards[0].get_child_count() == 0:
		if f % 100 == 0:
			var names := []
			for c in ui.upgrade_container.get_children():
				names.append(c.name + ":" + c.get_class() + (":" + c.text if c is Label else ""))
			log_line("[dbg] levelup visible but no cards; container children=%s" % str(names))
		return
	var box = cards[0]
	var options: Array = []
	for c in box.get_children():
		if c is Button and c.has_meta("up"):
			options.append(c)
	if options.is_empty():
		if f % 100 == 0:
			log_line("[dbg] cards present but no option buttons with meta: children=%d types=%s" % [box.get_child_count(), str(box.get_children().map(func(c): return c.get_class()))])
		return
	var choice: Button = null
	var scored: Array = []
	for c in options:
		var up: Dictionary = c.get_meta("up")
		var id := str(up.get("id", ""))
		var score := randf()
		var cat := str(up.get("category", ""))
		var rarity := int(up.get("rarity", 0))
		match policy:
			"weapons":
				# Focused: level the highest owned weapon, take partners of owned weapons.
				if cat == "WEAPONS":
					var lvl2 := int(up.get("current_level", 0))
					score += 3.0 + lvl2 * 0.8
					for sid in GameManager.WEAPON_SYNERGIES:
						var reqs: Array = GameManager.WEAPON_SYNERGIES[sid].requires
						if id in reqs:
							var other: String = str(reqs[0] if str(reqs[1]) == id else reqs[1])
							if GameManager.get_upgrade_level(other) > 0: score += 4.0
				elif cat == "SYSTEMS": score += 1.0
			"stats":
				if cat == "UPGRADES": score += 2.0
				if id == "fire_rate" or id == "damage": score += 1.5
			"balanced":
				# Mixed human-like policy: weapons early, then stats/systems, chase supers.
				var lvl := int(up.get("current_level", 0))
				if cat == "WEAPONS":
					score += 1.1 if lvl > 0 else (1.4 if GameManager.weapon_slot_count() < 3 else 0.4)
					if lvl >= 3: score += 0.6
				if cat == "SYSTEMS": score += 0.9
				if cat == "UPGRADES":
					score += 0.7 + rarity * 0.35
					if id in ["damage", "fire_rate", "max_hp", "crit"]: score += 0.4
				if bool(up.get("is_relic", false)): score += 1.2
		scored.append([score, c, up])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	choice = scored[0][1]
	var up: Dictionary = scored[0][2]
	var r := int(up.get("rarity", 0))
	picks[r] = int(picks.get(r, 0)) + 1
	picked_ids.append(str(up.get("id", "")))
	choice.emit_signal("pressed")

func _shop(ui: Node) -> void:
	merchant_visited = true
	# Buy the most useful affordable thing, up to a few purchases, then leave.
	var bought_any := false
	for c in ui.merchant_container.get_children():
		if c is Button and not c.disabled and c.has_meta("offer"):
			var offer: Dictionary = c.get_meta("offer")
			c.emit_signal("pressed")
			merchant_buys += 1
			bought_any = true
			break
	if not bought_any or merchant_buys >= 12:
		ui._on_merchant_leave()

func _snapshot(label: String) -> void:
	var p = GameManager.player
	var t: float = GameManager.game_time
	var total_dmg := 0.0
	for k in GameManager.damage_by_weapon:
		total_dmg += float(GameManager.damage_by_weapon[k])
	var dps := (total_dmg - dmg_at_last) / maxf(1.0, t - time_at_last)
	dmg_at_last = total_dmg
	time_at_last = t
	var weapons: Array = []
	for w in GameManager.WEAPON_UPGRADES:
		var lv := GameManager.get_upgrade_level(w)
		if lv > 0:
			weapons.append("%s:%d" % [w.replace("_system", "").substr(0, 8), lv])
	var systems := 0
	var cores := 0
	for id in GameManager.upgrade_levels:
		var lv2 := int(GameManager.upgrade_levels[id])
		if lv2 <= 0: continue
		if GameManager.is_system_upgrade(str(id)): systems += lv2
		elif not GameManager.is_weapon_upgrade(str(id)) and not GameManager.is_modifier_upgrade(str(id)): cores += lv2
	var avg_hp := 0.0
	for h in hp_samples: avg_hp += h
	avg_hp = avg_hp / maxf(1.0, hp_samples.size())
	var avg_en := 0.0
	for e in enemy_samples: avg_en += e
	avg_en = avg_en / maxf(1.0, enemy_samples.size())
	hp_samples.clear(); enemy_samples.clear()
	var enemy_hp := 18.0 + t * 0.55 + pow(t / 70.0, 1.18) * 9.0
	log_line("[sim %s] lvl=%d weapons=%d %s cores=%d systems=%d luck=%d rarities=%s scrap_earned=%d scrap_spent=%d merchant=%d rerolls=%d supers=%s dps=%.0f hull_avg=%.2f enemies_avg=%.1f enemy_hp=%.0f ttk=%.2fs dmg=%.1f fr=%.2f" % [
		label, p.level, weapons.size(), str(weapons), cores, systems, int(GameManager.player_luck), str(picks),
		GameManager.run_scrap_earned, GameManager.run_scrap_spent, merchant_buys, rerolls_used, str(super_times),
		dps, avg_hp, avg_en, enemy_hp, enemy_hp / maxf(1.0, dps), p.damage, p.fire_rate])

func _finish() -> void:
	log_line("[sim END] picks=" + str(picked_ids))
	get_tree().quit()
