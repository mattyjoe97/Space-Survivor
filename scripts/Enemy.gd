extends CharacterBody2D

@export var max_hp: float = 30.0
@export var speed: float = 90.0
@export var contact_damage: float = 12.0
@export var xp_value: float = 5.0
@export var score_value: int = 10

var current_hp: float
var player: Node2D = null
var base_speed: float = 90.0
var enemy_type: String = "chaser"
var behavior_timer: float = 0.0
var teleport_cooldown: float = 4.0
var sniper_cooldown: float = 2.8
var spitter_cooldown: float = 2.6
var spitter_warning: float = 0.0
var spitter_warning_line: Line2D = null
var frozen_timer: float = 0.0
var freeze_progress: float = 0.0
var chill_timer: float = 0.0   # set by Cryo Field: temporary slow
var chill_factor: float = 0.6

@onready var sprite: Polygon2D = $EnemyPolygon
var _art_node: Node = null

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	base_speed = speed
	player = GameManager.player
	_art_node = get_node_or_null("EnemyArt")
	if _art_node:
		_art_node.variant = enemy_type
	if enemy_type == "void_spitter":
		_create_spitter_telegraph()

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over or GameManager.is_victory:
		return
	if not is_instance_valid(player):
		player = GameManager.player
		if not player:
			return
	if _art_node and _art_node.variant != enemy_type:
		_art_node.variant = enemy_type
	frozen_timer = maxf(0.0, frozen_timer - delta)
	if frozen_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	behavior_timer -= delta
	teleport_cooldown -= delta
	sniper_cooldown -= delta
	spitter_cooldown -= delta
	if spitter_warning > 0.0:
		spitter_warning -= delta
		_update_spitter_telegraph()
		if spitter_warning <= 0.0:
			_fire_spitter()

	var dir = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	var spd = base_speed * GameManager.event_enemy_speed_multiplier
	if chill_timer > 0.0:
		chill_timer -= delta
		spd *= chill_factor
	if player.has_method("get"):
		var slow_value = player.get("slow_field")
		if slow_value != null and slow_value > 0.0 and distance < 235.0:
			spd *= (1.0 - slow_value)

	match enemy_type:
		"swarmer":
			spd *= 1.55
		"leecher":
			spd *= 0.8
			if distance < 140.0 and player.has_method("take_damage"):
				player.take_damage(3.0 * delta)
		"teleporter":
			spd *= 0.72
			if teleport_cooldown <= 0.0 and distance > 220.0:
				global_position = player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(260.0, 430.0)
				teleport_cooldown = 4.0
		"sniper":
			spd *= 0.35
			if sniper_cooldown <= 0.0:
				_fire_sniper(dir)
				sniper_cooldown = 3.2
		"void_spitter":
			# Hold a mid-range orbit and punish predictable movement.
			if distance > 380.0:
				spd *= 1.15
			elif distance < 285.0:
				spd *= 1.25
			else:
				spd *= 0.18
			if spitter_cooldown <= 0.0 and spitter_warning <= 0.0 and distance < 520.0:
				spitter_warning = 0.48
				_update_spitter_telegraph()
		"splitter":
			spd *= 0.9
		"armored":
			spd *= 0.7

	velocity = dir * spd
	move_and_slide()
	if enemy_type == "void_spitter":
		rotation = lerp_angle(rotation, dir.angle() + PI / 2.0, 0.12)
	else:
		rotation = dir.angle() + PI / 2

func _create_spitter_telegraph() -> void:
	spitter_warning_line = Line2D.new()
	spitter_warning_line.name = "SpitterAimTelegraph"
	spitter_warning_line.width = 2.0
	spitter_warning_line.default_color = Color(0.45, 0.9, 1.0, 0.65)
	spitter_warning_line.visible = false
	add_child(spitter_warning_line)

func _update_spitter_telegraph() -> void:
	if not spitter_warning_line or not is_instance_valid(player):
		return
	if spitter_warning <= 0.0:
		spitter_warning_line.visible = false
		return
	var lead_target = player.global_position
	var player_velocity = player.get("velocity")
	if player_velocity != null and player_velocity is Vector2:
		var distance = global_position.distance_to(player.global_position)
		var travel_time = distance / 270.0
		lead_target += player_velocity * min(travel_time, 0.75)
	var local_target = to_local(lead_target)
	spitter_warning_line.points = PackedVector2Array([Vector2.ZERO, local_target])
	spitter_warning_line.visible = true
	spitter_warning_line.modulate.a = 0.35 + 0.5 * (0.48 - spitter_warning) / 0.48

