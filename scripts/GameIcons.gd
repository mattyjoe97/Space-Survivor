class_name GameIcons
extends RefCounted

## Procedural vector icon library.
## Every icon is drawn into a unit circle (radius 1.0) around `c` and scaled by `s`.
## Used by IconView (Control), the HUD, level-up cards, hangar cards and the codex.
## Keeping icons procedural means they scale crisply at any size and need no assets.

const WEAPON_IDS := ["missile_system", "plasma_lance", "arc_coil", "void_blades", "railgun",
	"graviton_mines", "radiation", "cryo_field", "side_guns", "tesla_coil", "flamethrower", "torpedo_bay", "scattergun", "phase_disruptor"]
const SHIP_IDS := ["viper", "bulwark", "nova", "voidrunner", "destroyer", "aegis", "tempest", "dreadnought", "singularity"]
const ENEMY_IDS := ["chaser", "swarmer", "armored", "leecher", "teleporter", "sniper", "splitter", "void_spitter",
	"elite_spitter", "elite_rammer", "commander", "boss"]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func _pts(c: Vector2, s: float, raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in raw:
		out.append(c + Vector2(p[0], p[1]) * s)
	return out

static func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(p)
	if p.size() > 0:
		out.append(p[0])
	return out

static func _rot_pts(c: Vector2, s: float, raw: Array, ang: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in raw:
		out.append(c + Vector2(p[0], p[1]).rotated(ang) * s)
	return out

static func _alpha(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)

static func _poly_glow(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	ci.draw_polyline(_closed(pts), _alpha(col, 0.28), w * 3.0)
	ci.draw_polyline(_closed(pts), col, w)

# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

static func draw_icon(ci: CanvasItem, kind: String, id: String, c: Vector2, s: float, col: Color, t: float = 0.0) -> void:
	match kind:
		"weapon": draw_weapon(ci, id, c, s, col, t)
		"ship": draw_ship(ci, id, c, s, col)
		"enemy": draw_enemy(ci, id, c, s, col, t)
		"super": draw_super(ci, id, c, s, col, t)
		_: draw_misc(ci, id, c, s, col, t)

# ---------------------------------------------------------------------------
# Weapons
# ---------------------------------------------------------------------------

static func draw_weapon(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color, t: float = 0.0) -> void:
	var white := Color(1, 1, 1, 0.95)
	var dark := Color(0.04, 0.05, 0.09, 1.0)
	match id:
		"missile_system":
			# Angled missile with fins + exhaust, plus a small lock reticle.
			var ang := -PI * 0.25
			var body := _rot_pts(c, s, [[-0.55, -0.18], [0.45, -0.18], [0.75, 0.0], [0.45, 0.18], [-0.55, 0.18]], ang)
			ci.draw_colored_polygon(body, col)
			ci.draw_polyline(_closed(body), _alpha(white, 0.7), s * 0.05)
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.55, -0.18], [-0.75, -0.48], [-0.35, -0.18]], ang), col.darkened(0.25))
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.55, 0.18], [-0.75, 0.48], [-0.35, 0.18]], ang), col.darkened(0.25))
			ci.draw_colored_polygon(_rot_pts(c, s, [[0.15, -0.09], [0.55, -0.09], [0.55, 0.09], [0.15, 0.09]], ang), dark)
			var fl := 0.85 + sin(t * 18.0) * 0.15
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.55, -0.12], [-0.55 - 0.45 * fl, 0.0], [-0.55, 0.12]], ang), Color(1.0, 0.75, 0.3, 0.9))
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.55, -0.06], [-0.55 - 0.22 * fl, 0.0], [-0.55, 0.06]], ang), Color(1.0, 0.98, 0.8, 0.95))
			var rc := c + Vector2(0.52, -0.52) * s
			ci.draw_arc(rc, s * 0.26, 0.0, TAU, 20, _alpha(white, 0.75), s * 0.05)
			for k in range(4):
				var d := Vector2.from_angle(k * PI * 0.5)
				ci.draw_line(rc + d * s * 0.16, rc + d * s * 0.34, _alpha(white, 0.75), s * 0.05)
		"plasma_lance":
			# Long beam from a small emitter with a bright hot core and a tip flare.
			var a := c + Vector2(-0.8, 0.45) * s
			var b := c + Vector2(0.75, -0.6) * s
			ci.draw_line(a, b, _alpha(col, 0.25), s * 0.42)
			ci.draw_line(a, b, _alpha(col, 0.7), s * 0.2)
			ci.draw_line(a, b, Color(1, 0.92, 0.9, 0.98), s * 0.07)
			ci.draw_circle(a, s * 0.2, dark)
			ci.draw_arc(a, s * 0.2, 0.0, TAU, 16, col, s * 0.06)
			ci.draw_circle(b, s * 0.16, _alpha(white, 0.9))
			ci.draw_circle(b, s * 0.3, _alpha(col, 0.28))
			for k in range(4):
				var d := Vector2.from_angle(k * PI * 0.5 + PI * 0.25)
				ci.draw_line(b + d * s * 0.12, b + d * s * 0.36, _alpha(white, 0.6), s * 0.04)
		"arc_coil":
			# Two coil nodes with a jagged bolt between them.
			var n1 := c + Vector2(-0.62, 0.42) * s
			var n2 := c + Vector2(0.62, -0.42) * s
			for n: Vector2 in [n1, n2]:
				ci.draw_circle(n, s * 0.22, dark)
				ci.draw_arc(n, s * 0.22, 0.0, TAU, 16, col, s * 0.07)
				ci.draw_arc(n, s * 0.11, 0.0, TAU, 12, _alpha(col, 0.6), s * 0.04)
			var jit := sin(t * 23.0) * 0.06
			var bolt := _pts(c, s, [[-0.42, 0.28], [-0.12, 0.05 + jit], [0.02, 0.22 - jit], [0.18, -0.12 + jit], [0.42, -0.28]])
			ci.draw_polyline(bolt, _alpha(col, 0.3), s * 0.22)
			ci.draw_polyline(bolt, col, s * 0.1)
			ci.draw_polyline(bolt, _alpha(white, 0.9), s * 0.04)
		"void_blades":
			# Three curved blades orbiting a dark core.
			ci.draw_circle(c, s * 0.28, _alpha(col, 0.18))
			ci.draw_circle(c, s * 0.16, dark)
			ci.draw_arc(c, s * 0.16, 0.0, TAU, 16, col, s * 0.05)
			for k in range(3):
				var base := k * TAU / 3.0 + t * 1.6
				var blade := PackedVector2Array()
				blade.append(c + Vector2.from_angle(base) * s * 0.28)
				blade.append(c + Vector2.from_angle(base + 0.35) * s * 0.58)
				blade.append(c + Vector2.from_angle(base + 0.55) * s * 0.9)
				blade.append(c + Vector2.from_angle(base + 0.75) * s * 0.62)
				blade.append(c + Vector2.from_angle(base + 0.5) * s * 0.3)
				ci.draw_colored_polygon(blade, col)
				ci.draw_polyline(_closed(blade), _alpha(white, 0.55), s * 0.035)
		"railgun":
			# Heavy barrel with twin rails and a glowing slug leaving the muzzle.
			var ang := -PI * 0.2
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.85, -0.2], [0.25, -0.2], [0.25, 0.2], [-0.85, 0.2]], ang), Color(0.2, 0.24, 0.32))
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.85, -0.3], [-0.35, -0.3], [-0.35, 0.3], [-0.85, 0.3]], ang), Color(0.14, 0.17, 0.24))
			ci.draw_polyline(_rot_pts(c, s, [[-0.85, -0.12], [0.25, -0.12]], ang), col, s * 0.05)
			ci.draw_polyline(_rot_pts(c, s, [[-0.85, 0.12], [0.25, 0.12]], ang), col, s * 0.05)
			var mz := c + Vector2(0.25, 0).rotated(ang) * s
			var slug_dir := Vector2.RIGHT.rotated(ang)
			ci.draw_line(mz, mz + slug_dir * s * 0.6, _alpha(col, 0.25), s * 0.3)
			ci.draw_line(mz + slug_dir * s * 0.1, mz + slug_dir * s * 0.62, white, s * 0.1)
			ci.draw_circle(mz, s * 0.12, _alpha(white, 0.9))
		"graviton_mines":
			# Spiked mine with concentric gravity rings.
			for k in range(3):
				var r := 0.5 + k * 0.18 + fmod(t * 0.35, 0.18)
				ci.draw_arc(c, s * r, 0.0, TAU, 32, _alpha(col, 0.55 - k * 0.15), s * 0.035)
			for k in range(8):
				var d := Vector2.from_angle(k * TAU / 8.0)
				ci.draw_line(c + d * s * 0.2, c + d * s * 0.46, col, s * 0.09)
			ci.draw_circle(c, s * 0.3, dark)
			ci.draw_arc(c, s * 0.3, 0.0, TAU, 20, col, s * 0.07)
			ci.draw_circle(c, s * 0.12, _alpha(white, 0.9))
		"solar_flare":
			# Sun disc with alternating long/short rays.
			ci.draw_circle(c, s * 0.62, _alpha(col, 0.16))
			for k in range(12):
				var d := Vector2.from_angle(k * TAU / 12.0 + t * 0.4)
				var len := 0.95 if k % 2 == 0 else 0.7
				ci.draw_line(c + d * s * 0.42, c + d * s * len, col, s * (0.08 if k % 2 == 0 else 0.05))
			ci.draw_circle(c, s * 0.36, col)
			ci.draw_circle(c, s * 0.26, Color(1.0, 0.95, 0.75, 1.0))
		"radiation":
			# Classic trefoil.
			ci.draw_circle(c, s * 0.85, _alpha(col, 0.12))
			for k in range(3):
				var a0 := k * TAU / 3.0 - PI * 0.5 - 0.52
				var wedge := PackedVector2Array()
				wedge.append(c + Vector2.from_angle(a0 + 0.52) * s * 0.22)
				for j in range(9):
					wedge.append(c + Vector2.from_angle(a0 + j / 8.0 * 1.04) * s * 0.85)
				ci.draw_colored_polygon(wedge, col)
			ci.draw_circle(c, s * 0.18, col)
			ci.draw_circle(c, s * 0.09, dark)
		"cryo_field":
			# Six-spoke snowflake with side branches.
			ci.draw_circle(c, s * 0.8, _alpha(col, 0.1))
			for k in range(6):
				var d := Vector2.from_angle(k * TAU / 6.0 + PI / 6.0)
				var p := Vector2(-d.y, d.x)
				ci.draw_line(c, c + d * s * 0.88, col, s * 0.07)
				for br: float in [0.42, 0.66]:
					var base := c + d * s * br
					ci.draw_line(base, base + (d + p) * s * 0.16, col, s * 0.05)
					ci.draw_line(base, base + (d - p) * s * 0.16, col, s * 0.05)
			ci.draw_circle(c, s * 0.14, _alpha(white, 0.95))
		"side_guns":
			# Central hull with twin outward-facing cannons.
			ci.draw_colored_polygon(_pts(c, s, [[-0.22, -0.55], [0.22, -0.55], [0.3, 0.35], [0.0, 0.55], [-0.3, 0.35]]), Color(0.2, 0.24, 0.32))
			ci.draw_polyline(_closed(_pts(c, s, [[-0.22, -0.55], [0.22, -0.55], [0.3, 0.35], [0.0, 0.55], [-0.3, 0.35]])), _alpha(col, 0.8), s * 0.04)
			for sgn: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(_pts(c, s, [[sgn * 0.22, -0.16], [sgn * 0.92, -0.16], [sgn * 0.92, 0.04], [sgn * 0.22, 0.04]]), col)
				ci.draw_colored_polygon(_pts(c, s, [[sgn * 0.62, -0.24], [sgn * 0.8, -0.24], [sgn * 0.8, 0.12], [sgn * 0.62, 0.12]]), col.darkened(0.3))
				var fl := 0.5 + 0.5 * sin(t * 14.0 + sgn)
				ci.draw_circle(c + Vector2(sgn * 0.98, -0.06) * s, s * 0.14 * fl, Color(1.0, 0.9, 0.6, 0.9))
		"tesla_coil":
			# Coil tower with an orb and crackling arcs.
			ci.draw_colored_polygon(_pts(c, s, [[-0.55, 0.85], [0.55, 0.85], [0.35, 0.55], [-0.35, 0.55]]), Color(0.2, 0.24, 0.32))
			ci.draw_line(c + Vector2(0, 0.55) * s, c + Vector2(0, -0.25) * s, col.darkened(0.2), s * 0.18)
			for k in range(4):
				var y := 0.4 - k * 0.18
				ci.draw_line(c + Vector2(-0.22, y) * s, c + Vector2(0.22, y) * s, _alpha(white, 0.7), s * 0.05)
			ci.draw_circle(c + Vector2(0, -0.45) * s, s * 0.3, _alpha(col, 0.3))
			ci.draw_circle(c + Vector2(0, -0.45) * s, s * 0.2, white)
			for k in range(3):
				var a := t * 6.0 + k * TAU / 3.0
				var p0: Vector2 = c + Vector2(0, -0.45) * s
				ci.draw_polyline(PackedVector2Array([p0, p0 + Vector2.from_angle(a) * s * 0.3 + Vector2(0.06, -0.04) * s, p0 + Vector2.from_angle(a) * s * 0.55]), col, s * 0.05)
		"flamethrower":
			# Nozzle on the left, cone of flame tongues to the right.
			ci.draw_colored_polygon(_pts(c, s, [[-0.9, -0.2], [-0.45, -0.2], [-0.45, 0.2], [-0.9, 0.2]]), Color(0.25, 0.28, 0.36))
			ci.draw_colored_polygon(_pts(c, s, [[-0.5, -0.28], [-0.35, -0.28], [-0.35, 0.28], [-0.5, 0.28]]), col.darkened(0.3))
			for k in range(3):
				var yk := (k - 1) * 0.28
				var fl := 1.0 + 0.12 * sin(t * 15.0 + k * 2.0)
				ci.draw_colored_polygon(_pts(c, s, [[-0.35, yk - 0.16], [0.9 * fl, yk * 1.6], [-0.35, yk + 0.16]]), Color(1.0, 0.35, 0.05, 0.8))
				ci.draw_colored_polygon(_pts(c, s, [[-0.35, yk - 0.09], [0.55 * fl, yk * 1.5], [-0.35, yk + 0.09]]), Color(1.0, 0.75, 0.2, 0.9))
			ci.draw_colored_polygon(_pts(c, s, [[-0.35, -0.08], [0.25, 0.0], [-0.35, 0.08]]), Color(1.0, 0.98, 0.75, 0.95))
		"torpedo_bay":
			# Fat torpedo with fins and a big blast ring at the nose.
			var ang := -PI * 0.15
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.75, -0.22], [0.35, -0.22], [0.6, 0.0], [0.35, 0.22], [-0.75, 0.22]], ang), Color(0.6, 0.62, 0.7))
			ci.draw_colored_polygon(_rot_pts(c, s, [[0.0, -0.22], [0.15, -0.22], [0.15, 0.22], [0.0, 0.22]], ang), col)
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.75, -0.22], [-0.95, -0.52], [-0.55, -0.22]], ang), col.darkened(0.3))
			ci.draw_colored_polygon(_rot_pts(c, s, [[-0.75, 0.22], [-0.95, 0.52], [-0.55, 0.22]], ang), col.darkened(0.3))
			var nose: Vector2 = c + Vector2(0.6, 0).rotated(ang) * s
			var r := 0.3 + fmod(t * 0.6, 0.35)
			ci.draw_arc(nose, s * r, 0.0, TAU, 20, _alpha(col, 0.9 - r), s * 0.06)
			ci.draw_arc(nose, s * (r + 0.2), 0.0, TAU, 24, _alpha(col, 0.5 - r * 0.5), s * 0.04)
		"scattergun":
			# Short wide barrel with a fan of pellets.
			ci.draw_colored_polygon(_pts(c, s, [[-0.9, -0.3], [-0.2, -0.3], [-0.1, 0.3], [-0.9, 0.3]]), Color(0.25, 0.28, 0.36))
			ci.draw_colored_polygon(_pts(c, s, [[-0.9, -0.14], [-0.15, -0.16], [-0.15, 0.16], [-0.9, 0.14]]), col.darkened(0.35))
			for k in range(7):
				var a := (k - 3) * 0.19
				var d := Vector2.from_angle(a)
				var dist := 0.35 + fmod(t * 1.5 + k * 0.13, 0.55)
				var pp: Vector2 = c + Vector2(-0.15, 0) * s + d * s * dist
				ci.draw_colored_polygon(PackedVector2Array([pp + d * s * 0.09, pp + Vector2(-d.y, d.x) * s * 0.05, pp - d * s * 0.07, pp - Vector2(-d.y, d.x) * s * 0.05]), col)
			ci.draw_circle(c + Vector2(-0.1, 0) * s, s * 0.14, _alpha(white, 0.9))
		"phase_disruptor":
			# Crescent phase wave with ghost copies and a marked target ring.
			for g in range(3):
				var x := -0.55 + g * 0.22
				var wave := PackedVector2Array()
				for k in range(9):
					var kk := float(k) / 8.0 * 2.0 - 1.0
					wave.append(c + Vector2(x - kk * kk * 0.22, kk * 0.7) * s)
				ci.draw_polyline(wave, _alpha(col, 0.35 + g * 0.3), s * (0.06 + g * 0.04))
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.11, -0.7) * s, c + Vector2(0.11, 0.0) * s, c + Vector2(-0.11, 0.7) * s]), _alpha(white, 0.8), s * 0.04)
			var tc: Vector2 = c + Vector2(0.55, 0.0) * s
			ci.draw_arc(tc, s * 0.28, t * 4.0, t * 4.0 + 4.0, 16, col, s * 0.06)
			ci.draw_circle(tc, s * 0.1, white)
		_:
			ci.draw_circle(c, s * 0.5, col)

