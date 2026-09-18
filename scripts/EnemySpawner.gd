extends Node2D

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var elite_spitter_scene: PackedScene
@export var elite_rammer_scene: PackedScene
@export var merchant_scene: PackedScene
@export var spawn_radius_min: float = 520.0
@export var spawn_radius_max: float = 780.0

var spawn_timer: float = 0.0
var base_spawn_interval: float = 1.08
var enemies_per_spawn: int = 1
var elapsed: float = 0.0
var boss_instance: Node2D = null

var elite_schedule: Array[float] = [120.0, 300.0, 480.0]
var next_elite_index: int = 0
var merchant_times: Array[float] = [150.0, 330.0, 510.0]
var next_merchant_index: int = 0
var next_event_time: float = 75.0
var next_sector_time: float = 120.0
var next_threat_time: float = 60.0
var next_miniboss_time: float = 180.0
var event_timer: float = 0.0

func _ready() -> void:
	if not enemy_scene: enemy_scene = preload("res://scenes/Enemy.tscn")
	if not boss_scene: boss_scene = preload("res://scenes/Boss.tscn")
	if not elite_spitter_scene: elite_spitter_scene = preload("res://scenes/EliteSpitter.tscn")
	if not elite_rammer_scene: elite_rammer_scene = preload("res://scenes/EliteRammer.tscn")
	if not merchant_scene: merchant_scene = preload("res://scenes/Merchant.tscn")

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over or GameManager.is_victory:
		return

	elapsed += delta
	if GameManager.event_scrap_time > 0.0:
		GameManager.event_scrap_time -= delta
		if GameManager.event_scrap_time <= 0.0:
			GameManager.event_scrap_multiplier = 1.0
	if GameManager.event_enemy_time > 0.0:
		GameManager.event_enemy_time -= delta
		if GameManager.event_enemy_time <= 0.0:
			GameManager.event_enemy_speed_multiplier = 1.0
	GameManager.game_time = elapsed
	if elapsed >= next_threat_time and not GameManager.is_boss_phase:
		GameManager.set_threat(1 + int(elapsed / 60.0))
		GameManager.random_event.emit("THREAT LEVEL %d  •  %s" % [GameManager.threat_level, GameManager.threat_label])
		next_threat_time += 60.0
	GameManager.run_time_updated.emit(GameManager.get_time_left())
	if int(elapsed) != int(elapsed - delta):
		GameManager.update_time_contract(1)
	if GameManager.run_mode == "endless":
		# Live elapsed time from 0:00; achievements/contracts read this value.
		GameManager.endless_time = elapsed
		if elapsed >= GameManager.RUN_DURATION:
			GameManager._check_achievements()
	GameManager.update_mission("wave")
	GameManager.update_mission("scrap")

	if GameManager.run_mode == "standard" and elapsed >= GameManager.RUN_DURATION and not GameManager.boss_spawned_flag:
		_spawn_boss()
		return
	if elapsed >= next_sector_time and not GameManager.is_boss_phase:
		_change_sector()
		next_sector_time += 120.0
	if elapsed >= next_miniboss_time and not GameManager.is_boss_phase:
		_spawn_miniboss()
		next_miniboss_time += 180.0
	if elapsed >= next_event_time and not GameManager.is_boss_phase:
		_trigger_random_event()
		next_event_time += 75.0

	if GameManager.is_boss_phase:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_enemy(true)
			spawn_timer = 1.8
		return

	# Phase 1: controlled population and slower early pacing.
	var difficulty = 1.0 + elapsed / 90.0
	var interval = max(0.30, base_spawn_interval / difficulty)
	enemies_per_spawn = 1 if elapsed < 45.0 else (2 if elapsed < 150.0 else (3 if elapsed < 360.0 else 4))
	# Population cap grows with time (24 -> ~80 at 10:00) so pressure keeps rising even
	# when the build clears the screen; the old fixed cap of 24 made minute 3 feel like minute 8.
	var cap: int = 24 + int(elapsed / 10.5)
	var active_enemies := GameManager.get_enemies().size()
	if active_enemies >= int(float(cap) * 0.75):
		interval *= 1.25

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		if active_enemies < cap:
			var room := cap - active_enemies
			var count := mini(enemies_per_spawn, room)
			for i in range(count):
				_spawn_enemy(false)
		spawn_timer = interval

	if GameManager.run_mode == "endless" and elapsed >= 500.0 and fmod(elapsed, 45.0) < 0.25:
		_spawn_elite()
	if elapsed >= 240.0 and fmod(elapsed, 75.0) < delta * 1.01:
		_spawn_elite()

	if next_elite_index < elite_schedule.size() and elapsed >= elite_schedule[next_elite_index]:
		if get_tree().get_nodes_in_group("elites").size() < 1:
			_spawn_elite()
		next_elite_index += 1

	if next_merchant_index < merchant_times.size() and elapsed >= merchant_times[next_merchant_index] and not GameManager.is_boss_phase:
		next_merchant_index += 1
		if get_tree().get_nodes_in_group("merchants").is_empty():
			_spawn_merchant()

	var expected_wave = 1 + int(elapsed / 50.0) + (int(max(0.0, elapsed - 600.0) / 30.0) if GameManager.run_mode == "endless" else 0)
	if expected_wave > GameManager.current_wave:
		GameManager.next_wave()

