extends Node3D

const PLACES := [
    {"name":"Memória", "pos":Vector3(-15,0,-15), "color":Color("ec83e8")},
    {"name":"Sudoku", "pos":Vector3(15,0,-15), "color":Color("6ce4c3")},
    {"name":"Inglês", "pos":Vector3(-15,0,15), "color":Color("67c6ff")},
    {"name":"Matemática", "pos":Vector3(15,0,15), "color":Color("ffcf63")},
    {"name":"Lógica", "pos":Vector3(0,0,-22), "color":Color("b8a1ff")},
    {"name":"Português", "pos":Vector3(0,0,22), "color":Color("ff998e")},
    {"name":"Ciências", "pos":Vector3(-22,0,0), "color":Color("6ee1b4")},
    {"name":"Geografia", "pos":Vector3(22,0,0), "color":Color("ffd38a")},
    {"name":"Animais", "pos":Vector3(-22,0,-22), "color":Color("f0b2e2")},
    {"name":"Cores", "pos":Vector3(22,0,-22), "color":Color("91d4ff")},
    {"name":"Frases", "pos":Vector3(-22,0,22), "color":Color("e0d181")},
    {"name":"Soletração", "pos":Vector3(22,0,22), "color":Color("9be2e5")}
]
var thor: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var root_ui: Control
var hint: Label
var current_game: PSGames
var move_input := Vector2.ZERO
var touch_vector := Vector2.ZERO
var last_direction := Vector3.FORWARD
var world_time := 0.0
# Third-person follow camera, tuned for a child-friendly mobile adventure.
const CAMERA_DISTANCE := 6.4
const CAMERA_HEIGHT := 3.5
const CAMERA_LOOK_HEIGHT := 1.35
var camera_yaw := 0.0
var camera_pitch := -0.19
var camera_distance := 7.5
var camera_dragging := false
var touch_camera_index := -1
var touch_camera_last := Vector2.ZERO
var pietro_visual: Node3D
var pietro_rest_y := 0.0
var pietro_rest_rotation := 0.0
var thor_visual: Node3D
var thor_rest_y := 0.0
var camera_pivot: Node3D
var camera_arm: SpringArm3D
var movement_speed := 5.0
var running_speed := 8.5
var current_velocity := Vector3.ZERO
var footstep_timer := 0.0
var footsteps: AudioStreamPlayer
var ui_camera_hint: Label
var sound_step: AudioStreamPlayer
var sound_reward: AudioStreamPlayer
var sound_enter: AudioStreamPlayer
var collectibles: Array[Area3D] = []
var collected_count := 0
var total_collectibles := 18
var jump_velocity := 0.0
var jump_height := 7.0
var ground_y := 0.1




func _ready() -> void:
    _make_world()
    _make_player()
    _make_ui()
    _make_collectibles()
    _make_audio()

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = 0.82
    return m

