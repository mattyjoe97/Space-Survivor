extends Node2D
## L4 Void Blades wake: a brief purple rift left where a blade cut, ticks once.
var weapon: WeaponBase = null
var damage := 3.0
var _t := 0.0
var _ticked := false
func _process(delta: float) -> void:
	_t += delta
	if not _ticked and _t > 0.18 and weapon:
		_ticked = true
		for e in weapon.in_radius(global_position, 26.0):
			weapon.hit(e, damage)
	if _t > 0.45:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var a := 1.0 - clampf(_t / 0.45, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 14.0 + _t * 30.0, 0.0, TAU, 16, Color(0.7, 0.35, 1.0, 0.7 * a), 2.0)
	for i in range(4):
		var ang := _t * 10.0 + i * PI * 0.5
		draw_line(Vector2.from_angle(ang) * 4.0, Vector2.from_angle(ang) * (12.0 + _t * 20.0), Color(0.9, 0.7, 1.0, 0.8 * a), 1.2)