func _fire_spitter() -> void:
	spitter_cooldown = 2.65
	spitter_warning_line.visible = false
	if not is_instance_valid(player):
		return
	var lead_target = player.global_position
	var player_velocity = player.get("velocity")
	if player_velocity != null and player_velocity is Vector2:
		var distance = global_position.distance_to(player.global_position)
		lead_target += player_velocity * min(distance / 270.0, 0.75)
	var dir = (lead_target - global_position).normalized()
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	var b = bullet_scene.instantiate()
	b.global_position = global_position + dir * 20.0
	b.direction = dir
	b.speed = 270.0
	b.damage = max(8.0, contact_damage * 1.35)
	b.kind = "blob"
	b.leaves_puddle = true
	GameManager.spawn(b)

func _fire_sniper(dir: Vector2) -> void:
	var bullet_scene = preload("res://scenes/EnemyBullet.tscn")
	var b = bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = dir
	b.speed = 340.0
	b.damage = max(8.0, contact_damage * 1.5)
	b.kind = "needle"
	GameManager.spawn(b)

func apply_freeze_progress(amount: float, threshold: float) -> void:
	freeze_progress += amount
	if freeze_progress >= threshold:
		freeze_progress = 0.0
		frozen_timer = 1.10
		modulate = Color(0.55, 0.92, 1.15)
		VFX.ring_burst(global_position, 28.0, Color(0.55, 0.92, 1.0, 0.65))
		get_tree().create_timer(frozen_timer).timeout.connect(func():
			if is_instance_valid(self) and frozen_timer <= 0.0:
				modulate = Color.WHITE
		)


var _dead: bool = false

func take_damage(amount: float, is_crit: bool = false) -> void:
	var _src: String = GameManager.consume_damage_source()   # consumed even if this hit is blocked
	if _dead:
		return
	if enemy_type == "armored":
		amount *= 0.55
	var effective: float = minf(amount, maxf(current_hp, 0.0))
	GameManager.commit_damage(effective, _src)
	current_hp -= amount
	DamageNumber.spawn(global_position, amount, is_crit)
	# Hit flash + squash on the art node (the legacy polygon is hidden, so flash it directly).
	if _art_node:
		_art_node.flash = 1.0
		var punch: float = 0.82 if not is_crit else 0.68
		_art_node.scale = Vector2(1.0 + (1.0 - punch) * 0.6, punch)
		var tw := _art_node.create_tween()
		tw.tween_property(_art_node, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if current_hp <= 0.0:
		_dead = true
		_die()

func _die() -> void:
	var gem_scene = preload("res://scenes/XPGem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = global_position
	gem.xp_amount = xp_value
	GameManager.spawn(gem, true)
	GameManager.add_score(score_value)
	GameManager.record_kill(enemy_type)
	var death_col := Color(0.35, 0.85, 1.0, 0.78)
	match enemy_type:
		"swarmer": death_col = Color(1.0, 0.55, 0.2, 0.72)
		"armored": death_col = Color(0.95, 0.78, 0.35, 0.86)
		"sniper": death_col = Color(0.95, 0.3, 0.7, 0.82)
		"void_spitter": death_col = Color(0.35, 0.9, 1.0, 0.9)
		"teleporter": death_col = Color(0.7, 0.35, 1.0, 0.82)
	VFX.enemy_death(global_position, death_col, enemy_type == "armored")
	AudioManager.play("enemy_death", 1.0 + randf_range(-0.1, 0.15), -7.0)
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("on_kill_heal"):
		GameManager.player.on_kill_heal()
	if randf() < 0.28:
		var scrap_scene = preload("res://scenes/ScrapPickup.tscn")
		var s = scrap_scene.instantiate()
		s.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		s.amount = 3 + randi() % 4
		GameManager.spawn(s, true)
	if enemy_type == "splitter":
		for i in range(2):
			var child = preload("res://scenes/Enemy.tscn").instantiate()
			child.global_position = global_position + Vector2.from_angle(i * PI + randf() * 0.4) * 18.0
			child.max_hp = 8.0
			child.speed = 135.0
			child.xp_value = 1.5
			child.enemy_type = "swarmer"
			GameManager.spawn(child, true)
	if randf() < 0.025:
		var pick_scene = preload("res://scenes/Pickup.tscn")
		var p = pick_scene.instantiate()
		p.global_position = global_position
		p.pickup_type = 0 if randf() < 0.70 else 1
		GameManager.spawn(p, true)
	queue_free()
