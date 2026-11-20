extends Control
class_name PSGames
## Tela cheia das atividades: seleção de nível, quiz, memória, sudoku e soletração.

signal closed
signal level_won(mode: String, level: int, stars: int)

const NAVY := Color("1d2b53")
const GOOD := Color("3fbf6a")
const BAD := Color("e5534b")
const PRAISE := ["Muito bem!", "Isso aí!", "Você é demais!", "Perfeito!", "Uau, que esperto!", "Mandou bem!"]
const TRY_AGAIN := ["Quase! Vamos de novo.", "Não desanime!", "Você consegue!", "Errar faz parte de aprender!"]
const MEM_LEVELS := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 3), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 5), Vector2i(6, 6), Vector2i(8, 6), Vector2i(8, 8), Vector2i(10, 10)]

var mode := ""
var kind := ""
var color := Color("5b8cff")
var level := 1
var state := "levels"
var content: Control
var _star_label: Label
var _title: Label
var _say: Label
var _token := 0
var _locked := false

# quiz
var _questions: Array = []
var _qi := 0
var _correct := 0
var _mistakes := 0
var _opt_buttons: Array[Button] = []
# memória
var _cards: Array[Button] = []
var _pair_of: Array[int] = []
var _matched: Array[bool] = []
var _first := -1
var _moves := 0
var _pairs := 0
var _found := 0
# sudoku
var _n := 9
var _br := 3
var _bc := 3
var _solution: Array[int] = []
var _grid: Array[int] = []
var _given: Array[bool] = []
var _cells: Array[Button] = []
var _sel := -1
var _hints := 0
var _errors := 0
var _hint_btn: Button
var _style_cache: Dictionary = {}
# soletração
var _words: Array = []
var _wi := 0
var _pos := 0
var _slots: Array[Label] = []
var _tiles: Array[Button] = []

# ------------------------------------------------------------------------------------
func open(mode_name: String, place_color: Color) -> void:
	mode = mode_name
	kind = PSContent.mode_kind(mode_name)
	color = place_color
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_frame()
	PSAudio.music("music_quiz")
	PSAudio.sfx("open")
	show_levels()

func _build_frame() -> void:
	var bg := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([color.lerp(Color.WHITE, 0.78), color.lerp(Color.WHITE, 0.45)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_LINEAR
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	# cabeçalho
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var back := PSUI.button("‹  Voltar", color.darkened(0.25), Vector2(150, 56), 26)
	back.pressed.connect(_on_back)
	head.add_child(back)
	_title = PSUI.label(mode, 38, NAVY)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_title)
	var sp := PSUI.panel(Color(1, 1, 1, 0.9), 28)
	head.add_child(sp)
	var sh := HBoxContainer.new()
	sp.add_child(sh)
	sh.add_child(PSUI.Icon.new().setup("star", Color("ffc107"), 36))
	_star_label = PSUI.label(str(PSProgress.stars()), 28, NAVY)
	sh.add_child(_star_label)
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	# mascote
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 92)
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var thor := TextureRect.new()
	thor.texture = load("res://assets/ui/thor_front.png") as Texture2D
	thor.custom_minimum_size = Vector2(92, 92)
	thor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(thor)
	var bub := PSUI.panel(Color(1, 1, 1, 0.92), 20)
	bub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bub)
	_say = PSUI.label("Oi! Eu sou o Thor. Vamos brincar e aprender!", 24, NAVY)
	bub.add_child(_say)

func _vs() -> Vector2:
	return get_viewport_rect().size

func say(text: String) -> void:
	_say.text = text
	PSUI.pop(_say.get_parent() as Control, 0.85)

func _clear() -> void:
	_token += 1
	_locked = false
	for c in content.get_children():
		c.queue_free()

func _refresh_stars() -> void:
	_star_label.text = str(PSProgress.stars())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()
		return
	if state == "sudoku" and event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			var c := k.keycode
			if c >= KEY_1 and c <= KEY_9:
				_sudoku_input(c - KEY_0)
			elif c >= KEY_KP_1 and c <= KEY_KP_9:
				_sudoku_input(c - KEY_KP_0)
			elif c == KEY_BACKSPACE or c == KEY_DELETE or c == KEY_0:
				_sudoku_input(0)
			elif c == KEY_LEFT:
				_sudoku_move(-1, 0)
			elif c == KEY_RIGHT:
				_sudoku_move(1, 0)
			elif c == KEY_UP:
				_sudoku_move(0, -1)
			elif c == KEY_DOWN:
				_sudoku_move(0, 1)

