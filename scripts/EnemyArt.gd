extends Node2D

## Enemy art with more personality per variant:
## - the eye/sensor tracks the player
## - hit flash (set `flash = 1.0` from Enemy.take_damage)
## - freeze build-up shows as ice crystals, full freeze tints the body
## - each variant has its own body, mandibles/spines/fins and idle animation

@export var variant: String = "chaser"
var pulse := 0.0
var flash := 0.0
var _seed_offset := 0.0

const STYLES := {
	"chaser": {"c": Color(1.0, 0.24, 0.38), "dark": Color(0.25, 0.06, 0.10), "eye": Color(1.0, 0.86, 0.30)},
	"swarmer": {"c": Color(1.0, 0.42, 0.12), "dark": Color(0.3, 0.08, 0.02), "eye": Color(1.0, 0.95, 0.45)},
	"armored": {"c": Color(0.72, 0.56, 0.28), "dark": Color(0.18, 0.16, 0.12), "eye": Color(0.8, 1.0, 0.95)},
	"leecher": {"c": Color(0.25, 0.95, 0.55), "dark": Color(0.04, 0.22, 0.12), "eye": Color(1.0, 0.35, 0.45)},
	"teleporter": {"c": Color(0.68, 0.35, 1.0), "dark": Color(0.14, 0.05, 0.28), "eye": Color(0.9, 0.8, 1.0)},
	"sniper": {"c": Color(0.35, 0.8, 1.0), "dark": Color(0.04, 0.12, 0.22), "eye": Color(1.0, 0.35, 0.65)},
	"splitter": {"c": Color(1.0, 0.3, 0.7), "dark": Color(0.28, 0.04, 0.16), "eye": Color(0.6, 1.0, 1.0)},
	"void_spitter": {"c": Color(0.92, 0.30, 0.72), "dark": Color(0.24, 0.07, 0.20), "eye": Color(1.0, 0.72, 0.95)},
}

func _ready() -> void:
	_seed_offset = randf() * 10.0
	pulse = _seed_offset

func _process(delta: float) -> void:
	pulse += delta
	flash = maxf(0.0, flash - delta * 9.0)
	queue_redraw()

func _closed(p: PackedVector2Array) -> PackedVector2Array:
	return p + PackedVector2Array([p[0]])

func _draw() -> void:
	var st: Dictionary = STYLES.get(variant, STYLES["chaser"])
	var c: Color = st["c"]
	var dark: Color = st["dark"]
	var eye: Color = st["eye"]

	var parent := get_parent()
	var freeze := 0.0
	var frozen := false
	if parent:
		var fp = parent.get("freeze_progress")
		if fp != null:
			freeze = clampf(float(fp), 0.0, 1.0)
		var ft = parent.get("frozen_timer")
		if ft != null and float(ft) > 0.0:
			frozen = true
	if frozen:
		c = c.lerp(Color(0.6, 0.9, 1.0), 0.65)
		dark = dark.lerp(Color(0.2, 0.4, 0.6), 0.5)

	# Eye tracks the player.
	var look := Vector2.ZERO
	if is_instance_valid(GameManager.player):
		var to_p: Vector2 = (GameManager.player.global_position - global_position)
		look = to_p.normalized().rotated(-global_rotation) * 1.8

	var breathe := 1.0 + sin(pulse * 5.0) * 0.03
	draw_circle(Vector2.ZERO, 22.0 * breathe, Color(c.r, c.g, c.b, 0.07))

	match variant:
		"armored": _draw_armored(c, dark, eye, look)
		"sniper": _draw_sniper(c, dark, eye, look)
		"teleporter": _draw_teleporter(c, dark, eye, look)
		"void_spitter": _draw_spitter(c, dark, eye, look)
		_: _draw_bug(c, dark, eye, look)

	# Freeze build-up crystals.
	if freeze > 0.08 and not frozen:
		var n := int(round(freeze * 6.0))
		for i in range(n):
			var a := _seed_offset + i * 1.05
			var p := Vector2.from_angle(a) * 12.0
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3, 0), p + Vector2(0, 4), p + Vector2(-3, 0)]), Color(0.75, 0.95, 1.0, 0.85))
	if frozen:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(0.8, 0.97, 1.0, 0.55), 1.5)
		for i in range(6):
			var d := Vector2.from_angle(i * TAU / 6.0 + _seed_offset)
			draw_line(d * 10.0, d * 22.0, Color(0.85, 1.0, 1.0, 0.6), 1.2)

	# Hit flash overlay.
	if flash > 0.0:
		draw_circle(Vector2.ZERO, 19.0, Color(1, 1, 1, 0.7 * flash))

