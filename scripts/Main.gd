extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var star_field_far: Node2D = $StarFieldFar
@onready var star_field_mid: Node2D = $StarFieldMid
@onready var star_field_near: Node2D = $StarFieldNear
@onready var nebula_layer: Node2D = $NebulaLayer
@onready var spawner: Node2D = $EnemySpawner
@onready var space_environment: Node2D = $SpaceEnvironment

var far_stars: Array[Node2D] = []
var mid_stars: Array[Node2D] = []
var near_stars: Array[Node2D] = []

func _ready() -> void:
	GameManager.register_world(self)
	var bounds := Node2D.new()
	bounds.name = "ArenaBounds"
	bounds.set_script(load("res://scripts/ArenaBounds.gd"))
	add_child(bounds)
	_generate_space_background()
	player.add_to_group("player")
	MusicManager.set_mood("calm")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	# Parallax scrolling relative to player (camera center)
	var cam_pos = player.global_position
	star_field_far.position = cam_pos * 0.15
	star_field_mid.position = cam_pos * 0.35
	star_field_near.position = cam_pos * 0.55
	nebula_layer.position = cam_pos * 0.22
	space_environment.position = cam_pos * 0.08

func _generate_space_background() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Far layer – tiny dense stars
	for i in range(220):
		var star = _make_star(rng, 0.6, 1.6, 0.25, 0.7)
		star.position = Vector2(rng.randf_range(-2800, 2800), rng.randf_range(-2800, 2800))
		star_field_far.add_child(star)

	# Mid layer
	for i in range(140):
		var star = _make_star(rng, 1.0, 2.4, 0.4, 0.9)
		# Slight color tint
		if rng.randf() < 0.25:
			star.color = Color(0.7, 0.85, 1.0, star.color.a)
		elif rng.randf() < 0.15:
			star.color = Color(1.0, 0.85, 0.7, star.color.a)
		star.position = Vector2(rng.randf_range(-2600, 2600), rng.randf_range(-2600, 2600))
		star_field_mid.add_child(star)

	# Near layer – brighter / larger
	for i in range(70):
		var star = _make_star(rng, 1.4, 3.2, 0.55, 1.0)
		if rng.randf() < 0.3:
			star.color = Color(0.6, 0.9, 1.0, star.color.a)
		star.position = Vector2(rng.randf_range(-2400, 2400), rng.randf_range(-2400, 2400))
		star_field_near.add_child(star)

	# Nebulae / gas clouds
	for i in range(14):
		var neb = Polygon2D.new()
		var s = rng.randf_range(80, 180)
		var points: PackedVector2Array = []
		var verts = rng.randi_range(5, 8)
		for v in range(verts):
			var a = (float(v) / verts) * TAU + rng.randf_range(-0.3, 0.3)
			var r = s * rng.randf_range(0.55, 1.15)
			points.append(Vector2(cos(a), sin(a)) * r)
		neb.polygon = points
		var col_choice = rng.randi() % 4
		match col_choice:
			0: neb.color = Color(0.15, 0.05, 0.35, 0.11)  # purple
			1: neb.color = Color(0.05, 0.15, 0.35, 0.10)  # blue
			2: neb.color = Color(0.25, 0.05, 0.2, 0.09)   # magenta
			3: neb.color = Color(0.05, 0.2, 0.25, 0.10)   # teal
		neb.position = Vector2(rng.randf_range(-2000, 2000), rng.randf_range(-2000, 2000))
		nebula_layer.add_child(neb)

	# A couple of larger distant "galaxy" smudges
	for i in range(3):
		var gal = Polygon2D.new()
		var s = rng.randf_range(200, 320)
		gal.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.3), Vector2(s * 0.8, -s * 0.5),
			Vector2(s, s * 0.4), Vector2(-s * 0.6, s * 0.5)
		])
		gal.color = Color(0.12, 0.08, 0.28, 0.07)
		gal.position = Vector2(rng.randf_range(-1600, 1600), rng.randf_range(-1600, 1600))
		gal.rotation = rng.randf() * TAU
		nebula_layer.add_child(gal)

func _make_star(rng: RandomNumberGenerator, min_s: float, max_s: float, min_a: float, max_a: float) -> Polygon2D:
	var star = Polygon2D.new()
	var size = rng.randf_range(min_s, max_s)
	star.polygon = PackedVector2Array([
		Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
	])
	var b = rng.randf_range(0.45, 1.0)
	star.color = Color(b, b, b * 1.05, rng.randf_range(min_a, max_a))
	return star

func _exit_tree() -> void:
	GameManager.unregister_world(self)
	GameManager.purge_run_entities()
