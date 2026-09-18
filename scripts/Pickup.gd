extends Area2D
## Heal / magnet pickups. They drift toward the player once inside their own
## interaction radius and collect on contact. Elite magnets get a distinct look,
## a bigger interaction radius, a drop label and heavier collect feedback.

enum Type { HEAL, VACUUM }

var pickup_type: Type = Type.HEAL
var elite: bool = false
var collected := false
var attracting := false
var boosted := false
var speed := 0.0
var _t := 0.0

@onready var poly: Polygon2D = $Poly

func interact_radius() -> float:
	if pickup_type == Type.HEAL:
		return 80.0
	return 170.0 if elite else 110.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	var vfx = Node2D.new()
	vfx.set_script(preload("res://scripts/PickupVFX.gd"))
	vfx.kind = "heal" if pickup_type == Type.HEAL else ("elite_magnet" if elite else "vacuum")
	vfx.position = Vector2.ZERO
	add_child(vfx)
	# All pickup bodies are drawn procedurally by PickupVFX (3.16.3); the scene polys are legacy.
	poly.visible = false
	$Inner.visible = false
	z_index = 7
	match pickup_type:
		Type.HEAL:
			pass
		Type.VACUUM:
			if elite:
				_spawn_drop_label()
				VFX.shockwave(global_position, 90.0, Color(1.0, 0.45, 1.0, 0.9), 3.0, 0.4)
				VFX.sparks(global_position, 14, Color(1.0, 0.6, 1.0), 160.0, 0.5)
				AudioManager.play("phase", 0.8, -6.0)

func _spawn_drop_label() -> void:
	var lbl := Label.new()
	lbl.text = "MAGNET"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.0, 0.2))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-28, -44)
	lbl.z_index = 30
	add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", -60.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(1.4)
	tw.chain().tween_callback(lbl.queue_free)

## Called by the player's magnet sweep so heal/magnet pickups are vacuumed too.
func start_attract(_p: Node2D, boost: bool = false) -> void:
	attracting = true
	boosted = boosted or boost

func collect_now() -> void:
	if is_instance_valid(GameManager.player):
		collect(GameManager.player)

func _physics_process(delta: float) -> void:
	if collected:
		return
	_t += delta
	var p = GameManager.player
	if not is_instance_valid(p):
		return
	var d := global_position.distance_to(p.global_position)
	if not attracting and d <= interact_radius():
		attracting = true
	if attracting:
		speed = minf(speed + (1600.0 if boosted else 900.0) * delta, 1050.0 if boosted else 520.0)
		global_position += (p.global_position - global_position).normalized() * speed * delta
		if d < 26.0:
			collect(p)
	elif elite:
		# Hover bob so it reads as "alive".
		position.y += sin(_t * 4.0) * 0.12

func collect(player: Node2D) -> void:
	if collected:
		return
	collected = true
	var kind := "heal" if pickup_type == Type.HEAL else "vacuum"
	VFX.pickup_collect(global_position, kind, 1.6 if elite else 1.25)
	AudioManager.play("pickup_heal" if pickup_type == Type.HEAL else "pickup_xp", 1.05, -6.0)
	if pickup_type == Type.HEAL:
		VFX.ring_burst(global_position, 44.0, Color(0.3, 1.0, 0.5, 0.55))
	else:
		VFX.ring_burst(global_position, 64.0, Color(0.35, 0.85, 1.0, 0.55))
		if elite:
			VFX.shockwave(global_position, 160.0, Color(1.0, 0.5, 1.0, 0.9), 4.0, 0.45)
			VFX.sparks(global_position, 24, Color(1.0, 0.7, 1.0), 260.0, 0.5)
			VFX.screen_flash(Color(0.8, 0.4, 1.0, 0.18), 0.25)
			AudioManager.play("synergy", 1.2, -4.0)
	match pickup_type:
		Type.HEAL:
			if player.has_method("heal"):
				player.heal(28.0)
		Type.VACUUM:
			if player.has_method("activate_vacuum"):
				player.activate_vacuum(5.0, elite)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		collect(body)
