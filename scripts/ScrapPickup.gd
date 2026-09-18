extends Area2D
## Scrap drop. Same explicit-sweep collection model as XPGem.

var amount: int = 3
var target: Node2D = null
var attracting: bool = false
var boosted: bool = false
var collected: bool = false
var speed: float = 0.0
var trail: Line2D
var trail_points: Array[Vector2] = []

func _ready() -> void:
	add_to_group("scrap_pickups")
	body_entered.connect(_on_body_entered)
	$Poly.visible = false
	var vfx := Node2D.new()
	vfx.set_script(preload("res://scripts/PickupVFX.gd"))
	vfx.kind = "scrap"
	add_child(vfx)
	trail = Line2D.new()
	trail.width = 2.0
	trail.default_color = Color(1.0, 0.78, 0.25, 0.25)
	trail.z_index = -1
	add_child(trail)

func start_attract(p: Node2D, boost: bool = false) -> void:
	target = p
	attracting = true
	boosted = boosted or boost
	if boost:
		trail.default_color = Color(1.0, 0.9, 0.5, 0.5)
		trail.width = 3.0

func collect() -> void:
	collect_now()

func collect_now() -> void:
	if collected:
		return
	collected = true
	VFX.pickup_collect(global_position, "scrap", clampf(float(amount) / 3.0, 0.8, 1.5))
	AudioManager.play("pickup_scrap", 1.0, -8.0)
	GameManager.add_scrap(amount)
	GameManager.update_mission("scrap", amount)
	queue_free()

func _physics_process(delta: float) -> void:
	if collected:
		return
	if attracting and is_instance_valid(target):
		var cap := 1100.0 if boosted else 600.0
		speed = minf(speed + (1500.0 if boosted else 700.0) * delta, cap)
		var dir: Vector2 = (target.global_position - global_position).normalized()
		global_position += dir * speed * delta
		trail_points.push_back(to_local(global_position))
		if trail_points.size() > 6:
			trail_points.pop_front()
		trail.points = PackedVector2Array(trail_points)
		if global_position.distance_to(target.global_position) < 24.0:
			collect_now()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		collect_now()
