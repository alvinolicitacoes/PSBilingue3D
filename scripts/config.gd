extends RefCounted
class_name PSConfig
## Constantes globais do mundo e dados das atividades.

const ISLAND_R := 64.0
const PARK_R := 21.5
const ROAD_IN := 23.0
const ROAD_OUT := 28.0
const SIDEWALK_OUT := 29.5
const BUILD_R := 37.0
const WALK_LIMIT := 46.0

# Todos os modelos GLB seguem a convenção glTF (frente = +Z). Se no seu Godot os modelos
# aparecerem de costas, ative "Corrigir direção dos modelos" no menu de opções (ou mude aqui).
static var glb_flip := false

static func glb_yaw() -> float:
	return PI if glb_flip else 0.0

const ANIMALS := ["bear", "cat", "chick", "crocodile", "dog", "elephant", "fox", "koala", "lion", "panda", "penguin", "pig", "rabbit", "shark", "unicorn"]
const ANIMAL_EN := {"bear": "bear", "cat": "cat", "chick": "chick", "crocodile": "crocodile", "dog": "dog", "elephant": "elephant", "fox": "fox", "koala": "koala", "lion": "lion", "panda": "panda", "penguin": "penguin", "pig": "pig", "rabbit": "rabbit", "shark": "shark", "unicorn": "unicorn"}
const ANIMAL_PT := {"bear": "urso", "cat": "gato", "chick": "pintinho", "crocodile": "crocodilo", "dog": "cachorro", "elephant": "elefante", "fox": "raposa", "koala": "coala", "lion": "leão", "panda": "panda", "penguin": "pinguim", "pig": "porco", "rabbit": "coelho", "shark": "tubarão", "unicorn": "unicórnio"}

# Ordem = sentido horário a partir do norte; atividades parecidas ficam vizinhas.
const PLACES := [
	{"name": "Inglês", "token": "ABC", "color": Color("4f9dff"), "tag": "Palavras em inglês"},
	{"name": "Frases", "token": "Hi!", "color": Color("f2b705"), "tag": "Frases do dia a dia"},
	{"name": "Soletração", "token": "A-B-C", "color": Color("22b8b0"), "tag": "Monte as palavras"},
	{"name": "Português", "token": "Aa", "color": Color("ff7a6b"), "tag": "Nossa língua"},
	{"name": "Matemática", "token": "+ ×", "color": Color("ff9f1c"), "tag": "Números e contas"},
	{"name": "Lógica", "token": "1 2 ?", "color": Color("8f6bff"), "tag": "Padrões e sequências"},
	{"name": "Sudoku", "token": "9", "color": Color("2fc27f"), "tag": "Complete a grade"},
	{"name": "Memória", "token": "? ?", "color": Color("ee6bd0"), "tag": "Encontre os pares"},
	{"name": "Cores", "token": "RGB", "color": Color("e2554f"), "tag": "Cores em inglês"},
	{"name": "Animais", "token": "Zoo", "color": Color("b07a3c"), "tag": "Bichinhos do mundo"},
	{"name": "Ciências", "token": "H2O", "color": Color("3aa0d8"), "tag": "Descubra a natureza"},
	{"name": "Geografia", "token": "N S", "color": Color("5db35a"), "tag": "Países e mapas"},
]

static func place_pos(i: int, radius: float = BUILD_R) -> Vector3:
	var a := deg_to_rad(float(i) * 30.0)
	return Vector3(sin(a) * radius, 0.0, -cos(a) * radius)

## Yaw (rotation.y) para que o +Z local de um nó em `from` aponte para `to`.
static func yaw_to(from: Vector3, to: Vector3) -> float:
	var d := to - from
	return atan2(d.x, d.z)
