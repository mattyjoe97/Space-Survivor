extends Node2D

var phase := 0.0

func _ready() -> void:
	z_index = 3
	for n in ["../Body", "../Cabin", "../Engine"]:
		var node = get_node_or_null(n)
		if node:
			node.visible = false
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	rotation = sin(phase * 0.7) * 0.025
	queue_redraw()

func _draw() -> void:
	# Small roaming salvage hauler: asymmetric, chunky and readable at game distance.
	var glow := 0.55 + sin(phase * 3.0) * 0.12
	# engine glow
	draw_colored_polygon(PackedVector2Array([Vector2(-10,20),Vector2(-3,20),Vector2(-6,34),Vector2(-13,27)]), Color(0.25,0.9,1.0,0.45))
	draw_colored_polygon(PackedVector2Array([Vector2(3,20),Vector2(10,20),Vector2(13,27),Vector2(6,34)]), Color(0.25,0.9,1.0,0.45))
	# cargo hull
	draw_colored_polygon(PackedVector2Array([Vector2(-28,-7),Vector2(-18,-18),Vector2(14,-16),Vector2(27,-4),Vector2(23,17),Vector2(-20,20),Vector2(-30,9)]), Color(0.13,0.19,0.25,1.0))
	# armored plates
	draw_polyline(PackedVector2Array([Vector2(-28,-7),Vector2(-18,-18),Vector2(14,-16),Vector2(27,-4),Vector2(23,17),Vector2(-20,20),Vector2(-30,9),Vector2(-28,-7)]), Color(0.8,0.62,0.25,0.95), 2.0)
	draw_line(Vector2(-17,-13), Vector2(-12,15), Color(0.35,0.45,0.5,0.8), 2.0)
	draw_line(Vector2(8,-14), Vector2(11,14), Color(0.35,0.45,0.5,0.8), 2.0)
	# cockpit
	draw_colored_polygon(PackedVector2Array([Vector2(-7,-13),Vector2(9,-12),Vector2(14,-2),Vector2(-11,-2)]), Color(0.22,0.72,0.9,0.9))
	draw_polyline(PackedVector2Array([Vector2(-7,-13),Vector2(9,-12),Vector2(14,-2),Vector2(-11,-2),Vector2(-7,-13)]), Color(0.65,0.95,1,0.95), 1.5)
	# side cargo pods
	draw_rect(Rect2(-34,-2,8,13), Color(0.45,0.34,0.18,1))
	draw_rect(Rect2(26,-2,8,13), Color(0.45,0.34,0.18,1))
	# beacon / merchant light
	draw_circle(Vector2(0,-24), 5.0, Color(1.0,0.72,0.25,0.16))
	draw_circle(Vector2(0,-24), 2.3, Color(1.0,0.85,0.38,glow))
	# rotating salvage beacon ring
	draw_arc(Vector2(0,-24), 8.0 + sin(phase*2.0), phase, phase + 4.2, 18, Color(1.0,0.72,0.25,0.45), 1.2)
