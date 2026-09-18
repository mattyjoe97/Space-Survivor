extends Area2D

## Fly close and stay in range to harvest XP + scrap

var harvest_progress: float = 0.0
var harvest_time: float = 2.8
var harvested: bool = false
var player_in_range: bool = false

@onready var body: Polygon2D = $Body
@onready var ring: Polygon2D = $Ring
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("planets")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var hues = [
		Color(0.3, 0.6, 1.0), Color(0.4, 0.9, 0.5),
		Color(0.95, 0.55, 0.3), Color(0.7, 0.4, 0.95)
	]
	body.color = hues[randi() % hues.size()]
	ring.color = body.color.lightened(0.3)
	ring.color.a = 0.35
	label.text = "HARVEST"
	label.visible = false

func _process(delta: float) -> void:
	if harvested or GameManager.is_paused or GameManager.is_game_over:
		return
	ring.rotation += delta * 0.6
	if player_in_range and is_instance_valid(GameManager.player):
		harvest_progress += delta
		label.visible = true
		label.text = "HARVEST %.0f%%" % (harvest_progress / harvest_time * 100.0)
		if harvest_progress >= harvest_time:
			_complete_harvest()
	else:
		harvest_progress = max(0.0, harvest_progress - delta * 0.5)
		if harvest_progress <= 0.0:
			label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body == GameManager.player:
		player_in_range = false

func _complete_harvest() -> void:
	harvested = true
	label.text = "DONE"
	if GameManager.player and GameManager.player.has_method("add_xp"):
		GameManager.player.add_xp(35.0 + GameManager.game_time * 0.05)
	GameManager.add_scrap(18 + int(GameManager.game_time / 40.0))
	GameManager.add_score(120)
	GameManager.planets_harvested += 1
	GameManager.update_mission("planets", 1)
	# Small chance of free relic
	if randf() < 0.12 + GameManager.player_luck * 0.002:
		var relic = GameManager.get_random_relic()
		if not relic.is_empty():
			GameManager.gain_relic(relic.id)
	# Fade out
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
