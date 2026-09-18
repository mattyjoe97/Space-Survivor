extends CharacterBody2D

signal health_changed(current: float, max_hp: float)
signal xp_changed(current: float, needed: float)
signal leveled_up(level: int)

var speed: float
var max_hp: float
var current_hp: float
var damage: float
var fire_rate: float
var projectile_speed: float
var xp_magnet_range: float
var projectile_count: int = 1
var pierce: int = 0
var spread_bonus: float = 0.0
var proj_scale: float = 1.0
var explode_on_hit: bool = false
var explode_damage_mult: float = 1.0
var explode_radius: float = 55.0
var aura_radius: float = 112.0
# Mirrors kept for ShipWeaponVFX hull hardware drawing (set by WeaponManager).
var side_guns: int = 0
var missile_level: int = 0
var laser_level: int = 0
var arc_level: int = 0
var weapons: Node2D = null
# 3.17 system tiers read by weapons / projectiles
var duration_mult: float = 1.0
var homing_tier: int = 0
var burn_tier: int = 0
var cryo_tier: int = 0
var size_damage_bonus: float = 0.0
var extra_projectiles_by_weapon: Dictionary = {}
var slow_field: float = 0.0  # slow factor 0-0.5
var crit_chance: float = 0.0
var lifesteal: bool = false
var has_second_wind: bool = false
var second_wind_used: bool = false
var thorns_percent: float = 0.0
var gem_value_mult: float = 1.0
var xp_gain_mult: float = 1.0
var scrap_gain_mult: float = 1.0
var vacuum_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_duration: float = 0.16
var dash_timer: float = 0.0
var dash_speed: float = 760.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_flash_timer: float = 0.0
const DASH_COOLDOWN := 2.4
# 3.18 dash system: independent charges, built-in impact, synced forcefield.
var is_dead: bool = false   # authoritative; nothing changes HP once true
var dash_charges_max: int = 1
var dash_charges: int = 1
var dash_recharge: Array[float] = []      # one countdown per spent charge (independent recharge)
var dash_iframe_timer: float = 0.0       # dash-granted invulnerability only (drives the forcefield)
var dash_slow: bool = false              # Phase Thrusters
var _dash_seq: int = 0
var _dash_shield: Node2D = null
var _dash_hits: Dictionary = {}

# Evolution flags
var evo_nova_cannon: bool = false
var evo_radiation_storm: bool = false
var evo_chain_reactor: bool = false
var evo_bullet_hell: bool = false
var evo_frozen_void: bool = false
var evo_overdrive: bool = false
var evo_homing_array: bool = false
var evo_plasma_cutter: bool = false
var evo_chain_reaction: bool = false


var level: int = 1
var current_xp: float = 0.0
var xp_to_next: float = 15.0
var fire_timer: float = 0.0
var invuln_timer: float = 0.0
var cursed_decay_timer: float = 12.0
var misfire_timer: float = 0.0
const INVULN_TIME := 0.35

@onready var sprite: Polygon2D = $ShipBody
@onready var wing_l: Polygon2D = $WingL
@onready var wing_r: Polygon2D = $WingR
@onready var engine_glow: Polygon2D = $EngineGlow
@onready var cockpit: Polygon2D = $Cockpit
@onready var xp_shape: CollisionShape2D = $XPMagnet/CollisionShape2D

var projectile_scene: PackedScene
var drone_angles: Array[float] = [0.0, PI]

var _ghost_timer: float = 0.0
var _engine_trail: CPUParticles2D = null

func _ready() -> void:
	projectile_scene = preload("res://scenes/Projectile.tscn")
	_setup_engine_trail()
	_dash_shield = Node2D.new()
	_dash_shield.name = "DashShield"
	_dash_shield.set_script(load("res://scripts/DashShield.gd"))
	_dash_shield.visible = false
	add_child(_dash_shield)
	weapons = load("res://scripts/weapons/WeaponManager.gd").new()
	weapons.name = "Weapons"
	add_child(weapons)
	weapons.setup(self)
	GameManager.synergy_activated.connect(_on_synergy_activated)
	_apply_character()
	GameManager.player = self
	add_to_group("player")
	health_changed.emit(current_hp, max_hp)
	xp_changed.emit(current_xp, xp_to_next)
	_update_xp_magnet()

