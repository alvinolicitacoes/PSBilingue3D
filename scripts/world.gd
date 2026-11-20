extends Node3D
## Pietro e Thor — Cidade Bilíngue 3D (controlador principal)

const WALK_SPEED := 1.8
const RUN_SPEED := 3.6
const SPRINT_SPEED := 5.6
const JUMP_VEL := 8.2
const GRAVITY := 24.0
const QUESTS := [
	{"id": "stars", "text": "Colete estrelas", "base": 8, "reward": 3},
	{"id": "talk", "text": "Converse com amigos", "base": 3, "reward": 2},
	{"id": "fetch", "text": "Brinque de buscar com o Thor", "base": 3, "reward": 2},
	{"id": "pet", "text": "Faça carinho no Thor", "base": 3, "reward": 1},
	{"id": "play", "text": "Complete níveis das atividades", "base": 2, "reward": 3},
	{"id": "animals", "text": "Conheça os bichinhos", "base": 4, "reward": 2},
]
const COLLARS := [["Vermelha", Color("e8473f")], ["Azul", Color("2f7de1")], ["Verde", Color("3fbf4f")], ["Amarela", Color("f4c430")], ["Rosa", Color("f06ab8")], ["Roxa", Color("9b59d0")]]
const TUTORIAL := [
	"Oi! Eu sou o Thor, seu amigo bulldog francês. Vamos explorar a cidade juntos!",
	"Ande com W A S D ou as setas (ou use o joystick da tela). Arraste o mouse ou o dedo para girar a câmera.",
	"Pule com ESPAÇO e corra com SHIFT. Colete as estrelas douradas espalhadas pela cidade!",
	"Cada casinha colorida é uma atividade. Chegue no círculo brilhante da porta e toque no botão grande (ou aperte E) para entrar.",
	"Converse com as crianças para aprender inglês, jogue a bolinha comigo (tecla B) e use o MAPA para ir direto às atividades. Divirta-se!",
]

var city: PSCity
var player: CharacterBody3D
var hero: PSHero
var dog: PSDog
var cam_pivot: Node3D
var cam_arm: SpringArm3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.32
var cam_dist := 6.2
var cam_idle := 0.0
var vy := 0.0
var vel_h := Vector3.ZERO
var air_time := 0.0
var was_air := false
var jump_buffer := 0.0
var step_acc := 0.0
var idle_time := 0.0
var h_speed := 0.0

var npcs: Array[PSNpc] = []
var animals: Array[Dictionary] = []
var stars: Array[Dictionary] = []
var world_stars := 0
var ball: Node3D = null
var ball_flight: Dictionary = {}
var fetch_count := 0
var pending_cheer := false

# interface
var ui: CanvasLayer
var ui_root: Control
var hud: Control
var overlay: Control = null
var games: PSGames = null
var fade_rect: ColorRect
var toast_box: VBoxContainer
var star_label: Label
var world_star_label: Label
var quest_box: VBoxContainer
var joystick: PSUI.Joystick
var minimap: PSUI.MiniMap
var btn_jump: PSUI.HoldButton
var btn_run: PSUI.HoldButton
var prompt_btn: Button
var prompt_action: Callable
var prompt_dist := 999.0
var tut_panel: Control = null
var tut_step := 0
var touch_ui := false
var _star_mesh: ArrayMesh
var _star_mat: StandardMaterial3D

# ---------------------------------------------------------------------------------------
func _ready() -> void:
	randomize()
	PSConfig.glb_flip = bool(PSProgress.setting("glb_flip", false))
	touch_ui = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var audio := PSAudio.new()
	audio.name = "Audio"
	add_child(audio)
	city = PSCity.new()
	city.name = "City"
	add_child(city)
	city.cycle_on = bool(PSProgress.setting("day_cycle", true))
	city.build()
	city.sun.shadow_enabled = bool(PSProgress.setting("shadows", true))
	_build_player()
	_build_dog()
	_build_npcs()
	_build_animals()
	_build_stars()
	_build_ui()
	_load_outfit()
	_refresh_hud()
	PSAudio.music("music_city")
	PSAudio.ambient(true)
	if not PSProgress.flag("tutorial_done"):
		_start_tutorial()
	else:
		toast("Bem-vindo de volta, Pietro!")

# ---- construção ------------------------------------------------------------------------------
func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Pietro"
	player.position = city.spawn_pos
	player.rotation.y = PI
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.3
	cs.shape = cap
	cs.position.y = 0.67
	player.add_child(cs)
	add_child(player)
	hero = PSHero.new()
	player.add_child(hero)
	hero.build(1.25, "azul")
	cam_pivot = Node3D.new()
	cam_pivot.position = player.position + Vector3(0, 1.4, 0)
	add_child(cam_pivot)
	cam_arm = SpringArm3D.new()
	cam_arm.spring_length = cam_dist
	cam_arm.margin = 0.3
	cam_arm.add_excluded_object(player.get_rid())
	cam_pivot.add_child(cam_arm)
	camera = Camera3D.new()
	camera.fov = 68.0
	camera.far = 700.0
	cam_arm.add_child(camera)
	camera.make_current()
	yaw = 0.0
	cam_pivot.rotation = Vector3(pitch, yaw, 0)

func _build_dog() -> void:
	dog = PSDog.new()
	dog.name = "Thor"
	add_child(dog)
	dog.build(1.35)
	dog.position = city.spawn_pos + Vector3(1.6, 0, 1.6)
	dog.fetch_returned.connect(_on_fetch_returned)

