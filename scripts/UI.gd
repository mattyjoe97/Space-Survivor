extends CanvasLayer

@onready var ship_icon: Control = $HUD/TopLeft/ShipIcon
@onready var hp_bar: ProgressBar = $HUD/TopLeft/HPBar
@onready var hp_label: Label = $HUD/TopLeft/HPLabel
@onready var xp_bar: ProgressBar = $HUD/TopLeft/XPBar
@onready var level_label: Label = $HUD/TopLeft/LevelLabel
@onready var luck_label: Label = $HUD/TopLeft/LuckLabel
@onready var char_label: Label = $HUD/TopLeft/CharLabel
@onready var scrap_label: Label = $HUD/TopLeft/ScrapLabel
@onready var mission_label: Label = $HUD/MissionLabel
@onready var score_label: Label = $HUD/TopRight/ScoreLabel
@onready var time_label: Label = $HUD/TopRight/TimeLabel
@onready var wave_label: Label = $HUD/TopCenter/WaveLabel
var sector_label: Label
var build_label: Label
var elite_label: Label
var threat_label: Label
@onready var boss_panel: PanelContainer = $HUD/BossPanel
@onready var boss_hp_bar: ProgressBar = $HUD/BossPanel/VBox/BossHPBar
@onready var boss_label: Label = $HUD/BossPanel/VBox/BossLabel
@onready var weapon_panel: PanelContainer = $HUD/WeaponPanel
@onready var weapon_list: HBoxContainer = $HUD/WeaponPanel/Margin/VBox/WeaponList
@onready var modifier_panel: PanelContainer = $HUD/ModifierPanel
@onready var modifier_list: VBoxContainer = $HUD/ModifierPanel/Margin/VBox/ModifierList
var weapon_rows: Dictionary = {}
var weapon_panel_title: Label
var modifier_rows: Dictionary = {}
var modifier_panel_title: Label
var player_signals_bound: bool = false
@onready var levelup_panel: PanelContainer = $LevelUpPanel
@onready var upgrade_container: VBoxContainer = $LevelUpPanel/Margin/VBox/Upgrades
@onready var levelup_title: Label = $LevelUpPanel/Margin/VBox/Title
@onready var merchant_panel: PanelContainer = $MerchantPanel
@onready var merchant_container: VBoxContainer = $MerchantPanel/Margin/VBox/Offers
@onready var merchant_title: Label = $MerchantPanel/Margin/VBox/Title
@onready var merchant_scrap: Label = $MerchantPanel/Margin/VBox/ScrapInfo
@onready var merchant_leave: Button = $MerchantPanel/Margin/VBox/LeaveBtn
@onready var gameover_panel: PanelContainer = $GameOverPanel
@onready var final_score: Label = $GameOverPanel/Margin/VBox/FinalScore
@onready var final_time: Label = $GameOverPanel/Margin/VBox/FinalTime
var final_damage: RichTextLabel
@onready var restart_btn: Button = $GameOverPanel/Margin/VBox/RestartBtn
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var victory_score: Label = $VictoryPanel/Margin/VBox/FinalScore
@onready var victory_restart: Button = $VictoryPanel/Margin/VBox/RestartBtn
var victory_damage: RichTextLabel
@onready var relic_toast: Label = $RelicToast

var player: Node2D = null
var current_merchant: Node = null
var merchant_direction_label: Label
var manual_aim_reticle: Label
var stats_panel: PanelContainer
var stats_modifier_list: VBoxContainer
var stats_luck_label: Label
var stats_scrap_label: Label
var mission_window: PanelContainer
var mission_window_label: Label
var mission_progress_label: Label

var pause_panel: PanelContainer
var pause_settings_panel: PanelContainer
var pause_fullscreen_check: CheckButton
var pause_open: bool = false
var reroll_button: Button
var current_level: int = 1
var hp_chip_bar: ProgressBar
var boss_chip_bar: ProgressBar
var hud_frame: Control
var hud_hp_ratio: float = 1.0
var last_boss_phase: int = -1
const RARITY_NAMES := ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const RARITY_COLORS := [Color(0.75, 0.8, 0.85), Color(0.4, 0.85, 1.0), Color(0.55, 0.35, 1.0), Color(1.0, 0.38, 0.72), Color(1.0, 0.78, 0.22)]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	VisualTheme.style_progress(hp_bar, Color(0.95, 0.32, 0.42))
	VisualTheme.style_progress(xp_bar, Color(0.38, 1.0, 0.72))
	VisualTheme.style_progress(boss_hp_bar, Color(1.0, 0.32, 0.42))
	hud_frame = get_node_or_null("HUD/HUDFrame")
	hp_chip_bar = _make_chip_bar(hp_bar, Color(1.0, 0.85, 0.55, 0.55))
	boss_chip_bar = _make_chip_bar(boss_hp_bar, Color(1.0, 0.85, 0.55, 0.55))
	VisualTheme.style_panel(levelup_panel, VisualTheme.CYAN)
	VisualTheme.style_panel(merchant_panel, VisualTheme.GOLD)
	VisualTheme.style_panel(gameover_panel, Color(1.0, 0.32, 0.42))
	VisualTheme.style_panel(victory_panel, VisualTheme.MINT)
	VisualTheme.style_panel(modifier_panel, VisualTheme.GOLD)
	_build_pause_ui()
	levelup_panel.visible = false
	gameover_panel.visible = false
	victory_panel.visible = false
	merchant_panel.visible = false
	if boss_panel: boss_panel.visible = false
	if relic_toast: relic_toast.visible = false
	if luck_label: luck_label.visible = false
	if scrap_label: scrap_label.visible = false
	if modifier_panel: modifier_panel.visible = false
	if mission_label: mission_label.visible = false
	var old_mission_panel: Node = get_node_or_null("HUD/MissionPanel")
	if old_mission_panel:
		old_mission_panel.visible = false
	_build_stats_window()
	_build_mission_window()
	merchant_direction_label = Label.new()
	merchant_direction_label.position = Vector2(-160, 86)
	merchant_direction_label.size = Vector2(320, 20)
	merchant_direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	merchant_direction_label.add_theme_font_size_override("font_size", 11)
	merchant_direction_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	merchant_direction_label.visible = false
	$HUD/TopCenter.add_child(merchant_direction_label)
	manual_aim_reticle = Label.new()
	manual_aim_reticle.text = "⊙"
	manual_aim_reticle.size = Vector2(22, 22)
	manual_aim_reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_aim_reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	manual_aim_reticle.add_theme_font_size_override("font_size", 16)
	manual_aim_reticle.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0, 0.9))
	manual_aim_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manual_aim_reticle.z_index = 100
	$HUD.add_child(manual_aim_reticle)
	gameover_panel.custom_minimum_size = Vector2(380, 390)
	victory_panel.custom_minimum_size = Vector2(380, 410)
	final_damage = RichTextLabel.new()
	final_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	final_damage.add_theme_font_size_override("font_size", 11)
	final_damage.bbcode_enabled = true
	final_damage.fit_content = true
	final_damage.scroll_active = false
	final_damage.fit_content = true
	final_damage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var final_damage_scroll := ScrollContainer.new()
	final_damage_scroll.custom_minimum_size = Vector2(0, 210)
	final_damage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	final_damage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	final_damage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	final_damage_scroll.add_child(final_damage)
	$GameOverPanel/Margin/VBox.add_child(final_damage_scroll)
	victory_damage = RichTextLabel.new()
	victory_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	victory_damage.add_theme_font_size_override("font_size", 11)
	victory_damage.bbcode_enabled = true
	victory_damage.fit_content = true
	victory_damage.scroll_active = false
	victory_damage.fit_content = true
	victory_damage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var victory_damage_scroll := ScrollContainer.new()
	victory_damage_scroll.custom_minimum_size = Vector2(0, 210)
	victory_damage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	victory_damage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	victory_damage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_damage_scroll.add_child(victory_damage)
	$VictoryPanel/Margin/VBox.add_child(victory_damage_scroll)
	restart_btn.pressed.connect(_on_restart)
	victory_restart.pressed.connect(_on_restart)
	merchant_leave.pressed.connect(_on_merchant_leave)
	GameManager.player_leveled_up.connect(_on_player_leveled_up)
	GameManager.player_died.connect(_on_player_died)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_health_changed.connect(_on_boss_health)
	GameManager.victory.connect(_on_victory)
	GameManager.run_time_updated.connect(_on_time_updated)
	GameManager.luck_changed.connect(_on_luck_changed)
	GameManager.scrap_changed.connect(_on_scrap_changed)
	GameManager.mission_updated.connect(_on_mission_updated)
	GameManager.relic_gained.connect(_on_relic_gained)
	GameManager.evolution_unlocked.connect(_on_evolution)
	GameManager.synergy_activated.connect(_on_synergy_activated)
	GameManager.dash_used.connect(_on_dash_used)
	GameManager.random_event.connect(_on_random_event)
	GameManager.sector_changed.connect(_on_sector_changed)
	GameManager.mastery_reward.connect(_on_mastery_reward)
	GameManager.secret_found.connect(_on_secret_found)
	GameManager.threat_changed.connect(_on_threat_changed)
	var data = GameManager.get_character_data()
	if char_label:
		char_label.text = data.name
		char_label.modulate = data.color
	if ship_icon and ship_icon.has_method("set_ship_color"):
		ship_icon.set_ship_color(data.color)
	sector_label = Label.new()
	sector_label.position = Vector2(-185, 38)
	sector_label.size = Vector2(370, 20)
	sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sector_label.add_theme_font_size_override("font_size", 11)
	sector_label.modulate = Color(0.55, 0.8, 1.0)
	$HUD/TopCenter.add_child(sector_label)
	elite_label = Label.new()
	elite_label.position = Vector2(-185, 60)
	elite_label.size = Vector2(370, 18)
	elite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_label.add_theme_font_size_override("font_size", 12)
	elite_label.modulate = Color(1.0, 0.55, 0.35)
	$HUD/TopCenter.add_child(elite_label)

	build_label = Label.new()
	build_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	build_label.position = Vector2(26, -59)
	build_label.size = Vector2(265, 34)
	build_label.clip_text = true
	build_label.add_theme_font_size_override("font_size", 9)
	build_label.modulate = Color(0.75, 0.82, 1.0)
	$HUD.add_child(build_label)
	var hotkey_hint := Label.new()
	hotkey_hint.text = "K  STATS    J  MISSIONS"
	hotkey_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hotkey_hint.position = Vector2(24, -108)
	hotkey_hint.size = Vector2(230, 18)
	hotkey_hint.add_theme_font_size_override("font_size", 9)
	hotkey_hint.modulate = Color(0.45, 0.55, 0.68, 0.85)
	$HUD.add_child(hotkey_hint)
	_on_scrap_changed(GameManager.scrap)
	_on_sector_changed(GameManager.current_sector, GameManager.current_sector_gimmick)
	_update_build_label()
	_update_elite_label()
	_on_threat_changed(GameManager.threat_level, GameManager.threat_label)
	_update_weapon_hud()
	_update_modifier_hud()
	_bind_player_signals()
	_update_merchant_direction()

