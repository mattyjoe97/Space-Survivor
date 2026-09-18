extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 450.0
var damage: float = 10.0
var pierce: int = 0
var lifetime: float = 2.5
var hit_enemies: Array = []
var proj_scale: float = 1.0
var explode: bool = false
var explode_damage: float = 10.0
var explode_radius: float = 55.0
var chain_explode: bool = false
var crit_chance: float = 0.0
var homing_enabled: bool = false
var homing_target: Node2D = null
var homing_range: float = 340.0
var homing_turn_rate: float = 5.2
var homing_reacquire_timer: float = 0.0
var trail: Line2D = null
var source_id: String = "primary_fire"
var split_count: int = 0
var knockback: float = 0.0
var ricochet: int = 0
var on_hit: Callable

@onready var poly: Polygon2D = $Polygon2D
@onready var glow: Polygon2D = $Glow

var _trail_pts: Array[Vector2] = []
var _exhaust: CPUParticles2D = null
var _spin_t: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	scale = Vector2(proj_scale, proj_scale)
	_style_for_source()
	# History-based trail drawn in world space so it curves with homing shots.
	trail = Line2D.new()
	trail.name = "ProjectileTrail"
	trail.top_level = true
	trail.width = 5.0 * proj_scale
	trail.z_index = -1
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	var wc := Curve.new()
	wc.add_point(Vector2(0.0, 0.0))
	wc.add_point(Vector2(1.0, 1.0))
	trail.width_curve = wc
	var grad := Gradient.new()
	var tc := _trail_color()
	grad.set_color(0, Color(tc.r, tc.g, tc.b, 0.0))
	grad.set_color(1, Color(tc.r, tc.g, tc.b, 0.55))
	trail.gradient = grad
	add_child(trail)

func _trail_color() -> Color:
	if source_id == "missile_system":
		return Color(1.0, 0.75, 0.4)
	if homing_enabled:
		return Color(0.35, 0.9, 1.0)
	return Color(0.45, 1.0, 0.9)

func _style_for_source() -> void:
	if not poly or not glow:
		return
	if source_id == "missile_system":
		# Missile: slim body, fins, hot nozzle + exhaust particles.
		poly.polygon = PackedVector2Array([Vector2(12, 0), Vector2(6, -3), Vector2(-7, -3), Vector2(-9, -6), Vector2(-11, -6), Vector2(-9, 0), Vector2(-11, 6), Vector2(-9, 6), Vector2(-7, 3), Vector2(6, 3)])
		poly.color = Color(0.85, 0.88, 0.95, 1.0)
		glow.polygon = PackedVector2Array([Vector2(14, 0), Vector2(-12, -8), Vector2(-9, 0), Vector2(-12, 8)])
		glow.color = Color(1.0, 0.6, 0.25, 0.32)
		_exhaust = CPUParticles2D.new()
		_exhaust.amount = 18
		_exhaust.lifetime = 0.35
		_exhaust.local_coords = false
		_exhaust.position = Vector2(-10, 0)
		_exhaust.direction = Vector2(-1, 0)
		_exhaust.spread = 12.0
		_exhaust.initial_velocity_min = 30.0
		_exhaust.initial_velocity_max = 70.0
		_exhaust.scale_amount_min = 1.2
		_exhaust.scale_amount_max = 2.6
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.9, 0.6, 0.95))
		g.add_point(0.3, Color(1.0, 0.55, 0.2, 0.7))
		g.set_color(g.get_point_count() - 1, Color(0.5, 0.5, 0.55, 0.0))
		_exhaust.color_ramp = g
		_exhaust.z_index = -1
		add_child(_exhaust)
	else:
		# Energy bolt: elongated teardrop with a soft halo.
		var len := 12.0 if source_id != "side_guns" else 9.0
		poly.polygon = PackedVector2Array([Vector2(len, 0), Vector2(2, -3.2), Vector2(-6, -2.2), Vector2(-8, 0), Vector2(-6, 2.2), Vector2(2, 3.2)])
		poly.color = Color(0.85, 1.0, 1.0, 1.0)
		glow.polygon = PackedVector2Array([Vector2(len + 5, 0), Vector2(2, -7), Vector2(-9, -5), Vector2(-12, 0), Vector2(-9, 5), Vector2(2, 7)])
		glow.color = Color(0.25, 0.85, 1.0, 0.42)