func _on_back() -> void:
	PSAudio.sfx("back")
	if state == "levels":
		closed.emit()
	else:
		show_levels()

# ---- seleção de nível ------------------------------------------------------------------------------
func show_levels() -> void:
	_clear()
	state = "levels"
	_title.text = mode
	_refresh_stars()
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	content.add_child(vb)
	var tag := ""
	for p in PSConfig.PLACES:
		var pd: Dictionary = p
		if pd["name"] == mode:
			tag = str(pd["tag"])
	var t := PSUI.label("Escolha um nível", 40, NAVY)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := PSUI.label("%s   •   %d de 30 estrelas" % [tag, PSProgress.mode_stars(mode)], 24, NAVY.lightened(0.2))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	vb.add_child(cc)
	var unlocked := PSProgress.unlocked_level(mode)
	for l in range(1, 11):
		var b := Button.new()
		b.custom_minimum_size = Vector2(168, 128)
		b.focus_mode = Control.FOCUS_NONE
		var is_locked := l > unlocked
		PSUI.style_button(b, Color("9aa5c0") if is_locked else color.darkened(0.1))
		b.disabled = is_locked
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		var num := PSUI.label(("%d" % l) if not is_locked else "%d  (bloqueado)" % l, 40 if not is_locked else 22, Color.WHITE)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(num)
		var srow := HBoxContainer.new()
		srow.alignment = BoxContainer.ALIGNMENT_CENTER
		srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(srow)
		var got := PSProgress.level_stars(mode, l)
		for s in range(3):
			var ic := PSUI.Icon.new().setup("star", Color("ffd54f") if s < got else Color(1, 1, 1, 0.35), 34)
			srow.add_child(ic)
		b.pressed.connect(start_level.bind(l))
		grid.add_child(b)
	say("Escolha um nível. Cada nível tem até 3 estrelas!")

func start_level(l: int) -> void:
	level = l
	PSAudio.sfx("click")
	match kind:
		"memory":
			_start_memory()
		"sudoku":
			_start_sudoku()
		"spelling":
			_start_spelling()
		_:
			_start_quiz()

# ---- resultado --------------------------------------------------------------------------------------------
func _show_result(won: bool, stars: int, title: String, detail: String) -> void:
	_clear()
	state = "result"
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	content.add_child(vb)
	var t := PSUI.label(title, 56, NAVY)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var d := PSUI.label(detail, 30, NAVY)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(d)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	var icons: Array = []
	for s in range(3):
		var ic := PSUI.Icon.new().setup("star", Color("ffc107") if s < stars else Color("c9ced9"), 120)
		ic.modulate = Color(1, 1, 1, 0.0)
		row.add_child(ic)
		icons.append(ic)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 14)
	vb.add_child(btns)
	if won and level < 10:
		var nx := PSUI.button("Próximo nível ›", GOOD, Vector2(260, 64), 28)
		nx.pressed.connect(start_level.bind(level + 1))
		btns.add_child(nx)
	var again := PSUI.button("Jogar de novo", color.darkened(0.15), Vector2(240, 64), 28)
	again.pressed.connect(start_level.bind(level))
	btns.add_child(again)
	var lv := PSUI.button("Níveis", Color("6c7a9c"), Vector2(180, 64), 28)
	lv.pressed.connect(show_levels)
	btns.add_child(lv)
	if won:
		PSAudio.sfx("win")
		PSUI.confetti(self, Vector2(_vs().x * 0.5, _vs().y * 0.45), 120)
		say(PRAISE[randi() % PRAISE.size()] + " Você completou o nível!")
	else:
		PSAudio.sfx("fail")
		say(TRY_AGAIN[randi() % TRY_AGAIN.size()])
	var token := _token
	for i in range(icons.size()):
		await get_tree().create_timer(0.35).timeout
		if token != _token:
			return
		var ic2 := icons[i] as Control
		ic2.modulate = Color.WHITE
		PSUI.pop(ic2, 0.2)
		if i < stars:
			PSAudio.sfx("star", -2.0, 1.0 + 0.08 * float(i))

func _finish(stars: int, title: String, detail: String) -> void:
	PSProgress.complete(mode, level, stars)
	_refresh_stars()
	level_won.emit(mode, level, stars)
	_show_result(true, stars, title, detail)

