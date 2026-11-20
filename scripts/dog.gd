extends Node3D
class_name PSDog
## Thor, o bulldog francês (caramelo e branco, focinho preto). Frente = +Z.
## Corpo montado a partir de PSDogSpec e animado por código.

signal fetch_returned(pos: Vector3)

var parts: Dictionary = {}
var _mats: Dictionary = {}
var mode := "follow"       # follow | fetch_go | fetch_back
var ball: Node3D = null
var carrying := false
var speed := 0.0
var phase := 0.0
var sit_amt := 0.0
var lie_amt := 0.0
var bark_t := -1.0
var excite := 0.0
var tired := 0.0
var idle_time := 0.0
var _t := 0.0
var _blink := 3.0
var _twitch := 0.0
var _next_twitch := 4.0
var _next_bark := 18.0
var _fetch_time := 0.0
var _head_yaw := 0.0
var _carry_mesh: MeshInstance3D
var _collar_nodes: Array[Node3D] = []
var _ear_base_l := 0.0
var _ear_base_r := 0.0

func build(dog_scale: float = 1.35) -> PSDog:
	for p in PSDogSpec.PARTS:
		var d: Array = p
		var nm: String = d[0]
		var par: String = d[1]
		var pos: Vector3 = d[2]
		var rot: Vector3 = d[3]
		var col: Color = d[5]
		var gloss: float = d[6]
		var node: Node3D
		if d[4] == null:
			node = Node3D.new()
		else:
			var sz: Vector3 = d[4]
			var mi := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 1.0
			sp.radial_segments = 20
			sp.rings = 10
			mi.mesh = sp
			mi.scale = sz
			mi.material_override = _mat(col, gloss)
			node = mi
		node.name = nm
		node.position = pos
		node.rotation_degrees = rot
		if par == "":
			add_child(node)
		else:
			(parts[par] as Node3D).add_child(node)
		parts[nm] = node
	scale = Vector3.ONE * dog_scale
	_ear_base_l = (parts["EarL"] as Node3D).rotation.z
	_ear_base_r = (parts["EarR"] as Node3D).rotation.z
	# bola na boca
	_carry_mesh = MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.065
	bs.height = 0.13
	_carry_mesh.mesh = bs
	_carry_mesh.material_override = _mat(Color("ff4d4d"), 0.5)
	_carry_mesh.position = Vector3(0, -0.035, 0.27)
	_carry_mesh.visible = false
	(parts["Head"] as Node3D).add_child(_carry_mesh)
	# sombra
	var sh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.34
	cyl.bottom_radius = 0.34
	cyl.height = 0.01
	sh.mesh = cyl
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0, 0, 0, 0.3)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.material_override = sm
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sh.position = Vector3(0, 0.04, -0.02)
	add_child(sh)
	set_collar(Color("e8473f"), false)
	return self

func _mat(col: Color, gloss: float) -> StandardMaterial3D:
	var key := "%s_%s" % [col.to_html(), gloss]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8 - 0.55 * gloss
	m.metallic = 0.0
	if gloss > 0.5:
		m.metallic_specular = 0.8
	_mats[key] = m
	return m

func set_collar(color: Color, bow: bool) -> void:
	for n in _collar_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_collar_nodes.clear()
	var body := parts["Body"] as Node3D
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.118
	t.outer_radius = 0.15
	ring.mesh = t
	ring.material_override = _mat(color, 0.3)
	ring.position = Vector3(0, 0.07, 0.215)
	ring.rotation = Vector3(1.2, 0, 0)
	ring.scale = Vector3(1.0, 1.0, 0.85)
	body.add_child(ring)
	_collar_nodes.append(ring)
	var tag := MeshInstance3D.new()
	var ts := SphereMesh.new()
	ts.radius = 0.03
	ts.height = 0.06
	tag.mesh = ts
	tag.material_override = _mat(Color("ffd54f"), 0.9)
	tag.position = Vector3(0, -0.04, 0.275)
	body.add_child(tag)
	_collar_nodes.append(tag)
	if bow:
		for sx in [-1.0, 1.0]:
			var b := MeshInstance3D.new()
			var bm := SphereMesh.new()
			bm.radius = 0.5
			bm.height = 1.0
			b.mesh = bm
			b.scale = Vector3(0.09, 0.06, 0.05)
			b.position = Vector3(0.06 * sx, -0.02, 0.285)
			b.rotation = Vector3(0, 0, 0.5 * sx)
			b.material_override = _mat(color.lightened(0.1), 0.3)
			body.add_child(b)
			_collar_nodes.append(b)

