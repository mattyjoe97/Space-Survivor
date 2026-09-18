extends Node2D

## In-game player ship art.
## Each hangar ship now has its own hull silhouette (matching the hangar preview),
## animated engine flames that respond to throttle, subtle banking when turning,
## damage smoke/sparks at low hull, and a shield shimmer while invulnerable.

var pulse := 0.0
var _last_rot := 0.0
var _bank := 0.0
var _throttle := 0.0
var _flicker := 1.0
var _flicker_timer := 0.0

const PALETTE := {
	"viper": {"accent": Color(0.25, 0.85, 1.0), "core": Color(0.65, 0.95, 1.0), "hull": Color(0.16, 0.24, 0.34), "panel": Color(0.28, 0.42, 0.55), "flame": Color(0.3, 0.85, 1.0)},
	"bulwark": {"accent": Color(1.0, 0.58, 0.18), "core": Color(1.0, 0.88, 0.55), "hull": Color(0.30, 0.25, 0.20), "panel": Color(0.55, 0.43, 0.28), "flame": Color(1.0, 0.5, 0.18)},
	"nova": {"accent": Color(1.0, 0.35, 0.82), "core": Color(1.0, 0.72, 0.95), "hull": Color(0.28, 0.18, 0.30), "panel": Color(0.55, 0.30, 0.50), "flame": Color(0.95, 0.35, 1.0)},
	"voidrunner": {"accent": Color(0.65, 0.45, 1.0), "core": Color(0.86, 0.75, 1.0), "hull": Color(0.20, 0.16, 0.30), "panel": Color(0.42, 0.30, 0.60), "flame": Color(0.2, 1.0, 0.85)},
	"destroyer": {"accent": Color(1.0, 0.28, 0.18), "core": Color(1.0, 0.72, 0.45), "hull": Color(0.28, 0.20, 0.18), "panel": Color(0.56, 0.34, 0.28), "flame": Color(1.0, 0.25, 0.15)},
	"aegis": {"accent": Color(0.35, 0.72, 1.0), "core": Color(0.75, 0.95, 1.0), "hull": Color(0.18, 0.25, 0.36), "panel": Color(0.34, 0.52, 0.68), "flame": Color(1.0, 0.5, 0.2)},
	"tempest": {"accent": Color(0.35, 0.55, 1.0), "core": Color(0.72, 0.88, 1.0), "hull": Color(0.16, 0.20, 0.34), "panel": Color(0.28, 0.40, 0.68), "flame": Color(0.3, 0.7, 1.0)},
	"dreadnought": {"accent": Color(0.92, 0.34, 0.28), "core": Color(1.0, 0.70, 0.48), "hull": Color(0.24, 0.17, 0.16), "panel": Color(0.52, 0.31, 0.27), "flame": Color(1.0, 0.3, 0.15)},
	"singularity": {"accent": Color(0.66, 0.34, 1.0), "core": Color(0.86, 0.78, 1.0), "hull": Color(0.19, 0.14, 0.30), "panel": Color(0.40, 0.28, 0.58), "flame": Color(0.6, 0.25, 1.0)},
}

func _ready() -> void:
	var p := get_parent()
	_last_rot = p.rotation if p is Node2D else 0.0

func _process(delta: float) -> void:
	pulse += delta
	var parent := get_parent()
	if parent is Node2D:
		var rot: float = parent.rotation
		var dr := wrapf(rot - _last_rot, -PI, PI)
		_last_rot = rot
		_bank = lerpf(_bank, clampf(dr * 6.0, -0.55, 0.55), 0.18)
		var vel_v = parent.get("velocity")
		var vel: Vector2 = vel_v if vel_v != null else Vector2.ZERO
		var spd_v = parent.get("speed")
		var spd: float = float(spd_v) if spd_v != null else 220.0
		_throttle = lerpf(_throttle, clampf(vel.length() / maxf(spd, 1.0), 0.0, 1.6), 0.12)
	# Skew the hull a little to fake banking into turns.
	skew = _bank * 0.35
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = 0.03
		_flicker = randf_range(0.82, 1.18)
	queue_redraw()

