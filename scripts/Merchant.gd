extends Area2D

## Approach and press interact / auto-open shop when close

var shop_open: bool = false
var used: bool = false

@onready var body: Polygon2D = $Body
@onready var label: Label = $Label

signal shop_requested(merchant: Node)

func _ready() -> void:
	add_to_group("merchants")
	body_entered.connect(_on_body_entered)
	label.text = "MERCHANT [E]"
	label.visible = false

func _process(_delta: float) -> void:
	if used:
		return
	if label.visible and Input.is_action_just_pressed("ui_accept"):
		_open_shop()
	# Also open automatically after brief presence
	if label.visible and not shop_open:
		pass

func _on_body_entered(body: Node2D) -> void:
	if used:
		return
	if body.is_in_group("player") or body == GameManager.player:
		label.visible = true
		_open_shop()

func _open_shop() -> void:
	if used or shop_open:
		return
	shop_open = true
	GameManager.is_paused = true
	get_tree().paused = true
	# UI will show shop via signal / direct call
	var ui = get_tree().root.get_node_or_null("Main/UI")
	if ui and ui.has_method("show_merchant_shop"):
		ui.show_merchant_shop(self)

func close_and_leave() -> void:
	used = true
	shop_open = false
	label.text = "DEPARTED"
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)