## Creates a faded "chip" bar directly behind `source` so damage/heal changes leave
## a brief trailing ghost, a common juice trick that makes HP/boss bars read as reactive.
## Creates a ghost "chip" ProgressBar that visually overlays the source bar.
## If the source bar's parent is a container (VBoxContainer etc.), the chip is
## placed in an absolute-positioned Control sibling of the source so the chip
## doesn't disturb the layout. Otherwise it is inserted directly behind the source.
func _make_chip_bar(source: ProgressBar, chip_color: Color) -> ProgressBar:
	var chip := source.duplicate() as ProgressBar
	chip.name = source.name + "Chip"
	VisualTheme.style_progress(chip, chip_color)
	chip.value = source.value
	chip.show_percentage = false
	var parent := source.get_parent()
	if parent is Container:
		# For managed-layout parents we reparent the chip into a
		# CanvasLayer-relative overlay Control that tracks the source rect.
		var overlay := Control.new()
		overlay.name = source.name + "ChipOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = source.z_index
		# We'll position it in _process; attach it as a sibling of the Container.
		var grand := parent.get_parent()
		if grand:
			grand.add_child(overlay)
			overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			chip.layout_mode = 0  # manual inside the overlay
			overlay.add_child(chip)
			# Store a back-reference so we can update position in _on_boss_health.
			chip.set_meta("source_bar", source)
			chip.set_meta("overlay", overlay)
			_update_chip_overlay_rect(chip)
		else:
			# Fallback: just add without overlay positioning.
			parent.add_child(chip)
	else:
		parent.add_child(chip)
		parent.move_child(chip, source.get_index())
	return chip

func _update_chip_overlay_rect(chip: ProgressBar) -> void:
	if not chip.has_meta("source_bar"):
		return
	var src: ProgressBar = chip.get_meta("source_bar")
	if not is_instance_valid(src):
		return
	var overlay: Control = chip.get_meta("overlay")
	if not is_instance_valid(overlay):
		return
	# Convert the source bar's rect to the overlay's local space.
	var src_global_rect: Rect2 = src.get_global_rect()
	var overlay_xf: Transform2D = overlay.get_global_transform().affine_inverse()
	var local_origin: Vector2 = overlay_xf * src_global_rect.position
	chip.position = local_origin
	chip.size = src_global_rect.size

func _modal_blocks_hotkeys() -> bool:
	return levelup_panel.visible or merchant_panel.visible or gameover_panel.visible or victory_panel.visible or (pause_settings_panel and pause_settings_panel.visible)

func _set_game_paused_for_overlay(open: bool) -> void:
	if open:
		GameManager.is_paused = true
		get_tree().paused = true
	else:
		GameManager.is_paused = false
		get_tree().paused = false

func _toggle_stats_window() -> void:
	if stats_panel == null:
		return
	var open := not stats_panel.visible
	if open:
		if mission_window and mission_window.visible:
			mission_window.visible = false
		_update_stats_window()
	stats_panel.visible = open
	_set_game_paused_for_overlay(open)

func _toggle_mission_window() -> void:
	if mission_window == null:
		return
	var open := not mission_window.visible
	if open:
		if stats_panel and stats_panel.visible:
			stats_panel.visible = false
		_update_mission_window()
	mission_window.visible = open
	_set_game_paused_for_overlay(open)

func _build_stats_window() -> void:
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsWindow"
	stats_panel.visible = false
	stats_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	stats_panel.custom_minimum_size = Vector2(520, 520)
	stats_panel.position = Vector2(380, 95)
	VisualTheme.style_panel(stats_panel, VisualTheme.CYAN)
	$HUD.add_child(stats_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	stats_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "SHIP STATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = VisualTheme.CYAN
	box.add_child(title)
	var hint := Label.new()
	hint.text = "K  CLOSE  •  LIVE RUN DATA"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.48, 0.58, 0.7)
	box.add_child(hint)
	var summary := HBoxContainer.new()
	summary.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(summary)
	stats_luck_label = Label.new()
	stats_luck_label.add_theme_font_size_override("font_size", 14)
	stats_luck_label.modulate = Color(1.0, 0.84, 0.35)
	summary.add_child(stats_luck_label)
	var spacer := Label.new()
	spacer.text = "    •    "
	spacer.modulate = Color(0.35, 0.42, 0.5)
	summary.add_child(spacer)
	stats_scrap_label = Label.new()
	stats_scrap_label.add_theme_font_size_override("font_size", 14)
	stats_scrap_label.modulate = Color(1.0, 0.9, 0.4)
	summary.add_child(stats_scrap_label)
	var divider := HSeparator.new()
	box.add_child(divider)
	var section := Label.new()
	section.text = "CORE MODIFIERS"
	section.add_theme_font_size_override("font_size", 11)
	section.modulate = Color(0.55, 0.82, 1.0)
	box.add_child(section)
	stats_modifier_list = VBoxContainer.new()
	stats_modifier_list.add_theme_constant_override("separation", 4)
	box.add_child(stats_modifier_list)
	var footer := Label.new()
	footer.text = "Detailed stats live here so the combat HUD can stay clean."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 9)
	footer.modulate = Color(0.45, 0.52, 0.62)
	box.add_child(footer)

