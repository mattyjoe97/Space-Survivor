extends Control

@onready var star_bg: Node2D = $StarBG
@onready var content: VBoxContainer = $Center/Content
var progression_panel: PanelContainer
var progression_box: VBoxContainer
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var fullscreen_check: CheckButton = $SettingsPanel/Margin/VBox/FullscreenCheck
@onready var close_settings: Button = $SettingsPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	MusicManager.set_mood("menu")
	_generate_menu_stars()
	$Center/Content/LaunchBtn.pressed.connect(_launch)
	$Center/Content/HangarBtn.pressed.connect(_hangar)
	$Center/Content/SettingsBtn.pressed.connect(_open_settings)
	$Center/Content/QuitBtn.pressed.connect(_quit)
	_add_extra_menu_buttons()
	_style_menu_buttons()
	close_settings.pressed.connect(_close_settings)
	_build_progression_ui()
	fullscreen_check.toggled.connect(_toggle_fullscreen)
	_build_settings_controls()
	settings_panel.visible = false
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _style_menu_buttons() -> void:
	# Keep the title area clean; style only the actual interactive controls.
	for node in content.get_children():
		if node is Button:
			VisualTheme.style_button(node, VisualTheme.CYAN)
	VisualTheme.style_panel(settings_panel, VisualTheme.CYAN)

func _launch() -> void:
	GameManager.run_mode = "standard"
	GameManager.reset()
	call_deferred("_change_to_run")

func _launch_endless() -> void:
	GameManager.run_mode = "endless"
	GameManager.reset()
	call_deferred("_change_to_run")

func _change_to_run() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _add_extra_menu_buttons() -> void:
	var progression = Button.new()
	progression.name = "ProgressionBtn"
	progression.text = "PROGRESSION"
	progression.custom_minimum_size = Vector2(340, 48)
	progression.add_theme_font_size_override("font_size", 17)
	progression.pressed.connect(_open_progression)
	content.add_child(progression)
	content.move_child(progression, 3)
	var endless = Button.new()
	endless.name = "EndlessBtn"
	endless.text = "ENDLESS MODE"
	endless.custom_minimum_size = Vector2(340, 44)
	endless.add_theme_font_size_override("font_size", 15)
	endless.pressed.connect(_launch_endless)
	content.add_child(endless)
	content.move_child(endless, 4)

func _build_progression_ui() -> void:
	progression_panel = PanelContainer.new()
	progression_panel.set_anchors_preset(Control.PRESET_CENTER)
	progression_panel.position = Vector2(-450, -330)
	progression_panel.size = Vector2(900, 660)
	progression_panel.visible = false
	var panel_style := VisualTheme.panel_style(VisualTheme.CYAN)
	panel_style.bg_color = Color(VisualTheme.BG.r, VisualTheme.BG.g, VisualTheme.BG.b, 0.88)
	progression_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(progression_panel)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	progression_panel.add_child(margin)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	progression_box = VBoxContainer.new()
	progression_box.add_theme_constant_override("separation", 10)
	scroll.add_child(progression_box)
	var title = Label.new(); title.text = "PROGRESSION CENTER"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 26); progression_box.add_child(title)
	var status = Label.new(); status.name = "Status"; status.text = GameManager.get_progress_summary(); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; progression_box.add_child(status)
	var armory = Button.new(); armory.text = "ARMORY — PERMANENT UPGRADES"; armory.tooltip_text = "Spend banked Scrap on permanent upgrades that persist between runs."; armory.pressed.connect(_armory); progression_box.add_child(armory)
	var codex = Button.new(); codex.text = "CODEX / DISCOVERIES"; codex.tooltip_text = "Browse discovered enemies and weapon evolutions. Hover entries for details."; codex.pressed.connect(_codex); progression_box.add_child(codex)
	var achievements = Button.new(); achievements.text = "ACHIEVEMENTS"; achievements.tooltip_text = "Track milestones. Hover an achievement to see its requirement and progress."; achievements.pressed.connect(_achievements); progression_box.add_child(achievements)
	var close = Button.new(); close.text = "BACK"; close.pressed.connect(func(): progression_panel.visible = false); progression_box.add_child(close)
	_build_progression_home()

