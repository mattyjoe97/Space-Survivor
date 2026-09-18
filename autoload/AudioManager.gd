extends Node
## Procedural SFX manager for Space Survivors.
## Generates short PCM waveforms so the game has punchy feedback without external audio assets.

const SAMPLE_RATE := 22050
const MAX_PLAYERS := 12

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _streams: Dictionary = {}  # kind -> AudioStreamWAV
var _last_play_time: Dictionary = {}  # kind -> msec, for rate limiting

func _ready() -> void:
	_build_all_streams()
	var effects_idx := AudioServer.get_bus_index("Effects")
	var bus_name := "Effects" if effects_idx >= 0 else "Master"
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		p.bus = bus_name
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)

func play(kind: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(kind):
		return
	# Light rate-limit so dense combat doesn't spam the same SFX every frame.
	var now := Time.get_ticks_msec()
	var min_gap := 35 if kind in ["shoot", "hit", "scatter"] else (80 if kind in ["explode", "enemy_death"] else (140 if kind in ["blade", "freeze", "arc_zap", "tesla", "flame"] else 20))
	if _last_play_time.has(kind) and now - int(_last_play_time[kind]) < min_gap:
		return
	_last_play_time[kind] = now

	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % MAX_PLAYERS
	player.stream = _streams[kind]
	player.pitch_scale = clampf(pitch_scale * randf_range(0.94, 1.06), 0.7, 1.4)
	player.volume_db = volume_db - 2.0 + randf_range(-1.5, 1.0)
	player.play()

func play_ui(kind: String = "ui") -> void:
	play(kind, 1.0, -6.0)

func _build_all_streams() -> void:
	_streams["shoot"] = _make_shoot()
	_streams["hit"] = _make_hit()
	_streams["explode"] = _make_explode()
	_streams["enemy_death"] = _make_enemy_death()
	_streams["pickup_xp"] = _make_pickup(880.0, 0.08)
	_streams["pickup_scrap"] = _make_pickup(520.0, 0.10)
	_streams["pickup_heal"] = _make_pickup(660.0, 0.12)
	_streams["level_up"] = _make_level_up()
	_streams["dash"] = _make_dash()
	_streams["player_hurt"] = _make_player_hurt()
	_streams["boss_hit"] = _make_boss_hit()
	_streams["ui"] = _make_ui()
	_streams["laser"] = _make_laser()
	_streams["missile"] = _make_missile()
	_streams["crit"] = _make_crit()
	_streams["ship_destroy"] = _make_ship_destroy()
	# 3.15 additions
	_streams["arc_zap"] = _make_arc_zap()
	_streams["railgun"] = _make_railgun()
	_streams["solar"] = _make_solar()
	_streams["blade"] = _make_blade()
	_streams["mine"] = _make_mine()
	_streams["freeze"] = _make_freeze()
	_streams["merchant"] = _make_merchant()
	_streams["boss_roar"] = _make_boss_roar()
	_streams["warning"] = _make_warning()
	_streams["synergy"] = _make_synergy()
	_streams["evolve"] = _make_synergy(1.25)
	_streams["ui_hover"] = _make_ui_hover()
	_streams["ui_confirm"] = _make_ui_confirm()
	_streams["shield"] = _make_shield()
	_streams["elite_spawn"] = _make_elite_spawn()
	_streams["superweapon"] = _make_superweapon()
	_streams["torpedo"] = _make_torpedo()
	_streams["scatter"] = _make_scatter()
	_streams["flame"] = _make_flame()
	_streams["phase"] = _make_phase()
	_streams["tesla"] = _make_tesla()
	_streams["big_boom"] = _make_big_boom()

func _alloc(samples: int) -> PackedVector2Array:
	var data := PackedVector2Array()
	data.resize(samples)
	return data

func _to_stream(data: PackedVector2Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 4)
	for i in range(data.size()):
		var l := int(clampf(data[i].x, -1.0, 1.0) * 32767.0)
		var r := int(clampf(data[i].y, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 4, l)
		bytes.encode_s16(i * 4 + 2, r)
	stream.data = bytes
	return stream

func _env(t: float, attack: float, release: float, total: float) -> float:
	if t < attack:
		return t / attack
	if t > total - release:
		return maxf(0.0, (total - t) / release)
	return 1.0

func _make_shoot() -> AudioStreamWAV:
	var dur := 0.055
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.004, 0.035, dur)
		var freq := 920.0 - t * 4800.0
		var s := sin(t * freq * TAU) * 0.55 + sin(t * freq * 2.1 * TAU) * 0.18
		s += (randf() * 2.0 - 1.0) * 0.08 * env
		s *= env * 0.7
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_hit() -> AudioStreamWAV:
	var dur := 0.07
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.002, 0.05, dur)
		var noise := (randf() * 2.0 - 1.0)
		var tone := sin(t * 340.0 * TAU) * exp(-t * 28.0)
		var s := (noise * 0.55 + tone * 0.45) * env * 0.65
		data[i] = Vector2(s, s * 0.9)
	return _to_stream(data)