func _update_stats_window() -> void:
	if not stats_panel:
		return
	if stats_luck_label:
		stats_luck_label.text = "✦  LUCK %d" % int(GameManager.player_luck)
	if stats_scrap_label:
		stats_scrap_label.text = "◇  SCRAP %d" % int(GameManager.scrap)
	if not stats_modifier_list:
		return
	for child in stats_modifier_list.get_children():
		child.queue_free()
	var entries := [["CRIT", "crit"], ["LUCK", "luck"], ["FIRE RATE", "fire_rate"], ["SPEED", "speed"], ["HULL", "max_hp"], ["XP", "xp_gain"], ["XP MAGNET", "xp_magnet"], ["SLOW FIELD", "slow_field"], ["LIFESTEAL", "lifesteal"]]
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	right.add_theme_constant_override("separation", 4)	
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 28)
	grid.add_child(left)
	grid.add_child(right)
	stats_modifier_list.add_child(grid)
	for i in range(entries.size()):
		var key: String = entries[i][1]
		var lv: int = GameManager.get_upgrade_level(key)
		var value := "OFF"
		if key == "crit":
			value = "%d%%" % int(round(float(player.crit_chance) * 100.0)) if player else "0%"
		elif key == "luck":
			value = "%d" % int(GameManager.player_luck)
		elif key == "speed":
			value = "+%d%%" % (lv * 10)
		elif key == "max_hp":
			value = "+%d HP" % (lv * 25)
		elif key == "xp_gain":
			value = "+%d%%" % (lv * 10)
		elif key == "xp_magnet":
			value = "+%d%%" % (lv * 30)
		elif key == "slow_field":
			value = "+%d%%" % min(45, lv * 12)
		elif key == "lifesteal":
			value = "ON" if lv > 0 else "OFF"
		var row := Label.new()
		row.text = "%s   %s" % [key, value]
		row.add_theme_font_size_override("font_size", 12)
		row.modulate = Color(0.84, 0.9, 0.98) if lv > 0 else Color(0.48, 0.55, 0.65)
		if i < int(ceil(float(entries.size()) / 2.0)):
			left.add_child(row)
		else:
			right.add_child(row)

func _build_mission_window() -> void:
	mission_window = PanelContainer.new()
	mission_window.name = "MissionWindow"
	mission_window.visible = false
	mission_window.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mission_window.custom_minimum_size = Vector2(560, 360)
	mission_window.position = Vector2(360, 175)
	VisualTheme.style_panel(mission_window, VisualTheme.MINT)
	$HUD.add_child(mission_window)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	mission_window.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := Label.new()
	title.text = "MISSIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = VisualTheme.MINT
	box.add_child(title)
	var hint := Label.new()
	hint.text = "J  CLOSE  •  ACTIVE RUN OBJECTIVES"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.48, 0.58, 0.7)
	box.add_child(hint)
	var line := HSeparator.new()
	box.add_child(line)
	mission_window_label = Label.new()
	mission_window_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_window_label.add_theme_font_size_override("font_size", 18)
	mission_window_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_window_label.custom_minimum_size = Vector2(0, 80)
	box.add_child(mission_window_label)
	mission_progress_label = Label.new()
	mission_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_progress_label.add_theme_font_size_override("font_size", 14)
	mission_progress_label.modulate = Color(0.7, 0.9, 1.0)
	box.add_child(mission_progress_label)
	var footer := Label.new()
	footer.text = "Complete the objective for bonus Scrap, Score, and XP."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 10)
	footer.modulate = Color(0.45, 0.52, 0.62)
	box.add_child(footer)

func _update_mission_window() -> void:
	if not mission_window_label:
		return
	mission_window_label.text = str(GameManager.mission_text)
	if GameManager.mission_target > 0:
		mission_progress_label.text = "%d / %d" % [GameManager.mission_progress, GameManager.mission_target]
	else:
		mission_progress_label.text = "COMPLETE"

func _build_pause_ui() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-220, -210)
	pause_panel.size = Vector2(440, 420)
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	pause_panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub = Label.new()
	sub.text = "Take a breath. The void can wait."
	sub.modulate = Color(0.55, 0.63, 0.75)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var resume = Button.new()
	resume.text = "RESUME"
	resume.custom_minimum_size = Vector2(0, 52)
	resume.add_theme_font_size_override("font_size", 19)
	resume.pressed.connect(_resume_from_pause)
	box.add_child(resume)

	var settings = Button.new()
	settings.text = "SETTINGS"
	settings.custom_minimum_size = Vector2(0, 46)
	settings.pressed.connect(_open_pause_settings)
	box.add_child(settings)

	var menu = Button.new()
	menu.text = "RETURN TO MAIN MENU"
	menu.custom_minimum_size = Vector2(0, 46)
	menu.pressed.connect(_return_to_menu)
	box.add_child(menu)

	var hint = Label.new()
	hint.text = "Esc  Resume / Pause"
	hint.modulate = Color(0.42, 0.48, 0.58)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	pause_settings_panel = PanelContainer.new()
	pause_settings_panel.name = "PauseSettings"
	pause_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_settings_panel.position = Vector2(-200, -300)
	pause_settings_panel.size = Vector2(460, 560)
	pause_settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_settings_panel)
	var sm = MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 26)
	sm.add_theme_constant_override("margin_top", 20)
	sm.add_theme_constant_override("margin_right", 26)
	sm.add_theme_constant_override("margin_bottom", 20)
	pause_settings_panel.add_child(sm)
	var sb = VBoxContainer.new()
	sb.add_theme_constant_override("separation", 8)
	sm.add_child(sb)
	var st = Label.new()
	st.text = "SETTINGS"
	st.add_theme_font_size_override("font_size", 26)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb.add_child(st)
	var s_hint = Label.new()
	s_hint.text = "DISPLAY • AIM • AUDIO"
	s_hint.modulate = Color(0.55, 0.62, 0.72)
	s_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb.add_child(s_hint)
	pause_fullscreen_check = CheckButton.new()
	pause_fullscreen_check.text = "Fullscreen"
	pause_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	pause_fullscreen_check.toggled.connect(_toggle_pause_fullscreen)
	sb.add_child(pause_fullscreen_check)
	var damage = CheckButton.new(); damage.text = "Show Damage Numbers"; damage.button_pressed = SettingsManager.damage_numbers
	damage.toggled.connect(func(v): SettingsManager.damage_numbers = v; SettingsManager.save())
	sb.add_child(damage)
	var shake = CheckButton.new(); shake.text = "Screen Shake"; shake.button_pressed = SettingsManager.screen_shake
	shake.toggled.connect(func(v): SettingsManager.screen_shake = v; SettingsManager.save())
	sb.add_child(shake)
	var postfx = CheckButton.new(); postfx.text = "Screen Effects (vignette / distortion)"; postfx.button_pressed = SettingsManager.post_fx
	postfx.toggled.connect(func(v): SettingsManager.set_post_fx(v))
	sb.add_child(postfx)
	var floating = CheckButton.new(); floating.text = "Floating Combat Text"; floating.button_pressed = SettingsManager.floating_text
	floating.toggled.connect(func(v): SettingsManager.floating_text = v; SettingsManager.save())
	sb.add_child(floating)
	var attack_row := HBoxContainer.new()
	var attack_lab := Label.new(); attack_lab.text = "ATTACK MODE"; attack_lab.custom_minimum_size = Vector2(115, 28); attack_row.add_child(attack_lab)
	var attack_select := OptionButton.new(); attack_select.add_item("AUTO TARGET"); attack_select.add_item("MANUAL AIM")
	attack_select.selected = 1 if SettingsManager.attack_mode == "manual" else 0
	attack_select.item_selected.connect(func(index): SettingsManager.set_attack_mode("manual" if index == 1 else "auto"))
	attack_row.add_child(attack_select); sb.add_child(attack_row)
	var assist_row := HBoxContainer.new()
	var assist_lab := Label.new(); assist_lab.text = "AIM ASSIST"; assist_lab.custom_minimum_size = Vector2(115, 28); assist_row.add_child(assist_lab)
	var assist_select := OptionButton.new(); assist_select.add_item("OFF"); assist_select.add_item("LOW"); assist_select.add_item("HIGH")
	match SettingsManager.manual_aim_assist:
		"off": assist_select.selected = 0
		"low": assist_select.selected = 1
		_: assist_select.selected = 2
	assist_select.item_selected.connect(func(index): SettingsManager.set_manual_aim_assist(["off", "low", "high"][index]))
	assist_row.add_child(assist_select); sb.add_child(assist_row)
	for item in [["MASTER", SettingsManager.master_volume, "set_master"], ["MUSIC", SettingsManager.music_volume, "set_music"], ["EFFECTS", SettingsManager.effects_volume, "set_effects"]]:
		var row = HBoxContainer.new()
		var lab = Label.new(); lab.text = item[0]; lab.custom_minimum_size = Vector2(70, 28); row.add_child(lab)
		var slider = HSlider.new(); slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05; slider.value = item[1]; slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vl = Label.new(); vl.custom_minimum_size = Vector2(45, 28); vl.text = "%d%%" % int(slider.value * 100.0)
		slider.value_changed.connect(func(v, l=vl, method=item[2]): l.text = "%d%%" % int(v * 100.0); SettingsManager.call(method, v))
		row.add_child(slider); row.add_child(vl); sb.add_child(row)
	var back = Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 42)
	back.pressed.connect(_close_pause_settings)
	sb.add_child(back)

	pause_panel.visible = false
	pause_settings_panel.visible = false

