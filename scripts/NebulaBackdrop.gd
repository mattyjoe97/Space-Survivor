extends CanvasLayer

## Shader nebula that lives behind the world and drifts with the camera.

var rect: ColorRect = null
var _t: float = 0.0

func _ready() -> void:
	layer = -1
	rect = ColorRect.new()
	rect.name = "Rect"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/nebula.gdshader")
	rect.material = mat
	add_child(rect)
	_apply_sector_tint()
	if GameManager.has_signal("sector_changed"):
		GameManager.sector_changed.connect(func(_n, _g): _apply_sector_tint())

func _apply_sector_tint() -> void:
	if rect == null or rect.material == null:
		return
	var m: ShaderMaterial = rect.material
	var idx: int = 0
	var v = GameManager.get("sector_index")
	if v != null:
		idx = int(v)
	# Rotate through a few palettes so sectors feel different.
	var palettes := [
		[Color(0.10, 0.06, 0.28), Color(0.04, 0.16, 0.30), Color(0.28, 0.06, 0.20)],
		[Color(0.05, 0.14, 0.26), Color(0.03, 0.22, 0.24), Color(0.10, 0.08, 0.30)],
		[Color(0.26, 0.05, 0.14), Color(0.16, 0.05, 0.28), Color(0.30, 0.10, 0.06)],
		[Color(0.06, 0.20, 0.18), Color(0.03, 0.10, 0.26), Color(0.12, 0.24, 0.08)],
		[Color(0.22, 0.10, 0.04), Color(0.28, 0.04, 0.12), Color(0.10, 0.06, 0.24)],
		[Color(0.16, 0.04, 0.30), Color(0.04, 0.06, 0.20), Color(0.30, 0.05, 0.28)],
	]
	var pal: Array = palettes[posmod(idx, palettes.size())]
	m.set_shader_parameter("tint_a", pal[0])
	m.set_shader_parameter("tint_b", pal[1])
	m.set_shader_parameter("tint_c", pal[2])

func _process(delta: float) -> void:
	_t += delta
	if rect and rect.material:
		var m: ShaderMaterial = rect.material
		m.set_shader_parameter("time_s", _t)
		var p = GameManager.player
		if is_instance_valid(p):
			m.set_shader_parameter("cam_pos", p.global_position)
