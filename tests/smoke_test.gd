extends Node
## Headless smoke test: godot --headless --path . res://tests/SmokeTest.tscn
## Drives a run through combat, every weapon, elites, boss, level-up, dash and death.

var _frames := 0
var _main: Node = null
var _step := 0

func _ready() -> void:
	call_deferred("_start")

func _start() -> void:
	GameManager.selected_character = "viper"
	GameManager.reset()
	_main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(_main)
	print("[smoke] main loaded")

func _process(_delta: float) -> void:
	_frames += 1
	if _main == null:
		return
	var player = GameManager.player
	if not is_instance_valid(player):
		if _frames > 900: get_tree().quit(0)
		return
	match _frames:
		30:
			print("[smoke] give all weapons")
			GameManager.upgrade_levels.clear()
			for w in GameManager.WEAPON_DEFS.keys():
				for i in range(5):
					GameManager.upgrade_levels[w] = i
					player.apply_upgrade(w, 1)
			GameManager.upgrade_levels_changed.emit()
			GameManager._check_weapon_synergies()
			print("[smoke] supers active: ", GameManager.active_synergies)
		60:
			print("[smoke] spawn enemies of every type")
			var scene = load("res://scenes/Enemy.tscn")
			var types = ["chaser", "swarmer", "armored", "leecher", "teleporter", "sniper", "splitter", "void_spitter"]
			for i in range(types.size()):
				var e = scene.instantiate()
				e.enemy_type = types[i]
				e.global_position = player.global_position + Vector2.from_angle(i * 0.8) * 120.0
				get_tree().root.add_child(e)
		120:
			print("[smoke] damage + kill enemies")
			for e in GameManager.get_enemies():
				if is_instance_valid(e) and e.has_method("take_damage"):
					e.take_damage(5.0, true)
					e.take_damage(9999.0)
		150:
			print("[smoke] dash + hit player")
			Input.action_press("dash")
		152:
			Input.action_release("dash")
			player.take_damage(10.0)
		180:
			print("[smoke] elite spawn + kill")
			var el = load("res://scenes/EliteRammer.tscn").instantiate()
			el.global_position = player.global_position + Vector2(300, 0)
			get_tree().root.add_child(el)
			var es = load("res://scenes/EliteSpitter.tscn").instantiate()
			es.global_position = player.global_position + Vector2(-300, 0)
			get_tree().root.add_child(es)
		220:
			for el in get_tree().get_nodes_in_group("elites"):
				el.take_damage(99999.0)
		260:
			print("[smoke] boss spawn + hit")
			var b = load("res://scenes/Boss.tscn").instantiate()
			b.global_position = player.global_position + Vector2(0, -350)
			get_tree().root.add_child(b)
			GameManager.boss_spawned.emit()
		300:
			for b in get_tree().get_nodes_in_group("boss"):
				b.take_damage(50.0, true)
		330:
			for b in get_tree().get_nodes_in_group("boss"):
				b.take_damage(9999999.0)
		380:
			print("[smoke] level up UI")
			player.add_xp(100000.0)
		440:
			print("[smoke] close level up (pick first)")
			var ui = _main.get_node("UI")
			var cards = ui.find_children("ChoiceCards", "", true, false)
			if cards.size() > 0 and cards[0].get_child_count() > 0:
				cards[0].get_child(0).emit_signal("pressed")
			else:
				get_tree().paused = false
				GameManager.is_paused = false
		500:
			print("[smoke] merchant")
			var m = load("res://scenes/Merchant.tscn").instantiate()
			m.global_position = player.global_position + Vector2(40, 0)
			get_tree().root.add_child(m)
		560:
			get_tree().paused = false
			GameManager.is_paused = false
			print("[smoke] player death")
			player.invuln_timer = 0.0
			player.take_damage(999999.0)
		720:
			print("[smoke] done; music mood=", MusicManager.get_mood(), " music started=", MusicManager._started)
			get_tree().quit(0)
