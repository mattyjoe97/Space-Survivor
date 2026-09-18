extends Node2D
## The rail itself: white-hot core, blue sheath, receding tracer, then fade.
var reach := 900.0
var width := 6.0
var life := 0.5
var _max := 0.5
func _ready() -> void:
	z_index = 48
	_max = life
func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var f := clampf(life / _max, 0.0, 1.0)
	var g := clampf(life / (_max * 0.5), 0.0, 1.0)  # core holds longer
	var end := Vector2(reach, 0)
	draw_line(Vector2.ZERO, end, Color(0.45, 0.7, 1.0, 0.22 * f), width * 7.0)
	draw_line(Vector2.ZERO, end, Color(0.6, 0.82, 1.0, 0.7 * f), width * 2.6)
	draw_line(Vector2.ZERO, end, Color(1, 1, 1, 0.98 * g), width * 1.1)
	# Heat shimmer lines beside the rail
	for k in range(2):
		var off := (k * 2 - 1) * width * 2.2 * (1.0 + (1.0 - f) * 2.0)
		draw_line(Vector2(0, off), Vector2(reach, off), Color(0.7, 0.85, 1.0, 0.25 * f), 1.0)
	# Tracer sparkles along the rail
	for i in range(12):
		var x := fmod(float(i) / 12.0 + (1.0 - f) * 1.5, 1.0) * reach
		draw_circle(Vector2(x, 0), width * 0.8 * f, Color(1, 1, 1, 0.5 * f))
	# Muzzle bloom
	draw_circle(Vector2.ZERO, width * 4.0 * f, Color(0.8, 0.9, 1.0, 0.35 * f))