func _open_progression() -> void:
	progression_panel.visible = true
	_build_progression_home()

func _build_progression_home() -> void:
	_clear_progression_box()
	var title = Label.new(); title.text = "PROGRESSION CENTER"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 26); progression_box.add_child(title)
	var status = Label.new(); status.text = GameManager.get_progress_summary(); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.tooltip_text = "Your persistent progression: banked Scrap, completed runs, and total kills."; progression_box.add_child(status)
	var armory = Button.new(); armory.text = "ARMORY — PERMANENT UPGRADES"; armory.tooltip_text = "Spend banked Scrap on permanent upgrades that persist between runs."; armory.pressed.connect(_armory); progression_box.add_child(armory)
	var codex = Button.new(); codex.text = "CODEX / DISCOVERIES"; codex.tooltip_text = "Browse discovered enemies and weapon evolutions. Hover entries for details."; codex.pressed.connect(_codex); progression_box.add_child(codex)
	var achievements = Button.new(); achievements.text = "ACHIEVEMENTS"; achievements.tooltip_text = "Track milestones. Hover an achievement to see its requirement and progress."; achievements.pressed.connect(_achievements); progression_box.add_child(achievements)
	var contracts = Button.new(); contracts.text = "CURRENT CONTRACTS"; contracts.tooltip_text = "View active contracts and their Scrap rewards."; contracts.pressed.connect(_contracts); progression_box.add_child(contracts)
	var close = Button.new(); close.text = "BACK"; close.pressed.connect(func(): progression_panel.visible = false); progression_box.add_child(close)

func _clear_progression_box() -> void:
	while progression_box.get_child_count() > 0:
		var c := progression_box.get_child(0)
		progression_box.remove_child(c)
		c.queue_free()

func _show_list(title_text: String, lines: Array[String]) -> void:
	_clear_progression_box()
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	progression_box.add_child(title)
	for line in lines:
		var l = Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 13)
		progression_box.add_child(l)
	var back = Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 42)
	back.tooltip_text = "Return to the Progression Center."
	back.pressed.connect(_build_progression_home)
	progression_box.add_child(back)

func _contracts() -> void:
	var lines: Array[String] = []
	for c in GameManager.current_contracts:
		lines.append("%s — %d/%d — +%d banked scrap" % [c.title, int(c.progress), int(c.target), int(c.reward)])
	_show_list("CONTRACTS", lines)

