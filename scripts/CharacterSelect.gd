extends Control

var preview: Node2D
var name_label: Label
var role_label: Label
var desc_label: Label
var stats_label: Label
var mastery_label: Label
var back_btn: Button
var launch_btn: Button
var ship_grid: GridContainer
var scrap_label: Label
var stars_node: Node2D

var selected: String = "viper"
var buttons: Dictionary = {}

func _ready() -> void:
	_resolve_ui_nodes()
	_generate_stars()
	if back_btn != null:
		back_btn.pressed.connect(_back)
	if launch_btn != null:
		launch_btn.pressed.connect(_launch)
	for id in GameManager.CHARACTERS.keys():
		_add_ship_card(id)
	_select(GameManager.selected_character)
	_update_scrap()
	if GameManager.scrap_changed.is_connected(_update_scrap) == false:
		GameManager.scrap_changed.connect(_update_scrap)

func _process(_delta: float) -> void:
	_update_scrap()

func _update_scrap(_value: int = -1) -> void:
	if scrap_label != null:
		scrap_label.text = "SCRAP  %d" % GameManager.banked_scrap

func _resolve_ui_nodes() -> void:
	preview = get_node_or_null("HangarFrame/Layout/RightPanel/PreviewPanel/Preview") as Node2D
	name_label = get_node_or_null("HangarFrame/Layout/RightPanel/InfoPanel/VBox/Name") as Label
	role_label = get_node_or_null("HangarFrame/Layout/RightPanel/InfoPanel/VBox/Role") as Label
	desc_label = get_node_or_null("HangarFrame/Layout/RightPanel/InfoPanel/VBox/Desc") as Label
	stats_label = get_node_or_null("HangarFrame/Layout/RightPanel/InfoPanel/VBox/Stats") as Label
	mastery_label = get_node_or_null("HangarFrame/Layout/RightPanel/InfoPanel/VBox/Mastery") as Label
	back_btn = get_node_or_null("BackBtn") as Button
	launch_btn = get_node_or_null("HangarFrame/Layout/RightPanel/LaunchBtn") as Button
	var scroll := get_node_or_null("HangarFrame/Layout/LeftPanel/ShipScroll") as ScrollContainer
	ship_grid = get_node_or_null("HangarFrame/Layout/LeftPanel/ShipScroll/ShipGrid") as GridContainer
	if ship_grid == null and scroll != null:
		ship_grid = GridContainer.new()
		ship_grid.name = "ShipGridRuntime"
		ship_grid.columns = 2
		ship_grid.add_theme_constant_override("h_separation", 10)
		ship_grid.add_theme_constant_override("v_separation", 10)
		ship_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ship_grid.custom_minimum_size = Vector2(430, 420)
		scroll.add_child(ship_grid)
	if ship_grid != null:
		ship_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scrap_label = get_node_or_null("TopBar/HBox/Scrap") as Label
	if scrap_label == null:
		scrap_label = get_node_or_null("TopBar/Scrap") as Label
	stars_node = get_node_or_null("Stars") as Node2D

func _add_ship_card(id: String) -> void:
	var data: Dictionary = GameManager.CHARACTERS[id]
	var card := Button.new()
	card.name = id.capitalize() + "Btn"
	card.custom_minimum_size = Vector2(198, 104)
	card.text = _card_text(id)
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_theme_font_size_override("font_size", 13)
	card.tooltip_text = _tooltip_text(id)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.pressed.connect(_select_or_unlock.bind(id))
	if ship_grid == null:
		return
	ship_grid.add_child(card)
	buttons[id] = card
	var iv := IconView.make("ship", id, data.color, 54)
	iv.name = "ShipIcon"
	iv.position = Vector2(8, 25)
	card.add_child(iv)
	VisualTheme.add_button_feedback(card)
	_style_card(card, id)

func _card_text(id: String) -> String:
	var data: Dictionary = GameManager.CHARACTERS[id]
	var unlocked := GameManager.is_ship_unlocked(id)
	var cost := int(data.get("unlock_cost", 0))
	var mastery := GameManager.mastery_percent(id)
	if not unlocked:
		return "%s\nLOCKED  •  %d SCRAP\nMASTERY %d%%" % [data.name.to_upper(), cost, mastery]
	var signature: Dictionary = GameManager.get_ship_signature(id)
	var signature_name: String = GameManager.available_upgrade_name(str(signature.get("weapon", "")))
	return "%s\n%s\nSTART: %s\nMASTERY %d%%" % [data.name.to_upper(), "READY" if id != selected else "SELECTED", signature_name.to_upper(), mastery]

