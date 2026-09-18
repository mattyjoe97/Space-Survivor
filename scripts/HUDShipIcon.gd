extends Control

var ship_color: Color = Color(0.4, 0.85, 1.0)
var glow_color: Color = Color(0.4, 0.85, 1.0, 0.22)
var _t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func set_ship_color(value: Color) -> void:
	ship_color = value
	glow_color = Color(value.r, value.g, value.b, 0.22)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46
	draw_circle(center, radius, Color(0.015, 0.04, 0.07, 0.78))
	var sweep := _t * 1.2
	draw_arc(center, radius - 1.0, sweep, sweep + 2.2, 24, Color(ship_color.r, ship_color.g, ship_color.b, 0.55), 1.4)
	draw_arc(center, radius - 1.0, 0.0, TAU, 40, Color(ship_color.r, ship_color.g, ship_color.b, 0.25), 1.0)
	draw_circle(center, radius * 0.86, glow_color)
	GameIcons.draw_ship(self, GameManager.selected_character, center, radius * 0.62, ship_color)
