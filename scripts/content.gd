extends RefCounted
class_name PSContent
## Gera as perguntas de cada atividade. Cada pergunta é um Dictionary:
## prompt, options[{text | icon,color}], answer(índice), e opcionais: speak, speak_lang, image(animal), swatch(Color),
## seq(Array de {kind,color} ou null = "?"), note.

const PALETTE := [Color("e53935"), Color("1e88e5"), Color("43a047"), Color("fdd835"), Color("fb8c00"), Color("8e24aa"), Color("ec407a")]

# ------------------------------------------------------------------------------------
static func mode_kind(mode: String) -> String:
	match mode:
		"Memória":
			return "memory"
		"Sudoku":
			return "sudoku"
		"Soletração":
			return "spelling"
	return "quiz"

static func make(mode: String, level: int, count: int = 10) -> Array:
	match mode:
		"Inglês":
			return _english(level, count)
		"Frases":
			return _phrases(level, count)
		"Português":
			return _bank(PORTUGUES, level, count)
		"Ciências":
			return _bank(CIENCIAS, level, count)
		"Geografia":
			return _geografia(level, count)
		"Animais":
			return _animais(level, count)
		"Cores":
			return _cores(level, count)
		"Matemática":
			return _math(level, count)
		"Lógica":
			return _logic(level, count)
	return []

# ---- utilidades ------------------------------------------------------------------------
static func _mc(prompt: String, correct: String, wrong: Array, extra: Dictionary = {}) -> Dictionary:
	var opts: Array = [correct]
	var w := wrong.duplicate()
	w.shuffle()
	for x in w:
		if opts.size() >= 4:
			break
		var s := str(x)
		if s != correct and not opts.has(s):
			opts.append(s)
	opts.shuffle()
	var options: Array = []
	for o in opts:
		options.append({"text": str(o)})
	var q := {"prompt": prompt, "options": options, "answer": opts.find(correct)}
	for k in extra:
		q[k] = extra[k]
	return q

static func _tiers(level: int) -> Array:
	if level <= 2:
		return [1]
	if level <= 4:
		return [1, 2]
	if level <= 6:
		return [2]
	if level <= 8:
		return [2, 3]
	return [3]

## Sorteia `count` itens do banco [prompt, correta, [erradas], tier] respeitando o nível, sem repetir.
static func _pick(bank: Array, level: int, count: int) -> Array:
	var tiers := _tiers(level)
	var pool: Array = []
	var rest: Array = []
	for it in bank:
		var item: Array = it
		if tiers.has(int(item[item.size() - 1])):
			pool.append(item)
		else:
			rest.append(item)
	pool.shuffle()
	rest.shuffle()
	while pool.size() < count and not rest.is_empty():
		pool.append(rest.pop_back())
	return pool.slice(0, count)

static func _bank(bank: Array, level: int, count: int) -> Array:
	var out: Array = []
	for it in _pick(bank, level, count):
		var item: Array = it
		out.append(_mc(str(item[0]), str(item[1]), item[2]))
	return out

# ---- Inglês ---------------------------------------------------------------------------------
const VOCAB := [
	["cat", "gato", 1], ["dog", "cachorro", 1], ["house", "casa", 1], ["book", "livro", 1], ["water", "água", 1], ["sun", "sol", 1],
	["moon", "lua", 1], ["tree", "árvore", 1], ["apple", "maçã", 1], ["milk", "leite", 1], ["ball", "bola", 1], ["car", "carro", 1],
	["fish", "peixe", 1], ["bird", "pássaro", 1], ["pig", "porco", 1], ["lion", "leão", 1], ["bear", "urso", 1], ["rabbit", "coelho", 1],
	["egg", "ovo", 1], ["hat", "chapéu", 1], ["shoe", "sapato", 1], ["cake", "bolo", 1], ["star", "estrela", 1], ["bed", "cama", 1],
	["school", "escola", 2], ["teacher", "professor", 2], ["friend", "amigo", 2], ["family", "família", 2], ["window", "janela", 2], ["door", "porta", 2],
	["table", "mesa", 2], ["chair", "cadeira", 2], ["pencil", "lápis", 2], ["bread", "pão", 2], ["cheese", "queijo", 2], ["banana", "banana", 2],
	["flower", "flor", 2], ["rain", "chuva", 2], ["cloud", "nuvem", 2], ["hand", "mão", 2], ["foot", "pé", 2], ["head", "cabeça", 2],
	["eye", "olho", 2], ["nose", "nariz", 2], ["mouth", "boca", 2], ["sister", "irmã", 2], ["brother", "irmão", 2], ["penguin", "pinguim", 2],
	["elephant", "elefante", 2], ["shark", "tubarão", 2], ["panda", "panda", 2], ["fox", "raposa", 2], ["koala", "coala", 2], ["unicorn", "unicórnio", 2],
	["run", "correr", 3], ["jump", "pular", 3], ["eat", "comer", 3], ["drink", "beber", 3], ["sleep", "dormir", 3], ["read", "ler", 3],
	["write", "escrever", 3], ["sing", "cantar", 3], ["dance", "dançar", 3], ["swim", "nadar", 3], ["happy", "feliz", 3], ["sad", "triste", 3],
	["big", "grande", 3], ["small", "pequeno", 3], ["fast", "rápido", 3], ["slow", "devagar", 3], ["hot", "quente", 3], ["cold", "frio", 3],
	["strong", "forte", 3], ["tired", "cansado", 3], ["night", "noite", 3], ["morning", "manhã", 3], ["crocodile", "crocodilo", 3], ["kitchen", "cozinha", 3],
]

static func _animal_id(en: String) -> String:
	for k in PSConfig.ANIMAL_EN:
		if PSConfig.ANIMAL_EN[k] == en:
			return String(k)
	return ""

