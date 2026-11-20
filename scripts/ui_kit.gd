extends RefCounted
class_name PSUI
## Utilitários de interface: tema, botões, animações e controles próprios (ícones, joystick, minimapa).

static func style(color: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), border_w: int = 0, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(10)
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	if shadow:
		sb.shadow_size = 5
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_offset = Vector2(0, 3)
	return sb

static func make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", style(Color("5b8cff")))
	t.set_stylebox("hover", "Button", style(Color("7aa2ff")))
	t.set_stylebox("pressed", "Button", style(Color("3f6fe0")))
	t.set_stylebox("disabled", "Button", style(Color("9aa5c0")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.7))
	t.set_font_size("font_size", "Button", 26)
	t.set_font_size("font_size", "Label", 24)
	t.set_color("font_color", "Label", Color("1d2b53"))
	t.set_stylebox("panel", "PanelContainer", style(Color(1, 1, 1, 0.95), 22))
	return t

static func button(text: String, color: Color, min_size: Vector2 = Vector2(0, 56), font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	style_button(b, color)
	return b

static func style_button(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", style(color))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", style(color.darkened(0.3).lerp(Color.GRAY, 0.5)))

static func label(text: String, size: int = 24, color: Color = Color("1d2b53")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func panel(color: Color = Color(1, 1, 1, 0.95), radius: int = 22) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color, radius))
	return p

static func pop(node: Control, from: float = 0.6) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(from, from)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func shake(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.tween_property(node, "rotation", 0.07, 0.05)
	tw.tween_property(node, "rotation", -0.07, 0.08)
	tw.tween_property(node, "rotation", 0.04, 0.06)
	tw.tween_property(node, "rotation", 0.0, 0.05)

static func flash(node: CanvasItem, color: Color) -> void:
	node.modulate = color
	node.create_tween().tween_property(node, "modulate", Color.WHITE, 0.45)

static func confetti(parent: Node, pos: Vector2, amount: int = 80) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.9
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.gravity = Vector2(0, 750)
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 560.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	g.colors = PackedColorArray([Color("ff5a5f"), Color("ffc107"), Color("3ddc97"), Color("4f9dff"), Color("c06bff")])
	p.color_initial_ramp = g
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# =============================================================================
class Icon extends Control:
	## Ícone vetorial desenhado em código (não depende de fontes/emoji).
	var kind := "star"
	var color := Color("ffc107")

	func setup(k: String, c: Color, s: float = 64.0) -> Icon:
		kind = k
		color = c
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()
		return self

	func _reg(n: int, r: float, rot: float, c: Vector2) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n):
			var a := rot + TAU * float(i) / float(n)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		return pts

	func _circle_poly(c: Vector2, r: float) -> PackedVector2Array:
		return _reg(40, r, 0.0, c)

	func _fill(pts: PackedVector2Array, col: Color) -> void:
		draw_colored_polygon(pts, col)
		var line := pts.duplicate()
		line.append(pts[0])
		draw_polyline(line, col.darkened(0.35), 3.0, true)

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size / 2.0
		var r := s * 0.42
		var dark := color.darkened(0.35)
		match kind:
			"circle":
				draw_circle(c, r, color)
				draw_arc(c, r, 0, TAU, 40, dark, 3.0, true)
			"square":
				_fill(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r)]), color)
			"triangle":
				_fill(_reg(3, r * 1.1, -PI / 2.0, c + Vector2(0, r * 0.1)), color)
			"diamond":
				_fill(PackedVector2Array([c + Vector2(0, -r * 1.1), c + Vector2(r * 0.8, 0), c + Vector2(0, r * 1.1), c + Vector2(-r * 0.8, 0)]), color)
			"hex":
				_fill(_reg(6, r, 0.0, c), color)
			"star":
				var pts := PackedVector2Array()
				for i in range(10):
					var rr := r * 1.12 if i % 2 == 0 else r * 0.48
					var a := -PI / 2.0 + TAU * float(i) / 10.0
					pts.append(c + Vector2(cos(a), sin(a)) * rr + Vector2(0, r * 0.06))
				_fill(pts, color)
			"heart":
				var pts2 := PackedVector2Array()
				for i in range(48):
					var t := TAU * float(i) / 48.0
					var x := 16.0 * pow(sin(t), 3.0)
					var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
					pts2.append(c + Vector2(x, y) * (r * 1.05 / 16.0) + Vector2(0, r * 0.05))
				_fill(pts2, color)
			"moon":
				var outer := _circle_poly(c, r)
				var inner := _circle_poly(c + Vector2(r * 0.45, -r * 0.12), r * 0.82)
				var res := Geometry2D.clip_polygons(outer, inner)
				for poly in res:
					_fill(poly, color)
			"flower":
				for i in range(5):
					var a2 := TAU * float(i) / 5.0 - PI / 2.0
					var pc := c + Vector2(cos(a2), sin(a2)) * r * 0.55
					draw_circle(pc, r * 0.42, color)
					draw_arc(pc, r * 0.42, 0, TAU, 24, dark, 2.0, true)
				draw_circle(c, r * 0.3, Color("ffd54f"))
			"sun":
				for i in range(8):
					var a3 := TAU * float(i) / 8.0
					var d := Vector2(cos(a3), sin(a3))
					var n := Vector2(-d.y, d.x)
					draw_colored_polygon(PackedVector2Array([c + d * r * 1.1, c + d * r * 0.7 + n * r * 0.16, c + d * r * 0.7 - n * r * 0.16]), color)
				draw_circle(c, r * 0.62, color)
				draw_arc(c, r * 0.62, 0, TAU, 32, dark, 3.0, true)
			"cross":
				var k := r * 0.36
				_fill(PackedVector2Array([c + Vector2(-k, -r), c + Vector2(k, -r), c + Vector2(k, -k), c + Vector2(r, -k), c + Vector2(r, k), c + Vector2(k, k), c + Vector2(k, r), c + Vector2(-k, r), c + Vector2(-k, k), c + Vector2(-r, k), c + Vector2(-r, -k), c + Vector2(-k, -k)]), color)
			"drop":
				draw_circle(c + Vector2(0, r * 0.3), r * 0.72, color)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 1.05), c + Vector2(r * 0.66, r * 0.15), c + Vector2(-r * 0.66, r * 0.15)]), color)
			_:
				draw_circle(c, r, color)

	const KINDS := ["circle", "square", "triangle", "star", "heart", "diamond", "moon", "flower", "sun", "hex", "cross", "drop"]

