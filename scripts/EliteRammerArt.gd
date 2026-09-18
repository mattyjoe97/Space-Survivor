extends Node2D
var pulse := 0.0
func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()
func _draw() -> void:
	var glow := 1.0 + sin(pulse*8.0)*0.12
	var c := Color(1.0,0.40,0.12)
	draw_circle(Vector2.ZERO, 28.0*glow, Color(1.0,0.35,0.08,0.07))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-30),Vector2(18,-6),Vector2(22,12),Vector2(8,21),Vector2(0,16),Vector2(-8,21),Vector2(-22,12),Vector2(-18,-6)]),Color(0.28,0.16,0.12))
	draw_polyline(PackedVector2Array([Vector2(0,-30),Vector2(18,-6),Vector2(22,12),Vector2(8,21),Vector2(0,16),Vector2(-8,21),Vector2(-22,12),Vector2(-18,-6),Vector2(0,-30)]),c,2.2)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-31),Vector2(8,-11),Vector2(0,-4),Vector2(-8,-11)]),Color(1.0,0.72,0.28))
	draw_line(Vector2(0,-8),Vector2(0,15),Color(1,0.9,0.45),2.0)
	draw_circle(Vector2(-9,16),4.0,Color(1,0.25,0.08,0.9))
	draw_circle(Vector2(9,16),4.0,Color(1,0.25,0.08,0.9))
