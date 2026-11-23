class_name Feedback
extends Node3D
## Respuesta audiovisual del movimiento: efectos de sonido sintetizados al arrancar
## (sin archivos de audio) y partículas ligeras (CPUParticles3D, compatibles con móvil).

const RATE := 22050

var player: PlayerController
var sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _dust: CPUParticles3D
var _splash: CPUParticles3D
var _rng := RandomNumberGenerator.new()

func setup(p: PlayerController, rig: BodyRig, combo: ComboSystem) -> void:
	player = p
	_rng.seed = 11
	_build_sounds()
	for i in 8:
		var a := AudioStreamPlayer.new()
		a.bus = "Master"
		add_child(a)
		_players.append(a)
	_dust = _make_particles(Color(0.82, 0.8, 0.76, 0.8), 18, 0.5, 2.2, 0.12)
	_splash = _make_particles(Color(0.75, 0.9, 1.0, 0.9), 40, 0.9, 6.5, 0.1)
	p.landed.connect(_on_landed)
	p.move_performed.connect(_on_move)
	p.entered_water.connect(_on_water)
	p.bailed.connect(func(_r): play("bail", 0.9))
	p.state_changed.connect(_on_state)
	rig.footstep.connect(func(s): play("step", 0.35 + 0.4 * s, _rng.randf_range(0.85, 1.15)))
	combo.combo_banked.connect(func(pts, _s): if pts > 0: play("chime", 0.7))

func play(name: String, volume := 1.0, pitch := 1.0) -> void:
	if not sounds.has(name):
		return
	var a := _players[_next]
	_next = (_next + 1) % _players.size()
	a.stream = sounds[name]
	a.volume_db = linear_to_db(clampf(volume, 0.01, 1.5))
	a.pitch_scale = pitch
	a.play()

# ------------------------------------------------------------------ eventos

func _on_state(old: int, new: int) -> void:
	var S := PlayerController.State
	if new == S.AIR and old in [S.GROUND, S.ROLL] and player.velocity.y > 2.0:
		play("jump", 0.6, _rng.randf_range(0.95, 1.05))
	elif new == S.WALLRUN or new == S.WALLCLIMB:
		play("slap", 0.6, 0.9)
	elif new == S.HANG:
		play("slap", 0.8, 1.1)
	elif new == S.ROLL:
		play("roll", 0.6)
		_burst(_dust, player.global_position, 10)

func _on_move(name: String, _q: float, info: Dictionary) -> void:
	if name.ends_with("Vault"):
		play("slap", 0.8, _rng.randf_range(0.9, 1.1))
	elif name in ["Tic Tac", "Wall Jump", "Wall Kick"]:
		play("slap", 0.7, 1.2)
		play("jump", 0.5, 1.1)
	if info.has("flips"):
		pass

func _on_landed(r: Dictionary) -> void:
	var impact: float = r.impact
	var v := clampf(impact / 16.0, 0.25, 1.2)
	play("land", v, _rng.randf_range(0.9, 1.05) - (0.15 if r.hard else 0.0))
	if impact > 7.0 or r.quality == "crash":
		_burst(_dust, player.global_position, int(6 + impact))

func _on_water(r: Dictionary) -> void:
	var strength := clampf(r.entry_speed / 14.0, 0.3, 1.3)
	if r.quality == "flat":
		strength *= 1.4
	play("splash", strength, 1.0 if r.quality != "perfect" else 1.25)
	var pos := player.global_position
	pos.y = r.surface_y
	_burst(_splash, pos, int(12 + 28 * (strength if r.quality != "perfect" else 0.4)))

func _process(_dt: float) -> void:
	# Whoosh al iniciar una rotación
	if player and player.state == PlayerController.State.AIR and player.tricks.flicks > _last_flicks:
		play("whoosh", 0.55, _rng.randf_range(0.9, 1.15))
	_last_flicks = player.tricks.flicks if player else 0

var _last_flicks := 0

# ------------------------------------------------------------------ partículas

func _make_particles(color: Color, amount: int, life: float, speed: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = m
	p.mesh = mesh
	p.top_level = true
	add_child(p)
	return p

func _burst(p: CPUParticles3D, pos: Vector3, count: int) -> void:
	p.global_position = pos + Vector3.UP * 0.05
	p.amount = clampi(count, 4, 48)
	p.restart()
	p.emitting = true

# ------------------------------------------------------------------ síntesis

func _build_sounds() -> void:
	sounds["step"] = _synth(0.05, func(t, i): return _noise() * _env(t, 0.003, 0.045) * 0.5, 0.35)
	sounds["jump"] = _synth(0.16, func(t, i): return (_noise() * 0.5 + sin(TAU * (160.0 - 300.0 * t) * t) * 0.4) * _env(t, 0.005, 0.15), 0.25)
	sounds["land"] = _synth(0.22, func(t, i): return (sin(TAU * (90.0 - 120.0 * t) * t) * 0.9 + _noise() * 0.35) * _env(t, 0.002, 0.2), 0.15)
	sounds["slap"] = _synth(0.07, func(t, i): return _noise() * _env(t, 0.001, 0.06), 0.6)
	sounds["roll"] = _synth(0.4, func(t, i): return _noise() * 0.5 * _env(t, 0.03, 0.37) * (0.6 + 0.4 * sin(TAU * 9.0 * t)), 0.12)
	sounds["whoosh"] = _synth(0.32, func(t, i): return _noise() * sin(PI * t / 0.32) * 0.6, 0.08, true)
	sounds["splash"] = _synth(0.75, func(t, i): return (_noise() * 0.8 + sin(TAU * 70.0 * t) * 0.3 * exp(-t * 10.0)) * _env(t, 0.004, 0.74), 0.3, true)
	sounds["chime"] = _synth(0.45, func(t, i): return (sin(TAU * 880.0 * t) * 0.35 + sin(TAU * 1320.0 * t) * 0.25 * float(t > 0.08)) * exp(-t * 7.0), 1.0)
	sounds["bail"] = _synth(0.4, func(t, i): return (sin(TAU * 60.0 * t) * 0.8 + _noise() * 0.5 * exp(-t * 12.0)) * _env(t, 0.002, 0.38), 0.2)

var _lp := 0.0

func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)

func _env(t: float, attack: float, length: float) -> float:
	if t < attack:
		return t / attack
	return clampf(1.0 - (t - attack) / maxf(length - attack, 0.001), 0.0, 1.0) ** 2

## Genera un AudioStreamWAV de 16 bits. `smooth` es un filtro paso bajo simple (0..1, 1 = sin filtro).
func _synth(duration: float, f: Callable, smooth := 1.0, sweep := false) -> AudioStreamWAV:
	var n := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	_lp = 0.0
	for i in n:
		var t := float(i) / RATE
		var a := smooth
		if sweep:
			a = clampf(smooth * (1.0 + 2.0 * sin(PI * t / duration)), 0.01, 1.0)
		_lp += (float(f.call(t, i)) - _lp) * a
		var v := int(clampf(_lp, -1.0, 1.0) * 30000.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
