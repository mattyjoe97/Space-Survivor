extends Node2D
## Draws the orbiting void blades. Rotation is driven by VoidBlades.gd.
var blade_count := 2
var blade_len := 26.0
var orbit := 60.0
var lash := 0.0
var color := Color(0.65, 0.35, 1.0)
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, orbit, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.12 + lash * 0.2), 1.5)
	for i in range(blade_count):
		var a := float(i) * TAU / float(blade_count)
		var base := Vector2.from_angle(a) * orbit
		var d := Vector2.from_angle(a)
		var p := Vector2(-d.y, d.x)
		var L := blade_len * (1.0 + lash * 0.5)
		# Curved crescent blade, tangential to the orbit.
		var pts := PackedVector2Array([
			base - p * L * 0.9 + d * 4.0,
			base - p * L * 0.4 + d * 12.0,
			base + p * L * 0.55 + d * 9.0,
			base + p * L * 0.95 - d * 2.0,
			base + p * L * 0.5 - d * 8.0,
			base - p * L * 0.35 - d * 6.0,
		])
		draw_colored_polygon(pts, Color(color.r * 0.55, color.g * 0.4, color.b * 0.8, 0.95))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.9, 0.75, 1.0, 0.95), 1.6)
		# Hot edge and motion smear
		draw_line(pts[1], pts[3], Color(1, 1, 1, 0.75), 1.2)
		for k in range(3):
			var sa := -0.12 * (k + 1)
			var sb := Vector2.from_angle(a + sa) * orbit
			draw_circle(sb, 4.0 - k, Color(color.r, color.g, color.b, 0.25 - k * 0.07))
		draw_circle(base, 3.5, Color(1, 0.9, 1, 0.9))