func _change_sector() -> void:
	var next = (GameManager.sector_index + 1) % GameManager.SECTORS.size()
	GameManager.set_sector(next)
	GameManager.random_event.emit("SECTOR: %s  •  %s" % [GameManager.current_sector, GameManager.current_sector_gimmick])
	if GameManager.current_sector == "DERELICT STATION" and GameManager.player:
		GameManager.player.heal(GameManager.player.max_hp * 0.12)
		GameManager.add_scrap(30)

func _spawn_boss() -> void:
	if not GameManager.player: return
	GameManager.boss_spawned_flag = true
	GameManager.is_boss_phase = true
	GameManager.next_wave()
	var angle = randf() * TAU
	var pos = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * 420.0
	boss_instance = boss_scene.instantiate()
	boss_instance.global_position = pos
	GameManager.spawn(boss_instance)
	GameManager.boss_spawned.emit()

func _spawn_elite() -> void:
	if not GameManager.player: return
	if get_tree().get_nodes_in_group("elites").size() >= 1:
		return
	var angle = randf() * TAU
	var dist = randf_range(430.0, 560.0)
	var pos = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var elite: Node2D = elite_spitter_scene.instantiate() if randf() < 0.5 else elite_rammer_scene.instantiate()
	elite.global_position = pos
	var t = elapsed
	elite.max_hp *= 1.0 + t / 500.0
	# Elites are meant to be a visible threat, not something erased instantly.
	if t < 360.0:
		elite.max_hp *= 1.35
	elite.speed *= 1.0 + min(t / 500.0, 0.22)
	elite.xp_value *= 1.0 + t / 300.0
	GameManager.spawn(elite)
	AudioManager.play("elite_spawn", 1.0, -3.0)
	VFX.shockwave(pos, 90.0, Color(1.0, 0.6, 0.3, 0.8), 3.0, 0.5)
	VFX.sparks(pos, 16, Color(1.0, 0.7, 0.4), 180.0, 0.5)

func _spawn_miniboss() -> void:
	if not GameManager.player:
		return
	var angle = randf() * TAU
	var pos = GameManager.player.global_position + Vector2.from_angle(angle) * randf_range(600.0, 760.0)
	var mini = elite_rammer_scene.instantiate()
	mini.global_position = pos
	mini.max_hp *= 3.5
	mini.speed *= 0.85
	mini.contact_damage *= 1.7
	mini.xp_value *= 4.0
	mini.score_value *= 8
	var threat_mult = GameManager.get_threat_multiplier()
	mini.max_hp *= threat_mult
	mini.xp_value *= threat_mult
	mini.scale = Vector2(1.65, 1.65)
	GameManager.spawn(mini)
	GameManager.random_event.emit("COMMANDER INBOUND  •  Mini-boss detected")

func _spawn_merchant() -> void:
	if not GameManager.player: return
	var angle = randf() * TAU
	var pos = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * 300.0
	var m = merchant_scene.instantiate()
	m.global_position = pos
	GameManager.spawn(m)

