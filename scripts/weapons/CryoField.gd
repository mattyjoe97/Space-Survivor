extends WeaponBase
## CONTROL — cold pulses that slow enemies and build freeze; frozen enemies are locked.
## L3: frozen enemies take +25%. L5: frozen enemies shatter on death, chilling neighbours.

var _aura: Node2D = null

func on_level_changed(_old: int, new_lv: int) -> void:
	if new_lv > 0 and _aura == null:
		_aura = Node2D.new()
		_aura.set_script(load("res://scripts/weapons/fx/CryoAura.gd"))
		add_child(_aura)
	if _aura:
		_aura.visible = new_lv > 0 and not suppressed

func on_suppressed(on: bool) -> void:
	if _aura:
		_aura.visible = not on

func radius() -> float:
	return (140.0 + level * 16.0) * area_mult()

func cooldown() -> float:
	return maxf(0.32, 0.62 - level * 0.05)

func tick(delta: float) -> void:
	if _aura:
		_aura.radius = radius()
	super.tick(delta)

func fire() -> void:
	var r := radius()
	sfx("freeze", 1.0 + randf_range(-0.05, 0.05), -11.0)
	WeaponFX.pulse(player.global_position, 20.0, r, Color(0.6, 0.9, 1.0), 0.45, 10.0)
	if _aura:
		_aura.pulse()
	var pulse_damage := dmg(0.22 + level * 0.05)
	for e in in_radius(player.global_position, r):
		hit(e, pulse_damage, id, false, false)
		if e.has_method("apply_freeze_progress"):
			e.apply_freeze_progress(0.5 + level * 0.06, maxf(1.2, 2.6 - level * 0.25) * float(player.duration_mult))
		if "chill_timer" in e:
			e.chill_timer = 0.8
			e.chill_factor = 0.62 - level * 0.04
		if level >= 3:
			status(e, "chilled", 1.0, 0.25)
		if is_max():
			var h := StatusHost.get_or_create(e)
			if h:
				h.shatter_on_death = true