static func _english(level: int, count: int) -> Array:
	var tiers := _tiers(level)
	var pool: Array = []
	for v in VOCAB:
		var it: Array = v
		if tiers.has(int(it[2])):
			pool.append(it)
	pool.shuffle()
	var all_en: Array = []
	var all_pt: Array = []
	for v in VOCAB:
		var it2: Array = v
		all_en.append(it2[0])
		all_pt.append(it2[1])
	var out: Array = []
	for i in range(mini(count, pool.size())):
		var it3: Array = pool[i]
		var en := str(it3[0])
		var pt := str(it3[1])
		var img := _animal_id(en)
		var kind := randi() % 3
		if kind == 2 and not PSAudio.can_speak():
			kind = randi() % 2
		var extra: Dictionary = {}
		if img != "":
			extra["image"] = img
		if kind == 0:
			extra["speak"] = en
			extra["note"] = "%s = %s" % [en, pt]
			out.append(_mc("O que significa “%s”?" % en, pt, all_pt, extra))
		elif kind == 1:
			extra["note"] = "%s = %s" % [pt, en]
			out.append(_mc("Como se diz “%s” em inglês?" % pt, en, all_en, extra))
		else:
			extra["speak"] = en
			extra["auto_speak"] = true
			extra["note"] = "%s = %s" % [en, pt]
			extra.erase("image")
			out.append(_mc("Ouça e escolha a palavra certa", en, all_en, extra))
	return out

# ---- Frases -----------------------------------------------------------------------------------
const FILL := [
	["I ___ a student.", "am", ["is", "are", "be"], 1], ["She ___ a cat.", "has", ["have", "having", "haves"], 1],
	["They ___ happy.", "are", ["is", "am", "be"], 1], ["He ___ my friend.", "is", ["are", "am", "be"], 1],
	["We ___ to school.", "go", ["goes", "going", "gone"], 2], ["She ___ to school.", "goes", ["go", "going", "gone"], 2],
	["I ___ an apple.", "eat", ["eats", "eating", "ate"], 2], ["This is ___ apple.", "an", ["a", "the", "two"], 2],
	["I have ___ dog.", "a", ["an", "two", "are"], 1], ["The cat is ___ the table.", "on", ["in", "at", "to"], 2],
	["I like ___ play.", "to", ["at", "on", "of"], 2], ["Do you ___ ice cream?", "like", ["likes", "liking", "to like"], 2],
	["There ___ three books.", "are", ["is", "am", "be"], 3], ["My brother ___ a ball.", "has", ["have", "having", "haves"], 3],
	["___ is your name?", "What", ["Where", "Who", "When"], 1], ["___ are you? I am fine.", "How", ["What", "Where", "Who"], 1],
	["I am ___ years old.", "eight", ["eating", "eats", "ate"], 1], ["She is ___ than me.", "taller", ["tall", "tallest", "more tall"], 3],
	["Yesterday I ___ to the park.", "went", ["go", "goes", "going"], 3], ["He can ___ very fast.", "run", ["runs", "running", "ran"], 2],
]

static func _phrases(level: int, count: int) -> Array:
	var tiers := _tiers(level)
	var out: Array = []
	var phr: Array = PSNpc.all_phrases()
	phr = phr.filter(func(p): return tiers.has(int(p.get("level", 1))))
	phr.shuffle()
	var all_pt: Array = []
	var all_en: Array = []
	for p in PSNpc.all_phrases():
		var d: Dictionary = p
		all_pt.append(d["pt"])
		all_en.append(d["en"])
	var fills: Array = []
	for f in FILL:
		var fi: Array = f
		if tiers.has(int(fi[3])) or randf() < 0.25:
			fills.append(fi)
	fills.shuffle()
	var nf := mini(fills.size(), count / 2)
	for i in range(nf):
		var fi2: Array = fills[i]
		out.append(_mc("Complete a frase:  %s" % fi2[0], str(fi2[1]), fi2[2]))
	var j := 0
	while out.size() < count and j < phr.size():
		var d2: Dictionary = phr[j]
		j += 1
		var kind := randi() % 3
		if kind == 2 and not PSAudio.can_speak():
			kind = randi() % 2
		if kind == 0:
			out.append(_mc("O que significa:  “%s”" % d2["en"], str(d2["pt"]), all_pt, {"speak": d2["en"]}))
		elif kind == 1:
			out.append(_mc("Como se diz em inglês:  “%s”" % d2["pt"], str(d2["en"]), all_en))
		else:
			out.append(_mc("Ouça a frase e escolha a tradução", str(d2["pt"]), all_pt, {"speak": d2["en"], "auto_speak": true}))
	out.shuffle()
	return out

