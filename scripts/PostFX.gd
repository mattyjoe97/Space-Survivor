extends CanvasLayer

## Screen post-processing controller (vignette, chromatic aberration hits, low-hull pulse).
## Sits on layer 1 so the HUD (layer 2) stays crisp on top.
## Other systems call `PostFX.punch(amount)` through the group "postfx".

var rect: ColorRect = null
var _aberration: float = 0.0
var _danger_target: float = 0.0
var _danger: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	add_to_group("postfx")
	layer = 1
	rect = ColorRect.new()
	rect.name = "Rect"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/postfx.gdshader")
	rect.material = mat
	rect.visible = SettingsManager.post_fx
	add_child(rect)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_t += delta
	_aberration = maxf(0.0, _aberration - delta * 3.2)
	_danger = lerpf(_danger, _danger_target, delta * 4.0)
	if rect and rect.material:
		var m: ShaderMaterial = rect.material
		m.set_shader_parameter("time_s", _t)
		m.set_shader_parameter("aberration", _aberration)
		m.set_shader_parameter("danger", _danger)
	# Track hull for danger tint.
	var p = GameManager.player
	if is_instance_valid(p):
		var cur = p.get("current_hp")
		var mx = p.get("max_hp")
		if cur != null and mx != null and float(mx) > 0.0:
			var ratio: float = float(cur) / float(mx)
			_danger_target = clampf((0.32 - ratio) / 0.32, 0.0, 1.0) if not GameManager.is_game_over else 0.0
	else:
		_danger_target = 0.0

func punch(amount: float = 0.6) -> void:
	_aberration = clampf(maxf(_aberration, amount), 0.0, 1.0)

func set_enabled(on: bool) -> void:
	if rect:
		rect.visible = on

## Static helper for callers that don't hold a reference.
static func hit_punch(amount: float = 0.6) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.get_nodes_in_group("postfx"):
		if n.has_method("punch"):
			n.punch(amount)