func _armory() -> void:
	_clear_progression_box()
	var title = Label.new()
	title.text = "SCRAP LAB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	progression_box.add_child(title)
	var status = Label.new()
	status.text = "BANKED SCRAP: %d    •    Permanent upgrades persist between runs" % GameManager.banked_scrap
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.modulate = Color(0.55, 0.85, 1.0)
	progression_box.add_child(status)
	var hint = Label.new()
	hint.text = "Caps vary by upgrade. Core combat stats have more runway; economy and utility are intentionally limited."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(0.48, 0.55, 0.68)
	progression_box.add_child(hint)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	progression_box.add_child(grid)

	var defs = [
		["damage", "WEAPONS RESEARCH", "+4% weapon damage", 4.0],
		["fire_rate", "REACTOR TUNING", "+2% fire rate", 2.0],
		["weapons_core", "WEAPONS CORE", "+2.5% weapon damage", 2.5],
		["crit", "TARGETING SUITE", "+1.5% crit chance", 1.5],
		["hull", "HULL ENGINEERING", "+5% max hull", 5.0],
		["defense_core", "DEFENSE CORE", "+2.5% hull / +0.5% speed", 2.5],
		["speed", "THRUSTER CALIBRATION", "+2% move speed", 2.0],
		["magnet", "SALVAGE MAGNET", "+6% pickup range", 6.0],
		["xp", "NEURAL PROCESSING", "+4% XP gain", 4.0],
		["luck", "FORTUNE MATRIX", "+2 Luck", 2.0],
		["scrap", "SALVAGE PROTOCOL", "+5% Scrap earned", 5.0],
		["economy_core", "ECONOMY CORE", "+1% Scrap & Luck", 1.0],
		["arsenal", "ARSENAL EXPANSION", "+1 weapon slot", 1.0]
	]
	for d in defs:
		var id: String = d[0]
		var lv := int(GameManager.permanent_upgrades.get(id, 0))
		var cap := GameManager.get_permanent_upgrade_cap(id)
		var card = VBoxContainer.new()
		card.custom_minimum_size = Vector2(300, 78)
		var name_label = Label.new()
		name_label.text = "%s  [%d/%d]" % [d[1], lv, cap]
		name_label.add_theme_font_size_override("font_size", 13)
		card.add_child(name_label)
		var desc = Label.new()
		desc.text = d[2]
		desc.modulate = Color(0.62, 0.7, 0.82)
		desc.add_theme_font_size_override("font_size", 11)
		card.add_child(desc)
		var next_cost := 250 + lv * 225
		if id == "arsenal":
			next_cost = [2500, 9000][mini(lv, 1)] if lv < 2 else 0
		card.tooltip_text = d[1] + "\nCurrent Level: %d / %d\nEffect: %s\nNext Cost: %s" % [lv, cap, d[2], "MAXED" if lv >= cap else str(next_cost) + " Scrap"]
		var buy = Button.new()
		buy.custom_minimum_size = Vector2(0, 30)
		buy.text = "MAXED" if lv >= cap else "UPGRADE  •  %d SCRAP" % next_cost
		buy.disabled = lv >= cap or GameManager.banked_scrap < next_cost
		buy.pressed.connect(_buy_armory.bind(id))
		card.add_child(buy)
		grid.add_child(card)

	var divider = HSeparator.new()
	progression_box.add_child(divider)
	var unlock_title = Label.new()
	unlock_title.text = "ARSENAL UNLOCK"
	unlock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_title.add_theme_font_size_override("font_size", 16)
	progression_box.add_child(unlock_title)
	var back = Button.new()
	back.text = "BACK"
	back.pressed.connect(_build_progression_home)
	progression_box.add_child(back)

func _buy_armory(id: String) -> void:
	var level := int(GameManager.permanent_upgrades.get(id, 0))
	var cost := 250 + level * 225
	if GameManager.buy_permanent_upgrade(id, cost):
		_armory()