# =====================================================================================================
# QUIZ
# =====================================================================================================
func _start_quiz() -> void:
	_questions = PSContent.make(mode, level, 10)
	_qi = 0
	_correct = 0
	_mistakes = 0
	state = "quiz"
	_title.text = "%s  •  Nível %d" % [mode, level]
	if _questions.is_empty():
		show_levels()
		return
	_show_question()

func _opt_style(b: Button, bg: Color, fg: Color) -> void:
	var sb := PSUI.style(bg, 18, Color("c9d3ee"), 3)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb if st != "hover" else PSUI.style(bg.lerp(Color("dce6ff"), 0.5), 18, Color("9db4ff"), 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, fg)

func _media_for(q: Dictionary, parent: Control) -> void:
	if q.has("image"):
		var tr := TextureRect.new()
		var path := "res://assets/ui/animals/%s.png" % str(q["image"])
		if ResourceLoader.exists(path):
			tr.texture = load(path) as Texture2D
		tr.custom_minimum_size = Vector2(150, 150)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parent.add_child(tr)
	if q.has("swatch"):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(190, 96)
		p.add_theme_stylebox_override("panel", PSUI.style(q["swatch"], 24, Color("8892b0"), 4))
		parent.add_child(p)
	if q.has("seq"):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		parent.add_child(row)
		for it in q["seq"]:
			if it == null:
				var qb := Panel.new()
				qb.custom_minimum_size = Vector2(64, 64)
				qb.add_theme_stylebox_override("panel", PSUI.style(Color("fff8e1"), 14, Color("f5b700"), 4, false))
				var ql := PSUI.label("?", 40, Color("f5b700"))
				ql.set_anchors_preset(Control.PRESET_FULL_RECT)
				ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ql.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				qb.add_child(ql)
				row.add_child(qb)
			else:
				var d: Dictionary = it
				row.add_child(PSUI.Icon.new().setup(d["kind"], d["color"], 64))

func _show_question() -> void:
	_clear()
	var q: Dictionary = _questions[_qi]
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 12)
	content.add_child(vb)
	var pb := ProgressBar.new()
	pb.max_value = _questions.size()
	pb.value = _qi
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 16)
	vb.add_child(pb)
	var info := PSUI.label("Pergunta %d de %d        Acertos: %d" % [_qi + 1, _questions.size(), _correct], 22, NAVY.lightened(0.2))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info)
	var card := PSUI.panel(Color(1, 1, 1, 0.96), 26)
	vb.add_child(card)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", 10)
	card.add_child(cv)
	var media := VBoxContainer.new()
	media.alignment = BoxContainer.ALIGNMENT_CENTER
	media.add_theme_constant_override("separation", 8)
	var mcenter := CenterContainer.new()
	mcenter.add_child(media)
	cv.add_child(mcenter)
	_media_for(q, media)
	var prompt := PSUI.label(str(q["prompt"]), 34, NAVY)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt.custom_minimum_size = Vector2(500, 0)
	cv.add_child(prompt)
	if q.has("speak") and PSAudio.can_speak():
		var sp := PSUI.button("Ouvir", Color("ff8a3d"), Vector2(170, 52), 24)
		sp.pressed.connect(func(): PSAudio.speak(str(q["speak"]), "en"))
		var spc := CenterContainer.new()
		spc.add_child(sp)
		cv.add_child(spc)
		if q.get("auto_speak", false):
			var tk := _token
			get_tree().create_timer(0.35).timeout.connect(_auto_speak.bind(tk, str(q["speak"])))
	var opts: Array = q["options"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vb.add_child(grid)
	_opt_buttons.clear()
	for i in range(opts.size()):
		var o: Dictionary = opts[i]
		var b := Button.new()
		b.text = str(o.get("text", ""))
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 78)
		b.add_theme_font_size_override("font_size", 30)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_opt_style(b, Color.WHITE, NAVY)
		if o.has("icon"):
			var cc := CenterContainer.new()
			cc.set_anchors_preset(Control.PRESET_FULL_RECT)
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(cc)
			cc.add_child(PSUI.Icon.new().setup(o["icon"], o["color"], 60))
		b.pressed.connect(_on_answer.bind(i))
		grid.add_child(b)
		_opt_buttons.append(b)
	PSUI.pop(card, 0.92)