func _spawn_enemy(is_add: bool = false) -> void:
	if not GameManager.player: return
	var angle = randf() * TAU
	var dist = randf_range(spawn_radius_min, spawn_radius_max)
	var pos = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	var t = elapsed
	if is_add:
		enemy.max_hp = 45.0 + t * 0.5
		enemy.speed = 100.0 + randf_range(-10, 20)
		enemy.contact_damage = 11.0
		enemy.xp_value = 7.0
		enemy.score_value = 18
	else:
		enemy.max_hp = 18.0 + t * 0.55 + pow(t / 70.0, 1.18) * 9.0
		if t >= 300.0:
			enemy.max_hp *= 1.12
		var threat_mult = GameManager.get_threat_multiplier()
		enemy.max_hp *= threat_mult
		enemy.speed = 76.0 + min(t * 0.48, 92.0) + randf_range(-10, 14)
		enemy.contact_damage = (6.5 + min(t * 0.065, 12.0)) * (1.0 + float(max(0, GameManager.threat_level - 1)) * 0.025)
		enemy.xp_value = (3.5 + t * 0.018) * (1.0 + float(max(0, GameManager.threat_level - 1)) * 0.035)
		enemy.score_value = 6 + int(t / 15.0)
	var roll = randf()
	var bias = GameManager.get_sector_bias()
	if elapsed > 35.0:
		if bias == "swarm" and roll < 0.22: enemy.enemy_type = "swarmer"
		elif bias == "armored" and roll < 0.16: enemy.enemy_type = "armored"
		elif bias == "leech" and roll < 0.16: enemy.enemy_type = "leecher"
		elif bias == "teleporter" and roll < 0.12: enemy.enemy_type = "teleporter"
		elif bias == "gravity" and roll < 0.14: enemy.enemy_type = "sniper"
		elif elapsed > 90.0 and roll < 0.09: enemy.enemy_type = "sniper"
		elif roll < 0.24: enemy.enemy_type = "void_spitter"
		elif roll < 0.28: enemy.enemy_type = "splitter"
	if enemy.enemy_type == "armored":
		enemy.max_hp *= 1.8
		enemy.contact_damage *= 1.15
	elif enemy.enemy_type == "swarmer":
		enemy.max_hp *= 0.45
		enemy.xp_value *= 0.65
	elif enemy.enemy_type == "splitter":
		enemy.max_hp *= 1.25
		enemy.xp_value *= 1.35
	elif enemy.enemy_type == "void_spitter":
		enemy.max_hp *= 0.82
		enemy.speed *= 1.02
		enemy.contact_damage *= 0.55
		enemy.xp_value *= 1.15

	var poly = enemy.get_node_or_null("EnemyPolygon")
	if poly:
		var hues = [Color(1, 0.28, 0.38), Color(0.9, 0.3, 0.8), Color(1, 0.5, 0.22), Color(0.55, 0.25, 1), Color(0.3, 0.85, 0.5), Color(0.25, 0.55, 1)]
		poly.color = hues[randi() % hues.size()]
		match enemy.enemy_type:
			"swarmer": poly.color = Color(1.0, 0.8, 0.2)
			"armored": poly.color = Color(0.55, 0.62, 0.72)
			"leecher": poly.color = Color(0.35, 1.0, 0.45)
			"teleporter": poly.color = Color(0.45, 0.8, 1.0)
			"sniper": poly.color = Color(1.0, 0.4, 0.8)
			"splitter": poly.color = Color(1.0, 0.5, 0.2)
			"void_spitter": poly.color = Color(0.2, 0.9, 1.0)
		enemy.scale = Vector2(0.8 + randf() * 0.5, 0.8 + randf() * 0.5)
	GameManager.spawn(enemy)

func _trigger_random_event() -> void:
	var roll = randi() % 5
	match roll:
		0:
			GameManager.event_scrap_multiplier = 2.0
			GameManager.event_scrap_time = 25.0
			GameManager.random_event.emit("SALVAGE SURGE  •  Scrap doubled for 25s")
		1:
			if get_tree().get_nodes_in_group("elites").size() < 1:
				_spawn_elite()
			for i in range(3):
				_spawn_enemy(false)
			GameManager.random_event.emit("ELITE HUNT  •  Elite contact detected")
		2:
			GameManager.event_enemy_speed_multiplier = 1.35
			GameManager.event_enemy_time = 30.0
			GameManager.random_event.emit("VOID STORM  •  Enemies accelerated")
		3:
			if GameManager.player:
				GameManager.player.heal(GameManager.player.max_hp * 0.25)
			GameManager.random_event.emit("DISTRESS SIGNAL  •  Emergency repair received")
		_:
			GameManager.find_secret("ancient_signal", "Ancient signal decoded • hidden research cache recovered")
			if GameManager.player:
				GameManager.player.add_xp(35.0)
			GameManager.random_event.emit("UNKNOWN SIGNAL  •  Something answered")
