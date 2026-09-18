extends Node2D
## Acid pool left by Void Spitter blobs: standing in it hurts. Rewards moving.
var radius := 34.0
var damage_per_second := 6.0
var life := 2.4
var _t := 0.0
var _tick := 0.0
func _ready() -> void:
	z_index = 3
	add_to_group("enemy_bullets")
func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	_t += delta
	life -= delta
	_tick -= delta
	var p = GameManager.player
	if _tick <= 0.0 and is_instance_valid(p) and p.global_position.distance_to(global_position) <= radius + 10.0:
		_tick = 0.4
		if p.has_method("take_damage"):
			p.take_damage(damage_per_second * 0.4)
	if life <= 0.0:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var a := clampf(life / 0.5, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.2, 0.9, 0.16 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.4, 1.0, 0.6 * a), 1.5)
	for i in range(4):
		var ang := _t * 2.0 + i * TAU / 4.0
		draw_circle(Vector2.from_angle(ang) * radius * 0.5, 2.5 + sin(_t * 9.0 + i) * 1.0, Color(1.0, 0.7, 1.0, 0.7 * a))