# ---------------------------------------------------------------------------
# Superweapons: both parent icons fused under a burst
# ---------------------------------------------------------------------------

static func draw_super(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color, t: float = 0.0) -> void:
	var data: Dictionary = GameManager.WEAPON_SYNERGIES.get(id, {})
	var reqs: Array = data.get("requires", [])
	# Burst backdrop
	for k in range(8):
		var a := t * 0.5 + k * TAU / 8.0
		var d := Vector2.from_angle(a)
		ci.draw_line(c + d * s * 0.5, c + d * s * (1.0 + 0.08 * sin(t * 5.0 + k)), _alpha(col, 0.45), s * 0.08)
	ci.draw_circle(c, s * 0.9, _alpha(col, 0.14))
	ci.draw_arc(c, s * 0.9, 0.0, TAU, 32, _alpha(col, 0.7), s * 0.05)
	if reqs.size() >= 2:
		var ca: Color = GameManager.WEAPON_DEFS.get(reqs[0], {}).get("color", col)
		var cb: Color = GameManager.WEAPON_DEFS.get(reqs[1], {}).get("color", col)
		draw_weapon(ci, str(reqs[0]), c + Vector2(-0.3, -0.18) * s, s * 0.45, ca, t)
		draw_weapon(ci, str(reqs[1]), c + Vector2(0.3, 0.18) * s, s * 0.45, cb, t)
	# Star
	var star := PackedVector2Array()
	for k in range(10):
		var r := 0.28 if k % 2 == 0 else 0.12
		star.append(c + Vector2(0.0, 0.0) * s + Vector2.from_angle(-PI * 0.5 + k * PI / 5.0 + t) * s * r)
	ci.draw_colored_polygon(star, Color(1.0, 0.95, 0.7, 0.95))

