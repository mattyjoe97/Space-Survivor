extends Node2D
var pulse := 0.0
func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()
func _draw() -> void:
	var glow := 1.0 + sin(pulse*6.0)*0.08
	var c := Color(0.88,0.26,0.72)
	draw_circle(Vector2.ZERO, 27.0*glow, Color(0.9,0.25,0.75,0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-24),Vector2(14,-14),Vector2(24,2),Vector2(14,18),Vector2(0,14),Vector2(-14,18),Vector2(-24,2),Vector2(-14,-14)]),Color(0.25,0.10,0.25))
	draw_polyline(PackedVector2Array([Vector2(0,-24),Vector2(14,-14),Vector2(24,2),Vector2(14,18),Vector2(0,14),Vector2(-14,18),Vector2(-24,2),Vector2(-14,-14),Vector2(0,-24)]),c,2.0)
	# dorsal cannon
	draw_colored_polygon(PackedVector2Array([Vector2(-6,-9),Vector2(6,-9),Vector2(5,-27),Vector2(-5,-27)]),Color(0.50,0.18,0.48))
	draw_line(Vector2(0,-25),Vector2(0,-10),Color(1,0.72,0.94),3.0)
	draw_circle(Vector2(0,3),5.0,Color(1,0.72,0.94))
	draw_circle(Vector2(0,3),2.0,Color.WHITE)
	for x in [-17.0,17.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,2),Vector2(x*1.55,9),Vector2(x*1.15,13)]),c)
