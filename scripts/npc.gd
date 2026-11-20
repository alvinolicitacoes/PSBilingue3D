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

# Conteúdo graduado para crianças a partir de seis anos.
# level: 1 = iniciante, 2 = intermediário, 3 = avançado.
const EXTRA_PHRASES := [
	{"en": "Hi!","pt": "Oi!","level": 1},
	{"en": "Bye!","pt": "Tchau!","level": 1},
	{"en": "Yes, please.","pt": "Sim, por favor.","level": 1},
	{"en": "No, thank you.","pt": "Não, obrigado.","level": 1},
	{"en": "My name is Pietro.","pt": "Meu nome é Pietro.","level": 1},
	{"en": "I am six years old.","pt": "Eu tenho seis anos.","level": 1},
	{"en": "This is Thor.","pt": "Este é o Thor.","level": 1},
	{"en": "Thor is my dog.","pt": "Thor é meu cachorro.","level": 1},
	{"en": "I see a cat.","pt": "Eu vejo um gato.","level": 1},
	{"en": "The sun is yellow.","pt": "O sol é amarelo.","level": 1},
	{"en": "The sky is blue.","pt": "O céu é azul.","level": 1},
	{"en": "The grass is green.","pt": "A grama é verde.","level": 1},
	{"en": "I have two hands.","pt": "Eu tenho duas mãos.","level": 1},
	{"en": "I have ten fingers.","pt": "Eu tenho dez dedos nas mãos.","level": 1},
	{"en": "One, two, three!","pt": "Um, dois, três!","level": 1},
	{"en": "Open the door.","pt": "Abra a porta.","level": 1},
	{"en": "Close the window.","pt": "Feche a janela.","level": 1},
	{"en": "Sit down, please.","pt": "Sente-se, por favor.","level": 1},
	{"en": "Stand up, please.","pt": "Levante-se, por favor.","level": 1},
	{"en": "I can jump.","pt": "Eu consigo pular.","level": 1},
	{"en": "I can sing.","pt": "Eu consigo cantar.","level": 1},
	{"en": "I like bananas.","pt": "Eu gosto de bananas.","level": 1},
	{"en": "This is a red ball.","pt": "Esta é uma bola vermelha.","level": 1},
	{"en": "Where is Thor?","pt": "Onde está o Thor?","level": 1},
	{"en": "Here is my book.","pt": "Aqui está meu livro.","level": 1},
	{"en": "I need a pencil.","pt": "Eu preciso de um lápis.","level": 1},
	{"en": "Let's count together.","pt": "Vamos contar juntos.","level": 1},
	{"en": "I feel sad.","pt": "Eu me sinto triste.","level": 1},
	{"en": "I feel excited.","pt": "Eu estou animado.","level": 1},
	{"en": "Wash your hands.","pt": "Lave as mãos.","level": 1},
	{"en": "May I come in?","pt": "Posso entrar?","level": 2},
	{"en": "Can you repeat, please?","pt": "Você pode repetir, por favor?","level": 2},
	{"en": "I do not understand yet.","pt": "Eu ainda não entendo.","level": 2},
	{"en": "Can you speak slowly?","pt": "Você pode falar devagar?","level": 2},
	{"en": "I am learning English.","pt": "Estou aprendendo inglês.","level": 2},
	{"en": "My favorite color is purple.","pt": "Minha cor favorita é roxa.","level": 2},
	{"en": "I have a little sister.","pt": "Eu tenho uma irmãzinha.","level": 2},
	{"en": "We play after school.","pt": "Nós brincamos depois da escola.","level": 2},
	{"en": "I brush my teeth every day.","pt": "Eu escovo os dentes todos os dias.","level": 2},
	{"en": "I eat breakfast in the morning.","pt": "Eu tomo café da manhã de manhã.","level": 2},
	{"en": "We need to cross safely.","pt": "Precisamos atravessar com segurança.","level": 2},
	{"en": "Look both ways before crossing.","pt": "Olhe para os dois lados antes de atravessar.","level": 2},
	{"en": "The library has many books.","pt": "A biblioteca tem muitos livros.","level": 2},
	{"en": "The puppy is sleeping.","pt": "O filhote está dormindo.","level": 2},
	{"en": "My friends are waiting outside.","pt": "Meus amigos estão esperando lá fora.","level": 2},
	{"en": "I want to draw a rainbow.","pt": "Eu quero desenhar um arco-íris.","level": 2},
	{"en": "Let's share our toys.","pt": "Vamos compartilhar nossos brinquedos.","level": 2},
	{"en": "We should help each other.","pt": "Devemos ajudar uns aos outros.","level": 2},
	{"en": "Where can I find the teacher?","pt": "Onde posso encontrar o professor?","level": 2},
	{"en": "What do you like to read?","pt": "O que você gosta de ler?","level": 2},
	{"en": "There are five birds in the tree.","pt": "Há cinco pássaros na árvore.","level": 2},
	{"en": "The ball is under the chair.","pt": "A bola está debaixo da cadeira.","level": 2},
	{"en": "The toy is behind the box.","pt": "O brinquedo está atrás da caixa.","level": 2},
	{"en": "The school is next to the park.","pt": "A escola fica ao lado do parque.","level": 2},
	{"en": "I am wearing a blue shirt.","pt": "Estou vestindo uma camisa azul.","level": 2},
	{"en": "Today is a sunny day.","pt": "Hoje é um dia ensolarado.","level": 2},
	{"en": "Tomorrow we will visit the zoo.","pt": "Amanhã vamos visitar o zoológico.","level": 2},
	{"en": "Yesterday I played with Thor.","pt": "Ontem eu brinquei com o Thor.","level": 2},
	{"en": "First we read, then we play.","pt": "Primeiro lemos, depois brincamos.","level": 2},
	{"en": "I can try again if I make a mistake.","pt": "Posso tentar novamente se eu errar.","level": 2},
	{"en": "If it rains, we can play inside.","pt": "Se chover, podemos brincar dentro de casa.","level": 3},
	{"en": "Although the puzzle is hard, I will try.","pt": "Embora o quebra-cabeça seja difícil, vou tentar.","level": 3},
	{"en": "Could you explain that another way?","pt": "Você poderia explicar isso de outra maneira?","level": 3},
	{"en": "I wonder why the moon changes shape.","pt": "Eu me pergunto por que a Lua muda de forma.","level": 3},
	{"en": "The butterfly begins life as a caterpillar.","pt": "A borboleta começa a vida como lagarta.","level": 3},
	{"en": "Plants need water and sunlight to grow.","pt": "As plantas precisam de água e luz solar para crescer.","level": 3},
	{"en": "We should protect animals and their homes.","pt": "Devemos proteger os animais e seus habitats.","level": 3},
	{"en": "When I finish my homework, I can play.","pt": "Quando eu terminar a lição de casa, posso brincar.","level": 3},
	{"en": "If I had wings, I would fly over the city.","pt": "Se eu tivesse asas, voaria sobre a cidade.","level": 3},
	{"en": "I have never seen such a big rainbow.","pt": "Nunca vi um arco-íris tão grande.","level": 3},
	{"en": "We were playing when the bell rang.","pt": "Estávamos brincando quando o sinal tocou.","level": 3},
	{"en": "She has already finished her drawing.","pt": "Ela já terminou seu desenho.","level": 3},
	{"en": "Can you tell me how this machine works?","pt": "Você pode me dizer como esta máquina funciona?","level": 3},
	{"en": "The story was more exciting than I expected.","pt": "A história foi mais emocionante do que eu esperava.","level": 3},
	{"en": "Even small acts of kindness can help others.","pt": "Até pequenos gestos de gentileza podem ajudar os outros.","level": 3},
	{"en": "Before making a decision, let's think carefully.","pt": "Antes de decidir, vamos pensar com cuidado.","level": 3},
	{"en": "What would happen if there were no trees?","pt": "O que aconteceria se não existissem árvores?","level": 3},
	{"en": "We can solve the problem by working together.","pt": "Podemos resolver o problema trabalhando juntos.","level": 3},
	{"en": "I would rather read a story than watch television.","pt": "Eu preferiria ler uma história a assistir televisão.","level": 3},
	{"en": "The scientist observed how the seeds grew.","pt": "O cientista observou como as sementes cresceram.","level": 3},
	{"en": "Let's compare the two pictures carefully.","pt": "Vamos comparar as duas imagens com atenção.","level": 3},
	{"en": "The answer depends on what we discover.","pt": "A resposta depende do que descobrirmos.","level": 3},
	{"en": "I am proud because I did not give up.","pt": "Estou orgulhoso porque não desisti.","level": 3},
	{"en": "What is the difference between these shapes?","pt": "Qual é a diferença entre estas formas?","level": 3},
	{"en": "We can learn something new every day.","pt": "Podemos aprender algo novo todos os dias.","level": 3},
	{"en": "Please explain why you chose that answer.","pt": "Por favor, explique por que escolheu essa resposta.","level": 3},
	{"en": "After the rain stopped, we went outside.","pt": "Depois que a chuva parou, fomos lá para fora.","level": 3},
	{"en": "I noticed that the shadows move during the day.","pt": "Percebi que as sombras se movem durante o dia.","level": 3},
	{"en": "If we recycle paper, we can save resources.","pt": "Se reciclarmos papel, podemos economizar recursos.","level": 3},
	{"en": "I am curious about how stars are formed.","pt": "Tenho curiosidade sobre como as estrelas se formam.","level": 3},
]

static func all_phrases() -> Array:
	var result: Array = []
	for item in PHRASES:
		var p: Dictionary = item.duplicate()
		p["level"] = 1
		result.append(p)
	for item in EXTRA_PHRASES:
		result.append(item)
	return result

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
	for i in range(all_phrases().size()):
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

## Seleciona uma frase sem repetir até completar o ciclo embaralhado.
func next_phrase() -> Dictionary:
	if _order.is_empty():
		for i in range(all_phrases().size()):
			_order.append(i)
		_order.shuffle()
	var idx: int = _order.pop_front()
	var p: Dictionary = all_phrases()[idx]
	bubble.text = "%s\n(%s)" % [p["en"], p["pt"]]
	bubble.visible = true
	_bubble_t = 6.0
	if kind != "sitter":
		hero.wave()
	return p

func talk() -> Dictionary:
	var p := next_phrase()
	PSAudio.speak(str(p["en"]), "en")
	return p