func _build_npcs() -> void:
	var defs: Array = [
		["Lia", "rosa", 1.10, "walker", 20.0, 1.0],
		["Davi", "verde", 1.22, "walker", 140.0, -1.0],
		["Laura", "branca", 1.02, "walker", 250.0, 1.0],
		["Sofia", "amarela", 1.06, "stander", 0.0, 0.0],
		["Theo", "roxa", 1.25, "stander", 0.0, 0.0],
		["Caio", "azul", 1.30, "stander", 0.0, 0.0],
		["Alice", "laranja", 1.10, "sitter", 0.0, 0.0],
		["Bento", "vermelha", 1.16, "sitter", 0.0, 0.0],
	]
	var stand_spots: Array = [Vector3(5.5, 0, 14.0), Vector3(-13.0, 0, -5.0), Vector3(2.5, 0, -25.5)]
	var si := 0
	var bi := 0
	for d in defs:
		var row: Array = d
		var npc := PSNpc.new()
		add_child(npc)
		npc.setup(str(row[1]), float(row[2]), str(row[3]), str(row[0]))
		match str(row[3]):
			"walker":
				npc.place_on_ring(deg_to_rad(float(row[4])), 28.8, float(row[5]))
			"stander":
				var p: Vector3 = stand_spots[si % stand_spots.size()]
				si += 1
				npc.position = p
				npc.rotation.y = PSConfig.yaw_to(p, Vector3.ZERO)
			"sitter":
				var spot: Dictionary = city.bench_spots[(2 + bi * 5) % city.bench_spots.size()]
				bi += 1
				var by: float = spot["yaw"]
				var bp: Vector3 = spot["pos"]
				var fwd := Vector3(sin(by), 0, cos(by))
				npc.position = Vector3(bp.x, npc.position.y, bp.z) + fwd * 0.22
				npc.rotation.y = by
				npc.home_yaw = by
		npcs.append(npc)

func _build_animals() -> void:
	var ids: Array = PSConfig.ANIMALS.duplicate()
	ids.shuffle()
	for i in range(city.zoo_spots.size()):
		var id: String = ids[i % ids.size()]
		var sp: Vector3 = city.zoo_spots[i]
		var path := "res://assets/animals/%s_01.glb" % id.capitalize()
		var holder := city._place_glb(path, sp, randf() * TAU, 1.05, self, true)
		if holder == null:
			continue
		var lab := Label3D.new()
		lab.text = "%s\n%s" % [PSConfig.ANIMAL_EN[id], PSConfig.ANIMAL_PT[id]]
		lab.font_size = 60
		lab.pixel_size = 0.006
		lab.outline_size = 16
		lab.outline_modulate = Color("1d2b53")
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.position = Vector3(0, 1.6, 0)
		lab.visible = false
		holder.add_child(lab)
		animals.append({"node": holder, "id": id, "base": sp, "phase": randf() * 6.0, "label": lab})

func _make_star_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var r := 0.5 if i % 2 == 0 else 0.22
		var a := -PI / 2.0 + TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), -sin(a)) * r)
	var h := 0.09
	for i in range(10):
		var a2 := pts[i]
		var b2 := pts[(i + 1) % 10]
		st.add_vertex(Vector3(0, 0, h))
		st.add_vertex(Vector3(b2.x, b2.y, h))
		st.add_vertex(Vector3(a2.x, a2.y, h))
		st.add_vertex(Vector3(0, 0, -h))
		st.add_vertex(Vector3(a2.x, a2.y, -h))
		st.add_vertex(Vector3(b2.x, b2.y, -h))
		st.add_vertex(Vector3(a2.x, a2.y, h))
		st.add_vertex(Vector3(b2.x, b2.y, h))
		st.add_vertex(Vector3(b2.x, b2.y, -h))
		st.add_vertex(Vector3(a2.x, a2.y, h))
		st.add_vertex(Vector3(b2.x, b2.y, -h))
		st.add_vertex(Vector3(a2.x, a2.y, -h))
	return st.commit()

func _build_stars() -> void:
	_star_mesh = _make_star_mesh()
	_star_mat = StandardMaterial3D.new()
	_star_mat.albedo_color = Color("ffd21f")
	_star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_star_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for sp in city.star_spots:
		var n := Node3D.new()
		n.position = sp
		var mi := MeshInstance3D.new()
		mi.mesh = _star_mesh
		mi.material_override = _star_mat
		mi.scale = Vector3.ONE * 1.1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		add_child(n)
		stars.append({"node": n, "pos": sp, "on": true, "phase": randf() * 6.0})

func _respawn_stars() -> void:
	for s in stars:
		s["on"] = true
		(s["node"] as Node3D).visible = true
	world_stars = 0

