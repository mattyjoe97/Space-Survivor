extends Node2D
## Pale frost field with drifting snow crystals and a breath pulse.
var radius := 150.0
var _t := 0.0
var _pulse := 0.0
var _flakes: Array = []
func _ready() -> void:
	top_level = true
	z_index = 2
	for i in range(22):
		_flakes.append([randf() * TAU, randf_range(0.15, 0.95), randf_range(0.3, 1.2), randf() * TAU])
func pulse() -> void:
	_pulse = 1.0
func _process(delta: float) -> void:
	_t += delta
	_pulse = maxf(0.0, _pulse - delta * 2.5)
	var p := get_parent()
	if p and p.get("player") != null and is_instance_valid(p.player):
		global_position = p.player.global_position
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.85, 1.0, 0.05 + _pulse * 0.05))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.7, 0.95, 1.0, 0.3 + _pulse * 0.4), 1.5 + _pulse * 2.0)
	for i in range(6):
		var a := i * TAU / 6.0 + _t * 0.15
		draw_line(Vector2.from_angle(a) * radius * 0.92, Vector2.from_angle(a) * radius * 1.04, Color(0.8, 0.97, 1.0, 0.5), 1.5)
	for fl in _flakes:
		var ang: float = fl[0] + _t * 0.25 * fl[2]
		var r: float = radius * fl[1]
		var p := Vector2.from_angle(ang) * r
		var rot: float = fl[3] + _t
		for k in range(3):
			var d := Vector2.from_angle(rot + k * PI / 3.0) * 3.0
			draw_line(p - d, p + d, Color(0.85, 0.97, 1.0, 0.7), 1.0)