func _toggle_pause_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _open_pause_settings() -> void:
	pause_panel.visible = false
	pause_settings_panel.visible = true
	pause_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	pause_fullscreen_check.grab_focus()

func _close_pause_settings() -> void:
	pause_settings_panel.visible = false
	pause_panel.visible = true

func _resume_from_pause() -> void:
	pause_open = false
	pause_panel.visible = false
	GameManager.is_paused = false
	get_tree().paused = false

func _toggle_pause() -> void:
	if levelup_panel.visible or merchant_panel.visible or gameover_panel.visible or victory_panel.visible or pause_settings_panel.visible:
		return
	pause_open = not pause_open
	pause_panel.visible = pause_open
	GameManager.is_paused = pause_open
	get_tree().paused = pause_open
	if pause_open:
		pause_panel.get_child(0).get_child(0).get_child(2).grab_focus()

func _return_to_menu() -> void:
	pause_open = false
	GameManager.is_paused = false
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_K and not _modal_blocks_hotkeys():
			_toggle_stats_window()
			return
		if event.physical_keycode == KEY_J and not _modal_blocks_hotkeys():
			_toggle_mission_window()
			return
	if event.is_action_pressed("ui_cancel"):
		if pause_settings_panel and pause_settings_panel.visible:
			_close_pause_settings()
		elif stats_panel and stats_panel.visible:
			stats_panel.visible = false
			_set_game_paused_for_overlay(false)
		elif mission_window and mission_window.visible:
			mission_window.visible = false
			_set_game_paused_for_overlay(false)
		elif not levelup_panel.visible and not merchant_panel.visible and not gameover_panel.visible and not victory_panel.visible:
			_toggle_pause()

func _bind_player_signals() -> void:
	if player_signals_bound and is_instance_valid(player):
		return
	if not player:
		player = GameManager.player
	if not player:
		return
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("xp_changed"):
		player.xp_changed.connect(_on_xp_changed)
	if player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_level_changed)
	player_signals_bound = true
	# Player emits these in its own _ready before UI binds, so seed the HUD now.
	_on_health_changed(float(player.current_hp), float(player.max_hp))
	_on_xp_changed(float(player.current_xp), float(player.xp_to_next))
	_on_level_changed(int(player.level))
	_on_luck_changed(float(GameManager.player_luck))

func _update_modifier_hud() -> void:
	_update_stats_window()

func _weapon_chip_style(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.045, 0.08, 0.86)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_left = 7
	sb.corner_radius_bottom_right = 7
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

var _weapon_hud_key: String = ""

func _update_weapon_hud() -> void:
	if not weapon_list:
		return
	if not player:
		player = GameManager.player
	if not player:
		return
	# Only rebuild when the loadout actually changes (was rebuilding every frame).
	var key := "%d/%d" % [GameManager.weapon_slot_count(), GameManager.get_weapon_slot_limit()]
	for id in GameManager.WEAPON_UPGRADES:
		key += "|%s:%d" % [id, GameManager.get_upgrade_level(id)]
	for sid in GameManager.active_synergies:
		key += "|S:" + sid
	if key == _weapon_hud_key:
		return
	_weapon_hud_key = key
	for child in weapon_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "%d/%d SLOTS" % [GameManager.weapon_slot_count(), GameManager.get_weapon_slot_limit()]
	title.add_theme_font_size_override("font_size", 9)
	title.modulate = Color(0.45, 0.85, 1.0)
	weapon_list.add_child(title)
	# Superweapon chips replace their two parent weapons.
	var absorbed: Array = []
	for sid in GameManager.active_synergies:
		var sdata: Dictionary = GameManager.WEAPON_SYNERGIES.get(sid, {})
		var scol: Color = sdata.get("color", Color(1, 0.9, 0.5))
		absorbed.append_array(sdata.get("requires", []))
		var srow := PanelContainer.new()
		srow.custom_minimum_size = Vector2(0, 42)
		var st := _weapon_chip_style(scol)
		st.set_border_width_all(2)
		st.border_color = Color(1.0, 0.92, 0.6, 0.95)
		st.bg_color = Color(scol.r * 0.25, scol.g * 0.25, scol.b * 0.25, 0.8)
		srow.add_theme_stylebox_override("panel", st)
		var shb := HBoxContainer.new()
		shb.add_theme_constant_override("separation", 6)
		srow.add_child(shb)
		var siv := IconView.make("super", sid, scol, 32)
		shb.add_child(siv)
		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 0)
		shb.add_child(svb)
		var stag := Label.new()
		stag.text = "★ SUPERWEAPON"
		stag.add_theme_font_size_override("font_size", 7)
		stag.modulate = Color(1.0, 0.92, 0.6)
		svb.add_child(stag)
		var sname := Label.new()
		sname.text = str(sdata.get("name", sid))
		sname.add_theme_font_size_override("font_size", 10)
		sname.modulate = scol.lightened(0.2)
		svb.add_child(sname)
		weapon_list.add_child(srow)
		srow.pivot_offset = Vector2(0, 21)
		srow.scale = Vector2(0.5, 0.5)
		var stw := srow.create_tween()
		stw.tween_property(srow, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for id in GameManager.WEAPON_UPGRADES:
		var level := GameManager.get_upgrade_level(id)
		if level <= 0 or id in absorbed:
			continue
		var wcol: Color = GameManager.WEAPON_DEFS[id].color
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 36)
		row.add_theme_stylebox_override("panel", _weapon_chip_style(wcol))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		row.add_child(hb)
		var iv := IconView.make("weapon", id, wcol, 24)
		iv.animated = false
		hb.add_child(iv)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		hb.add_child(vb)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 9)
		label.modulate = wcol
		label.text = str(GameManager.WEAPON_DEFS[id].name).to_upper()
		vb.add_child(label)
		# Level pips
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 2)
		for i in range(GameManager.MAX_WEAPON_LEVEL):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(7, 3)
			pip.color = wcol if i < level else Color(wcol.r, wcol.g, wcol.b, 0.18)
			pips.add_child(pip)
		vb.add_child(pips)
		weapon_list.add_child(row)
		# Pop-in animation for new chips.
		row.pivot_offset = Vector2(0, 18)
		row.scale = Vector2(0.6, 0.6)
		row.modulate.a = 0.0
		var tw := row.create_tween()
		tw.set_parallel(true)
		tw.tween_property(row, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(row, "modulate:a", 1.0, 0.18)

func _on_synergy_activated(synergy_id: String) -> void:
	var data: Dictionary = GameManager.WEAPON_SYNERGIES.get(synergy_id, {})
	if data.is_empty():
		return
	_show_super_banner(str(data.get("name", synergy_id)), data.get("color", Color(0.5, 0.8, 1.0)), str(data.get("desc", "")))
	_weapon_hud_key = ""

## Big centre-screen superweapon announcement.
func _show_super_banner(sname: String, col: Color, desc: String) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 60
	add_child(root)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.anchor_left = 0.5; vb.anchor_right = 0.5; vb.anchor_top = 0.5; vb.anchor_bottom = 0.5
	vb.offset_left = -360; vb.offset_right = 360; vb.offset_top = -110; vb.offset_bottom = 10
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(vb)
	var tag := Label.new()
	tag.text = "S U P E R W E A P O N   O N L I N E"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 13)
	tag.modulate = Color(1.0, 0.92, 0.6)
	vb.add_child(tag)
	var big := Label.new()
	big.text = sname
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 44)
	big.add_theme_color_override("font_color", col.lightened(0.25))
	big.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05))
	big.add_theme_constant_override("outline_size", 8)
	vb.add_child(big)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = col
	vb.add_child(line)
	var d := Label.new()
	d.text = desc
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 12)
	d.modulate = Color(0.85, 0.9, 0.98)
	vb.add_child(d)
	vb.pivot_offset = Vector2(360, 60)
	vb.scale = Vector2(1.6, 1.6)
	vb.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(vb, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(vb, "modulate:a", 1.0, 0.2)
	tw.chain().tween_interval(2.6)
	tw.chain().tween_property(vb, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(root.queue_free)

var _warn_timer: float = 0.0
var _aim_label: Label = null
var _dash_hud: Control = null

func _process(_delta: float) -> void:
	_update_build_label()
	_update_music_state(_delta)
	_update_aim_indicator()
	_update_dash_hud()
	_update_elite_label()
	_update_weapon_hud()
	_update_modifier_hud()
	_bind_player_signals()
	_update_manual_aim_reticle()
	_update_hp_alert_pulse()

func _update_dash_hud() -> void:
	if _dash_hud == null:
		_dash_hud = Control.new()
		_dash_hud.set_script(load("res://scripts/DashHUD.gd"))
		_dash_hud.position = Vector2(20, 162)
		_dash_hud.size = Vector2(160, 16)
		_dash_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dash_hud)
	_dash_hud.player = player

func _update_aim_indicator() -> void:
	if _aim_label == null:
		_aim_label = Label.new()
		_aim_label.add_theme_font_size_override("font_size", 9)
		_aim_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_aim_label.position = Vector2(20, 146)
		_aim_label.size = Vector2(260, 14)
		add_child(_aim_label)
	var manual := SettingsManager.attack_mode == "manual"
	_aim_label.text = ("◎ MANUAL AIM" if manual else "◉ AUTO TARGET") + "   [MMB]"
	_aim_label.modulate = Color(1.0, 0.85, 0.45) if manual else Color(0.55, 0.9, 1.0)

func _update_music_state(delta: float) -> void:
	var paused_ui: bool = get_tree().paused or levelup_panel.visible or merchant_panel.visible
	MusicManager.duck(paused_ui and not GameManager.is_game_over and not GameManager.is_victory)
	if MusicManager.get_mood() == "calm" and GameManager.game_time > 18.0 and not GameManager.is_game_over:
		MusicManager.set_mood("combat")
	# Low-hull warning beep, throttled.
	if hud_hp_ratio < 0.25 and hud_hp_ratio > 0.0 and not GameManager.is_game_over and not paused_ui:
		_warn_timer -= delta
		if _warn_timer <= 0.0:
			_warn_timer = 2.4
			AudioManager.play("warning", 1.0, -8.0)

func _update_hp_alert_pulse() -> void:
	if hud_hp_ratio < 0.3 and hud_hp_ratio > 0.0:
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := 0.5 + 0.5 * sin(t * 8.0)
		hp_label.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.3, 0.3), pulse)
	else:
		hp_label.modulate = Color(1, 1, 1)

