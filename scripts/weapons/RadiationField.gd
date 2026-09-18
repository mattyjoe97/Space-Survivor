extends WeaponBase
## AURA — persistent toxic field. Enemies inside get irradiated (keeps ticking after they leave).
## L5: irradiated enemies burst into fallout clouds on death.

var _field: Node2D = null

func on_level_changed(_old: int, new_lv: int) -> void:
	if new_lv > 0 and _field == null:
		_field = Node2D.new()
		_field.set_script(load("res://scripts/weapons/fx/RadiationAura.gd"))
		_field.z_index = 2
		add_child(_field)
	if _field:
		_field.visible = new_lv > 0 and not suppressed

func on_suppressed(on: bool) -> void:
	if _field:
		_field.visible = not on

func radius() -> float:
	return (105.0 + level * 14.0) * area_mult()

func cooldown() -> float:
	return maxf(0.22, 0.42 - level * 0.035)

func tick(delta: float) -> void:
	if _field:
		_field.radius = radius()
		_field.intensity = float(level) / 5.0
	super.tick(delta)

func fire() -> void:
	var r := radius()
	var dose := dmg(0.16 + level * 0.035)
	for e in in_radius(player.global_position, r):
		hit(e, dose, id, false, false)
		if level >= 3:
			status(e, "irradiated", 2.0 + level * 0.3, dmg(0.06 + level * 0.012))
		if is_max():
			var h := StatusHost.get_or_create(e)
			if h:
				h.fallout_on_death = true
	if randf() < 0.25:
		VFX.radiation_pulse(player.global_position, r)
