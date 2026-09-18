extends Node
## WEAPON POWER-CURVE LAB (reusable). Each weapon is tested alone at five run-time snapshots
## whose weapon level, core investment and enemy stats match a normal run at that minute:
##   1:00 L1 0 cores / HP 59 x8   3:00 L2 1dmg / HP 144 x12   5:00 L3 2dmg 1fr / HP 233 x16
##   7:00 L4 3dmg 2fr / HP 324 x20   10:00 L5 4dmg 3fr / HP 470 x26 (+ elite and boss encounters)
## Each snapshot runs twice: stationary and moving (circle, 220 px/s) — "reliability while moving".
## Run: LAB_WEAPONS=all|a,b LAB_SECONDS=12 LAB_OUT=/tmp/weaponlab.csv godot --headless --path . res://tests/WeaponLab.tscn
## Then: python3 tests/weaponlab_report.py /tmp/weaponlab.csv

const SNAPS := [
	{"min": 1, "lv": 1, "dmg": 0, "fr": 0, "hp": 59.0, "n": 8, "spd": 80.0},
	{"min": 3, "lv": 2, "dmg": 1, "fr": 0, "hp": 144.0, "n": 12, "spd": 90.0},
	{"min": 5, "lv": 3, "dmg": 2, "fr": 1, "hp": 233.0, "n": 16, "spd": 100.0},
	{"min": 7, "lv": 4, "dmg": 3, "fr": 2, "hp": 324.0, "n": 20, "spd": 110.0},
	{"min": 10, "lv": 5, "dmg": 4, "fr": 3, "hp": 470.0, "n": 26, "spd": 120.0},
]
var main: Node = null
var f := 0
var queue: Array = []
var cur: Dictionary = {}
var phase := "boot"
var run_f0 := 0
var seconds := 12.0
var _file: FileAccess = null
var kills0 := 0
var dmg_taken := 0.0
var hp_prev := 0.0
var active_frames := 0
var alive_sum := 0.0
var alive_n := 0
var boss: Node = null
var elites: Array = []
var boss_killed_at := -1.0
var elite_killed_at := -1.0
var dmg_prev_total := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("LAB_SECONDS") != "": seconds = float(OS.get_environment("LAB_SECONDS"))
	var out := OS.get_environment("LAB_OUT") if OS.get_environment("LAB_OUT") != "" else "/tmp/weaponlab.csv"
	var which := OS.get_environment("LAB_WEAPONS")
	var ids: Array = GameManager.WEAPON_UPGRADES.duplicate() if (which == "" or which == "all") else Array(which.split(","))
	for wid in ids:
		for snap in SNAPS:
			for mv in ["still", "moving"]:
				queue.append({"w": wid, "snap": snap, "scenario": "swarm", "move": mv})
		queue.append({"w": wid, "snap": SNAPS[4], "scenario": "elite", "move": "still"})
		queue.append({"w": wid, "snap": SNAPS[4], "scenario": "boss", "move": "still"})
	_file = FileAccess.open(out, FileAccess.WRITE)
	_file.store_line("weapon,minute,scenario,move,seconds,total_damage,dps,kills,kills_per_s,alive_avg,dmg_taken,uptime,boss_ttk,elite_ttk")
	GameManager.selected_character = "viper"
	GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.call_deferred("add_child", main)

func _log(line: String) -> void:
	_file.store_line(line); _file.flush(); printerr(line)

func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p): return
	match phase:
		"boot":
			if main == null or not is_instance_valid(main): main = get_tree().root.get_node_or_null("Main")
			if f > 10 and main:
				var sp = main.get_node_or_null("EnemySpawner")
				if sp: sp.set_process(false); sp.set_physics_process(false)
				phase = "next"
		"next":
			if queue.is_empty():
				_log("# done"); get_tree().quit(); return
			cur = queue.pop_front(); _setup_run(p); phase = "run"
		"run": _tick_run(p)

func _clear_world() -> void:
	for g in ["enemies", "elites", "boss", "xp_gems", "scrap_pickups", "pickups", "projectiles", "enemy_bullets", "tesla_coils", "run_vfx", "damage_numbers"]:
		for n in get_tree().get_nodes_in_group(g):
			if is_instance_valid(n): n.queue_free()
	for n in main.get_children():
		if n.is_in_group("run_entity") and not (n is CanvasLayer): n.queue_free()