func _update_manual_aim_reticle() -> void:
	if manual_aim_reticle == null:
		return
	var visible_reticle: bool = SettingsManager.attack_mode == "manual" and not levelup_panel.visible and not merchant_panel.visible and not gameover_panel.visible and not victory_panel.visible and not pause_settings_panel.visible
	manual_aim_reticle.visible = visible_reticle
	if visible_reticle:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		manual_aim_reticle.position = mouse_pos - manual_aim_reticle.size * 0.5

func _update_elite_label() -> void:
	if elite_label:
		elite_label.text = "ELITES DEFEATED  %d" % GameManager.elites_killed

func _update_build_label() -> void:
	if not build_label:
		return
	var names: Array[String] = []
	for id in GameManager.WEAPON_UPGRADES:
		if GameManager.get_upgrade_level(id) > 0:
			names.append(str(GameManager.WEAPON_DEFS[id].name))
	var count := names.size()
	var shown := names
	if shown.size() > 3:
		shown = shown.slice(0, 3)
	var suffix := ""
	if count > 3:
		suffix = "  +%d" % (count - 3)
	var shown_text := ""
	for i in range(shown.size()):
		if i > 0:
			shown_text += "  •  "
		shown_text += shown[i]
	build_label.text = "%d/%d  " % [count, GameManager.get_weapon_slot_limit()] + shown_text + suffix

func _update_merchant_direction() -> void:
	if merchant_direction_label == null or player == null:
		return
	var target: Node = current_merchant
	if target == null or not is_instance_valid(target):
		var merchants := get_tree().get_nodes_in_group("merchants")
		if merchants.is_empty():
			merchant_direction_label.visible = false
			return
		var nearest: Node = null
		var best: float = INF
		for merchant in merchants:
			if not is_instance_valid(merchant):
				continue
			var d: float = player.global_position.distance_squared_to(merchant.global_position)
			if d < best:
				best = d
				nearest = merchant
		target = nearest
	if target == null or not is_instance_valid(target):
		merchant_direction_label.visible = false
		return
	var delta: Vector2 = target.global_position - player.global_position
	var dist: float = delta.length()
	merchant_direction_label.visible = true
	if dist < 140.0:
		merchant_direction_label.text = "◆ MERCHANT  •  IN RANGE"
		return
	var ang: float = atan2(delta.y, delta.x)
	var dirs := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	var index: int = int(round((ang + PI) / (PI / 4.0))) % 8
	merchant_direction_label.text = "%s  MERCHANT  •  %dm" % [dirs[index], int(dist)]

func _on_sector_changed(name: String, gimmick: String) -> void:
	if sector_label:
		sector_label.text = name + "  •  " + gimmick
	_show_toast("SECTOR: " + name, Color(0.5, 0.8, 1.0))

func _on_mastery_reward(text: String) -> void:
	_show_toast(text, Color(0.4, 1.0, 0.75))

func _on_secret_found(text: String) -> void:
	_show_toast("SECRET DISCOVERED  •  " + text, Color(1.0, 0.75, 0.3))

func _on_time_updated(time_left: float) -> void:
	if GameManager.run_mode == "endless":
		time_label.text = "ENDLESS  %02d:%02d" % [int(GameManager.endless_time) / 60, int(GameManager.endless_time) % 60]
		time_label.modulate = Color(1.0, 0.55, 0.8)
	elif GameManager.is_boss_phase:
		time_label.text = "10:00  •  TITAN"
		time_label.modulate = Color(1.0, 0.45, 0.5)
	else:
		# Presentation only: elapsed time counting up to the 10:00 boss mark.
		var elapsed: float = clampf(GameManager.RUN_DURATION - time_left, 0.0, GameManager.RUN_DURATION)
		time_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
		if time_left < 60.0:
			time_label.text += "  ▸ TITAN %02d:%02d" % [int(GameManager.RUN_DURATION) / 60, 0]
		time_label.modulate = Color(1.0, 0.65, 0.35) if time_left < 60.0 else Color(0.75, 0.9, 1.0)