func _pal(key: String) -> Color:
	var id: String = GameManager.selected_character
	var p: Dictionary = PALETTE.get(id, PALETTE["viper"])
	return p[key]

func _draw() -> void:
	var accent := _pal("accent")
	var hull := _pal("hull")
	var panel := _pal("panel")
	var core := _pal("core")
	var flame := _pal("flame")
	var id: String = GameManager.selected_character

	var parent := get_parent()
	var hp_ratio := 1.0
	var invuln := 0.0
	if parent:
		var cur = parent.get("current_hp")
		var mx = parent.get("max_hp")
		if cur != null and mx != null and float(mx) > 0.0:
			hp_ratio = clampf(float(cur) / float(mx), 0.0, 1.0)
		var inv = parent.get("invuln_timer")
		if inv != null:
			invuln = float(inv)

	# Engine flames first (behind hull).
	var engines: Array = _engine_spots(id)
	for sp in engines:
		_draw_flame(sp[0], sp[1], flame, core)

	match id:
		"bulwark": _hull_bulwark(hull, panel, accent)
		"nova": _hull_nova(hull, panel, accent)
		"voidrunner": _hull_voidrunner(hull, panel, accent)
		"destroyer": _hull_destroyer(hull, panel, accent)
		"aegis": _hull_aegis(hull, panel, accent)
		"tempest": _hull_tempest(hull, panel, accent)
		"dreadnought": _hull_dreadnought(hull, panel, accent)
		"singularity": _hull_singularity(hull, panel, accent)
		_: _hull_viper(hull, panel, accent)

	# Cockpit canopy with a moving specular highlight.
	var canopy := PackedVector2Array([Vector2(0, -18), Vector2(6, -7), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0), Vector2(-6, -7)])
	draw_colored_polygon(canopy, Color(core.r, core.g, core.b, 0.88))
	var hl := 0.5 + 0.5 * sin(pulse * 1.7)
	draw_line(Vector2(-2.5, -13 + hl * 4.0), Vector2(2.0, -8 + hl * 4.0), Color(1, 1, 1, 0.45), 1.4)
	draw_polyline(canopy + PackedVector2Array([canopy[0]]), Color(1, 1, 1, 0.42), 1.0)

	# Running lights blink.
	var blink := 1.0 if fmod(pulse, 1.4) < 0.12 else 0.25
	draw_circle(Vector2(-22, 9), 1.6, Color(1.0, 0.3, 0.3, blink))
	draw_circle(Vector2(22, 9), 1.6, Color(0.35, 1.0, 0.45, blink))

	# Damage state: sparks and smoke wisps when hull is low.
	if hp_ratio < 0.45:
		var sev := (0.45 - hp_ratio) / 0.45
		if randf() < 0.18 * sev:
			var sp := Vector2(randf_range(-10, 10), randf_range(-12, 10))
			draw_circle(sp, randf_range(1.0, 2.6), Color(1.0, 0.85, 0.4, 0.9))
		for i in range(3):
			var ph := pulse * 1.5 + i * 2.1
			var off := Vector2(sin(ph) * 5.0 + (i - 1) * 6.0, 6.0 + fmod(ph, 2.0) * 9.0)
			var a := (1.0 - fmod(ph, 2.0) / 2.0) * 0.28 * sev
			draw_circle(off, 3.0 + fmod(ph, 2.0) * 3.0, Color(0.4, 0.4, 0.45, a))

	# Shield shimmer while invulnerable (dash / post-hit).
	if invuln > 0.0:
		var ph2 := pulse * 9.0
		draw_arc(Vector2.ZERO, 30.0 + sin(ph2) * 1.5, ph2, ph2 + 2.6, 22, Color(accent.r, accent.g, accent.b, 0.55), 2.0)
		draw_arc(Vector2.ZERO, 30.0 + sin(ph2) * 1.5, ph2 + PI, ph2 + PI + 2.6, 22, Color(1, 1, 1, 0.35), 1.4)
		draw_circle(Vector2.ZERO, 30.0, Color(accent.r, accent.g, accent.b, 0.06))

