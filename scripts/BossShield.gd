extends Node2D
## Boss phase shield: absorbs everything for a few seconds while the boss changes phase.
var active := false
var _t := 0.0
var _left := 0.0
var _hits := 0.0
func raise(duration: float) -> void:
	active = true
	_left = duration
func absorb() -> void:
	_hits = 1.0
func _process(delta: float) -> void:
	_t += delta
	_hits = maxf(0.0, _hits - delta * 6.0)
	if active:
		_left -= delta
		if _left <= 0.0:
			active = false
			VFX.shatter_burst(global_position, 120.0)
	queue_redraw()
func _draw() -> void:
	if not active:
		return
	var r := 96.0 + sin(_t * 6.0) * 3.0
	draw_circle(Vector2.ZERO, r, Color(0.7, 0.4, 1.0, 0.10 + _hits * 0.15))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.9, 0.6, 1.0, 0.7 + _hits * 0.3), 3.0 + _hits * 2.0)
	for i in range(6):
		var a := _t * 2.0 + i * TAU / 6.0
		draw_arc(Vector2.ZERO, r + 8.0, a, a + 0.5, 6, Color(1, 0.9, 1, 0.8), 2.0)