func _set_build(p: Node) -> void:
	var snap: Dictionary = cur["snap"]
	p.weapons.deactivate_all_supers(); GameManager.active_synergies.clear()
	for w in GameManager.WEAPON_UPGRADES: GameManager.upgrade_levels[w] = 0
	for c in GameManager.CORE_DEFS.keys(): GameManager.upgrade_levels[c] = 0
	p._apply_character()
	p.weapons.sync_levels()
	for i in range(int(snap["lv"])): GameManager.upgrade_levels[cur["w"]] = i; p.apply_upgrade(cur["w"], 1)
	for i in range(int(snap["dmg"])): GameManager.upgrade_levels["damage"] = i; p.apply_upgrade("damage", 1)
	for i in range(int(snap["fr"])): GameManager.upgrade_levels["fire_rate"] = i; p.apply_upgrade("fire_rate", 1)
	p.max_hp = 1.0e6; p.current_hp = 1.0e6; p.level = 2 + int(snap["min"]) * 2; p.xp_to_next = 1.0e12
	get_tree().paused = false; GameManager.is_paused = false
	# Primary cannons are excluded so the weapon is measured alone.
	p.projectile_count = 0

func _spawn_enemy(at: Vector2, hp: float, spd: float, type: String) -> void:
	var e = load("res://scenes/Enemy.tscn").instantiate()
	e.enemy_type = type; e.max_hp = hp; e.global_position = at
	GameManager.spawn(e); e.speed = spd; e.base_speed = spd

func _spawn_ring(p: Node, n: int, radius: float, hp: float, spd: float) -> void:
	var types := ["chaser", "swarmer", "chaser", "armored", "chaser", "void_spitter"]
	for i in range(n):
		_spawn_enemy(p.global_position + Vector2.from_angle(float(i) / n * TAU) * radius, hp, spd, types[i % types.size()])

func _setup_run(p: Node) -> void:
	_clear_world(); _set_build(p)
	p.global_position = Vector2.ZERO; p.invuln_timer = 0.0
	GameManager.damage_by_weapon.clear()
	kills0 = GameManager.run_kills; dmg_taken = 0.0; hp_prev = p.current_hp
	active_frames = 0; alive_sum = 0.0; alive_n = 0; boss = null; elites = []; boss_killed_at = -1.0; elite_killed_at = -1.0; dmg_prev_total = 0.0
	var snap: Dictionary = cur["snap"]
	match cur["scenario"]:
		"swarm": _spawn_ring(p, int(snap["n"]), 300.0, float(snap["hp"]), float(snap["spd"]))
		"elite":
			for sc in ["res://scenes/EliteRammer.tscn", "res://scenes/EliteSpitter.tscn"]:
				var el = load(sc).instantiate()
				el.global_position = p.global_position + Vector2(300 if sc.ends_with("Rammer.tscn") else -300, 60)
				GameManager.spawn(el); elites.append(el)
			_spawn_ring(p, 6, 320.0, float(snap["hp"]), 90.0)
		"boss":
			boss = load("res://scenes/Boss.tscn").instantiate()
			boss.global_position = p.global_position + Vector2(0, -220)
			GameManager.spawn(boss)
	run_f0 = f

func _total_damage() -> float:
	var t := 0.0
	for k in GameManager.damage_by_weapon: t += float(GameManager.damage_by_weapon[k])
	return t

func _tick_run(p: Node) -> void:
	var el := float(f - run_f0) / 60.0
	var snap: Dictionary = cur["snap"]
	if cur["move"] == "moving":
		p.global_position = Vector2.from_angle(el * 1.1) * 200.0
		p.rotation = el * 1.1 + PI * 0.5
	var alive := GameManager.get_enemies().size()
	alive_sum += alive; alive_n += 1
	if cur["scenario"] == "swarm" and alive < int(snap["n"]) / 2 and int(f - run_f0) % 30 == 0:
		_spawn_ring(p, int(snap["n"]), 320.0, float(snap["hp"]), float(snap["spd"]))
	if p.current_hp < hp_prev: dmg_taken += hp_prev - p.current_hp
	hp_prev = p.current_hp
	var tot := _total_damage()
	if tot > dmg_prev_total + 0.01: active_frames += 1
	dmg_prev_total = tot
	if boss and (not is_instance_valid(boss) or boss._dead) and boss_killed_at < 0.0: boss_killed_at = el
	if not elites.is_empty() and elite_killed_at < 0.0:
		var all_dead := true
		for e in elites:
			if is_instance_valid(e) and not e._dead: all_dead = false
		if all_dead: elite_killed_at = el
	var done: bool = el >= seconds or (cur["scenario"] == "boss" and boss_killed_at >= 0.0)
	if not done: return
	_log("%s,%d,%s,%s,%.1f,%.0f,%.1f,%d,%.2f,%.1f,%.0f,%.2f,%.1f,%.1f" % [cur["w"], int(snap["min"]), cur["scenario"], cur["move"], el, tot, tot / maxf(0.1, el), GameManager.run_kills - kills0, float(GameManager.run_kills - kills0) / maxf(0.1, el), alive_sum / maxf(1, alive_n), dmg_taken, float(active_frames) / maxf(1.0, float(f - run_f0)), boss_killed_at, elite_killed_at])
	phase = "next"