func _apply_character() -> void:
	var data = GameManager.get_character_data()
	speed = data.base_speed * (1.0 + float(GameManager.permanent_upgrades.get("speed", 0)) * 0.02)
	speed *= 1.0 + float(GameManager.permanent_upgrades.get("defense_core", 0)) * 0.005
	max_hp = data.base_max_hp * (1.0 + float(GameManager.permanent_upgrades.get("hull", 0)) * 0.05)
	max_hp *= 1.0 + float(GameManager.permanent_upgrades.get("defense_core", 0)) * 0.025
	current_hp = max_hp
	damage = data.base_damage * 1.15 * (1.0 + float(GameManager.permanent_upgrades.get("damage", 0)) * 0.04)
	damage *= 1.0 + float(GameManager.permanent_upgrades.get("weapons_core", 0)) * 0.025
	fire_rate = data.base_fire_rate * (1.0 - float(GameManager.permanent_upgrades.get("fire_rate", 0)) * 0.02)
	projectile_speed = data.base_projectile_speed
	xp_magnet_range = data.base_xp_magnet * (1.0 + float(GameManager.permanent_upgrades.get("magnet", 0)) * 0.06)
	is_dead = false
	projectile_count = 0   # legacy base-cannon count; kept at 0 (drives hull hardware art only)
	dash_charges_max = 1 + (1 if "twin_thrusters" in GameManager.active_relics else 0) + (1 if "phase_thrusters" in GameManager.active_relics else 0)
	dash_charges = dash_charges_max
	dash_recharge.clear()
	dash_slow = "phase_thrusters" in GameManager.active_relics
	dash_iframe_timer = 0.0
	pierce = int(data.get("start_pierce", 0))
	spread_bonus = 0.0
	proj_scale = 1.0
	explode_on_hit = false
	explode_damage_mult = 1.0
	explode_radius = 55.0
	duration_mult = 1.0
	homing_tier = 0
	burn_tier = 0
	cryo_tier = 0
	size_damage_bonus = 0.0
	aura_radius = 112.0
	side_guns = 0
	extra_projectiles_by_weapon.clear()
	slow_field = 0.0
	crit_chance = float(GameManager.permanent_upgrades.get("crit", 0)) * 0.015
	lifesteal = false
	has_second_wind = false
	second_wind_used = false
	thorns_percent = 0.0
	gem_value_mult = 1.0
	xp_gain_mult = 1.0 + float(GameManager.permanent_upgrades.get("xp", 0)) * 0.04
	scrap_gain_mult = 1.0
	evo_nova_cannon = false
	evo_radiation_storm = false
	evo_chain_reactor = false
	evo_bullet_hell = false
	evo_frozen_void = false
	evo_overdrive = false
	evo_homing_array = false
	evo_plasma_cutter = false
	evo_chain_reaction = false
	if weapons:
		weapons.sync_levels()
	level = 1
	current_xp = 0.0
	xp_to_next = 26.0
	GameManager.player_luck = data.get("base_luck", 0.0) + float(GameManager.permanent_upgrades.get("luck", 0)) * 2.0 + float(GameManager.permanent_upgrades.get("economy_core", 0)) * 1.0
	GameManager.luck_changed.emit(GameManager.player_luck)

	var col: Color = data.color
	if sprite: sprite.color = col
	if wing_l: wing_l.color = col.darkened(0.15)
	if wing_r: wing_r.color = col.darkened(0.15)
	if cockpit:
		match GameManager.selected_character:
			"viper": cockpit.color = Color(0.7, 0.95, 1.0, 0.9)
			"bulwark": cockpit.color = Color(1.0, 0.85, 0.5, 0.9)
			"nova": cockpit.color = Color(1.0, 0.7, 1.0, 0.9)
	if engine_glow:
		match GameManager.selected_character:
			"viper": engine_glow.color = Color(0.3, 0.85, 1.0, 0.85)
			"bulwark": engine_glow.color = Color(1.0, 0.45, 0.15, 0.85)
			"nova": engine_glow.color = Color(0.9, 0.3, 1.0, 0.85)

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return

	dash_cooldown = max(0.0, dash_cooldown - delta)
	dash_timer = max(0.0, dash_timer - delta)
	dash_iframe_timer = max(0.0, dash_iframe_timer - delta)
	for i in range(dash_recharge.size() - 1, -1, -1):
		dash_recharge[i] -= delta
		if dash_recharge[i] <= 0.0:
			dash_recharge.remove_at(i)
			dash_charges = mini(dash_charges_max, dash_charges + 1)
	dash_flash_timer = max(0.0, dash_flash_timer - delta)

	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"): dir.y -= 1
	if Input.is_action_pressed("move_down"): dir.y += 1
	if Input.is_action_pressed("move_left"): dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		if dash_timer <= 0.0:
			velocity = dir * speed
		rotation = lerp_angle(rotation, dir.angle() + PI / 2.0, 0.18)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 5.0 * delta)

	if Input.is_action_just_pressed("dash") and dash_charges > 0 and dash_timer <= 0.0:
		_start_dash(dir if dir != Vector2.ZERO else Vector2.from_angle(rotation - PI / 2.0))

	if dash_timer > 0.0:
		velocity = dash_direction * dash_speed * _dash_ship("speed")
		modulate.a = 0.75 + 0.25 * sin(dash_timer * 70.0)
		_dash_impact()
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.045
			VFX.ship_ghost(self, _accent_color())
	else:
		modulate.a = 1.0 if invuln_timer <= 0.0 else modulate.a
	_update_engine_trail(delta)
	_tick_siphon(delta)
	_tick_contact()
	_sync_dash_shield()

	move_and_slide()
	position = position.clamp(Vector2(-2500, -2500), Vector2(2500, 2500))
	if (abs(position.x) > 2350.0 or abs(position.y) > 2350.0) and GameManager.game_time > 30.0:
		GameManager.find_secret("edge_of_void", "Void boundary reached • experimental navigation data found")

	# Ship signature passives make the hangar choices meaningfully different.
	if false:
		pass
	elif GameManager.selected_character == "bulwark" and current_hp < max_hp * 0.35:
		invuln_timer = max(invuln_timer, 0.02)
	elif GameManager.selected_character == "nova" and randf() < delta * 0.7:
		var target = _get_nearest_enemy()
		if target and target.has_method("take_damage"):
			var nova_damage: float = damage * 0.35
			GameManager.record_damage("ship_signature", nova_damage)
			target.take_damage(nova_damage)
	weapons.tick(delta)

	# Primary cannons removed in 3.17.6: every hull fights with its signature weapon.
	fire_timer = 0.0
	if false:
		_fire()
		fire_timer = fire_rate

	# Cursed technology drawbacks
	cursed_decay_timer -= delta
	if "blood_battery" in GameManager.cursed_upgrades and cursed_decay_timer <= 0.0:
		max_hp = max(20.0, max_hp - 1.0)
		current_hp = min(current_hp, max_hp)
		cursed_decay_timer = 12.0
	if "unstable_ai" in GameManager.cursed_upgrades:
		misfire_timer -= delta

	# Slow field
	if slow_field > 0.0:
		_apply_slow_field()

	# Orbit drones relic
	if "orbit_drones" in GameManager.active_relics:
		_update_drones(delta)

	# Explicit pickup sweep (distance based; Area2D overlap is only a backup path).
	_pickup_sweep()
	# Magnet effect
	if vacuum_timer > 0.0:
		vacuum_timer -= delta
		_magnet_sweep()
		if vacuum_timer <= 0.0:
			_magnet_final_sweep()

	if invuln_timer > 0.0:
		invuln_timer -= delta
		modulate.a = 0.45 + 0.55 * abs(sin(invuln_timer * 28.0))
	else:
		modulate.a = 1.0

