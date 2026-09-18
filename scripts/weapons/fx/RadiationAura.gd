extends Node2D
## Green toxic field around the ship: drifting particles + rotating trefoil hint.
var radius := 110.0
var intensity := 0.4
var _t := 0.0
var _motes: Array = []
func _ready() -> void:
	top_level = true
	for i in range(18):
		_motes.append([randf() * TAU, randf_range(0.2, 1.0), randf_range(0.5, 1.5)])
func _process(delta: float) -> void:
	_t += delta
	var p := get_parent()
	if p and p.get("player") != null and is_instance_valid(p.player):
		global_position = p.player.global_position
	queue_redraw()
func _draw() -> void:
	var a := 0.025 + intensity * 0.03
	draw_circle(Vector2.ZERO, radius, Color(0.35, 1.0, 0.3, a))
	draw_circle(Vector2.ZERO, radius * 0.6, Color(0.45, 1.0, 0.35, a * 0.5))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.5, 1.0, 0.4, 0.35 + 0.15 * sin(_t * 3.0)), 1.5)
	draw_arc(Vector2.ZERO, radius * (0.6 + 0.4 * fmod(_t * 0.5, 1.0)), 0.0, TAU, 40, Color(0.6, 1.0, 0.45, 0.25 * (1.0 - fmod(_t * 0.5, 1.0))), 2.0)
	for i in range(3):
		var a0 := _t * 0.8 + i * TAU / 3.0
		draw_arc(Vector2.ZERO, radius * 0.82, a0, a0 + 0.7, 10, Color(0.6, 1.0, 0.45, 0.35), 3.0)
	for m in _motes:
		var ang: float = m[0] + _t * 0.4 * m[2]
		var r: float = radius * (m[1] + 0.08 * sin(_t * 2.0 + m[0]))
		draw_circle(Vector2.from_angle(ang) * r, 1.8 + intensity, Color(0.7, 1.0, 0.5, 0.75))