# ---------------------------------------------------------------------------

func _engine_spots(id: String) -> Array:
	match id:
		"bulwark": return [[Vector2(-9, 18), 1.0], [Vector2(9, 18), 1.0]]
		"nova": return [[Vector2(0, 21), 1.15]]
		"voidrunner": return [[Vector2(-7, 18), 0.85], [Vector2(7, 18), 0.85]]
		"destroyer": return [[Vector2(-10, 20), 1.05], [Vector2(10, 20), 1.05]]
		"aegis": return [[Vector2(-10, 19), 0.9], [Vector2(10, 19), 0.9]]
		"tempest": return [[Vector2(-7, 19), 0.8], [Vector2(7, 19), 0.8]]
		"dreadnought": return [[Vector2(-13, 22), 1.1], [Vector2(13, 22), 1.1]]
		"singularity": return [[Vector2(-6, 20), 0.85], [Vector2(6, 20), 0.85]]
		_: return [[Vector2(-7, 17), 0.85], [Vector2(7, 17), 0.85]]

func _draw_flame(at: Vector2, size: float, flame: Color, core: Color) -> void:
	var len := (7.0 + _throttle * 16.0) * size * _flicker
	var w := (3.4 + _throttle * 1.2) * size
	var glow_r := (6.0 + _throttle * 5.0) * size
	draw_circle(at, glow_r, Color(flame.r, flame.g, flame.b, 0.16))
	# Outer flame
	draw_colored_polygon(PackedVector2Array([at + Vector2(-w, 0), at + Vector2(w, 0), at + Vector2(0, len)]), Color(flame.r, flame.g, flame.b, 0.75))
	# Inner hot core
	draw_colored_polygon(PackedVector2Array([at + Vector2(-w * 0.45, 0), at + Vector2(w * 0.45, 0), at + Vector2(0, len * 0.55)]), Color(1.0, 1.0, 0.92, 0.95))
	draw_circle(at, w * 0.7, core)

func _outline(pts: PackedVector2Array, col: Color, w: float = 1.6) -> void:
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, w)

func _hardpoints(xs: Array, y: float, accent: Color) -> void:
	for x in xs:
		draw_circle(Vector2(x, y), 3.5, Color(0.05, 0.08, 0.12, 1))
		draw_circle(Vector2(x, y), 2.0, accent)

# ---------------------------------------------------------------------------
# Hull designs. All fit roughly within a 62px wide / 54px tall box, nose at -y.

func _hull_viper(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-5, -1), Vector2(-30, 8), Vector2(-24, 16), Vector2(-7, 10), Vector2(-10, 5)])
	var wr := PackedVector2Array([Vector2(5, -1), Vector2(30, 8), Vector2(24, 16), Vector2(7, 10), Vector2(10, 5)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.3); _outline(wr, accent, 1.3)
	var body := PackedVector2Array([Vector2(0, -29), Vector2(11, -4), Vector2(8, 13), Vector2(0, 19), Vector2(-8, 13), Vector2(-11, -4)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(5, -10), Vector2(0, -5), Vector2(-5, -10)]), panel)
	draw_line(Vector2(0, -23), Vector2(0, 12), Color(accent.r, accent.g, accent.b, 0.7), 1.2)
	_hardpoints([-21.0, 21.0], 8.0, accent)