func _cube(parent: Node3D, label: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.material_override = _material(color)
    m.position = pos
    parent.add_child(m)
    return m

func _sphere(parent: Node3D, label: String, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = label
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2
    m.mesh = mesh
    m.material_override = _material(color)
    m.position = pos
    parent.add_child(m)
    return m


# Modelos importados: altura normalizada para manter escala consistente.
func _model(parent: Node3D, file: String, label: String, pos: Vector3, height: float, yaw: float = 0.0) -> Node3D:
    var scene: PackedScene = load(file) as PackedScene
    if scene == null:
        push_warning("Modelo indisponível: " + file)
        return null
    var holder := Node3D.new()
    holder.name = label
    holder.position = pos
    holder.rotation.y = yaw
    parent.add_child(holder)
    var instance := scene.instantiate() as Node3D
    holder.add_child(instance)
    # Obtém os limites dos MeshInstance3D, incluindo transformações internas.
    var bounds := AABB()
    var first := true
    for node in instance.find_children("*", "MeshInstance3D", true, false):
        var mesh_node := node as MeshInstance3D
        if mesh_node.mesh == null:
            continue
        var transform := instance.global_transform.affine_inverse() * mesh_node.global_transform
        var part := transform * mesh_node.get_aabb()
        if first:
            bounds = part
            first = false
        else:
            bounds = bounds.merge(part)
    if not first and bounds.size.y > 0.001:
        var factor := height / bounds.size.y
        instance.scale = Vector3.ONE * factor
        instance.position = Vector3(-bounds.get_center().x * factor, -bounds.position.y * factor, -bounds.get_center().z * factor)
    return holder

func _make_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("b9e3f1")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("dce9f4")
    e.ambient_light_energy = 0.45
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-32,0)
    sun.light_energy = 0.72
    sun.shadow_enabled = true
    add_child(sun)
    _cube(self,"Ilha principal",Vector3(64,1.5,64),Vector3(0,-0.85,0),Color("86bca0"))
    _cube(self,"Base da ilha",Vector3(59,2,59),Vector3(0,-2.5,0),Color("8278a9"))
    _cube(self,"Avenida central",Vector3(59,0.07,3.2),Vector3(0,0,0),Color("c9c7bb"))
    _cube(self,"Caminho central",Vector3(3.2,0.08,59),Vector3(0,0,0),Color("c9c7bb"))
    var building_models := [
        "Eco_Building_Grid.glb", "Eco_Building_Slope.glb", "Eco_Building_Terrace.glb",
        "Regular_Building_TwistedTower_Large.glb"
    ]
    for idx in range(PLACES.size()):
        var place: Dictionary = PLACES[idx]
        var p: Vector3 = place["pos"]
        var c: Color = place["color"]
        _cube(self, str(place["name"]) + " praça", Vector3(10,0.20,10), p + Vector3(0,0.05,0), c.darkened(0.29))
        var file: String = "res://assets/city/" + building_models[idx % building_models.size()]
        _model(self, file, str(place["name"]) + " edifício", p + Vector3(0,0.17,-0.8), 4.4, PI)
        var sign := Label3D.new()
        sign.text = str(place["name"])
        sign.font_size = 80
        sign.pixel_size = 0.008
        sign.position = p + Vector3(0,4.9,0)
        sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        sign.modulate = Color("243b61")
        add_child(sign)
    for i in range(38):
        var angle := float(i) * 2.399963
        var radius := 25.0 + float(i % 6)
        var point := Vector3(cos(angle)*radius, 0.03, sin(angle)*radius)
        var tree := "Palm_03.glb" if i % 3 == 0 else "Bush_06.glb"
        _model(self, "res://assets/city/" + tree, "Vegetação %02d" % i, point, 3.5 if i % 3 == 0 else 1.4, angle)
    for i in range(7):
        var angle := float(i) * TAU / 7.0
        var point := Vector3(cos(angle)*12.0, 0.05, sin(angle)*12.0)
        _model(self, "res://assets/city/Bush_07.glb", "Jardim %02d" % i, point, 1.0, angle)
    _model(self, "res://assets/city/Fountain_03.glb", "Fonte central", Vector3(6,0.05,6), 2.2)

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Pietro"
    add_child(player)
    player.position = Vector3(0,0.1,0)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 2.3
    collision.shape = capsule
    collision.position.y = 1.1
    player.add_child(collision)
    pietro_visual = _model(player, "res://assets/characters/pietro/base_basic_shaded.glb", "PietroModelo", Vector3.ZERO, 2.05, PI)
    if pietro_visual != null:
        pietro_rest_y = pietro_visual.position.y
        pietro_rest_rotation = pietro_visual.rotation.z
    thor = Node3D.new()
    thor.name = "Thor"
    add_child(thor)
    thor.position = Vector3(1.8,0,1.5)
    # Dog_01 é provisório: não há confirmação de que seja bulldog francês.
    thor_visual = _model(thor, "res://assets/animals/Dog_01.glb", "ThorModeloProvisorio", Vector3.ZERO, 0.85, PI)
    if thor_visual != null:
        thor_rest_y = thor_visual.position.y
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraOrbit"
    add_child(camera_pivot)
    camera_arm = SpringArm3D.new()
    camera_arm.name = "CameraCollisionArm"
    camera_arm.spring_length = camera_distance
    camera_arm.margin = 0.15
    camera_pivot.add_child(camera_arm)
    camera = Camera3D.new()
    camera.name = "Camera3D"
    camera.fov = 66.0
    camera.near = 0.12
    camera.current = true
    camera_arm.add_child(camera)
    camera_pivot.position = player.position + Vector3.UP * CAMERA_LOOK_HEIGHT
    camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)
    camera_arm.add_excluded_object(player.get_rid())
    footsteps = AudioStreamPlayer.new()
    footsteps.name = "Footsteps"
    footsteps.volume_db = -15.0
    add_child(footsteps)