# ---- Português ------------------------------------------------------------------------------------
const PORTUGUES := [
	["Qual palavra começa com a letra B?", "bola", ["casa", "mesa", "dedo"], 1],
	["Quantas sílabas tem a palavra “bola”?", "2", ["1", "3", "4"], 1],
	["Qual é o plural de “gato”?", "gatos", ["gatoes", "gatus", "gatinho"], 1],
	["O contrário de “grande” é…", "pequeno", ["alto", "forte", "longo"], 1],
	["O contrário de “quente” é…", "frio", ["morno", "fogo", "calor"], 1],
	["Qual palavra está escrita corretamente?", "casa", ["caza", "kasa", "cassa"], 1],
	["Qual destas letras é uma vogal?", "E", ["B", "M", "T"], 1],
	["Qual animal late?", "cachorro", ["gato", "pato", "peixe"], 1],
	["Qual palavra rima com “pato”?", "gato", ["casa", "bola", "livro"], 1],
	["Qual palavra rima com “mão”?", "pão", ["pé", "sol", "lua"], 1],
	["Qual palavra é o nome de uma fruta?", "banana", ["cadeira", "mesa", "lápis"], 1],
	["Qual palavra é um animal?", "cavalo", ["caderno", "janela", "bolo"], 1],
	["Qual é a letra inicial de “sol”?", "S", ["C", "Z", "X"], 1],
	["Qual palavra vem primeiro no alfabeto?", "abelha", ["casa", "dado", "fogo"], 1],
	["Quantas letras tem a palavra “sol”?", "3", ["2", "4", "5"], 1],
	["Qual é o plural de “pão”?", "pães", ["pãos", "pões", "pãeses"], 2],
	["Qual é o plural de “animal”?", "animais", ["animals", "animales", "animaes"], 2],
	["Qual é o feminino de “menino”?", "menina", ["menine", "meninão", "meninou"], 2],
	["O feminino de “leão” é…", "leoa", ["leã", "leona", "leão"], 2],
	["Qual palavra é um verbo?", "correr", ["mesa", "azul", "feliz"], 2],
	["Qual palavra é um adjetivo (uma qualidade)?", "bonito", ["cantar", "livro", "ontem"], 2],
	["Quantas sílabas tem “borboleta”?", "4", ["3", "5", "2"], 2],
	["Quantas sílabas tem “elefante”?", "4", ["3", "5", "2"], 2],
	["Qual palavra está escrita corretamente?", "chuva", ["xuva", "chuvá", "shuva"], 2],
	["Qual está escrita corretamente?", "caminhão", ["caminhaum", "caminhao", "camiñão"], 2],
	["Qual está correta?", "café", ["cafe", "cafê", "caffé"], 2],
	["O contrário de “dia” é…", "noite", ["tarde", "manhã", "sol"], 2],
	["O contrário de “alegre” é…", "triste", ["feliz", "rindo", "contente"], 2],
	["O contrário de “subir” é…", "descer", ["pular", "andar", "correr"], 2],
	["O contrário de “cheio” é…", "vazio", ["pesado", "grande", "novo"], 2],
	["Qual palavra tem o mesmo sentido de “bonito”?", "belo", ["feio", "triste", "pequeno"], 2],
	["“Rápido” é parecido com…", "veloz", ["lento", "pesado", "baixo"], 2],
	["Quantas palavras tem a frase “O gato subiu no telhado.”?", "5", ["4", "6", "3"], 2],
	["Em “Maria comeu a maçã.”, quem comeu?", "Maria", ["maçã", "a", "comeu"], 2],
	["Que sinal usamos no fim de uma pergunta?", "?", ["!", ".", ","], 2],
	["Qual é o plural de “cidadão”?", "cidadãos", ["cidadões", "cidadães", "cidadans"], 3],
	["Qual frase está correta?", "Eu fui à escola.", ["Eu foi à escola.", "Nós vai à escola.", "Eles vou à escola."], 3],
	["Qual palavra está escrita corretamente?", "coração", ["corasão", "coraçao", "corassão"], 3],
	["Qual palavra é um nome próprio?", "Brasil", ["país", "rio", "cidade"], 3],
	["Quantas letras tem a palavra “escola”?", "6", ["5", "7", "8"], 3],
	["Qual é o diminutivo de “casa”?", "casinha", ["casona", "casão", "casarão"], 3],
	["Qual é o aumentativo de “bola”?", "bolão", ["bolinha", "bolete", "bolinho"], 3],
	["Complete: Eu quero ___ suco.", "mais", ["mas", "más", "maz"], 3],
	["Como se chama um conjunto de peixes?", "cardume", ["matilha", "enxame", "rebanho"], 3],
	["Como se chama um conjunto de abelhas?", "enxame", ["cardume", "matilha", "manada"], 3],
	["Em “Os meninos brincam”, qual palavra é o verbo?", "brincam", ["meninos", "Os", "brincar"], 3],
	["Qual palavra tem o dígrafo “nh”?", "ninho", ["mina", "nota", "bonito"], 3],
	["Qual palavra é sinônimo de “contente”?", "alegre", ["bravo", "cansado", "doente"], 3],
]

# ---- Ciências ----------------------------------------------------------------------------------------
const CIENCIAS := [
	["Em qual planeta nós vivemos?", "Terra", ["Marte", "Lua", "Sol"], 1],
	["O que as plantas precisam para crescer?", "água e luz do sol", ["só doces", "só sombra", "plástico"], 1],
	["Qual destes animais é um mamífero?", "cachorro", ["cobra", "sapo", "peixe"], 1],
	["Qual destes é um líquido?", "água", ["pedra", "madeira", "areia"], 1],
	["Com qual parte do corpo a gente enxerga?", "olhos", ["nariz", "boca", "orelhas"], 1],
	["Com qual parte do corpo a gente ouve?", "ouvidos", ["olhos", "mãos", "pés"], 1],
	["Quantos sentidos nós temos?", "5", ["3", "4", "6"], 1],
	["Quem ilumina a Terra durante o dia?", "Sol", ["Lua", "estrelas", "nuvens"], 1],
	["A chuva é formada por gotas de…", "água", ["areia", "leite", "suco"], 1],
	["Qual destes é um inseto?", "abelha", ["aranha", "minhoca", "caracol"], 1],
	["Qual inseto faz mel?", "abelha", ["formiga", "borboleta", "mosca"], 1],
	["A água do mar é…", "salgada", ["doce", "azeda", "amarga"], 1],
	["Qual estação vem depois do verão?", "outono", ["inverno", "primavera", "verão"], 1],
	["Qual gás precisamos respirar para viver?", "oxigênio", ["hélio", "ouro", "fumaça"], 2],
	["Qual é o maior planeta do Sistema Solar?", "Júpiter", ["Terra", "Marte", "Vênus"], 2],
	["Qual é o planeta mais próximo do Sol?", "Mercúrio", ["Vênus", "Terra", "Marte"], 2],
	["Quantos planetas tem o Sistema Solar?", "8", ["9", "7", "10"], 2],
	["A água vira gelo quando fica…", "muito fria", ["muito quente", "escura", "barulhenta"], 2],
	["Qual animal é um réptil?", "jacaré", ["sapo", "golfinho", "pato"], 2],
	["Qual animal é uma ave?", "pinguim", ["morcego", "golfinho", "tubarão"], 2],
	["Qual parte da planta fica embaixo da terra?", "raiz", ["flor", "folha", "fruto"], 2],
	["Qual parte da planta se transforma em fruto?", "flor", ["raiz", "caule", "espinho"], 2],
	["O arco-íris aparece quando há sol e…", "gotinhas de chuva", ["neve", "terremoto", "trovão"], 2],
	["Qual material é atraído por um ímã?", "ferro", ["madeira", "plástico", "vidro"], 2],
	["Qual animal vive na água e respira por guelras?", "peixe", ["gato", "pássaro", "cavalo"], 2],
	["Como se chama o filhote da rã?", "girino", ["pintinho", "potro", "cordeiro"], 2],
	["Um herbívoro é um animal que come…", "plantas", ["carne", "pedras", "areia"], 2],
	["Qual astro gira ao redor da Terra?", "Lua", ["Sol", "Marte", "Júpiter"], 2],
	["Qual é o estado da água no vapor?", "gasoso", ["sólido", "líquido", "pastoso"], 3],
	["Qual osso protege o cérebro?", "crânio", ["costela", "fêmur", "coluna"], 3],
	["Qual órgão bombeia o sangue pelo corpo?", "coração", ["pulmão", "estômago", "rim"], 3],
	["Quais órgãos usamos para respirar?", "pulmões", ["estômago", "coração", "fígado"], 3],
	["Em 24 horas a Terra…", "gira em torno de si mesma", ["dá uma volta ao redor do Sol", "para de girar", "muda de lugar"], 3],
	["Quanto tempo a Terra leva para dar uma volta ao redor do Sol?", "1 ano", ["1 dia", "1 mês", "1 semana"], 3],
	["Qual é o animal terrestre mais rápido?", "guepardo", ["leão", "cavalo", "elefante"], 3],
	["Qual é o maior animal do mundo?", "baleia-azul", ["elefante", "girafa", "tubarão"], 3],
	["Quando a água do mar vira vapor e sobe, isso se chama…", "evaporação", ["congelamento", "fusão", "colisão"], 3],
	["Como se chama a camada de gases que envolve a Terra?", "atmosfera", ["litosfera", "hidrosfera", "biosfera"], 3],
	["O que a fotossíntese faz?", "as plantas fazem seu alimento com a luz do sol", ["os animais dormem", "a chuva cai", "o vento sopra"], 3],
	["Qual destes é um animal carnívoro?", "leão", ["vaca", "coelho", "girafa"], 3],
]