func _on_answer(i: int) -> void:
	if _locked:
		return
	_locked = true
	var q: Dictionary = _questions[_qi]
	var right := int(q["answer"])
	var ok := i == right
	for b in _opt_buttons:
		b.disabled = true
	var wait := 1.0
	if ok:
		_correct += 1
		_opt_style(_opt_buttons[i], GOOD, Color.WHITE)
		PSAudio.sfx("correct")
		PSUI.pop(_opt_buttons[i], 0.9)
		var gp := _opt_buttons[i].get_global_rect().get_center()
		PSUI.confetti(self, gp - global_position, 30)
		say(PRAISE[randi() % PRAISE.size()])
		if q.has("speak") and not q.get("auto_speak", false):
			PSAudio.speak(str(q["speak"]), "en")
	else:
		_mistakes += 1
		_opt_style(_opt_buttons[i], BAD, Color.WHITE)
		_opt_style(_opt_buttons[right], GOOD, Color.WHITE)
		PSAudio.sfx("wrong")
		PSUI.shake(_opt_buttons[i])
		var ans_text := str((q["options"] as Array)[right].get("text", ""))
		say(("Quase! A resposta é: " + ans_text) if ans_text != "" else "Quase! Veja a resposta certa em verde.")
		wait = 2.2
	if q.has("note"):
		say(str(q["note"]))
		wait = maxf(wait, 1.8)
	var token := _token
	await get_tree().create_timer(wait).timeout
	if token != _token:
		return
	_qi += 1
	if _qi >= _questions.size():
		_quiz_end()
	else:
		_show_question()

func _quiz_end() -> void:
	var total := _questions.size()
	if _correct >= int(ceil(float(total) * 0.7)):
		var stars := 3 if _mistakes <= 1 else (2 if _mistakes <= 3 else 1)
		_finish(stars, "Parabéns!", "Você acertou %d de %d perguntas." % [_correct, total])
	else:
		_show_result(false, 0, "Quase lá!", "Você acertou %d de %d. Precisa de %d para passar." % [_correct, total, int(ceil(float(total) * 0.7))])

# =====================================================================================================
# MEMÓRIA
# =====================================================================================================
func _mem_faces(pairs: int) -> Array:
	var faces: Array = []
	var animals: Array = PSConfig.ANIMALS.duplicate()
	animals.shuffle()
	for a in animals:
		faces.append({"animal": a})
	var combos: Array = []
	for k in PSUI.Icon.KINDS:
		for c in PSContent.PALETTE:
			combos.append({"kind": k, "color": c})
	combos.shuffle()
	faces.append_array(combos)
	return faces.slice(0, pairs)

func _start_memory() -> void:
	_clear()
	state = "memory"
	_title.text = "Memória  •  Nível %d" % level
	var dim: Vector2i = MEM_LEVELS[level - 1]
	var cols := dim.x
	var rows := dim.y
	_pairs = cols * rows / 2
	_found = 0
	_moves = 0
	_first = -1
	var faces := _mem_faces(_pairs)
	var deck: Array = []
	for i in range(_pairs):
		deck.append(i)
		deck.append(i)
	deck.shuffle()
	var avail := Vector2(_vs().x - 60.0, _vs().y - 250.0)
	var gap := 8.0 if cols * rows > 40 else 14.0
	var cs := minf(minf((avail.x - gap * float(cols - 1)) / float(cols), (avail.y - gap * float(rows - 1)) / float(rows)), 150.0)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(cc)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", int(gap))
	grid.add_theme_constant_override("v_separation", int(gap))
	cc.add_child(grid)
	_cards.clear()
	_pair_of.clear()
	_matched.clear()
	for i in range(deck.size()):
		var pid: int = deck[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(cs, cs)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", int(cs * 0.5))
		b.text = "?"
		_card_style(b, false, false)
		var f: Dictionary = faces[pid]
		var face: Control
		if f.has("animal"):
			var tr := TextureRect.new()
			tr.texture = load("res://assets/ui/animals/%s.png" % str(f["animal"])) as Texture2D
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face = tr
		else:
			face = PSUI.Icon.new().setup(f["kind"], f["color"], cs)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.visible = false
		b.add_child(face)
		b.set_meta("face", face)
		b.set_meta("animal", str(f.get("animal", "")))
		b.pressed.connect(_on_card.bind(i))
		grid.add_child(b)
		_cards.append(b)
		_pair_of.append(pid)
		_matched.append(false)
	say("Vire duas cartas e encontre os pares iguais!")

func _card_style(b: Button, up: bool, done: bool) -> void:
	var bg := Color.WHITE if up else color.darkened(0.1)
	var bd := GOOD if done else (Color("c9d3ee") if up else color.lightened(0.3))
	var sb := PSUI.style(bg, 16, bd, 5 if done else 3)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)

