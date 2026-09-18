extends Node2D
## Charge telegraph: particles converge on the nose, a ring tightens.
var duration := 0.5
var _t := 0.0
func _ready() -> void:
	z_index = 8
	position = Vector2(0, -24)
func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var r := lerpf(46.0, 5.0, k)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.75, 0.9, 1.0, 0.4 + k * 0.5), 1.5 + k * 2.0)
	for i in range(8):
		var a := _t * 6.0 + i * TAU / 8.0
		var d := Vector2.from_angle(a)
		draw_line(d * r * 1.7, d * r * 0.7, Color(0.85, 0.95, 1.0, 0.5 + 0.5 * k), 2.0)
	draw_circle(Vector2.ZERO, 2.0 + k * 5.0, Color(1, 1, 1, 0.9))
	if k > 0.7:
		draw_circle(Vector2.ZERO, 14.0 * (k - 0.7) / 0.3, Color(0.8, 0.9, 1.0, 0.35))