func _codex() -> void:
	_clear_progression_box()
	var title = Label.new()
	title.text = "CODEX // INTELLIGENCE ARCHIVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	progression_box.add_child(title)
	var hint = Label.new()
	hint.text = "Hover an entry for details. Discovered entries reveal tactical information."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.52, 0.62, 0.76)
	hint.add_theme_font_size_override("font_size", 11)
	progression_box.add_child(hint)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	progression_box.add_child(grid)

	var enemy_defs = [
		["chaser", "CHASER", "Basic pursuer. Fast approach and direct contact damage."],
		["swarmer", "SWARMER", "Light enemy that appears in groups and overwhelms by numbers."],
		["armored", "ARMORED", "Slow heavy target with increased durability."],
		["leecher", "LEECHER", "Aggressive parasite enemy designed to pressure sustained movement."],
		["teleporter", "TELEPORTER", "Unpredictable enemy that changes position around the battlefield."],
		["sniper", "SNIPER", "Long-range threat that attacks from a distance."],
		["splitter", "SPLITTER", "Dangerous target that creates additional threats when destroyed."],
		["void_spitter", "VOID SPITTER", "Ranged void entity that fires dangerous projectiles."],
		["elite", "ELITE", "Elite-class enemy with increased health and stronger attacks."],
		["void_titan", "VOID TITAN", "The run's major boss. Defeating it completes the boss codex entry."],
	]
	for d in enemy_defs:
		var discovered := bool(GameManager.codex_entries.get(d[0], false))
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 128)
		card.tooltip_text = (d[1] + "\n" + d[2]) if discovered else (d[1] + "\n\nUndiscovered — encounter this enemy to reveal its entry.")
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		card.add_child(box)
		var icon_id: String = str(d[0])
		if icon_id == "elite": icon_id = "elite_rammer"
		elif icon_id == "void_titan": icon_id = "boss"
		var icon_col: Color = Color(1.0, 0.35, 0.45) if discovered else Color(0.35, 0.4, 0.5)
		if discovered:
			var es: Dictionary = {"swarmer": Color(1.0,0.42,0.12), "armored": Color(0.72,0.56,0.28), "leecher": Color(0.25,0.95,0.55), "teleporter": Color(0.68,0.35,1.0), "sniper": Color(0.35,0.8,1.0), "splitter": Color(1.0,0.3,0.7), "void_spitter": Color(0.92,0.3,0.72), "elite": Color(1.0,0.45,0.18), "void_titan": Color(0.92,0.18,0.42)}
			icon_col = es.get(str(d[0]), Color(1.0, 0.24, 0.38))
		var icon_holder := CenterContainer.new()
		icon_holder.add_child(IconView.make("enemy", icon_id, icon_col, 40))
		box.add_child(icon_holder)
		var name_label = Label.new()
		name_label.text = d[1] if discovered else "???"
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_label)
		var state = Label.new()
		state.text = "DISCOVERED" if discovered else "LOCKED"
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state.modulate = Color(0.45, 0.9, 0.7) if discovered else Color(0.5, 0.54, 0.62)
		state.add_theme_font_size_override("font_size", 10)
		box.add_child(state)
		grid.add_child(card)

	var evo_title = Label.new()
	evo_title.text = "EVOLUTIONS"
	evo_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evo_title.add_theme_font_size_override("font_size", 16)
	progression_box.add_child(evo_title)
	var evo_grid = GridContainer.new()
	evo_grid.columns = 3
	evo_grid.add_theme_constant_override("h_separation", 10)
	evo_grid.add_theme_constant_override("v_separation", 8)
	progression_box.add_child(evo_grid)
	for evo_id in GameManager.EVOLUTIONS.keys():
		var evo = GameManager.EVOLUTIONS[evo_id]
		var active := GameManager.active_evolutions.has(evo_id)
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 64)
		var evo_reqs: Array = []
		for rid in evo.requires:
			evo_reqs.append(str(GameManager.WEAPON_DEFS.get(rid, {}).get("name", rid)))
		card.tooltip_text = evo.name + "\n" + evo.desc + "\nRequires: " + " + ".join(evo_reqs)
		var l = Label.new()
		l.text = evo.name + ("\nUNLOCKED" if active else "\nLOCKED")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		card.add_child(l)
		evo_grid.add_child(card)

	var syn_title = Label.new()
	syn_title.text = "WEAPON SYNERGIES"
	syn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	syn_title.add_theme_font_size_override("font_size", 16)
	progression_box.add_child(syn_title)
	var syn_grid = GridContainer.new()
	syn_grid.columns = 2
	syn_grid.add_theme_constant_override("h_separation", 10)
	syn_grid.add_theme_constant_override("v_separation", 8)
	progression_box.add_child(syn_grid)
	for synergy_id in GameManager.WEAPON_SYNERGIES.keys():
		var synergy = GameManager.WEAPON_SYNERGIES[synergy_id]
		var discovered := bool(GameManager.codex_entries.get("synergy_" + synergy_id, false))
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)
		var req_names: Array = []
		for rid in synergy.requires:
			req_names.append(str(GameManager.WEAPON_DEFS.get(rid, {}).get("name", rid)))
		if discovered:
			card.tooltip_text = str(synergy.name) + "\n" + str(synergy.desc) + "\nRequires: " + " + ".join(req_names)
		else:
			card.tooltip_text = "██████████\n???\nRequires: " + " + ".join(req_names) + "\nMax both weapons to unlock."

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var reqs: Array = synergy.requires
		for wid in reqs:
			row.add_child(IconView.make("weapon", str(wid), (GameManager.WEAPON_DEFS[wid].color if discovered else Color(0.4, 0.45, 0.55)), 34))
		var lab = Label.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.text = (str(synergy.name) if discovered else "???") + ("\nDISCOVERED" if discovered else "\nUNDISCOVERED")
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 11)
		lab.modulate = synergy.color if discovered else Color(0.45,0.5,0.6)
		row.add_child(lab)
		syn_grid.add_child(card)

	var back = Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 42)
	back.tooltip_text = "Return to the Progression Center."
	back.pressed.connect(_build_progression_home)
	progression_box.add_child(back)