func _on_health_changed(current: float, max_hp: float) -> void:
	var prev: float = hp_bar.value
	hp_bar.max_value = max_hp
	if hp_chip_bar: hp_chip_bar.max_value = max_hp
	hp_label.text = "%d / %d" % [int(current), int(max_hp)]
	hud_hp_ratio = current / maxf(max_hp, 1.0)
	if hud_frame and hud_frame.has_method("set_alert"):
		hud_frame.set_alert(clampf(1.0 - hud_hp_ratio / 0.3, 0.0, 1.0))
	if current < prev - 0.01:
		# Damage: the main bar drops immediately, the chip lingers then catches down.
		hp_bar.value = current
		if hp_chip_bar:
			hp_chip_bar.value = prev
			var tw := create_tween()
			tw.tween_interval(0.25)
			tw.tween_property(hp_chip_bar, "value", current, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		# Heal/regen: tween both bars up together for a smooth fill.
		if hp_chip_bar: hp_chip_bar.value = current
		var tw := create_tween()
		tw.tween_property(hp_bar, "value", current, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_xp_changed(current: float, needed: float) -> void:
	var prev: float = xp_bar.value
	xp_bar.max_value = needed
	if current < prev - 0.01:
		xp_bar.value = current
	else:
		var tw := create_tween()
		tw.tween_property(xp_bar, "value", current, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_level_changed(level: int) -> void:
	level_label.text = "◈  LVL %d" % level
	level_label.scale = Vector2(1.5, 1.5)
	level_label.modulate = VisualTheme.GOLD
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(level_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(level_label, "modulate", Color(1, 1, 1), 0.5)

func _on_luck_changed(luck: float) -> void:
	if stats_luck_label: stats_luck_label.text = "✦  LUCK %d" % int(luck)

func _on_scrap_changed(scrap: int) -> void:
	if stats_scrap_label: stats_scrap_label.text = "◇  SCRAP %d" % scrap

func _on_mission_updated(text: String) -> void:
	if mission_label: mission_label.text = text
	_update_mission_window()

func _on_score_changed(score: int) -> void:
	score_label.text = "%d" % score

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "WAVE %d" % wave


func _on_threat_changed(level: int, label: String) -> void:
	if not threat_label:
		threat_label = Label.new()
		threat_label.position = Vector2(-185, 78)
		threat_label.size = Vector2(370, 18)
		threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		threat_label.add_theme_font_size_override("font_size", 11)
		$HUD/TopCenter.add_child(threat_label)
	threat_label.text = "THREAT %d  •  %s" % [level, label]
	threat_label.modulate = Color(1.0, 0.55, 0.35) if level >= 5 else Color(1.0, 0.8, 0.4)

func _on_boss_spawned() -> void:
	MusicManager.set_mood("boss")
	AudioManager.play("boss_roar", 1.0, 0.0)
	VFX.screen_flash(Color(0.8, 0.2, 0.6, 0.3), 0.5)
	VFX.postfx_punch(0.8)
	if boss_panel: boss_panel.visible = true
	last_boss_phase = -1
	wave_label.text = "FINAL BOSS"
	wave_label.modulate = Color(1.0, 0.4, 0.5)

func _on_boss_health(current: float, max_hp: float) -> void:
	var prev: float = boss_hp_bar.value
	boss_hp_bar.max_value = max_hp
	if boss_chip_bar:
		boss_chip_bar.max_value = max_hp
		_update_chip_overlay_rect(boss_chip_bar)
	if current < prev - 0.01:
		boss_hp_bar.value = current
		if boss_chip_bar:
			boss_chip_bar.value = prev
			var tw := create_tween()
			tw.tween_interval(0.2)
			tw.tween_property(boss_chip_bar, "value", current, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		if boss_chip_bar: boss_chip_bar.value = current
		boss_hp_bar.value = current
	var phase_text := ""
	var boss_nodes = get_tree().get_nodes_in_group("boss")
	if boss_nodes.size() > 0 and is_instance_valid(boss_nodes[0]):
		var boss_phase = boss_nodes[0].get("phase")
		if boss_phase != null:
			var phase_int := int(boss_phase)
			phase_text = "  •  PHASE %d" % phase_int
			if last_boss_phase != -1 and phase_int != last_boss_phase and boss_panel:
				VFX.screen_flash(Color(1.0, 0.35, 0.2, 0.3), 0.3)
				var ptw := create_tween()
				boss_panel.scale = Vector2(1.08, 1.08)
				ptw.tween_property(boss_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			last_boss_phase = phase_int
	boss_label.text = "VOID TITAN%s" % phase_text

func _show_toast(text: String, col: Color = Color(1, 0.85, 0.4)) -> void:
	if not relic_toast:
		return
	relic_toast.text = text
	relic_toast.modulate = col
	relic_toast.visible = true
	relic_toast.modulate.a = 0.0
	relic_toast.scale = Vector2(0.85, 0.85)
	var base_pos: Vector2 = relic_toast.position
	relic_toast.position = base_pos + Vector2(0, 10)
	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(relic_toast, "modulate:a", 1.0, 0.18)
	tw_in.tween_property(relic_toast, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(relic_toast, "position", base_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var tw_out := create_tween()
	tw_out.tween_interval(2.2)
	tw_out.tween_property(relic_toast, "modulate:a", 0.0, 0.5)
	tw_out.tween_callback(func(): relic_toast.visible = false)

func _on_relic_gained(relic_name: String) -> void:
	_show_toast("RELIC: " + relic_name)

func _on_dash_used() -> void:
	_show_toast("DASH", Color(0.45, 0.9, 1.0))

func _on_random_event(text: String) -> void:
	_show_toast(text, Color(0.45, 1.0, 0.75))

func _on_evolution(evo_name: String) -> void:
	_show_toast("EVOLUTION: " + evo_name, Color(1.0, 0.5, 0.9))
	AudioManager.play("evolve", 1.0, -1.0)

func _on_player_leveled_up(_level: int) -> void:
	current_level = _level
	# (3.19.1) An exhausted build no longer short-circuits to heal/scrap/score: the panel
	# opens as usual and build_levelup_choices() supplies OVERCHARGE cards.
	if GameManager.is_game_over or (player and player.is_dead):
		return   # a level-up generated at the moment of death must not reopen the panel
	GameManager.is_paused = true
	get_tree().paused = true
	_show_upgrades()

func _show_upgrades() -> void:
	if GameManager.is_game_over or (player and player.is_dead):
		return
	levelup_panel.visible = true
	levelup_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for child in upgrade_container.get_children():
		# Detach immediately so the new "ChoiceCards" box keeps its name (queue_free alone
		# leaves the old sibling in place for a frame and forces an auto-rename).
		upgrade_container.remove_child(child)
		child.queue_free()
	if reroll_button:
		reroll_button.queue_free()
		reroll_button = null

	var milestone_text := "LEVEL UP"
	var special_mode := "normal"
	if GameManager.is_relic_milestone(current_level):
		milestone_text = "RELIC MILESTONE • LVL %d" % current_level
		special_mode = "relic"
	elif GameManager.is_rare_milestone(current_level):
		milestone_text = "RARE BLUEPRINT • LVL %d" % current_level
		special_mode = "rare"

	levelup_title.text = "%s  •  CHOOSE 1  •  WEAPONS %d/%d  •  REROLLS %d/%d" % [
		milestone_text,
		GameManager.weapon_slot_count(), GameManager.get_weapon_slot_limit(),
		GameManager.rerolls_available, GameManager.MAX_REROLLS_PER_RUN
	]

	var hint := Label.new()
	hint.text = "Choose 1 of %d • Weapon • System • Core — your build shapes the pool" % GameManager.LEVELUP_CHOICES
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.48, 0.56, 0.68)
	hint.custom_minimum_size = Vector2(0, 24)
	upgrade_container.add_child(hint)

	var choices: Array[Dictionary] = GameManager.build_levelup_choices(GameManager.LEVELUP_CHOICES, current_level)
	if choices.is_empty():
		var empty := Label.new()
		empty.text = "NO UPGRADES AVAILABLE"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty.add_theme_font_size_override("font_size", 20)
		empty.modulate = Color(0.45, 0.5, 0.6)
		upgrade_container.add_child(empty)
	else:
		var card_box := VBoxContainer.new()
		card_box.name = "ChoiceCards"
		card_box.add_theme_constant_override("separation", 10)
		card_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		upgrade_container.add_child(card_box)
		var idx := 0
		for up in choices:
			var card := _make_levelup_option(up)
			card_box.add_child(card)
			# Staggered slide-in from the left (tweens run while the tree is paused).
			card.modulate.a = 0.0
			card.position.x -= 60.0
			var ctw := card.create_tween()
			ctw.set_parallel(true)
			ctw.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(0.06 * idx)
			ctw.tween_property(card, "position:x", card.position.x + 60.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.06 * idx)
			idx += 1
		# Panel pop.
		levelup_panel.pivot_offset = levelup_panel.size * 0.5
		levelup_panel.scale = Vector2(0.94, 0.94)
		var ptw := levelup_panel.create_tween()
		ptw.tween_property(levelup_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var footer := Label.new()
	footer.text = "HOVER TO INSPECT  •  CLICK TO LOCK IN"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 9)
	footer.modulate = Color(0.34, 0.42, 0.54)
	footer.custom_minimum_size = Vector2(0, 18)
	upgrade_container.add_child(footer)

	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(300, 42)
	reroll_button.text = "REROLL ALL  [%d/%d]" % [GameManager.rerolls_available, GameManager.MAX_REROLLS_PER_RUN]
	reroll_button.disabled = GameManager.rerolls_available <= 0
	reroll_button.pressed.connect(_on_reroll_pressed)
	upgrade_container.add_child(reroll_button)

func _fill_levelup_choices(base: Array[Dictionary], target_count: int, rare_only: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used := {}
	for item in base:
		var item_id := str(item.get("id", ""))
		if item_id == "" or used.has(item_id):
			continue
		result.append(item)
		used[item_id] = true
		if result.size() >= target_count:
			return result
	var pool: Array[Dictionary] = GameManager.get_random_upgrades(target_count * 2, "ALL")
	if rare_only:
		pool = GameManager.get_random_rare_upgrades(target_count * 2, "ALL")
	for item in pool:
		var item_id := str(item.get("id", ""))
		if item_id == "" or used.has(item_id):
			continue
		result.append(item)
		used[item_id] = true
		if result.size() >= target_count:
			break
	return result

func _get_unified_levelup_choices(target_count: int, rare_only: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used := {}
	var weapon_slot_open := GameManager.weapon_slot_count() < GameManager.get_weapon_slot_limit()

	# Guarantee at least one weapon while the player can still add a weapon.
	if weapon_slot_open:
		var weapon_pool: Array[Dictionary] = []
		if rare_only:
			weapon_pool = GameManager.get_random_rare_upgrades(target_count * 2, "WEAPONS")
		else:
			weapon_pool = GameManager.get_random_upgrades(target_count * 2, "WEAPONS")
		if not weapon_pool.is_empty():
			var weighted_weapon := weapon_pool[randi() % weapon_pool.size()]
			result.append(weighted_weapon)
			used[str(weighted_weapon.get("id", ""))] = true

	var general: Array[Dictionary] = []
	if rare_only:
		general = GameManager.get_random_rare_upgrades(target_count * 3, "ALL")
	else:
		general = GameManager.get_random_upgrades(target_count * 3, "ALL")
	general.shuffle()
	for item in general:
		var item_id := str(item.get("id", ""))
		if item_id == "" or used.has(item_id):
			continue
		result.append(item)
		used[item_id] = true
		if result.size() >= target_count:
			break

	# If randomness couldn't fill all four slots, fill from category pools.
	if result.size() < target_count:
		result = _fill_levelup_choices(result, target_count, rare_only)
	return result.slice(0, target_count)

func _make_levelup_option(up: Dictionary) -> Button:
	var rarity: int = int(up.get("rarity", 0))
	var is_relic: bool = bool(up.get("is_relic", false))
	var is_cursed: bool = bool(up.get("is_cursed", false))
	var category: String = str(up.get("category", "MODIFIERS" if (is_relic or is_cursed) else "UPGRADES"))
	var level: int = int(up.get("current_level", 0))
	var max_level: int = GameManager.MAX_WEAPON_LEVEL if category == "WEAPONS" else (GameManager.MAX_SYSTEM_LEVEL if category == "SYSTEMS" else (999 if category == "OVERCHARGE" else GameManager.core_cap(str(up.get("id", "")))))
	var name: String = str(up.get("name", "UNKNOWN"))
	var details: String = str(up.get("details", up.get("desc", "")))
	var compat: String = ""
	var system_effect: String = ""
	if category == "SYSTEMS":
		compat = GameManager.get_system_compatibility(str(up.get("id", "")))
		system_effect = GameManager.get_system_effect_text(str(up.get("id", "")))
	var effect: String = str(up.get("rolled_desc", up.get("desc", "")))
	var rarity_name: String = "RELIC" if is_relic else ("CURSED" if is_cursed else ("WEAPON" if category == "WEAPONS" else str(GameManager.get_rarity_name(rarity))))
	var next_level: int = mini(level + 1, max_level)
	var border: Color = RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]
	if category == "WEAPONS":
		border = Color(up.get("icon_color", Color(0.45, 0.85, 1.0)))
	if is_relic:
		border = Color(up.get("icon_color", Color(0.5, 0.9, 1.0)))
	elif is_cursed:
		border = Color(1.0, 0.25, 0.35)

	var btn := Button.new()
	btn.set_meta("up", up)
	btn.custom_minimum_size = Vector2(700, 154)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_ALL
	btn.flat = false
	btn.text = ""
	var tooltip_details: String = details
	if compat != "":
		tooltip_details += "\n\nCompatible weapons: " + compat
		if system_effect != "":
			tooltip_details += "\nWhat it does here: " + system_effect
	# (3.18) no hover tooltip on in-run level-up cards: the card already shows everything.
	btn.tooltip_text = ""

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.045, 0.06, 0.10, 0.99)
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.14, 0.21, 1.0)
	hover.border_color = Color(1.0, 1.0, 1.0, 0.95)
	hover.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	var accent: Color = Color(border.r, border.g, border.b, 1.0)
	var arrow: Label = Label.new()
	arrow.text = "➜"
	arrow.position = Vector2(-18, 37)
	arrow.size = Vector2(34, 48)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 30)
	arrow.add_theme_color_override("font_color", accent)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.visible = false
	btn.add_child(arrow)

	var rarity_badge: Label = Label.new()
	rarity_badge.text = rarity_name
	if category == "WEAPONS":
		rarity_badge.text = "WEAPON"
	rarity_badge.position = Vector2(20, 10)
	rarity_badge.size = Vector2(160, 22)
	rarity_badge.add_theme_font_size_override("font_size", 10)
	rarity_badge.add_theme_color_override("font_color", accent)
	rarity_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(rarity_badge)

	var category_badge: Label = Label.new()
	category_badge.text = category
	category_badge.position = Vector2(500, 10)
	category_badge.size = Vector2(175, 22)
	category_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	category_badge.add_theme_font_size_override("font_size", 10)
	category_badge.add_theme_color_override("font_color", Color(0.65, 0.73, 0.84))
	category_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(category_badge)

	var icon_kind := "misc"
	var icon_id := "upgrade"
	if category == "WEAPONS" and GameManager.WEAPON_DEFS.has(str(up.get("id", ""))):
		icon_kind = "weapon"
		icon_id = str(up.get("id", ""))
	elif is_relic:
		icon_id = "relic"
	elif is_cursed:
		icon_id = "cursed"
	else:
		icon_id = GameIcons.misc_id_for_upgrade(str(up.get("id", "")), category)
	var card_icon := IconView.make(icon_kind, icon_id, accent, 58)
	card_icon.position = Vector2(20, 40)
	card_icon.glow = 0.4 if (is_relic or rarity >= 2) else 0.0
	btn.add_child(card_icon)

	var name_label: Label = Label.new()
	name_label.text = name
	name_label.position = Vector2(92, 33)
	name_label.size = Vector2(580, 30)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = details
	desc_label.position = Vector2(92, 60)
	desc_label.size = Vector2(580, 25 if compat != "" else 30)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.62, 0.70, 0.80))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(desc_label)

	var effect_label: Label = Label.new()
	effect_label.text = effect
	effect_label.position = Vector2(92, 105 if compat != "" else 91)
	effect_label.size = Vector2(400, 25)
	effect_label.add_theme_font_size_override("font_size", 13)
	effect_label.add_theme_color_override("font_color", accent)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(effect_label)

	var level_label: Label = Label.new()
	level_label.text = "%d/%d" % [level, next_level] if is_relic else ("LEVEL %d → %d" % [level, next_level])
	level_label.position = Vector2(500, 105 if compat != "" else 91)
	level_label.size = Vector2(175, 25)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(level_label)

	if compat != "":
		var compat_label := Label.new()
		var compat_count: int = compat.split(" • ").size()
		compat_label.text = "WORKS WITH  %s" % compat
		compat_label.position = Vector2(92, 84)
		compat_label.size = Vector2(583, 18)
		compat_label.add_theme_font_size_override("font_size", 9)
		compat_label.add_theme_color_override("font_color", Color(0.42, 0.72, 0.82))
		compat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		compat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(compat_label)

	var synergy_hint: String = _get_synergy_hint(str(up.get("id", "")))
	if synergy_hint != "":
		var synergy_label: Label = Label.new()
		synergy_label.text = synergy_hint
		synergy_label.position = Vector2(92, 128)
		synergy_label.size = Vector2(583, 24)
		synergy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		synergy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		synergy_label.clip_text = false
		synergy_label.add_theme_font_size_override("font_size", 9)
		synergy_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.92))
		synergy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(synergy_label)

	btn.pivot_offset = Vector2(350, 77)
	btn.mouse_entered.connect(func():
		arrow.visible = true
		card_icon.glow = 1.0
		AudioManager.play("ui_hover", 1.0, -10.0)
		var htw := btn.create_tween()
		htw.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		arrow.visible = false
		card_icon.glow = 0.4 if (is_relic or rarity >= 2) else 0.0
		var htw := btn.create_tween()
		htw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	btn.pressed.connect(func(): AudioManager.play("ui_confirm", 1.0, -5.0))
	if is_relic:
		btn.pressed.connect(_on_relic_chosen.bind(str(up.get("relic_id", ""))))
	elif is_cursed:
		btn.pressed.connect(_on_cursed_chosen.bind(str(up.get("cursed_id", ""))))
	else:
		btn.pressed.connect(_on_upgrade_chosen.bind(str(up.get("id", "")), rarity))
	return btn

func _get_synergy_hint(upgrade_id: String) -> String:
	if not GameManager.WEAPON_DEFS.has(upgrade_id):
		return ""
	var names: Array[String] = []
	for synergy_id in GameManager.WEAPON_SYNERGIES.keys():
		var data: Dictionary = GameManager.WEAPON_SYNERGIES[synergy_id]
		var reqs: Array = data.get("requires", [])
		if upgrade_id not in reqs:
			continue
		var other_id := str(reqs[0] if str(reqs[1]) == upgrade_id else reqs[1])
		var other_level := GameManager.get_upgrade_level(other_id)
		if other_level > 0 and other_level < GameManager.MAX_WEAPON_LEVEL:
			var other_name := str(GameManager.WEAPON_DEFS[other_id].name)
			names.append("SYNERGY PATH  •  %s  %d/%d" % [other_name, other_level, GameManager.MAX_WEAPON_LEVEL])
		elif other_level >= GameManager.MAX_WEAPON_LEVEL:
			names.append("SUPERWEAPON READY AT MAX  •  %s 5/5" % str(GameManager.WEAPON_DEFS[other_id].name))
	if names.is_empty():
		return ""
	return names[0]

func _on_reroll_pressed() -> void:
	if not GameManager.use_reroll():
		return
	_show_upgrades()

func _on_upgrade_chosen(upgrade_id: String, rarity: int = 0) -> void:
	if GameManager.is_game_over or (player and player.is_dead):
		return
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade_id, rarity)
	levelup_panel.visible = false
	GameManager.is_paused = false
	get_tree().paused = false

func _on_cursed_chosen(cursed_id: String) -> void:
	if GameManager.is_game_over or (player and player.is_dead):
		return
	GameManager.apply_cursed_upgrade(cursed_id)
	levelup_panel.visible = false
	GameManager.is_paused = false
	get_tree().paused = false

func _on_relic_chosen(relic_id: String) -> void:
	if GameManager.is_game_over or (player and player.is_dead):
		return
	GameManager.gain_relic(relic_id)
	levelup_panel.visible = false
	GameManager.is_paused = false
	get_tree().paused = false

func show_merchant_shop(merchant: Node) -> void:
	AudioManager.play("merchant", 1.0, -2.0)
	current_merchant = merchant
	GameManager.open_merchant_visit()
	merchant_title.text = "WANDERING MERCHANT  •  VISIT %d" % GameManager.merchant_visit
	_render_merchant_offers("RUN SCRAP: %d   •   BANKED RESERVE: %d" % [GameManager.scrap, GameManager.banked_scrap])
	merchant_panel.visible = true

func _render_merchant_offers(status: String) -> void:
	merchant_scrap.text = status
	for child in merchant_container.get_children():
		merchant_container.remove_child(child)
		child.queue_free()
	for o in GameManager.merchant_offers:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(300, 56)
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bought: bool = bool(o.get("bought", false))
		btn.text = "%s  [%d SCRAP]\n%s" % [o.name, int(o.cost), ("SOLD" if bought else o.desc)]
		btn.disabled = bought or GameManager.scrap < int(o.get("cost", 0))
		btn.add_theme_color_override("font_color", Color(o.get("color", Color.WHITE)).lightened(0.2))
		btn.set_meta("offer", o)
		btn.pressed.connect(_on_merchant_buy.bind(o))
		VisualTheme.add_button_feedback(btn)
		merchant_container.add_child(btn)
	# Paid refresh, once per visit.
	var rf = Button.new()
	rf.custom_minimum_size = Vector2(300, 40)
	rf.add_theme_font_size_override("font_size", 11)
	rf.text = ("NEW STOCK  [%d SCRAP]  •  once per visit" % GameManager.merchant_refresh_cost()) if not GameManager.merchant_refreshed else "STOCK ALREADY REFRESHED"
	rf.disabled = GameManager.merchant_refreshed or GameManager.scrap < GameManager.merchant_refresh_cost()
	rf.pressed.connect(func():
		if GameManager.merchant_refresh():
			AudioManager.play("ui_confirm", 1.2, -5.0)
			_render_merchant_offers("NEW STOCK\nRUN SCRAP: %d   •   BANKED RESERVE: %d" % [GameManager.scrap, GameManager.banked_scrap]))
	VisualTheme.add_button_feedback(rf)
	merchant_container.add_child(rf)

func _on_merchant_buy(offer: Dictionary) -> void:
	if GameManager.is_game_over or (player and player.is_dead):
		return
	if bool(offer.get("bought", false)):
		return
	if not GameManager.spend_scrap(int(offer.cost)):
		merchant_scrap.text = "Need %d more run scrap." % (int(offer.cost) - GameManager.scrap)
		return
	var result := "PURCHASED: %s" % str(offer.name).to_upper()
	match str(offer.kind):
		"weapon", "system", "core":
			if player:
				player.apply_upgrade(str(offer.id), int(offer.get("rarity", 0)))
		"relic":
			GameManager.gain_relic(str(offer.id))
		"reroll":
			GameManager.grant_reroll()
			GameManager.merchant_reroll_bought = true
		"heal":
			if player:
				var before = player.current_hp
				player.heal(player.max_hp * 0.40)
				result = "HULL REPAIRED  •  +%d HP" % int(round(player.current_hp - before))
		"shield":
			if player: player.has_second_wind = true; player.second_wind_used = false
		"magnet":
			if player: player.activate_vacuum(6.0, false)
	offer["bought"] = true
	GameManager.merchant_purchases += 1
	# Each purchase nudges the remaining prices up for this visit.
	for o in GameManager.merchant_offers:
		if not bool(o.get("bought", false)):
			o["cost"] = int(float(o["cost"]) * 1.2)
	_render_merchant_offers("%s\nRUN SCRAP: %d   •   BANKED RESERVE: %d" % [result, GameManager.scrap, GameManager.banked_scrap])

func _on_merchant_leave() -> void:
	merchant_panel.visible = false
	GameManager.is_paused = false
	get_tree().paused = false
	if current_merchant and current_merchant.has_method("close_and_leave"):
		current_merchant.close_and_leave()
	current_merchant = null

func _on_player_died() -> void:
	# Authoritative dead state for the UI: close every selection surface and refuse input.
	levelup_panel.visible = false
	merchant_panel.visible = false
	for child in upgrade_container.get_children():
		upgrade_container.remove_child(child); child.queue_free()
	get_tree().paused = false
	GameManager.is_paused = false
	if player:
		player.current_hp = 0.0
	_on_health_changed(0.0, player.max_hp if player else 1.0)
	MusicManager.set_mood("calm")
	GameManager.finalize_run(false)
	gameover_panel.visible = true
	final_score.text = "Score  %d" % GameManager.score
	var t = GameManager.game_time
	final_time.text = "SCRAP EARNED %d  •  SPENT %d  •  SECURED %d  •  BANKED %d\nSURVIVED %02d:%02d   •   KILLS %d   •   SECTORS %d" % [GameManager.run_scrap_earned, GameManager.run_scrap_spent, GameManager.scrap, GameManager.banked_scrap, int(t) / 60, int(t) % 60, GameManager.run_kills, GameManager.sector_index + 1]
	if final_damage:
		final_damage.text = GameManager.get_damage_chart_bbcode()
	get_tree().paused = true

func _on_victory() -> void:
	MusicManager.set_mood("menu")
	AudioManager.play("synergy", 1.0, 0.0)
	GameManager.finalize_run(true)
	victory_panel.visible = true
	victory_score.text = "Score %d\nSCRAP EARNED %d  •  SPENT %d  •  SECURED %d  •  BANKED %d" % [GameManager.score, GameManager.run_scrap_earned, GameManager.run_scrap_spent, GameManager.scrap, GameManager.banked_scrap]
	if victory_damage:
		victory_damage.text = GameManager.get_damage_chart_bbcode()
	if boss_panel: boss_panel.visible = false
	get_tree().paused = true

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
