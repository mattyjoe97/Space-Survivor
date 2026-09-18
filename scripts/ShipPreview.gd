extends Node2D

var ship_color: Color = Color(0.35, 0.85, 1.0)
var cockpit_color: Color = Color(0.7, 0.95, 1.0, 0.9)
var engine_color: Color = Color(0.3, 0.85, 1.0, 0.85)
var t: float = 0.0
var ship_id := "viper"

func set_ship(character_id: String) -> void:
	ship_id = character_id
	var data: Dictionary = GameManager.CHARACTERS.get(character_id, GameManager.CHARACTERS["viper"])
	ship_color = data.color
	cockpit_color = Color(0.8, 0.95, 1.0, 0.92)
	engine_color = data.color.lightened(0.18)
	match character_id:
		"bulwark", "aegis":
			cockpit_color = Color(1.0, 0.85, 0.5, 0.92)
			engine_color = Color(1.0, 0.45, 0.18, 0.9)
		"nova":
			cockpit_color = Color(1.0, 0.72, 1.0, 0.92)
			engine_color = Color(0.92, 0.3, 1.0, 0.9)
		"voidrunner":
			cockpit_color = Color(0.72, 1.0, 0.94, 0.95)
			engine_color = Color(0.15, 1.0, 0.85, 0.95)
		"destroyer", "dreadnought":
			cockpit_color = Color(1.0, 0.72, 0.48, 0.95)
			engine_color = Color(1.0, 0.2, 0.12, 0.95)
		"tempest":
			cockpit_color = Color(0.78, 0.9, 1.0, 0.95)
			engine_color = Color(0.3, 0.7, 1.0, 1.0)
		"singularity":
			cockpit_color = Color(0.9, 0.8, 1.0, 0.95)
			engine_color = Color(0.58, 0.2, 1.0, 0.95)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var bob := sin(t * 1.5) * 4.0
	var p := Vector2(0, bob)
	var pulse := 0.88 + sin(t * 5.0) * 0.12
	draw_circle(p, 84.0, Color(ship_color.r, ship_color.g, ship_color.b, 0.045))
	draw_arc(p, 78.0, t * 0.25, t * 0.25 + 4.7, 64, Color(ship_color.r, ship_color.g, ship_color.b, 0.22), 1.6)
	match ship_id:
		"bulwark": _draw_bulwark(p, pulse)
		"nova": _draw_nova(p, pulse)
		"voidrunner": _draw_voidrunner(p, pulse)
		"destroyer": _draw_destroyer(p, pulse)
		"aegis": _draw_aegis(p, pulse)
		"tempest": _draw_tempest(p, pulse)
		"dreadnought": _draw_dreadnought(p, pulse)
		"singularity": _draw_singularity(p, pulse)
		_: _draw_viper(p, pulse)

func _engine(pos: Vector2, size: float = 24.0) -> void:
	var c := engine_color
	c.a *= 0.22
	draw_circle(pos, size * 0.75, c)
	c.a = 0.85
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-size * 0.24, 0), pos + Vector2(size * 0.24, 0), pos + Vector2(0, size),]), c)

func _cockpit(p: Vector2, scale := 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0,-22)*scale, p + Vector2(8,-5)*scale, p + Vector2(0,5)*scale, p + Vector2(-8,-5)*scale]), cockpit_color)
	draw_polyline(PackedVector2Array([p + Vector2(0,-22)*scale, p + Vector2(8,-5)*scale, p + Vector2(0,5)*scale, p + Vector2(-8,-5)*scale, p + Vector2(0,-22)*scale]), Color(1,1,1,0.42), 1.0)

func _draw_viper(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(0, 30), 24)
	var wing := ship_color.darkened(0.16)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-5,0),p+Vector2(-36,8),p+Vector2(-27,24),p+Vector2(-4,14)]), wing)
	draw_colored_polygon(PackedVector2Array([p+Vector2(5,0),p+Vector2(36,8),p+Vector2(27,24),p+Vector2(4,14)]), wing)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-38),p+Vector2(15,5),p+Vector2(8,28),p+Vector2(0,20),p+Vector2(-8,28),p+Vector2(-15,5)]), ship_color)
	_cockpit(p, 1.0)
	draw_line(p+Vector2(0,-34),p+Vector2(0,17),Color(1,1,1,0.2),1.1)

func _draw_bulwark(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-12, 34), 20)
	_engine(p + Vector2(12, 34), 20)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-31,-2),p+Vector2(-48,16),p+Vector2(-38,30),p+Vector2(-10,16)]), ship_color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([p+Vector2(31,-2),p+Vector2(48,16),p+Vector2(38,30),p+Vector2(10,16)]), ship_color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-20,-25),p+Vector2(20,-25),p+Vector2(28,8),p+Vector2(18,28),p+Vector2(-18,28),p+Vector2(-28,8)]), ship_color)
	_cockpit(p,1.15)
	draw_line(p+Vector2(-18,8),p+Vector2(18,8),Color(1,0.9,0.65,0.35),3)

