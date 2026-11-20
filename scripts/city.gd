extends Node3D
class_name PSCity
## Constrói e anima a cidade: ilha, avenida circular, parque, fonte, 12 casinhas temáticas,
## trânsito, céu com ciclo dia/noite, mar, pássaros e nuvens.

const WATER_SHADER := """
shader_type spatial;
uniform vec4 col_a : source_color = vec4(0.10, 0.50, 0.78, 1.0);
uniform vec4 col_b : source_color = vec4(0.38, 0.82, 0.95, 1.0);
void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.35 + TIME * 1.1) * 0.10 + cos(VERTEX.z * 0.28 + TIME * 0.8) * 0.08;
}
void fragment() {
	float w = 0.5 + 0.5 * sin(UV.x * 90.0 + TIME * 1.4) * sin(UV.y * 90.0 - TIME * 1.1);
	ALBEDO = mix(col_a.rgb, col_b.rgb, w * 0.35);
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}
"""

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var time_of_day := 0.40
var cycle_on := true
var night_amt := 0.0
var places: Array[Dictionary] = []
var star_spots: Array[Vector3] = []
var zoo_spots: Array[Vector3] = []
var bench_spots: Array[Dictionary] = []
var doghouse_pos := Vector3.ZERO
var spawn_pos := Vector3(0, 0, 11)

var _night_mats: Array[StandardMaterial3D] = []
var _glass_mat: StandardMaterial3D
var _lamp_mat: StandardMaterial3D
var _cars: Array[Dictionary] = []
var _birds: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _boats: Array[Dictionary] = []
var _icons: Array[Node3D] = []
var _rings: Array[MeshInstance3D] = []
var _seesaw: Node3D
var _t := 0.0
var _mats: Dictionary = {}

# ---------------------------------------------------------------------------------
func build() -> void:
	_glass_mat = _mat(Color("fff1b0"), 0.3)
	_lamp_mat = _mat(Color("fff1b0"), 0.3)
	for m in [_glass_mat, _lamp_mat]:
		var sm: StandardMaterial3D = m
		sm.emission_enabled = true
		sm.emission = Color("ffd86b")
		sm.emission_energy_multiplier = 0.0
		_night_mats.append(sm)
	_build_environment()
	_build_ground()
	_build_roads()
	_build_plaza()
	_build_houses()
	_build_park()
	_build_scenery()
	_build_traffic()
	_build_sky_life()
	_build_star_spots()
	_apply_time()

# ---- helpers ---------------------------------------------------------------------
func _mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	_mats[key] = m
	return m

