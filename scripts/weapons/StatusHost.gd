class_name StatusHost
extends Node2D

## Per-enemy status effects (burn, irradiated, phased, chilled). Attaches itself
## to any enemy that has take_damage(), including elites and the boss, and draws
## its own overlay so every enemy type shows the effect.
##  burn:       stacking DoT, strength = damage per tick
##  irradiated: DoT that keeps ticking after leaving the field; L5 fallout burst on death
##  phased:     damage taken multiplier (strength = bonus fraction), purple ring
##  chilled:    damage taken bonus while frozen (strength = bonus fraction)

var effects: Dictionary = {}   # kind -> {"t": remaining, "s": strength, "src": weapon id, "stacks": n}
var _tick := 0.0
var _phase := 0.0
var _host: Node2D = null
var fallout_on_death: bool = false
var shatter_on_death: bool = false

static func get_or_create(e: Node2D) -> StatusHost:
	if not is_instance_valid(e):
		return null
	var h: Node = e.get_node_or_null("StatusHost")
	if h == null:
		h = StatusHost.new()
		h.name = "StatusHost"
		h.z_index = 3
		e.add_child(h)
		h._host = e
	return h as StatusHost

static func apply(e: Node2D, kind: String, duration: float, strength: float, src: String = "") -> void:
	var h := get_or_create(e)
	if h == null:
		return
	var cur: Dictionary = h.effects.get(kind, {"t": 0.0, "s": 0.0, "src": src, "stacks": 0})
	cur["t"] = maxf(float(cur["t"]), duration)
	if kind == "burn":
		cur["stacks"] = mini(int(cur["stacks"]) + 1, 8)
		cur["s"] = maxf(float(cur["s"]), strength)
	else:
		cur["s"] = maxf(float(cur["s"]), strength)
		cur["stacks"] = 1
	cur["src"] = src
	h.effects[kind] = cur
	h.queue_redraw()

static func has(e: Node2D, kind: String) -> bool:
	if not is_instance_valid(e):
		return false
	var h: Node = e.get_node_or_null("StatusHost")
	return h != null and h.effects.has(kind)

static func damage_mult(e: Node2D) -> float:
	if not is_instance_valid(e):
		return 1.0
	var h: Node = e.get_node_or_null("StatusHost")
	if h == null:
		return 1.0
	var m := 1.0
	if h.effects.has("phased"):
		m += float(h.effects["phased"]["s"])
	if h.effects.has("chilled"):
		var ft = e.get("frozen_timer")
		if ft != null and float(ft) > 0.0:
			m += float(h.effects["chilled"]["s"])
	return m

func _ready() -> void:
	_host = get_parent() as Node2D
	if _host and _host.has_signal("tree_exiting"):
		_host.tree_exiting.connect(_on_host_exiting)

func _on_host_exiting() -> void:
	if not is_instance_valid(_host) or not is_inside_tree() or get_tree().paused:
		return
	var hp = _host.get("current_hp")
	if hp == null or float(hp) > 0.0:
		return
	# Death procs.
	if fallout_on_death and effects.has("irradiated"):
		var dps: float = float(effects["irradiated"]["s"])
		VFX.fallout_cloud(_host.global_position, 70.0, dps * 0.6, 2.5)
	if shatter_on_death and effects.has("chilled"):
		var ft = _host.get("frozen_timer")
		if ft != null and float(ft) > 0.0:
			VFX.shatter_burst(_host.global_position, 95.0)
			for e in GameManager.get_enemies():
				if is_instance_valid(e) and e != _host and e.global_position.distance_to(_host.global_position) < 95.0:
					if e.has_method("take_damage"):
						GameManager.record_damage("cryo_field", 18.0)
						e.take_damage(18.0)
					if e.has_method("apply_freeze_progress"):
						e.apply_freeze_progress(0.9, 2.0)

func _process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	if effects.is_empty():
		return
	_phase += delta
	_tick -= delta
	var expired: Array = []
	for kind in effects.keys():
		effects[kind]["t"] = float(effects[kind]["t"]) - delta
		if float(effects[kind]["t"]) <= 0.0:
			expired.append(kind)
	for k in expired:
		effects.erase(k)
	if _tick <= 0.0:
		_tick = 0.4
		if is_instance_valid(_host) and _host.has_method("take_damage"):
			if effects.has("burn"):
				var b: Dictionary = effects["burn"]
				var d: float = float(b["s"]) * (1.0 + 0.35 * (int(b["stacks"]) - 1))
				GameManager.record_damage(str(b["src"]), d)
				_host.take_damage(d)
				if randf() < 0.5:
					VFX.sparks(_host.global_position, 3, Color(1.0, 0.55, 0.15), 60.0, 0.35, Vector2.UP, 60.0)
			if effects.has("irradiated"):
				var r: Dictionary = effects["irradiated"]
				GameManager.record_damage(str(r["src"]), float(r["s"]))
				_host.take_damage(float(r["s"]))
	queue_redraw()

func _draw() -> void:
	if effects.has("burn"):
		var st: int = int(effects["burn"]["stacks"])
		for i in range(mini(st, 5) + 1):
			var a := _phase * 9.0 + i * 1.7
			var p := Vector2(sin(a) * 8.0 + (i - 2) * 4.0, -6.0 - fmod(a, 2.0) * 7.0)
			var life := 1.0 - fmod(a, 2.0) / 2.0
			draw_circle(p, 3.5 * life + 1.0, Color(1.0, 0.55 * life + 0.2, 0.1, 0.75 * life))
		draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.45, 0.1, 0.08))
	if effects.has("irradiated"):
		draw_circle(Vector2.ZERO, 21.0, Color(0.4, 1.0, 0.35, 0.12 + 0.05 * sin(_phase * 6.0)))
		for i in range(3):
			var a := _phase * 2.5 + i * TAU / 3.0
			draw_circle(Vector2.from_angle(a) * 15.0, 2.0, Color(0.6, 1.0, 0.4, 0.9))
	if effects.has("phased"):
		var r := 22.0 + sin(_phase * 7.0) * 2.0
		draw_arc(Vector2.ZERO, r, _phase * 4.0, _phase * 4.0 + 4.2, 20, Color(0.85, 0.45, 1.0, 0.8), 2.0)
		draw_arc(Vector2.ZERO, r - 5.0, -_phase * 5.0, -_phase * 5.0 + 3.0, 16, Color(1.0, 0.8, 1.0, 0.5), 1.2)
	if effects.has("chilled"):
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 20, Color(0.7, 0.95, 1.0, 0.35), 1.0)