func _start_dash(dir: Vector2) -> void:
	dash_direction = dir.normalized()
	var dur := dash_duration * _dash_ship("duration")
	dash_timer = dur
	dash_charges -= 1
	dash_recharge.append(DASH_COOLDOWN)
	dash_cooldown = DASH_COOLDOWN
	_dash_seq += 1
	_dash_hits.clear()
	dash_iframe_timer = dur + 0.08 + _dash_ship("iframe_bonus")
	invuln_timer = max(invuln_timer, dash_iframe_timer)
	_sync_dash_shield()
	rotation = dash_direction.angle() + PI / 2.0
	VFX.dash_burst(global_position, dash_direction)
	VFX.sparks(global_position, 8, _accent_color(), 140.0, 0.3, -dash_direction, 40.0)
	VFX.shockwave(global_position, 40.0, Color(1, 1, 1, 0.5), 2.0, 0.22)
	_ghost_timer = 0.0
	GameManager.dash_used.emit()
	AudioManager.play("dash", 1.0, -4.0)

func _apply_slow_field() -> void:
	var r: float = 220.0 + aura_radius * 0.35
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < r:
			if "speed" in e:
				# temporary soft slow via flag if not already
				pass

func _update_drones(delta: float) -> void:
	for i in range(drone_angles.size()):
		drone_angles[i] += delta * 2.2
	if randf() < delta * 3.5:
		var ang = drone_angles[randi() % drone_angles.size()]
		var pos = global_position + Vector2(cos(ang), sin(ang)) * 55.0
		var target = _get_nearest_enemy()
		if target and projectile_scene:
			_spawn_proj(pos, (target.global_position - pos).normalized(), damage * 0.5, max(0, pierce - 1), 1.0, "orbit_drones")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		SettingsManager.attack_mode = "manual" if SettingsManager.attack_mode == "auto" else "auto"
		SettingsManager.save()
		AudioManager.play("ui_confirm", 1.1, -8.0)
		GameManager.random_event.emit("AIM MODE  •  " + ("MANUAL AIM" if SettingsManager.attack_mode == "manual" else "AUTO TARGET"))

func _is_manual_aim() -> bool:
	return SettingsManager.attack_mode == "manual"

func _get_mouse_world_position() -> Vector2:
	# Node2D's built-in conversion stays correct with Camera2D smoothing/zoom.
	return get_global_mouse_position()

func _get_aim_direction(fallback_angle: float) -> Vector2:
	if not _is_manual_aim():
		return Vector2.from_angle(fallback_angle)
	var mouse_delta: Vector2 = _get_mouse_world_position() - global_position
	if mouse_delta.length_squared() <= 4.0:
		return Vector2.from_angle(fallback_angle)
	return mouse_delta.normalized()

func _get_manual_target(origin: Vector2, aim_dir: Vector2) -> Node2D:
	var assist: String = SettingsManager.manual_aim_assist
	if assist == "off":
		return null
	var cone_cos: float = 0.98 if assist == "low" else 0.90
	var best: Node2D = null
	var best_score: float = INF
	for enemy in GameManager.get_enemies():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		if to_enemy.length_squared() <= 1.0:
			continue
		var dist: float = to_enemy.length()
		var dot_value: float = aim_dir.dot(to_enemy.normalized())
		if dot_value < cone_cos:
			continue
		var score: float = dist + (1.0 - dot_value) * 650.0
		if score < best_score:
			best_score = score
			best = enemy
	return best

func _get_manual_line_target(origin: Vector2, aim_dir: Vector2, reach: float, width: float) -> Node2D:
	var best: Node2D = null
	var best_along: float = INF
	for enemy in GameManager.get_enemies():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var rel: Vector2 = enemy.global_position - origin
		var along: float = rel.dot(aim_dir)
		if along < 0.0 or along > reach:
			continue
		var lateral: float = absf(rel.cross(aim_dir))
		if lateral <= width and along < best_along:
			best = enemy
			best_along = along
	return best

func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := 999999.0
	for e in GameManager.get_enemies():
		if not is_instance_valid(e):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest

func _spawn_proj(pos: Vector2, dir: Vector2, dmg: float, prc: int, scale_mult: float = 1.0, source_id: String = "primary_fire") -> Area2D:
	var proj = projectile_scene.instantiate()
	proj.global_position = pos
	proj.direction = dir
	proj.speed = projectile_speed
	proj.damage = dmg
	proj.pierce = prc
	proj.proj_scale = proj_scale * scale_mult
	proj.explode = (explode_on_hit and source_id != "primary_fire") or evo_nova_cannon
	proj.explode_damage = dmg * explode_damage_mult * (1.4 if evo_nova_cannon else 1.0)
	proj.explode_radius = explode_radius * (1.5 if evo_nova_cannon else 1.0) * (aura_radius / 90.0)
	proj.chain_explode = evo_chain_reactor
	proj.source_id = source_id
	proj.crit_chance = crit_chance
	if evo_nova_cannon:
		proj.pierce = max(proj.pierce, 3)
		proj.proj_scale *= 1.6
	# 3.17 systems that ride on projectiles.
	if homing_tier > 0 and source_id in ["primary_fire", "side_guns", "scattergun"]:
		proj.homing_enabled = true
		proj.homing_turn_rate = [2.5, 4.5, 8.0][clampi(homing_tier - 1, 0, 2)]
		proj.homing_range = 260.0 + homing_tier * 60.0
	if (burn_tier > 0 or cryo_tier > 0) and source_id != "primary_fire":
		var bt := burn_tier
		var ct := cryo_tier
		var dmg_ref := dmg
		var src := source_id
		proj.on_hit = func(_pr, body):
			if bt > 0:
				StatusHost.apply(body, "burn", 1.5 + bt * 0.4, dmg_ref * (0.08 + bt * 0.04), src)
			if ct > 0 and body.has_method("apply_freeze_progress"):
				body.apply_freeze_progress(0.10 + ct * 0.06, 1.4)
				if ct >= 3:
					StatusHost.apply(body, "chilled", 1.0, 0.2, src)
	GameManager.spawn(proj)
	if source_id in ["primary_fire", "side_guns"]:
		AudioManager.play("shoot", 1.0 + randf_range(-0.08, 0.12), -8.0)
		VFX.muzzle_flash(pos, dir, Color(0.75, 0.95, 1.0), 0.8 * proj.proj_scale)
	elif source_id == "missile_system":
		AudioManager.play("missile", 1.0, -6.0)
		VFX.muzzle_flash(pos, dir, Color(1.0, 0.8, 0.45), 0.9)
		VFX.smoke(pos - dir * 6.0, 2, Color(0.55, 0.55, 0.6, 0.28), 6.0)
	return proj

func _get_nearest_enemy_from(origin: Vector2, exclude: Array = []) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for e in GameManager.get_enemies():
		if not is_instance_valid(e) or e in exclude:
			continue
		var d = origin.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _apply_area_control(center: Vector2, damage_radius: float, control_radius: float, pull_strength: float, slow_amount: float, duration: float = 0.35) -> void:
	for enemy in GameManager.get_enemies():
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var d: float = center.distance_to(enemy.global_position)
		if d > control_radius:
			continue
		var falloff: float = 1.0
		if control_radius > damage_radius:
			falloff = clampf(1.0 - maxf(0.0, d - damage_radius) / maxf(1.0, control_radius - damage_radius), 0.28, 1.0)
		if enemy.has_method("apply_area_control"):
			enemy.apply_area_control(center, pull_strength * falloff, slow_amount * falloff, duration)
		elif enemy is Node2D:
			var pull_dir: Vector2 = (center - enemy.global_position).normalized()
			enemy.global_position += pull_dir * pull_strength * 0.08 * falloff

func _fire() -> void:
	if not projectile_scene:
		return
	if projectile_count <= 0:
		return
	if "unstable_ai" in GameManager.cursed_upgrades and randf() < 0.10:
		VFX.ring_burst(global_position, 24.0, Color(1.0, 0.2, 0.4, 0.45))
		return
	var target: Node2D = _get_nearest_enemy()
	var aim_dir: Vector2 = _get_aim_direction(rotation - PI / 2.0)
	if _is_manual_aim():
		# Manual aim always fires toward the cursor; target assistance is optional.
		target = _get_manual_target(global_position, aim_dir)
	var base_angle: float = aim_dir.angle() if _is_manual_aim() else ((target.global_position - global_position).angle() if target else rotation - PI / 2.0)

	var count = projectile_count
	if evo_bullet_hell:
		count += 3
	var base_spread = 0.22 + spread_bonus + (0.15 if evo_bullet_hell else 0.0)

	for i in range(count):
		var angle_offset = 0.0
		if count > 1:
			angle_offset = lerp(-base_spread, base_spread, float(i) / float(count - 1))
		# Primary cannons are the hull's base gun, not a build core: 55% of weapon damage.
		_spawn_proj(global_position + Vector2.from_angle(base_angle) * 18.0, Vector2.from_angle(base_angle + angle_offset), damage * 0.55, pierce, 0.9, "primary_fire")

	_notify_weapon_vfx("bullet")


func take_damage(amount: float) -> void:
	if is_dead:
		return
	if invuln_timer > 0.0 or GameManager.is_game_over:
		if dash_iframe_timer > 0.0 and _dash_shield:
			_dash_shield.ripple()
		return
	_siphon_lockout = 0.8
	current_hp -= amount
	invuln_timer = INVULN_TIME
	var heavy_hit := amount >= max_hp * 0.18
	VFX.player_hit_feedback(global_position, heavy_hit)
	AudioManager.play("player_hurt", 1.0, -2.0)
	if current_hp <= 0.0 and has_second_wind and not second_wind_used:
		current_hp = 1.0
		second_wind_used = true
		invuln_timer = 1.2
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		current_hp = 0.0
		_die()