# ---------------------------------------------------------------------------
# Ships (compact silhouettes; nose up)
# ---------------------------------------------------------------------------

static func draw_ship(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color) -> void:
	var wing := col.darkened(0.22)
	var canopy := Color(0.85, 0.97, 1.0, 0.95)
	var line := Color(1, 1, 1, 0.55)
	var eng := Color(1.0, 0.72, 0.35, 0.9)
	match id:
		"bulwark":
			eng = Color(1.0, 0.5, 0.2, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.62, -0.05], [-0.95, 0.35], [-0.75, 0.6], [-0.2, 0.32]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.62, -0.05], [0.95, 0.35], [0.75, 0.6], [0.2, 0.32]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[-0.4, -0.5], [0.4, -0.5], [0.56, 0.15], [0.36, 0.55], [-0.36, 0.55], [-0.56, 0.15]]), col)
			ci.draw_line(c + Vector2(-0.36, 0.15) * s, c + Vector2(0.36, 0.15) * s, Color(1, 0.9, 0.65, 0.4), s * 0.06)
			_ship_engines(ci, c, s, [Vector2(-0.24, 0.6), Vector2(0.24, 0.6)], 0.3, eng)
		"nova":
			eng = Color(0.95, 0.35, 1.0, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.16, 0.0], [-0.9, 0.1], [-0.4, 0.3], [-0.06, 0.24]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.16, 0.0], [0.9, 0.1], [0.4, 0.3], [0.06, 0.24]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.85], [0.24, 0.24], [0.0, 0.62], [-0.24, 0.24]]), col)
			ci.draw_arc(c + Vector2(0, -0.02) * s, s * 0.6, 2.8, 6.6, 20, Color(1, 0.6, 0.95, 0.5), s * 0.05)
			_ship_engines(ci, c, s, [Vector2(0.0, 0.66)], 0.3, eng)
		"voidrunner":
			eng = Color(0.2, 1.0, 0.85, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.08, 0.0], [-0.84, 0.32], [-0.46, 0.48], [-0.04, 0.28]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.08, 0.0], [0.84, 0.32], [0.46, 0.48], [0.04, 0.28]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.84], [0.22, -0.04], [0.1, 0.56], [0.0, 0.36], [-0.1, 0.56], [-0.22, -0.04]]), col)
			ci.draw_arc(c, s * 0.95, 0.6, 2.6, 20, Color(0.25, 1.0, 0.9, 0.4), s * 0.05)
			_ship_engines(ci, c, s, [Vector2(-0.2, 0.6), Vector2(0.2, 0.6)], 0.24, eng)
		"destroyer":
			eng = Color(1.0, 0.25, 0.15, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.46, -0.08], [-1.0, 0.26], [-0.84, 0.6], [-0.24, 0.36]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.46, -0.08], [1.0, 0.26], [0.84, 0.6], [0.24, 0.36]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.68], [0.46, -0.04], [0.4, 0.56], [-0.4, 0.56], [-0.46, -0.04]]), col)
			for x: float in [-0.52, 0.52]:
				ci.draw_rect(Rect2(c + Vector2(x - 0.08, 0.08) * s, Vector2(0.16, 0.3) * s), Color(0.06, 0.07, 0.1, 1))
			_ship_engines(ci, c, s, [Vector2(-0.28, 0.62), Vector2(0.28, 0.62)], 0.3, eng)
		"aegis":
			eng = Color(1.0, 0.5, 0.2, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.84, 0.0], [-1.0, 0.32], [-0.8, 0.54], [-0.16, 0.32]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.84, 0.0], [1.0, 0.32], [0.8, 0.54], [0.16, 0.32]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.68], [0.38, -0.02], [0.38, 0.5], [0.0, 0.62], [-0.38, 0.5], [-0.38, -0.02]]), col)
			ci.draw_arc(c, s * 0.68, -1.0, 4.15, 24, Color(0.5, 0.9, 1, 0.5), s * 0.06)
			_ship_engines(ci, c, s, [Vector2(-0.3, 0.6), Vector2(0.3, 0.6)], 0.24, eng)
		"tempest":
			eng = Color(0.3, 0.7, 1.0, 1.0)
			ci.draw_colored_polygon(_pts(c, s, [[-0.06, 0.02], [-1.0, 0.2], [-0.56, 0.36], [-0.08, 0.24]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.06, 0.02], [1.0, 0.2], [0.56, 0.36], [0.08, 0.24]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.88], [0.18, -0.06], [0.12, 0.6], [0.0, 0.46], [-0.12, 0.6], [-0.18, -0.06]]), col)
			ci.draw_arc(c, s * 0.95, 0.5, 2.0, 12, Color(0.35, 0.65, 1, 0.5), s * 0.07)
			ci.draw_arc(c, s * 0.95, 3.65, 5.15, 12, Color(0.35, 0.65, 1, 0.5), s * 0.07)
			_ship_engines(ci, c, s, [Vector2(-0.22, 0.6), Vector2(0.22, 0.6)], 0.22, eng)
		"dreadnought":
			eng = Color(1.0, 0.25, 0.15, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.62, -0.04], [-1.0, 0.3], [-0.8, 0.66], [-0.36, 0.38]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.62, -0.04], [1.0, 0.3], [0.8, 0.66], [0.36, 0.38]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.6], [0.54, -0.08], [0.56, 0.56], [0.0, 0.74], [-0.56, 0.56], [-0.54, -0.08]]), col)
			for x: float in [-0.6, 0.0, 0.6]:
				ci.draw_circle(c + Vector2(x, 0.36) * s, s * 0.09, Color(0.05, 0.07, 0.1, 1))
			_ship_engines(ci, c, s, [Vector2(-0.38, 0.74), Vector2(0.38, 0.74)], 0.3, eng)
		"singularity":
			eng = Color(0.6, 0.25, 1.0, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.56, 0.1], [-0.98, 0.36], [-0.7, 0.58], [-0.14, 0.36]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.56, 0.1], [0.98, 0.36], [0.7, 0.58], [0.14, 0.36]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.68], [0.3, 0.08], [0.16, 0.54], [0.0, 0.68], [-0.16, 0.54], [-0.3, 0.08]]), col)
			ci.draw_circle(c + Vector2(0, 0.14) * s, s * 0.22, Color(0.08, 0.03, 0.14, 0.95))
			ci.draw_arc(c + Vector2(0, 0.14) * s, s * 0.32, 0.6, 5.0, 24, Color(0.75, 0.45, 1, 0.7), s * 0.05)
			_ship_engines(ci, c, s, [Vector2(-0.18, 0.66), Vector2(0.18, 0.66)], 0.24, eng)
		_:
			# viper / default
			eng = Color(0.3, 0.85, 1.0, 0.95)
			ci.draw_colored_polygon(_pts(c, s, [[-0.1, 0.0], [-0.72, 0.16], [-0.54, 0.48], [-0.08, 0.28]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.1, 0.0], [0.72, 0.16], [0.54, 0.48], [0.08, 0.28]]), wing)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.76], [0.3, 0.1], [0.16, 0.56], [0.0, 0.4], [-0.16, 0.56], [-0.3, 0.1]]), col)
			ci.draw_line(c + Vector2(0, -0.68) * s, c + Vector2(0, 0.34) * s, Color(1, 1, 1, 0.22), s * 0.04)
			_ship_engines(ci, c, s, [Vector2(0.0, 0.6)], 0.3, eng)
	# Shared canopy.
	ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.44], [0.16, -0.1], [0.0, 0.1], [-0.16, -0.1]]), canopy)
	ci.draw_polyline(_closed(_pts(c, s, [[0.0, -0.44], [0.16, -0.1], [0.0, 0.1], [-0.16, -0.1]])), line, s * 0.03)

