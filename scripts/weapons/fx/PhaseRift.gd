extends Node2D
## A rift left behind by max-level Phase Disruptor: pulses damage 3 times then closes.
var weapon: WeaponBase = null
var damage := 6.0
var pull := 0.0
var _t := 0.0
var _pulses := 0
var _next := 0.35
func _ready() -> void:
	z_index = 5
func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	_t += delta
	if pull > 0.0 and weapon:
		for e in weapon.in_radius(global_position, 120.0):
			PullSafety.pull(e, global_position, pull, delta)
	if _t >= _next:
		_next += 0.45
		_pulses += 1
		WeaponFX.pulse(global_position, 6.0, 70.0, Color(0.85, 0.45, 1.0), 0.3, 6.0)
		AudioManager.play("phase", 1.5, -12.0)
		if weapon:
			for e in weapon.in_radius(global_position, 70.0):
				weapon.hit(e, damage)
		if _pulses >= 2:
			VFX.sparks(global_position, 8, Color(0.9, 0.6, 1.0), 120.0, 0.35)
			queue_free()
	queue_redraw()
func _draw() -> void:
	var a := 0.6 + 0.4 * sin(_t * 12.0)
	draw_circle(Vector2.ZERO, 9.0, Color(0.05, 0.0, 0.1, 0.95))
	draw_arc(Vector2.ZERO, 12.0, _t * 6.0, _t * 6.0 + 3.5, 16, Color(0.85, 0.45, 1.0, a), 2.0)
	draw_arc(Vector2.ZERO, 17.0, -_t * 4.0, -_t * 4.0 + 2.5, 16, Color(1.0, 0.85, 1.0, a * 0.7), 1.4)
	for i in range(4):
		var d := Vector2.from_angle(_t * 3.0 + i * PI / 2.0)
		draw_line(d * 9.0, d * (20.0 + sin(_t * 15.0 + i) * 4.0), Color(0.9, 0.6, 1.0, 0.6), 1.0)
