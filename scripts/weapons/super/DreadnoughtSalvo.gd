extends SuperWeaponBase
## HUNTER MISSILES + TORPEDO BAY: a rolling 8-warhead homing torpedo salvo that carpet-bombs.
var _salvo_left := 0
var _salvo_timer := 0.0
var _side := 1.0
var _hatch: Node2D = null
var _missile_t := 0.0

func on_activated() -> void:
	_hatch = Node2D.new()
	_hatch.set_script(load("res://scripts/weapons/fx/SalvoHatch.gd"))
	_hatch.z_index = 3
	add_child(_hatch)

func cooldown() -> float:
	return 2.8

func fire() -> void:
	_salvo_left = 8 + part_a.extra() + part_b.extra()
	_salvo_timer = 0.0
	sfx("torpedo", 0.8, -2.0)
	VFX.shockwave(player.global_position, 90.0, super_color(), 3.0, 0.3)
	if _hatch:
		_hatch.open = 1.0

func tick(delta: float) -> void:
	if _salvo_left > 0:
		_salvo_timer -= delta
		if _salvo_timer <= 0.0:
			_salvo_timer = 0.09
			_salvo_left -= 1
			_launch()
		return
	if _hatch:
		_hatch.open = maxf(0.0, _hatch.open - delta * 2.0)
	# Between salvos the launcher keeps a stream of hunter missiles going.
	_missile_t -= delta
	if _missile_t <= 0.0:
		_missile_t = 1.0
		var a := aim()
		for i in range(3):
			var d: Vector2 = a[1].rotated((i - 1) * 0.5)
			var pr: Area2D = player._spawn_proj(player.global_position, d, dmg(1.3), int(player.pierce), 1.1, id)
			if pr:
				pr.homing_enabled = true
				pr.homing_turn_rate = 5.0
				pr.homing_range = 480.0
				pr.homing_target = a[0]
				pr.explode = true
				pr.explode_radius = 42.0 * area_mult()
				pr.explode_damage = dmg(0.6)
	super.tick(delta)

func _launch() -> void:
	_side *= -1.0
	var a := aim()
	var base: Vector2 = a[1]
	var dir := base.rotated(_side * (0.35 + randf() * 0.3))
	var t := Node2D.new()
	t.set_script(load("res://scripts/weapons/fx/Torpedo.gd"))
	t.global_position = player.global_position + Vector2(_side * 18.0, 8.0).rotated(player.rotation)
	t.direction = dir
	t.weapon = self
	t.target = a[0] if is_instance_valid(a[0]) else nearest()
	t.blast_radius = 115.0 * area_mult()
	t.damage = dmg(3.2) * player.explode_damage_mult
	t.accel = 700.0
	t.scale = Vector2(0.8, 0.8) * size_mult()
	t.cluster = true
	t.set_meta("turn", 3.6)
	GameManager.spawn(t)
	VFX.muzzle_flash(t.global_position, dir, Color(1.0, 0.7, 0.35), 0.9)
	sfx("missile", 0.9 + randf() * 0.2, -8.0)
