extends Node2D

@export var kind: String = "xp"
var phase: float = 0.0
var base_scale := Vector2.ONE

func _ready() -> void:
	base_scale = scale
	z_index = 6
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	rotation += delta * (1.1 if kind == "scrap" else 0.75)
	var pulse := 1.0 + sin(phase * 4.0) * 0.08
	scale = base_scale * pulse
	queue_redraw()

func _draw() -> void:
	match kind:
		"elite_magnet":
			_draw_elite_magnet()
			return
		"heal":
			_draw_heal()
			return
		"vacuum":
			_draw_magnet()
			return
		"scrap":
			_draw_scrap()
			return
	var c := Color(0.35, 1.0, 0.65, 0.18)
	if kind == "scrap":
		c = Color(1.0, 0.78, 0.25, 0.18)
	elif kind == "heal":
		c = Color(0.35, 1.0, 0.55, 0.20)
	elif kind == "vacuum":
		c = Color(0.35, 0.85, 1.0, 0.20)
	for i in range(3):
		var r := 10.0 + float(i) * 5.0 + sin(phase * 3.0 + i) * 1.5
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, c, 1.2)

## Elite magnet: magenta/white horseshoe magnet, strong pulsing glow, orbiting sparks, wide ring.
func _draw_elite_magnet() -> void:
	var pulse := 0.5 + 0.5 * sin(phase * 5.0)
	var mag := Color(1.0, 0.45, 1.0)
	# Un-rotate so the magnet glyph stays upright while the rings spin.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_circle(Vector2.ZERO, 30.0 + pulse * 6.0, Color(mag.r, mag.g, mag.b, 0.12 + pulse * 0.08))
	draw_circle(Vector2.ZERO, 18.0, Color(0.12, 0.02, 0.18, 0.95))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 28, Color(1.0, 0.85, 1.0, 0.9), 1.6 + pulse)
	# Glyph
	GameIcons.draw_misc(self, "magnet", Vector2.ZERO, 11.0, Color(1.0, 0.6, 1.0), phase)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Interaction ring + spinning arcs
	draw_arc(Vector2.ZERO, 40.0 + pulse * 3.0, 0.0, TAU, 40, Color(mag.r, mag.g, mag.b, 0.35), 1.5)
	for i in range(3):
		var a := phase * 2.5 + i * TAU / 3.0
		draw_arc(Vector2.ZERO, 34.0, a, a + 1.1, 12, Color(1.0, 0.85, 1.0, 0.85), 2.5)
	# Orbiting sparks
	for i in range(6):
		var a2 := -phase * 4.0 + i * TAU / 6.0
		var r := 24.0 + sin(phase * 6.0 + i) * 4.0
		draw_circle(Vector2.from_angle(a2) * r, 2.0, Color(1.0, 0.9, 1.0, 0.9))

## HEAL: red medical energy pod — dark red hex capsule, bright white cross, red halo pulse, orbiting "+" motes.
func _draw_heal() -> void:
	var pulse := 0.5 + 0.5 * sin(phase * 4.0)
	var red := Color(1.0, 0.22, 0.28)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_circle(Vector2.ZERO, 20.0 + pulse * 4.0, Color(red.r, red.g, red.b, 0.14 + pulse * 0.08))
	# Capsule body (rounded hex)
	var body := PackedVector2Array([Vector2(0, -11), Vector2(9, -5), Vector2(9, 5), Vector2(0, 11), Vector2(-9, 5), Vector2(-9, -5)])
	draw_colored_polygon(body, Color(0.55, 0.06, 0.12))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(1.0, 0.45, 0.5, 0.95), 1.6)
	# Inner energy core + white cross
	draw_circle(Vector2.ZERO, 6.5, Color(1.0, 0.3, 0.35, 0.55 + pulse * 0.3))
	draw_rect(Rect2(Vector2(-1.7, -6), Vector2(3.4, 12)), Color(1, 1, 1, 0.97))
	draw_rect(Rect2(Vector2(-6, -1.7), Vector2(12, 3.4)), Color(1, 1, 1, 0.97))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Heartbeat ring + orbiting plus motes
	var beat := pow(maxf(0.0, sin(phase * 4.0)), 6.0)
	draw_arc(Vector2.ZERO, 14.0 + beat * 8.0, 0.0, TAU, 28, Color(1.0, 0.35, 0.4, 0.5 * (1.0 - beat)), 1.5)
	for i in range(3):
		var a := phase * 1.8 + i * TAU / 3.0
		var p := Vector2.from_angle(a) * 16.0
		draw_line(p + Vector2(-2, 0), p + Vector2(2, 0), Color(1.0, 0.6, 0.65, 0.9), 1.2)
		draw_line(p + Vector2(0, -2), p + Vector2(0, 2), Color(1.0, 0.6, 0.65, 0.9), 1.2)

