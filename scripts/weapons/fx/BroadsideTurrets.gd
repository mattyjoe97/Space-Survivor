extends Node2D
## Visible flank turrets on the hull that recoil when they fire.
var quad := false
var _recoil: Dictionary = {}
func _process(delta: float) -> void:
	for k in _recoil.keys():
		_recoil[k] = maxf(0.0, float(_recoil[k]) - delta * 6.0)
	queue_redraw()
func kick(dir_world: Vector2) -> void:
	var local := dir_world.rotated(-get_parent().player.rotation) if get_parent().get("player") != null else dir_world
	var key := "r" if local.x > 0.5 else ("l" if local.x < -0.5 else ("f" if local.y < -0.5 else "b"))
	_recoil[key] = 1.0
func _draw() -> void:
	var mounts := {"l": [Vector2(-19, 6), Vector2(-1, 0)], "r": [Vector2(19, 6), Vector2(1, 0)]}
	if quad:
		mounts["f"] = [Vector2(0, -26), Vector2(0, -1)]
		mounts["b"] = [Vector2(0, 22), Vector2(0, 1)]
	for k in mounts.keys():
		var base: Vector2 = mounts[k][0]
		var d: Vector2 = mounts[k][1]
		var rc: float = float(_recoil.get(k, 0.0))
		var p := Vector2(-d.y, d.x)
		draw_circle(base, 5.0, Color(0.06, 0.07, 0.1))
		draw_arc(base, 5.0, 0.0, TAU, 12, Color(1.0, 0.75, 0.3, 0.8), 1.2)
		var barrel := base + d * (9.0 - rc * 4.0)
		draw_line(base + p * 2.0, barrel + p * 2.0, Color(0.85, 0.7, 0.45), 2.2)
		draw_line(base - p * 2.0, barrel - p * 2.0, Color(0.85, 0.7, 0.45), 2.2)
		if rc > 0.0:
			draw_circle(barrel + d * 3.0, 4.0 * rc, Color(1.0, 0.9, 0.5, rc))
