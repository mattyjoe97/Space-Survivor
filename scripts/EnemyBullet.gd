extends Area2D
## Enemy projectile with distinct, high-contrast silhouettes per kind:
##  dart   - default: small hot-pink dart with a bright white core and a short trail
##  needle - sniper: long thin cyan-white needle, fast, with a long trail
##  blob   - void spitter: fat magenta plasma blob that leaves a short-lived acid puddle
##  orb    - boss: slow violet orb with a dark halo and a pulsing core
## Every kind has a dark outline halo (contrast on nebula backgrounds), a bright core, and a
## proximity warning flash when it gets close to the ship.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: float = 14.0
var lifetime: float = 3.5
var kind: String = "dart"
var leaves_puddle: bool = false
var _t := 0.0
var _trail: Array[Vector2] = []
var _line: Line2D = null

func _ready() -> void:
	add_to_group("enemy_bullets")
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	z_index = 12
	$Poly.visible = false
	$Glow.visible = false
	_line = Line2D.new()
	_line.top_level = true
	_line.z_index = 11
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	var wc := Curve.new(); wc.add_point(Vector2(0, 0.0)); wc.add_point(Vector2(1, 1.0))
	_line.width_curve = wc
	var g := Gradient.new()
	var c := _color()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0)); g.set_color(1, Color(c.r, c.g, c.b, 0.7))
	_line.gradient = g
	_line.width = {"dart": 4.0, "needle": 3.0, "blob": 7.0, "orb": 6.0}.get(kind, 4.0)
	add_child(_line)

func _color() -> Color:
	match kind:
		"needle": return Color(0.55, 0.95, 1.0)
		"blob": return Color(1.0, 0.35, 0.95)
		"orb": return Color(0.75, 0.4, 1.0)
	return Color(1.0, 0.3, 0.5)

func _physics_process(delta: float) -> void:
	_t += delta
	position += direction * speed * delta
	lifetime -= delta
	_trail.push_back(global_position)
	var keep := 10 if kind == "needle" else 6
	while _trail.size() > keep:
		_trail.pop_front()
	_line.points = PackedVector2Array(_trail)
	if lifetime <= 0.0:
		_expire()
		return
	queue_redraw()

func _expire() -> void:
	if leaves_puddle:
		_spawn_puddle()
	queue_free()

func _spawn_puddle() -> void:
	var pd := Node2D.new()
	pd.set_script(load("res://scripts/EnemyPuddle.gd"))
	pd.global_position = global_position
	pd.damage_per_second = damage * 0.6
	GameManager.spawn(pd, true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if leaves_puddle:
			_spawn_puddle()
		queue_free()

func _draw() -> void:
	var c := _color()
	var p = GameManager.player
	var near := 0.0
	if is_instance_valid(p):
		near = clampf(1.0 - global_position.distance_to(p.global_position) / 140.0, 0.0, 1.0)
	var flash := 0.5 + 0.5 * sin(_t * 30.0)
	var outline := Color(0.03, 0.0, 0.06, 0.85)
	match kind:
		"needle":
			draw_line(Vector2(-16, 0), Vector2(14, 0), outline, 6.0)
			draw_line(Vector2(-16, 0), Vector2(14, 0), c, 3.0)
			draw_line(Vector2(-8, 0), Vector2(14, 0), Color(1, 1, 1, 0.95), 1.4)
			draw_circle(Vector2(14, 0), 3.0, Color(1, 1, 1, 0.95))
		"blob":
			var r := 8.0 + sin(_t * 12.0) * 1.2
			draw_circle(Vector2.ZERO, r + 3.0, outline)
			draw_circle(Vector2.ZERO, r, c)
			draw_circle(Vector2(-2, -2), r * 0.45, Color(1.0, 0.85, 1.0, 0.95))
			for i in range(3):
				var a := _t * 6.0 + i * TAU / 3.0
				draw_circle(Vector2.from_angle(a) * (r + 2.0), 1.8, Color(1.0, 0.6, 1.0, 0.8))
		"orb":
			var r2 := 9.0 + sin(_t * 8.0) * 1.5
			draw_circle(Vector2.ZERO, r2 + 4.0, outline)
			draw_circle(Vector2.ZERO, r2 + 1.0, Color(c.r, c.g, c.b, 0.55))
			draw_circle(Vector2.ZERO, r2 * 0.6, Color(1.0, 0.9, 1.0, 0.95))
			draw_arc(Vector2.ZERO, r2 + 3.0, _t * 5.0, _t * 5.0 + 3.0, 12, Color(1, 1, 1, 0.6), 1.2)
		_:
			var pts := PackedVector2Array([Vector2(11, 0), Vector2(-6, -5), Vector2(-3, 0), Vector2(-6, 5)])
			var big := PackedVector2Array([Vector2(14, 0), Vector2(-9, -8), Vector2(-5, 0), Vector2(-9, 8)])
			draw_colored_polygon(big, outline)
			draw_colored_polygon(pts, c)
			draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(-2, -2), Vector2(-1, 0), Vector2(-2, 2)]), Color(1, 1, 1, 0.95))
	# Proximity warning: brightening ring as it closes on the ship.
	if near > 0.0:
		draw_arc(Vector2.ZERO, 14.0 + near * 6.0, 0.0, TAU, 20, Color(1.0, 0.95, 0.6, 0.35 + near * 0.5 * flash), 1.5 + near)