func _make_ui() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    root_ui = Control.new()
    root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(root_ui)
    var top := PanelContainer.new()
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    root_ui.add_child(top)
    var bar := HBoxContainer.new()
    top.add_child(bar)
    var title := Label.new()
    title.text = "🌈 PSBilingue 3D • Mundo do Pietro"
    title.add_theme_font_size_override("font_size",25)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.add_child(title)
    var stars := Label.new()
    stars.name = "Stars"
    stars.text = "⭐ %d" % int(PSProgress.load_data().get("stars",0))
    stars.add_theme_font_size_override("font_size",25)
    bar.add_child(stars)
    hint = Label.new()
    hint.text = "Explore com WASD/setas • ESPAÇO entra na escola"
    hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    hint.position = Vector2(-290,62)
    hint.add_theme_color_override("font_color",Color("24345c"))
    hint.add_theme_font_size_override("font_size",19)
    root_ui.add_child(hint)
    ui_camera_hint = Label.new()
    ui_camera_hint.text = "WASD: andar | Shift: correr | Q: pular | botão direito: câmera | R: centralizar"
    ui_camera_hint.add_theme_font_size_override("font_size", 14)
    ui_camera_hint.add_theme_color_override("font_color", Color("24345c"))
    ui_camera_hint.position = Vector2(18, 88)
    root_ui.add_child(ui_camera_hint)
    var collect_label := Label.new()
    collect_label.name = "Collectibles"
    collect_label.text = "✨ 0/%d estrelas do mundo" % total_collectibles
    collect_label.position = Vector2(18, 113)
    collect_label.add_theme_font_size_override("font_size", 17)
    collect_label.add_theme_color_override("font_color", Color("213c59"))
    root_ui.add_child(collect_label)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    root_ui.add_child(panel)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 112
    panel.add_child(scroll)
    var bar_games := HBoxContainer.new()
    scroll.add_child(bar_games)
    for place in PLACES:
        var button := Button.new()
        button.text = str(place["name"])
        button.custom_minimum_size = Vector2(130,85)
        button.add_theme_font_size_override("font_size",20)
        button.pressed.connect(_open_game.bind(str(place["name"])))
        bar_games.add_child(button)
    var mobile := HBoxContainer.new()
    mobile.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    mobile.position = Vector2(20,-220)
    root_ui.add_child(mobile)
    for entry in [{"label":"◀","vec":Vector2(-1,0)},{"label":"▲","vec":Vector2(0,-1)},{"label":"▼","vec":Vector2(0,1)},{"label":"▶","vec":Vector2(1,0)}]:
        var button := Button.new()
        button.text = entry["label"]
        button.custom_minimum_size = Vector2(66,62)
        button.button_down.connect(func(): touch_vector = entry["vec"])
        button.button_up.connect(func(): touch_vector = Vector2.ZERO)
        mobile.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
    if current_game != null:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            camera_dragging = event.pressed
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = maxf(3.0, camera_distance - 0.65)
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = minf(14.0, camera_distance + 0.65)
    elif event is InputEventMouseMotion and camera_dragging:
        _rotate_camera(event.screen_relative)
    elif event is InputEventScreenTouch:
        if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.43 and touch_camera_index == -1:
            touch_camera_index = event.index
            touch_camera_last = event.position
        elif not event.pressed and event.index == touch_camera_index:
            touch_camera_index = -1
    elif event is InputEventScreenDrag and event.index == touch_camera_index:
        _rotate_camera(event.position - touch_camera_last)
        touch_camera_last = event.position