func _achievements() -> void:
	_clear_progression_box()
	var title = Label.new()
	title.text = "ACHIEVEMENTS // MILESTONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	progression_box.add_child(title)
	var hint = Label.new()
	hint.text = "Hover an achievement to see exactly what is required and your current progress."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.52, 0.62, 0.76)
	hint.add_theme_font_size_override("font_size", 11)
	progression_box.add_child(hint)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	progression_box.add_child(grid)

	var defs = [
		["first_blood", "FIRST BLOOD", "Kill 1 enemy.", "%d / 1 kills" % int(GameManager.total_kills)],
		["centurion", "CENTURION", "Kill 100 enemies.", "%d / 100 kills" % mini(int(GameManager.total_kills), 100)],
		["elite_hunter", "ELITE HUNTER", "Defeat 10 elite enemies.", "%d / 10 elites" % mini(int(GameManager.elites_killed), 10)],
		["void_slayer", "VOID SLAYER", "Defeat the Void Titan.", "%d / 1 boss" % (1 if GameManager.codex_entries.has("void_titan") else 0)],
		["fully_armed", "FULLY ARMED", "Fill all 8 core upgrade slots during a run.", "%d / 8 slots" % mini(GameManager.unique_upgrade_count(), 8)],
		["mastery_100", "SHIP MASTERY", "Get 500 mastery kills on your selected ship.", "%d / 500 kills" % mini(int(GameManager.mastery_kills.get(GameManager.selected_character, 0)), 500)],
		["survivor", "SURVIVOR", "Survive for 6 minutes.", "%d / 360 sec" % mini(int(GameManager.game_time), 360)],
		["collector", "COLLECTOR", "Hold 4 relics in one run.", "%d / 4 relics" % mini(GameManager.active_relics.size(), 4)],
		["evolver", "EVOLVER", "Unlock 1 weapon evolution.", "%d / 1 evolutions" % mini(GameManager.active_evolutions.size(), 1)],
		["endless", "ENDLESS ADEPT", "Survive 3 minutes in Endless Mode.", "%d / 180 sec" % mini(int(GameManager.endless_time), 180)],
	]
	for d in defs:
		var id: String = d[0]
		var unlocked := bool(GameManager.achievements.get(id, false))
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 76)
		card.tooltip_text = d[1] + "\nRequirement: " + d[2] + "\nProgress: " + d[3] + "\nStatus: " + ("COMPLETED" if unlocked else "IN PROGRESS")
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		card.add_child(box)
		var name_label = Label.new()
		name_label.text = ("✓  " if unlocked else "○  ") + d[1]
		name_label.add_theme_font_size_override("font_size", 13)
		box.add_child(name_label)
		var req = Label.new()
		req.text = "COMPLETED" if unlocked else d[2]
		req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		req.modulate = Color(0.45, 0.9, 0.7) if unlocked else Color(0.65, 0.7, 0.8)
		req.add_theme_font_size_override("font_size", 10)
		box.add_child(req)
		grid.add_child(card)

	var back = Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 42)
	back.tooltip_text = "Return to the Progression Center."
	back.pressed.connect(_build_progression_home)
	progression_box.add_child(back)

func _hangar() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _open_settings() -> void:
	settings_panel.visible = true
	content.modulate.a = 0.35
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.grab_focus()

func _close_settings() -> void:
	settings_panel.visible = false
	content.modulate.a = 1.0
	$Center/Content/SettingsBtn.grab_focus()

