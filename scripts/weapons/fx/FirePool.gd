extends Node2D
## Burning ground left by the Plasma Flamethrower at max level.
var weapon: WeaponBase = null
var radius := 40.0
var damage := 3.0
var life := 2.5
var _t := 0.0
var _tick := 0.0
var _tongues: Array = []
func _ready() -> void:
	z_index = 4
	for i in range(8):
		_tongues.append([randf() * TAU, randf_range(0.3, 0.9), randf() * TAU])
func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	_t += delta
	life -= delta
	_tick -= delta
	if _tick <= 0.0 and weapon:
		_tick = 0.3
		for e in weapon.in_radius(global_position, radius):
			weapon.hit(e, damage, weapon.id, false, false)
			weapon.status(e, "burn", 1.5, damage * 0.8)
	if life <= 0.0:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var a := clampf(life / 0.6, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.4, 0.1, 0.12 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(1.0, 0.55, 0.15, 0.5 * a), 1.5)
	for tg in _tongues:
		var p: Vector2 = Vector2.from_angle(float(tg[0])) * radius * float(tg[1])
		var h: float = 8.0 + 6.0 * sin(_t * 12.0 + float(tg[2]))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(0, -h)]), Color(1.0, 0.6, 0.2, 0.8 * a))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(0, -h * 0.55)]), Color(1.0, 0.95, 0.6, 0.9 * a))
