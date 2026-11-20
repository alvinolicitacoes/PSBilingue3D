extends Node3D
class_name PSNpc
## Criança da cidade: anda pela calçada, senta no banco ou fica acenando. Ao conversar, fala uma frase em inglês.

const PHRASES := [
	{"en": "Hello! How are you?", "pt": "Olá! Como você está?"},
	{"en": "Good morning!", "pt": "Bom dia!"},
	{"en": "Good afternoon!", "pt": "Boa tarde!"},
	{"en": "Good night!", "pt": "Boa noite!"},
	{"en": "What is your name?", "pt": "Qual é o seu nome?"},
	{"en": "Nice to meet you!", "pt": "Prazer em conhecer você!"},
	{"en": "I like to play.", "pt": "Eu gosto de brincar."},
	{"en": "Thank you very much!", "pt": "Muito obrigado!"},
	{"en": "You are welcome.", "pt": "De nada."},
	{"en": "Please, help me.", "pt": "Por favor, me ajude."},
	{"en": "Can I have some water?", "pt": "Posso tomar água?"},
	{"en": "I am happy today.", "pt": "Eu estou feliz hoje."},
	{"en": "Let's play together!", "pt": "Vamos brincar juntos!"},
	{"en": "See you tomorrow!", "pt": "Até amanhã!"},
	{"en": "I love my dog.", "pt": "Eu amo meu cachorro."},
	{"en": "What time is it?", "pt": "Que horas são?"},
	{"en": "How old are you?", "pt": "Quantos anos você tem?"},
	{"en": "Where is the park?", "pt": "Onde fica o parque?"},
	{"en": "This is my friend.", "pt": "Este é meu amigo."},
	{"en": "I like ice cream.", "pt": "Eu gosto de sorvete."},
	{"en": "Do you like animals?", "pt": "Você gosta de animais?"},
	{"en": "Let's read a book.", "pt": "Vamos ler um livro."},
	{"en": "Have a nice day!", "pt": "Tenha um bom dia!"},
	{"en": "I am hungry.", "pt": "Estou com fome."},
	{"en": "I am thirsty.", "pt": "Estou com sede."},
	{"en": "Excuse me.", "pt": "Com licença."},
	{"en": "I am sorry.", "pt": "Desculpe."},
	{"en": "Look at the stars!", "pt": "Olhe as estrelas!"},
	{"en": "Come here, please.", "pt": "Venha aqui, por favor."},
	{"en": "I can run fast!", "pt": "Eu consigo correr rápido!"},
	{"en": "What color is it?", "pt": "De que cor é?"},
	{"en": "It is a beautiful day.", "pt": "É um dia lindo."},
	{"en": "Good job!", "pt": "Muito bem!"},
]

var hero: PSHero
var kind := "stander"      # walker | stander | sitter
var display_name := "Amigo"
var ang := 0.0
var dir := 1.0
var radius := 28.8
var walk_speed := 1.3
var bubble: Label3D
var mark: Label3D
var _order: Array = []
var _bubble_t := 0.0
var _greet_cd := 0.0
var _t := randf() * 6.0
var _near := false
var home_yaw := 0.0

func setup(shirt: String, height: float, kind_: String, name_: String) -> PSNpc:
	kind = kind_
	display_name = name_
	hero = PSHero.new()
	add_child(hero)
	hero.build(height, shirt)
	mark = Label3D.new()
	mark.text = "!"
	mark.font_size = 90
	mark.pixel_size = 0.008
	mark.modulate = Color("ffd23f")
	mark.outline_size = 16
	mark.outline_modulate = Color("5b3a00")
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0, height + 0.55, 0)
	add_child(mark)
	bubble = Label3D.new()
	bubble.font_size = 56
	bubble.pixel_size = 0.0065
	bubble.modulate = Color.WHITE
	bubble.outline_size = 18
	bubble.outline_modulate = Color("1d2b53")
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.width = 720.0
	bubble.position = Vector3(0, height + 1.1, 0)
	bubble.visible = false
	add_child(bubble)
	for i in range(PHRASES.size()):
		_order.append(i)
	_order.shuffle()
	if kind == "sitter":
		hero.sit()
		position.y = 0.11
	return self

func place_on_ring(angle_rad: float, r: float, direction: float) -> void:
	ang = angle_rad
	radius = r
	dir = direction
	position = Vector3(sin(ang) * radius, 0, -cos(ang) * radius)

func tick(delta: float, player_pos: Vector3) -> void:
	_t += delta
	_greet_cd -= delta
	var to_player := player_pos - global_position
	to_player.y = 0.0
	var d := to_player.length()
	_near = d < 6.0
	mark.position.y = hero.height + 0.55 + sin(_t * 3.0) * 0.07
	mark.visible = d < 28.0 and _bubble_t <= 0.0
	match kind:
		"walker":
			var spd := walk_speed
			if d < 3.2:
				spd = 0.0
				rotation.y = lerp_angle(rotation.y, atan2(to_player.x, to_player.z), clampf(6.0 * delta, 0.0, 1.0))
			else:
				ang += dir * walk_speed / radius * delta
				position = Vector3(sin(ang) * radius, 0, -cos(ang) * radius)
				rotation.y = atan2(cos(ang) * dir, sin(ang) * dir)
			hero.set_motion(spd)
		"sitter":
			rotation.y = lerp_angle(rotation.y, home_yaw, clampf(4.0 * delta, 0.0, 1.0))
		_:
			if d < 7.0:
				rotation.y = lerp_angle(rotation.y, atan2(to_player.x, to_player.z), clampf(5.0 * delta, 0.0, 1.0))
				if d < 5.0 and _greet_cd <= 0.0:
					_greet_cd = 25.0
					hero.wave()
			hero.set_motion(0.0)
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			bubble.visible = false

## Conversa: mostra balão e fala a frase em inglês. Devolve a frase.
func talk() -> Dictionary:
	var idx: int = _order.pop_front()
	_order.append(idx)
	var p: Dictionary = PHRASES[idx]
	bubble.text = "%s\n(%s)" % [p["en"], p["pt"]]
	bubble.visible = true
	_bubble_t = 6.0
	if kind != "sitter":
		hero.wave()
	PSAudio.speak(str(p["en"]), "en")
	return p