# ---------------------------------------------------------------------------

func _eye(at: Vector2, eye: Color, look: Vector2, r: float = 3.4) -> void:
	draw_circle(at, r + 1.2, Color(0.05, 0.03, 0.05, 0.9))
	draw_circle(at, r, eye)
	draw_circle(at + look * 0.6, r * 0.42, Color.WHITE)

func _draw_bug(c: Color, dark: Color, eye: Color, look: Vector2) -> void:
	var wig := sin(pulse * 9.0) * 1.5
	var pts := PackedVector2Array([Vector2(0, -18), Vector2(10, -8), Vector2(16, 2), Vector2(9, 13), Vector2(0, 9), Vector2(-9, 13), Vector2(-16, 2), Vector2(-10, -8)])
	# Engine glow behind the body.
	draw_circle(Vector2(0, 12), 5.0 + sin(pulse * 12.0) * 1.0, Color(c.r, c.g, c.b, 0.35))
	match variant:
		"swarmer":
			draw_line(Vector2(-14, -8), Vector2(-23, -15 + wig), c.lightened(0.25), 2.0)
			draw_line(Vector2(14, -8), Vector2(23, -15 - wig), c.lightened(0.25), 2.0)
			draw_circle(Vector2(-23, -15 + wig), 1.8, eye)
			draw_circle(Vector2(23, -15 - wig), 1.8, eye)
		"leecher":
			for a in [-0.8, 0.0, 0.8]:
				var d := Vector2.from_angle(a - PI * 0.5)
				var tip := d * (23.0 + sin(pulse * 6.0 + a * 3.0) * 2.0)
				draw_line(d * 8.0, tip, c.lightened(0.2), 2.2)
				draw_circle(tip, 2.2, Color(1.0, 0.45, 0.5, 0.9))
		"splitter":
			draw_line(Vector2(-12, 8), Vector2(-20 + wig, 15), c.lightened(0.2), 2.0)
			draw_line(Vector2(12, 8), Vector2(20 - wig, 15), c.lightened(0.2), 2.0)
			# Seam that hints it splits.
			draw_line(Vector2(0, -14), Vector2(0, 7), Color(0.6, 1.0, 1.0, 0.45 + 0.3 * abs(sin(pulse * 4.0))), 1.6)
	draw_colored_polygon(pts, c)
	draw_polyline(_closed(pts), Color(1, 0.75, 0.82, 0.75), 1.4)
	# Segmented plates
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -3), Vector2(7, -3), Vector2(5, 7), Vector2(-5, 7)]), dark)
	draw_line(Vector2(-6, 1), Vector2(6, 1), Color(c.r, c.g, c.b, 0.5), 1.0)
	# Mandibles snapping.
	var snap := 0.5 + 0.5 * sin(pulse * 7.0)
	draw_line(Vector2(-4, -15), Vector2(-7 - snap * 2.0, -22), c.lightened(0.15), 1.6)
	draw_line(Vector2(4, -15), Vector2(7 + snap * 2.0, -22), c.lightened(0.15), 1.6)
	_eye(Vector2(0, -6), eye, look)

func _draw_armored(c: Color, dark: Color, eye: Color, look: Vector2) -> void:
	var spin := pulse * 0.8
	draw_circle(Vector2.ZERO, 17.0, c)
	# Rotating armor plates.
	for i in range(6):
		var a0 := spin + i * TAU / 6.0
		var plate := PackedVector2Array()
		for j in range(5):
			plate.append(Vector2.from_angle(a0 + j / 4.0 * 0.85) * 19.0)
		for j in range(5):
			plate.append(Vector2.from_angle(a0 + (4 - j) / 4.0 * 0.85) * 14.0)
		draw_colored_polygon(plate, c.darkened(0.25) if i % 2 == 0 else c.lightened(0.1))
	draw_circle(Vector2.ZERO, 12.0, dark)
	draw_arc(Vector2.ZERO, 18.5, 0.0, TAU, 32, Color(1, 0.85, 0.45, 0.9), 2.5)
	# Rivets
	for i in range(6):
		draw_circle(Vector2.from_angle(spin + i * TAU / 6.0 + 0.5) * 16.5, 1.3, Color(0.95, 0.85, 0.6, 0.9))
	_eye(Vector2(0, -1), eye, look, 3.8)