func _make_explode() -> AudioStreamWAV:
	var dur := 0.28
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 7.5)
		var noise := (randf() * 2.0 - 1.0)
		var low := sin(t * 90.0 * TAU) * exp(-t * 9.0)
		var s := (noise * 0.7 + low * 0.5) * env * 0.85
		# soft stereo spread
		data[i] = Vector2(s * 0.95, s * 1.05)
	return _to_stream(data)

func _make_enemy_death() -> AudioStreamWAV:
	var dur := 0.14
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 14.0)
		var noise := (randf() * 2.0 - 1.0) * 0.6
		var tone := sin(t * (220.0 - t * 400.0) * TAU) * 0.4
		var s := (noise + tone) * env * 0.55
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_pickup(base_freq: float, dur: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.005, 0.04, dur)
		var freq := base_freq + t * 900.0
		var s := sin(t * freq * TAU) * env * 0.55
		s += sin(t * freq * 1.5 * TAU) * env * 0.2
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_level_up() -> AudioStreamWAV:
	var dur := 0.45
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var notes := [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for ni in range(notes.size()):
			var note_t := t - ni * 0.07
			if note_t < 0.0 or note_t > 0.22:
				continue
			var env := _env(note_t, 0.01, 0.12, 0.22)
			s += sin(note_t * notes[ni] * TAU) * env * 0.28
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_dash() -> AudioStreamWAV:
	var dur := 0.12
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.008, 0.07, dur)
		var freq := 180.0 + t * 900.0
		var s := sin(t * freq * TAU) * 0.4 + (randf() * 2.0 - 1.0) * 0.25
		s *= env * 0.7
		data[i] = Vector2(s * 0.9, s * 1.1)
	return _to_stream(data)

func _make_player_hurt() -> AudioStreamWAV:
	var dur := 0.18
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 9.0)
		var noise := (randf() * 2.0 - 1.0) * 0.5
		var tone := sin(t * 140.0 * TAU) * 0.5 + sin(t * 90.0 * TAU) * 0.3
		var s := (noise + tone) * env * 0.7
		data[i] = Vector2(s, s * 0.85)
	return _to_stream(data)

func _make_boss_hit() -> AudioStreamWAV:
	var dur := 0.16
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 8.0)
		var s := sin(t * 70.0 * TAU) * 0.5 + (randf() * 2.0 - 1.0) * 0.45
		s *= env * 0.8
		data[i] = Vector2(s * 1.05, s * 0.95)
	return _to_stream(data)

func _make_ui() -> AudioStreamWAV:
	var dur := 0.05
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.003, 0.03, dur)
		var s := sin(t * 1100.0 * TAU) * env * 0.4
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_laser() -> AudioStreamWAV:
	var dur := 0.16
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.01, 0.08, dur)
		var freq := 1400.0 - t * 600.0
		var s := sin(t * freq * TAU) * 0.35 + sin(t * freq * 1.01 * TAU) * 0.25
		s *= env * 0.55
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_missile() -> AudioStreamWAV:
	var dur := 0.10
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.01, 0.06, dur)
		var noise := (randf() * 2.0 - 1.0) * 0.35
		var tone := sin(t * (280.0 + t * 200.0) * TAU) * 0.4
		var s := (noise + tone) * env * 0.6
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_crit() -> AudioStreamWAV:
	var dur := 0.11
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.004, 0.06, dur)
		var s := sin(t * 1480.0 * TAU) * 0.35 + sin(t * 2220.0 * TAU) * 0.2
		s += (randf() * 2.0 - 1.0) * 0.12
		s *= env * 0.65
		data[i] = Vector2(s, s)
	return _to_stream(data)