# ---- interface ---------------------------------------------------------------------------------
func _hud_button(text: String, color: Color, cb: Callable, w: float = 120.0) -> Button:
	var b := PSUI.button(text, color, Vector2(w, 54), 24)
	b.pressed.connect(cb)
	return b

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = PSUI.make_theme()
	ui.add_child(ui_root)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	# estrelas (canto superior esquerdo)
	var sp := PSUI.panel(Color(1, 1, 1, 0.92), 26)
	sp.position = Vector2(16, 14)
	hud.add_child(sp)
	var sv := VBoxContainer.new()
	sp.add_child(sv)
	var sh := HBoxContainer.new()
	sv.add_child(sh)
	sh.add_child(PSUI.Icon.new().setup("star", Color("ffc107"), 42))
	star_label = PSUI.label("0", 34, Color("1d2b53"))
	sh.add_child(star_label)
	world_star_label = PSUI.label("", 18, Color("5a6b99"))
	sv.add_child(world_star_label)
	# missões
	var qp := PSUI.panel(Color(1, 1, 1, 0.78), 18)
	qp.position = Vector2(16, 112)
	hud.add_child(qp)
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 2)
	qp.add_child(quest_box)
	# botões superiores
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 8)
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -16
	tr.offset_top = 14
	hud.add_child(tr)
	tr.add_child(_hud_button("Mapa", Color("2fa7b8"), _open_map, 110))
	tr.add_child(_hud_button("Roupas", Color("ee6bd0"), _open_wardrobe, 120))
	tr.add_child(_hud_button("Opções", Color("6c7a9c"), _open_options, 120))
	# minimapa
	minimap = PSUI.MiniMap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	minimap.offset_right = -16
	minimap.offset_top = 80
	minimap.gui_input.connect(_on_minimap_input)
	hud.add_child(minimap)
	# avisos
	toast_box = VBoxContainer.new()
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.offset_left = -330
	toast_box.offset_right = 330
	toast_box.offset_top = 92
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(toast_box)
	# joystick (toque)
	joystick = PSUI.Joystick.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.grow_vertical = Control.GROW_DIRECTION_BEGIN
	joystick.offset_left = 28
	joystick.offset_bottom = -28
	joystick.visible = touch_ui
	hud.add_child(joystick)
	# botões de ação
	var ab := Control.new()
	ab.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ab.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ab.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ab.offset_right = -18
	ab.offset_bottom = -18
	ab.custom_minimum_size = Vector2(330, 270)
	ab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ab)
	btn_jump = PSUI.HoldButton.new().setup("PULAR", Color("3fbf6a"), 124, 22)
	btn_jump.position = Vector2(200, 142)
	btn_jump.pressed_down.connect(func(): jump_buffer = 0.18)
	ab.add_child(btn_jump)
	btn_run = PSUI.HoldButton.new().setup("CORRER", Color("ff8a3d"), 96, 18)
	btn_run.position = Vector2(88, 176)
	ab.add_child(btn_run)
	var btn_ball := PSUI.HoldButton.new().setup("BOLA", Color("e5534b"), 96, 20)
	btn_ball.position = Vector2(92, 62)
	btn_ball.pressed_down.connect(_throw_ball)
	ab.add_child(btn_ball)
	var btn_call := PSUI.HoldButton.new().setup("THOR", Color("c98d4c"), 96, 20)
	btn_call.position = Vector2(206, 24)
	btn_call.pressed_down.connect(_call_dog)
	ab.add_child(btn_call)
	# botão de interação contextual
	prompt_btn = PSUI.button("", Color("ffb703"), Vector2(560, 76), 32)
	prompt_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_btn.offset_left = -280
	prompt_btn.offset_right = 280
	prompt_btn.offset_bottom = -34
	prompt_btn.offset_top = -110
	prompt_btn.visible = false
	prompt_btn.add_theme_color_override("font_color", Color("3a2a00"))
	prompt_btn.add_theme_color_override("font_hover_color", Color("3a2a00"))
	prompt_btn.add_theme_color_override("font_pressed_color", Color("3a2a00"))
	prompt_btn.pressed.connect(_do_interact)
	hud.add_child(prompt_btn)
	if not touch_ui:
		var hint := PSUI.label("WASD andar  •  Shift correr  •  Espaço pular  •  E interagir  •  B bola  •  M mapa", 18, Color(1, 1, 1, 0.9))
		hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		hint.add_theme_constant_override("outline_size", 6)
		hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
		hint.offset_left = 18
		hint.offset_bottom = -10
		hud.add_child(hint)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade_rect)

func _refresh_hud() -> void:
	star_label.text = str(PSProgress.stars())
	world_star_label.text = "Estrelas na cidade: %d/%d" % [world_stars, stars.size()]
	_refresh_quests()
	minimap.star_points = []

func _refresh_quests() -> void:
	for c in quest_box.get_children():
		c.queue_free()
	var scored: Array = []
	for q in QUESTS:
		var qd: Dictionary = q
		var goal := int(qd["base"]) * (PSProgress.quest_tier(str(qd["id"])) + 1)
		var n := PSProgress.quest_count(str(qd["id"]))
		scored.append({"q": qd, "goal": goal, "n": n, "r": float(n) / float(goal)})
	scored.sort_custom(func(a, b): return float(a["r"]) > float(b["r"]))
	quest_box.add_child(PSUI.label("Missões", 18, Color("5a6b99")))
	for i in range(3):
		var s: Dictionary = scored[i]
		var qd2: Dictionary = s["q"]
		quest_box.add_child(PSUI.label("%s  %d/%d" % [qd2["text"], s["n"], s["goal"]], 17, Color("1d2b53")))

