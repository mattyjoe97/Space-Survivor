extends Node
## Dash / forcefield / Void Blades control test (headless).
var f := 0; var main: Node = null; var fails := 0; var ship := "viper"
var small: Node = null; var med: Node = null; var elite: Node = null; var boss: Node = null
var shield_mismatch := 0; var shield_frames := 0; var p0: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ship = OS.get_environment("DASH_SHIP") if OS.get_environment("DASH_SHIP") != "" else "viper"
	GameManager.selected_character = ship; GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate(); get_tree().root.call_deferred("add_child", main)
func _chk(c: bool, m: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + m); if not c: fails += 1
func _spawn(type: String, at: Vector2) -> Node:
	var e = load("res://scenes/Enemy.tscn").instantiate(); e.enemy_type = type; e.max_hp = 5000.0; e.global_position = at
	GameManager.spawn(e); e.speed = 0.0; e.base_speed = 0.0; return e
func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p): return
	if f == 10:
		var sp = main.get_node_or_null("EnemySpawner"); if sp: sp.set_process(false); sp.set_physics_process(false)
		p.max_hp = 1.0e6; p.current_hp = 1.0e6; p.xp_to_next = 1.0e12; p.global_position = Vector2.ZERO
		for w in GameManager.WEAPON_UPGRADES: GameManager.upgrade_levels[w] = 0
		p.weapons.sync_levels()
		GameManager.damage_by_weapon.clear()
		small = _spawn("chaser", Vector2(60, 0)); med = _spawn("armored", Vector2(110, 0))
		elite = load("res://scenes/EliteRammer.tscn").instantiate(); elite.global_position = Vector2(170, 0); GameManager.spawn(elite); elite.speed = 0.0; elite.base_speed = 0.0
		boss = load("res://scenes/Boss.tscn").instantiate(); boss.global_position = Vector2(240, 0); GameManager.spawn(boss); boss.speed = 0.0; boss.set_physics_process(false); boss.set_process(false)
		p0 = {"s": small.global_position.x, "m": med.global_position.x, "e": elite.global_position.x, "b": boss.global_position.x}
		print("=== DASH TEST ship=%s charges=%d/%d" % [ship, p.dash_charges, p.dash_charges_max])
	if f == 12:
		Input.action_press("move_right"); Input.action_press("dash")
	if f == 14:
		Input.action_release("dash")
	if f > 12 and f < 80:
		# forcefield sync audit every frame
		var should: bool = p.dash_iframe_timer > 0.0 and p.invuln_timer > 0.0
		if p._dash_shield.visible != should: shield_mismatch += 1
		if p._dash_shield.visible: shield_frames += 1
	if f == 40:
		Input.action_release("move_right")
		_chk(GameManager.damage_by_weapon.has("ship_ability") and float(GameManager.damage_by_weapon["ship_ability"]) > 0.0, "dash damage recorded as ship_ability (%.0f)" % float(GameManager.damage_by_weapon.get("ship_ability", 0.0)))
		_chk(small.global_position.x - p0["s"] > 30.0, "small enemy knocked back (%.0f px)" % (small.global_position.x - p0["s"]))
		_chk(med.global_position.x - p0["m"] > 15.0 and med.global_position.x - p0["m"] < small.global_position.x - p0["s"] + 1.0, "medium enemy moderate knockback (%.0f px)" % (med.global_position.x - p0["m"]))
		_chk(absf(elite.global_position.x - p0["e"]) < 30.0, "elite barely displaced (%.0f px)" % (elite.global_position.x - p0["e"]))
		_chk(absf(boss.global_position.x - p0["b"]) < 1.0, "boss not displaced (%.1f px)" % (boss.global_position.x - p0["b"]))
		_chk(p.dash_charges == p.dash_charges_max - 1 and p.dash_recharge.size() == 1, "charge consumed, recharging (%d/%d)" % [p.dash_charges, p.dash_charges_max])
	if f == 80:
		_chk(shield_mismatch == 0 and shield_frames > 5, "forcefield matched the real i-frame window every frame (visible %d frames, mismatches %d)" % [shield_frames, shield_mismatch])
		_chk(not p._dash_shield.visible, "forcefield gone after i-frames")
		GameManager.gain_relic("twin_thrusters"); GameManager.gain_relic("phase_thrusters")
		_chk(p.dash_charges_max == 3, "Twin + Phase Thrusters -> 3 charges (%d)" % p.dash_charges_max)
	if f == 90:
		Input.action_press("dash")
	if f == 92:
		Input.action_release("dash"); Input.action_press("dash")
	if f == 94:
		Input.action_release("dash")
	if f == 130:
		_chk(p.dash_recharge.size() >= 2, "two spent charges recharge independently (%d timers)" % p.dash_recharge.size())
		_chk(p.dash_charges < p.dash_charges_max, "no infinite charge loop (%d/%d)" % [p.dash_charges, p.dash_charges_max])
		# Void Blades L5 sanity: shockwave fires, blades shove smalls, boss unmoved
		for i in range(5): GameManager.upgrade_levels["void_blades"] = i; p.apply_upgrade("void_blades", 1)
		small.global_position = Vector2(70, 0); med.global_position = Vector2(-100, 0)
		p0["b"] = boss.global_position.x; p0["s2"] = small.global_position.length()
	if f == 330:
		_chk(float(GameManager.damage_by_weapon.get("void_blades", 0.0)) > 0.0, "Void Blades L5 dealing damage (%.0f)" % float(GameManager.damage_by_weapon.get("void_blades", 0.0)))
		_chk(absf(boss.global_position.x - p0["b"]) < 1.0, "boss immune to blade displacement")
		print("=== DONE ship=%s failures=%d" % [ship, fails]); get_tree().quit(1 if fails > 0 else 0)
