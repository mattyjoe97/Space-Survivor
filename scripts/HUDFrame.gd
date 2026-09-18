extends Control

var pulse := 0.0
## 0 = normal, 1 = critical HP. Ramps the corner brackets and screen edges toward
## a warning red and speeds up the pulse so low health reads as urgent.
var alert_level := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func set_alert(level: float) -> void:
	alert_level = clampf(level, 0.0, 1.0)

func _process(delta: float) -> void:
	pulse += delta * (1.0 + alert_level * 2.2)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var a := 0.16 + sin(pulse * 1.7) * 0.035 + alert_level * 0.1
	var c := Color(0.35, 0.86, 1.0, a).lerp(Color(1.0, 0.2, 0.22, a), alert_level)
	var c2 := Color(0.38, 1.0, 0.72, a * 0.8).lerp(Color(1.0, 0.25, 0.2, a * 0.9), alert_level)
	# Subtle tactical corner brackets.
	_draw_corner(Vector2(7, 7), Vector2(1, 1), c)
	_draw_corner(Vector2(w - 7, 7), Vector2(-1, 1), c)
	_draw_corner(Vector2(7, h - 7), Vector2(1, -1), c2)
	_draw_corner(Vector2(w - 7, h - 7), Vector2(-1, -1), c2)
	# Very faint horizontal scan marks near the edges.
	for y in [h * 0.25, h * 0.5, h * 0.75]:
		draw_line(Vector2(8, y), Vector2(22, y), Color(c.r, c.g, c.b, 0.035), 1.0)
		draw_line(Vector2(w - 22, y), Vector2(w - 8, y), Color(c.r, c.g, c.b, 0.035), 1.0)
	# Critical-health vignette: a soft red glow creeping in from the screen edges.
	if alert_level > 0.01:
		var glow := 0.05 + sin(pulse * 2.4) * 0.03
		var vig := Color(0.9, 0.08, 0.1, alert_level * glow)
		var edge := 46.0 + alert_level * 30.0
		draw_rect(Rect2(0, 0, w, edge), vig, true)
		draw_rect(Rect2(0, h - edge, w, edge), vig, true)
		draw_rect(Rect2(0, 0, edge, h), vig, true)
		draw_rect(Rect2(w - edge, 0, edge, h), vig, true)

func _draw_corner(p: Vector2, dir: Vector2, col: Color) -> void:
	var lx := 34.0
	var ly := 18.0
	draw_line(p, p + Vector2(dir.x * lx, 0), col, 1.0)
	draw_line(p, p + Vector2(0, dir.y * ly), col, 1.0)