func toast(text: String, col: Color = Color("1d2b53")) -> void:
	var p := PSUI.panel(Color(1, 1, 1, 0.96), 20)
	var l := PSUI.label(text, 26, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	p.add_child(l)
	toast_box.add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

func _fade(to_alpha: float, t: float = 0.25) -> void:
	var tw := fade_rect.create_tween()
	tw.tween_property(fade_rect, "color:a", to_alpha, t)
	await tw.finished

# ---- missões e estrelas -------------------------------------------------------------------------
func _quest(id: String) -> void:
	for q in QUESTS:
		var qd: Dictionary = q
		if qd["id"] == id:
			if PSProgress.quest_add(id, int(qd["base"])):
				var r := int(qd["reward"])
				PSProgress.add_stars(r)
				toast("Missão cumprida: %s!  +%d estrelas" % [qd["text"], r], Color("2e8b57"))
				PSAudio.sfx("levelup")
				hero.cheer()
			break
	_refresh_hud()

func _collect_star(s: Dictionary) -> void:
	s["on"] = false
	(s["node"] as Node3D).visible = false
	world_stars += 1
	PSProgress.add_stars(1)
	PSAudio.sfx("star")
	_burst(s["pos"], Color("ffd21f"), 16)
	_quest("stars")
	_refresh_hud()
	if world_stars >= stars.size():
		toast("Você coletou todas as estrelas da cidade! +5", Color("2e8b57"))
		PSProgress.add_stars(5)
		PSAudio.sfx("win")
		_respawn_stars()
		_refresh_hud()

func _burst(pos: Vector3, col: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	p.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = m
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -6.0, 0)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)

# ---- bola / Thor ----------------------------------------------------------------------------------
func _throw_ball() -> void:
	if games != null or overlay != null:
		return
	if (ball != null and is_instance_valid(ball)) or dog.is_busy():
		toast("Espere o Thor trazer a bolinha!")
		return
	var fwd := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	var side := Vector3(cos(player.rotation.y), 0, -sin(player.rotation.y))
	var target := player.position + fwd * randf_range(8.0, 12.0) + side * randf_range(-3.0, 3.0)
	var r := Vector2(target.x, target.z).length()
	if r > PSConfig.WALK_LIMIT:
		target = Vector3(target.x, 0, target.z) * (PSConfig.WALK_LIMIT / r)
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.15
	sm.height = 0.3
	(ball as MeshInstance3D).mesh = sm
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color("ff4d4d")
	bm.roughness = 0.4
	(ball as MeshInstance3D).material_override = bm
	add_child(ball)
	ball.position = player.position + Vector3(0, 1.1, 0) + fwd * 0.4
	ball_flight = {"from": ball.position, "to": Vector3(target.x, 0.15, target.z), "t": 0.0, "dur": 0.95}
	PSAudio.sfx("throw")
	hero.play_once("wave", 0.6)
	dog.fetch(ball)
	dog.excite_for(1.0)

func _update_ball(delta: float) -> void:
	if ball == null or not is_instance_valid(ball) or ball_flight.is_empty():
		return
	var t: float = ball_flight["t"] + delta
	ball_flight["t"] = t
	var k := clampf(t / float(ball_flight["dur"]), 0.0, 1.0)
	var a: Vector3 = ball_flight["from"]
	var b: Vector3 = ball_flight["to"]
	var p := a.lerp(b, k)
	p.y = lerpf(a.y, b.y, k) + 4.0 * 3.0 * k * (1.0 - k)
	ball.position = p
	if k >= 1.0:
		ball_flight = {}
		PSAudio.sfx("bounce", -4.0)

func _on_fetch_returned(pos: Vector3) -> void:
	fetch_count += 1
	_burst(pos + Vector3(0, 1.0, 0), Color("ff7ab8"), 10)
	PSAudio.sfx("heart")
	_quest("fetch")
	if fetch_count % 3 == 0:
		PSProgress.add_stars(1)
		toast("Thor ganhou uma estrela pra você! +1", Color("2e8b57"))
		_refresh_hud()

func _call_dog() -> void:
	dog.mode = "follow"
	dog.excite_for(2.0)
	dog.bark(true)
	if dog.position.distance_to(player.position) > 20.0:
		dog.position = player.position + Vector3(2.0, 0, 2.0)

# ---- interação -------------------------------------------------------------------------------------------
func _update_prompt() -> void:
	var best_d := 999.0
	var best_label := ""
	var best_cb := Callable()
	var pp := player.position
	for pl in city.places:
		var d := Vector2(pp.x - pl["entrance"].x, pp.z - pl["entrance"].z).length()
		if d < 4.3 and d - 1.5 < best_d:
			best_d = d - 1.5
			best_label = "Entrar: %s" % pl["name"]
			best_cb = _enter_place.bind(int(pl["index"]))
	for npc in npcs:
		var d2 := pp.distance_to(npc.global_position)
		if d2 < 3.2 and d2 < best_d:
			best_d = d2
			best_label = "Conversar com %s" % npc.display_name
			best_cb = _talk_to.bind(npc)
	for a in animals:
		var an: Node3D = a["node"]
		var d3 := pp.distance_to(an.global_position)
		var lab: Label3D = a["label"]
		lab.visible = d3 < 5.0
		if d3 < 2.7 and d3 < best_d:
			best_d = d3
			best_label = "Ouvir: %s" % PSConfig.ANIMAL_EN[a["id"]]
			best_cb = _hear_animal.bind(a)
	var dd := pp.distance_to(dog.position)
	if dd < 2.4 and dd < best_d:
		best_d = dd
		best_label = "Fazer carinho no Thor"
		best_cb = _pet_dog
	prompt_btn.visible = best_label != "" and games == null and overlay == null
	if best_label != "":
		prompt_btn.text = best_label if touch_ui else best_label + "   [E]"
		prompt_action = best_cb
		prompt_dist = best_d