func _auto_speak(tk: int, text: String) -> void:
	if tk == _token:
		PSAudio.speak(text, "en")

func _set_face(b: Button, up: bool, done: bool) -> void:
	if not is_instance_valid(b):
		return
	b.text = "" if up else "?"
	(b.get_meta("face") as Control).visible = up
	_card_style(b, up, done)

func _flip(b: Button, up: bool, done: bool = false) -> void:
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale:x", 0.0, 0.09)
	tw.tween_callback(_set_face.bind(b, up, done))
	tw.tween_property(b, "scale:x", 1.0, 0.09)

func _on_card(i: int) -> void:
	if _locked or _matched[i] or i == _first:
		return
	PSAudio.sfx("flip")
	_flip(_cards[i], true)
	if _first == -1:
		_first = i
		return
	_moves += 1
	var a := _first
	_first = -1
	_locked = true
	var token := _token
	await get_tree().create_timer(0.55).timeout
	if token != _token:
		return
	if _pair_of[a] == _pair_of[i]:
		_matched[a] = true
		_matched[i] = true
		_found += 1
		_flip(_cards[a], true, true)
		_flip(_cards[i], true, true)
		PSAudio.sfx("match")
		var an := str(_cards[i].get_meta("animal"))
		if an != "":
			PSAudio.speak(str(PSConfig.ANIMAL_EN[an]), "en")
			say("%s = %s" % [PSConfig.ANIMAL_EN[an], PSConfig.ANIMAL_PT[an]])
		else:
			say(PRAISE[randi() % PRAISE.size()])
		_locked = false
		if _found >= _pairs:
			await get_tree().create_timer(0.8).timeout
			if token != _token:
				return
			var stars := 3 if _moves <= int(float(_pairs) * 1.7) + 1 else (2 if _moves <= int(float(_pairs) * 2.6) + 2 else 1)
			_finish(stars, "Você achou todos os pares!", "Jogadas: %d   (pares: %d)" % [_moves, _pairs])
	else:
		PSAudio.sfx("mismatch")
		await get_tree().create_timer(0.45).timeout
		if token != _token:
			return
		_flip(_cards[a], false)
		_flip(_cards[i], false)
		await get_tree().create_timer(0.25).timeout
		if token != _token:
			return
		_locked = false

# =====================================================================================================
# SUDOKU
# =====================================================================================================
func _cand_mask(g: Array, i: int) -> int:
	var r := i / _n
	var c := i % _n
	var used := 0
	for k in range(_n):
		used |= 1 << g[r * _n + k]
		used |= 1 << g[k * _n + c]
	var r0 := (r / _br) * _br
	var c0 := (c / _bc) * _bc
	for rr in range(_br):
		for cc in range(_bc):
			used |= 1 << g[(r0 + rr) * _n + c0 + cc]
	return used

func _count_solutions(g: Array, limit: int) -> int:
	var best := -1
	var best_cnt := 99
	var best_used := 0
	for i in range(g.size()):
		if g[i] == 0:
			var used := _cand_mask(g, i)
			var cnt := 0
			for d in range(1, _n + 1):
				if (used & (1 << d)) == 0:
					cnt += 1
			if cnt == 0:
				return 0
			if cnt < best_cnt:
				best_cnt = cnt
				best = i
				best_used = used
				if cnt == 1:
					break
	if best == -1:
		return 1
	var total := 0
	for d in range(1, _n + 1):
		if (best_used & (1 << d)) == 0:
			g[best] = d
			total += _count_solutions(g, limit)
			g[best] = 0
			if total >= limit:
				return total
	return total

func _gen_solution() -> Array[int]:
	var sol: Array[int] = []
	sol.resize(_n * _n)
	var digits: Array = range(1, _n + 1)
	digits.shuffle()
	var bands := _n / _br
	var stacks := _n / _bc
	var band_order: Array = range(bands)
	band_order.shuffle()
	var rows: Array = []
	for b in band_order:
		var within: Array = range(_br)
		within.shuffle()
		for w in within:
			rows.append(int(b) * _br + int(w))
	var stack_order: Array = range(stacks)
	stack_order.shuffle()
	var cols: Array = []
	for s in stack_order:
		var within2: Array = range(_bc)
		within2.shuffle()
		for w2 in within2:
			cols.append(int(s) * _bc + int(w2))
	for r in range(_n):
		for c in range(_n):
			var pat := (_bc * (int(rows[r]) % _br) + int(rows[r]) / _br + int(cols[c])) % _n
			sol[r * _n + c] = int(digits[pat])
	return sol

