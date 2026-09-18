extends Node
## SUPERWEAPON BALANCE LAB (reusable).
## Runs each superweapon through 4 configurations x 4 scenarios, in-process, and writes CSV.
##   configs:   A (parent A L5) | B (parent B L5) | AB (both L5, not evolved) | SUPER (evolved)
##   scenarios: standard (ring of 12, HP 600, rushing) | dense (30, HP 350) | elite (rammer+spitter) | boss
## Run:  LAB_SUPER=all|<synergy_id> LAB_OUT=/tmp/superlab.csv LAB_SECONDS=15 \
##       godot --headless --path . res://tests/SuperLab.tscn
## Then: python3 tests/superlab_report.py /tmp/superlab.csv

const SCENARIOS := ["standard", "dense", "elite", "boss"]
const CONFIGS := ["A", "B", "AB", "SUPER"]

var main: Node = null
var f := 0
var queue: Array = []          # [sid, config, scenario]
var cur: Array = []
var phase := "boot"
var run_f0 := 0
var seconds := 15.0
var out_path := "/tmp/superlab.csv"
var _file: FileAccess = null
# per-run accumulators
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
	if OS.get_environment("LAB_SECONDS") != "":
		seconds = float(OS.get_environment("LAB_SECONDS"))
	if OS.get_environment("LAB_OUT") != "":
		out_path = OS.get_environment("LAB_OUT")
	var which := OS.get_environment("LAB_SUPER")
	var ids: Array = GameManager.WEAPON_SYNERGIES.keys() if (which == "" or which == "all") else [which]
	for sid in ids:
		for cfg in CONFIGS:
			for sc in SCENARIOS:
				queue.append([sid, cfg, sc])
	_file = FileAccess.open(out_path, FileAccess.WRITE)
	_file.store_line("super,config,scenario,seconds,total_damage,dps,kills,kills_per_s,alive_avg,dmg_taken,active_uptime,boss_damage,boss_ttk,elite_damage,elite_ttk,by_source")
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
			if main == null or not is_instance_valid(main):
				main = get_tree().root.get_node_or_null("Main")
			if f > 10 and main:
				var sp = main.get_node_or_null("EnemySpawner")
				if sp: sp.set_process(false); sp.set_physics_process(false)
				p.max_hp = 1.0e6; p.current_hp = 1.0e6; p.xp_to_next = 1.0e12; p.level = 16
				phase = "next"
		"next":
			if queue.is_empty():
				_log("# done"); get_tree().quit(); return
			cur = queue.pop_front()
			_setup_run(p)
			phase = "run"
		"run":
			_tick_run(p)

func _clear_world() -> void:
	for g in ["enemies", "elites", "boss", "xp_gems", "scrap_pickups", "pickups", "projectiles", "enemy_bullets", "tesla_coils", "run_vfx", "damage_numbers"]:
		for n in get_tree().get_nodes_in_group(g):
			if is_instance_valid(n): n.queue_free()
	for n in get_tree().root.get_children():
		if n.is_in_group("run_entity") and n != main: n.queue_free()
	for n in main.get_children():
		if n.is_in_group("run_entity") and not (n is CanvasLayer): n.queue_free()

func _set_build(p: Node, sid: String, cfg: String) -> void:
	var reqs: Array = GameManager.WEAPON_SYNERGIES[sid].requires
	p.weapons.deactivate_all_supers()
	GameManager.active_synergies.clear()
	for w in GameManager.WEAPON_UPGRADES:
		GameManager.upgrade_levels[w] = 0
	p.weapons.sync_levels()
	var want: Array = []
	match cfg:
		"A": want = [reqs[0]]
		"B": want = [reqs[1]]
		_: want = [reqs[0], reqs[1]]
	for w in want:
		for i in range(5):
			GameManager.upgrade_levels[w] = i; p.apply_upgrade(w, 1)
	# comparable core investment for every config: 3 damage, 2 fire rate
	GameManager.upgrade_levels["damage"] = 0; GameManager.upgrade_levels["fire_rate"] = 0
	p._apply_character()
	p.max_hp = 1.0e6; p.current_hp = 1.0e6; p.level = 16; p.xp_to_next = 1.0e12
	get_tree().paused = false; GameManager.is_paused = false
	for i in range(3): GameManager.upgrade_levels["damage"] = i; p.apply_upgrade("damage", 1)
	for i in range(2): GameManager.upgrade_levels["fire_rate"] = i; p.apply_upgrade("fire_rate", 1)
	if cfg == "SUPER":
		GameManager._check_weapon_synergies()
	else:
		# apply_upgrade auto-evolves at 5/5 + 5/5; the un-evolved AB config must undo that.
		p.weapons.deactivate_all_supers()
		GameManager.active_synergies.clear()