func _do_interact() -> void:
	if games != null or overlay != null or not prompt_btn.visible:
		return
	if prompt_action.is_valid():
		prompt_action.call()

func _talk_to(npc: PSNpc) -> void:
	npc.talk()
	_quest("talk")

func _hear_animal(a: Dictionary) -> void:
	var id: String = a["id"]
	PSAudio.speak(str(PSConfig.ANIMAL_EN[id]), "en")
	PSAudio.sfx("pop")
	var an: Node3D = a["node"]
	a["hop"] = 1.0
	toast("%s  =  %s" % [PSConfig.ANIMAL_EN[id], PSConfig.ANIMAL_PT[id]])
	_quest("animals")

func _pet_dog() -> void:
	dog.excite_for(3.0)
	dog.bark(true)
	_burst(dog.position + Vector3(0, 1.1, 0), Color("ff7ab8"), 12)
	PSAudio.sfx("heart")
	hero.wave()
	_quest("pet")

# ---- atividades ------------------------------------------------------------------------------------------
func _enter_place(i: int) -> void:
	if games != null:
		return
	PSAudio.sfx("door")
	await _fade(1.0, 0.25)
	_open_game(i)
	await _fade(0.0, 0.25)

func _open_game(i: int) -> void:
	var pl: Dictionary = PSConfig.PLACES[i]
	games = PSGames.new()
	ui_root.add_child(games)
	ui_root.move_child(fade_rect, ui_root.get_child_count() - 1)
	games.open(str(pl["name"]), pl["color"])
	games.closed.connect(_close_game)
	games.level_won.connect(_on_level_won)
	hud.visible = false
	prompt_btn.visible = false
	PSAudio.ducked(true)

func _close_game() -> void:
	if games == null:
		return
	games.queue_free()
	games = null
	hud.visible = true
	PSAudio.music("music_city")
	PSAudio.ducked(false)
	_refresh_hud()
	if pending_cheer:
		pending_cheer = false
		hero.cheer()
		dog.excite_for(3.0)
		dog.bark(true)

func _on_level_won(_mode: String, _level: int, stars_got: int) -> void:
	pending_cheer = true
	_quest("play")

# ---- sobreposições (mapa, roupas, opções) --------------------------------------------------------------
func _make_overlay(dim: float = 0.5) -> Control:
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var d := ColorRect.new()
	d.color = Color(0.05, 0.08, 0.2, dim)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(d)
	ui_root.add_child(overlay)
	ui_root.move_child(fade_rect, ui_root.get_child_count() - 1)
	prompt_btn.visible = false
	PSAudio.sfx("open")
	return overlay

func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null

func _open_map() -> void:
	if games != null:
		return
	var ov := _make_overlay(0.55)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	ov.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	margin.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var t := PSUI.label("Mapa das atividades", 40, Color.WHITE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(_hud_button("Fechar", Color("6c7a9c"), _close_overlay, 140))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	for i in range(PSConfig.PLACES.size()):
		var pl: Dictionary = PSConfig.PLACES[i]
		var col: Color = pl["color"]
		var card := PSUI.panel(col.lerp(Color.WHITE, 0.25), 22)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)
		var nl := PSUI.label(str(pl["name"]), 30, Color("1d2b53"))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nl)
		var tl := PSUI.label("%s  •  %d/30" % [pl["tag"], PSProgress.mode_stars(str(pl["name"]))], 17, Color("1d2b53"))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(tl)
		var br := HBoxContainer.new()
		br.alignment = BoxContainer.ALIGNMENT_CENTER
		br.add_theme_constant_override("separation", 8)
		cv.add_child(br)
		var go := PSUI.button("Ir até lá", Color("2fa7b8"), Vector2(110, 46), 20)
		go.pressed.connect(_teleport_to.bind(i))
		br.add_child(go)
		var play := PSUI.button("Jogar", Color("3fbf6a"), Vector2(100, 46), 20)
		play.pressed.connect(_play_from_map.bind(i))
		br.add_child(play)

func _on_minimap_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).device != InputEvent.DEVICE_ID_EMULATION:
		_open_map()
	elif e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed:
		_open_map()

func _play_from_map(i: int) -> void:
	_close_overlay()
	_enter_place(i)

func _teleport_to(i: int) -> void:
	_close_overlay()
	PSAudio.sfx("door")
	await _fade(1.0, 0.25)
	var pl: Dictionary = city.places[i]
	var ent: Vector3 = pl["entrance"]
	var front := (Vector3.ZERO - ent).normalized()
	player.position = ent + front * 2.4
	player.rotation.y = PSConfig.yaw_to(player.position, pl["pos"])
	yaw = player.rotation.y + PI
	vel_h = Vector3.ZERO
	vy = 0.0
	dog.position = player.position + Vector3(1.4, 0, 1.2)
	cam_pivot.position = player.position + Vector3(0, 1.4, 0)
	await _fade(0.0, 0.25)

