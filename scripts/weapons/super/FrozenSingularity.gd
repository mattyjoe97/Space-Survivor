extends SuperWeaponBase
## GRAVITON MINES + CRYO FIELD: a persistent black hole ahead of the ship that freezes and drags,
## then collapses in a shatter burst and reforms.
var _hole: Node2D = null

func on_activated() -> void:
	_hole = Node2D.new()
	_hole.set_script(load("res://scripts/weapons/fx/BlackHole.gd"))
	_hole.weapon = self
	_hole.global_position = player.global_position + aim_dir() * 210.0
	GameManager.spawn(_hole)

func tick(delta: float) -> void:
	if _hole == null or not is_instance_valid(_hole):
		on_activated()
	var want: Vector2 = player.global_position + aim_dir() * 210.0
	_hole.global_position = _hole.global_position.lerp(want, delta * 2.2)
	_hole.radius = 240.0 * area_mult()

func _exit_tree() -> void:
	if is_instance_valid(_hole):
		_hole.queue_free()
