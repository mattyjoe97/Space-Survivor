class_name WeaponBase
extends Node2D

## Base class for every weapon module. Lives under Player/Weapons so local
## coordinates follow the ship. Subclasses override cooldown(), fire(),
## and optionally tick(), on_level_changed(), on_suppressed().

var id: String = ""
var level: int = 0
var timer: float = 0.0
var player: CharacterBody2D = null
var manager: Node = null
## True while a superweapon has absorbed this weapon; normal firing stops.
var suppressed: bool = false

func setup(p: CharacterBody2D, m: Node, wid: String) -> void:
	player = p
	manager = m
	id = wid
	name = wid

func set_level(lv: int) -> void:
	var old := level
	level = lv
	if old == 0 and lv > 0:
		timer = 0.25
	on_level_changed(old, lv)

func on_level_changed(_old: int, _new: int) -> void:
	pass

func on_suppressed(_on: bool) -> void:
	pass

func cooldown() -> float:
	return 1.0

func fire() -> void:
	pass

func tick(delta: float) -> void:
	if level <= 0 or suppressed:
		return
	timer -= delta
	if timer <= 0.0:
		fire()
		timer = cooldown()

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

func is_max() -> bool:
	return level >= GameManager.MAX_WEAPON_LEVEL

func extra() -> int:
	return int(player.extra_projectiles_by_weapon.get(id, 0))

func area_mult() -> float:
	return player.aura_radius / 112.0

func size_mult() -> float:
	return player.proj_scale

func dmg(mult: float) -> float:
	return player.damage * mult

func enemies() -> Array:
	var out: Array = []
	for e in GameManager.get_enemies():
		if is_instance_valid(e):
			out.append(e)
	return out

func nearest(max_range: float = INF, exclude: Array = [], origin: Vector2 = Vector2.INF) -> Node2D:
	if origin == Vector2.INF:
		origin = player.global_position
	var best: Node2D = null
	var best_d := max_range * max_range
	for e in enemies():
		if e in exclude:
			continue
		var d := origin.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func in_radius(center: Vector2, r: float) -> Array:
	var out: Array = []
	for e in enemies():
		if center.distance_to(e.global_position) <= r:
			out.append(e)
	return out

func in_line(origin: Vector2, dir: Vector2, reach: float, half_width: float) -> Array:
	var out: Array = []
	for e in enemies():
		var rel: Vector2 = e.global_position - origin
		var along := rel.dot(dir)
		if along < 0.0 or along > reach:
			continue
		if absf(rel.cross(dir)) <= half_width + 12.0:
			out.append(e)
	return out

func manual() -> bool:
	return player._is_manual_aim()

func aim_dir() -> Vector2:
	return player._get_aim_direction(player.rotation - PI / 2.0)

## Returns [target_or_null, direction]. Honors manual / auto aim settings.
func aim() -> Array:
	var d := aim_dir()
	if manual():
		var t: Node2D = player._get_manual_target(player.global_position, d)
		return [t, d]
	var t2 := nearest()
	if t2:
		return [t2, (t2.global_position - player.global_position).normalized()]
	return [null, d]

func roll_crit() -> bool:
	return player.crit_chance > 0.0 and randf() < player.crit_chance

## Apply damage with crit roll, status multipliers and damage attribution.
func hit(e: Node2D, amount: float, src: String = "", force_crit: bool = false, allow_crit: bool = true) -> float:
	if not is_instance_valid(e) or not e.has_method("take_damage"):
		return 0.0
	var crit := force_crit or (allow_crit and roll_crit())
	var final := amount * (2.0 if crit else 1.0) * StatusHost.damage_mult(e)
	GameManager.record_damage(src if src != "" else id, final)
	e.take_damage(final, crit)
	return final

func status(e: Node2D, kind: String, duration: float, strength: float) -> void:
	StatusHost.apply(e, kind, duration, strength, id)

func sfx(kind: String, pitch: float = 1.0, vol: float = -6.0) -> void:
	AudioManager.play(kind, pitch, vol)

func color() -> Color:
	return GameManager.WEAPON_DEFS.get(id, {}).get("color", Color.WHITE)

## Spawns a free-floating Node2D in the world (not parented to the ship).
func world_node(at: Vector2, z: int = 5) -> Node2D:
	var n := Node2D.new()
	n.global_position = at
	n.z_index = z
	GameManager.spawn(n)
	return n
