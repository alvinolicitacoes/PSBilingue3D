extends RefCounted
class_name PSContent

const TOPICS := ["Inglês", "Matemática", "Lógica", "Português", "Ciências", "Geografia", "Animais", "Cores", "Frases", "Soletração"]
const WORDS := [
    ["cat", "gato"], ["dog", "cachorro"], ["sun", "sol"], ["moon", "lua"], ["book", "livro"],
    ["water", "água"], ["house", "casa"], ["tree", "árvore"], ["bird", "pássaro"], ["fish", "peixe"],
    ["apple", "maçã"], ["school", "escola"], ["friend", "amigo"], ["happy", "feliz"], ["blue", "azul"],
    ["red", "vermelho"], ["green", "verde"], ["yellow", "amarelo"], ["chair", "cadeira"], ["table", "mesa"],
    ["window", "janela"], ["door", "porta"], ["star", "estrela"], ["flower", "flor"], ["family", "família"],
    ["mother", "mãe"], ["father", "pai"], ["brother", "irmão"], ["sister", "irmã"], ["play", "brincar"],
    ["learn", "aprender"], ["read", "ler"], ["write", "escrever"], ["jump", "pular"], ["run", "correr"],
    ["walk", "andar"], ["small", "pequeno"], ["big", "grande"], ["fast", "rápido"], ["slow", "devagar"],
    ["cold", "frio"], ["hot", "quente"], ["rain", "chuva"], ["cloud", "nuvem"], ["river", "rio"],
    ["mountain", "montanha"], ["beach", "praia"], ["city", "cidade"], ["country", "país"], ["world", "mundo"]
]

static func question(topic: int, level: int, index: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(topic * 100000 + level * 1000 + index * 13 + 101)
    if topic == 1:
        var a := rng.randi_range(1, 5 + level * 3)
        var b := rng.randi_range(1, 5 + level * 2)
        var op := (level + index) % 3
        if op == 0:
            return _number("Quanto é %d + %d?" % [a,b], a+b, rng)
        if op == 1:
            return _number("Quanto é %d - %d?" % [a+b,b], a, rng)
        return _number("Quanto é %d × %d?" % [a,b], a*b, rng)
    if topic == 2:
        var step := rng.randi_range(2, level + 4)
        var start := rng.randi_range(1, 20)
        return _number("Complete: %d, %d, %d, ?" % [start,start+step,start+step*2], start+step*3, rng)
    if topic == 4:
        var facts := [["Qual planeta é conhecido como planeta vermelho?", "Marte", "Terra", "Vênus", "Júpiter"], ["O que as plantas absorvem pelas raízes?", "Água", "Luz", "Vento", "Fogo"], ["Qual órgão bombeia o sangue?", "Coração", "Pulmão", "Estômago", "Rim"], ["Quantas patas tem um inseto?", "6", "4", "8", "10"], ["O gelo é água em estado...", "Sólido", "Gasoso", "Plasma", "Líquido"]]
        return _fact(facts[(index+level)%facts.size()], rng)
    if topic == 5:
        var facts := [["Qual é a capital do Brasil?", "Brasília", "Salvador", "Recife", "São Paulo"], ["Em qual continente fica o Brasil?", "América do Sul", "Europa", "Ásia", "África"], ["Qual é o maior oceano?", "Pacífico", "Atlântico", "Índico", "Ártico"], ["O Sol nasce aproximadamente no...", "Leste", "Oeste", "Norte", "Sul"], ["Qual é o nosso planeta?", "Terra", "Marte", "Saturno", "Netuno"]]
        return _fact(facts[(index+level)%facts.size()], rng)
    if topic == 6:
        var facts := [["Qual animal mia?", "Gato", "Cachorro", "Vaca", "Pato"], ["Qual animal produz mel?", "Abelha", "Formiga", "Borboleta", "Mosca"], ["Qual animal vive na água e tem brânquias?", "Peixe", "Leão", "Cavalo", "Coelho"], ["Qual animal tem tromba?", "Elefante", "Girafa", "Zebra", "Urso"], ["Qual animal é conhecido por seu pescoço longo?", "Girafa", "Tigre", "Lobo", "Raposa"]]
        return _fact(facts[(index+level)%facts.size()], rng)
    if topic == 7:
        var colors := [["red", "vermelho"], ["blue", "azul"], ["green", "verde"], ["yellow", "amarelo"], ["purple", "roxo"], ["orange", "laranja"], ["black", "preto"], ["white", "branco"], ["pink", "rosa"], ["brown", "marrom"]]
        return _translation(colors, (index+level)%colors.size(), rng)
    if topic == 3:
        var facts := [["Qual palavra está escrita corretamente?", "Caderno", "Cadernu", "Caderna", "Cadernou"], ["Qual é o plural de flor?", "Flores", "Florais", "Flors", "Floris"], ["Qual palavra é um verbo?", "Correr", "Azul", "Casa", "Feliz"], ["Qual é o contrário de alto?", "Baixo", "Grande", "Largo", "Forte"], ["Qual palavra tem três sílabas?", "Banana", "Sol", "Flor", "Pé"]]
        return _fact(facts[(index+level)%facts.size()], rng)
    if topic == 8:
        var phrases := [["Good morning", "Bom dia"], ["Thank you", "Obrigado"], ["How are you?", "Como você está?"], ["I love you", "Eu te amo"], ["See you later", "Até mais tarde"], ["My name is Pietro", "Meu nome é Pietro"], ["I am happy", "Estou feliz"], ["Let's play", "Vamos brincar"], ["I like books", "Eu gosto de livros"], ["Good night", "Boa noite"]]
        return _translation(phrases, (index+level)%phrases.size(), rng)
    var word_index := (level * 7 + index * 3 + topic) % WORDS.size()
    if topic == 9:
        var w: String = WORDS[word_index][0]
        var wrong := w + "s"
        return _fact(["Como se escreve '%s' em inglês?" % WORDS[word_index][1], w, wrong, w + "e", w.substr(0,maxi(1,w.length()-1))], rng)
    return _translation(WORDS, word_index, rng)

static func _translation(words: Array, idx: int, rng: RandomNumberGenerator) -> Dictionary:
    var options: Array[String] = [str(words[idx][1])]
    var shift := 1
    while options.size() < 4:
        var candidate := str(words[(idx + shift * 7) % words.size()][1])
        if not options.has(candidate):
            options.append(candidate)
        shift += 1
    options.shuffle()
    return {"prompt": "O que significa '%s'?" % words[idx][0], "answer": str(words[idx][1]), "options": options}

static func _number(prompt: String, answer: int, rng: RandomNumberGenerator) -> Dictionary:
    var options: Array[String] = [str(answer)]
    for offset in [1, 2, 3, 5, 7, 9]:
        var candidate := str(answer + offset)
        if not options.has(candidate):
            options.append(candidate)
        if options.size() == 4:
            break
    options.shuffle()
    return {"prompt": prompt, "answer": str(answer), "options": options}

static func _fact(row: Array, rng: RandomNumberGenerator) -> Dictionary:
    var options: Array[String] = [str(row[1]),str(row[2]),str(row[3]),str(row[4])]
    options.shuffle()
    return {"prompt": row[0], "answer": str(row[1]), "options": options}