func _hull_bulwark(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-19, -2), Vector2(-32, 10), Vector2(-25, 19), Vector2(-7, 10)])
	var wr := PackedVector2Array([Vector2(19, -2), Vector2(32, 10), Vector2(25, 19), Vector2(7, 10)])
	draw_colored_polygon(wl, hull.darkened(0.1)); draw_colored_polygon(wr, hull.darkened(0.1))
	_outline(wl, accent, 1.3); _outline(wr, accent, 1.3)
	var body := PackedVector2Array([Vector2(-13, -18), Vector2(13, -18), Vector2(19, 5), Vector2(12, 18), Vector2(-12, 18), Vector2(-19, 5)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -16), Vector2(11, -16), Vector2(9, -6), Vector2(-9, -6)]), panel)
	draw_line(Vector2(-12, 6), Vector2(12, 6), Color(1, 0.9, 0.65, 0.4), 3.0)
	for y in [-2.0, 10.0]:
		draw_line(Vector2(-15, y), Vector2(15, y), Color(accent.r, accent.g, accent.b, 0.35), 1.0)
	_hardpoints([-16.0, 16.0], -8.0, accent)

func _hull_nova(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-5, 0), Vector2(-30, 3), Vector2(-13, 10), Vector2(-2, 8)])
	var wr := PackedVector2Array([Vector2(5, 0), Vector2(30, 3), Vector2(13, 10), Vector2(2, 8)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.2); _outline(wr, accent, 1.2)
	var body := PackedVector2Array([Vector2(0, -30), Vector2(8, 8), Vector2(0, 21), Vector2(-8, 8)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(4, -12), Vector2(0, -6), Vector2(-4, -12)]), panel)
	var ph := pulse * 2.0
	draw_arc(Vector2(0, -1), 20.0, ph, ph + 3.8, 20, Color(1, 0.6, 0.95, 0.45), 1.6)
	_hardpoints([-17.0, 17.0], 5.0, accent)

func _hull_voidrunner(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-3, 0), Vector2(-28, 11), Vector2(-15, 16), Vector2(-2, 9)])
	var wr := PackedVector2Array([Vector2(3, 0), Vector2(28, 11), Vector2(15, 16), Vector2(2, 9)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.2); _outline(wr, accent, 1.2)
	var body := PackedVector2Array([Vector2(0, -29), Vector2(8, -1), Vector2(4, 19), Vector2(0, 12), Vector2(-4, 19), Vector2(-8, -1)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 1.8)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(4, -12), Vector2(0, -7), Vector2(-4, -12)]), panel)
	var ph := pulse * 3.0
	draw_arc(Vector2.ZERO, 34.0, ph, ph + 1.6, 16, Color(0.2, 1.0, 0.9, 0.35), 1.6)
	draw_arc(Vector2.ZERO, 34.0, ph + PI, ph + PI + 1.6, 16, Color(0.2, 1.0, 0.9, 0.35), 1.6)
	_hardpoints([-19.0, 19.0], 10.0, accent)

func _hull_destroyer(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-15, -3), Vector2(-36, 8), Vector2(-27, 19), Vector2(-8, 11)])
	var wr := PackedVector2Array([Vector2(15, -3), Vector2(36, 8), Vector2(27, 19), Vector2(8, 11)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.3); _outline(wr, accent, 1.3)
	var body := PackedVector2Array([Vector2(0, -24), Vector2(15, -2), Vector2(13, 19), Vector2(-13, 19), Vector2(-15, -2)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -24), Vector2(6, -8), Vector2(0, -3), Vector2(-6, -8)]), panel)
	for x in [-17.0, 17.0]:
		draw_rect(Rect2(Vector2(x - 2.5, -14), Vector2(5, 20)), Color(0.06, 0.07, 0.1, 1))
		draw_rect(Rect2(Vector2(x - 1.0, -14), Vector2(2, 20)), Color(accent.r, accent.g, accent.b, 0.55))
	_hardpoints([-27.0, 27.0], 11.0, accent)

func _hull_aegis(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-27, 0), Vector2(-36, 10), Vector2(-25, 17), Vector2(-5, 10)])
	var wr := PackedVector2Array([Vector2(27, 0), Vector2(36, 10), Vector2(25, 17), Vector2(5, 10)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.3); _outline(wr, accent, 1.3)
	var body := PackedVector2Array([Vector2(0, -22), Vector2(12, -1), Vector2(12, 16), Vector2(0, 20), Vector2(-12, 16), Vector2(-12, -1)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(5, -8), Vector2(0, -3), Vector2(-5, -8)]), panel)
	var ph := 0.5 + 0.5 * sin(pulse * 2.4)
	draw_arc(Vector2.ZERO, 23.0, -1.0, 4.15, 26, Color(0.5, 0.9, 1, 0.3 + ph * 0.2), 2.0)
	_hardpoints([-21.0, 21.0], 5.0, accent)