## Recoil is purely visual: the hull art kicks back and eases home; the body never moves.
func visual_recoil(dir: Vector2, px: float) -> void:
	var art: Node2D = get_node_or_null("ShipArt")
	if art == null:
		return
	art.position = -dir.rotated(-rotation) * px
	var tw := art.create_tween()
	tw.tween_property(art, "position", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _accent_color() -> Color:
	match GameManager.selected_character:
		"bulwark": return Color(1.0, 0.58, 0.18)
		"nova": return Color(1.0, 0.35, 0.82)
		"voidrunner": return Color(0.65, 0.45, 1.0)
		"destroyer": return Color(1.0, 0.28, 0.18)
		"aegis": return Color(0.35, 0.72, 1.0)
		"tempest": return Color(0.35, 0.55, 1.0)
		"dreadnought": return Color(0.92, 0.34, 0.28)
		"singularity": return Color(0.66, 0.34, 1.0)
	return Color(0.35, 0.85, 1.0)

func _setup_engine_trail() -> void:
	_engine_trail = CPUParticles2D.new()
	_engine_trail.name = "EngineTrail"
	_engine_trail.z_index = -1
	_engine_trail.amount = 40
	_engine_trail.lifetime = 0.55
	_engine_trail.lifetime_randomness = 0.35
	_engine_trail.local_coords = false
	_engine_trail.position = Vector2(0, 18)
	_engine_trail.direction = Vector2(0, 1)
	_engine_trail.spread = 14.0
	_engine_trail.initial_velocity_min = 40.0
	_engine_trail.initial_velocity_max = 90.0
	_engine_trail.damping_min = 60.0
	_engine_trail.damping_max = 120.0
	_engine_trail.scale_amount_min = 1.4
	_engine_trail.scale_amount_max = 3.0
	var accent := _accent_color()
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 0.95, 0.9))
	grad.add_point(0.25, Color(accent.r, accent.g, accent.b, 0.7))
	grad.set_color(grad.get_point_count() - 1, Color(accent.r, accent.g, accent.b, 0.0))
	_engine_trail.color_ramp = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	_engine_trail.scale_amount_curve = curve
	_engine_trail.emitting = true
	add_child(_engine_trail)

func _update_engine_trail(_delta: float) -> void:
	if _engine_trail == null:
		return
	var throttle := clampf(velocity.length() / maxf(speed, 1.0), 0.0, 1.5)
	_engine_trail.emitting = throttle > 0.08 and visible
	_engine_trail.initial_velocity_max = 60.0 + throttle * 80.0
	_engine_trail.modulate.a = clampf(0.35 + throttle * 0.65, 0.0, 1.0)
	_engine_trail.scale_amount_max = 1.8 + throttle * 1.6

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	current_hp = 0.0
	health_changed.emit(0.0, max_hp)
	vacuum_timer = 0.0
	dash_timer = 0.0
	dash_iframe_timer = 0.0
	_sync_dash_shield()
	if weapons:
		weapons.set_process(false)
	for r in get_tree().get_nodes_in_group("void_reticles"):
		r.queue_free()
	var accent := _accent_color()
	VFX.ship_breakup(global_position, rotation, accent)
	VFX.explosion(global_position, 88.0, Color(accent.r, accent.g, accent.b, 0.9))
	VFX.shockwave(global_position, 220.0, Color(1, 1, 1, 0.85), 4.0, 0.5)
	VFX.sparks(global_position, 32, Color(1.0, 0.9, 0.6), 300.0, 0.7)
	VFX.smoke(global_position, 10, Color(0.35, 0.35, 0.4, 0.4), 22.0)
	VFX.screen_shake(9.0)
	VFX.screen_flash(Color(1.0, 0.35, 0.2, 0.4), 0.35)
	AudioManager.play("ship_destroy", 1.0, 1.5)
	AudioManager.play("explode", 0.9, -2.0)
	# Mark run over immediately so enemies/spawner stop, but delay the end screen
	# so the breakup + explosion can fully play out.
	GameManager.is_game_over = true
	visible = false
	set_physics_process(false)
	var tree := get_tree()
	if tree:
		await tree.create_timer(1.15).timeout
	GameManager.player_died.emit()

func add_xp(amount: float) -> void:
	if is_dead or GameManager.is_game_over:
		return
	current_xp += amount * gem_value_mult * xp_gain_mult
	# One pickup can grant a level, but never chain multiple level-up screens at once.
	if current_xp >= xp_to_next:
		current_xp -= xp_to_next
		_level_up()
	xp_changed.emit(current_xp, xp_to_next)

func _level_up() -> void:
	level += 1
	# Accelerating curve: frequent early rewards, then deliberate mid/late progression.
	# Steeper than the enemy XP income curve so late levels stay deliberate:
	# ~lvl 8 by 3:00, ~13 by 5:00, ~17 by 7:00, ~20 by 9-10:00 on a normal build.
	xp_to_next = 22.0 + pow(float(level), 1.42) * 6.2
	leveled_up.emit(level)
	GameManager.player_leveled_up.emit(level)
	GameManager.update_mission("level")
	VFX.level_up_burst(global_position)
	VFX.shockwave(global_position, 120.0, Color(0.6, 0.95, 1.0, 0.8), 3.0, 0.45)
	VFX.sparks(global_position, 18, Color(0.7, 0.95, 1.0), 200.0, 0.55)
	VFX.screen_flash(Color(0.5, 0.9, 1.0, 0.18), 0.3)
	VFX.screen_shake(2.0)
	AudioManager.play("level_up", 1.0, -2.0)
	current_hp = mini(current_hp + 12.0 + level * 0.5, max_hp)
	health_changed.emit(current_hp, max_hp)

