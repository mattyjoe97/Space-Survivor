extends Node
## Procedural music for Space Survivors. No audio assets required.
##
## Three perfectly loop-length-matched stems are synthesized once (in a background
## thread so the menu stays responsive) and played in sync on the Music bus:
##   pad      - slow evolving chords, sub bass, sparse plucks     (always on)
##   drive    - kick / hats / eighth-note bass / arpeggio          (combat)
##   tension  - drone, snare, sweeping siren                       (boss / endless late game)
## Moods crossfade: MusicManager.set_mood("menu" | "combat" | "boss" | "calm" | "off")

const RATE := 16000
const BPM := 120.0
const BARS := 8
const LOOP_SECONDS := 60.0 / BPM * 4.0 * BARS  # 16 s

# Chord progression (root frequency, quality) - A minor flavour, one chord per 2 beats
const PROG := [
	[220.00, "min"], [174.61, "maj"], [261.63, "maj"], [196.00, "maj"],
	[220.00, "min"], [174.61, "maj"], [146.83, "min"], [164.81, "maj"],
]

var _players: Dictionary = {}   # stem -> AudioStreamPlayer
var _target_vol: Dictionary = {"pad": 0.0, "drive": 0.0, "tension": 0.0}
var _cur_vol: Dictionary = {"pad": 0.0, "drive": 0.0, "tension": 0.0}
var _mood: String = "off"
var _thread: Thread = null
var _ready_streams: Dictionary = {}
var _started := false
var _pending_mood := ""
var _duck := 1.0
var _duck_target := 1.0