func _hull_tempest(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-2, 1), Vector2(-33, 7), Vector2(-18, 12), Vector2(-3, 8)])
	var wr := PackedVector2Array([Vector2(2, 1), Vector2(33, 7), Vector2(18, 12), Vector2(3, 8)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.2); _outline(wr, accent, 1.2)
	var body := PackedVector2Array([Vector2(0, -30), Vector2(6, -2), Vector2(4, 19), Vector2(0, 15), Vector2(-4, 19), Vector2(-6, -2)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 1.8)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(3, -12), Vector2(0, -8), Vector2(-3, -12)]), panel)
	for sgn in [-1.0, 1.0]:
		var tip := Vector2(sgn * 31.0, 7.0)
		var jit := sin(pulse * 27.0 + sgn) * 2.0
		draw_line(tip, tip + Vector2(sgn * 4.0, -5.0 + jit), Color(0.55, 0.8, 1.0, 0.7), 1.0)
		draw_circle(tip, 2.0, Color(0.7, 0.9, 1.0, 0.85))
	_hardpoints([-14.0, 14.0], 6.0, accent)

func _hull_dreadnought(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-20, -2), Vector2(-38, 9), Vector2(-30, 21), Vector2(-11, 12)])
	var wr := PackedVector2Array([Vector2(20, -2), Vector2(38, 9), Vector2(30, 21), Vector2(11, 12)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.3); _outline(wr, accent, 1.3)
	var body := PackedVector2Array([Vector2(0, -20), Vector2(17, -3), Vector2(18, 18), Vector2(0, 23), Vector2(-18, 18), Vector2(-17, -3)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 2.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -14), Vector2(8, -14), Vector2(6, -4), Vector2(-6, -4)]), panel)
	for x in [-19.0, 0.0, 19.0]:
		draw_circle(Vector2(x, 12), 3.2, Color(0.05, 0.07, 0.1, 1))
		draw_circle(Vector2(x, 12), 1.6, Color(1.0, 0.7, 0.4, 0.9))
	_hardpoints([-30.0, 30.0], 14.0, accent)

func _hull_singularity(hull: Color, panel: Color, accent: Color) -> void:
	var wl := PackedVector2Array([Vector2(-18, 3), Vector2(-32, 12), Vector2(-22, 19), Vector2(-5, 12)])
	var wr := PackedVector2Array([Vector2(18, 3), Vector2(32, 12), Vector2(22, 19), Vector2(5, 12)])
	draw_colored_polygon(wl, hull); draw_colored_polygon(wr, hull)
	_outline(wl, accent, 1.2); _outline(wr, accent, 1.2)
	var body := PackedVector2Array([Vector2(0, -23), Vector2(10, 3), Vector2(5, 18), Vector2(0, 23), Vector2(-5, 18), Vector2(-10, 3)])
	draw_colored_polygon(body, hull)
	_outline(body, accent, 1.8)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -23), Vector2(4, -9), Vector2(0, -4), Vector2(-4, -9)]), panel)
	var r := 8.0 + sin(pulse * 3.0) * 1.2
	draw_circle(Vector2(0, 5), r, Color(0.08, 0.03, 0.14, 0.95))
	var ph := pulse * 1.4
	draw_arc(Vector2(0, 5), r + 4.0, ph, ph + 4.5, 26, Color(0.75, 0.45, 1, 0.65), 1.6)
	draw_circle(Vector2(0, 5), 2.0, Color(0.9, 0.8, 1.0, 0.95))
	_hardpoints([-21.0, 21.0], 12.0, accent)
