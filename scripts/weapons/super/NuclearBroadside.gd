extends SuperWeaponBase
## RADIATION FIELD + SIDE BATTERIES: quad fission shells that leave fallout zones; the aura blooms.
var _aura: Node2D = null
var _burst_left := 0
var _burst_t := 0.0
var _aura_tick := 0.0

func on_activated() -> void:
	_aura = Node2D.new()
	_aura.set_script(load("res://scripts/weapons/fx/RadiationAura.gd"))
	_aura.z_index = 2
	add_child(_aura)

func _radius() -> float:
	return 200.0 * area_mult()

func cooldown() -> float:
	return 1.4

func fire() -> void:
	_burst_left = 3
	_burst_t = 0.0

func tick(delta: float) -> void:
	if _aura == null:
		on_activated()
	_aura.radius = _radius()
	_aura.intensity = 1.0
	_aura_tick -= delta
	if _aura_tick <= 0.0:
		_aura_tick = 0.3
		for e in in_radius(player.global_position, _radius()):
			hit(e, dmg(0.3), id, false, false)
			status(e, "irradiated", 3.0, dmg(0.1))
			var h := StatusHost.get_or_create(e)
			if h:
				h.fallout_on_death = true
		if randf() < 0.3:
			VFX.radiation_pulse(player.global_position, _radius())
	if _burst_left > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst_t = 0.12
			_burst_left -= 1
			_volley()
		return
	super.tick(delta)

func _volley() -> void:
	var fwd := Vector2.from_angle(player.rotation - PI / 2.0)
	var right := Vector2(-fwd.y, fwd.x)
	for d: Vector2 in [right, -right, fwd, -fwd]:
		var pos: Vector2 = player.global_position + d * 22.0
		var p: Area2D = player._spawn_proj(pos, d.rotated(randf_range(-0.05, 0.05)), dmg(1.1), int(player.pierce), 1.5, id)
		if p:
			p.speed = player.projectile_speed * 0.95
			p.lifetime = 1.3
			p.knockback = 26.0
			p.explode = true
			p.explode_radius = 60.0 * area_mult()
			p.explode_damage = dmg(0.8) * player.explode_damage_mult
			var poly: Polygon2D = p.get_node_or_null("Polygon2D")
			if poly:
				poly.color = Color(0.7, 1.0, 0.45)
				p.get_node("Glow").color = Color(0.4, 1.0, 0.3, 0.5)
			var w := self
			p.on_hit = func(_proj, body):
				VFX.fallout_cloud(body.global_position, 62.0 * w.area_mult(), w.dmg(0.35), 3.0, w.id)
		VFX.muzzle_flash(pos, d, Color(0.7, 1.0, 0.45), 1.3)
	sfx("shoot", 0.5, -4.0)
	VFX.screen_shake(1.5)