func _make_ship_destroy() -> AudioStreamWAV:
	var dur := 0.55
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 4.2)
		# Deep boom
		var low := sin(t * 55.0 * TAU) * exp(-t * 5.5) * 0.7
		# Mid crackle
		var mid := sin(t * 180.0 * TAU) * exp(-t * 8.0) * 0.35
		# Noise burst that decays
		var noise := (randf() * 2.0 - 1.0) * exp(-t * 6.0) * 0.55
		# Secondary high metallic ping
		var ping := 0.0
		if t > 0.04 and t < 0.22:
			var pt := t - 0.04
			ping = sin(pt * 980.0 * TAU) * exp(-pt * 18.0) * 0.25
		var s := (low + mid + noise + ping) * env * 0.95
		data[i] = Vector2(s * 1.05, s * 0.95)
	return _to_stream(data)


# ---------------------------------------------------------------------------
# 3.15 SFX
# ---------------------------------------------------------------------------

func _make_arc_zap() -> AudioStreamWAV:
	var dur := 0.14
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var ph := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.003, 0.09, dur)
		# Crackly square-ish buzz with random frequency jitter.
		var freq := 1800.0 + sin(t * 90.0) * 700.0 + (randf() - 0.5) * 900.0
		ph += freq / SAMPLE_RATE
		var sq := 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		var s2 := sq * 0.3 + (randf() * 2.0 - 1.0) * 0.35
		s2 *= env * 0.6
		data[i] = Vector2(s2, s2 * 0.9)
	return _to_stream(data)

func _make_railgun() -> AudioStreamWAV:
	var dur := 0.42
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 6.0)
		var crack := (randf() * 2.0 - 1.0) * exp(-t * 40.0) * 0.9
		var sweep := sin(t * (2400.0 - t * 3200.0) * TAU) * exp(-t * 12.0) * 0.45
		var boom := sin(t * 60.0 * TAU) * exp(-t * 7.0) * 0.6
		var s2 := (crack + sweep + boom) * env * 0.95
		data[i] = Vector2(s2 * 1.05, s2 * 0.95)
	return _to_stream(data)

func _make_solar() -> AudioStreamWAV:
	var dur := 0.5
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.03, 0.3, dur)
		var rise := sin(t * (120.0 + t * 500.0) * TAU) * 0.4
		var shimmer := sin(t * 1600.0 * TAU) * sin(t * 13.0) * 0.18
		var noise := (randf() * 2.0 - 1.0) * 0.28 * exp(-t * 5.0)
		var s2 := (rise + shimmer + noise) * env * 0.8
		data[i] = Vector2(s2 * 0.9, s2 * 1.1)
	return _to_stream(data)

func _make_blade() -> AudioStreamWAV:
	var dur := 0.13
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.01, 0.08, dur)
		# Whoosh: filtered noise with a pitch swoop.
		var sw := sin(t * (600.0 + sin(t * 30.0) * 300.0) * TAU) * 0.25
		var noise := (randf() * 2.0 - 1.0) * 0.4 * (0.5 + 0.5 * sin(t * 45.0))
		var s2 := (sw + noise) * env * 0.5
		data[i] = Vector2(s2 * 1.1, s2 * 0.9)
	return _to_stream(data)

