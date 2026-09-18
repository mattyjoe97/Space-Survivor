class_name DamageNumber
extends Node2D

## Floating combat text.
## 3.17.1 fixes:
##  - numbers keep their spawn position (the old _process overwrote `position` with just the
##    drift offset, so every number drifted to the world origin — the "invisible object")
##  - the active-number pool is counted by a group, not a static counter that never
##    decremented when numbers were purged (which permanently blocked non-crit numbers)
##  - hits landing on the same spot within a short window merge into one rising number,
##    so beams / DoT / high fire rate don't flood the screen

const MAX_ACTIVE := 40
const MERGE_WINDOW := 0.12
const MERGE_DIST := 26.0

var amount: float = 0.0
var critical: bool = false
var is_heal: bool = false
var life := 0.7
var max_life := 0.7
var start_scale := 1.0
var drift := Vector2(0, -34)
var side_drift := 0.0
var label: Label
var base_pos := Vector2.ZERO
var _age := 0.0
var _merge_count := 1

static var _recent: Array = []   # live numbers eligible for merging

func _ready() -> void:
	z_index = 30
	top_level = true
	global_position = base_pos
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-55, -12)
	label.size = Vector2(110, 24)
	label.add_theme_font_size_override("font_size", 18 if critical else 12)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 3)
	if is_heal:
		label.modulate = Color(0.45, 1.0, 0.55)
	elif critical:
		label.modulate = Color(1.0, 0.75, 0.25)
	else:
		label.modulate = Color(0.92, 0.97, 1.0)
	_refresh_text()
	start_scale = 0.55 if critical else 0.7
	scale = Vector2.ONE * start_scale
	side_drift = randf_range(-14.0, 14.0)
	add_child(label)
	var target_scale := 1.35 if critical else 1.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_text() -> void:
	var text := "%d" % int(round(amount))
	if is_heal:
		text = "+" + text
	elif critical:
		text = "CRIT " + text
	if _merge_count > 1 and not critical:
		text += " ×%d" % _merge_count
	label.text = text

func absorb(value: float) -> void:
	amount += value
	_merge_count += 1
	life = max_life
	_age = 0.0
	_refresh_text()
	scale = Vector2.ONE * (1.35 if critical else 1.0) * 1.15

func _process(delta: float) -> void:
	life -= delta
	_age += delta
	var t: float = 1.0 - clampf(life / max_life, 0.0, 1.0)
	var ease_t := 1.0 - pow(1.0 - t, 2.0)
	global_position = base_pos + Vector2(side_drift * ease_t, drift.y * ease_t)
	if critical:
		var pulse := 1.0 + sin((max_life - life) * 18.0) * 0.06
		scale = Vector2.ONE * 1.35 * pulse
	elif scale.x > 1.0:
		scale = scale.move_toward(Vector2.ONE, delta * 2.0)
	label.modulate.a = clampf(life / (max_life * 0.4), 0.0, 1.0)
	if life <= 0.0:
		queue_free()

func _exit_tree() -> void:
	_recent.erase(self)

static func active_count() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	return tree.get_nodes_in_group("damage_numbers").size()

static func spawn(at: Vector2, value: float, is_crit: bool = false, heal: bool = false) -> void:
	if not SettingsManager.damage_numbers:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	# Merge rapid hits on the same spot (beam ticks, DoT, fast weapons) into one number.
	if not is_crit and not heal:
		for n in _recent:
			if is_instance_valid(n) and n.is_inside_tree() and not n.critical and not n.is_heal \
					and n._age <= MERGE_WINDOW and n.base_pos.distance_to(at) <= MERGE_DIST:
				n.absorb(value)
				return
	if active_count() >= MAX_ACTIVE and not is_crit and not heal:
		# Pool full: fold the value into the oldest live number instead of dropping it.
		if not _recent.is_empty() and is_instance_valid(_recent[0]):
			_recent[0].absorb(value)
		return
	var n := DamageNumber.new()
	n.amount = value
	n.critical = is_crit
	n.is_heal = heal
	n.max_life = 0.85 if is_crit else 0.7
	n.life = n.max_life
	n.base_pos = at + Vector2(randf_range(-7.0, 7.0), -10.0)
	n.add_to_group("damage_numbers")
	_recent.append(n)
	while _recent.size() > 64:
		_recent.pop_front()
	GameManager.spawn(n)