func _build_settings_controls() -> void:
	var box: VBoxContainer = $SettingsPanel/Margin/VBox
	var damage = CheckButton.new(); damage.name = "DamageNumbersCheck"; damage.text = "Show Damage Numbers"; damage.button_pressed = SettingsManager.damage_numbers
	damage.toggled.connect(func(v): SettingsManager.damage_numbers = v; SettingsManager.save())
	box.add_child(damage); box.move_child(damage, box.get_child_count() - 1)
	var shake = CheckButton.new(); shake.text = "Screen Shake"; shake.button_pressed = SettingsManager.screen_shake
	shake.toggled.connect(func(v): SettingsManager.screen_shake = v; SettingsManager.save())
	box.add_child(shake); box.move_child(shake, box.get_child_count() - 1)
	var postfx = CheckButton.new(); postfx.text = "Screen Effects (vignette / distortion)"; postfx.button_pressed = SettingsManager.post_fx
	postfx.toggled.connect(func(v): SettingsManager.set_post_fx(v))
	box.add_child(postfx); box.move_child(postfx, box.get_child_count() - 1)
	var floating = CheckButton.new(); floating.text = "Floating Combat Text"; floating.button_pressed = SettingsManager.floating_text
	floating.toggled.connect(func(v): SettingsManager.floating_text = v; SettingsManager.save())
	box.add_child(floating); box.move_child(floating, box.get_child_count() - 1)
	var attack_row := HBoxContainer.new()
	var attack_lab := Label.new(); attack_lab.text = "ATTACK MODE"; attack_lab.custom_minimum_size = Vector2(115, 28); attack_row.add_child(attack_lab)
	var attack_select := OptionButton.new(); attack_select.name = "AttackModeSelect"; attack_select.add_item("AUTO TARGET"); attack_select.add_item("MANUAL AIM")
	attack_select.selected = 1 if SettingsManager.attack_mode == "manual" else 0
	attack_select.item_selected.connect(func(index): SettingsManager.set_attack_mode("manual" if index == 1 else "auto"))
	attack_row.add_child(attack_select); box.add_child(attack_row); box.move_child(attack_row, box.get_child_count() - 1)
	var assist_row := HBoxContainer.new()
	var assist_lab := Label.new(); assist_lab.text = "AIM ASSIST"; assist_lab.custom_minimum_size = Vector2(115, 28); assist_row.add_child(assist_lab)
	var assist_select := OptionButton.new(); assist_select.name = "AimAssistSelect"; assist_select.add_item("OFF"); assist_select.add_item("LOW"); assist_select.add_item("HIGH")
	match SettingsManager.manual_aim_assist:
		"off": assist_select.selected = 0
		"low": assist_select.selected = 1
		_: assist_select.selected = 2
	assist_select.item_selected.connect(func(index): SettingsManager.set_manual_aim_assist(["off", "low", "high"][index]))
	assist_row.add_child(assist_select); box.add_child(assist_row); box.move_child(assist_row, box.get_child_count() - 1)
	for item in [["MASTER", SettingsManager.master_volume, "set_master"], ["MUSIC", SettingsManager.music_volume, "set_music"], ["EFFECTS", SettingsManager.effects_volume, "set_effects"]]:
		var row = HBoxContainer.new()
		var lab = Label.new(); lab.text = item[0]; lab.custom_minimum_size = Vector2(70, 28); row.add_child(lab)
		var slider = HSlider.new(); slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05; slider.value = item[1]; slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label = Label.new(); value_label.custom_minimum_size = Vector2(45, 28); value_label.text = "%d%%" % int(slider.value * 100.0)
		slider.value_changed.connect(func(v, l=value_label, method=item[2]): l.text = "%d%%" % int(v * 100.0); SettingsManager.call(method, v))
		row.add_child(slider); row.add_child(value_label); box.add_child(row)
		box.move_child(row, box.get_child_count() - 1)
	box.move_child(close_settings, box.get_child_count() - 1)

func _toggle_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and progression_panel and progression_panel.visible:
		progression_panel.visible = false
	elif event.is_action_pressed("ui_cancel") and settings_panel.visible:
		_close_settings()

func _generate_menu_stars() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(150):
		var star = Polygon2D.new()
		var s = rng.randf_range(0.7, 2.3)
		star.polygon = PackedVector2Array([Vector2(-s,0), Vector2(0,-s), Vector2(s,0), Vector2(0,s)])
		var b = rng.randf_range(0.35, 1.0)
		star.color = Color(b, b, min(1.0, b * 1.06), rng.randf_range(0.3, 0.85))
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720))
		star_bg.add_child(star)
