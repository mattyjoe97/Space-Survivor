extends Node2D
## Dash forcefield. Visibility is driven ONLY by Player (dash_iframe_timer > 0 and invuln_timer > 0),
## so it reflects the real invulnerability window and never extends it.
## 3.19 look: two hex-facet layers rotating against each other, an inner distortion ring, a bright
## activation pulse in the first ~0.12 s, localized impact ripples, restrained glow.
var _t := 0.0
var _on_t := 0.0
var _was_visible := false
var _ripples: Array = []
func _ready() -> void:
	z_index = 9
func ripple() -> void:
	if _ripples.size() < 6:
		_ripples.append([randf() * TAU, 0.0])
	VFX.sparks(global_position, 3, Color(0.7, 0.95, 1.0), 100.0, 0.2)
func _process(delta: float) -> void:
	_t += delta
	if visible and not _was_visible:
		_on_t = 0.0
	_was_visible = visible
	if visible:
		_on_t += delta
	for r in _ripples: r[1] += delta
	_ripples = _ripples.filter(func(r): return r[1] < 0.3)
	queue_redraw()
func _hex(c: Vector2, r: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(6):
		pts.append(c + Vector2.from_angle(rot + k * TAU / 6.0) * r)
	pts.append(pts[0])
	return pts
func _draw() -> void:
	if not visible:
		return
	var pulse: float = clampf(1.0 - _on_t / 0.14, 0.0, 1.0)   # activation flash
	var r := 33.0 + sin(_t * 14.0) * 1.2 + pulse * 6.0
	var col := Color(0.45, 0.88, 1.0)
	# Soft shell (restrained), brighter at activation.
	draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.07 + pulse * 0.25))
	# Outer facet layer
	for i in range(14):
		var a := _t * 1.6 + i * TAU / 14.0
		var c := Vector2.from_angle(a) * (r - 5.0)
		var alpha := 0.16 + 0.14 * maxf(0.0, sin(_t * 7.0 + i * 0.9)) + pulse * 0.3
		draw_polyline(_hex(c, 5.0, a), Color(col.r, col.g, col.b, alpha), 1.0)
	# Inner facet layer, counter-rotating, smaller
	for i in range(10):
		var a2 := -_t * 2.3 + i * TAU / 10.0
		var c2 := Vector2.from_angle(a2) * (r - 13.0)
		draw_polyline(_hex(c2, 3.5, a2), Color(0.8, 0.95, 1.0, 0.10 + 0.08 * maxf(0.0, sin(_t * 9.0 + i))), 0.8)
	# Distortion ring: thin wobbling ellipse suggesting refraction
	var wob := PackedVector2Array()
	for k in range(41):
		var a3 := float(k) / 40.0 * TAU
		wob.append(Vector2.from_angle(a3) * (r - 2.0 + sin(a3 * 6.0 + _t * 10.0) * 1.4))
	draw_polyline(wob, Color(1, 1, 1, 0.35 + pulse * 0.4), 1.2)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 44, Color(col.r, col.g, col.b, 0.75 + pulse * 0.25), 1.6 + pulse * 2.0)
	# Rim highlight sweep (dimensionality)
	var sweep := _t * 3.0
	draw_arc(Vector2.ZERO, r - 1.0, sweep, sweep + 1.2, 12, Color(1, 1, 1, 0.55), 2.2)
	# Impact ripples
	for rp in _ripples:
		var k: float = rp[1] / 0.3
		var p := Vector2.from_angle(rp[0]) * r
		draw_arc(p, 5.0 + k * 14.0, 0.0, TAU, 14, Color(1, 1, 1, 0.85 * (1.0 - k)), 1.8 * (1.0 - k) + 0.4)
		draw_arc(Vector2.ZERO, r, rp[0] - 0.5 * (1.0 - k), rp[0] + 0.5 * (1.0 - k), 8, Color(1, 1, 1, 0.9 * (1.0 - k)), 3.0)