static func _ship_engines(ci: CanvasItem, c: Vector2, s: float, spots: Array, size: float, eng: Color) -> void:
	for sp in spots:
		var p: Vector2 = c + sp * s
		ci.draw_circle(p, s * size * 0.75, _alpha(eng, 0.22))
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-size * 0.28, 0) * s, p + Vector2(size * 0.28, 0) * s, p + Vector2(0, size * 1.1) * s]), eng)
		ci.draw_circle(p, s * size * 0.22, Color(1, 1, 0.92, 0.95))

# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------

static func draw_enemy(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color, t: float = 0.0) -> void:
	var dark := col.darkened(0.6)
	var eye := Color(1.0, 0.88, 0.35)
	match id:
		"armored":
			ci.draw_circle(c, s * 0.82, col)
			ci.draw_circle(c, s * 0.56, dark)
			ci.draw_arc(c, s * 0.88, 0.0, TAU, 32, Color(1, 0.85, 0.45, 0.95), s * 0.12)
			for k in range(6):
				var d := Vector2.from_angle(k * TAU / 6.0)
				ci.draw_line(c + d * s * 0.56, c + d * s * 0.82, dark, s * 0.06)
			ci.draw_circle(c, s * 0.2, eye)
		"sniper":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.95], [0.3, -0.1], [0.0, 0.7], [-0.3, -0.1]]), col)
			ci.draw_line(c + Vector2(-0.8, 0) * s, c + Vector2(0.8, 0) * s, col.lightened(0.25), s * 0.12)
			ci.draw_arc(c + Vector2(0, -0.2) * s, s * 0.22, 0.0, TAU, 16, Color(1, 0.35, 0.65, 0.95), s * 0.05)
			ci.draw_circle(c + Vector2(0, -0.2) * s, s * 0.08, Color(1, 0.4, 0.7))
		"teleporter":
			ci.draw_arc(c, s * 0.78, -1.05, 1.05, 18, col, s * 0.13)
			ci.draw_arc(c, s * 0.78, PI - 1.05, PI + 1.05, 18, col, s * 0.13)
			ci.draw_arc(c, s * 0.42, 0.0, TAU, 20, _alpha(col, 0.5), s * 0.05)
			ci.draw_circle(c, s * 0.2, Color(0.95, 0.85, 1.0))
		"void_spitter", "elite_spitter":
			var big := id == "elite_spitter"
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.78], [0.55, -0.3], [0.7, 0.3], [0.32, 0.72], [0.0, 0.52], [-0.32, 0.72], [-0.7, 0.3], [-0.55, -0.3]]), col)
			ci.draw_colored_polygon(_pts(c, s, [[-0.3, -0.05], [0.3, -0.05], [0.22, 0.4], [-0.22, 0.4]]), dark)
			var mouth := c + Vector2(0, -0.35) * s
			ci.draw_circle(mouth, s * 0.2, dark)
			ci.draw_circle(mouth, s * (0.1 + 0.03 * sin(t * 9.0)), Color(1.0, 0.75, 0.95))
			if big:
				ci.draw_arc(c, s * 0.95, 0.0, TAU, 32, Color(1, 0.85, 0.45, 0.9), s * 0.06)
		"elite_rammer":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.98], [0.62, -0.2], [0.72, 0.42], [0.28, 0.72], [0.0, 0.55], [-0.28, 0.72], [-0.72, 0.42], [-0.62, -0.2]]), col.darkened(0.45))
			ci.draw_polyline(_closed(_pts(c, s, [[0.0, -0.98], [0.62, -0.2], [0.72, 0.42], [0.28, 0.72], [0.0, 0.55], [-0.28, 0.72], [-0.72, 0.42], [-0.62, -0.2]])), col, s * 0.08)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -1.0], [0.28, -0.35], [0.0, -0.12], [-0.28, -0.35]]), Color(1.0, 0.72, 0.28))
			ci.draw_arc(c, s * 0.98, 0.0, TAU, 32, Color(1, 0.85, 0.45, 0.9), s * 0.06)
		"commander":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.9], [0.5, -0.5], [0.85, 0.0], [0.5, 0.55], [0.0, 0.75], [-0.5, 0.55], [-0.85, 0.0], [-0.5, -0.5]]), col.darkened(0.5))
			ci.draw_polyline(_closed(_pts(c, s, [[0.0, -0.9], [0.5, -0.5], [0.85, 0.0], [0.5, 0.55], [0.0, 0.75], [-0.5, 0.55], [-0.85, 0.0], [-0.5, -0.5]])), col, s * 0.07)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.32], [0.28, 0.0], [0.0, 0.32], [-0.28, 0.0]]), Color(1.0, 0.7, 0.25))
			for k in range(3):
				var d := Vector2.from_angle(-PI / 2.0 + (k - 1) * 0.5)
				ci.draw_line(c + d * s * 0.5, c + d * s * 0.95, Color(1, 0.85, 0.45, 0.9), s * 0.06)
		"boss":
			ci.draw_circle(c, s * 0.98, _alpha(col, 0.14))
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.95], [0.5, -0.58], [0.88, -0.1], [0.7, 0.55], [0.3, 0.8], [0.0, 0.66], [-0.3, 0.8], [-0.7, 0.55], [-0.88, -0.1], [-0.5, -0.58]]), Color(0.2, 0.09, 0.15))
			ci.draw_polyline(_closed(_pts(c, s, [[0.0, -0.95], [0.5, -0.58], [0.88, -0.1], [0.7, 0.55], [0.3, 0.8], [0.0, 0.66], [-0.3, 0.8], [-0.7, 0.55], [-0.88, -0.1], [-0.5, -0.58]])), col, s * 0.07)
			ci.draw_circle(c, s * 0.36, _alpha(col, 0.2))
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.3], [0.24, 0.0], [0.0, 0.3], [-0.24, 0.0]]), Color(1.0, 0.68, 0.2))
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.15], [0.12, 0.0], [0.0, 0.15], [-0.12, 0.0]]), Color(1, 0.95, 0.72))
			for p: Array in [[-0.62, -0.18], [0.62, -0.18], [-0.5, 0.46], [0.5, 0.46]]:
				ci.draw_circle(c + Vector2(p[0], p[1]) * s, s * 0.08, col)
		_:
			# chaser / swarmer / leecher / splitter share the bug body with different accents.
			var body := _pts(c, s, [[0.0, -0.85], [0.5, -0.4], [0.8, 0.1], [0.45, 0.62], [0.0, 0.42], [-0.45, 0.62], [-0.8, 0.1], [-0.5, -0.4]])
			if id == "swarmer":
				ci.draw_line(c + Vector2(-0.6, -0.4) * s, c + Vector2(-1.0, -0.75) * s, col.lightened(0.25), s * 0.09)
				ci.draw_line(c + Vector2(0.6, -0.4) * s, c + Vector2(1.0, -0.75) * s, col.lightened(0.25), s * 0.09)
			elif id == "leecher":
				for a: float in [-0.8, 0.0, 0.8]:
					var d := Vector2.from_angle(a - PI / 2.0)
					ci.draw_line(c + d * s * 0.5, c + d * s * 1.0, col.lightened(0.2), s * 0.09)
			elif id == "splitter":
				ci.draw_line(c + Vector2(-0.55, 0.4) * s, c + Vector2(-0.95, 0.75) * s, col.lightened(0.2), s * 0.09)
				ci.draw_line(c + Vector2(0.55, 0.4) * s, c + Vector2(0.95, 0.75) * s, col.lightened(0.2), s * 0.09)
				ci.draw_line(c + Vector2(0, -0.6) * s, c + Vector2(0, 0.3) * s, Color(0.6, 1, 1, 0.5), s * 0.05)
			ci.draw_colored_polygon(body, col)
			ci.draw_polyline(_closed(body), Color(1, 0.75, 0.82, 0.75), s * 0.05)
			ci.draw_colored_polygon(_pts(c, s, [[-0.32, -0.12], [0.32, -0.12], [0.24, 0.34], [-0.24, 0.34]]), dark)
			if id == "leecher":
				eye = Color(1.0, 0.35, 0.45)
			ci.draw_circle(c + Vector2(0, -0.15) * s, s * 0.17, eye)
			ci.draw_circle(c + Vector2(0, -0.15) * s, s * 0.07, Color.WHITE)