# =============================================================================
class Joystick extends Control:
	var value := Vector2.ZERO
	var _touch := -999
	var _knob := Vector2.ZERO

	func _init() -> void:
		custom_minimum_size = Vector2(230, 230)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			var t := e as InputEventScreenTouch
			if t.pressed and _touch == -999:
				_touch = t.index
				_update(t.position)
			elif not t.pressed and t.index == _touch:
				_release()
		elif e is InputEventScreenDrag:
			var d := e as InputEventScreenDrag
			if d.index == _touch:
				_update(d.position)
		elif e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.device == InputEvent.DEVICE_ID_EMULATION or mb.button_index != MOUSE_BUTTON_LEFT:
				return
			if mb.pressed:
				_touch = -1
				_update(mb.position)
			elif _touch == -1:
				_release()
		elif e is InputEventMouseMotion:
			var mm := e as InputEventMouseMotion
			if _touch == -1 and mm.device != InputEvent.DEVICE_ID_EMULATION:
				_update(mm.position)

	func _update(p: Vector2) -> void:
		var v := p - size / 2.0
		var radius := size.x * 0.36
		if v.length() > radius:
			v = v.normalized() * radius
		_knob = v
		value = v / radius
		queue_redraw()

	func _release() -> void:
		_touch = -999
		value = Vector2.ZERO
		_knob = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, size.x * 0.46, Color(1, 1, 1, 0.16))
		draw_arc(c, size.x * 0.46, 0, TAU, 48, Color(1, 1, 1, 0.55), 4.0, true)
		draw_circle(c + _knob, size.x * 0.2, Color(1, 1, 1, 0.55))
		draw_arc(c + _knob, size.x * 0.2, 0, TAU, 32, Color(1, 1, 1, 0.9), 3.0, true)

# =============================================================================
class HoldButton extends Control:
	signal pressed_down
	signal released
	var text := ""
	var color := Color("ffffff")
	var held := false
	var font_size := 24
	var _touch := -999

	func setup(t: String, c: Color, s: float = 110.0, fs: int = 24) -> HoldButton:
		text = t
		color = c
		font_size = fs
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_STOP
		return self

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			var t := e as InputEventScreenTouch
			if t.pressed and _touch == -999:
				_touch = t.index
				_set_held(true)
			elif not t.pressed and t.index == _touch:
				_touch = -999
				_set_held(false)
		elif e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.device == InputEvent.DEVICE_ID_EMULATION or mb.button_index != MOUSE_BUTTON_LEFT:
				return
			if mb.pressed:
				_touch = -1
				_set_held(true)
			elif _touch == -1:
				_touch = -999
				_set_held(false)

	func _set_held(v: bool) -> void:
		if held == v:
			return
		held = v
		queue_redraw()
		if v:
			pressed_down.emit()
		else:
			released.emit()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.46
		draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.25))
		draw_circle(c, r, color.darkened(0.25) if held else color)
		draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.9), 4.0, true)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(0, c.y + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)

# =============================================================================
class MiniMap extends Control:
	var player := Vector3.ZERO
	var yaw := 0.0
	var dog := Vector3.ZERO
	var star_points: Array = []

	func _init() -> void:
		custom_minimum_size = Vector2(190, 190)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _w2m(p: Vector3, c: Vector2, k: float) -> Vector2:
		return c + Vector2(p.x, p.z) * k

	func _draw() -> void:
		var R := size.x * 0.5
		var c := Vector2(R, R)
		var k := R / 50.0
		draw_circle(c, R, Color(0.18, 0.5, 0.78, 0.92))
		draw_circle(c, R * 0.96, Color(0.42, 0.74, 0.38, 0.96))
		draw_arc(c, 25.5 * k, 0, TAU, 72, Color(0.45, 0.47, 0.52), 5.0 * k)
		draw_circle(c, PSConfig.PARK_R * k, Color(0.55, 0.82, 0.45, 0.9))
		draw_circle(c, 5.0 * k, Color(0.85, 0.85, 0.8))
		for i in range(PSConfig.PLACES.size()):
			var pl: Dictionary = PSConfig.PLACES[i]
			var pc := _w2m(PSConfig.place_pos(i, 37.0), c, k)
			var col: Color = pl["color"]
			draw_circle(pc, 7.0, Color.WHITE)
			draw_circle(pc, 5.5, col)
		for sp in star_points:
			var v3: Vector3 = sp
			draw_circle(_w2m(v3, c, k), 2.6, Color("ffd400"))
		draw_circle(_w2m(dog, c, k), 4.0, Color("c98d4c"))
		var pp := _w2m(player, c, k)
		var f := Vector2(sin(yaw), cos(yaw))
		var n := Vector2(-f.y, f.x)
		draw_colored_polygon(PackedVector2Array([pp + f * 11.0, pp - f * 6.0 + n * 7.0, pp - f * 6.0 - n * 7.0]), Color("e53935"))
		draw_arc(c, R - 1.5, 0, TAU, 64, Color.WHITE, 3.0, true)