func _spawn_enemy(p: Node, at: Vector2, hp: float, spd: float, type: String = "chaser") -> void:
	var e = load("res://scenes/Enemy.tscn").instantiate()
	e.enemy_type = type; e.max_hp = hp; e.global_position = at
	GameManager.spawn(e)
	e.speed = spd; e.base_speed = spd

func _spawn_ring(p: Node, n: int, radius: float, hp: float, spd: float) -> void:
	for i in range(n):
		_spawn_enemy(p, p.global_position + Vector2.from_angle(float(i) / n * TAU) * radius, hp, spd, ["chaser","swarmer","armored","chaser"][i % 4])

func _setup_run(p: Node) -> void:
	_clear_world()
	_set_build(p, cur[0], cur[1])
	p.global_position = Vector2.ZERO
	p.invuln_timer = 0.0
	GameManager.damage_by_weapon.clear()
	kills0 = GameManager.run_kills; dmg_taken = 0.0; hp_prev = p.current_hp
	active_frames = 0; alive_sum = 0.0; alive_n = 0; boss = null; elites = []; boss_killed_at = -1.0; elite_killed_at = -1.0; dmg_prev_total = 0.0
	match cur[2]:
		"standard": _spawn_ring(p, 12, 300.0, 600.0, 90.0)
		"dense": _spawn_ring(p, 30, 260.0, 350.0, 110.0)
		"elite":
			for sc in ["res://scenes/EliteRammer.tscn", "res://scenes/EliteSpitter.tscn"]:
				var el = load(sc).instantiate()
				el.global_position = p.global_position + Vector2(340 if sc.ends_with("Rammer.tscn") else -340, 80)
				GameManager.spawn(el); elites.append(el)
			_spawn_ring(p, 6, 320.0, 400.0, 80.0)
		"boss":
			boss = load("res://scenes/Boss.tscn").instantiate()
			boss.global_position = p.global_position + Vector2(0, -300)
			GameManager.spawn(boss)
	run_f0 = f

func _total_damage() -> float:
	var t := 0.0
	for k in GameManager.damage_by_weapon: t += float(GameManager.damage_by_weapon[k])
	return t

func _tick_run(p: Node) -> void:
	var el := float(f - run_f0) / 60.0
	# top up swarms so clearing speed is measurable
	var alive := GameManager.get_enemies().size()
	alive_sum += alive; alive_n += 1
	if cur[2] in ["standard", "dense"] and alive < (6 if cur[2] == "standard" else 14) and int(f - run_f0) % 30 == 0:
		_spawn_ring(p, 12 if cur[2] == "standard" else 16, 300.0, 600.0 if cur[2] == "standard" else 350.0, 90.0)
	# player takes real damage (huge pool) so defensive contribution is measurable
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
	var done: bool = el >= seconds or (cur[2] == "boss" and boss_killed_at >= 0.0)
	if not done: return
	var kills := GameManager.run_kills - kills0
	var boss_dmg := 0.0; var elite_dmg := 0.0
	if cur[2] == "boss": boss_dmg = tot
	if cur[2] == "elite": elite_dmg = tot
	var by := ""
	for k in GameManager.damage_by_weapon: by += "%s:%d " % [k, int(GameManager.damage_by_weapon[k])]
	_log("%s,%s,%s,%.1f,%.0f,%.1f,%d,%.2f,%.1f,%.0f,%.2f,%.0f,%.1f,%.0f,%.1f,%s" % [cur[0], cur[1], cur[2], el, tot, tot / maxf(0.1, el), kills, kills / maxf(0.1, el), alive_sum / maxf(1, alive_n), dmg_taken, float(active_frames) / maxf(1.0, float(f - run_f0)), boss_dmg, boss_killed_at, elite_dmg, elite_killed_at, by.strip_edges()])
	phase = "next"