func _start_sudoku() -> void:
	_clear()
	state = "sudoku"
	_title.text = "Sudoku  •  Nível %d" % level
	if level <= 3:
		_n = 4
		_br = 2
		_bc = 2
	elif level <= 6:
		_n = 6
		_br = 2
		_bc = 3
	else:
		_n = 9
		_br = 3
		_bc = 3
	var targets := [11, 9, 7, 24, 20, 17, 42, 38, 34, 30]
	var target: int = targets[level - 1]
	var wait := PSUI.label("Preparando o tabuleiro…", 34, NAVY)
	wait.set_anchors_preset(Control.PRESET_CENTER)
	content.add_child(wait)
	await get_tree().process_frame
	_solution = _gen_solution()
	var puzzle: Array = _solution.duplicate()
	var order: Array = range(_n * _n)
	order.shuffle()
	var clues := _n * _n
	var t0 := Time.get_ticks_msec()
	var steps := 0
	for idx in order:
		if clues <= target or Time.get_ticks_msec() - t0 > 1800:
			break
		var i: int = idx
		var keep: int = puzzle[i]
		puzzle[i] = 0
		if _count_solutions(puzzle.duplicate(), 2) != 1:
			puzzle[i] = keep
		else:
			clues -= 1
		steps += 1
		if steps % 6 == 0:
			await get_tree().process_frame
			if state != "sudoku":
				return
	_grid.clear()
	_given.clear()
	for v in puzzle:
		_grid.append(int(v))
		_given.append(int(v) != 0)
	_hints = 0
	_errors = 0
	_sel = -1
	_build_sudoku_ui()

func _scell(kind_: String) -> StyleBoxFlat:
	if _style_cache.has(kind_):
		return _style_cache[kind_]
	var bg := Color.WHITE
	var bd := Color("b8c2dd")
	match kind_:
		"given":
			bg = Color("e4e9f7")
		"given_peer":
			bg = Color("d3dcf5")
		"peer":
			bg = Color("eaf2ff")
		"sel":
			bg = Color("ffe082")
			bd = Color("f5a000")
		"bad":
			bg = Color("ffd1cf")
			bd = Color("e5534b")
		"same":
			bg = Color("c9f1d4")
	var sb := PSUI.style(bg, 8, bd, 2, false)
	_style_cache[kind_] = sb
	return sb

func _build_sudoku_ui() -> void:
	_clear()
	state = "sudoku"
	_style_cache.clear()
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 30)
	content.add_child(hb)
	var avail := minf(_vs().y - 260.0, _vs().x * 0.55)
	var cs := minf(avail / float(_n), 74.0)
	var boxes := GridContainer.new()
	boxes.columns = _n / _bc
	boxes.add_theme_constant_override("h_separation", 7)
	boxes.add_theme_constant_override("v_separation", 7)
	var frame := PSUI.panel(Color("5a6b99"), 14)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.add_child(boxes)
	hb.add_child(frame)
	_cells.clear()
	_cells.resize(_n * _n)
	for brow in range(_n / _br):
		for bcol in range(_n / _bc):
			var box := GridContainer.new()
			box.columns = _bc
			box.add_theme_constant_override("h_separation", 2)
			box.add_theme_constant_override("v_separation", 2)
			boxes.add_child(box)
			for rr in range(_br):
				for cc in range(_bc):
					var r := brow * _br + rr
					var c := bcol * _bc + cc
					var b := Button.new()
					b.custom_minimum_size = Vector2(cs, cs)
					b.focus_mode = Control.FOCUS_NONE
					b.add_theme_font_size_override("font_size", int(cs * 0.55))
					b.pressed.connect(_sudoku_select.bind(r * _n + c))
					box.add_child(b)
					_cells[r * _n + c] = b
	# painel lateral
	var side := VBoxContainer.new()
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 12)
	hb.add_child(side)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 8)
	pad.add_theme_constant_override("v_separation", 8)
	side.add_child(pad)
	for d in range(1, _n + 1):
		var nb := PSUI.button(str(d), color.darkened(0.1), Vector2(78, 70), 34)
		nb.pressed.connect(_sudoku_input.bind(d))
		pad.add_child(nb)
	var er := PSUI.button("Apagar", Color("6c7a9c"), Vector2(0, 58), 26)
	er.pressed.connect(_sudoku_input.bind(0))
	side.add_child(er)
	_hint_btn = PSUI.button("Dica (3)", Color("ff8a3d"), Vector2(0, 58), 26)
	_hint_btn.pressed.connect(_sudoku_hint)
	side.add_child(_hint_btn)
	_sudoku_refresh()
	say("Cada linha, coluna e quadradinho tem os números sem repetir. Toque numa casa e escolha um número.")