func apply_upgrade(upgrade_id: String, rarity: int = 0) -> void:
	if not GameManager.can_take_upgrade(upgrade_id):
		return
	GameManager.level_up_upgrade(upgrade_id)
	var lv := GameManager.get_upgrade_level(upgrade_id)
	var rarity_bonus := GameManager.get_upgrade_roll_value(upgrade_id, rarity)
	var gained: float = 0.0
	match upgrade_id:
		"damage":
			gained = GameManager.add_run_upgrade_bonus("damage", rarity_bonus)
			damage *= 1.0 + gained
		"speed":
			gained = GameManager.add_run_upgrade_bonus("speed", rarity_bonus)
			speed *= 1.0 + gained
		"fire_rate":
			gained = GameManager.add_run_upgrade_bonus("fire_rate", rarity_bonus)
			fire_rate = max(0.09, fire_rate * (1.0 - gained))
		"projectile_speed":
			gained = GameManager.add_run_upgrade_bonus("projectile_speed", rarity_bonus)
			projectile_speed *= 1.0 + gained
		"max_hp":
			gained = GameManager.add_run_upgrade_bonus("max_hp", rarity_bonus)
			var hull_gain := max_hp * gained
			max_hp += hull_gain
			current_hp = minf(current_hp + hull_gain, max_hp)
			health_changed.emit(current_hp, max_hp)
		"xp_magnet":
			gained = GameManager.add_run_upgrade_bonus("xp_magnet", rarity_bonus)
			xp_magnet_range *= 1.0 + gained
			_update_xp_magnet()
		"xp_gain":
			gained = GameManager.add_run_upgrade_bonus("xp_gain", rarity_bonus)
			xp_gain_mult += gained
		"scrap":
			gained = GameManager.add_run_upgrade_bonus("scrap", rarity_bonus)
			scrap_gain_mult += gained
		"extra_projectile":
			# (3.17.6) no longer touches projectile_count: that legacy line switched on the
			# pre-signature-weapon base cannons, a hidden free weapon.
			for weapon_id in GameManager.get_equipped_weapon_ids():
				if weapon_id in GameManager.SYSTEM_COMPATIBILITY["extra_projectile"]:
					extra_projectiles_by_weapon[weapon_id] = int(extra_projectiles_by_weapon.get(weapon_id, 0)) + 1
		"pierce":
			pierce += 1
		"area":
			# Tiered system: +18% per tier to every area-type effect.
			spread_bonus += 0.06
			aura_radius *= 1.18
			explode_radius *= 1.12
		"luck":
			gained = GameManager.add_run_upgrade_bonus("luck", rarity_bonus)
			GameManager.add_luck(gained)
		"proj_size":
			proj_scale *= 1.18
			explode_radius *= 1.08
			if lv >= 2:
				damage *= 1.06
		"explosive":
			match lv:
				1:
					explode_on_hit = true
					explode_damage_mult += 0.15
				2:
					explode_radius *= 1.35
				_:
					explode_damage_mult += 0.5
		"duration":
			duration_mult += 0.25
		"homing":
			homing_tier = lv
		"incendiary":
			burn_tier = lv
		"cryo_rounds":
			cryo_tier = lv
		"slow_field":
			slow_field = mini(0.45, slow_field + 0.12)
		"crit":
			gained = GameManager.add_run_upgrade_bonus("crit", rarity_bonus)
			crit_chance = minf(0.60, crit_chance + gained)
		"lifesteal":
			lifesteal = true
		"oc_damage": damage *= 1.015; GameManager.overcharge_levels += 1
		"oc_fire_rate": fire_rate *= 0.99; GameManager.overcharge_levels += 1
		"oc_speed": speed *= 1.02; GameManager.overcharge_levels += 1
		"oc_hull":
			max_hp *= 1.02; current_hp = minf(current_hp * 1.02, max_hp); health_changed.emit(current_hp, max_hp); GameManager.overcharge_levels += 1
		"oc_proj_speed": projectile_speed *= 1.02; GameManager.overcharge_levels += 1
		"oc_crit": crit_chance = minf(0.85, crit_chance + 0.005); GameManager.overcharge_levels += 1
		_:
			if GameManager.is_weapon_upgrade(upgrade_id) and weapons:
				weapons.set_level(upgrade_id, lv)

	_refresh_weapon_modules()

func _on_synergy_activated(synergy_id: String) -> void:
	var data: Dictionary = GameManager.WEAPON_SYNERGIES.get(synergy_id, {})
	if data.is_empty():
		return
	if weapons:
		weapons.activate_super(synergy_id)
	var col: Color = data.get("color", Color(0.5, 0.8, 1.0))
	VFX.superweapon_activation(global_position, col)
	AudioManager.play("superweapon", 1.0, 0.0)

func _notify_weapon_vfx(kind: String) -> void:
	var modules = get_node_or_null("WeaponModules")
	if modules and modules.has_method("weapon_fired"):
		modules.weapon_fired(kind)

func _refresh_weapon_modules() -> void:
	var modules = get_node_or_null("WeaponModules")
	if modules and modules.has_method("queue_redraw"):
		modules.queue_redraw()

