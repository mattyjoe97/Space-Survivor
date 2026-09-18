extends Node2D
## Visual for the active magnet: spinning field ring around the player and pull
## lines to the drops currently flying in, so the player can see it working.
var player: Node2D = null
var elite := false
var _t := 0.0
var _done := false

func _ready() -> void:
	z_index = 12
	top_level = true

func finish() -> void:
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	_t += delta
	global_position = player.global_position
	queue_redraw()

func _draw() -> void:
	var col := Color(1.0, 0.55, 1.0) if elite else Color(0.45, 0.9, 1.0)
	var t: float = player.vacuum_timer if "vacuum_timer" in player else 1.0
	# Field ring with rotating segments
	draw_circle(Vector2.ZERO, 70.0, Color(col.r, col.g, col.b, 0.07))
	for i in range(4):
		var a := _t * 3.0 + i * PI * 0.5
		draw_arc(Vector2.ZERO, 62.0 + sin(_t * 8.0) * 3.0, a, a + 0.9, 12, Color(col.r, col.g, col.b, 0.85), 3.0)
	draw_arc(Vector2.ZERO, 46.0, -_t * 4.0, -_t * 4.0 + 2.2, 14, Color(1, 1, 1, 0.6), 1.5)
	# Timer arc
	draw_arc(Vector2.ZERO, 76.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(t / 5.0, 0.0, 1.0), 40, Color(col.r, col.g, col.b, 0.5), 2.0)
	# Pull lines to the nearest drops in flight
	var tree := get_tree()
	if tree == null:
		return
	var drawn := 0
	for grp in ["xp_gems", "scrap_pickups", "pickups"]:
		for g in tree.get_nodes_in_group(grp):
			if drawn >= 40:
				break
			if not is_instance_valid(g) or not g.get("attracting"):
				continue
			var rel: Vector2 = g.global_position - global_position
			if rel.length() > 900.0:
				continue
			var k := fmod(_t * 3.0 + float(drawn) * 0.37, 1.0)
			draw_line(rel, Vector2.ZERO, Color(col.r, col.g, col.b, 0.22), 1.0)
			draw_circle(rel * (1.0 - k), 2.2, Color(1, 1, 1, 0.8 * (1.0 - k)))
			drawn += 1
