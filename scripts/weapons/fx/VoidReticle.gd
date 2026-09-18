class_name VoidReticle
extends Node2D
## VOID ARTILLERY reticle. Telegraph on a target, then a Void Spike strikes.
## Lifecycle is explicit and owned here: the reticle frees itself when the spike fires, when the
## target dies / is removed, when the weapon is gone, when the run ends or the player dies, and on
## a hard timeout. It is a run_entity (purged on reset). Active count is capped.
const MAX_ACTIVE := 8
const TIMEOUT := 2.0
static var active: int = 0

var target: Node2D = null
var weapon: WeaponBase = null
var delay := 0.55
var damage := 10.0
var radius := 55.0
var control := 26.0
var _t := 0.0
var _done := false

static func try_place(target_: Node2D, weapon_: WeaponBase, damage_: float, radius_: float, delay_: float = 0.55, control_: float = 26.0) -> bool:
	if active >= MAX_ACTIVE or not is_instance_valid(target_) or target_.has_meta("void_reticle"):
		return false
	var r := Node2D.new()
	r.set_script(load("res://scripts/weapons/fx/VoidReticle.gd"))
	r.target = target_; r.weapon = weapon_; r.damage = damage_; r.radius = radius_; r.delay = delay_; r.control = control_
	r.global_position = target_.global_position
	target_.set_meta("void_reticle", true)
	GameManager.spawn(r)
	return true

func _ready() -> void:
	z_index = 15
	active += 1
	add_to_group("void_reticles")

func _exit_tree() -> void:
	active = maxi(0, active - 1)
	if is_instance_valid(target) and target.has_meta("void_reticle"):
		target.remove_meta("void_reticle")

func _cancel() -> void:
	if _done: return
	_done = true
	queue_free()

func _process(delta: float) -> void:
	if _done: return
	_t += delta
	# Guaranteed removal paths.
	if GameManager.is_game_over or not is_instance_valid(GameManager.player) or GameManager.player.is_dead:
		_cancel(); return
	if not is_instance_valid(weapon) or weapon.level <= 0 or weapon.suppressed and not (weapon is SuperWeaponBase):
		_cancel(); return
	if not is_instance_valid(target) or target.get("_dead") == true or not target.is_inside_tree():
		_cancel(); return
	if _t >= TIMEOUT:
		_cancel(); return
	global_position = target.global_position
	if _t >= delay:
		_strike()
		return
	queue_redraw()

func _strike() -> void:
	_done = true
	var at := global_position
	# Impact: the reticle collapses into the spike; no ring is left behind.
	WeaponFX.pulse(at, 6.0, radius, Color(0.85, 0.45, 1.0), 0.28, 8.0)
	VFX.sparks(at, 8, Color(0.9, 0.6, 1.0), 180.0, 0.35)
	AudioManager.play("phase", 1.3, -9.0)
	if is_instance_valid(weapon):
		for e in weapon.in_radius(at, radius):
			weapon.hit(e, damage)
			var out_dir: Vector2 = (e.global_position - at).normalized() if e.global_position.distance_to(at) > 1.0 else Vector2.RIGHT
			GameManager.player.apply_control(e, out_dir, control, control * 0.6, 4.0, 0.2)
	queue_free()

func _draw() -> void:
	var k := clampf(_t / delay, 0.0, 1.0)
	var col := Color(0.85, 0.45, 1.0)
	var r := lerpf(30.0, 12.0, k)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.5 + k * 0.4), 1.5 + k)
	for i in range(4):
		var a := k * 3.0 + i * PI * 0.5
		var d := Vector2.from_angle(a)
		draw_line(d * (r + 3.0), d * (r + 9.0), Color(1.0, 0.85, 1.0, 0.9), 1.6)
	draw_circle(Vector2.ZERO, 2.0 + k * 3.0, Color(1, 1, 1, 0.6 + k * 0.4))
	# Incoming spike streak in the last third of the delay
	if k > 0.66:
		var s := (k - 0.66) / 0.34
		draw_line(Vector2(0, -160.0 * (1.0 - s)), Vector2(0, -8.0), Color(0.9, 0.6, 1.0, 0.8 * s), 2.5)