func on_relic_gained(relic_id: String) -> void:
	if relic_id in ["twin_thrusters", "phase_thrusters"]:
		dash_charges_max += 1
		dash_charges += 1
		if relic_id == "phase_thrusters":
			dash_slow = true
	match relic_id:
		"second_wind":
			has_second_wind = true
		"thorns":
			thorns_percent = 0.4
		_:
			pass

## Energy Siphon: heals 1% of max hull per kill, capped at 3% max hull per second, and
## goes quiet for 0.8s after taking damage. Strong sustain while you fight well; not an
## AFK button while you're being hit.
var _siphon_budget: float = 0.0
var _siphon_lockout: float = 0.0

func on_kill_heal() -> void:
	if is_dead or not lifesteal or _siphon_lockout > 0.0:
		return
	var amount := minf(max_hp * 0.01, _siphon_budget)
	if amount <= 0.0:
		return
	_siphon_budget -= amount
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func _tick_siphon(delta: float) -> void:
	_siphon_budget = minf(_siphon_budget + max_hp * 0.03 * delta, max_hp * 0.03)
	_siphon_lockout = maxf(0.0, _siphon_lockout - delta)

## Magnet pickup effect. Explicit sweeps every physics frame + a final sweep at the end,
## so eligible drops can never be stranded by missed Area2D overlaps.
const MAGNET_FINAL_RADIUS := 340.0
const PICKUP_COLLECT_RADIUS := 22.0
var magnet_elite: bool = false
var _magnet_fx: Node2D = null

func activate_vacuum(duration: float = 4.0, elite: bool = false) -> void:
	AudioManager.play("shield", 1.1, -4.0)
	vacuum_timer = maxf(vacuum_timer, duration)
	magnet_elite = magnet_elite or elite
	VFX.ring_burst(global_position, 80.0, Color(0.35, 0.85, 1.0, 0.55))
	VFX.shockwave(global_position, 260.0, Color(0.6, 0.9, 1.0, 0.8), 3.0, 0.5)
	if _magnet_fx == null or not is_instance_valid(_magnet_fx):
		_magnet_fx = Node2D.new()
		_magnet_fx.set_script(load("res://scripts/MagnetFX.gd"))
		_magnet_fx.player = self
		GameManager.spawn(_magnet_fx)
	_magnet_fx.elite = magnet_elite
	_magnet_sweep()

## Normal pickup radius: attract anything inside xp_magnet_range, collect anything touching.
func _pickup_sweep() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var origin := global_position
	var r2 := xp_magnet_range * xp_magnet_range
	var c2 := PICKUP_COLLECT_RADIUS * PICKUP_COLLECT_RADIUS
	for grp in ["xp_gems", "scrap_pickups"]:
		for g in tree.get_nodes_in_group(grp):
			if not is_instance_valid(g) or g.get("collected") == true:
				continue
			var d2 := origin.distance_squared_to(g.global_position)
			if d2 <= c2:
				g.collect_now()
			elif d2 <= r2 and not bool(g.get("attracting")):
				g.start_attract(self)

## While the magnet is active: every eligible drop on the map is pulled (boosted).
func _magnet_sweep() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for grp in ["xp_gems", "scrap_pickups", "pickups"]:
		for g in tree.get_nodes_in_group(grp):
			if not is_instance_valid(g) or g.get("collected") == true:
				continue
			if not bool(g.get("boosted")):
				g.start_attract(self, true)

## When the magnet ends: anything inside the final radius is collected instantly;
## everything else keeps flying in (start_attract is sticky).
func _magnet_final_sweep() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r2 := MAGNET_FINAL_RADIUS * MAGNET_FINAL_RADIUS
	var n := 0
	for grp in ["xp_gems", "scrap_pickups", "pickups"]:
		for g in tree.get_nodes_in_group(grp):
			if not is_instance_valid(g) or g.get("collected") == true:
				continue
			if global_position.distance_squared_to(g.global_position) <= r2:
				g.collect_now()
				n += 1
			elif not bool(g.get("attracting")):
				g.start_attract(self, true)
	magnet_elite = false
	if is_instance_valid(_magnet_fx):
		_magnet_fx.finish()
	_magnet_fx = null
	if n > 0:
		VFX.shockwave(global_position, MAGNET_FINAL_RADIUS, Color(0.7, 0.95, 1.0, 0.9), 3.0, 0.45)
		AudioManager.play("shield", 1.4, -6.0)

func heal(amount: float) -> void:
	if is_dead or GameManager.is_game_over:
		return
	current_hp = mini(current_hp + amount, max_hp)
	VFX.ring_burst(global_position, 38.0, Color(0.3, 1.0, 0.5, 0.55))
	health_changed.emit(current_hp, max_hp)

func _update_xp_magnet() -> void:
	if xp_shape and xp_shape.shape is CircleShape2D:
		(xp_shape.shape as CircleShape2D).radius = xp_magnet_range

func _on_hurtbox_body_entered(body: Node2D) -> void:
	_contact_hit(body)

