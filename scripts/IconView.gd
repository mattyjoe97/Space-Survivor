class_name IconView
extends Control

## A self-contained icon badge. Drop it anywhere in the UI:
##   var ic := IconView.make("weapon", "railgun", Color(0.85,0.9,1.0), 40)
## Drawn with GameIcons so it stays crisp at any size and needs no textures.

@export var kind: String = "misc"
@export var icon_id: String = "upgrade"
@export var accent: Color = Color(0.4, 0.85, 1.0)
@export var animated: bool = true
@export var show_badge: bool = true
@export var badge_alpha: float = 0.85
@export var glow: float = 0.0  # 0..1 extra highlight ring (used for hover / selected)

var _t: float = 0.0

static func make(p_kind: String, p_id: String, p_accent: Color, px: float = 36.0, p_badge: bool = true) -> IconView:
	var v := IconView.new()
	v.kind = p_kind
	v.icon_id = p_id
	v.accent = p_accent
	v.show_badge = p_badge
	v.custom_minimum_size = Vector2(px, px)
	v.size = Vector2(px, px)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

func set_icon(p_kind: String, p_id: String, p_accent: Color) -> void:
	kind = p_kind
	icon_id = p_id
	accent = p_accent
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_t = randf() * 10.0
	queue_redraw()

func _process(delta: float) -> void:
	if animated and is_visible_in_tree():
		_t += delta
		queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	if show_badge:
		draw_circle(c, r, Color(0.02, 0.035, 0.07, badge_alpha))
		draw_arc(c, r - 0.8, 0.0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.35 + glow * 0.5), 1.2 + glow * 1.5)
		if glow > 0.0:
			draw_circle(c, r * 0.95, Color(accent.r, accent.g, accent.b, 0.12 * glow))
		draw_arc(c, r * 0.72, -2.4, -0.7, 14, Color(1, 1, 1, 0.06), r * 0.16)
	GameIcons.draw_icon(self, kind, icon_id, c, r * 0.62, accent, _t)
