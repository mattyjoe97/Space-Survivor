extends Node2D
## Graviton mine: drift -> arm (blink) -> pull -> (singularity) -> detonate.
var velocity := Vector2.ZERO
var weapon: WeaponBase = null
var pull_radius := 140.0
var blast_radius := 80.0
var pull_strength := 150.0
var arm_time := 0.6
var pull_time := 1.2
var damage := 20.0
var singularity := false
var color := Color(0.75, 0.5, 1.0)
var _t := 0.0
var _state := "drift"
var _state_t := 0.0
var _spin := 0.0

func _ready() -> void:
	z_index = 7
	_spin = randf() * TAU

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	_t += delta
	_state_t += delta
	_spin += delta * (1.5 if _state != "pull" else 6.0)
	match _state:
		"drift":
			global_position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
			if _state_t >= arm_time:
				_set_state("pull")
				AudioManager.play("mine", 1.4, -10.0)
		"pull":
			var strength := pull_strength * (1.0 if not singularity else 1.0 + _state_t * 0.6)
			for e in GameManager.get_enemies():
				if not is_instance_valid(e) or not (e is CharacterBody2D):
					continue
				var d := global_position.distance_to(e.global_position)
				if d < pull_radius:
					PullSafety.pull(e, global_position, strength, delta, 0.5 + 0.5 * (1.0 - d / pull_radius))
			if _state_t >= pull_time:
				if singularity:
					_set_state("collapse")
					VFX.postfx_punch(0.3)
				else:
					_detonate()
		"collapse":
			for e in GameManager.get_enemies():
				if is_instance_valid(e) and e is CharacterBody2D:
					if global_position.distance_to(e.global_position) < pull_radius * 1.6:
						PullSafety.pull(e, global_position, 520.0, delta)
			if _state_t >= 0.5:
				_detonate()
	queue_redraw()

func _set_state(s: String) -> void:
	_state = s
	_state_t = 0.0

func _detonate() -> void:
	VFX.explosion(global_position, blast_radius, Color(color.r, color.g, color.b, 0.85))
	WeaponFX.pulse(global_position, 8.0, blast_radius * 1.4, color, 0.4, 10.0)
	AudioManager.play("explode", 0.85 if not singularity else 0.6, -5.0)
	if singularity:
		VFX.shockwave(global_position, blast_radius * 2.2, Color(1, 1, 1, 0.8), 4.0, 0.45)
		VFX.screen_shake(5.0)
	if weapon:
		var now := Time.get_ticks_msec()
		for e in weapon.in_radius(global_position, blast_radius * (1.35 if singularity else 1.0)):
			# Overlap protection: a clump dragged into several mines takes one blast at a
			# time, not four stacked ones (this stacking was the 75% damage-share outlier).
			if e.has_meta("mine_hit_ms") and now - int(e.get_meta("mine_hit_ms")) < 450:
				continue
			e.set_meta("mine_hit_ms", now)
			weapon.hit(e, damage * (1.3 if singularity else 1.0))
			if e is CharacterBody2D:
				e.global_position += (e.global_position - global_position).normalized() * 30.0
	queue_free()

func _draw() -> void:
	var blink := fmod(_t, 0.5) < 0.25
	match _state:
		"drift":
			draw_circle(Vector2.ZERO, 9.0, Color(0.1, 0.05, 0.18))
			for i in range(8):
				var d := Vector2.from_angle(_spin + i * TAU / 8.0)
				draw_line(d * 8.0, d * 14.0, color, 2.0)
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 16, color, 1.5)
			draw_circle(Vector2.ZERO, 3.0, Color(1, 0.4, 0.4) if blink else Color(0.4, 0.2, 0.3))
		"pull":
			var k := clampf(_state_t / pull_time, 0.0, 1.0)
			draw_circle(Vector2.ZERO, pull_radius, Color(color.r, color.g, color.b, 0.03))
			for j in range(2):
				var rr := pull_radius * (1.0 - fmod(_t * 0.9 + j * 0.5, 1.0))
				draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.45 * (rr / pull_radius)), 1.5)
			for i in range(6):
				var a := _spin + i * TAU / 6.0
				draw_line(Vector2.from_angle(a) * pull_radius * 0.9, Vector2.from_angle(a + 0.9) * 12.0, Color(color.r, color.g, color.b, 0.35), 1.0)
			draw_circle(Vector2.ZERO, 11.0 + k * 4.0, Color(0.1, 0.05, 0.18))
			for i in range(8):
				var d := Vector2.from_angle(_spin + i * TAU / 8.0)
				draw_line(d * 9.0, d * 16.0, color, 2.0)
			draw_circle(Vector2.ZERO, 4.0 + sin(_t * 20.0) * 1.5, Color(1, 1, 1, 0.95))
		"collapse":
			var k := clampf(_state_t / 0.5, 0.0, 1.0)
			draw_circle(Vector2.ZERO, pull_radius * 1.6 * (1.0 - k), Color(color.r, color.g, color.b, 0.10))
			draw_circle(Vector2.ZERO, 26.0 * (1.0 - k * 0.5), Color(0.02, 0.0, 0.05, 1.0))
			draw_arc(Vector2.ZERO, 30.0 * (1.0 - k * 0.4), _spin * 3.0, _spin * 3.0 + 4.0, 24, Color(1, 0.85, 1.0, 0.9), 2.5)
			draw_arc(Vector2.ZERO, 38.0 * (1.0 - k * 0.4), -_spin * 2.0, -_spin * 2.0 + 3.0, 24, Color(color.r, color.g, color.b, 0.8), 2.0)
