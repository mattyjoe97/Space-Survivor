extends Node2D
var pulse := 0.0
func _process(delta: float) -> void:
	pulse += delta
	rotation = sin(pulse*0.8)*0.025
	queue_redraw()
func _draw() -> void:
	var c := Color(0.92,0.18,0.42)
	var c2 := Color(0.62,0.12,0.32)
	var core := Color(1.0,0.68,0.20)
	var g := 1.0 + sin(pulse*5.0)*0.08
	draw_circle(Vector2.ZERO, 62.0*g, Color(1,0.15,0.35,0.055))
	# command hull
	draw_colored_polygon(PackedVector2Array([Vector2(0,-46),Vector2(24,-28),Vector2(43,-5),Vector2(34,26),Vector2(15,39),Vector2(0,32),Vector2(-15,39),Vector2(-34,26),Vector2(-43,-5),Vector2(-24,-28)]),Color(0.20,0.09,0.15))
	draw_polyline(PackedVector2Array([Vector2(0,-46),Vector2(24,-28),Vector2(43,-5),Vector2(34,26),Vector2(15,39),Vector2(0,32),Vector2(-15,39),Vector2(-34,26),Vector2(-43,-5),Vector2(-24,-28),Vector2(0,-46)]),c,3.0)
	# armor plates
	draw_colored_polygon(PackedVector2Array([Vector2(0,-42),Vector2(15,-24),Vector2(9,-9),Vector2(0,-15),Vector2(-9,-9),Vector2(-15,-24)]),c2)
	draw_line(Vector2(0,-39),Vector2(0,28),Color(1,0.35,0.5,0.8),2.0)
	# reactor core
	draw_circle(Vector2.ZERO, 18.0, Color(1,0.25,0.4,0.16))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-15),Vector2(12,0),Vector2(0,15),Vector2(-12,0)]),core)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-8),Vector2(7,0),Vector2(0,8),Vector2(-7,0)]),Color(1,0.95,0.72))
	# weapon hardpoints
	for p in [Vector2(-31,-9),Vector2(31,-9),Vector2(-25,23),Vector2(25,23)]:
		draw_circle(p,6.0,Color(0.08,0.04,0.08))
		draw_circle(p,3.5,c)
	# four dorsal fins
	draw_colored_polygon(PackedVector2Array([Vector2(28,-20),Vector2(48,-35),Vector2(38,-7)]),c)
	draw_colored_polygon(PackedVector2Array([Vector2(-28,-20),Vector2(-48,-35),Vector2(-38,-7)]),c)
	draw_colored_polygon(PackedVector2Array([Vector2(22,25),Vector2(43,42),Vector2(27,39)]),c)
	draw_colored_polygon(PackedVector2Array([Vector2(-22,25),Vector2(-43,42),Vector2(-27,39)]),c)