func _peers(a: int, b: int) -> bool:
	var ra := a / _n
	var ca := a % _n
	var rb := b / _n
	var cb := b % _n
	return ra == rb or ca == cb or ((ra / _br) == (rb / _br) and (ca / _bc) == (cb / _bc))

func _is_conflict(i: int) -> bool:
	var v: int = _grid[i]
	if v == 0:
		return false
	for j in range(_n * _n):
		if j != i and _grid[j] == v and _peers(i, j):
			return true
	return false

func _sudoku_refresh() -> void:
	var selv := 0
	if _sel >= 0:
		selv = _grid[_sel]
	for i in range(_n * _n):
		var b := _cells[i]
		var v: int = _grid[i]
		b.text = str(v) if v != 0 else ""
		var kind_ := "given" if _given[i] else "empty"
		var peer := _sel >= 0 and _peers(_sel, i)
		if _is_conflict(i):
			kind_ = "bad"
		elif i == _sel:
			kind_ = "sel"
		elif selv != 0 and v == selv:
			kind_ = "same"
		elif peer:
			kind_ = "given_peer" if _given[i] else "peer"
		var sb: StyleBoxFlat = _scell(kind_) if kind_ != "empty" else _scell("empty")
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		var fg := Color("1d2b53") if _given[i] else Color("2f6bff")
		if kind_ == "bad":
			fg = BAD
		for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(cn, fg)
	var left := 3 - _hints
	_hint_btn.text = "Dica (%d)" % left
	_hint_btn.disabled = left <= 0

func _sudoku_select(i: int) -> void:
	_sel = i
	PSAudio.sfx("tick", -6.0)
	_sudoku_refresh()

func _sudoku_move(dx: int, dy: int) -> void:
	if _sel < 0:
		_sel = 0
	else:
		var r := clampi(_sel / _n + dy, 0, _n - 1)
		var c := clampi(_sel % _n + dx, 0, _n - 1)
		_sel = r * _n + c
	_sudoku_refresh()

func _sudoku_input(v: int) -> void:
	if state != "sudoku" or _sel < 0 or _given[_sel] or v > _n:
		return
	if v == 0:
		if _grid[_sel] != 0:
			PSAudio.sfx("erase", -4.0)
		_grid[_sel] = 0
		_sudoku_refresh()
		return
	_grid[_sel] = v
	if _is_conflict(_sel):
		_errors += 1
		PSAudio.sfx("error", -4.0)
		say("Opa! Esse número já aparece na linha, coluna ou quadradinho.")
	else:
		PSAudio.sfx("tick")
	_sudoku_refresh()
	_sudoku_check_win()

func _sudoku_hint() -> void:
	if _hints >= 3:
		return
	var target := _sel
	if target < 0 or _given[target] or _grid[target] == _solution[target]:
		var empties: Array = []
		for i in range(_n * _n):
			if _grid[i] != _solution[i]:
				empties.append(i)
		if empties.is_empty():
			return
		target = empties[randi() % empties.size()]
	_sel = target
	_grid[target] = _solution[target]
	_given[target] = true
	_hints += 1
	PSAudio.sfx("hint")
	say("Coloquei um número para ajudar. Você consegue o resto!")
	_sudoku_refresh()
	_sudoku_check_win()

func _sudoku_check_win() -> void:
	for i in range(_n * _n):
		if _grid[i] == 0 or _is_conflict(i):
			return
	state = "sudoku_done"
	var stars := 3 if (_hints == 0 and _errors <= 2) else (2 if (_hints <= 1 and _errors <= 5) else 1)
	var token := _token
	await get_tree().create_timer(0.7).timeout
	if token != _token:
		return
	_finish(stars, "Sudoku resolvido!", "Dicas usadas: %d   •   Erros: %d" % [_hints, _errors])