func _draw_sniper(c: Color, dark: Color, eye: Color, look: Vector2) -> void:
	var body := PackedVector2Array([Vector2(0, -23), Vector2(7, -3), Vector2(0, 18), Vector2(-7, -3)])
	draw_circle(Vector2(0, 14), 4.0, Color(c.r, c.g, c.b, 0.4))
	draw_colored_polygon(body, c)
	draw_polyline(_closed(body), Color(0.8, 0.95, 1.0, 0.7), 1.2)
	# Wing bar with charge lights.
	draw_line(Vector2(-18, 0), Vector2(18, 0), c.lightened(0.2), 3.0)
	var parent := get_parent()
	var cd := 1.0
	if parent:
		var v = parent.get("sniper_cooldown")
		if v != null:
			cd = clampf(float(v) / 2.8, 0.0, 1.0)
	for x in [-14.0, -8.0, 8.0, 14.0]:
		var on: bool = (1.0 - cd) > (absf(float(x)) / 16.0)
		draw_circle(Vector2(x, 0), 1.8, Color(1.0, 0.4, 0.7, 0.95) if on else Color(0.2, 0.3, 0.4, 0.8))
	# Scope lens
	draw_circle(Vector2(0, -8), 4.5, dark)
	_eye(Vector2(0, -8), eye, look, 3.0)

func _draw_teleporter(c: Color, dark: Color, eye: Color, look: Vector2) -> void:
	var spin := pulse * 2.2
	# Two orbiting arc segments plus a phasing core.
	draw_arc(Vector2.ZERO, 18.0, spin - 1.0, spin + 1.0, 18, c, 3.0)
	draw_arc(Vector2.ZERO, 18.0, spin + PI - 1.0, spin + PI + 1.0, 18, c, 3.0)
	draw_arc(Vector2.ZERO, 12.0, -spin * 1.5, -spin * 1.5 + 2.2, 14, Color(c.r, c.g, c.b, 0.6), 1.6)
	var ph := 0.5 + 0.5 * sin(pulse * 3.0)
	draw_circle(Vector2.ZERO, 7.0 + ph * 1.5, dark)
	draw_circle(Vector2.ZERO, 5.0, Color(c.r, c.g, c.b, 0.55 + ph * 0.4))
	_eye(Vector2.ZERO, eye, look, 2.6)

func _draw_spitter(c: Color, dark: Color, eye: Color, look: Vector2) -> void:
	var pts := PackedVector2Array([Vector2(0, -17), Vector2(12, -7), Vector2(16, 6), Vector2(7, 16), Vector2(0, 12), Vector2(-7, 16), Vector2(-16, 6), Vector2(-12, -7)])
	draw_circle(Vector2(0, 13), 5.0, Color(c.r, c.g, c.b, 0.35))
	draw_colored_polygon(pts, c)
	draw_polyline(_closed(pts), Color(1, 0.8, 0.95, 0.7), 1.4)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -1), Vector2(7, -1), Vector2(5, 9), Vector2(-5, 9)]), dark)
	# Plasma maw that glows as the shot charges.
	var parent := get_parent()
	var warn := 0.0
	if parent:
		var v = parent.get("spitter_warning")
		if v != null:
			warn = clampf(float(v), 0.0, 1.0)
	var maw_r := 4.0 + (1.0 - warn) * 0.0 + (2.5 if warn > 0.0 else 0.0) * (0.5 + 0.5 * sin(pulse * 22.0))
	draw_circle(Vector2(0, -8), maw_r + 1.5, dark)
	draw_circle(Vector2(0, -8), maw_r, Color(1.0, 0.72, 0.95, 0.9 if warn > 0.0 else 0.6))
	draw_circle(Vector2(0, -8), maw_r * 0.45, Color(1, 1, 1, 0.9))
	_eye(Vector2(-6, 2), eye, look, 2.0)
	_eye(Vector2(6, 2), eye, look, 2.0)
