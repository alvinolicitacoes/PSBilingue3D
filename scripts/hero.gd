extends Node3D
class_name PSHero
## Menino 3D com esqueleto (clipes: idle, walk, run, sit, wave, cheer, jump) + camisetas e acessórios.
## Frente do personagem = +Z local.

const GLB := "res://assets/characters/pietro/pietro_rigged.glb"
const BASE_H := 1.87
const SHIRTS := ["azul", "vermelha", "verde", "amarela", "roxa", "laranja", "rosa", "branca"]
const SHIRT_COLORS := [Color("4f9dff"), Color("e8473f"), Color("3fbf4f"), Color("f4c430"), Color("9b59d0"), Color("ff8c1a"), Color("f06ab8"), Color("f2f2f2")]
const HATS := ["", "gorro", "bone", "festa", "coroa", "orelhas"]
const HAT_NAMES := ["Sem chapéu", "Gorro", "Boné", "Festa", "Coroa", "Orelhinhas"]
const HAT_COST := [0, 0, 5, 15, 30, 50]
const GLASSES_COST := 10

var holder: Node3D
var model: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var mesh: MeshInstance3D
var height := 1.25
var shirt_name := "azul"
var hat_id := ""
var glasses := false
var _attach: Node3D
var _acc: Node3D
var _lock := 0.0
var _cancel := true
var _air := false
var _sitting := false
var _names: Dictionary = {}

func build(h: float, shirt: String = "azul") -> PSHero:
	height = h
	holder = Node3D.new()
	holder.add_to_group("glb_front")
	holder.rotation.y = PSConfig.glb_yaw()
	add_child(holder)
	var ps := load(GLB) as PackedScene
	if ps != null:
		model = ps.instantiate() as Node3D
		holder.add_child(model)
		var s := h / BASE_H
		model.scale = Vector3(s, s, s)
		anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		skel = model.find_child("Skeleton3D", true, false) as Skeleton3D
		var ms := model.find_children("*", "MeshInstance3D", true, false)
		if ms.size() > 0:
			mesh = ms[0] as MeshInstance3D
		_setup_anims()
	else:
		push_warning("Modelo do menino não encontrado: " + GLB)
		var cap := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.25 * h / 1.25
		cm.height = h
		cap.mesh = cm
		cap.position.y = h * 0.5
		add_child(cap)
	set_shirt(shirt)
	_make_shadow()
	_play("idle", 1.0)
	return self

func _make_shadow() -> void:
	var sh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42 * height / 1.25
	cyl.bottom_radius = cyl.top_radius
	cyl.height = 0.01
	sh.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0, 0, 0, 0.32)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.material_override = m
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sh.position.y = 0.04
	add_child(sh)

# ---- animações -----------------------------------------------------------------
func _setup_anims() -> void:
	if anim == null:
		return
	for n in anim.get_animation_list():
		var a := anim.get_animation(n)
		var low := String(n).to_lower()
		if low.contains("sit") or low.contains("jump"):
			a.loop_mode = Animation.LOOP_NONE
		else:
			a.loop_mode = Animation.LOOP_LINEAR

func _find(key: String) -> String:
	if _names.has(key):
		return _names[key]
	var found := ""
	if anim != null:
		for n in anim.get_animation_list():
			if String(n).to_lower().contains(key):
				found = String(n)
				break
	_names[key] = found
	return found

func _play(key: String, spd: float) -> void:
	if anim == null:
		return
	var n := _find(key)
	if n == "":
		return
	if anim.current_animation != n:
		anim.play(n, 0.18)
	anim.speed_scale = spd

## Define a animação de locomoção conforme a velocidade real (m/s).
func set_motion(speed: float) -> void:
	if _sitting:
		if speed > 0.3:
			stand()
		else:
			return
	if _lock > 0.0:
		if speed > 0.6 and _cancel:
			_lock = 0.0
		else:
			return
	if _air:
		return
	var s := height / BASE_H
	if speed < 0.15:
		_play("idle", 1.0)
	elif speed < 2.1:
		_play("walk", clampf(speed / (1.46 * s), 0.6, 2.2))
	else:
		_play("run", clampf(speed / (4.9 * s), 0.7, 1.8))

func play_once(key: String, duration: float = 0.0, cancel_on_move: bool = true) -> void:
	if anim == null:
		return
	var n := _find(key)
	if n == "":
		return
	anim.play(n, 0.15)
	anim.speed_scale = 1.0
	_lock = duration if duration > 0.0 else anim.get_animation(n).length
	_cancel = cancel_on_move

func wave() -> void:
	play_once("wave", 2.4)

func cheer() -> void:
	play_once("cheer", 2.2)

func sit() -> void:
	if _sitting:
		return
	_sitting = true
	_lock = 0.0
	var n := _find("sit")
	if n != "" and anim != null:
		anim.play(n, 0.25)
		anim.speed_scale = 1.0

