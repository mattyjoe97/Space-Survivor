extends CharacterBody2D

signal died

@export var max_hp: float = 5200.0
@export var speed: float = 58.0
@export var contact_damage: float = 24.0

var current_hp: float
var player: Node2D = null
var phase: int = 1
var attack_timer: float = 2.0
var pattern_timer: float = 0.0
var is_charging: bool = false
var charge_dir: Vector2 = Vector2.ZERO
var charge_time: float = 0.0
var attack_index: int = 0
var telegraph_line: Line2D = null
var telegraph_ring: Polygon2D = null
var black_hole_timer: float = 0.0

@onready var sprite: Polygon2D = $BossPolygon
@onready var core: Polygon2D = $Core

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	# Survivability scales with the build that reaches it (level 20 -> ~3.4x base).
	var plv: int = int(GameManager.player.level) if is_instance_valid(GameManager.player) else 10
	max_hp = max_hp * (1.0 + 0.10 * float(plv))
	current_hp = max_hp
	var hpn := Node2D.new()
	hpn.set_script(load("res://scripts/BossShield.gd"))
	hpn.name = "BossShield"
	add_child(hpn)
	player = GameManager.player
	GameManager.boss_health_changed.emit(current_hp, max_hp)
	scale = Vector2(2.8, 2.8)
	_create_telegraphs()

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over or GameManager.is_victory:
		return
	if not is_instance_valid(player):
		player = GameManager.player
		if not player:
			return

	attack_timer -= delta
	pattern_timer -= delta
	_tick_close_range(delta)
	if black_hole_timer > 0.0:
		black_hole_timer -= delta
		if black_hole_timer <= 0.0 and telegraph_ring:
			telegraph_ring.visible = false

	if is_charging:
		charge_time -= delta
		velocity = charge_dir * (speed * 5.0)
		move_and_slide()
		if charge_time <= 0.0:
			is_charging = false
			velocity = Vector2.ZERO
		return

	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	rotation = lerp_angle(rotation, dir.angle() + PI / 2.0, 0.08)

	var hp_ratio = current_hp / max_hp
	if hp_ratio < 0.72 and phase == 1:
		phase = 2
		_phase_shield()
		speed *= 1.12
		attack_timer = 0.6
		GameManager.random_event.emit("VOID TITAN PHASE II  •  The rift is destabilizing")
		VFX.ring_burst(global_position, 110.0, Color(0.7, 0.25, 1.0, 0.9))
	elif hp_ratio < 0.45 and phase == 2:
		phase = 3
		_phase_shield()
		speed *= 1.16
		attack_timer = 0.5
		GameManager.random_event.emit("VOID TITAN PHASE III  •  Reality is collapsing")
		VFX.ring_burst(global_position, 130.0, Color(1.0, 0.2, 0.65, 0.95))
	elif hp_ratio < 0.22 and phase == 3:
		phase = 4
		_phase_shield()
		speed *= 1.22
		attack_timer = 0.35
		GameManager.random_event.emit("VOID TITAN ENRAGED  •  FINAL PHASE")
		VFX.ring_burst(global_position, 150.0, Color(1.0, 0.35, 0.2, 1.0))

	if pattern_timer <= 0.0 and attack_timer <= 0.0 and not is_charging:
		_start_next_attack()
	if telegraph_line and telegraph_line.visible:
		_update_line_telegraph()

func _create_telegraphs() -> void:
	telegraph_line = Line2D.new()
	telegraph_line.name = "AttackTelegraph"
	telegraph_line.width = 5.0
	telegraph_line.default_color = Color(1.0, 0.25, 0.55, 0.72)
	telegraph_line.visible = false
	add_child(telegraph_line)

	telegraph_ring = Polygon2D.new()
	telegraph_ring.name = "BlackHoleTelegraph"
	telegraph_ring.color = Color(0.45, 0.15, 0.9, 0.22)
	telegraph_ring.polygon = PackedVector2Array([Vector2(-75,-75),Vector2(75,-75),Vector2(75,75),Vector2(-75,75)])
	telegraph_ring.visible = false
	add_child(telegraph_ring)

func _start_next_attack() -> void:
	attack_index += 1
	var attack_count = 4 if phase < 3 else 5
	var choice = attack_index % attack_count
	match choice:
		0:
			_start_targeted_barrage()
		1:
			_start_radial_burst()
		2:
			_start_charge_attack()
		3:
			_start_sweeping_beam()
		4:
			_start_black_hole()

