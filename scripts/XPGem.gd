extends Area2D
## XP gem. Collection is driven by the player's explicit pickup sweep (distance based)
## with the Area2D overlap kept only as a redundant path. `collected` guards double-collect.

var xp_amount: float = 5.0
var target: Node2D = null
var attracting: bool = false
var boosted: bool = false
var collected: bool = false
var speed: float = 0.0
var trail: Line2D
var trail_points: Array[Vector2] = []
var base_rotation: float = 0.0

func _ready() -> void:
	add_to_group("xp_gems")
	body_entered.connect(_on_body_entered)
	base_rotation = rotation
	trail = Line2D.new()
	trail.width = 2.0
	trail.default_color = Color(0.45, 1.0, 0.7, 0.28)
	trail.z_index = -1
	add_child(trail)

func start_attract(p: Node2D, boost: bool = false) -> void:
	target = p
	attracting = true
	boosted = boosted or boost
	if boost:
		trail.default_color = Color(0.7, 1.0, 0.9, 0.5)
		trail.width = 3.0

func _physics_process(delta: float) -> void:
	if collected:
		return
	rotation = base_rotation + sin(Time.get_ticks_msec() * 0.004 + global_position.x * 0.01) * 0.35
	if attracting and is_instance_valid(target):
		var cap := 1150.0 if boosted else 640.0
		speed = minf(speed + (1600.0 if boosted else 800.0) * delta, cap)
		var dir: Vector2 = (target.global_position - global_position).normalized()
		global_position += dir * speed * delta
		trail_points.push_back(to_local(global_position))
		if trail_points.size() > 7:
			trail_points.pop_front()
		trail.points = PackedVector2Array(trail_points)
		if global_position.distance_to(target.global_position) < 22.0:
			collect_now()
	else:
		position.y += sin(Time.get_ticks_msec() * 0.005 + position.x) * 0.15

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		collect_now()

func collect_now() -> void:
	if collected:
		return
	collected = true
	VFX.pickup_collect(global_position, "xp", clampf(xp_amount / 5.0, 0.8, 1.5))
	AudioManager.play("pickup_xp", 1.0 + randf_range(-0.05, 0.1), -9.0)
	if GameManager.player and GameManager.player.has_method("add_xp"):
		GameManager.player.add_xp(xp_amount)
	queue_free()

func _collect() -> void:
	collect_now()