# ---- Geografia --------------------------------------------------------------------------------------------
const GEO := [
	["Em qual país nós moramos?", "Brasil", ["Argentina", "Portugal", "Japão"], 1],
	["Qual é a capital do Brasil?", "Brasília", ["Rio de Janeiro", "São Paulo", "Salvador"], 1],
	["Qual língua se fala no Brasil?", "português", ["espanhol", "inglês", "francês"], 1],
	["Qual oceano banha o litoral do Brasil?", "Atlântico", ["Pacífico", "Índico", "Ártico"], 1],
	["Qual é o maior rio do Brasil?", "Amazonas", ["São Francisco", "Tietê", "Paraná"], 1],
	["Quais são as cores principais da bandeira do Brasil?", "verde e amarelo", ["vermelho e branco", "preto e roxo", "rosa e cinza"], 1],
	["Em qual estado fica Salvador?", "Bahia", ["Ceará", "Pernambuco", "Maranhão"], 1],
	["Qual é a capital da Bahia?", "Salvador", ["Recife", "Fortaleza", "Aracaju"], 1],
	["Em qual continente fica o Brasil?", "América do Sul", ["África", "Europa", "Ásia"], 1],
	["O que é um mapa?", "um desenho que mostra lugares", ["um tipo de comida", "um brinquedo", "uma música"], 1],
	["Em qual direção o Sol nasce?", "leste", ["oeste", "norte", "sul"], 1],
	["Qual é a capital de São Paulo (estado)?", "São Paulo", ["Campinas", "Santos", "Brasília"], 2],
	["Qual é a capital de Minas Gerais?", "Belo Horizonte", ["Uberlândia", "Salvador", "Vitória"], 2],
	["Qual é a capital de Pernambuco?", "Recife", ["Olinda", "Natal", "Maceió"], 2],
	["Qual é a capital do Ceará?", "Fortaleza", ["Recife", "Teresina", "Natal"], 2],
	["Qual é a capital do Paraná?", "Curitiba", ["Londrina", "Florianópolis", "Porto Alegre"], 2],
	["Qual é a capital do Rio Grande do Sul?", "Porto Alegre", ["Curitiba", "Pelotas", "Florianópolis"], 2],
	["Qual é a capital do Amazonas?", "Manaus", ["Belém", "Macapá", "Porto Velho"], 2],
	["Qual é a capital do Pará?", "Belém", ["Manaus", "Santarém", "Palmas"], 2],
	["Qual é a capital de Goiás?", "Goiânia", ["Brasília", "Cuiabá", "Palmas"], 2],
	["Qual é a capital de Santa Catarina?", "Florianópolis", ["Joinville", "Curitiba", "Blumenau"], 2],
	["Quantos estados (além do Distrito Federal) tem o Brasil?", "26", ["20", "30", "12"], 2],
	["Qual é o maior continente?", "Ásia", ["África", "Europa", "Oceania"], 2],
	["Qual é o maior oceano?", "Pacífico", ["Atlântico", "Índico", "Ártico"], 2],
	["Qual é a capital da Argentina?", "Buenos Aires", ["Santiago", "Lima", "Montevidéu"], 2],
	["Qual é a capital de Portugal?", "Lisboa", ["Madri", "Porto", "Paris"], 2],
	["Qual é a capital da França?", "Paris", ["Londres", "Roma", "Berlim"], 2],
	["Qual é a capital do Japão?", "Tóquio", ["Pequim", "Seul", "Bangcoc"], 2],
	["Em qual país fica a Torre Eiffel?", "França", ["Itália", "Inglaterra", "Alemanha"], 2],
	["Em qual país ficam as pirâmides do Egito?", "Egito", ["México", "Peru", "Índia"], 2],
	["Em qual cidade brasileira fica o Cristo Redentor?", "Rio de Janeiro", ["Salvador", "São Paulo", "Brasília"], 2],
	["Qual país é famoso pelos cangurus?", "Austrália", ["Canadá", "Brasil", "Índia"], 2],
	["Qual é o menor continente?", "Oceania", ["Europa", "Antártida", "América do Sul"], 3],
	["Qual país tem o formato parecido com uma bota?", "Itália", ["Espanha", "Grécia", "Portugal"], 3],
	["Qual é o maior país do mundo em área?", "Rússia", ["China", "Brasil", "Canadá"], 3],
	["Qual é o maior país da América do Sul?", "Brasil", ["Argentina", "Peru", "Colômbia"], 3],
	["Qual cordilheira fica na América do Sul?", "Andes", ["Himalaia", "Alpes", "Rochosas"], 3],
	["Qual é o deserto quente mais famoso da África?", "Saara", ["Gobi", "Atacama", "Kalahari"], 3],
	["Qual linha imaginária divide a Terra em hemisfério norte e sul?", "Equador", ["Meridiano", "Trópico", "Polo"], 3],
	["Quais são os pontos cardeais?", "norte, sul, leste e oeste", ["cima, baixo, frente e trás", "alto, baixo, perto e longe", "claro e escuro"], 3],
	["Qual é a capital do Canadá?", "Ottawa", ["Toronto", "Vancouver", "Montreal"], 3],
	["Qual é a capital da Austrália?", "Camberra", ["Sydney", "Melbourne", "Perth"], 3],
	["Qual é a capital do Peru?", "Lima", ["Quito", "Bogotá", "Santiago"], 3],
	["Qual é a capital do Uruguai?", "Montevidéu", ["Assunção", "Lima", "Buenos Aires"], 3],
	["Qual bioma é a maior floresta tropical do Brasil?", "Amazônia", ["Pampa", "Cerrado", "Pantanal"], 3],
	["Qual bioma é típico do sertão nordestino?", "Caatinga", ["Amazônia", "Mata Atlântica", "Pampa"], 3],
	["Qual é a montanha mais alta do mundo?", "Monte Everest", ["Monte Fuji", "Mont Blanc", "Aconcágua"], 3],
]