func _make_mine() -> AudioStreamWAV:
	var dur := 0.22
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.005, 0.12, dur)
		var thud := sin(t * 110.0 * TAU) * exp(-t * 14.0) * 0.6
		var beep := sin(t * 1320.0 * TAU) * (1.0 if fmod(t, 0.07) < 0.03 else 0.0) * 0.22
		var s2 := (thud + beep) * env * 0.75
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_freeze() -> AudioStreamWAV:
	var dur := 0.2
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.004, 0.14, dur)
		var s2 := 0.0
		for f in [2200.0, 2960.0, 3520.0]:
			s2 += sin(t * f * TAU) * 0.12 * exp(-t * 9.0)
		s2 += (randf() * 2.0 - 1.0) * 0.1 * exp(-t * 25.0)
		s2 *= env
		data[i] = Vector2(s2 * 0.8, s2 * 1.2)
	return _to_stream(data)

func _make_merchant() -> AudioStreamWAV:
	var dur := 0.4
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var notes := [659.25, 880.0, 1174.66]
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var s2 := 0.0
		for ni in range(notes.size()):
			var nt := t - ni * 0.09
			if nt < 0.0 or nt > 0.25:
				continue
			s2 += sin(nt * notes[ni] * TAU) * _env(nt, 0.01, 0.15, 0.25) * 0.25
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_boss_roar() -> AudioStreamWAV:
	# Mechanical roar: growling noise with amplitude modulation and a metal shriek layer.
	var dur := 1.0
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.05, 0.4, dur)
		lp = lp * 0.8 + (randf() * 2.0 - 1.0) * 0.2
		var am := 0.6 + 0.4 * (1.0 if fmod(t * 34.0, 1.0) < 0.5 else 0.0)
		var s2 := lp * 2.2 * am + (randf() * 2.0 - 1.0) * 0.15 * (1.0 if fmod(t * 7.0, 1.0) < 0.3 else 0.0)
		s2 *= env * 0.85
		data[i] = Vector2(s2 * 1.05, s2 * 0.95)
	return _to_stream(data)

func _make_warning() -> AudioStreamWAV:
	var dur := 0.3
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var on := 1.0 if fmod(t, 0.15) < 0.09 else 0.0
		var s2 := sin(t * 740.0 * TAU) * 0.3 * on * _env(t, 0.005, 0.05, dur)
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_synergy(pitch: float = 1.0) -> AudioStreamWAV:
	var dur := 0.75
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var notes := [392.0, 523.25, 659.25, 783.99, 1046.5]
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var s2 := 0.0
		for ni in range(notes.size()):
			var nt := t - ni * 0.06
			if nt < 0.0:
				continue
			var e := _env(nt, 0.01, 0.35, dur - ni * 0.06)
			s2 += sin(nt * notes[ni] * pitch * TAU) * e * 0.16
			s2 += sin(nt * notes[ni] * pitch * 2.0 * TAU) * e * 0.05
		data[i] = Vector2(s2 * 0.95, s2 * 1.05)
	return _to_stream(data)

func _make_ui_hover() -> AudioStreamWAV:
	var dur := 0.035
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var s2 := sin(t * 1900.0 * TAU) * _env(t, 0.003, 0.02, dur) * 0.22
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_ui_confirm() -> AudioStreamWAV:
	var dur := 0.12
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var f := 880.0 if t < 0.05 else 1320.0
		var s2 := sin(t * f * TAU) * _env(t, 0.003, 0.05, dur) * 0.35
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_shield() -> AudioStreamWAV:
	var dur := 0.25
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.01, 0.15, dur)
		var s2 := sin(t * (300.0 + t * 1400.0) * TAU) * 0.3 + sin(t * 2400.0 * TAU) * 0.08
		s2 *= env * 0.7
		data[i] = Vector2(s2 * 0.9, s2 * 1.1)
	return _to_stream(data)