# =====================================================================================================
# SOLETRAÇÃO
# =====================================================================================================
func _start_spelling() -> void:
	_words = PSContent.spelling_words(level, 10)
	_wi = 0
	_mistakes = 0
	state = "spelling"
	_title.text = "Soletração  •  Nível %d" % level
	if _words.is_empty():
		show_levels()
		return
	_show_word()

func _show_word() -> void:
	_clear()
	state = "spelling"
	_pos = 0
	var w: Dictionary = _words[_wi]
	var word := str(w["word"])
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	content.add_child(vb)
	var pb := ProgressBar.new()
	pb.max_value = _words.size()
	pb.value = _wi
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 16)
	vb.add_child(pb)
	var card := PSUI.panel(Color(1, 1, 1, 0.96), 26)
	vb.add_child(card)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)
	var media := CenterContainer.new()
	cv.add_child(media)
	var mv := VBoxContainer.new()
	mv.alignment = BoxContainer.ALIGNMENT_CENTER
	media.add_child(mv)
	if str(w["image"]) != "":
		var tr := TextureRect.new()
		tr.texture = load("res://assets/ui/animals/%s.png" % str(w["image"])) as Texture2D
		tr.custom_minimum_size = Vector2(150, 150)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mv.add_child(tr)
	var meaning := PSUI.label("Em português: %s" % str(w["pt"]), 36, NAVY)
	meaning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(meaning)
	var hint := PSUI.label("Monte a palavra em inglês!", 24, NAVY.lightened(0.25))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(hint)
	if PSAudio.can_speak():
		var sp := PSUI.button("Ouvir", Color("ff8a3d"), Vector2(170, 52), 24)
		sp.pressed.connect(func(): PSAudio.speak(word, "en"))
		var spc := CenterContainer.new()
		spc.add_child(sp)
		cv.add_child(spc)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 8)
	vb.add_child(slots)
	_slots.clear()
	var ssize := minf(72.0, (_vs().x - 120.0) / float(word.length()) - 8.0)
	for i in range(word.length()):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(ssize, ssize + 10.0)
		p.add_theme_stylebox_override("panel", PSUI.style(Color("ffffff"), 14, Color("8892b0"), 4, false))
		var l := PSUI.label("", int(ssize * 0.6), color.darkened(0.3))
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		slots.add_child(p)
		_slots.append(l)
	var tiles := HFlowContainer.new()
	tiles.alignment = FlowContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("h_separation", 10)
	tiles.add_theme_constant_override("v_separation", 10)
	vb.add_child(tiles)
	_tiles.clear()
	var letters: Array = w["letters"]
	for i in range(letters.size()):
		var tb := PSUI.button(str(letters[i]).to_upper(), color.darkened(0.1), Vector2(78, 78), 40)
		tb.pressed.connect(_on_tile.bind(i))
		tiles.add_child(tb)
		_tiles.append(tb)
	say("Toque nas letras na ordem certa.")
	if PSAudio.can_speak():
		PSAudio.speak(word, "en")

func _on_tile(i: int) -> void:
	if _locked:
		return
	var w: Dictionary = _words[_wi]
	var word := str(w["word"])
	var letter := str((w["letters"] as Array)[i])
	if letter == word[_pos]:
		_slots[_pos].text = letter.to_upper()
		PSUI.pop(_slots[_pos], 0.4)
		_tiles[i].disabled = true
		_tiles[i].modulate = Color(1, 1, 1, 0.35)
		_pos += 1
		PSAudio.sfx("tick")
		if _pos >= word.length():
			_locked = true
			PSAudio.sfx("correct")
			PSAudio.speak(word, "en")
			say("%s  =  %s" % [word, w["pt"]])
			PSUI.confetti(self, Vector2(_vs().x * 0.5, _vs().y * 0.4), 40)
			var token := _token
			await get_tree().create_timer(1.6).timeout
			if token != _token:
				return
			_wi += 1
			if _wi >= _words.size():
				var stars := 3 if _mistakes <= 2 else (2 if _mistakes <= 6 else 1)
				_finish(stars, "Soletrou tudo!", "Letras erradas: %d" % _mistakes)
			else:
				_show_word()
	else:
		_mistakes += 1
		PSAudio.sfx("wrong", -4.0)
		PSUI.shake(_tiles[i])
		say("Essa não é a próxima letra. Tente outra!")