static func _geografia(level: int, count: int) -> Array:
	return _bank(GEO, level, count)

# ---- Animais ---------------------------------------------------------------------------------------------------
const ANIM_TXT := [
	["Qual animal faz “miau”?", "gato", ["cachorro", "vaca", "pato"], 1],
	["Qual animal faz “muuu”?", "vaca", ["cavalo", "porco", "galo"], 1],
	["O que a galinha põe?", "ovos", ["leite", "mel", "lã"], 1],
	["Qual animal tem uma tromba?", "elefante", ["leão", "girafa", "zebra"], 1],
	["Qual animal tem listras pretas e brancas?", "zebra", ["leão", "onça", "macaco"], 1],
	["Qual animal tem o pescoço muito comprido?", "girafa", ["urso", "porco", "coelho"], 1],
	["Qual animal é chamado de rei da selva?", "leão", ["macaco", "cobra", "tartaruga"], 1],
	["Qual animal pula e leva o filhote numa bolsa?", "canguru", ["coelho", "sapo", "esquilo"], 1],
	["Qual animal dorme de cabeça para baixo?", "morcego", ["gato", "cavalo", "peixe"], 1],
	["Qual animal faz “quá quá”?", "pato", ["galo", "ovelha", "cachorro"], 1],
	["Qual é o maior animal que vive em terra firme?", "elefante", ["girafa", "urso", "cavalo"], 2],
	["Qual animal nos dá lã?", "ovelha", ["vaca", "galinha", "pato"], 2],
	["Qual animal muda de cor?", "camaleão", ["sapo", "cobra", "tartaruga"], 2],
	["Qual animal come bambu?", "panda", ["leão", "lobo", "tigre"], 2],
	["Quantas patas tem uma aranha?", "8", ["6", "4", "10"], 2],
	["Quantas patas tem um inseto?", "6", ["4", "8", "10"], 2],
	["A lagarta se transforma em…", "borboleta", ["abelha", "formiga", "besouro"], 2],
	["Qual animal tem casco e anda bem devagar?", "tartaruga", ["coelho", "gato", "cavalo"], 2],
	["Qual ave não voa e vive em lugares gelados?", "pinguim", ["pardal", "papagaio", "coruja"], 2],
	["Como se chama a casa das abelhas?", "colmeia", ["toca", "ninho", "curral"], 2],
	["Como se chama a casa dos passarinhos?", "ninho", ["colmeia", "toca", "estábulo"], 2],
	["Qual animal pertence ao grupo dos marsupiais?", "coala", ["urso", "macaco", "coelho"], 3],
	["Qual mamífero consegue voar?", "morcego", ["pinguim", "galinha", "gaivota"], 3],
	["Qual ave é símbolo de sabedoria?", "coruja", ["pombo", "galo", "pato"], 3],
	["Os golfinhos são…", "mamíferos", ["peixes", "répteis", "insetos"], 3],
	["Os tubarões respiram por…", "guelras", ["pulmões", "pele de sapo", "nariz"], 3],
	["O que come um animal carnívoro?", "carne", ["só plantas", "só frutas", "só pedras"], 3],
	["O filhote do cavalo se chama…", "potro", ["cordeiro", "bezerro", "leitão"], 3],
	["O filhote da vaca se chama…", "bezerro", ["potro", "cabrito", "pintinho"], 3],
	["Qual animal tem a pele cheia de espinhos e se enrola em bola?", "ouriço", ["tatu", "coelho", "esquilo"], 3],
]

static func _animais(level: int, count: int) -> Array:
	var out: Array = []
	var n_img := count / 2 if level >= 3 else count - 3
	var ids: Array = PSConfig.ANIMALS.duplicate()
	ids.shuffle()
	var all_pt: Array = []
	var all_en: Array = []
	for id in PSConfig.ANIMALS:
		all_pt.append(PSConfig.ANIMAL_PT[id])
		all_en.append(PSConfig.ANIMAL_EN[id])
	for i in range(mini(n_img, ids.size())):
		var id: String = ids[i]
		var en_mode := level >= 5 and randf() < 0.5
		if en_mode:
			out.append(_mc("Como se diz este bichinho em inglês?", String(PSConfig.ANIMAL_EN[id]), all_en, {"image": id, "speak": PSConfig.ANIMAL_EN[id], "note": "%s = %s" % [PSConfig.ANIMAL_EN[id], PSConfig.ANIMAL_PT[id]]}))
		else:
			out.append(_mc("Que animal é este?", String(PSConfig.ANIMAL_PT[id]), all_pt, {"image": id, "speak": PSConfig.ANIMAL_EN[id]}))
	for q in _bank(ANIM_TXT, level, count - out.size()):
		out.append(q)
	out.shuffle()
	return out

# ---- Cores -----------------------------------------------------------------------------------------------------
const COLORS := [
	["red", "vermelho", Color("e53935")], ["blue", "azul", Color("1e88e5")], ["green", "verde", Color("43a047")],
	["yellow", "amarelo", Color("fdd835")], ["orange", "laranja", Color("fb8c00")], ["purple", "roxo", Color("8e24aa")],
	["pink", "rosa", Color("ec407a")], ["brown", "marrom", Color("795548")], ["black", "preto", Color("212121")],
	["white", "branco", Color("fafafa")], ["gray", "cinza", Color("9e9e9e")],
]
const OBJ_COLOR := [
	["a banana", "yellow"], ["the grass", "green"], ["the sky", "blue"], ["snow", "white"], ["a strawberry", "red"],
	["chocolate", "brown"], ["an orange", "orange"], ["a plum", "purple"], ["an elephant", "gray"], ["coal", "black"],
]
const MIX := [
	["blue", "yellow", "green"], ["red", "yellow", "orange"], ["red", "blue", "purple"], ["red", "white", "pink"],
]

