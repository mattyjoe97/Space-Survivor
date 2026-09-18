extends Node2D
## Subtle boundary of the playable arena (Player clamps to ±2500). Drawn as a faint
## dashed frame with corner brackets and soft inner glow that brightens as the ship
## approaches an edge.
const LIMIT := 2500.0
var _t := 0.0

func _ready() -> void:
	z_index = -5

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var p = GameManager.player
	var near := 0.0
	if is_instance_valid(p):
		var pos: Vector2 = p.global_position
		var edge_d: float = LIMIT - maxf(absf(pos.x), absf(pos.y))
		near = clampf(1.0 - edge_d / 500.0, 0.0, 1.0)
	var col := Color(0.45, 0.75, 1.0, 0.16 + near * 0.35)
	var rect := Rect2(Vector2(-LIMIT, -LIMIT), Vector2(LIMIT * 2.0, LIMIT * 2.0))
	# Dashed frame
	var dash := 60.0
	var gap := 40.0
	var offset := fmod(_t * 25.0, dash + gap)
	var corners := [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	for i in range(4):
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var dir := (b - a).normalized()
		var len := a.distance_to(b)
		var x := -offset
		while x < len:
			var s0 := maxf(x, 0.0)
			var s1 := minf(x + dash, len)
			if s1 > s0:
				draw_line(a + dir * s0, a + dir * s1, col, 2.0)
			x += dash + gap
	# Inner warning band
	draw_rect(rect.grow(-40.0), Color(0.45, 0.75, 1.0, 0.05 + near * 0.12), false, 6.0)
	# Corner brackets
	for c in corners:
		var sx: float = -1.0 if c.x > 0.0 else 1.0
		var sy: float = -1.0 if c.y > 0.0 else 1.0
		draw_line(c, c + Vector2(sx * 160.0, 0), Color(0.6, 0.85, 1.0, 0.5 + near * 0.4), 4.0)
		draw_line(c, c + Vector2(0, sy * 160.0), Color(0.6, 0.85, 1.0, 0.5 + near * 0.4), 4.0)