func _draw_nova(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(0, 33), 20)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-8,0),p+Vector2(-45,5),p+Vector2(-20,15),p+Vector2(-3,12)]), ship_color.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([p+Vector2(8,0),p+Vector2(45,5),p+Vector2(20,15),p+Vector2(3,12)]), ship_color.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-42),p+Vector2(12,12),p+Vector2(0,31),p+Vector2(-12,12)]), ship_color)
	_cockpit(p,0.9)
	draw_arc(p+Vector2(0,-1),30,2.8,6.6,24,Color(1,0.6,0.95,0.42),2)

func _draw_voidrunner(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-10, 30), 18)
	_engine(p + Vector2(10, 30), 18)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-4,0),p+Vector2(-42,16),p+Vector2(-23,24),p+Vector2(-2,14)]), ship_color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([p+Vector2(4,0),p+Vector2(42,16),p+Vector2(23,24),p+Vector2(2,14)]), ship_color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-42),p+Vector2(11,-2),p+Vector2(5,28),p+Vector2(0,18),p+Vector2(-5,28),p+Vector2(-11,-2)]), ship_color)
	_cockpit(p,0.8)
	draw_arc(p,52,t*0.9,t*0.9+2.2,30,Color(0.2,1,0.9,0.28),2)

func _draw_destroyer(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-14,36), 22)
	_engine(p + Vector2(14,36), 22)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-23,-4),p+Vector2(-58,13),p+Vector2(-42,30),p+Vector2(-12,18)]), ship_color.darkened(0.22))
	draw_colored_polygon(PackedVector2Array([p+Vector2(23,-4),p+Vector2(58,13),p+Vector2(42,30),p+Vector2(12,18)]), ship_color.darkened(0.22))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-34),p+Vector2(23,-2),p+Vector2(20,28),p+Vector2(-20,28),p+Vector2(-23,-2)]), ship_color)
	_cockpit(p,1.0)
	for x in [-26.0, 26.0]: draw_rect(Rect2(p+Vector2(x-4,4),Vector2(8,15)), Color(0.06,0.07,0.1,1))

func _draw_aegis(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-15, 33), 18)
	_engine(p + Vector2(15, 33), 18)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-42,0),p+Vector2(-58,16),p+Vector2(-40,27),p+Vector2(-8,16)]), ship_color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([p+Vector2(42,0),p+Vector2(58,16),p+Vector2(40,27),p+Vector2(8,16)]), ship_color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-34),p+Vector2(19,-1),p+Vector2(19,25),p+Vector2(0,31),p+Vector2(-19,25),p+Vector2(-19,-1)]), ship_color)
	draw_arc(p,34,-1.0,4.15,40,Color(0.5,0.9,1,0.4),2.4)
	_cockpit(p,0.95)

func _draw_tempest(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-12,31), 17)
	_engine(p + Vector2(12,31), 17)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-3,1),p+Vector2(-52,10),p+Vector2(-28,18),p+Vector2(-4,12)]), ship_color.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([p+Vector2(3,1),p+Vector2(52,10),p+Vector2(28,18),p+Vector2(4,12)]), ship_color.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-44),p+Vector2(9,-3),p+Vector2(6,30),p+Vector2(0,23),p+Vector2(-6,30),p+Vector2(-9,-3)]), ship_color)
	_cockpit(p,0.7)
	draw_arc(p,50,0.5,2.0,20,Color(0.35,0.65,1,0.45),3)
	draw_arc(p,50,3.65,5.15,20,Color(0.35,0.65,1,0.45),3)

func _draw_dreadnought(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-19,37), 22)
	_engine(p + Vector2(19,37), 22)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-31,-2),p+Vector2(-69,15),p+Vector2(-55,34),p+Vector2(-18,19)]), ship_color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([p+Vector2(31,-2),p+Vector2(69,15),p+Vector2(55,34),p+Vector2(18,19)]), ship_color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-30),p+Vector2(27,-4),p+Vector2(28,28),p+Vector2(0,37),p+Vector2(-28,28),p+Vector2(-27,-4)]), ship_color)
	_cockpit(p,1.1)
	for x in [-30.0,0.0,30.0]: draw_circle(p+Vector2(x,18),4.5,Color(0.05,0.07,0.1,1))

func _draw_singularity(p: Vector2, pulse: float) -> void:
	_engine(p + Vector2(-9,33), 18)
	_engine(p + Vector2(9,33), 18)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-28,5),p+Vector2(-49,18),p+Vector2(-35,29),p+Vector2(-7,18)]), ship_color.darkened(0.16))
	draw_colored_polygon(PackedVector2Array([p+Vector2(28,5),p+Vector2(49,18),p+Vector2(35,29),p+Vector2(7,18)]), ship_color.darkened(0.16))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-34),p+Vector2(15,4),p+Vector2(8,27),p+Vector2(0,34),p+Vector2(-8,27),p+Vector2(-15,4)]), ship_color)
	_cockpit(p,0.92)
	draw_circle(p+Vector2(0,6),13+sin(t*3)*1.8,Color(0.08,0.03,0.14,0.9))
	draw_arc(p+Vector2(0,6),20,t*0.6,t*0.6+4.5,36,Color(0.75,0.45,1,0.6),2)