# ---- comandos ---------------------------------------------------------------------
func bark(happy: bool = false) -> void:
	bark_t = 0.0
	if happy:
		PSAudio.sfx("bark_happy", -3.0)
	else:
		PSAudio.sfx("bark1" if randf() < 0.5 else "bark2", -3.0)

func excite_for(seconds: float) -> void:
	excite = maxf(excite, seconds)
	idle_time = 0.0

func fetch(ball_node: Node3D) -> void:
	ball = ball_node
	mode = "fetch_go"
	_fetch_time = 0.0
	idle_time = 0.0

func is_busy() -> bool:
	return mode != "follow"

# ---- simulação ------------------------------------------------------------------------
func tick(delta: float, o_pos: Vector3, o_yaw: float, o_speed: float) -> void:
	_t += delta
	var goal := position
	var move_speed := 0.0
	var fwd := Vector3(sin(o_yaw), 0, cos(o_yaw))
	var side := Vector3(cos(o_yaw), 0, -sin(o_yaw))
	match mode:
		"follow":
			goal = o_pos - fwd * 1.7 + side * 1.1
			var d := Vector2(goal.x - position.x, goal.z - position.z).length()
			if d > 28.0:
				position = Vector3(goal.x, 0, goal.z)
			elif d > 0.9:
				move_speed = clampf(d * 1.9, 1.5, 6.2)
		"fetch_go":
			_fetch_time += delta
			if ball == null or not is_instance_valid(ball):
				mode = "follow"
			else:
				goal = ball.global_position
				var d2 := Vector2(goal.x - position.x, goal.z - position.z).length()
				move_speed = 6.4
				if d2 < 0.8:
					carrying = true
					_carry_mesh.visible = true
					ball.queue_free()
					ball = null
					mode = "fetch_back"
					_fetch_time = 0.0
				elif _fetch_time > 12.0:
					mode = "follow"
		"fetch_back":
			_fetch_time += delta
			goal = o_pos + fwd * 1.0
			var d3 := Vector2(goal.x - position.x, goal.z - position.z).length()
			move_speed = 6.0
			if d3 < 1.4 or _fetch_time > 14.0:
				carrying = false
				_carry_mesh.visible = false
				mode = "follow"
				excite_for(2.6)
				bark(true)
				fetch_returned.emit(position)
	# movimento
	speed = move_toward(speed, move_speed, 11.0 * delta)
	if speed > 0.05:
		var dir := Vector3(goal.x - position.x, 0, goal.z - position.z)
		if dir.length() > 0.01:
			dir = dir.normalized()
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), clampf(11.0 * delta, 0.0, 1.0))
			position += Vector3(sin(rotation.y), 0, cos(rotation.y)) * speed * delta
	position.y = 0.0
	# estados de repouso
	if speed < 0.2 and o_speed < 0.2 and mode == "follow":
		idle_time += delta
	else:
		idle_time = 0.0
	var want_sit := 1.0 if idle_time > 2.5 and idle_time < 30.0 else 0.0
	var want_lie := 1.0 if idle_time >= 30.0 else 0.0
	sit_amt = move_toward(sit_amt, want_sit, 2.8 * delta)
	lie_amt = move_toward(lie_amt, want_lie, 1.6 * delta)
	if lie_amt > 0.0:
		sit_amt = minf(sit_amt, 1.0 - lie_amt)
	tired = move_toward(tired, 1.0 if speed > 3.5 else 0.0, (0.5 if speed > 3.5 else 0.12) * delta)
	if excite > 0.0:
		excite -= delta
	# latido ocasional
	_next_bark -= delta
	if _next_bark <= 0.0:
		_next_bark = randf_range(18.0, 40.0)
		if mode == "follow" and speed < 0.3 and sit_amt > 0.5:
			bark(false)
	_animate(delta, o_pos)