func _tooltip_text(id: String) -> String:
	var data: Dictionary = GameManager.CHARACTERS[id]
	var mastery := GameManager.mastery_percent(id)
	var state := "UNLOCKED" if GameManager.is_ship_unlocked(id) else "LOCKED — %d banked Scrap required" % int(data.get("unlock_cost", 0))
	var signature: Dictionary = GameManager.get_ship_signature(id)
	var signature_name: String = GameManager.available_upgrade_name(str(signature.get("weapon", "")))
	return "%s\n%s\n%s\n\nSTARTING WEAPON: %s\nSHIP TRAIT: %s\n\nSPEED %d  •  HULL %d\nDAMAGE %d  •  FIRE %.2fs\nPROJECTILE %d  •  MAGNET %d\nMASTERY %d%%" % [data.name.to_upper(), data.desc, state, signature_name, str(signature.get("trait", "")), int(data.base_speed), int(data.base_max_hp), int(data.base_damage), data.base_fire_rate, int(data.base_projectile_speed), int(data.base_xp_magnet), mastery]

func _style_card(card: Button, id: String) -> void:
	if card == null:
		return
	var data: Dictionary = GameManager.CHARACTERS[id]
	var accent: Color = data.color
	if not GameManager.is_ship_unlocked(id):
		accent = Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55, 1.0)
	card.add_theme_color_override("font_color", Color(0.82, 0.9, 0.98, 1.0))
	card.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	card.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	card.add_theme_color_override("font_focus_color", accent)
	var selected_now: bool = id == selected
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := VisualTheme.button_style(accent, state != "normal" or selected_now)
		sb.content_margin_left = 70
		if selected_now:
			sb.border_color = accent
			sb.set_border_width_all(2)
		card.add_theme_stylebox_override(state, sb)
	var iv: Node = card.get_node_or_null("ShipIcon")
	if iv:
		iv.accent = accent
		iv.glow = 1.0 if selected_now else 0.0
		iv.queue_redraw()

func _refresh_cards() -> void:
	for id in buttons.keys():
		var b: Button = buttons[id]
		b.text = _card_text(id)
		b.tooltip_text = _tooltip_text(id)
		_style_card(b, id)

func _select_or_unlock(id: String) -> void:
	if not GameManager.is_ship_unlocked(id):
		var cost := int(GameManager.CHARACTERS[id].get("unlock_cost", 0))
		if not GameManager.unlock_ship(id, cost):
			return
	_select(id)

func _select(id: String) -> void:
	if not GameManager.CHARACTERS.has(id):
		id = "viper"
	if not GameManager.is_ship_unlocked(id):
		id = "viper"
	selected = id
	GameManager.selected_character = id
	var data: Dictionary = GameManager.CHARACTERS[selected]
	if preview != null:
		preview.set_ship(selected)
	if name_label != null:
		name_label.text = data.name.to_upper()
		name_label.modulate = data.color
	if role_label != null:
		role_label.text = _role_text(selected)
	if desc_label != null:
		desc_label.text = str(data.desc)
	var signature: Dictionary = GameManager.get_ship_signature(selected)
	var signature_name: String = GameManager.available_upgrade_name(str(signature.get("weapon", "")))
	if stats_label != null:
		stats_label.text = "SIGNATURE  %s\nTRAIT  %s\n%s\nSPEED %d  •  HULL %d  •  DAMAGE %d\nFIRE %.2fs  •  PROJ %d  •  MAGNET %d" % [signature_name.to_upper(), str(signature.get("trait", "")), GameManager.get_ship_trait_text(selected), int(data.base_speed), int(data.base_max_hp), int(data.base_damage), data.base_fire_rate, int(data.base_projectile_speed), int(data.base_xp_magnet)]
	if mastery_label != null:
		mastery_label.text = "MASTERY  %d%%    •    %d KILLS" % [GameManager.mastery_percent(selected), int(GameManager.mastery_kills.get(selected, 0))]
	_refresh_cards()

func _role_text(id: String) -> String:
	match id:
		"viper": return "INTERCEPTOR  //  AGILITY"
		"bulwark": return "CRUISER  //  ARMOR"
		"nova": return "CANNON  //  BURST"
		"voidrunner": return "SKIRMISHER  //  PHASE"
		"destroyer": return "GUNSHIP  //  HEAVY"
		"aegis": return "FRIGATE  //  DEFENSE"
		"tempest": return "INTERCEPTOR  //  STORM"
		"dreadnought": return "BATTLESHIP  //  SIEGE"
		"singularity": return "ANOMALY  //  CONTROL"
	return "STARFRAME  //  MULTIROLE"

func _launch() -> void:
	GameManager.selected_character = selected
	GameManager.run_mode = "standard"
	GameManager.reset()
	call_deferred("_change_to_run")

func _change_to_run() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _cyan() -> Color:
	return Color(0.35, 0.86, 1.0, 1.0)

func _mint() -> Color:
	return Color(0.38, 1.0, 0.72, 1.0)

func _bg() -> Color:
	return Color(0.018, 0.024, 0.05, 0.97)

func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(180):
		var star := Polygon2D.new()
		var size := rng.randf_range(0.5, 1.8)
		star.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)])
		var b := rng.randf_range(0.25, 0.8)
		star.color = Color(b, b, min(1.0, b * 1.1), rng.randf_range(0.25, 0.75))
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720))
		if stars_node != null:
			stars_node.add_child(star)
		else:
			star.queue_free()