func _start_targeted_barrage() -> void:
	telegraph_line.visible = true
	pattern_timer = 0.72
	attack_timer = _attack_cooldown(2.8)
	_update_line_telegraph()
	await get_tree().create_timer(0.72).timeout
	if not is_instance_valid(self) or GameManager.is_game_over or GameManager.is_victory:
		return
	telegraph_line.visible = false
	var count = 3 if phase < 3 else 5
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	var target = player.global_position
	var pv = player.get("velocity")
	if pv != null and pv is Vector2:
		target += pv * 0.45
	for i in range(count):
		var b = bullet_scene.instantiate()
		var d = (target - global_position).normalized().rotated((float(i) - float(count - 1) / 2.0) * 0.11)
		b.global_position = global_position + d * 38.0
		b.direction = d
		b.speed = 285.0 + phase * 18.0
		b.damage = 13.0 + phase * 2.0
		b.kind = "orb"
		GameManager.spawn(b)

func _start_radial_burst() -> void:
	pattern_timer = 0.55
	attack_timer = _attack_cooldown(3.0)
	VFX.ring_burst(global_position, 62.0, Color(0.75, 0.2, 1.0, 0.8))
	await get_tree().create_timer(0.55).timeout
	if not is_instance_valid(self):
		return
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	var count = 14 if phase == 1 else (18 if phase == 2 else (22 if phase == 3 else 28))
	for i in range(count):
		var b = bullet_scene.instantiate()
		var d = Vector2.from_angle((float(i) / float(count)) * TAU + global_rotation)
		b.global_position = global_position + d * 40.0
		b.direction = d
		b.speed = 205.0 + phase * 18.0
		b.damage = 11.0 + phase * 2.0
		b.kind = "orb"
		GameManager.spawn(b)

func _start_charge_attack() -> void:
	pattern_timer = 0.9
	attack_timer = _attack_cooldown(3.6)
	telegraph_line.visible = true
	_update_line_telegraph()
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self):
		return
	telegraph_line.visible = false
	is_charging = true
	charge_dir = (player.global_position - global_position).normalized()
	charge_time = 0.8

func _start_sweeping_beam() -> void:
	pattern_timer = 1.15
	attack_timer = _attack_cooldown(4.0)
	telegraph_line.visible = true
	_update_line_telegraph()
	await get_tree().create_timer(0.65).timeout
	if not is_instance_valid(self):
		return
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	for i in range(9 if phase >= 3 else 7):
		if not is_instance_valid(player):
			break
		var target = (player.global_position - global_position).normalized().rotated(-0.56 + i * 0.14)
		var b = bullet_scene.instantiate()
		b.global_position = global_position + target * 42.0
		b.direction = target
		b.speed = 330.0 + phase * 12.0
		b.damage = 15.0 + phase
		b.kind = "orb"
		GameManager.spawn(b)
		await get_tree().create_timer(0.08).timeout
	telegraph_line.visible = false

func _start_black_hole() -> void:
	pattern_timer = 2.0
	attack_timer = _attack_cooldown(5.0)
	telegraph_ring.global_position = player.global_position
	telegraph_ring.visible = true
	black_hole_timer = 2.0
	await get_tree().create_timer(0.75).timeout
	if not is_instance_valid(self):
		return
	for i in range(13):
		if not is_instance_valid(player):
			break
		var offset = telegraph_ring.global_position - player.global_position
		if offset.length() > 35.0:
			player.velocity += offset.normalized() * (20.0 + phase * 2.0)
		await get_tree().create_timer(0.1).timeout
	telegraph_ring.visible = false
	black_hole_timer = 0.0

func _update_line_telegraph() -> void:
	if not telegraph_line or not is_instance_valid(player):
		return
	var target = player.global_position
	var pv = player.get("velocity")
	if pv != null and pv is Vector2:
		target += pv * 0.55
	telegraph_line.points = PackedVector2Array([Vector2.ZERO, to_local(target)])

func _attack_cooldown(base: float) -> float:
	return max(0.6, base * 0.8 - float(phase - 1) * 0.3)

var _dead: bool = false

