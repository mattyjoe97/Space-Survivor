extends Node
## v3.19 integrity tests: death lock, endless timer, effective damage, reticle lifecycle, overcharge.
var f := 0; var main: Node = null; var fails := 0; var hp_max_after_death := 0.0; var tick := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.selected_character = "viper"; GameManager.run_mode = "endless"; GameManager.reset()
	main = load("res://scenes/Main.tscn").instantiate(); get_tree().root.call_deferred("add_child", main)
func _chk(c: bool, m: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + m); if not c: fails += 1
func _process(_d: float) -> void:
	f += 1
	var p = GameManager.player
	if not is_instance_valid(p): return
	var ui = main.get_node_or_null("UI")
	match f:
		30:
			p.xp_to_next = 1.0e12
			_chk(GameManager.endless_time > 0.0 and GameManager.endless_time < 2.0, "endless timer live from start (%.2f s)" % GameManager.endless_time)
			# effective damage: 30 HP enemy hit for 500 -> chart gets 30, second hit on dead target ignored
			var e = load("res://scenes/Enemy.tscn").instantiate(); e.max_hp = 30.0; e.global_position = p.global_position + Vector2(400, 0); GameManager.spawn(e)
			e.current_hp = 30.0
			GameManager.damage_by_weapon.clear()
			GameManager.record_damage("railgun", 500.0); e.take_damage(500.0)
			GameManager.record_damage("railgun", 500.0); e.take_damage(500.0)
			_chk(absf(float(GameManager.damage_by_weapon.get("railgun", 0.0)) - 30.0) < 0.01, "overkill + dead-target accounting: charted %.0f of 1000 attempted" % float(GameManager.damage_by_weapon.get("railgun", 0.0)))
			# boss burst cap reflected
			var b = load("res://scenes/Boss.tscn").instantiate(); b.global_position = p.global_position + Vector2(-500, 0); GameManager.spawn(b); b.set_physics_process(false)
			GameManager.damage_by_weapon.clear()
			GameManager.record_damage("starbreaker", 100000.0); b.take_damage(100000.0)
			_chk(float(GameManager.damage_by_weapon.get("starbreaker", 0.0)) <= b.max_hp * 0.0251, "boss burst cap reflected in chart (%.0f vs cap %.0f)" % [float(GameManager.damage_by_weapon.get("starbreaker", 0.0)), b.max_hp * 0.025])
			b.queue_free()
			_chk(GameManager.fmt_compact(2356364) == "2.36M" and GameManager.fmt_compact(645879) == "646K" and GameManager.fmt_compact(70642) == "70.6K", "compact formatting")
			# reticles: place on 12 targets, cap 8; one target dies before strike
			for w in ["phase_disruptor"]:
				for i in range(5): GameManager.upgrade_levels[w] = i; p.apply_upgrade(w, 1)
			var pdw = p.weapons.get_weapon("phase_disruptor")
			var victims: Array = []
			for i in range(12):
				var v = load("res://scenes/Enemy.tscn").instantiate(); v.max_hp = 200.0; v.global_position = p.global_position + Vector2(200 + i * 20, 100); GameManager.spawn(v); v.speed = 0.0; v.base_speed = 0.0; victims.append(v)
			var placed := 0
			for v in victims:
				if VoidReticle.try_place(v, pdw, 5.0, 40.0, 0.6): placed += 1
			_chk(placed == 8, "reticle cap: %d of 12 placed (cap 8)" % placed)
			victims[0].take_damage(9999.0)
			set_meta("victims", victims)
			# Silence the live weapon so the count below only tracks the 8 hand-placed reticles.
			pdw.level = 0
		36:
			print("  dbg paused=%s is_paused=%s levelup=%s merchant=%s settings=%s gameover=%s" % [str(get_tree().paused), str(GameManager.is_paused), str(ui.levelup_panel.visible), str(ui.merchant_panel.visible), str(ui.pause_settings_panel.visible if ui.pause_settings_panel else "-"), str(ui.gameover_panel.visible)])
			var n := get_tree().get_nodes_in_group("void_reticles").size()
			_chk(n == 7, "reticle removed when its target died (%d active)" % n)
		80:
			_chk(get_tree().get_nodes_in_group("void_reticles").is_empty(), "all reticles gone after strike / weapon disabled (%d left)" % get_tree().get_nodes_in_group("void_reticles").size())
			p.weapons.get_weapon("phase_disruptor").level = 5
			_chk(GameManager.endless_time > 1.0, "endless timer kept counting before death (%.1f)" % GameManager.endless_time)
			# overcharge fallback: exhaust everything
			for w in GameManager.WEAPON_UPGRADES: GameManager.upgrade_levels[w] = 5
			for sysid in GameManager.SYSTEM_UPGRADES: GameManager.upgrade_levels[sysid] = 3
			for c in GameManager.CORE_DEFS: GameManager.upgrade_levels[c] = GameManager.core_cap(c)
			for m in GameManager.MODIFIER_UPGRADES: GameManager.upgrade_levels[m] = 3
			var ch = GameManager.build_levelup_choices(3, 40)
			var all_oc := ch.size() == 3
			for c in ch:
				if not bool(c.get("is_overcharge", false)): all_oc = false
			_chk(all_oc, "overcharge fallback offers 3 OVERCHARGE cards when progression is exhausted (%d)" % ch.size())
			var d0 = p.damage; p.apply_upgrade("oc_damage", 0)
			_chk(absf(p.damage / d0 - 1.015) < 0.001, "overcharge applies +1.5% damage")
			# now die with a heal pickup adjacent and siphon active, and with reticles active
			p.lifesteal = true
			for v in get_meta("victims"):
				if is_instance_valid(v): VoidReticle.try_place(v, p.weapons.get_weapon("phase_disruptor"), 5.0, 40.0, 1.5)
			var hl = load("res://scenes/Pickup.tscn").instantiate(); hl.pickup_type = 0; hl.global_position = p.global_position + Vector2(10, 0); GameManager.spawn(hl)
			p.xp_to_next = 1.0; p.add_xp(5.0)   # level-up opens
		110:
			_chk(ui.levelup_panel.visible, "level-up panel was open before death")
		112:
			p.invuln_timer = 0.0; p.take_damage(1.0e9)
			p.heal(50.0); p.on_kill_heal(); p.add_xp(1000.0)
		114:
			_chk(p.is_dead and p.current_hp == 0.0, "player dead, HP == 0 (%.1f)" % p.current_hp)
		150:
			_chk(p.current_hp == 0.0, "HP still 0 after heal/siphon/pickup attempts (%.1f)" % p.current_hp)
			_chk(not ui.levelup_panel.visible and not ui.merchant_panel.visible, "level-up/merchant panels closed on death")
			_chk(ui.hp_label.text.begins_with("0 /"), "HUD shows 0 HP (%s)" % ui.hp_label.text)
			_chk(get_tree().get_nodes_in_group("void_reticles").is_empty(), "reticles purged on death")
			var lv0 = GameManager.get_upgrade_level("damage")
			ui._on_upgrade_chosen("damage", 0)
			_chk(GameManager.get_upgrade_level("damage") == lv0, "upgrade selection rejected after death")
		200:
			# restart resets
			GameManager.reset()
			_chk(GameManager.endless_time == 0.0 and GameManager.overcharge_levels == 0, "reset clears endless timer and overcharge")
			print("=== DONE failures=%d" % fails); get_tree().quit(1 if fails > 0 else 0)
