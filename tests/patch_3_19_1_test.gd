extends Node
## 3.19.1: real Overcharge level-up flow + atomic damage attribution regression.
var f := 0; var main: Node = null; var fails := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.selected_character = "viper"; GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate(); get_tree().root.call_deferred("add_child", main)
func _chk(c: bool, m: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + m); if not c: fails += 1
func _cards(ui: Node) -> Array:
	var out: Array = []
	for c in ui.upgrade_container.get_children():
		if c is VBoxContainer:
			for b in c.get_children():
				if b is Button and b.has_meta("up"): out.append(b)
	return out
func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p): return
	var ui = main.get_node_or_null("UI")
	match f:
		20:
			var sp = main.get_node_or_null("EnemySpawner"); if sp: sp.set_process(false); sp.set_physics_process(false)
			p.max_hp = 1.0e6; p.current_hp = 1.0e6
			print("=== DAMAGE ATTRIBUTION")
			var b = load("res://scenes/Boss.tscn").instantiate(); b.global_position = p.global_position + Vector2(-500, 0); GameManager.spawn(b); b.set_physics_process(false)
			var e = load("res://scenes/Enemy.tscn").instantiate(); e.max_hp = 100.0; e.global_position = p.global_position + Vector2(500, 0); GameManager.spawn(e); e.current_hp = 100.0
			var e2 = load("res://scenes/Enemy.tscn").instantiate(); e2.max_hp = 25.0; e2.global_position = p.global_position + Vector2(500, 200); GameManager.spawn(e2); e2.current_hp = 25.0
			GameManager.damage_by_weapon.clear()
			# A/B/C: railgun into a shielded boss -> blocked, nothing committed, no stale source
			b.get_node("BossShield").raise(3.0)
			GameManager.record_damage("railgun", 900.0); b.take_damage(900.0)
			_chk(not GameManager.damage_by_weapon.has("railgun"), "A/B shielded boss: railgun committed nothing")
			_chk(GameManager._pending_source == "", "C no railgun source left pending")
			# D/E: unrelated source right after
			GameManager.record_damage("scattergun", 40.0); e.take_damage(40.0)
			_chk(GameManager.damage_by_weapon.keys() == ["scattergun"] and absf(float(GameManager.damage_by_weapon["scattergun"]) - 40.0) < 0.01, "D/E second hit attributed only to scattergun (%s)" % str(GameManager.damage_by_weapon))
			# dead target + zero damage do not leave a source either
			GameManager.record_damage("torpedo_bay", 500.0); e2.take_damage(500.0)   # 25 effective, dies
			GameManager.record_damage("torpedo_bay", 500.0); e2.take_damage(500.0)   # dead: consumed, nothing
			GameManager.record_damage("plasma_lance", 0.0); e.take_damage(0.0)       # zero
			e.take_damage(10.0)   # unannounced hit -> "other", never inherits lance/torpedo
			_chk(absf(float(GameManager.damage_by_weapon.get("torpedo_bay", 0.0)) - 25.0) < 0.01, "overkill excluded, dead target excluded (torpedo 25 of 1000)")
			_chk(not GameManager.damage_by_weapon.has("plasma_lance") and absf(float(GameManager.damage_by_weapon.get("other", 0.0)) - 10.0) < 0.01, "zero-damage hit leaves no source; unannounced hit -> other (%s)" % str(GameManager.damage_by_weapon))
			# crit / status / explosion / dash / relic / super attribution through the real helpers
			var w = p.weapons.get_weapon("railgun"); w.set_level(1)
			w.hit(e, 5.0, "", true); _chk(absf(float(GameManager.damage_by_weapon.get("railgun", 0.0)) - 10.0) < 0.01, "crit via WeaponBase.hit -> railgun 10")
			StatusHost.apply(e, "burn", 1.0, 2.0, "flamethrower")
			p.dash_direction = Vector2.RIGHT; p.dash_timer = 0.2; p.global_position = e.global_position - Vector2(30, 0); p._dash_impact()
			_chk(float(GameManager.damage_by_weapon.get("ship_ability", 0.0)) > 0.0, "dash -> ship_ability")
			GameManager.record_damage("orbit_drones", 3.0); e.take_damage(3.0)
			_chk(absf(float(GameManager.damage_by_weapon.get("orbit_drones", 0.0)) - 3.0) < 0.01, "relic -> orbit_drones")
			GameManager.record_damage("starbreaker", 4.0); e.take_damage(4.0)
			_chk(absf(float(GameManager.damage_by_weapon.get("starbreaker", 0.0)) - 4.0) < 0.01, "superweapon attribution")
			set_meta("e", e); p.global_position = Vector2.ZERO
		60:
			_chk(float(GameManager.damage_by_weapon.get("flamethrower", 0.0)) > 0.0, "DoT ticks -> flamethrower (%.1f)" % float(GameManager.damage_by_weapon.get("flamethrower", 0.0)))
			print("=== OVERCHARGE REAL FLOW")
			for w in GameManager.WEAPON_UPGRADES: GameManager.upgrade_levels[w] = 5
			for sysid in GameManager.SYSTEM_UPGRADES: GameManager.upgrade_levels[sysid] = 3
			for c in GameManager.CORE_DEFS: GameManager.upgrade_levels[c] = GameManager.core_cap(c)
			for m in GameManager.MODIFIER_UPGRADES: GameManager.upgrade_levels[m] = 3
			_chk(not GameManager.has_any_available_upgrade(), "build is exhausted")
			set_meta("dmg0", p.damage); set_meta("hp0", p.current_hp); set_meta("scrap0", GameManager.scrap)
			p.xp_to_next = 1.0; p.add_xp(5.0)   # REAL level-up
		100:
			_chk(ui.levelup_panel.visible, "level-up panel opened for an exhausted build")
			var cards := _cards(ui)
			var all_oc := cards.size() == 3
			for c in cards:
				if not bool(c.get_meta("up").get("is_overcharge", false)): all_oc = false
			_chk(all_oc, "3 OVERCHARGE cards displayed (%d cards)" % cards.size())
			_chk(GameManager.scrap == int(get_meta("scrap0")), "no automatic scrap fallback")
			if cards.size() > 0:
				set_meta("pick", str(cards[0].get_meta("up").get("id", "")))
				cards[0].emit_signal("pressed")
		110:
			_chk(not ui.levelup_panel.visible and not get_tree().paused, "panel closed and run resumed after picking")
			_chk(GameManager.overcharge_levels == 1, "overcharge applied (count %d, picked %s)" % [GameManager.overcharge_levels, str(get_meta("pick"))])
			p.xp_to_next = 1.0; p.add_xp(5.0)   # second real level-up
		150:
			var cards := _cards(ui)
			var oc := cards.size() == 3 and bool(cards[0].get_meta("up").get("is_overcharge", false))
			_chk(ui.levelup_panel.visible and oc, "second level-up offers Overcharge again")
			if cards.size() > 0: cards[1].emit_signal("pressed")
		160:
			_chk(GameManager.overcharge_levels == 2, "second overcharge applied (%d)" % GameManager.overcharge_levels)
			GameManager.reset()
			_chk(GameManager.overcharge_levels == 0, "restart resets overcharge")
			print("=== DONE failures=%d" % fails); get_tree().quit(1 if fails > 0 else 0)
