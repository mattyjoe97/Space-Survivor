extends Node2D
var velocity := Vector2.ZERO
var weapon: WeaponBase = null
var radius := 50.0
var damage := 15.0
var _t := 0.0
func _ready() -> void:
	z_index = 8
func _process(delta: float) -> void:
	_t += delta
	global_position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	if _t > 0.45:
		VFX.explosion(global_position, radius, Color(1.0, 0.6, 0.3, 0.85))
		AudioManager.play("explode", 1.2, -7.0)
		if weapon:
			for e in weapon.in_radius(global_position, radius):
				weapon.hit(e, damage)
		queue_free()
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(0.6, 0.6, 0.66))
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.3, 0.2) if fmod(_t, 0.1) < 0.05 else Color(0.4, 0.2, 0.2))
