extends Node
## Boss time-to-kill with a representative late build (level ~18: 4 L5 weapons, 6 damage,
## 5 fire rate, 2 systems), player invulnerable so only DPS is measured.
var f := 0
var main: Node = null
var boss: Node = null
var t0 := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.selected_character = "viper"
	GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.call_deferred("add_child", main)
func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p): return
	if f == 10:
		var sp = main.get_node_or_null("EnemySpawner")
		if sp: sp.set_process(false); sp.set_physics_process(false)
		var mode := OS.get_environment("BOSS_MODE")
		if mode == "":
			p.invuln_timer = 1.0e9
		p.max_hp = 1.0e6; p.current_hp = 1.0e6; p.xp_to_next = 1.0e12; p.level = 18
		for w in ["missile_system", "torpedo_bay", "graviton_mines", "railgun"]:
			for i in range(5):
				GameManager.upgrade_levels[w] = i; p.apply_upgrade(w, 1)
		for i in range(6): GameManager.upgrade_levels["damage"] = i; p.apply_upgrade("damage", 1)
		for i in range(5): GameManager.upgrade_levels["fire_rate"] = i; p.apply_upgrade("fire_rate", 1)
		for i in range(3): GameManager.upgrade_levels["extra_projectile"] = i; p.apply_upgrade("extra_projectile", 1)
		var scene = OS.get_environment("BOSS_SUPER") == "1"
		if scene: GameManager._check_weapon_synergies()
		boss = load("res://scenes/Boss.tscn").instantiate()
		boss.global_position = p.global_position + Vector2(0, -260)
		GameManager.spawn(boss)
		t0 = Time.get_ticks_msec() / 1000.0
		print("[boss] max_hp=%.0f player dmg=%.1f fr=%.2f supers=%s" % [boss.max_hp, p.damage, p.fire_rate, str(GameManager.active_synergies)])
	var mode := OS.get_environment("BOSS_MODE")
	if mode != "" and f > 10 and is_instance_valid(boss):
		# Damage-taken test: stationary on top of the boss / moving in a circle / dodging away from attacks.
		if f == 11:
			p.global_position = boss.global_position + Vector2(20, 0)
			set_meta("hp0", p.current_hp)
		match mode:
			"moving":
				p.global_position = boss.global_position + Vector2.from_angle(float(f) * 0.06) * 150.0
			"dodging":
				var away: Vector2 = (p.global_position - boss.global_position).normalized()
				var flee: bool = boss._close_charge >= 0.0 or boss.is_charging or boss.get_node("BossShield").active
				p.global_position += (away * 260.0 if flee else Vector2(-away.y, away.x) * 160.0) * (1.0 / 60.0)
				if p.global_position.distance_to(boss.global_position) > 420.0:
					p.global_position = boss.global_position + away * 420.0
		if f == 10 + 180:
			print("[boss %s] damage taken over 3 s: %.0f" % [mode, float(get_meta("hp0")) - p.current_hp])
			get_tree().quit()
		return
	if f > 10 and f % 120 == 0 and is_instance_valid(boss):
		print("[boss] +%.1fs hp=%.0f (%.0f%%) phase=%d shield=%s" % [float(f - 10) / 60.0, boss.current_hp, 100.0 * boss.current_hp / boss.max_hp, boss.phase, str(boss.get_node("BossShield").active)])
	if f > 10 and (not is_instance_valid(boss) or boss._dead):
		print("[boss] KILLED after %.1f s of game time" % (float(f - 10) / 60.0))
		get_tree().quit()
	if f > 60 * 200:
		print("[boss] survived 200s"); get_tree().quit()
