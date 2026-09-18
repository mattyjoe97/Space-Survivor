extends Node2D
## Persistent radiation cloud (spawned by Radiation Field L5 / Nuclear Broadside).
var radius := 70.0
var dps := 4.0
var life := 2.5
var src := "radiation"
var _t := 0.0
var _tick := 0.0
var _blobs: Array = []

func _ready() -> void:
	for i in range(7):
		_blobs.append([Vector2.from_angle(randf() * TAU) * radius * randf_range(0.1, 0.55), randf_range(0.4, 0.8), randf() * TAU])

func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	_t += delta
	life -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.4
		for e in GameManager.get_enemies():
			if is_instance_valid(e) and e.has_method("take_damage") and e.global_position.distance_to(global_position) <= radius:
				var d := dps * 0.4
				GameManager.record_damage(src, d)
				e.take_damage(d)
				StatusHost.apply(e, "irradiated", 1.5, dps * 0.25, src)
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var a := clampf(life / 0.6, 0.0, 1.0) * clampf(_t / 0.3, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.35, 1.0, 0.3, 0.10 * a))
	for b in _blobs:
		var p: Vector2 = b[0] + Vector2(sin(_t * 1.3 + b[2]), cos(_t * 1.1 + b[2])) * 6.0
		draw_circle(p, radius * b[1] * 0.55, Color(0.45, 1.0, 0.35, 0.12 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.5, 1.0, 0.4, 0.35 * a), 1.5)
	for i in range(3):
		var ang := _t * 1.5 + i * TAU / 3.0
		draw_circle(Vector2.from_angle(ang) * radius * 0.7, 2.5, Color(0.7, 1.0, 0.5, 0.9 * a))