func take_damage(amount: float, is_crit: bool = false) -> void:
	var _src: String = GameManager.consume_damage_source()   # consumed even if this hit is blocked
	if _dead:
		return
	var sh: Node = get_node_or_null("BossShield")
	if sh and sh.active:
		sh.absorb()
		return
	# Burst cap: no single hit removes more than 2.5% of the boss's hull.
	amount = minf(amount, max_hp * 0.025)
	AudioManager.play("boss_hit", 1.0 + randf_range(-0.05, 0.08), -6.0)
	GameManager.commit_damage(minf(amount, maxf(current_hp, 0.0)), _src)
	current_hp -= amount
	DamageNumber.spawn(global_position, amount, is_crit)
	GameManager.boss_health_changed.emit(current_hp, max_hp)
	sprite.modulate = Color(2.2, 2.2, 2.2)
	var art_node: Node = get_node_or_null("BossArt")
	if art_node:
		art_node.modulate = Color(2.4, 2.2, 2.2)
		var ftw := art_node.create_tween()
		ftw.tween_property(art_node, "modulate", Color.WHITE, 0.12)
	get_tree().create_timer(0.07).timeout.connect(func():
		if is_instance_valid(self):
			sprite.modulate = Color.WHITE
	)
	if current_hp <= 0.0:
		_dead = true
		_die()

func _die() -> void:
	VFX.mega_explosion(global_position, Color(0.85, 0.3, 0.9))
	VFX.explosion(global_position, 190.0, Color(0.75, 0.25, 1.0, 0.95))
	AudioManager.play("explode", 0.85, 0.0)
	AudioManager.play("boss_hit", 0.9, -2.0)
	VFX.ring_burst(global_position, 150.0, Color(1.0, 0.25, 0.65, 0.95))
	VFX.screen_shake(12.0)
	for i in range(18):
		var gem_scene = preload("res://scenes/XPGem.tscn")
		var gem = gem_scene.instantiate()
		gem.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		gem.xp_amount = 25.0 + randf() * 15.0
		GameManager.spawn(gem)
	GameManager.add_score(5000)
	GameManager.unlock_ship("voidrunner")
	GameManager.banked_scrap += 1000
	GameManager._save_progress()
	GameManager.is_victory = true
	GameManager.victory.emit()
	died.emit()
	queue_free()

func _phase_shield() -> void:
	var sh: Node = get_node_or_null("BossShield")
	if sh:
		sh.raise(2.6)
	VFX.shockwave(global_position, 260.0, Color(0.85, 0.4, 1.0, 0.9), 4.0, 0.5)
	AudioManager.play("shield", 0.7, -2.0)
	GameManager.random_event.emit("TITAN SHIELD UP  •  Phase %d" % phase)
	# Radial burst the player has to weave through while the shield is up.
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	for i in range(14):
		var b = bullet_scene.instantiate()
		b.global_position = global_position
		b.direction = Vector2.from_angle(float(i) / 14.0 * TAU)
		b.speed = 210.0
		b.damage = 12.0
		b.kind = "orb"
		GameManager.spawn(b)

# Close-range punish: hugging the Titan triggers a telegraphed hull shockwave.
var _close_t := 0.0
var _close_charge := -1.0
func _tick_close_range(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var d := global_position.distance_to(player.global_position)
	if _close_charge >= 0.0:
		_close_charge -= delta
		if _close_charge <= 0.0:
			_close_charge = -1.0
			VFX.shockwave(global_position, 190.0, Color(1.0, 0.35, 0.6, 0.95), 6.0, 0.35)
			VFX.screen_shake(6.0)
			AudioManager.play("big_boom", 0.9, -2.0)
			if global_position.distance_to(player.global_position) < 190.0:
				player.invuln_timer = 0.0
				player.take_damage(26.0 + float(phase) * 4.0)
				player.global_position += (player.global_position - global_position).normalized() * 90.0
		return
	_close_t -= delta
	if d < 170.0 and _close_t <= 0.0:
		_close_t = 2.4 - float(phase) * 0.25
		_close_charge = 0.55
		# Telegraph: bright contracting ring + warning bullets are visible for 0.55 s.
		WeaponFX.pulse(global_position, 220.0, 60.0, Color(1.0, 0.4, 0.6), 0.55, 10.0)
		AudioManager.play("warning", 1.5, -6.0)
