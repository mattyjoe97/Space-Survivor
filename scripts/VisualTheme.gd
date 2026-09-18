class_name VisualTheme
extends RefCounted

const BG := Color(0.018, 0.024, 0.05, 0.97)
const BG_2 := Color(0.035, 0.05, 0.09, 0.98)
const LINE := Color(0.16, 0.28, 0.42, 0.9)
const CYAN := Color(0.35, 0.86, 1.0, 1.0)
const MINT := Color(0.38, 1.0, 0.72, 1.0)
const GOLD := Color(1.0, 0.78, 0.32, 1.0)

static func panel_style(accent: Color = CYAN) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(BG.r, BG.g, BG.b, 0.90)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.38)
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(0, 0, 0, 0.38)
	s.shadow_size = 10
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

static func button_style(accent: Color = CYAN, active: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.045, 0.065, 0.11, 0.96) if not active else Color(0.08, 0.15, 0.2, 1.0)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.55 if active else 0.25)
	s.set_border_width_all(1 if not active else 2)
	s.set_corner_radius_all(7)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func progress_style(fill: Color, height: int = 8) -> Array:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.01, 0.016, 0.03, 0.92)
	bg.border_color = Color(0.16, 0.24, 0.34, 0.9)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(4)
	fg.shadow_color = Color(fill.r, fill.g, fill.b, 0.25)
	fg.shadow_size = 4
	return [bg, fg]

static func style_button(btn: Button, accent: Color = CYAN) -> void:
	add_button_feedback(btn)
	btn.add_theme_stylebox_override("normal", button_style(accent))
	btn.add_theme_stylebox_override("hover", button_style(accent, true))
	btn.add_theme_stylebox_override("pressed", button_style(accent, true))
	btn.add_theme_stylebox_override("focus", button_style(accent, true))
	btn.add_theme_color_override("font_color", Color(0.82, 0.9, 0.98, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))

## Hover / press feedback: tiny scale pop + UI sounds. Safe to call more than once.
static func add_button_feedback(btn: Button) -> void:
	if btn == null or btn.has_meta("fx_bound"):
		return
	btn.set_meta("fx_bound", true)
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		AudioManager.play("ui_hover", 1.0, -10.0)
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	btn.pressed.connect(func(): AudioManager.play("ui_confirm", 1.0, -6.0))

static func style_panel(panel: PanelContainer, accent: Color = CYAN) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(accent))

static func style_progress(bar: ProgressBar, fill: Color) -> void:
	var styles = progress_style(fill)
	bar.add_theme_stylebox_override("background", styles[0])
	bar.add_theme_stylebox_override("fill", styles[1])
