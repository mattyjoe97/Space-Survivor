extends Node

const SAVE_PATH := "user://space_survivors_settings.cfg"
var damage_numbers: bool = true
var music_volume: float = 0.75
var effects_volume: float = 0.85
var master_volume: float = 1.0
var screen_shake: bool = true
var post_fx: bool = true
var floating_text: bool = true
var attack_mode: String = "auto"
var manual_aim_assist: String = "high"

func _ready() -> void:
	_load()
	_setup_audio_buses()
	_apply_audio()

func _setup_audio_buses() -> void:
	# Add custom buses at explicit positions. This avoids relying on the
	# post-add bus_count value, which can vary with the project's audio layout.
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var new_index: int = AudioServer.get_bus_count()
			AudioServer.add_bus(new_index)
			AudioServer.set_bus_name(new_index, bus_name)
			AudioServer.set_bus_send(new_index, "Master")

func _apply_audio() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	var music_index := AudioServer.get_bus_index("Music")
	var effects_index := AudioServer.get_bus_index("Effects")
	if master_index >= 0:
		AudioServer.set_bus_volume_linear(master_index, clampf(master_volume, 0.0, 1.0))
	if music_index >= 0:
		AudioServer.set_bus_volume_linear(music_index, clampf(music_volume, 0.0, 1.0))
	if effects_index >= 0:
		AudioServer.set_bus_volume_linear(effects_index, clampf(effects_volume, 0.0, 1.0))

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "damage_numbers", damage_numbers)
	cfg.set_value("display", "screen_shake", screen_shake)
	cfg.set_value("display", "post_fx", post_fx)
	cfg.set_value("display", "floating_text", floating_text)
	cfg.set_value("combat", "attack_mode", attack_mode)
	cfg.set_value("combat", "manual_aim_assist", manual_aim_assist)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "effects_volume", effects_volume)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	damage_numbers = bool(cfg.get_value("display", "damage_numbers", true))
	screen_shake = bool(cfg.get_value("display", "screen_shake", true))
	post_fx = bool(cfg.get_value("display", "post_fx", true))
	floating_text = bool(cfg.get_value("display", "floating_text", true))
	attack_mode = str(cfg.get_value("combat", "attack_mode", "auto"))
	manual_aim_assist = str(cfg.get_value("combat", "manual_aim_assist", "high"))
	if attack_mode not in ["auto", "manual"]:
		attack_mode = "auto"
	if manual_aim_assist not in ["off", "low", "high"]:
		manual_aim_assist = "high"
	master_volume = float(cfg.get_value("audio", "master_volume", 1.0))
	music_volume = float(cfg.get_value("audio", "music_volume", 0.75))
	effects_volume = float(cfg.get_value("audio", "effects_volume", 0.85))

func set_master(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0); _apply_audio(); save()
func set_music(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0); _apply_audio(); save()
func set_effects(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0); _apply_audio(); save()

func set_attack_mode(value: String) -> void:
	attack_mode = "manual" if value == "manual" else "auto"
	save()

func set_manual_aim_assist(value: String) -> void:
	manual_aim_assist = value if value in ["off", "low", "high"] else "high"
	save()

func set_post_fx(value: bool) -> void:
	post_fx = value
	save()
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("postfx"):
			if n.has_method("set_enabled"):
				n.set_enabled(value)