func _load_outfit() -> void:
	var shirt := str(PSProgress.outfit_get("shirt", "azul"))
	var hat := str(PSProgress.outfit_get("hat", ""))
	var gl := bool(PSProgress.outfit_get("glasses", false))
	# peças ainda não liberadas voltam ao padrão
	var total := PSProgress.stars()
	var hi := PSHero.HATS.find(hat)
	if hi > 0 and total < int(PSHero.HAT_COST[hi]):
		hat = ""
	if gl and total < PSHero.GLASSES_COST:
		gl = false
	hero.apply_outfit(shirt, hat, gl)
	var ci := int(PSProgress.outfit_get("collar", 0))
	var col: Color = COLLARS[clampi(ci, 0, COLLARS.size() - 1)][1]
	dog.set_collar(col, bool(PSProgress.outfit_get("bow", false)))

func _open_wardrobe() -> void:
	if games != null:
		return
	var ov := _make_overlay(0.0)
	var panel := PSUI.panel(Color(1, 1, 1, 0.96), 26)
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -470
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = -16
	ov.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)
	var tt := PSUI.label("Guarda-roupa", 36, Color("1d2b53"))
	vb.add_child(tt)
	var total := PSProgress.stars()
	vb.add_child(PSUI.label("Você tem %d estrelas. Ganhe mais para liberar!" % total, 18, Color("5a6b99")))
	vb.add_child(PSUI.label("Camiseta do Pietro", 24, Color("1d2b53")))
	var sg := GridContainer.new()
	sg.columns = 4
	sg.add_theme_constant_override("h_separation", 8)
	sg.add_theme_constant_override("v_separation", 8)
	vb.add_child(sg)
	for i in range(PSHero.SHIRTS.size()):
		var b := PSUI.button("", PSHero.SHIRT_COLORS[i], Vector2(86, 56), 20)
		b.pressed.connect(_set_shirt.bind(str(PSHero.SHIRTS[i])))
		sg.add_child(b)
	vb.add_child(PSUI.label("Chapéus", 24, Color("1d2b53")))
	var hg := GridContainer.new()
	hg.columns = 2
	hg.add_theme_constant_override("h_separation", 8)
	hg.add_theme_constant_override("v_separation", 8)
	vb.add_child(hg)
	for i in range(PSHero.HATS.size()):
		var cost: int = PSHero.HAT_COST[i]
		var locked := total < cost
		var hb := PSUI.button(str(PSHero.HAT_NAMES[i]) + (("  (%d estrelas)" % cost) if locked else ""), Color("5b8cff"), Vector2(196, 52), 18)
		hb.disabled = locked
		hb.pressed.connect(_set_hat.bind(str(PSHero.HATS[i])))
		hg.add_child(hb)
	var gl_locked := total < PSHero.GLASSES_COST
	var gb := PSUI.button("Óculos ligado/desligado" + (("  (%d estrelas)" % PSHero.GLASSES_COST) if gl_locked else ""), Color("8f6bff"), Vector2(0, 52), 18)
	gb.disabled = gl_locked
	gb.pressed.connect(_toggle_glasses)
	vb.add_child(gb)
	vb.add_child(PSUI.label("Coleira do Thor", 24, Color("1d2b53")))
	var cg := GridContainer.new()
	cg.columns = 3
	cg.add_theme_constant_override("h_separation", 8)
	cg.add_theme_constant_override("v_separation", 8)
	vb.add_child(cg)
	for i in range(COLLARS.size()):
		var cb := PSUI.button(str(COLLARS[i][0]), COLLARS[i][1], Vector2(130, 50), 18)
		cb.pressed.connect(_set_collar.bind(i))
		cg.add_child(cb)
	var bow_locked := total < 20
	var bb := PSUI.button("Laço no Thor" + ("  (20 estrelas)" if bow_locked else ""), Color("ee6bd0"), Vector2(0, 52), 18)
	bb.disabled = bow_locked
	bb.pressed.connect(_toggle_bow)
	vb.add_child(bb)
	var done := PSUI.button("Pronto!", Color("3fbf6a"), Vector2(0, 62), 28)
	done.pressed.connect(_close_overlay)
	vb.add_child(done)
	hero.cheer()

func _set_shirt(id: String) -> void:
	PSProgress.outfit_set("shirt", id)
	hero.set_shirt(id)
	PSAudio.sfx("pop")

func _set_hat(id: String) -> void:
	PSProgress.outfit_set("hat", id)
	hero.set_hat(id)
	PSAudio.sfx("pop")
	hero.cheer()

func _toggle_glasses() -> void:
	var v := not hero.glasses
	PSProgress.outfit_set("glasses", v)
	hero.set_glasses(v)
	PSAudio.sfx("pop")

func _set_collar(i: int) -> void:
	PSProgress.outfit_set("collar", i)
	dog.set_collar(COLLARS[i][1], bool(PSProgress.outfit_get("bow", false)))
	PSAudio.sfx("pop")
	dog.excite_for(1.5)

func _toggle_bow() -> void:
	var v := not bool(PSProgress.outfit_get("bow", false))
	PSProgress.outfit_set("bow", v)
	_load_outfit()
	PSAudio.sfx("pop")