func _animate(delta: float, o_pos: Vector3) -> void:
	var body := parts["Body"] as Node3D
	var head := parts["Head"] as Node3D
	var jaw := parts["Jaw"] as Node3D
	var tail := parts["Tail"] as Node3D
	var moving := speed > 0.15
	if moving:
		phase += delta * (5.5 + speed * 1.9)
	var amp := clampf(speed / 3.0, 0.0, 1.0) * (0.55 + 0.4 * clampf((speed - 2.5) / 3.5, 0.0, 1.0))
	var gallop := clampf((speed - 3.6) / 1.6, 0.0, 1.0)
	var s1 := sin(phase)
	var s2 := sin(phase + PI)
	var sh := sin(phase + 1.3)
	var fl := s1
	var fr := lerpf(s2, s1, gallop)
	var bl := lerpf(s2, sh, gallop)
	var br := lerpf(s1, sh, gallop)
	var up := 1.0 - sit_amt - lie_amt
	(parts["LegFL"] as Node3D).rotation.x = fl * amp * up + 0.1 * sit_amt - 1.5 * lie_amt
	(parts["LegFR"] as Node3D).rotation.x = fr * amp * up + 0.1 * sit_amt - 1.5 * lie_amt
	(parts["LegBL"] as Node3D).rotation.x = bl * amp * up - 1.25 * sit_amt - 1.4 * lie_amt
	(parts["LegBR"] as Node3D).rotation.x = br * amp * up - 1.25 * sit_amt - 1.4 * lie_amt
	# corpo
	var bk := 0.0
	if bark_t >= 0.0:
		bark_t += delta
		bk = sin(clampf(bark_t / 0.28, 0.0, 1.0) * PI)
		if bark_t > 0.3:
			bark_t = -1.0
	var bounce := 0.0
	if excite > 0.0 and not moving:
		bounce = absf(sin(_t * 9.0)) * 0.09 * minf(excite, 1.0)
	body.position.y = 0.28 + absf(sin(phase)) * 0.035 * amp - 0.11 * sit_amt - 0.15 * lie_amt + bounce
	body.position.z = -0.04 * bk
	body.rotation.x = -0.5 * sit_amt + sin(phase * 2.0) * 0.05 * amp + gallop * sin(phase) * 0.12
	body.rotation.z = sin(phase) * 0.04 * amp
	body.scale = Vector3(1.0, 1.0 + 0.015 * sin(_t * 3.0), 1.0)
	# cabeça olha para o dono quando parado
	var target_yaw := 0.0
	if speed < 0.5:
		var to := o_pos - position
		target_yaw = clampf(wrapf(atan2(to.x, to.z) - rotation.y, -PI, PI), -0.9, 0.9)
	_head_yaw = lerpf(_head_yaw, target_yaw, clampf(5.0 * delta, 0.0, 1.0))
	head.rotation = Vector3(0.4 * sit_amt + 0.3 * lie_amt + sin(phase * 2.0 + 0.5) * 0.05 * amp - 0.38 * bk, _head_yaw, 0.0)
	# boca / língua
	var pant := tired * 0.12 * (1.0 + 0.5 * sin(_t * 15.0)) if speed < 3.0 else 0.1
	jaw.rotation.x = 0.55 * bk + pant + (0.15 if excite > 0.0 else 0.0)
	# cauda
	var wag_speed := 7.0 + minf(excite, 1.0) * 10.0
	var wag_amp := 0.25 + 0.35 * minf(excite, 1.0) + 0.2 * amp
	if sit_amt > 0.5 or mode != "follow":
		wag_amp += 0.15
	tail.rotation = Vector3(0.5 - 0.3 * lie_amt, sin(_t * wag_speed) * wag_amp, 0.0)
	# orelhas
	_next_twitch -= delta
	if _next_twitch <= 0.0:
		_next_twitch = randf_range(3.0, 8.0)
		_twitch = 0.4
	var tw := 0.0
	if _twitch > 0.0:
		_twitch -= delta
		tw = sin((0.4 - _twitch) / 0.4 * TAU * 2.0) * 0.18
	var flop := sin(phase * 2.0) * 0.09 * amp + gallop * 0.25
	(parts["EarL"] as Node3D).rotation.z = _ear_base_l - flop - tw - (0.1 if excite > 0.0 else 0.0)
	(parts["EarR"] as Node3D).rotation.z = _ear_base_r + flop + (0.1 if excite > 0.0 else 0.0)
	# olhos piscando
	_blink -= delta
	var eye_y := 1.0
	if _blink <= 0.0:
		eye_y = 0.12
		if _blink < -0.13:
			_blink = randf_range(2.5, 5.5)
	if lie_amt > 0.6:
		eye_y = 0.15
	var eyes: Array[String] = ["EyeL", "EyeR"]
	for e in eyes:
		var n := parts[e] as MeshInstance3D
		n.scale.y = 0.072 * eye_y
	var glints: Array[String] = ["GlintL", "GlintR"]
	for g in glints:
		(parts[g] as Node3D).visible = eye_y > 0.5