func stand() -> void:
	_sitting = false
	_lock = 0.0
	if anim != null:
		anim.stop()
	_play("idle", 1.0)

func is_sitting() -> bool:
	return _sitting

func set_air(on: bool) -> void:
	if on and not _air:
		_air = true
		_lock = 0.0
		var n := _find("jump")
		if n != "" and anim != null:
			anim.play(n, 0.08)
			anim.speed_scale = 1.0
	elif not on and _air:
		_air = false
		_play("idle", 1.0)

func _process(delta: float) -> void:
	if _lock > 0.0:
		_lock -= delta
		if _lock <= 0.0 and anim != null:
			anim.stop()

# ---- aparência -------------------------------------------------------------------
func set_shirt(shirt: String) -> void:
	shirt_name = shirt
	if mesh == null:
		return
	var path := "res://assets/characters/pietro/camisa_%s.jpg" % shirt
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat

func set_hat(id: String) -> void:
	hat_id = id
	_rebuild_acc()

func set_glasses(on: bool) -> void:
	glasses = on
	_rebuild_acc()

func apply_outfit(shirt: String, hat: String, gl: bool) -> void:
	hat_id = hat
	glasses = gl
	set_shirt(shirt)
	_rebuild_acc()

func _ensure_attach() -> Node3D:
	if _attach != null and is_instance_valid(_attach):
		return _attach
	if skel != null and skel.find_bone("Head") != -1:
		var ba := BoneAttachment3D.new()
		skel.add_child(ba)
		ba.bone_name = "Head"
		_attach = ba
	elif model != null:
		var n := Node3D.new()
		n.position = Vector3(0, 1.39, 0.03)
		model.add_child(n)
		_attach = n
	else:
		var n2 := Node3D.new()
		n2.position = Vector3(0, height * 0.9, 0)
		add_child(n2)
		_attach = n2
	return _attach

func _rebuild_acc() -> void:
	var at := _ensure_attach()
	if _acc != null and is_instance_valid(_acc):
		_acc.queue_free()
	_acc = Node3D.new()
	at.add_child(_acc)
	match hat_id:
		"gorro":
			_part(_sphere(), Color("e8473f"), Vector3(0, 0.36, -0.01), Vector3(0.64, 0.5, 0.64))
			_part(_sphere(), Color("ffffff"), Vector3(0, 0.6, -0.01), Vector3(0.14, 0.14, 0.14))
			_part(_cyl(0.3, 0.3, 0.05), Color("ffffff"), Vector3(0, 0.215, -0.01), Vector3.ONE)
		"bone":
			_part(_sphere(), Color("2f7de1"), Vector3(0, 0.36, -0.01), Vector3(0.6, 0.42, 0.6))
			_part(_box(), Color("1f5fb8"), Vector3(0, 0.27, 0.27), Vector3(0.3, 0.025, 0.22), Vector3(0.18, 0, 0))
		"festa":
			_part(_cyl(0.0, 0.17, 0.44), Color("9b59d0"), Vector3(0, 0.64, -0.01), Vector3.ONE, Vector3(-0.1, 0, 0))
			_part(_sphere(), Color("ffd54f"), Vector3(0, 0.87, -0.05), Vector3(0.1, 0.1, 0.1))
		"coroa":
			_part(_cyl(0.25, 0.27, 0.1), Color("ffc400"), Vector3(0, 0.43, -0.01), Vector3.ONE, Vector3.ZERO, 0.7)
			for i in range(6):
				var a := TAU * float(i) / 6.0
				_part(_cyl(0.0, 0.05, 0.14), Color("ffc400"), Vector3(cos(a) * 0.24, 0.55, sin(a) * 0.24 - 0.01), Vector3.ONE, Vector3.ZERO, 0.7)
		"orelhas":
			for sx in [-1.0, 1.0]:
				_part(_sphere(), Color("f6f0f0"), Vector3(0.11 * sx, 0.68, -0.02), Vector3(0.11, 0.36, 0.06), Vector3(0, 0, -0.12 * sx))
				_part(_sphere(), Color("ffb3c7"), Vector3(0.11 * sx, 0.68, 0.01), Vector3(0.065, 0.27, 0.03), Vector3(0, 0, -0.12 * sx))
	if glasses:
		for sx2 in [-1.0, 1.0]:
			var t := TorusMesh.new()
			t.inner_radius = 0.055
			t.outer_radius = 0.08
			_part(t, Color("26324d"), Vector3(0.105 * sx2, 0.115, 0.215), Vector3.ONE, Vector3(PI / 2.0, 0, 0))
		_part(_box(), Color("26324d"), Vector3(0, 0.125, 0.215), Vector3(0.05, 0.014, 0.014))

func _sphere() -> Mesh:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 20
	s.rings = 10
	return s

func _box() -> Mesh:
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	return b

func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 20
	return c

func _part(mesh_res: Mesh, color: Color, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO, metal: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_res
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	m.metallic = metal
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	_acc.add_child(mi)