func _open_options() -> void:
	if games != null:
		return
	var ov := _make_overlay(0.55)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var panel := PSUI.panel(Color(1, 1, 1, 0.97), 28)
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(620, 0)
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(PSUI.label("Opções", 40, Color("1d2b53")))
	var audio := get_node("Audio") as PSAudio
	vb.add_child(PSUI.label("Música", 24))
	var ms := HSlider.new()
	ms.min_value = 0.0
	ms.max_value = 1.0
	ms.step = 0.05
	ms.value = float(PSProgress.setting("music_vol", 0.55))
	ms.custom_minimum_size = Vector2(0, 32)
	ms.value_changed.connect(func(v: float): audio.set_music_volume(v))
	vb.add_child(ms)
	vb.add_child(PSUI.label("Efeitos sonoros", 24))
	var ss := HSlider.new()
	ss.min_value = 0.0
	ss.max_value = 1.0
	ss.step = 0.05
	ss.value = float(PSProgress.setting("sfx_vol", 0.9))
	ss.custom_minimum_size = Vector2(0, 32)
	ss.value_changed.connect(func(v: float): audio.set_sfx_volume(v))
	vb.add_child(ss)
	vb.add_child(_check("Voz lendo as palavras em inglês", audio.tts_enabled, func(v: bool): audio.set_voice(v)))
	vb.add_child(_check("Ciclo de dia e noite", city.cycle_on, _on_day_cycle))
	vb.add_child(_check("Sombras (desligue em celulares lentos)", city.sun.shadow_enabled, _on_shadows))
	vb.add_child(_check("Corrigir direção dos modelos 3D (se estiverem de costas)", PSConfig.glb_flip, _on_glb_flip))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	var tut := PSUI.button("Rever tutorial", Color("2fa7b8"), Vector2(0, 56), 22)
	tut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tut.pressed.connect(_on_tut_again)
	row.add_child(tut)
	var cont := PSUI.button("Continuar", Color("3fbf6a"), Vector2(0, 56), 22)
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.pressed.connect(_close_overlay)
	row.add_child(cont)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var quit := PSUI.button("Sair do jogo", Color("e5534b"), Vector2(0, 52), 22)
		quit.pressed.connect(func(): get_tree().quit())
		vb.add_child(quit)

func _on_day_cycle(v: bool) -> void:
	city.cycle_on = v
	PSProgress.set_setting("day_cycle", v)

func _on_shadows(v: bool) -> void:
	city.sun.shadow_enabled = v
	PSProgress.set_setting("shadows", v)

func _on_glb_flip(v: bool) -> void:
	PSConfig.glb_flip = v
	PSProgress.set_setting("glb_flip", v)
	_apply_glb_flip()

func _on_tut_again() -> void:
	_close_overlay()
	_start_tutorial()

func _check(text: String, value: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 22)
	c.add_theme_color_override("font_color", Color("1d2b53"))
	c.add_theme_color_override("font_hover_color", Color("1d2b53"))
	c.add_theme_color_override("font_pressed_color", Color("1d2b53"))
	c.toggled.connect(cb)
	return c

func _apply_glb_flip() -> void:
	for n in get_tree().get_nodes_in_group("glb_front"):
		(n as Node3D).rotation.y = PSConfig.glb_yaw()

# ---- tutorial ------------------------------------------------------------------------------------------------------
func _start_tutorial() -> void:
	tut_step = 0
	_show_tut()

