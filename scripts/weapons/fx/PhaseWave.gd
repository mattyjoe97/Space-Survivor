extends Node2D
## Travelling crescent wave; passes through enemies and marks them.
var direction := Vector2.RIGHT
var weapon: WeaponBase = null
var half_width := 40.0
var reach := 520.0
var damage := 10.0
var mark_time := 3.0
var mark_bonus := 0.2
var shove := 0.0
var rift := false
var _travelled := 0.0
var _speed := 620.0
var _t := 0.0
var _hit: Array = []

func _ready() -> void:
	z_index = 20
	rotation = direction.angle()

func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	_t += delta
	var step := _speed * delta
	global_position += direction * step
	_travelled += step
	if weapon:
		for e in weapon.enemies():
			if e in _hit:
				continue
			var rel: Vector2 = e.global_position - global_position
			var along := rel.dot(direction)
			if along > -8.0 and along < step + 8.0 and absf(rel.cross(direction)) <= half_width + 12.0:
				_hit.append(e)
				weapon.hit(e, damage)
				weapon.status(e, "phased", mark_time, mark_bonus)
				VFX.hit(e.global_position, false, Color(0.85, 0.45, 1.0, 0.95))
				if shove > 0.0 and e is CharacterBody2D:
					e.global_position += direction * shove
				# Void Artillery: a targeting reticle on the marked enemy, then a Void Spike.
				VoidReticle.try_place(e, weapon, damage * (0.9 if rift else 0.55), 75.0 if rift else 55.0, 0.55, 30.0 if rift else 20.0)
	if _travelled >= reach:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var f: float = 1.0 - clampf(_travelled / reach, 0.0, 1.0)
	var pts := PackedVector2Array()
	var n := 12
	for i in range(n + 1):
		var k := float(i) / float(n) * 2.0 - 1.0
		pts.append(Vector2(-k * k * 14.0, k * half_width))
	draw_polyline(pts, Color(0.85, 0.45, 1.0, 0.25 * f + 0.1), 18.0)
	draw_polyline(pts, Color(0.85, 0.45, 1.0, 0.85 * f + 0.1), 5.0)
	draw_polyline(pts, Color(1.0, 0.9, 1.0, 0.9 * f), 1.8)
	# Trailing ghost copies
	for g in range(3):
		var off := Vector2(-16.0 * (g + 1), 0)
		var gp := PackedVector2Array()
		for q in pts:
			gp.append(q + off)
		draw_polyline(gp, Color(0.7, 0.4, 1.0, (0.25 - g * 0.07) * f), 3.0 - g * 0.6)
	# Distortion ticks
	for i in range(5):
		var y := (float(i) / 4.0 * 2.0 - 1.0) * half_width * 0.8
		var x := sin(_t * 30.0 + i) * 4.0
		draw_line(Vector2(x - 6, y), Vector2(x + 6, y), Color(1, 1, 1, 0.5 * f), 1.0)