func _rotate_camera(motion: Vector2) -> void:
    camera_yaw -= motion.x * 0.005
    camera_pitch = clampf(camera_pitch - motion.y * 0.004, -1.05, 0.35)

func _process(delta: float) -> void:
    world_time += delta
    if Input.is_key_pressed(KEY_R):
        camera_yaw = lerp_angle(camera_yaw, player.rotation.y + PI, minf(1.0, delta * 6.0))
        camera_pitch = lerpf(camera_pitch, -0.19, minf(1.0, delta * 6.0))
    if current_game != null:
        return
    var input_axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_vector
    if Input.is_key_pressed(KEY_A): input_axis.x -= 1.0
    if Input.is_key_pressed(KEY_D): input_axis.x += 1.0
    if Input.is_key_pressed(KEY_W): input_axis.y -= 1.0
    if Input.is_key_pressed(KEY_S): input_axis.y += 1.0
    input_axis = input_axis.limit_length(1.0)
    var camera_forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
    var camera_right := Vector3(cos(camera_yaw), 0, -sin(camera_yaw))
    var move_direction := (camera_right * input_axis.x - camera_forward * input_axis.y).normalized()
    var moving := input_axis.length() > 0.08
    var speed := running_speed if Input.is_key_pressed(KEY_SHIFT) else movement_speed
    var target_velocity := move_direction * speed if moving else Vector3.ZERO
    current_velocity = current_velocity.move_toward(target_velocity, delta * 19.0)
    # Salto simples com gravidade: evita mover o personagem apenas como uma estátua.
    if Input.is_key_pressed(KEY_Q) and player.position.y <= ground_y + 0.02 and jump_velocity <= 0.0:
        jump_velocity = jump_height
        _play_sfx(sound_enter)
    jump_velocity -= 19.6 * delta
    player.position.y = maxf(ground_y, player.position.y + jump_velocity * delta)
    if player.position.y <= ground_y:
        jump_velocity = 0.0
    player.position += current_velocity * delta
    player.position.x = clampf(player.position.x, -29, 29)
    player.position.z = clampf(player.position.z, -29, 29)
    if moving and player.position.y <= ground_y + 0.03:
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            _play_sfx(sound_step)
            footstep_timer = 0.29 if speed > movement_speed else 0.43
    else:
        footstep_timer = 0.0
    if moving:
        var target_yaw := atan2(move_direction.x, move_direction.z)
        player.rotation.y = lerp_angle(player.rotation.y, target_yaw, clampf(delta * 12.0, 0.0, 1.0))
    # O Cute Boy nao possui Skeleton3D: movimento visual leve, sem fingir animacao articulada.
    if pietro_visual != null:
        var motion_weight := clampf(current_velocity.length() / movement_speed, 0.0, 1.0)
        pietro_visual.position.y = pietro_rest_y + absf(sin(world_time * (12.0 if speed > movement_speed else 9.0))) * 0.055 * motion_weight
        pietro_visual.rotation.z = pietro_rest_rotation + sin(world_time * 8.0) * 0.018 * motion_weight
    var desired := player.position + player.global_transform.basis * Vector3(1.45, 0, 1.6)
    var gap := thor.position.distance_to(desired)
    if gap > 0.9:
        thor.position = thor.position.move_toward(desired, minf(gap - 0.7, delta * 5.4))
        var dog_dir := desired - thor.position
        if dog_dir.length_squared() > 0.01:
            thor.rotation.y = lerp_angle(thor.rotation.y, atan2(dog_dir.x, dog_dir.z), clampf(delta * 10.0, 0.0, 1.0))
    if thor_visual != null:
        thor_visual.position.y = thor_rest_y + (absf(sin(world_time * 10.0)) * 0.045 if gap > 1.2 else 0.0)
    camera_pivot.position = camera_pivot.position.lerp(player.position + Vector3.UP * CAMERA_LOOK_HEIGHT, clampf(delta * 8.0, 0.0, 1.0))
    camera_pivot.rotation.y = camera_yaw
    camera_pivot.rotation.x = camera_pitch
    camera_arm.spring_length = lerpf(camera_arm.spring_length, camera_distance, clampf(delta * 8.0, 0.0, 1.0))
    for collectible in collectibles:
        if is_instance_valid(collectible) and collectible.visible:
            collectible.rotate_y(delta * 1.9)
            var mesh := collectible.get_node_or_null("Visual") as Node3D
            if mesh != null:
                mesh.position.y = 0.12 * sin(world_time * 2.6 + collectible.position.x)
            if player.position.distance_to(collectible.position) < 1.35:
                collectible.visible = false
                collected_count += 1
                var label := root_ui.get_node_or_null("Collectibles") as Label
                if label != null:
                    label.text = "✨ %d/%d estrelas do mundo" % [collected_count, total_collectibles]
                _play_sfx(sound_reward)
    var nearest := ""
    var dist := 5.0
    for place in PLACES:
        var target: Vector3 = place["pos"]
        var d: float = player.position.distance_to(target)
        if d < dist:
            nearest = str(place["name"])
            dist = d
    if nearest != "":
        hint.text = "Perto de %s — pressione ESPAÇO para entrar" % nearest
        if Input.is_action_just_pressed("ui_accept"):
            _open_game(nearest)
    else:
        hint.text = "Explore o mundo com as setas ou escolha uma atividade abaixo"