# ---------------------------------------------------------------------------
# Misc: pickups, stats, systems, UI glyphs
# ---------------------------------------------------------------------------

static func draw_misc(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color, t: float = 0.0) -> void:
	var white := Color(1, 1, 1, 0.95)
	var dark := Color(0.04, 0.05, 0.09, 1.0)
	match id:
		"xp":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.85], [0.6, 0.0], [0.0, 0.85], [-0.6, 0.0]]), col)
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.45], [0.3, 0.0], [0.0, 0.45], [-0.3, 0.0]]), Color(0.85, 1.0, 0.92))
			ci.draw_polyline(_closed(_pts(c, s, [[0.0, -0.85], [0.6, 0.0], [0.0, 0.85], [-0.6, 0.0]])), _alpha(white, 0.6), s * 0.04)
		"scrap":
			ci.draw_colored_polygon(_pts(c, s, [[-0.7, -0.3], [-0.2, -0.75], [0.55, -0.55], [0.75, 0.2], [0.25, 0.7], [-0.55, 0.5]]), col)
			ci.draw_polyline(_closed(_pts(c, s, [[-0.7, -0.3], [-0.2, -0.75], [0.55, -0.55], [0.75, 0.2], [0.25, 0.7], [-0.55, 0.5]])), _alpha(white, 0.6), s * 0.05)
			ci.draw_line(c + Vector2(-0.3, -0.35) * s, c + Vector2(0.3, 0.3) * s, dark, s * 0.08)
			ci.draw_line(c + Vector2(0.25, -0.35) * s, c + Vector2(-0.25, 0.3) * s, dark, s * 0.08)
		"heal", "hull":
			ci.draw_circle(c, s * 0.82, _alpha(col, 0.16))
			ci.draw_colored_polygon(_pts(c, s, [[-0.22, -0.7], [0.22, -0.7], [0.22, -0.22], [0.7, -0.22], [0.7, 0.22], [0.22, 0.22], [0.22, 0.7], [-0.22, 0.7], [-0.22, 0.22], [-0.7, 0.22], [-0.7, -0.22], [-0.22, -0.22]]), col)
		"shield", "defense":
			var sh := _pts(c, s, [[0.0, -0.85], [0.72, -0.55], [0.66, 0.15], [0.0, 0.82], [-0.66, 0.15], [-0.72, -0.55]])
			ci.draw_colored_polygon(sh, _alpha(col, 0.35))
			ci.draw_polyline(_closed(sh), col, s * 0.08)
			ci.draw_line(c + Vector2(0, -0.55) * s, c + Vector2(0, 0.45) * s, _alpha(white, 0.75), s * 0.06)
		"speed":
			for k in range(3):
				var x := -0.55 + k * 0.42
				ci.draw_polyline(_pts(c, s, [[x - 0.2, -0.5], [x + 0.2, 0.0], [x - 0.2, 0.5]]), _alpha(col, 0.5 + k * 0.25), s * 0.12)
		"damage", "weapons":
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 28, col, s * 0.07)
			for k in range(4):
				var d := Vector2.from_angle(k * PI * 0.5)
				ci.draw_line(c + d * s * 0.4, c + d * s * 0.88, col, s * 0.07)
			ci.draw_circle(c, s * 0.16, Color(1, 0.4, 0.4))
		"fire_rate":
			for k in range(3):
				var y := -0.42 + k * 0.42
				ci.draw_colored_polygon(_pts(c, s, [[-0.7 + k * 0.1, y - 0.12], [0.3 - k * 0.1, y - 0.12], [0.55 - k * 0.1, y], [0.3 - k * 0.1, y + 0.12], [-0.7 + k * 0.1, y + 0.12]]), _alpha(col, 0.55 + k * 0.2))
		"crit":
			for k in range(4):
				var d := Vector2.from_angle(k * PI * 0.5 - PI * 0.25)
				var star := PackedVector2Array([c + d * s * 0.95, c + d.rotated(0.45) * s * 0.3, c + d.rotated(-0.45) * s * 0.3])
				ci.draw_colored_polygon(star, col)
			ci.draw_circle(c, s * 0.28, Color(1, 0.95, 0.75))
		"area":
			for k in range(3):
				var r := 0.3 + k * 0.28
				ci.draw_arc(c, s * r, 0.0, TAU, 24 + k * 8, _alpha(col, 0.9 - k * 0.28), s * 0.07)
			ci.draw_circle(c, s * 0.12, white)
		"magnet", "pickup_range":
			ci.draw_arc(c + Vector2(0, 0.1) * s, s * 0.55, PI, TAU, 24, col, s * 0.24)
			ci.draw_rect(Rect2(c + Vector2(-0.67, 0.1) * s, Vector2(0.24, 0.5) * s), col)
			ci.draw_rect(Rect2(c + Vector2(0.43, 0.1) * s, Vector2(0.24, 0.5) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.67, 0.38) * s, Vector2(0.24, 0.22) * s), white)
			ci.draw_rect(Rect2(c + Vector2(0.43, 0.38) * s, Vector2(0.24, 0.22) * s), white)
		"luck":
			for k in range(4):
				var d := Vector2.from_angle(k * PI * 0.5)
				ci.draw_circle(c + d * s * 0.38, s * 0.34, col)
			ci.draw_line(c + Vector2(0.1, 0.35) * s, c + Vector2(0.28, 0.9) * s, col.darkened(0.3), s * 0.08)
			ci.draw_circle(c, s * 0.14, Color(1, 1, 1, 0.5))
		"reroll":
			ci.draw_arc(c, s * 0.62, 0.3, 2.7, 20, col, s * 0.12)
			ci.draw_arc(c, s * 0.62, PI + 0.3, PI + 2.7, 20, col, s * 0.12)
			for a: float in [0.3, PI + 0.3]:
				var tip := c + Vector2.from_angle(a) * s * 0.62
				var d := Vector2.from_angle(a - PI * 0.5)
				ci.draw_colored_polygon(PackedVector2Array([tip + d * s * 0.28, tip + d.rotated(PI * 0.5) * s * 0.2, tip - d.rotated(PI * 0.5) * s * 0.2]), col)
		"merchant":
			ci.draw_colored_polygon(_pts(c, s, [[-0.75, -0.2], [0.75, -0.2], [0.6, 0.75], [-0.6, 0.75]]), col)
			ci.draw_arc(c + Vector2(0, -0.2) * s, s * 0.34, PI, TAU, 16, col.lightened(0.2), s * 0.1)
			ci.draw_colored_polygon(_pts(c, s, [[-0.18, 0.05], [0.18, 0.05], [0.18, 0.45], [-0.18, 0.45]]), dark)
		"relic":
			var gem := _pts(c, s, [[0.0, -0.85], [0.55, -0.35], [0.7, 0.15], [0.0, 0.85], [-0.7, 0.15], [-0.55, -0.35]])
			ci.draw_colored_polygon(gem, col)
			ci.draw_polyline(_closed(gem), _alpha(white, 0.7), s * 0.05)
			ci.draw_line(c + Vector2(-0.55, -0.35) * s, c + Vector2(0.55, -0.35) * s, _alpha(white, 0.4), s * 0.04)
			ci.draw_line(c + Vector2(0, -0.35) * s, c + Vector2(0, 0.85) * s, _alpha(white, 0.3), s * 0.04)
			var sp := 0.5 + 0.5 * sin(t * 4.0)
			ci.draw_circle(c + Vector2(-0.22, -0.55) * s, s * 0.1 * sp, white)
		"cursed":
			var bolt := _pts(c, s, [[0.2, -0.9], [-0.4, 0.05], [0.05, 0.05], [-0.2, 0.9], [0.45, -0.1], [0.05, -0.1]])
			ci.draw_colored_polygon(bolt, col)
			ci.draw_polyline(_closed(bolt), Color(0.1, 0.0, 0.05, 0.9), s * 0.04)
		"synergy":
			ci.draw_arc(c + Vector2(-0.28, 0) * s, s * 0.45, 0.0, TAU, 24, col, s * 0.1)
			ci.draw_arc(c + Vector2(0.28, 0) * s, s * 0.45, 0.0, TAU, 24, col.lightened(0.3), s * 0.1)
			ci.draw_circle(c, s * 0.12, white)
		"system", "systems":
			# Gear.
			for k in range(8):
				var d := Vector2.from_angle(k * TAU / 8.0 + t * 0.3)
				ci.draw_line(c + d * s * 0.45, c + d * s * 0.85, col, s * 0.22)
			ci.draw_circle(c, s * 0.55, col)
			ci.draw_circle(c, s * 0.24, dark)
		"upgrade", "upgrades":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.85], [0.75, 0.0], [0.32, 0.0], [0.32, 0.8], [-0.32, 0.8], [-0.32, 0.0], [-0.75, 0.0]]), col)
		"skull", "danger":
			ci.draw_colored_polygon(_pts(c, s, [[0.0, -0.9], [0.85, 0.7], [-0.85, 0.7]]), col)
			ci.draw_line(c + Vector2(0, -0.3) * s, c + Vector2(0, 0.25) * s, dark, s * 0.12)
			ci.draw_circle(c + Vector2(0, 0.48) * s, s * 0.08, dark)
		"star":
			var star := PackedVector2Array()
			for k in range(10):
				var r := 0.9 if k % 2 == 0 else 0.4
				star.append(c + Vector2.from_angle(-PI * 0.5 + k * PI / 5.0) * s * r)
			ci.draw_colored_polygon(star, col)
		"clock", "timer":
			ci.draw_arc(c, s * 0.8, 0.0, TAU, 28, col, s * 0.09)
			ci.draw_line(c, c + Vector2(0, -0.5) * s, col, s * 0.08)
			ci.draw_line(c, c + Vector2(0.35, 0.15) * s, col, s * 0.08)
		_:
			ci.draw_circle(c, s * 0.55, _alpha(col, 0.3))
			ci.draw_arc(c, s * 0.55, 0.0, TAU, 20, col, s * 0.08)

## Best-effort icon lookup for an upgrade/relic id used by the level-up UI.
static func misc_id_for_upgrade(upgrade_id: String, category: String = "") -> String:
	var u := upgrade_id.to_lower()
	if GameIcons.WEAPON_IDS.has(u):
		return u
	if category == "SYSTEMS":
		return "system"
	for key in ["fire_rate", "crit", "magnet", "speed", "hull", "damage", "area", "luck", "reroll", "shield", "heal", "pickup"]:
		if u.find(key) >= 0:
			return key
	if u.find("hp") >= 0 or u.find("armor") >= 0 or u.find("plating") >= 0:
		return "hull"
	if u.find("projectile") >= 0 or u.find("spread") >= 0 or u.find("multi") >= 0:
		return "fire_rate"
	if u.find("explo") >= 0 or u.find("blast") >= 0:
		return "area"
	if u.find("fortune") >= 0:
		return "luck"
	if u.find("regen") >= 0 or u.find("repair") >= 0:
		return "heal"
	return "upgrade"