func _mi(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _box(parent: Node, size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mi(parent, b, _mat(color), pos, rot)

func _cyl(parent: Node, top: float, bottom: float, h: float, pos: Vector3, color: Color, seg: int = 24) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return _mi(parent, c, _mat(color), pos)

func _ball(parent: Node, r: float, pos: Vector3, color: Color, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	var mi := _mi(parent, s, _mat(color), pos)
	mi.scale = scl
	return mi

func _collider_box(parent: Node, size: Vector3, pos: Vector3, rot_y: float = 0.0) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.position = pos
	sb.rotation.y = rot_y
	parent.add_child(sb)

func _collider_cyl(parent: Node, radius: float, h: float, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = radius
	cy.height = h
	cs.shape = cy
	sb.add_child(cs)
	sb.position = pos + Vector3(0, h * 0.5, 0)
	parent.add_child(sb)

func _label(parent: Node, text: String, size_px: int, color: Color, pos: Vector3, pix: float = 0.01) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size_px
	l.pixel_size = pix
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = Color(0.1, 0.12, 0.2, 1)
	l.position = pos
	parent.add_child(l)
	return l

func _multi(mesh: Mesh, mat: Material, xforms: Array, colors: Array = []) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		if colors.size() > 0:
			mm.set_instance_color(i, colors[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _glb(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	return ps.instantiate() as Node3D

func _rel_xform(n: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root and cur is Node3D:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t

func _aabb_of(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var bb := _rel_xform(mi, root) * mi.get_aabb()
		if first:
			result = bb
			first = false
		else:
			result = result.merge(bb)
	return result

## Instancia um GLB, escala para `target_h` de altura e apoia no chão, centrado em XZ.
func _place_glb(path: String, pos: Vector3, yaw: float, target_h: float, parent: Node = null, front_group: bool = false) -> Node3D:
	var model := _glb(path)
	if model == null:
		return null
	var bb := _aabb_of(model)
	var s := target_h / maxf(bb.size.y, 0.001)
	model.scale = Vector3.ONE * s
	model.position = Vector3(-(bb.position.x + bb.size.x * 0.5) * s, -bb.position.y * s, -(bb.position.z + bb.size.z * 0.5) * s)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	if front_group:
		var inner := Node3D.new()
		inner.add_to_group("glb_front")
		inner.rotation.y = PSConfig.glb_yaw()
		holder.add_child(inner)
		inner.add_child(model)
	else:
		holder.add_child(model)
	(parent if parent != null else self).add_child(holder)
	return holder

# ---- ambiente ----------------------------------------------------------------------
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.0018
	env.glow_enabled = true
	env.glow_intensity = 0.18
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75.0
	sun.shadow_bias = 0.06
	add_child(sun)

func _apply_time() -> void:
	var ang := (time_of_day - 0.25) * TAU
	var s := sin(ang)
	var day := clampf((s + 0.28) / 0.55, 0.0, 1.0)
	var warm := 1.0 - clampf(s * 2.2, 0.0, 1.0)
	night_amt = 1.0 - day
	var elev := lerpf(10.0, 62.0, clampf(s, 0.0, 1.0))
	sun.rotation_degrees = Vector3(-elev, -50.0 + time_of_day * 260.0, 0.0)
	sun.light_energy = lerpf(0.18, 0.85, day)
	sun.light_color = Color("fff3e0").lerp(Color("ff9a5a"), warm * 0.8).lerp(Color("8aa4ff"), night_amt)
	var top := Color("4ea3ff").lerp(Color("6a5acd"), warm * 0.6).lerp(Color("0b1030"), night_amt)
	var hor := Color("c4e6ff").lerp(Color("ffb27a"), warm * 0.75).lerp(Color("2a3566"), night_amt)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.ground_bottom_color = hor.darkened(0.3)
	env.ambient_light_energy = lerpf(0.35, 0.68, day)
	env.fog_light_color = hor
	for m in _night_mats:
		m.emission_energy_multiplier = night_amt * 2.2

# ---- chão, mar, ilha -----------------------------------------------------------------
func _build_ground() -> void:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 420)
	pm.subdivide_width = 90
	pm.subdivide_depth = 90
	water.mesh = pm
	var sh := Shader.new()
	sh.code = WATER_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	water.material_override = sm
	water.position.y = -0.7
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	_cyl(self, 66.0, 62.0, 7.0, Vector3(0, -3.55, 0), Color("8b6b4a"), 48)
	_cyl(self, PSConfig.ISLAND_R, PSConfig.ISLAND_R, 0.2, Vector3(0, -0.12, 0), Color("a9815a"), 64)
	_cyl(self, 60.0, 60.0, 0.2, Vector3(0, -0.1, 0), Color("8b7658"), 64)
	_collider_box(self, Vector3(170, 1, 170), Vector3(0, -0.5, 0))

func _disc(r: float, top: float, color: Color) -> void:
	_cyl(self, r, r, 0.05, Vector3(0, top - 0.025, 0), color, 72)

func _build_roads() -> void:
	_disc(PSConfig.SIDEWALK_OUT, 0.01, Color("92979b"))
	_disc(PSConfig.ROAD_OUT, 0.02, Color("343940"))
	_disc(PSConfig.ROAD_IN, 0.03, Color("92979b"))
	_disc(PSConfig.PARK_R, 0.04, Color("76a16a"))
	_disc(7.2, 0.05, Color("a7a5a0"))
	_disc(6.4, 0.06, Color("b8b6b0"))
	# trilhas radiais
	for i in range(12):
		var a := deg_to_rad(float(i) * 30.0)
		var yaw := PI - a
		var mid_in := Vector3(sin(a) * 14.0, 0.05, -cos(a) * 14.0)
		_box(self, Vector3(3.0, 0.03, 15.0), mid_in, Color("9b9d9d"), Vector3(0, yaw, 0))
		var mid_out := Vector3(sin(a) * 31.3, 0.025, -cos(a) * 31.3)
		_box(self, Vector3(3.6, 0.03, 3.6), mid_out, Color("9b9d9d"), Vector3(0, yaw, 0))
	# faixas de pedestres e linha central
	var stripes: Array = []
	for i in range(12):
		var a2 := deg_to_rad(float(i) * 30.0)
		var radial := Vector3(sin(a2), 0, -cos(a2))
		var tang := Vector3(cos(a2), 0, sin(a2))
		for j in range(-3, 4):
			var p := radial * 25.5 + tang * (float(j) * 0.62)
			stripes.append(Transform3D(Basis(Vector3.UP, PI - a2), Vector3(p.x, 0.032, p.z)))
	var sm := BoxMesh.new()
	sm.size = Vector3(0.4, 0.02, 4.6)
	_multi(sm, _mat(Color("deded9")), stripes)
	var dashes: Array = []
	for k in range(40):
		var a3 := deg_to_rad(float(k) * 9.0 + 4.5)
		dashes.append(Transform3D(Basis(Vector3.UP, PI / 2.0 - a3), Vector3(sin(a3) * 25.5, 0.032, -cos(a3) * 25.5)))
	var dm := BoxMesh.new()
	dm.size = Vector3(0.15, 0.02, 1.3)
	_multi(dm, _mat(Color("ffd23f")), dashes)

# ---- praça central -----------------------------------------------------------------
func _build_plaza() -> void:
	var f := _place_glb("res://assets/city/Fountain_03.glb", Vector3(0, 0.05, 0), 0.0, 3.4)
	_collider_cyl(self, 3.3, 1.2, Vector3(0, 0, 0))
	var water := CPUParticles3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.06
	dm.height = 0.12
	water.mesh = dm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.6, 0.85, 1.0, 0.85)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water.material_override = wm
	water.position = Vector3(0, 3.0, 0)
	water.amount = 70
	water.lifetime = 1.5
	water.direction = Vector3(0, 1, 0)
	water.spread = 14.0
	water.initial_velocity_min = 3.2
	water.initial_velocity_max = 4.4
	water.gravity = Vector3(0, -9.8, 0)
	water.emitting = true
	add_child(water)
	if f == null:
		_cyl(self, 1.0, 2.5, 1.4, Vector3(0, 0.7, 0), Color("c98d4c"))
	# canteiros e bancos
	var flower_cols: Array = [Color("ff5a5f"), Color("ffc107"), Color("ff8ad8"), Color("ffffff"), Color("a56bff")]
	var bush_paths: Array = ["res://assets/city/Bush_06.glb", "res://assets/city/Bush_07.glb", "res://assets/city/Bush_10.glb"]
	for i in range(12):
		var a := deg_to_rad(float(i) * 30.0 + 15.0)
		var r := 9.2
		var p := Vector3(sin(a) * r, 0, -cos(a) * r)
		_bench(p, atan2(-p.x, -p.z), i)
		var q := Vector3(sin(a) * 6.0, 0.06, -cos(a) * 6.0)
		var bsh := _place_glb(bush_paths[i % 3], q, 0.0, 1.2)
		if bsh == null:
			_ball(self, 0.6, q + Vector3(0, 0.6, 0), Color("3fa34d"))
			_ball(self, 0.15, q + Vector3(0.3, 1.0, 0.2), flower_cols[i % 5])
		_collider_cyl(self, 0.55, 1.0, q)

func _bench(pos: Vector3, yaw: float, idx: int) -> void:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = yaw
	add_child(b)
	var wood := Color("b0753a")
	_box(b, Vector3(1.7, 0.09, 0.55), Vector3(0, 0.40, 0), wood)
	_box(b, Vector3(1.7, 0.45, 0.07), Vector3(0, 0.68, -0.26), wood.darkened(0.1), Vector3(-0.12, 0, 0))
	_box(b, Vector3(0.09, 0.4, 0.5), Vector3(-0.75, 0.2, 0), Color("6b5a4a"))
	_box(b, Vector3(0.09, 0.4, 0.5), Vector3(0.75, 0.2, 0), Color("6b5a4a"))
	_collider_box(b, Vector3(1.8, 0.9, 0.6), Vector3(0, 0.45, 0))
	bench_spots.append({"pos": pos, "yaw": yaw, "index": idx})

# ---- casinhas temáticas -----------------------------------------------------------------
func _build_houses() -> void:
	for i in range(PSConfig.PLACES.size()):
		_house(i)

func _house(i: int) -> void:
	var pl: Dictionary = PSConfig.PLACES[i]
	var col: Color = pl["color"]
	var pos := PSConfig.place_pos(i, PSConfig.BUILD_R)
	var yaw := PSConfig.yaw_to(pos, Vector3.ZERO)
	var W := 9.0
	var D := 7.0
	var H := 5.0
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var wall := col.lerp(Color.WHITE, 0.58)
	var trim := col.darkened(0.15)
	var roof := col.darkened(0.3)
	_box(root, Vector3(W, H, D), Vector3(0, H * 0.5, 0), wall)
	_box(root, Vector3(W + 0.4, 0.55, D + 0.4), Vector3(0, 0.27, 0), trim)
	_box(root, Vector3(W + 0.3, 0.3, D + 0.3), Vector3(0, H + 0.02, 0), trim)
	var prism := PrismMesh.new()
	prism.size = Vector3(W + 1.4, 2.6, D + 1.4)
	_mi(root, prism, _mat(roof), Vector3(0, H + 1.45, 0))
	_box(root, Vector3(0.9, 1.8, 0.9), Vector3(2.6, H + 1.9, -1.0), Color("b5654a"))
	# porta
	_box(root, Vector3(2.1, 3.0, 0.1), Vector3(0, 1.5, D * 0.5 + 0.02), Color("fff8ec"))
	_box(root, Vector3(1.7, 2.7, 0.14), Vector3(0, 1.35, D * 0.5 + 0.05), Color("6b4226"))
	_ball(root, 0.09, Vector3(0.55, 1.3, D * 0.5 + 0.17), Color("ffd54f"))
	_box(root, Vector3(2.6, 0.18, 0.9), Vector3(0, 0.09, D * 0.5 + 0.5), Color("cfcab9"))
	# toldo listrado
	for s in range(6):
		var sc := trim if s % 2 == 0 else Color("fffaf0")
		_box(root, Vector3(0.75, 0.12, 1.7), Vector3(-1.875 + float(s) * 0.75, 3.35, D * 0.5 + 0.8), sc, Vector3(0.28, 0, 0))
	# janelas
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(1.25, 1.25, 0.12)
	for sx in [-1.0, 1.0]:
		_box(root, Vector3(1.6, 1.6, 0.1), Vector3(3.0 * sx, 2.5, D * 0.5 + 0.02), Color("ffffff"))
		_mi(root, glass_mesh, _glass_mat, Vector3(3.0 * sx, 2.5, D * 0.5 + 0.07))
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.12, 1.25, 1.25)
		_mi(root, side_mesh, _glass_mat, Vector3((W * 0.5 + 0.03) * sx, 2.5, 0))
	# placa com o nome
	_box(root, Vector3(6.4, 1.15, 0.25), Vector3(0, 4.2, D * 0.5 + 0.2), trim.darkened(0.25))
	_label(root, String(pl["name"]), 100, Color.WHITE, Vector3(0, 4.2, D * 0.5 + 0.36))
	# ícone flutuante giratório
	var icon := Node3D.new()
	icon.position = Vector3(0, H + 5.0, 0)
	root.add_child(icon)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.6
	disc.bottom_radius = 1.6
	disc.height = 0.35
	var dm := _mi(icon, disc, _mat(col, 0.4), Vector3.ZERO, Vector3(PI / 2.0, 0, 0))
	var rim := TorusMesh.new()
	rim.inner_radius = 1.55
	rim.outer_radius = 1.85
	_mi(icon, rim, _mat(Color.WHITE, 0.4), Vector3.ZERO, Vector3(PI / 2.0, 0, 0))
	var tok := String(pl["token"])
	_label(icon, tok, 130, Color.WHITE, Vector3(0, 0, 0.25))
	var back := _label(icon, tok, 130, Color.WHITE, Vector3(0, 0, -0.25))
	back.rotation.y = PI
	dm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_icons.append(icon)
	# canteiros laterais
	for sx2 in [-1.0, 1.0]:
		_cyl(root, 0.55, 0.45, 0.5, Vector3((W * 0.5 + 1.0) * sx2, 0.25, D * 0.5 + 0.5), Color("d9d4c7"))
		_ball(root, 0.55, Vector3((W * 0.5 + 1.0) * sx2, 0.85, D * 0.5 + 0.5), Color("3fa34d"))
		_ball(root, 0.14, Vector3((W * 0.5 + 1.15) * sx2, 1.2, D * 0.5 + 0.7), Color("ff6b6b"))
	# praça de entrada + anel de entrada
	_box(root, Vector3(W + 1.0, 0.03, 6.0), Vector3(0, 0.04, D * 0.5 + 3.3), col.lerp(Color.WHITE, 0.45))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.95
	ring.outer_radius = 1.2
	var rm := StandardMaterial3D.new()
	rm.albedo_color = col
	rm.emission_enabled = true
	rm.emission = col
	rm.emission_energy_multiplier = 1.4
	var rmi := _mi(root, ring, rm, Vector3(0, 0.1, D * 0.5 + 3.4))
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rings.append(rmi)
	_collider_box(self, Vector3(W + 0.6, H + 3.0, D + 0.6), pos + Vector3(0, (H + 3.0) * 0.5, 0), yaw)
	var front := (Vector3.ZERO - pos).normalized()
	places.append({"index": i, "name": String(pl["name"]), "pos": pos, "yaw": yaw, "color": col, "entrance": pos + front * (D * 0.5 + 3.4)})

# ---- parque ---------------------------------------------------------------------------
func _build_park() -> void:
	# parquinho (setor 0): escorregador e gangorra
	var pg := Vector3(sin(deg_to_rad(15.0)) * 15.0, 0, -cos(deg_to_rad(15.0)) * 15.0)
	var pn := Node3D.new()
	pn.position = pg
	pn.rotation.y = 0.6
	add_child(pn)
	_cyl(pn, 3.4, 3.4, 0.05, Vector3(0, 0.07, 0), Color("f1d9a0"), 32)
	_box(pn, Vector3(1.4, 0.12, 1.4), Vector3(-1.0, 1.4, 0), Color("ffb703"))
	for cx in [-1.6, -0.4]:
		for cz in [-0.6, 0.6]:
			_box(pn, Vector3(0.12, 1.4, 0.12), Vector3(cx, 0.7, cz), Color("e63946"))
	_box(pn, Vector3(2.6, 0.1, 0.9), Vector3(0.9, 0.72, 0), Color("4cc9f0"), Vector3(0, 0, -0.5))
	_collider_box(pn, Vector3(3.4, 1.5, 1.6), Vector3(0, 0.75, 0))
	_seesaw = Node3D.new()
	_seesaw.position = Vector3(1.0, 0.45, 2.2)
	pn.add_child(_seesaw)
	_box(_seesaw, Vector3(3.0, 0.1, 0.4), Vector3.ZERO, Color("8ac926"))
	_ball(pn, 0.2, Vector3(1.0, 0.2, 2.2), Color("6a994e"), Vector3(1, 1, 2))
	# casinha do Thor (setor 3)
	var dpos := Vector3(sin(deg_to_rad(105.0)) * 14.5, 0, -cos(deg_to_rad(105.0)) * 14.5)
	doghouse_pos = dpos
	var dh := Node3D.new()
	dh.position = dpos
	dh.rotation.y = PSConfig.yaw_to(dpos, Vector3.ZERO)
	add_child(dh)
	_box(dh, Vector3(1.9, 1.3, 1.7), Vector3(0, 0.65, 0), Color("e9d8b4"))
	var rp := PrismMesh.new()
	rp.size = Vector3(2.3, 0.95, 2.1)
	_mi(dh, rp, _mat(Color("c0392b")), Vector3(0, 1.75, 0))
	_ball(dh, 0.42, Vector3(0, 0.5, 0.86), Color("2b2118"), Vector3(1, 1.2, 0.3))
	_label(dh, "THOR", 70, Color("fff3c4"), Vector3(0, 1.2, 0.9), 0.006)
	_cyl(dh, 0.3, 0.22, 0.12, Vector3(0.9, 0.06, 1.5), Color("e63946"))
	_collider_box(dh, Vector3(2.0, 1.8, 1.8), Vector3(0, 0.9, 0))
	# jardim de flores (setor 6) e gramado dos bichinhos (setor 9)
	var fl: Array = []
	var fc: Array = []
	var pal: Array = [Color("ff5a5f"), Color("ffc107"), Color("ff8ad8"), Color("ffffff"), Color("a56bff"), Color("4cc9f0")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for n in range(110):
		var sector := rng.randi_range(0, 11)
		var a := deg_to_rad(float(sector) * 30.0 + 15.0 + rng.randf_range(-9.0, 9.0))
		var r := rng.randf_range(10.5, 19.5)
		if sector == 0 or sector == 3 or sector == 9:
			continue
		fl.append(Transform3D(Basis(), Vector3(sin(a) * r, 0.16, -cos(a) * r)))
		fc.append(pal[rng.randi_range(0, pal.size() - 1)])
	var fm := SphereMesh.new()
	fm.radius = 0.14
	fm.height = 0.28
	var flm := StandardMaterial3D.new()
	flm.vertex_color_use_as_albedo = true
	_multi(fm, flm, fl, fc)
	var zc := Vector3(sin(deg_to_rad(285.0)) * 14.5, 0, -cos(deg_to_rad(285.0)) * 14.5)
	_cyl(self, 5.2, 5.2, 0.05, zc + Vector3(0, 0.07, 0), Color("a5e07a"), 40)
	for k in range(8):
		var za := TAU * float(k) / 8.0
		zoo_spots.append(zc + Vector3(cos(za), 0, sin(za)) * 3.0)
	for k in range(24):
		var fa := TAU * float(k) / 24.0
		var post := _box(self, Vector3(0.12, 0.7, 0.12), zc + Vector3(cos(fa), 0, sin(fa)) * 5.2 + Vector3(0, 0.35, 0), Color("fffaf0"))
		post.rotation.y = -fa

# ---- cenário: árvores, postes, esqueleto de prédios -------------------------------------
func _tree(pos: Vector3, s: float, shade: int) -> void:
	var greens: Array = [Color("4caf50"), Color("5cc15f"), Color("3f9b46"), Color("6fcf6a")]
	_cyl(self, 0.14 * s, 0.2 * s, 1.5 * s, pos + Vector3(0, 0.75 * s, 0), Color("8b5a2b"), 10)
	_ball(self, 1.25 * s, pos + Vector3(0, 2.2 * s, 0), greens[shade % 4], Vector3(1, 0.92, 1))
	_ball(self, 0.8 * s, pos + Vector3(0.6 * s, 2.9 * s, 0.2 * s), greens[(shade + 1) % 4])
	_collider_cyl(self, 0.35 * s, 2.0, pos)

func _lamp(pos: Vector3) -> void:
	_cyl(self, 0.06, 0.08, 3.2, pos + Vector3(0, 1.6, 0), Color("4a4f5c"), 8)
	var bulb := SphereMesh.new()
	bulb.radius = 0.24
	bulb.height = 0.48
	_mi(self, bulb, _lamp_mat, pos + Vector3(0, 3.3, 0))
	_collider_cyl(self, 0.15, 2.0, pos)

func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# árvores do parque (entre as trilhas)
	for i in range(12):
		if i == 0 or i == 3 or i == 9:
			continue
		for rr in [13.0, 18.5]:
			var a := deg_to_rad(float(i) * 30.0 + 15.0 + rng.randf_range(-6.0, 6.0))
			var r: float = rr
			_tree(Vector3(sin(a) * r, 0, -cos(a) * r), rng.randf_range(0.85, 1.2), i + int(r))
	# bosque na borda da ilha
	for k in range(46):
		var a2 := TAU * float(k) / 46.0 + rng.randf_range(-0.05, 0.05)
		var r2 := rng.randf_range(44.0, 52.0)
		_tree(Vector3(sin(a2) * r2, 0, -cos(a2) * r2), rng.randf_range(1.2, 1.9), k)
	# palmeiras junto às calçadas externas (entre as casinhas)
	for k in range(12):
		var a3 := deg_to_rad(float(k) * 30.0 + 15.0)
		var p := Vector3(sin(a3) * 31.5, 0.0, -cos(a3) * 31.5)
		var pm := _place_glb("res://assets/city/Palm_03.glb", p, rng.randf() * TAU, 7.5)
		if pm == null:
			_tree(p, 1.3, k)
		else:
			_collider_cyl(self, 0.3, 3.0, p)
	# postes de luz
	for k in range(12):
		var a4 := deg_to_rad(float(k) * 30.0 + 15.0)
		_lamp(Vector3(sin(a4) * 22.3, 0, -cos(a4) * 22.3))
		_lamp(Vector3(sin(a4) * 28.8, 0, -cos(a4) * 28.8))
	# mobiliário urbano
	for k in range(4):
		var a5 := deg_to_rad(float(k) * 90.0 + 8.0)
		var p5 := Vector3(sin(a5) * 28.9, 0, -cos(a5) * 28.9)
		_place_glb("res://assets/city/traffic_light_001.glb", p5, PSConfig.yaw_to(p5, Vector3.ZERO) + PI / 2.0, 4.2)
		var a6 := deg_to_rad(float(k) * 90.0 + 52.0)
		var p6 := Vector3(sin(a6) * 29.0, 0, -cos(a6) * 29.0)
		var bs := _place_glb("res://assets/city/Bus_Stop_02.glb", p6, PSConfig.yaw_to(p6, Vector3.ZERO), 2.8)
		if bs != null:
			_collider_box(self, Vector3(3.0, 2.5, 1.2), p6 + Vector3(0, 1.25, 0), PSConfig.yaw_to(p6, Vector3.ZERO) + PI / 2.0)
	for k in range(6):
		var a7 := deg_to_rad(float(k) * 60.0 + 20.0)
		var p7 := Vector3(sin(a7) * 22.6, 0, -cos(a7) * 22.6)
		var tc := _place_glb("res://assets/city/Trash_Can_04.glb", p7, 0.0, 1.0)
		if tc != null:
			_collider_cyl(self, 0.35, 1.0, p7)
	# prédios ao fundo (skyline)
	var sky_paths: Array = ["res://assets/city/Eco_Building_Grid.glb", "res://assets/city/Eco_Building_Slope.glb", "res://assets/city/Eco_Building_Terrace.glb", "res://assets/city/Regular_Building_TwistedTower_Large.glb"]
	for k in range(16):
		var a8 := TAU * float(k) / 16.0 + 0.1
		var r8 := 56.5 + rng.randf_range(-1.0, 1.5)
		var p8 := Vector3(sin(a8) * r8, 0, -cos(a8) * r8)
		var hh := rng.randf_range(20.0, 34.0)
		if k % 4 == 2:
			hh = rng.randf_range(10.0, 14.0)
		_place_glb(sky_paths[k % 4], p8, PSConfig.yaw_to(p8, Vector3.ZERO), hh)

# ---- trânsito -----------------------------------------------------------------------------
func _build_traffic() -> void:
	var models: Array = ["res://assets/city/Car_06.glb", "res://assets/city/Car_13.glb", "res://assets/city/Van.glb"]
	var lens: Array = [3.7, 4.5, 5.0]
	var plan: Array = [[24.2, 1, 0.0], [24.2, 1, 120.0], [24.2, 1, 240.0], [26.8, -1, 60.0], [26.8, -1, 180.0], [26.8, -1, 300.0]]
	for k in range(plan.size()):
		var pd: Array = plan[k]
		var mi := k % 3
		var car := _place_glb(models[mi], Vector3.ZERO, 0.0, 1.6 if mi != 2 else 2.4, null, true)
		if car == null:
			continue
		var r: float = pd[0]
		var dir: int = pd[1]
		var ang: float = deg_to_rad(float(pd[2]))
		_cars.append({"node": car, "r": r, "dir": dir, "a": ang, "v": 0.0, "vmax": 5.5 + float(k % 3) * 0.7})

# ---- céu: nuvens, pássaros, barcos -------------------------------------------------------
func _build_sky_life() -> void:
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(1, 1, 1, 0.92)
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in range(9):
		var c := Node3D.new()
		add_child(c)
		var n := rng.randi_range(3, 5)
		for j in range(n):
			var sp := SphereMesh.new()
			sp.radius = rng.randf_range(3.0, 5.0)
			sp.height = sp.radius * 1.5
			var m := _mi(c, sp, cm, Vector3(float(j) * 4.0 - 8.0, rng.randf_range(-0.6, 0.8), rng.randf_range(-1.5, 1.5)))
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_clouds.append({"node": c, "a": rng.randf() * TAU, "r": rng.randf_range(70.0, 130.0), "h": rng.randf_range(38.0, 58.0), "w": rng.randf_range(0.004, 0.009)})
	for k in range(7):
		var b := Node3D.new()
		add_child(b)
		_ball(b, 0.22, Vector3.ZERO, Color("fffaf0"), Vector3(1, 0.8, 1.6))
		var wl := _box(b, Vector3(0.6, 0.03, 0.3), Vector3(-0.3, 0.05, 0), Color("f1f1f1"))
		var wr := _box(b, Vector3(0.6, 0.03, 0.3), Vector3(0.3, 0.05, 0), Color("f1f1f1"))
		wl.position = Vector3(-0.3, 0.05, 0)
		_birds.append({"node": b, "wl": wl, "wr": wr, "a": rng.randf() * TAU, "r": rng.randf_range(18.0, 50.0), "h": rng.randf_range(9.0, 18.0), "w": rng.randf_range(0.12, 0.25) * (1.0 if k % 2 == 0 else -1.0), "ph": rng.randf() * 6.0})
	for k in range(3):
		var bt := Node3D.new()
		add_child(bt)
		_box(bt, Vector3(1.0, 0.4, 2.6), Vector3(0, 0.1, 0), Color("fffaf0"))
		_box(bt, Vector3(0.12, 2.6, 0.12), Vector3(0, 1.5, 0.2), Color("8b6b4a"))
		var sail := PrismMesh.new()
		sail.size = Vector3(1.6, 2.2, 0.06)
		_mi(bt, sail, _mat([Color("ff6b6b"), Color("ffd166"), Color("4cc9f0")][k], 0.7), Vector3(0, 1.6, 0.0), Vector3(0, PI / 2.0, 0))
		_boats.append({"node": bt, "a": rng.randf() * TAU, "r": 78.0 + float(k) * 14.0, "w": 0.012 + float(k) * 0.004})

func _build_star_spots() -> void:
	for i in range(12):
		var a := deg_to_rad(float(i) * 30.0 + 15.0)
		star_spots.append(Vector3(sin(a) * 12.0, 1.1, -cos(a) * 12.0))
		star_spots.append(Vector3(sin(a) * 31.0, 1.1, -cos(a) * 31.0))
	var pts: Array = [Vector3(5, 1.1, 8), Vector3(-6, 1.1, 5), Vector3(4.5, 1.1, -4.5), Vector3(8, 1.1, -6), Vector3(-9, 1.1, -3), Vector3(2, 1.1, 17)]
	for p in pts:
		star_spots.append(p)

# ---- atualização por quadro --------------------------------------------------------------
func update(delta: float, player_pos: Vector3) -> void:
	_t += delta
	if cycle_on:
		time_of_day = fmod(time_of_day + delta / 600.0, 1.0)
		_apply_time()
	for ic in _icons:
		ic.rotation.y += delta * 0.9
		ic.position.y = 10.0 + sin(_t * 1.6 + ic.get_instance_id() * 0.001) * 0.3
	for r in _rings:
		var s := 1.0 + 0.12 * sin(_t * 3.0)
		r.scale = Vector3(s, 1, s)
	if _seesaw != null:
		_seesaw.rotation.z = sin(_t * 1.3) * 0.22
	_update_cars(delta, player_pos)
	for b in _birds:
		b["a"] = float(b["a"]) + float(b["w"]) * delta
		var n: Node3D = b["node"]
		var a: float = b["a"]
		var rad: float = b["r"]
		n.position = Vector3(sin(a) * rad, float(b["h"]) + sin(_t + float(b["ph"])) * 0.6, -cos(a) * rad)
		var wdir := signf(float(b["w"]))
		n.rotation.y = atan2(cos(a) * wdir, sin(a) * wdir)
		var flap := sin(_t * 11.0 + float(b["ph"])) * 0.7
		(b["wl"] as Node3D).rotation.z = flap
		(b["wr"] as Node3D).rotation.z = -flap
	for c in _clouds:
		c["a"] = float(c["a"]) + float(c["w"]) * delta
		var cn: Node3D = c["node"]
		var ca: float = c["a"]
		cn.position = Vector3(sin(ca) * float(c["r"]), float(c["h"]), -cos(ca) * float(c["r"]))
	for bt in _boats:
		bt["a"] = float(bt["a"]) + float(bt["w"]) * delta
		var bn: Node3D = bt["node"]
		var ba: float = bt["a"]
		bn.position = Vector3(sin(ba) * float(bt["r"]), -0.55 + sin(_t * 1.4 + ba) * 0.08, -cos(ba) * float(bt["r"]))
		bn.rotation = Vector3(sin(_t * 1.2) * 0.04, atan2(cos(ba), sin(ba)), cos(_t * 1.1) * 0.05)

func _update_cars(delta: float, player_pos: Vector3) -> void:
	var pr := Vector2(player_pos.x, player_pos.z).length()
	var pa := atan2(player_pos.x, -player_pos.z)
	for c in _cars:
		var r: float = c["r"]
		var dir: int = c["dir"]
		var a: float = c["a"]
		var target: float = c["vmax"]
		# pedestre à frente
		if pr > PSConfig.ROAD_IN - 1.0 and pr < PSConfig.ROAD_OUT + 1.0:
			var ahead := wrapf((pa - a) * float(dir), -PI, PI)
			if ahead > 0.0 and ahead * r < 9.0 and absf(pr - r) < 3.6:
				target = 0.0
		# carro da frente na mesma pista
		for o in _cars:
			if o == c or float(o["r"]) != r:
				continue
			var gap := wrapf((float(o["a"]) - a) * float(dir), -PI, PI)
			if gap > 0.0 and gap * r < 7.5:
				target = minf(target, float(o["v"]) * 0.8)
		c["v"] = move_toward(float(c["v"]), target, (9.0 if target == 0.0 else 3.0) * delta)
		a += float(dir) * float(c["v"]) / r * delta
		c["a"] = a
		var n: Node3D = c["node"]
		n.position = Vector3(sin(a) * r, 0.03, -cos(a) * r)
		var heading := atan2(cos(a) * float(dir), sin(a) * float(dir))
		n.rotation.y = heading

func is_night() -> bool:
	return night_amt > 0.6