func _show_tut() -> void:
	if tut_panel != null:
		tut_panel.queue_free()
	tut_panel = PSUI.panel(Color(1, 1, 1, 0.96), 26)
	tut_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tut_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tut_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tut_panel.offset_bottom = -130
	hud.add_child(tut_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	tut_panel.add_child(hb)
	var thor := TextureRect.new()
	thor.texture = load("res://assets/ui/thor_front.png") as Texture2D
	thor.custom_minimum_size = Vector2(110, 110)
	thor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(thor)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	hb.add_child(vb)
	var l := PSUI.label(TUTORIAL[tut_step], 24, Color("1d2b53"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	vb.add_child(l)
	var last := tut_step >= TUTORIAL.size() - 1
	var nb := PSUI.button("Vamos lá!" if last else "Próximo", Color("3fbf6a"), Vector2(180, 52), 24)
	nb.pressed.connect(_next_tut)
	vb.add_child(nb)
	PSAudio.sfx("pop")
	dog.bark(true)

func _next_tut() -> void:
	tut_step += 1
	if tut_step >= TUTORIAL.size():
		tut_panel.queue_free()
		tut_panel = null
		PSProgress.set_flag("tutorial_done", true)
		toast("Dica: a casa azul 'Inglês' fica ao norte!")
		return
	_show_tut()

# ---- entrada e física ----------------------------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if games != null:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			match k.keycode:
				KEY_SPACE:
					if overlay == null:
						jump_buffer = 0.18
				KEY_E, KEY_ENTER, KEY_KP_ENTER:
					_do_interact()
				KEY_B:
					_throw_ball()
				KEY_M:
					if overlay == null:
						_open_map()
					else:
						_close_overlay()
				KEY_ESCAPE:
					if overlay != null:
						_close_overlay()
					else:
						_open_options()
				KEY_Z:
					yaw += 0.4
				KEY_C:
					yaw -= 0.4
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)) != 0 and mm.device != InputEvent.DEVICE_ID_EMULATION:
			_rotate_cam(mm.relative)
	elif event is InputEventScreenDrag:
		_rotate_cam((event as InputEventScreenDrag).relative * 0.8)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = clampf(cam_dist - 0.5, 3.4, 11.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = clampf(cam_dist + 0.5, 3.4, 11.0)

func _rotate_cam(rel: Vector2) -> void:
	if overlay != null:
		return
	yaw -= rel.x * 0.006
	pitch = clampf(pitch - rel.y * 0.004, -1.2, 0.1)
	cam_idle = 0.0

func _read_move() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y -= 1.0
	var jv := joystick.value
	v += Vector2(jv.x, -jv.y)
	var gx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var gy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(gx) > 0.2 or absf(gy) > 0.2:
		v += Vector2(gx, -gy)
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if absf(rx) > 0.25:
		yaw -= rx * 0.04
	if v.length() > 1.0:
		v = v.normalized()
	return v

func _physics_process(delta: float) -> void:
	var blocked := games != null or overlay != null
	var input := Vector2.ZERO if blocked else _read_move()
	var running := (Input.is_key_pressed(KEY_SHIFT) or btn_run.held) and not blocked
	var cf := Vector3(-sin(yaw), 0, -cos(yaw))
	var cr := Vector3(cos(yaw), 0, -sin(yaw))
	var dir := cr * input.x + cf * input.y
	var m := input.length()
	var target_speed := 0.0
	if m > 0.1:
		target_speed = WALK_SPEED if (m < 0.6 and not running) else (SPRINT_SPEED if running else RUN_SPEED)
	var target_v := dir.normalized() * target_speed if m > 0.1 else Vector3.ZERO
	vel_h = vel_h.move_toward(target_v, 24.0 * delta)
	var on_floor := player.is_on_floor()
	if on_floor:
		vy = -0.5
		if was_air:
			was_air = false
			PSAudio.sfx("land", -6.0)
			hero.set_air(false)
		air_time = 0.0
	else:
		vy -= GRAVITY * delta
		air_time += delta
		if air_time > 0.12 and not was_air:
			was_air = true
			hero.set_air(true)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if jump_buffer > 0.0 and on_floor and not blocked:
		vy = JUMP_VEL
		jump_buffer = 0.0
		PSAudio.sfx("jump", -4.0)
		hero.set_air(true)
		was_air = true
		air_time = 0.2
	player.velocity = Vector3(vel_h.x, vy, vel_h.z)
	player.move_and_slide()
	vy = player.velocity.y
	var r := Vector2(player.position.x, player.position.z).length()
	if r > PSConfig.WALK_LIMIT:
		var k := PSConfig.WALK_LIMIT / r
		player.position.x *= k
		player.position.z *= k
	h_speed = Vector2(vel_h.x, vel_h.z).length()
	if h_speed > 0.3:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(vel_h.x, vel_h.z), clampf(14.0 * delta, 0.0, 1.0))
		idle_time = 0.0
	else:
		idle_time += delta
	hero.set_motion(h_speed if on_floor else 0.0)
	if idle_time > 14.0 and on_floor and not hero.is_sitting() and not blocked:
		hero.sit()
	# passos
	if on_floor and h_speed > 0.5:
		step_acc += h_speed * delta
		if step_acc > 0.9 + 0.1 * h_speed:
			step_acc = 0.0
			var pave := r < 7.2 or (r > 21.0 and r < 30.0)
			PSAudio.sfx_rand("step_pave" if pave else "step_grass", 3, -8.0)
	else:
		step_acc = 0.0
	dog.tick(delta, player.position, player.rotation.y, h_speed)
	for npc in npcs:
		npc.tick(delta, player.position)
	_update_ball(delta)

func _process(delta: float) -> void:
	city.update(delta, player.position)
	# câmera
	cam_idle += delta
	if cam_idle > 1.6 and h_speed > 1.0 and overlay == null:
		var want := player.rotation.y + PI
		yaw = lerp_angle(yaw, want, clampf(0.9 * delta, 0.0, 1.0))
	cam_pivot.position = cam_pivot.position.lerp(player.position + Vector3(0, 1.4, 0), clampf(14.0 * delta, 0.0, 1.0))
	cam_pivot.rotation = Vector3(pitch, yaw, 0)
	cam_arm.spring_length = lerpf(cam_arm.spring_length, cam_dist, clampf(6.0 * delta, 0.0, 1.0))
	# estrelas colecionáveis
	var t := Time.get_ticks_msec() / 1000.0
	var pp := player.position
	for s in stars:
		if not s["on"]:
			continue
		var n: Node3D = s["node"]
		n.rotation.y = t * 2.0 + float(s["phase"])
		var sp: Vector3 = s["pos"]
		n.position.y = sp.y + sin(t * 2.4 + float(s["phase"])) * 0.15
		if Vector2(pp.x - sp.x, pp.z - sp.z).length() < 1.2 and absf(pp.y + 0.9 - sp.y) < 1.9:
			_collect_star(s)
	# bichinhos
	for a in animals:
		var an: Node3D = a["node"]
		var base: Vector3 = a["base"]
		var ph: float = a["phase"]
		var hop: float = a.get("hop", 0.0)
		a["hop"] = maxf(0.0, hop - delta * 1.4)
		an.position.y = absf(sin(t * 2.0 + ph)) * 0.04 + hop * absf(sin(t * 12.0)) * 0.35
		var to := player.position - an.position
		if to.length() < 7.0:
			an.rotation.y = lerp_angle(an.rotation.y, atan2(to.x, to.z), clampf(4.0 * delta, 0.0, 1.0))
		an.position.x = base.x
		an.position.z = base.z
	# interface
	if games == null:
		_update_prompt()
		minimap.player = player.position
		minimap.yaw = player.rotation.y
		minimap.dog = dog.position
		var pts: Array = []
		for s2 in stars:
			if s2["on"]:
				pts.append(s2["pos"])
		minimap.star_points = pts
		minimap.queue_redraw()