## MAGNET (normal drop): purple horseshoe magnet with orbiting field motes and a magnetic pulse.
func _draw_magnet() -> void:
	var pulse := 0.5 + 0.5 * sin(phase * 4.5)
	var pur := Color(0.72, 0.4, 1.0)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_circle(Vector2.ZERO, 19.0 + pulse * 3.0, Color(pur.r, pur.g, pur.b, 0.12 + pulse * 0.06))
	draw_circle(Vector2.ZERO, 12.5, Color(0.14, 0.05, 0.22, 0.95))
	draw_arc(Vector2.ZERO, 12.5, 0.0, TAU, 24, Color(0.85, 0.65, 1.0, 0.9), 1.4)
	GameIcons.draw_misc(self, "magnet", Vector2.ZERO, 9.5, Color(0.9, 0.62, 1.0), phase)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Field lines: two arcs sweeping in like a magnetic pull
	for i in range(2):
		var a := phase * 3.0 + i * PI
		draw_arc(Vector2.ZERO, 22.0, a, a + 1.4, 12, Color(pur.r, pur.g, pur.b, 0.75), 2.0)
	# Motes spiralling inward
	for i in range(4):
		var k := fmod(phase * 0.7 + i * 0.25, 1.0)
		var a2 := -phase * 3.0 + i * PI * 0.5 + k * 4.0
		draw_circle(Vector2.from_angle(a2) * (26.0 - k * 14.0), 1.8, Color(0.95, 0.85, 1.0, 0.9 * (1.0 - k * 0.5)))

## SCRAP: metallic salvage shard — steel-grey jagged plate, amber hot edge, rivets, specular glint.
func _draw_scrap() -> void:
	var shard := PackedVector2Array([Vector2(-8, -5), Vector2(-2, -9), Vector2(6, -6), Vector2(9, 1), Vector2(4, 8), Vector2(-4, 6), Vector2(-9, 2)])
	draw_colored_polygon(shard, Color(0.52, 0.56, 0.64))
	# Torn edge highlight on one side (amber, hot from the wreck)
	draw_polyline(PackedVector2Array([shard[2], shard[3], shard[4], shard[5]]), Color(1.0, 0.68, 0.25, 1.0), 2.6)
	draw_polyline(shard + PackedVector2Array([shard[0]]), Color(0.75, 0.8, 0.9, 0.85), 1.0)
	# Panel line + rivets
	draw_line(Vector2(-6, -2), Vector2(5, 2), Color(0.2, 0.22, 0.28, 0.9), 1.2)
	draw_circle(Vector2(-4, 1), 1.3, Color(0.85, 0.88, 0.95))
	draw_circle(Vector2(3, -3), 1.3, Color(0.85, 0.88, 0.95))
	# Specular glint sweeping across
	var g := fmod(phase * 0.8, 1.0)
	var gx := -9.0 + g * 18.0
	draw_line(Vector2(gx - 2, -8), Vector2(gx + 2, 8), Color(1, 1, 1, 0.55 * (1.0 - absf(g - 0.5) * 2.0)), 1.5)
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.7, 0.3, 0.06))