const MOODS := {
	"off": {"pad": 0.0, "drive": 0.0, "tension": 0.0},
	"menu": {"pad": 1.0, "drive": 0.0, "tension": 0.0},
	"calm": {"pad": 1.0, "drive": 0.35, "tension": 0.0},
	"combat": {"pad": 0.9, "drive": 1.0, "tension": 0.0},
	"boss": {"pad": 0.75, "drive": 1.0, "tension": 1.0},
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus_name := "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	for stem in ["pad", "drive", "tension"]:
		var p := AudioStreamPlayer.new()
		p.bus = bus_name
		p.volume_db = -80.0
		add_child(p)
		_players[stem] = p
	_thread = Thread.new()
	_thread.start(_generate_all)

func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	for stem in _players.keys():
		var p: AudioStreamPlayer = _players[stem]
		p.stop()
		p.stream = null
	_ready_streams.clear()

func set_mood(mood: String) -> void:
	if not MOODS.has(mood):
		return
	_mood = mood
	if not _started:
		_pending_mood = mood
		return
	var m: Dictionary = MOODS[mood]
	for stem in m.keys():
		_target_vol[stem] = m[stem]

func get_mood() -> String:
	return _mood

## Briefly lower the music (level-up screen, merchant, pause).
func duck(on: bool) -> void:
	_duck_target = 0.45 if on else 1.0

func _process(delta: float) -> void:
	if not _started and _thread and not _thread.is_alive() and _thread.is_started():
		_thread.wait_to_finish()
		_finish_setup()
	if not _started:
		return
	_duck = lerpf(_duck, _duck_target, delta * 4.0)
	for stem in _players.keys():
		var target: float = float(_target_vol[stem])
		var cur: float = float(_cur_vol[stem])
		cur = move_toward(cur, target, delta * (0.55 if target > cur else 0.9))
		_cur_vol[stem] = cur
		var p: AudioStreamPlayer = _players[stem]
		var lin := cur * _duck
		p.volume_db = linear_to_db(maxf(lin, 0.0001)) - 6.0 if lin > 0.001 else -80.0

func _finish_setup() -> void:
	for stem in _players.keys():
		var p: AudioStreamPlayer = _players[stem]
		p.stream = _ready_streams.get(stem)
	# Start all stems together so they stay phase-locked.
	for stem in _players.keys():
		var p: AudioStreamPlayer = _players[stem]
		if p.stream:
			p.play(0.0)
	_started = true
	if _pending_mood != "":
		set_mood(_pending_mood)
	elif _mood != "off":
		set_mood(_mood)

# ---------------------------------------------------------------------------
# Synthesis (runs on a worker thread)
# ---------------------------------------------------------------------------

func _generate_all() -> void:
	var n := int(RATE * LOOP_SECONDS)
	_ready_streams["pad"] = _to_stream(_gen_pad(n))
	_ready_streams["drive"] = _to_stream(_gen_drive(n))
	_ready_streams["tension"] = _to_stream(_gen_tension(n))

func _to_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = data.size() / 2
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in range(data.size()):
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	stream.data = bytes
	return stream

func _chord_freqs(root: float, quality: String) -> Array:
	var third := root * (1.1892 if quality == "min" else 1.2599)  # minor / major third
	var fifth := root * 1.4983
	return [root, third, fifth, root * 2.0]

func _chord_index(t: float) -> int:
	var beat := 60.0 / BPM
	return int(floor(t / (beat * 4.0))) % PROG.size()

## Soft "supersaw" pad built from a few detuned harmonics; amplitude falls off like a low-pass.
func _gen_pad(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n * 2)
	var beat := 60.0 / BPM
	var chord_len := beat * 4.0
	# Pre-build voice tables per chord to avoid recomputing.
	var voices: Array = []
	for ch in PROG:
		voices.append(_chord_freqs(ch[0] * 0.5, ch[1]))
	var pluck_notes: Array = []
	for ch in PROG:
		pluck_notes.append(_chord_freqs(ch[0] * 2.0, ch[1]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Pre-roll a sparse pluck pattern (which 8th-notes play)
	var pluck_pattern: Array = []
	for i in range(BARS * 8):
		pluck_pattern.append(rng.randf() < 0.35)
	for i in range(n):
		var t := float(i) / RATE
		var ci := _chord_index(t)
		var local := fmod(t, chord_len)
		var env := smoothstep(0.0, 0.6, local) * (1.0 - smoothstep(chord_len - 0.5, chord_len, local))
		var s_l := 0.0
		var s_r := 0.0
		var vs: Array = voices[ci]
		for vi in range(vs.size()):
			var f: float = vs[vi]
			var detune := 1.0 + (vi - 1.5) * 0.0017
			var a := 0.16 if vi < 3 else 0.06
			var v := sin(t * f * detune * TAU) + sin(t * f * detune * 2.0 * TAU) * 0.35 + sin(t * f * detune * 3.0 * TAU) * 0.12
			var trem := 0.85 + 0.15 * sin(t * 0.7 + vi)
			v *= a * trem
			if vi % 2 == 0:
				s_l += v * 1.0; s_r += v * 0.7
			else:
				s_l += v * 0.7; s_r += v * 1.0
		s_l *= env; s_r *= env
		# Sub bass on the root, gentle.
		var root: float = vs[0] * 0.5
		var sub := sin(t * root * TAU) * 0.22 * env
		s_l += sub; s_r += sub
		# Sparse plucks with a simple echo.
		var eighth := beat * 0.5
		var step := int(floor(t / eighth)) % (BARS * 8)
		var pluck := 0.0
		for k in range(2):
			var st := step - k * 3
			if st < 0:
				continue
			if pluck_pattern[st % pluck_pattern.size()]:
				var pt := fmod(t, eighth) + k * 3.0 * eighth
				var pn: Array = pluck_notes[ci]
				var pf: float = pn[(st * 7) % pn.size()]
				pluck += sin(pt * pf * TAU) * exp(-pt * 7.0) * 0.14 * (0.55 if k == 1 else 1.0)
		s_l += pluck * 0.8; s_r += pluck * 1.1
		out[i * 2] = s_l * 0.55
		out[i * 2 + 1] = s_r * 0.55
	return _fade_loop(out)

## Combat drive: kick on beats, hats on 8ths, bass pulse on 8ths, 16th arps.
func _gen_drive(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n * 2)
	var beat := 60.0 / BPM
	var arp_notes: Array = []
	for ch in PROG:
		arp_notes.append(_chord_freqs(ch[0] * 2.0, ch[1]))
	var bass_notes: Array = []
	for ch in PROG:
		bass_notes.append(ch[0] * 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(n):
		var t := float(i) / RATE
		var ci := _chord_index(t)
		var s := 0.0
		# Kick: every beat, with an extra ghost kick on the "and" of 2.
		var bt := fmod(t, beat)
		var beat_in_bar := int(floor(t / beat)) % 4
		var kick := sin(bt * (55.0 + 120.0 * exp(-bt * 30.0)) * TAU) * exp(-bt * 12.0) * 0.9
		if beat_in_bar == 1 and fmod(t, beat * 0.5) < bt and bt > beat * 0.5:
			var gt := bt - beat * 0.5
			kick += sin(gt * (55.0 + 120.0 * exp(-gt * 30.0)) * TAU) * exp(-gt * 14.0) * 0.5
		s += kick
		# Hats: 8th notes, open hat on off-beats.
		var et := fmod(t, beat * 0.5)
		var is_off := fmod(t, beat) >= beat * 0.5
		var hat := (rng.randf() * 2.0 - 1.0) * exp(-et * (28.0 if is_off else 70.0)) * (0.12 if is_off else 0.09)
		s += hat
		# Bass pulse on 8ths with a short pluck envelope.
		var bf: float = bass_notes[ci]
		var bass := (sin(t * bf * TAU) + sin(t * bf * 2.0 * TAU) * 0.3) * exp(-et * 9.0) * 0.32
		s += bass
		# Arp: 16th notes cycling through chord tones, mid volume.
		var sixteenth := beat * 0.25
		var st := int(floor(t / sixteenth))
		var an: Array = arp_notes[ci]
		var af: float = an[st % an.size()] * (2.0 if (st / 8) % 2 == 1 else 1.0)
		var at := fmod(t, sixteenth)
		var arp := sin(at * af * TAU) * exp(-at * 18.0) * 0.14
		var pan := 0.5 + 0.5 * sin(t * 0.9)
		out[i * 2] = (s + arp * (1.4 - pan)) * 0.6
		out[i * 2 + 1] = (s + arp * (0.6 + pan)) * 0.6
	return _fade_loop(out)

## Boss tension: low drone, snare on 2 & 4, rising siren sweep every 2 bars, noise risers.
func _gen_tension(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n * 2)
	var beat := 60.0 / BPM
	var bar := beat * 4.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in range(n):
		var t := float(i) / RATE
		var ci := _chord_index(t)
		var root: float = PROG[ci][0] * 0.25
		var s := 0.0
		# Drone: detuned low saw-ish
		var drone := 0.0
		for h in range(1, 6):
			drone += sin(t * root * h * 1.003 * TAU) / float(h) * 0.5
			drone += sin(t * root * h * 0.997 * TAU) / float(h) * 0.5
		s += drone * 0.18 * (0.8 + 0.2 * sin(t * 2.0))
		# Snare on beats 2 and 4
		var beat_in_bar := int(floor(t / beat)) % 4
		if beat_in_bar == 1 or beat_in_bar == 3:
			var bt := fmod(t, beat)
			var snare := (rng.randf() * 2.0 - 1.0) * exp(-bt * 22.0) * 0.5 + sin(bt * 190.0 * TAU) * exp(-bt * 30.0) * 0.4
			s += snare
		# Siren sweep across every second bar
		var two := fmod(t, bar * 2.0)
		if two > bar * 1.5:
			var st := (two - bar * 1.5) / (bar * 0.5)
			s += sin(t * (200.0 + st * 900.0) * TAU) * 0.16 * sin(st * PI)
		# Noise riser into every 4th bar
		var four := fmod(t, bar * 4.0)
		if four > bar * 3.0:
			var rt := (four - bar * 3.0) / bar
			s += (rng.randf() * 2.0 - 1.0) * rt * rt * 0.22
		out[i * 2] = s * 0.6 * (1.0 + 0.1 * sin(t * 3.1))
		out[i * 2 + 1] = s * 0.6 * (1.0 - 0.1 * sin(t * 3.1))
	return _fade_loop(out)

## Short crossfade at loop boundary to avoid clicks.
func _fade_loop(data: PackedFloat32Array) -> PackedFloat32Array:
	var frames := data.size() / 2
	var fade := int(RATE * 0.01)
	for i in range(fade):
		var a := float(i) / float(fade)
		data[i * 2] *= a
		data[i * 2 + 1] *= a
		var j := frames - 1 - i
		data[j * 2] *= a
		data[j * 2 + 1] *= a
	return data