static func _cores(level: int, count: int) -> Array:
	var n_colors := 6 if level <= 3 else (9 if level <= 6 else 11)
	var pool: Array = COLORS.slice(0, n_colors)
	var out: Array = []
	var names_en: Array = []
	var names_pt: Array = []
	for c in pool:
		var ci: Array = c
		names_en.append(ci[0])
		names_pt.append(ci[1])
	var idx: Array = range(pool.size())
	idx.shuffle()
	var used := 0
	while out.size() < count:
		var kind := randi() % (3 if level <= 3 else (5 if level <= 6 else 6))
		var ci2: Array = pool[idx[used % idx.size()]]
		used += 1
		var en := str(ci2[0])
		var pt := str(ci2[1])
		var col: Color = ci2[2]
		match kind:
			0:
				out.append(_mc("What color is this?", en, names_en, {"swatch": col, "speak": en, "note": "%s = %s" % [en, pt]}))
			1:
				out.append(_mc("Qual é o nome desta cor em português?", pt, names_pt, {"swatch": col, "speak": en}))
			2:
				var q := _mc("Which one is %s?" % en, en, names_en)
				var opts: Array = []
				var ok := 0
				var chosen: Array = [col]
				var others: Array = pool.duplicate()
				others.shuffle()
				for o in others:
					var oi: Array = o
					if chosen.size() >= 4:
						break
					if not chosen.has(oi[2]):
						chosen.append(oi[2])
				chosen.shuffle()
				for k in range(chosen.size()):
					opts.append({"icon": "circle", "color": chosen[k], "text": ""})
					if chosen[k] == col:
						ok = k
				q = {"prompt": "Which one is %s?  (%s)" % [en, pt], "options": opts, "answer": ok, "speak": en}
				out.append(q)
			3:
				var oc: Array = OBJ_COLOR[randi() % OBJ_COLOR.size()]
				out.append(_mc("What color is %s?" % oc[0], str(oc[1]), names_en))
			4:
				out.append(_mc("Como se diz “%s” em inglês?" % pt, en, names_en, {"swatch": col}))
			_:
				var m: Array = MIX[randi() % MIX.size()]
				out.append(_mc("%s + %s = ?  (em inglês)" % [m[0], m[1]], str(m[2]), ["green", "orange", "purple", "pink", "brown"], {"note": "%s + %s = %s" % [m[0], m[1], m[2]]}))
		if used > 60:
			break
	return out.slice(0, count)

# ---- Matemática --------------------------------------------------------------------------------------------------
static func _num_q(prompt: String, ans: int, extra: Dictionary = {}) -> Dictionary:
	var cands: Array = []
	for d in [1, -1, 2, -2, 3, -3, 10, -10, 5, -5]:
		var v: int = ans + int(d)
		if v >= 0 and v != ans:
			cands.append(v)
	cands.shuffle()
	var wrong: Array = []
	for c in cands:
		if wrong.size() < 3:
			wrong.append(str(c))
	return _mc(prompt, str(ans), wrong, extra)

static func _icons_row(n: int) -> Array:
	var k: String = PSUI.Icon.KINDS[randi() % PSUI.Icon.KINDS.size()]
	var col: Color = PALETTE[randi() % PALETTE.size()]
	var row: Array = []
	for i in range(n):
		row.append({"kind": k, "color": col})
	return row

static func _math(level: int, count: int) -> Array:
	var out: Array = []
	var seen := {}
	var guard := 0
	while out.size() < count and guard < 300:
		guard += 1
		var q := _math_one(level)
		var key := str(q["prompt"])
		if seen.has(key):
			continue
		seen[key] = true
		out.append(q)
	return out

static func _math_one(level: int) -> Dictionary:
	var kinds_by_level: Array = [
		["count", "add10"], ["add20", "sub10", "count"], ["add50", "sub50", "compare"], ["add100", "sub100", "missing"],
		["mul_easy", "skip", "missing"], ["mul", "div_easy", "word"], ["mul9", "div", "double_half"],
		["two_step", "div", "word"], ["mul_big", "word", "two_step"], ["frac", "square", "two_step", "order"],
	]
	var ks: Array = kinds_by_level[clampi(level, 1, 10) - 1]
	var kind: String = ks[randi() % ks.size()]
	var a := 0
	var b := 0
	match kind:
		"count":
			var n := randi_range(2, 5 + level * 2)
			return _num_q("Quantas figuras você vê?", n, {"seq": _icons_row(n)})
		"add10":
			a = randi_range(1, 9)
			b = randi_range(1, 10 - a) if a < 10 else 1
			return _num_q("%d + %d = ?" % [a, b], a + b)
		"add20":
			a = randi_range(3, 15)
			b = randi_range(2, 20 - a)
			return _num_q("%d + %d = ?" % [a, b], a + b)
		"sub10":
			a = randi_range(4, 10)
			b = randi_range(1, a - 1)
			return _num_q("%d − %d = ?" % [a, b], a - b)
		"add50":
			a = randi_range(10, 35)
			b = randi_range(5, 50 - a)
			return _num_q("%d + %d = ?" % [a, b], a + b)
		"sub50":
			a = randi_range(20, 50)
			b = randi_range(5, a - 5)
			return _num_q("%d − %d = ?" % [a, b], a - b)
		"compare":
			a = randi_range(10, 99)
			b = randi_range(10, 99)
			if a == b:
				b += 1
			return _mc("Qual número é maior?", str(maxi(a, b)), [str(mini(a, b)), str(maxi(a, b) + 10), str(mini(a, b) - 1)])
		"add100":
			a = randi_range(20, 70)
			b = randi_range(10, 100 - a)
			return _num_q("%d + %d = ?" % [a, b], a + b)
		"sub100":
			a = randi_range(40, 100)
			b = randi_range(10, a - 10)
			return _num_q("%d − %d = ?" % [a, b], a - b)
		"missing":
			a = randi_range(3, 40)
			b = randi_range(3, 40)
			return _num_q("%d + ? = %d" % [a, a + b], b)
		"mul_easy":
			a = [2, 5, 10][randi() % 3]
			b = randi_range(2, 10)
			return _num_q("%d × %d = ?" % [a, b], a * b)
		"skip":
			var step: int = [2, 3, 4, 5, 10][randi() % 5]
			var st := randi_range(0, 3) * step
			return _num_q("%d, %d, %d, %d, ?" % [st, st + step, st + 2 * step, st + 3 * step], st + 4 * step)
		"mul":
			a = randi_range(2, 6)
			b = randi_range(2, 9)
			return _num_q("%d × %d = ?" % [a, b], a * b)
		"div_easy":
			a = randi_range(2, 5)
			b = randi_range(2, 9)
			return _num_q("%d ÷ %d = ?" % [a * b, a], b)
		"word":
			a = randi_range(6, 20)
			b = randi_range(3, 15)
			var names := ["Pietro", "Lia", "Davi", "Sofia", "Theo"]
			var nm: String = names[randi() % names.size()]
			if randi() % 2 == 0:
				return _num_q("%s tinha %d figurinhas e ganhou mais %d. Com quantas ficou?" % [nm, a, b], a + b)
			return _num_q("%s tinha %d balas e deu %d para um amigo. Com quantas ficou?" % [nm, a + b, b], a)
		"mul9":
			a = randi_range(2, 9)
			b = randi_range(6, 9)
			return _num_q("%d × %d = ?" % [a, b], a * b)
		"div":
			a = randi_range(3, 9)
			b = randi_range(3, 9)
			return _num_q("%d ÷ %d = ?" % [a * b, a], b)
		"double_half":
			a = randi_range(5, 40) * 2
			if randi() % 2 == 0:
				return _num_q("Qual é o dobro de %d?" % (a / 2), a)
			return _num_q("Qual é a metade de %d?" % a, a / 2)
		"two_step":
			a = randi_range(2, 9)
			b = randi_range(2, 9)
			var c := randi_range(1, 20)
			return _num_q("%d × %d + %d = ?" % [a, b, c], a * b + c)
		"mul_big":
			a = randi_range(11, 25)
			b = randi_range(2, 5)
			return _num_q("%d × %d = ?" % [a, b], a * b)
		"frac":
			var f: int = [2, 4, 5][randi() % 3]
			var base := f * randi_range(2, 8)
			return _num_q("Quanto é 1/%d de %d?" % [f, base], base / f)
		"square":
			a = randi_range(2, 12)
			return _num_q("Quanto é %d × %d?" % [a, a], a * a)
		"order":
			a = randi_range(2, 9)
			b = randi_range(2, 9)
			var c2 := randi_range(2, 9)
			return _num_q("%d + %d × %d = ?" % [a, b, c2], a + b * c2)
	return _num_q("1 + 1 = ?", 2)