func _make_elite_spawn() -> AudioStreamWAV:
	# Klaxon alarm: two alternating tones with a sharp noise tick, so "elite inbound"
	# reads as a warning rather than a horn.
	var dur := 0.7
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.01, 0.15, dur)
		var hi := fmod(t, 0.175) < 0.0875
		var f := 880.0 if hi else 660.0
		var s2 := (1.0 if fmod(t * f, 1.0) < 0.5 else -1.0) * 0.16 + sin(t * f * TAU) * 0.18
		if fmod(t, 0.175) < 0.02:
			s2 += (randf() * 2.0 - 1.0) * 0.25
		s2 *= env * 0.8
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_superweapon() -> AudioStreamWAV:
	var dur := 1.6
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var notes := [261.63, 329.63, 392.0, 523.25, 659.25, 783.99, 1046.5]
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var s2 := 0.0
		# Rising power-up sweep
		s2 += sin(t * (80.0 + t * 420.0) * TAU) * exp(-t * 1.6) * 0.3
		for ni in range(notes.size()):
			var nt := t - 0.35 - ni * 0.07
			if nt < 0.0:
				continue
			var e := _env(nt, 0.01, 0.6, dur - 0.35 - ni * 0.07)
			s2 += sin(nt * notes[ni] * TAU) * e * 0.13
			s2 += sin(nt * notes[ni] * 2.0 * TAU) * e * 0.04
		# Impact hit at 0.35
		if t > 0.35:
			var it := t - 0.35
			s2 += (randf() * 2.0 - 1.0) * exp(-it * 9.0) * 0.5 + sin(it * 50.0 * TAU) * exp(-it * 5.0) * 0.5
		data[i] = Vector2(s2 * 0.95, s2 * 1.05)
	return _to_stream(data)

func _make_torpedo() -> AudioStreamWAV:
	# Pneumatic launch: noise burst + low thump, no tonal sweep.
	var dur := 0.3
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		lp = lp * 0.85 + (randf() * 2.0 - 1.0) * 0.15
		var s2 := lp * 2.5 * exp(-t * 9.0) + sin(t * 48.0 * TAU) * exp(-t * 12.0) * 0.6
		s2 *= _env(t, 0.005, 0.15, dur) * 0.85
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_scatter() -> AudioStreamWAV:
	var dur := 0.12
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 22.0)
		var s2 := (randf() * 2.0 - 1.0) * 0.7 + sin(t * 210.0 * TAU) * 0.5 * exp(-t * 30.0)
		s2 *= env * 0.85
		data[i] = Vector2(s2 * 1.05, s2 * 0.95)
	return _to_stream(data)

func _make_flame() -> AudioStreamWAV:
	var dur := 0.3
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.03, 0.12, dur)
		lp = lp * 0.9 + (randf() * 2.0 - 1.0) * 0.1
		var s2 := lp * 3.0 * (0.7 + 0.3 * sin(t * 60.0)) * env * 0.6
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_phase() -> AudioStreamWAV:
	# Digital chirp: short upward zip with a shimmer, no long descending sweep.
	var dur := 0.16
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.005, 0.08, dur)
		var f := 1200.0 + t * 6000.0
		var s2 := sin(t * f * TAU) * 0.3 + sin(t * 2600.0 * TAU) * 0.1 * sin(t * 60.0)
		s2 *= env * 0.7
		data[i] = Vector2(s2 * 0.8, s2 * 1.2)
	return _to_stream(data)

func _make_tesla() -> AudioStreamWAV:
	var dur := 0.1
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env(t, 0.002, 0.06, dur)
		var s2 := (1.0 if fmod(t * 2600.0, 1.0) < 0.5 else -1.0) * 0.22 + (randf() * 2.0 - 1.0) * 0.3
		s2 *= env * 0.5
		data[i] = Vector2(s2, s2)
	return _to_stream(data)

func _make_big_boom() -> AudioStreamWAV:
	# Impact: filtered noise crack + very short sub punch. No sustained tone (the old 42 Hz
	# sine tail was the "foghorn" on every torpedo / singularity detonation).
	var dur := 0.45
	var n := int(SAMPLE_RATE * dur)
	var data := _alloc(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		lp = lp * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		var s2 := lp * 1.6 * exp(-t * 7.0) + (randf() * 2.0 - 1.0) * 0.5 * exp(-t * 30.0)
		s2 += sin(t * 70.0 * TAU) * exp(-t * 28.0) * 0.5
		s2 *= 0.9
		data[i] = Vector2(s2 * 1.05, s2 * 0.95)
	return _to_stream(data)