## Contact damage is continuous: every time the i-frame window ends while an enemy is still
## overlapping the hurtbox, the strongest overlapping enemy hits again. Previously only the
## first touch dealt damage (and even that was dropped if it landed during i-frames), which is
## why standing inside a swarm or on top of the boss was nearly free.
func _contact_hit(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	var dmg = body.contact_damage if "contact_damage" in body else 10.0
	if body.is_in_group("boss"):
		dmg *= 1.6
	take_damage(dmg)
	if thorns_percent > 0.0 and body.has_method("take_damage"):
		body.take_damage(dmg * thorns_percent)

func _tick_contact() -> void:
	if invuln_timer > 0.0 or dash_timer > 0.0:
		return
	var hb: Area2D = get_node_or_null("Hurtbox")
	if hb == null:
		return
	var best: Node2D = null
	var best_dmg := 0.0
	var bodies: Array = hb.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("enemies"):
			var d: float = float(b.contact_damage) if "contact_damage" in b else 10.0
			if d > best_dmg:
				best_dmg = d
				best = b
	if best:
		_contact_hit(best)

func _on_xp_magnet_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_gems") and area.has_method("start_attract"):
		area.start_attract(self)
	if area.is_in_group("scrap_pickups") and area.has_method("collect"):
		area.collect()
	# Heal / magnet pickups drift in on their own interaction radius (see Pickup.gd).


# ---------------------------------------------------------------------------
# Dash impact (3.18): modest built-in damage + class-based control, once per enemy per dash.
# Not scaled by weapon stats; tracked as "ship_ability".
# ---------------------------------------------------------------------------
const DASH_SHIP := {
	"viper":       {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 1.5, "kb": 1.0, "stagger": 0.35},
	"voidrunner":  {"speed": 1.12, "duration": 1.25, "iframe_bonus": 0.0,  "dmg": 1.0, "kb": 0.9, "stagger": 0.3},
	"bulwark":     {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.18, "dmg": 0.9, "kb": 1.0, "stagger": 0.35},
	"destroyer":   {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 1.25, "kb": 1.4, "stagger": 0.6},
	"aegis":       {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 0.8, "kb": 0.6, "stagger": 0.5},
	"tempest":     {"speed": 1.05, "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 1.0, "kb": 0.9, "stagger": 0.3},
	"dreadnought": {"speed": 0.95, "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 1.2, "kb": 1.6, "stagger": 0.7},
	"nova":        {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 1.1, "kb": 1.0, "stagger": 0.35},
	"singularity": {"speed": 1.0,  "duration": 1.0,  "iframe_bonus": 0.0,  "dmg": 0.9, "kb": 0.7, "stagger": 0.4},
}

## The forcefield mirrors the REAL dash i-frame state; evaluated at dash start and at the end of
## every physics step (after all timers have been decremented).
func _sync_dash_shield() -> void:
	if _dash_shield:
		_dash_shield.visible = dash_iframe_timer > 0.0 and invuln_timer > 0.0

func _dash_ship(key: String) -> float:
	var d: Dictionary = DASH_SHIP.get(GameManager.selected_character, DASH_SHIP["viper"])
	return float(d.get(key, 1.0))

## Enemy size class for control effects: small / medium / elite / boss.
static func enemy_class(e: Node) -> String:
	if e.is_in_group("boss"):
		return "boss"
	if e.is_in_group("elites"):
		return "elite"
	var t: String = str(e.get("enemy_type")) if e.get("enemy_type") != null else "chaser"
	return "small" if t in ["chaser", "swarmer"] else "medium"

## Shared knockback/stagger rule (used by the dash and Void Blades).
static func apply_control(e: Node2D, dir: Vector2, kb_small: float, kb_medium: float, elite_shift: float, elite_stagger: float) -> void:
	if not (e is CharacterBody2D):
		return
	match enemy_class(e):
		"small": e.global_position += dir * kb_small
		"medium": e.global_position += dir * kb_medium
		"elite":
			e.global_position += dir * elite_shift
			if "frozen_timer" in e:
				e.frozen_timer = maxf(float(e.frozen_timer), elite_stagger)
		_: pass   # bosses are never displaced

func _dash_impact() -> void:
	var ship := GameManager.selected_character
	var base := 18.0 * (1.0 + float(level) * 0.03) * _dash_ship("dmg")
	for e in GameManager.get_enemies():
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		if global_position.distance_to(e.global_position) > 46.0:
			continue
		var key: int = e.get_instance_id()
		if _dash_hits.has(key):
			continue
		_dash_hits[key] = true
		var dmg_amt := base
		GameManager.record_damage("ship_ability", dmg_amt)
		e.take_damage(dmg_amt)
		var kb: float = _dash_ship("kb")
		apply_control(e, dash_direction, 90.0 * kb, 55.0 * kb, 12.0 * kb, _dash_ship("stagger"))
		VFX.hit(e.global_position, false, _accent_color())
		if dash_slow and "chill_timer" in e:
			e.chill_timer = 1.2
			e.chill_factor = 0.6
		match ship:
			"tempest":
				var n := 0
				for o in GameManager.get_enemies():
					if n >= 2 or o == e or not is_instance_valid(o): continue
					if o.global_position.distance_to(e.global_position) < 140.0:
						WeaponFX.bolt(e.global_position, o.global_position, Color(0.6, 0.9, 1.0), 2.5, 0.15)
						GameManager.record_damage("ship_ability", 8.0)
						o.take_damage(8.0)
						n += 1
			"nova":
				StatusHost.apply(e, "burn", 1.5, 3.0, "ship_ability")
			"singularity":
				if e.has_method("apply_freeze_progress"):
					e.apply_freeze_progress(0.35, 1.4)
			"aegis":
				if "chill_timer" in e:
					e.chill_timer = 1.0
					e.chill_factor = 0.5

func _process(_delta: float) -> void:
	_sync_dash_shield()
	if is_dead and current_hp != 0.0:
		current_hp = 0.0
		health_changed.emit(0.0, max_hp)