# ---- Lógica -----------------------------------------------------------------------------------------------------------
const ODD_WORD := [
	["Qual NÃO pertence ao grupo?", "cadeira", ["maçã", "banana", "uva"]],
	["Qual NÃO pertence ao grupo?", "cachorro", ["azul", "verde", "vermelho"]],
	["Qual NÃO pertence ao grupo?", "lápis", ["gato", "leão", "cavalo"]],
	["Qual NÃO pertence ao grupo?", "carro", ["rosa", "tulipa", "margarida"]],
	["Qual NÃO pertence ao grupo?", "sol", ["segunda", "terça", "quarta"]],
	["Qual NÃO pertence ao grupo?", "tomate", ["cadeira", "mesa", "sofá"]],
	["Qual NÃO pertence ao grupo?", "peixe", ["pardal", "pombo", "coruja"]],
	["Qual NÃO pertence ao grupo?", "janeiro", ["quadrado", "círculo", "triângulo"]],
]
const ANALOGY := [
	["Pé está para meia, assim como mão está para…", "luva", ["boné", "camisa", "cinto"]],
	["Dia está para claro, assim como noite está para…", "escuro", ["lua", "sono", "estrela"]],
	["Pássaro está para ninho, assim como abelha está para…", "colmeia", ["toca", "estábulo", "curral"]],
	["Peixe está para água, assim como pássaro está para…", "ar", ["chão", "areia", "fogo"]],
	["Quente está para frio, assim como alto está para…", "baixo", ["grande", "longo", "forte"]],
	["Livro está para ler, assim como lápis está para…", "escrever", ["comer", "pular", "dormir"]],
]

static func _rand_icon(exclude: Array = []) -> Dictionary:
	for t in range(30):
		var d := {"kind": PSUI.Icon.KINDS[randi() % PSUI.Icon.KINDS.size()], "color": PALETTE[randi() % PALETTE.size()]}
		var dup := false
		for e in exclude:
			var ed: Dictionary = e
			if ed["kind"] == d["kind"] and ed["color"] == d["color"]:
				dup = true
		if not dup:
			return d
	return {"kind": "circle", "color": Color.RED}

static func _icon_options(correct: Dictionary, extras: Array) -> Dictionary:
	var items: Array = [correct]
	for e in extras:
		var ed: Dictionary = e
		var dup := false
		for it in items:
			var itd: Dictionary = it
			if itd["kind"] == ed["kind"] and itd["color"] == ed["color"]:
				dup = true
		if not dup and items.size() < 4:
			items.append(ed)
	while items.size() < 4:
		items.append(_rand_icon(items))
	items.shuffle()
	var options: Array = []
	var ans := 0
	for i in range(items.size()):
		var d: Dictionary = items[i]
		options.append({"icon": d["kind"], "color": d["color"], "text": ""})
		if d["kind"] == correct["kind"] and d["color"] == correct["color"]:
			ans = i
	return {"options": options, "answer": ans}

static func _logic(level: int, count: int) -> Array:
	var out: Array = []
	var seen := {}
	var guard := 0
	while out.size() < count and guard < 200:
		guard += 1
		var q := _logic_one(level)
		var key := str(q["prompt"]) + str(q.get("seq", ""))
		if seen.has(key):
			continue
		seen[key] = true
		out.append(q)
	return out

