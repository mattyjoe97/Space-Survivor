extends Node2D
## Animated flame cone: layered tongues of fire with flicker, embers at the edge.
var reach := 160.0
var half_angle := 0.32
var active := false
var _t := 0.0
var _seeds: Array = []
func _ready() -> void:
	top_level = true
	for i in range(14):
		_seeds.append([randf(), randf(), randf() * TAU])
func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
func _draw() -> void:
	if not active:
		# Pilot light
		draw_circle(Vector2(22, 0), 3.0 + sin(_t * 20.0), Color(1.0, 0.6, 0.2, 0.8))
		return
	# Overlapping soft tongues instead of one solid wedge.
	var tongues := 9
	for i in range(tongues):
		var k := float(i) / float(tongues - 1) * 2.0 - 1.0
		var ang := k * half_angle * 0.9
		var flick := 1.0 + 0.22 * sin(_t * 19.0 + i * 2.3) + 0.1 * sin(_t * 37.0 + i * 5.1)
		var L := reach * (0.6 + 0.4 * (1.0 - absf(k))) * flick
		var d := Vector2.from_angle(ang)
		var p := Vector2(-d.y, d.x)
		var w := reach * 0.09
		var tip := d * L
		var mid := d * L * 0.55
		var outer := PackedVector2Array([Vector2(14, 0) + p * w * 0.35, mid + p * w, tip, mid - p * w, Vector2(14, 0) - p * w * 0.35])
		draw_colored_polygon(outer, Color(1.0, 0.3, 0.05, 0.22))
		var inner := PackedVector2Array([Vector2(16, 0) + p * w * 0.2, mid * 0.9 + p * w * 0.5, tip * 0.8, mid * 0.9 - p * w * 0.5, Vector2(16, 0) - p * w * 0.2])
		draw_colored_polygon(inner, Color(1.0, 0.62, 0.15, 0.35))
		var core := PackedVector2Array([Vector2(18, 0) + p * w * 0.1, mid * 0.7 + p * w * 0.22, tip * 0.5, mid * 0.7 - p * w * 0.22, Vector2(18, 0) - p * w * 0.1])
		draw_colored_polygon(core, Color(1.0, 0.92, 0.55, 0.5))
	# Heat haze ring at the muzzle
	draw_arc(Vector2(18, 0), 10.0 + sin(_t * 25.0) * 3.0, 0.0, TAU, 12, Color(1.0, 0.8, 0.4, 0.4), 1.0)
	# Embers
	for sd in _seeds:
		var k: float = fmod(float(sd[0]) + _t * (0.6 + float(sd[1]) * 0.6), 1.0)
		var ang: float = -half_angle + float(sd[1]) * half_angle * 2.0 + sin(_t * 3.0 + float(sd[2])) * 0.05
		var p := Vector2.from_angle(ang) * reach * (0.2 + k * 0.9)
		draw_circle(p, 2.5 * (1.0 - k) + 0.5, Color(1.0, 0.85, 0.4, 0.9 * (1.0 - k)))
	draw_circle(Vector2(16, 0), 6.0 + sin(_t * 30.0) * 2.0, Color(1, 1, 0.85, 0.9))
