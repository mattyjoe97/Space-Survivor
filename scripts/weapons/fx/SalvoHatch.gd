extends Node2D
## Dreadnought Salvo launcher racks on the hull that open while a salvo is firing.
var open := 0.0
var _t := 0.0
func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
func _draw() -> void:
	for sgn: float in [-1.0, 1.0]:
		var base := Vector2(sgn * 16.0, 6.0)
		draw_rect(Rect2(base + Vector2(-6, -8), Vector2(12, 16)), Color(0.12, 0.14, 0.2))
		draw_rect(Rect2(base + Vector2(-6, -8), Vector2(12, 16)), Color(1.0, 0.62, 0.3, 0.7), false, 1.0)
		for i in range(3):
			var y := -5.0 + i * 5.0
			draw_circle(base + Vector2(0, y), 1.6, Color(1.0, 0.7, 0.35, 0.5 + open * 0.5))
		if open > 0.0:
			draw_rect(Rect2(base + Vector2(-6 - sgn * 8.0 * open, -8), Vector2(6, 16)), Color(0.2, 0.22, 0.3, open))
			draw_circle(base, 6.0 * open, Color(1.0, 0.75, 0.4, 0.4 * open))
