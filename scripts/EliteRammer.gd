extends CharacterBody2D

const ELITE_BAR_SCENE = preload("res://scripts/EliteHealthBar.gd")
const ELITE_BAR_TITLE := "VOID RAMMER"
const ELITE_BAR_COLOR := Color(1.0, 0.42, 0.16, 1.0)

## Elite: Void Rammer — deadly telegraphed charges

@export var max_hp: float = 400.0
@export var speed: float = 110.0
@export var contact_damage: float = 24.0
@export var xp_value: float = 60.0
@export var score_value: int = 220

var current_hp: float
var player: Node2D = null
var state: String = "chase"
var state_timer: float = 0.0
var charge_dir: Vector2 = Vector2.ZERO
var base_speed: float = 110.0
var area_control_timer: float = 0.0
var area_control_center: Vector2 = Vector2.ZERO
var area_control_strength: float = 0.0
var frozen_timer: float = 0.0
var freeze_progress: float = 0.0

@onready var sprite: Polygon2D = $Body
@onready var glow: Polygon2D = $Glow

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("elites")
	current_hp = max_hp
	base_speed = speed
	player = GameManager.player
	scale = Vector2(1.75, 1.75)
	state_timer = 1.8 + randf()
	_create_health_bar()

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	if not is_instance_valid(player):
		player = GameManager.player
		if not player:
			return

	frozen_timer = maxf(0.0, frozen_timer - delta)
	if frozen_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	state_timer -= delta
	if area_control_timer > 0.0:
		area_control_timer -= delta
		if state != "charge" and state != "telegraph":
			var control_dir: Vector2 = (area_control_center - global_position).normalized()
			velocity = control_dir * maxf(base_speed * 1.15, area_control_strength)
			move_and_slide()
			rotation = lerp_angle(rotation, control_dir.angle() + PI / 2.0, 0.18)
			return
	var spd = base_speed
	if player and "slow_field" in player and player.slow_field > 0.0:
		if global_position.distance_to(player.global_position) < 200.0 and state == "chase":
			spd *= (1.0 - player.slow_field * 0.6)

	match state:
		"chase":
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * spd
			move_and_slide()
			rotation = lerp_angle(rotation, dir.angle() + PI / 2.0, 0.14)
			var health_bar = get_node_or_null("EliteHealthBar")
			if health_bar:
				health_bar.rotation = -rotation
			if state_timer <= 0.0:
				state = "telegraph"
				state_timer = 0.85
				velocity = Vector2.ZERO
				sprite.modulate = Color(2.2, 1.3, 0.4)
				glow.visible = true

		"telegraph":
			velocity = Vector2.ZERO
			var dir = (player.global_position - global_position).normalized()
			rotation = lerp_angle(rotation, dir.angle() + PI / 2.0, 0.3)
			var health_bar = get_node_or_null("EliteHealthBar")
			if health_bar:
				health_bar.rotation = -rotation
			if state_timer <= 0.0:
				state = "charge"
				state_timer = 0.7
				charge_dir = (player.global_position - global_position).normalized()
				sprite.modulate = Color(2.8, 2.0, 0.7)

		"charge":
			velocity = charge_dir * (spd * 6.0)
			move_and_slide()
			if state_timer <= 0.0:
				state = "recover"
				state_timer = 0.9
				sprite.modulate = Color.WHITE
				glow.visible = false

		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			move_and_slide()
			if state_timer <= 0.0:
				state = "chase"
				state_timer = 2.0 + randf() * 0.8

func apply_freeze_progress(amount: float, threshold: float) -> void:
	freeze_progress += amount
	if freeze_progress >= threshold:
		freeze_progress = 0.0
		frozen_timer = 0.78
		if sprite:
			sprite.modulate = Color(0.58, 0.92, 1.08)
		VFX.ring_burst(global_position, 34.0, Color(0.55, 0.92, 1.0, 0.68))
		get_tree().create_timer(frozen_timer).timeout.connect(func():
			if is_instance_valid(self) and frozen_timer <= 0.0 and sprite:
				sprite.modulate = Color.WHITE
		)


var _dead: bool = false

func take_damage(amount: float, is_crit: bool = false) -> void:
	var _src: String = GameManager.consume_damage_source()   # consumed even if this hit is blocked
	if _dead:
		return
	var effective: float = minf(amount, maxf(current_hp, 0.0))
	GameManager.commit_damage(effective, _src)
	current_hp -= amount
	DamageNumber.spawn(global_position, amount, is_crit)
	_update_health_bar()
	var art_node: Node = get_node_or_null("EliteArt")
	if art_node:
		art_node.modulate = Color(2.2, 2.2, 2.2)
		var ftw := art_node.create_tween()
		ftw.tween_property(art_node, "modulate", Color.WHITE, 0.1)
	if state != "telegraph" and state != "charge":
		sprite.modulate = Color(2, 2, 2)
		get_tree().create_timer(0.06).timeout.connect(func():
			if is_instance_valid(self) and state == "chase":
				sprite.modulate = Color.WHITE
		)
	if current_hp <= 0.0:
		_dead = true
		_die()

func _create_health_bar() -> void:
	var bar = ELITE_BAR_SCENE.new()
	bar.name = "EliteHealthBar"
	bar.position = Vector2(0, -58)
	bar.set_values(current_hp, max_hp, ELITE_BAR_TITLE, ELITE_BAR_COLOR)
	add_child(bar)

func _update_health_bar() -> void:
	var bar = get_node_or_null("EliteHealthBar")
	if bar:
		bar.set_values(current_hp, max_hp, ELITE_BAR_TITLE, ELITE_BAR_COLOR)

func _die() -> void:
	VFX.death_burst(global_position, 78.0, Color(1.0, 0.42, 0.18, 0.95))
	VFX.mega_explosion(global_position, Color(1.0, 0.45, 0.18))
	AudioManager.play("enemy_death", 0.85, -3.0)
	AudioManager.play("explode", 1.1, -4.0)
	VFX.screen_shake(5.0)
	var gem_scene = preload("res://scenes/XPGem.tscn")
	for i in range(6):
		var gem = gem_scene.instantiate()
		gem.global_position = global_position + Vector2(randf_range(-28, 28), randf_range(-28, 28))
		gem.xp_amount = xp_value / 6.0
		GameManager.spawn(gem)
	GameManager.add_score(score_value)
	GameManager.add_scrap(14)
	GameManager.record_elite_kill()
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("on_kill_heal"):
		GameManager.player.on_kill_heal()
	# Elites always drop a vacuum magnet as a meaningful reward for the kill.
	# A small chance for an extra heal keeps elite rewards useful without flooding the arena.
	var pick_scene = preload("res://scenes/Pickup.tscn")
	var magnet = pick_scene.instantiate()
	magnet.global_position = global_position
	magnet.pickup_type = 1
	magnet.elite = true
	GameManager.spawn(magnet)
	if randf() < 0.20:
		var heal = pick_scene.instantiate()
		heal.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-14, 14))
		heal.pickup_type = 0
		GameManager.spawn(heal)
	queue_free()

func apply_area_control(center: Vector2, strength: float, slow_amount: float, duration: float) -> void:
	area_control_center = center
	area_control_strength = maxf(area_control_strength, strength * (1.0 - slow_amount * 0.25))
	area_control_timer = maxf(area_control_timer, duration)
