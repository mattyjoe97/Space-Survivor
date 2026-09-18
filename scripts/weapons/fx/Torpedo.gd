extends Node2D
## Heavy torpedo: starts slow, accelerates, explodes on contact or after proximity fuse.
var direction := Vector2.RIGHT
var weapon: WeaponBase = null
var target: Node2D = null
var blast_radius := 120.0
var damage := 40.0
var accel := 400.0
var cluster := false
var _speed := 120.0
var _t := 0.0
var _life := 3.0
var _exhaust: CPUParticles2D = null

func _ready() -> void:
	z_index = 8
	rotation = direction.angle()
	_exhaust = CPUParticles2D.new()
	_exhaust.amount = 24
	_exhaust.lifetime = 0.6
	_exhaust.local_coords = false
	_exhaust.position = Vector2(-14, 0)
	_exhaust.direction = Vector2(-1, 0)
	_exhaust.spread = 10.0
	_exhaust.initial_velocity_min = 20.0
	_exhaust.initial_velocity_max = 50.0
	_exhaust.scale_amount_min = 2.0
	_exhaust.scale_amount_max = 4.0
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.8, 0.4, 0.9))
	g.add_point(0.3, Color(0.6, 0.6, 0.65, 0.6))
	g.set_color(g.get_point_count() - 1, Color(0.4, 0.4, 0.45, 0.0))
	_exhaust.color_ramp = g
	add_child(_exhaust)

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	_t += delta
	_life -= delta
	_speed = minf(_speed + accel * delta, 900.0)
	# Gentle steer toward target so slow launches still connect.
	if is_instance_valid(target):
		var want := (target.global_position - global_position).normalized()
		var turn: float = float(get_meta("turn", 1.4))
		direction = direction.rotated(clampf(direction.angle_to(want), -turn * delta, turn * delta))
		rotation = direction.angle()
	global_position += direction * _speed * delta
	# Proximity fuse
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and e.global_position.distance_to(global_position) < 30.0:
			_detonate()
			return
	if _life <= 0.0:
		_detonate()
		return
	queue_redraw()

func _detonate() -> void:
	VFX.explosion(global_position, blast_radius * 0.55, Color(1.0, 0.55, 0.25, 0.9))
	VFX.shockwave(global_position, blast_radius * 1.15, Color(1, 1, 1, 0.85), 5.0, 0.45)
	WeaponFX.pulse(global_position, 10.0, blast_radius, Color(1.0, 0.6, 0.3), 0.4, 14.0)
	VFX.smoke(global_position, 8, Color(0.4, 0.38, 0.4, 0.4), blast_radius * 0.25)
	VFX.screen_shake(5.0)
	VFX.postfx_punch(0.4)
	AudioManager.play("big_boom", 1.0, -3.0)
	if weapon:
		for e in weapon.in_radius(global_position, blast_radius):
			var d := global_position.distance_to(e.global_position)
			var falloff := 1.0 - 0.5 * (d / blast_radius)
			if e.is_in_group("elites") or e.is_in_group("boss"):
				falloff *= 1.4   # heavy ordnance
			weapon.hit(e, damage * falloff)
			if weapon.player.burn_tier > 0:
				weapon.status(e, "burn", 2.0, damage * 0.05 * weapon.player.burn_tier)
			if weapon.player.cryo_tier > 0 and e.has_method("apply_freeze_progress"):
				e.apply_freeze_progress(0.2 + 0.1 * weapon.player.cryo_tier, 1.6)
			if e is CharacterBody2D:
				e.global_position += (e.global_position - global_position).normalized() * 70.0 * falloff
	if cluster:
		for i in range(int(get_meta("bomblets", 3))):
			var b := Node2D.new()
			b.set_script(load("res://scripts/weapons/fx/Bomblet.gd"))
			b.global_position = global_position
			b.velocity = Vector2.from_angle(direction.angle() + (i - 1) * 0.9 + randf_range(-0.2, 0.2)) * randf_range(180.0, 260.0)
			b.weapon = weapon
			b.radius = blast_radius * 0.45
			b.damage = damage * 0.4
			GameManager.spawn(b)
	queue_free()

func _draw() -> void:
	var s := 1.0
	# Body
	draw_colored_polygon(PackedVector2Array([Vector2(18, 0), Vector2(10, -6), Vector2(-14, -6), Vector2(-16, 0), Vector2(-14, 6), Vector2(10, 6)]) , Color(0.55, 0.58, 0.66))
	draw_polyline(PackedVector2Array([Vector2(18, 0), Vector2(10, -6), Vector2(-14, -6), Vector2(-16, 0), Vector2(-14, 6), Vector2(10, 6), Vector2(18, 0)]), Color(0.9, 0.92, 1.0, 0.7), 1.0)
	# Warhead band + fins
	draw_rect(Rect2(Vector2(6, -6), Vector2(4, 12)), Color(1.0, 0.55, 0.25))
	for sgn: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(-12, sgn * 6.0), Vector2(-18, sgn * 12.0), Vector2(-8, sgn * 6.0)]), Color(0.75, 0.4, 0.2))
	# Nozzle glow
	draw_circle(Vector2(-16, 0), 4.0 + sin(_t * 30.0) * 1.5, Color(1.0, 0.75, 0.35, 0.9))
	# Blink
	if fmod(_t, 0.3) < 0.15:
		draw_circle(Vector2(8, 0), 2.0, Color(1, 0.2, 0.2))
