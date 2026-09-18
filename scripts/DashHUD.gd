extends Control
## Compact dash indicator: one pip per charge; a charging pip fills clockwise; READY / seconds text.
var player: Node = null
func _process(_d: float) -> void:
	queue_redraw()
func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var maxc: int = int(player.dash_charges_max)
	var have: int = int(player.dash_charges)
	var rech: Array = player.dash_recharge
	var col := Color(0.45, 0.9, 1.0)
	for i in range(maxc):
		var c := Vector2(8 + i * 18, 8)
		var full: bool = i < have
		draw_circle(c, 6.5, Color(0.03, 0.06, 0.1, 0.9))
		draw_arc(c, 6.5, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.5), 1.0)
		if full:
			draw_circle(c, 4.5, col)
		elif i - have < rech.size():
			# Longest-remaining charges are drawn last; show the one that will be ready next.
			var sorted := rech.duplicate(); sorted.sort()
			var left: float = float(sorted[i - have])
			var k: float = 1.0 - clampf(left / player.DASH_COOLDOWN, 0.0, 1.0)
			draw_arc(c, 4.5, -PI * 0.5, -PI * 0.5 + TAU * k, 16, col, 2.5)
	var lbl := "DASH READY" if have > 0 else "DASH %.1fs" % (rech.min() if not rech.is_empty() else 0.0)
	if maxc > 1:
		lbl += "  %d/%d" % [have, maxc]
	draw_string(ThemeDB.fallback_font, Vector2(8 + maxc * 18 + 2, 12), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(col.r, col.g, col.b, 0.9 if have > 0 else 0.6))
