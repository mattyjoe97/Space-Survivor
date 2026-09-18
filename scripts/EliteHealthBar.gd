extends Node2D

## Clean world-space elite health display. Stays level and readable while the elite rotates.
var max_hp: float = 100.0
var current_hp: float = 100.0
var title: String = "ELITE"
var accent: Color = Color(1.0, 0.45, 0.2)
var state_text: String = ""
var flash: float = 0.0

func _ready() -> void:
	z_index = 20
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(flash - delta * 4.0, 0.0)
		queue_redraw()

func set_values(current: float, maximum: float, elite_title: String, color: Color) -> void:
	if current < current_hp:
		flash = 1.0
	current_hp = max(current, 0.0)
	max_hp = max(maximum, 1.0)
	title = elite_title
	accent = color
	queue_redraw()

func set_state(text: String) -> void:
	state_text = text
	queue_redraw()

func _draw() -> void:
	var width := 92.0
	var bar_y := 3.0
	var ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	# soft shadow / backing
	draw_rect(Rect2(-width * 0.5 - 2.0, -2.0, width + 4.0, 17.0), Color(0.0, 0.0, 0.0, 0.42), true)
	# title strip
	draw_rect(Rect2(-width * 0.5, -15.0, width, 12.0), Color(0.025, 0.035, 0.06, 0.94), true)
	draw_rect(Rect2(-width * 0.5, -15.0, 3.0, 12.0), accent, true)
	var font := ThemeDB.fallback_font
	var title_text := title
	if state_text != "":
		title_text += "  •  " + state_text
	draw_string(font, Vector2(-width * 0.5 + 7.0, -6.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, width - 10.0, 8, Color(0.82, 0.88, 0.96, 0.96))
	# health track + border
	draw_rect(Rect2(-width * 0.5, bar_y, width, 7.0), Color(0.015, 0.02, 0.035, 0.96), true)
	var fill_col := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), flash * 0.7)
	draw_rect(Rect2(-width * 0.5, bar_y, width * ratio, 7.0), fill_col, true)
	draw_rect(Rect2(-width * 0.5, bar_y, width, 7.0), Color(0.55, 0.65, 0.78, 0.55 + flash * 0.4), false, 1.0 + flash * 0.6)
	# tiny hp readout makes damage progress obvious without clutter
	var hp_text := "%d%%" % int(ratio * 100.0)
	draw_string(font, Vector2(width * 0.5 + 6.0, 9.0), hp_text, HORIZONTAL_ALIGNMENT_LEFT, 34.0, 8, Color(0.72, 0.8, 0.9, 0.8))