func _physics_process(delta: float) -> void:
	if homing_enabled:
		homing_reacquire_timer -= delta
		if not is_instance_valid(homing_target) or homing_reacquire_timer <= 0.0:
			homing_reacquire_timer = 0.10
			if not is_instance_valid(homing_target):
				var best = null
				var best_dist := homing_range * homing_range
				for e in GameManager.get_enemies():
					if not is_instance_valid(e):
						continue
					var d = global_position.distance_squared_to(e.global_position)
					if d < best_dist:
						best_dist = d
						best = e
				homing_target = best
		if is_instance_valid(homing_target):
			var desired = (homing_target.global_position - global_position).normalized()
			if desired != Vector2.ZERO:
				var turn = clamp(direction.angle_to(desired), -homing_turn_rate * delta, homing_turn_rate * delta)
				direction = direction.rotated(turn).normalized()
				rotation = direction.angle()
	position += direction * speed * delta
	if trail:
		_trail_pts.push_back(global_position)
		if _trail_pts.size() > 9:
			_trail_pts.pop_front()
		trail.points = PackedVector2Array(_trail_pts)
	if glow:
		_spin_t += delta
		glow.scale = Vector2.ONE * (1.0 + sin(_spin_t * 30.0) * 0.12)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in hit_enemies:
		hit_enemies.append(body)
		var dmg = damage
		var critical = false
		if crit_chance > 0.0 and randf() < crit_chance:
			dmg *= 2.0
			critical = true
			if poly:
				poly.modulate = Color(1.5, 1.2, 0.4)
		if body.has_method("take_damage"):
			dmg *= StatusHost.damage_mult(body)
			GameManager.record_damage(source_id, dmg)
			body.take_damage(dmg, critical)
			if knockback > 0.0 and body is CharacterBody2D:
				body.global_position += direction * knockback
			if on_hit.is_valid():
				on_hit.call(self, body)
			if split_count > 0:
				_split(body)
			if ricochet > 0:
				ricochet -= 1
				var next := _find_ricochet_target(body)
				if next:
					damage *= 0.6   # each ricochet loses energy
					direction = (next.global_position - global_position).normalized()
					rotation = direction.angle()
					lifetime = maxf(lifetime, 0.6)
					pierce += 1
					VFX.sparks(global_position, 4, Color(1.0, 0.95, 0.6), 120.0, 0.25)
			VFX.hit(body.global_position, critical or dmg >= 35.0, Color(1.0, 0.72, 0.3, 0.95) if critical else Color(0.45, 0.9, 1.0, 0.85))
			if critical:
				VFX.sparks(body.global_position, 8, Color(1.0, 0.8, 0.35), 170.0, 0.35, -direction, 70.0)
			if critical:
				AudioManager.play("crit", 1.05, -3.0)
			else:
				AudioManager.play("hit", 1.0, -10.0)
		if explode:
			_do_explode(body.global_position)
		if hit_enemies.size() > pierce:
			queue_free()

func _find_ricochet_target(exclude: Node2D) -> Node2D:
	var best: Node2D = null
	var best_d := 260.0 * 260.0
	for e in GameManager.get_enemies():
		if not is_instance_valid(e) or e == exclude or e in hit_enemies:
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _split(body: Node2D) -> void:
	var count := split_count
	split_count = 0
	var scene: PackedScene = load("res://scenes/Projectile.tscn")
	for i in range(count):
		var p = scene.instantiate()
		p.global_position = global_position
		p.direction = direction.rotated((i - (count - 1) * 0.5) * 1.3 + randf_range(-0.2, 0.2))
		p.speed = speed * 1.15
		p.damage = damage * 0.35
		p.proj_scale = proj_scale * 0.7
		p.source_id = source_id
		p.homing_enabled = true
		p.homing_turn_rate = 7.0
		p.homing_range = 300.0
		p.lifetime = 1.6
		p.crit_chance = crit_chance
		p.hit_enemies = [body]
		GameManager.spawn(p, true)
	VFX.sparks(global_position, 6, Color(0.6, 0.85, 1.0), 120.0, 0.3)

func _do_explode(at: Vector2) -> void:
	VFX.explosion(at, explode_radius)
	AudioManager.play("explode", 0.95, -5.0)
	for e in GameManager.get_enemies():
		if not is_instance_valid(e):
			continue
		if at.distance_to(e.global_position) <= explode_radius:
			if e.has_method("take_damage"):
				var blast_damage: float = explode_damage * 0.7
				GameManager.record_damage(source_id, blast_damage)
				e.take_damage(blast_damage)
			if chain_explode and randf() < 0.35 and e.global_position.distance_to(at) > 5.0:
				VFX.explosion(e.global_position, explode_radius * 0.55, Color(1.0, 0.4, 0.1, 0.7))
				for e2 in GameManager.get_enemies():
					if is_instance_valid(e2) and e.global_position.distance_to(e2.global_position) < explode_radius * 0.6:
						if e2.has_method("take_damage"):
							var chain_damage: float = explode_damage * 0.35
							GameManager.record_damage(source_id, chain_damage)
							e2.take_damage(chain_damage)