static func _logic_one(level: int) -> Dictionary:
	var pool: Array = []
	if level <= 3:
		pool = ["pattern", "pattern", "odd", "numseq"]
	elif level <= 6:
		pool = ["pattern", "numseq", "numseq", "oddword", "odd"]
	else:
		pool = ["pattern3", "numseq2", "oddword", "analogy", "numseq2", "pattern3"]
	var kind: String = pool[randi() % pool.size()]
	match kind:
		"pattern", "pattern3":
			var A := _rand_icon()
			var B := _rand_icon([A])
			var C := _rand_icon([A, B])
			var unit: Array = []
			if kind == "pattern":
				unit = [A, B] if randi() % 2 == 0 else [A, A, B]
			else:
				unit = [A, B, C] if randi() % 2 == 0 else [A, A, B, B]
			var seq: Array = []
			for i in range(unit.size() * 2 + 1 + (1 if unit.size() < 3 else 0)):
				seq.append(unit[i % unit.size()])
			var correct: Dictionary = seq.pop_back()
			seq.append(null)
			var extras: Array = [A, B, C]
			var oq := _icon_options(correct, extras)
			return {"prompt": "O que vem no lugar do ?", "seq": seq, "options": oq["options"], "answer": oq["answer"]}
		"odd":
			var base := _rand_icon()
			var diff := {"kind": base["kind"], "color": base["color"]}
			while diff["kind"] == base["kind"]:
				diff["kind"] = PSUI.Icon.KINDS[randi() % PSUI.Icon.KINDS.size()]
			var items: Array = [base, base, base, diff]
			items.shuffle()
			var options: Array = []
			var ans := 0
			for i in range(4):
				var d: Dictionary = items[i]
				options.append({"icon": d["kind"], "color": d["color"], "text": ""})
				if d["kind"] == diff["kind"]:
					ans = i
			return {"prompt": "Qual figura é diferente das outras?", "options": options, "answer": ans}
		"numseq":
			var step: int = [1, 2, 3, 4, 5, 10][randi() % 6]
			var s0 := randi_range(0, 10)
			var down := level >= 4 and randi() % 3 == 0
			var terms: Array = []
			for i in range(5):
				terms.append(s0 + step * i if not down else s0 + step * (5 - i) )
			var ans_v: int = terms.pop_back()
			return _num_q("Complete: %s, ?" % ", ".join(PackedStringArray(terms.map(func(x): return str(x)))), ans_v)
		"numseq2":
			var t := randi() % 4
			var terms2: Array = []
			var nxt := 0
			if t == 0:
				terms2 = [1, 2, 4, 8, 16]
				nxt = 32
			elif t == 1:
				terms2 = [1, 4, 9, 16, 25]
				nxt = 36
			elif t == 2:
				var s1 := randi_range(1, 6)
				terms2 = [s1, s1 + 2, s1 + 3, s1 + 5, s1 + 6]
				nxt = s1 + 8
			else:
				terms2 = [1, 1, 2, 3, 5]
				nxt = 8
			return _num_q("Qual número vem depois: %s, ?" % ", ".join(PackedStringArray(terms2.map(func(x): return str(x)))), nxt)
		"oddword":
			var o: Array = ODD_WORD[randi() % ODD_WORD.size()]
			return _mc(str(o[0]), str(o[1]), o[2])
	var an: Array = ANALOGY[randi() % ANALOGY.size()]
	return _mc(str(an[0]), str(an[1]), an[2])

# ---- Soletração ------------------------------------------------------------------------------------------------------------
const SPELL := [
	["cat", "gato"], ["dog", "cachorro"], ["sun", "sol"], ["pig", "porco"], ["bus", "ônibus"], ["hat", "chapéu"], ["cup", "copo"], ["bed", "cama"],
	["pen", "caneta"], ["egg", "ovo"], ["car", "carro"], ["bag", "bolsa"], ["box", "caixa"], ["key", "chave"], ["toy", "brinquedo"], ["sky", "céu"],
	["leg", "perna"], ["arm", "braço"], ["ear", "orelha"], ["fox", "raposa"],
	["bear", "urso"], ["fish", "peixe"], ["bird", "pássaro"], ["duck", "pato"], ["frog", "sapo"], ["lion", "leão"], ["milk", "leite"], ["book", "livro"],
	["door", "porta"], ["tree", "árvore"], ["moon", "lua"], ["star", "estrela"], ["hand", "mão"], ["nose", "nariz"], ["rain", "chuva"], ["ball", "bola"],
	["cake", "bolo"], ["shoe", "sapato"], ["king", "rei"], ["blue", "azul"], ["farm", "fazenda"], ["fork", "garfo"],
	["apple", "maçã"], ["bread", "pão"], ["house", "casa"], ["water", "água"], ["mouse", "rato"], ["panda", "panda"], ["tiger", "tigre"], ["horse", "cavalo"],
	["sheep", "ovelha"], ["snake", "cobra"], ["shark", "tubarão"], ["eagle", "águia"], ["zebra", "zebra"], ["chair", "cadeira"], ["table", "mesa"],
	["spoon", "colher"], ["plant", "planta"], ["cloud", "nuvem"], ["grape", "uva"], ["lemon", "limão"], ["pizza", "pizza"], ["smile", "sorriso"],
	["happy", "feliz"], ["green", "verde"], ["black", "preto"], ["white", "branco"], ["brown", "marrom"], ["sleep", "dormir"], ["koala", "coala"],
	["banana", "banana"], ["orange", "laranja"], ["school", "escola"], ["friend", "amigo"], ["flower", "flor"], ["monkey", "macaco"], ["rabbit", "coelho"],
	["turtle", "tartaruga"], ["window", "janela"], ["family", "família"], ["mother", "mãe"], ["father", "pai"], ["sister", "irmã"], ["yellow", "amarelo"],
	["purple", "roxo"], ["circle", "círculo"], ["pencil", "lápis"], ["summer", "verão"], ["winter", "inverno"], ["garden", "jardim"], ["cheese", "queijo"],
	["penguin", "pinguim"], ["giraffe", "girafa"], ["dolphin", "golfinho"], ["teacher", "professor"], ["brother", "irmão"], ["rainbow", "arco-íris"],
	["elephant", "elefante"], ["bicycle", "bicicleta"], ["kitchen", "cozinha"], ["morning", "manhã"], ["chicken", "galinha"], ["unicorn", "unicórnio"],
]

static func spelling_words(level: int, count: int = 10) -> Array:
	var lo := 3
	var hi := 3
	if level <= 2:
		lo = 3
		hi = 3
	elif level <= 4:
		lo = 4
		hi = 4
	elif level <= 6:
		lo = 5
		hi = 5
	elif level <= 8:
		lo = 6
		hi = 6
	else:
		lo = 7
		hi = 9
	var pool: Array = []
	for w in SPELL:
		var wi: Array = w
		var n := str(wi[0]).length()
		if n >= lo and n <= hi:
			pool.append(wi)
	pool.shuffle()
	var out: Array = []
	for i in range(mini(count, pool.size())):
		var wi2: Array = pool[i]
		var en := str(wi2[0])
		var letters: Array = []
		for ch in en:
			letters.append(ch)
		var extras := clampi(level / 3, 0, 3)
		var alphabet := "abcdefghijklmnopqrstuvwxyz"
		for k in range(extras):
			letters.append(alphabet[randi() % alphabet.length()])
		letters.shuffle()
		out.append({"word": en, "pt": wi2[1], "image": _animal_id(en), "letters": letters})
	return out
