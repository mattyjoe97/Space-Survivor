extends Node2D
var radius := 165.0
var _t := 0.0
func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.55, 0.85, 1.0, 0.12), 1.0)
	for i in range(4):
		var p := Vector2.from_angle(i * TAU / 4.0) * radius
		draw_circle(p, 12.0, Color(0.1, 0.14, 0.22))
		draw_arc(p, 12.0, 0.0, TAU, 16, Color(0.6, 0.9, 1.0, 0.9), 2.0)
		draw_circle(p, 5.0 + sin(_t * 14.0 + i) * 1.5, Color(0.9, 0.98, 1.0, 0.95))
		for k in range(3):
			var a := _t * 8.0 + k * TAU / 3.0 + i
			draw_line(p, p + Vector2.from_angle(a) * (14.0 + randf() * 5.0), Color(0.8, 0.95, 1.0, 0.6), 1.0)