func _open_game(name_: String) -> void:
    if current_game != null:
        return
    _play_sfx(sound_enter)
    current_game = PSGames.new()
    current_game.mode = name_
    root_ui.add_child(current_game)
    current_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    current_game.exit_game.connect(_close_game)

func _close_game() -> void:
    current_game.queue_free()
    current_game = null
    var stars := root_ui.get_node_or_null("PanelContainer/HBoxContainer/Stars") as Label
    if stars != null:
        stars.text = "⭐ %d" % int(PSProgress.load_data().get("stars",0))


func _make_audio() -> void:
    # Efeitos sintetizados localmente: não dependem de downloads nem de licenças externas.
    sound_step = _tone(140.0, 0.065, 0.07)
    sound_reward = _tone(880.0, 0.24, 0.18)
    sound_enter = _tone(440.0, 0.14, 0.12)

func _tone(frequency: float, seconds: float, volume: float) -> AudioStreamPlayer:
    var sample_rate := 22050
    var frames := int(seconds * sample_rate)
    var bytes := PackedByteArray()
    bytes.resize(frames * 2)
    for i in range(frames):
        var t := float(i) / sample_rate
        var envelope := pow(1.0 - float(i) / frames, 2.0)
        var waveform := sin(TAU * frequency * t) + 0.22 * sin(TAU * frequency * 2.0 * t)
        var amplitude := int(clampf(waveform * envelope * volume, -1.0, 1.0) * 32767.0)
        bytes.encode_s16(i * 2, amplitude)
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.data = bytes
    var player_audio := AudioStreamPlayer.new()
    player_audio.stream = stream
    add_child(player_audio)
    return player_audio

func _play_sfx(sound: AudioStreamPlayer) -> void:
    if sound != null:
        sound.play()

func _make_collectibles() -> void:
    var golden := StandardMaterial3D.new()
    golden.albedo_color = Color("ffd34d")
    golden.metallic = 0.35
    golden.roughness = 0.26
    golden.emission_enabled = true
    golden.emission = Color("c38b13")
    golden.emission_energy_multiplier = 0.28
    for i in range(total_collectibles):
        var angle := TAU * float(i) / total_collectibles + 0.22
        var radius := 10.0 + float(i % 4) * 4.0
        var collectible := Area3D.new()
        collectible.name = "EstrelaMundo_%02d" % i
        collectible.position = Vector3(cos(angle) * radius, 1.1, sin(angle) * radius)
        add_child(collectible)
        var visual := Node3D.new()
        visual.name = "Visual"
        collectible.add_child(visual)
        var mesh := MeshInstance3D.new()
        var prism := SphereMesh.new()
        prism.radius = 0.31
        prism.height = 0.62
        prism.radial_segments = 8
        prism.rings = 4
        mesh.mesh = prism
        mesh.material_override = golden
        visual.add_child(mesh)
        collectibles.append(collectible)
