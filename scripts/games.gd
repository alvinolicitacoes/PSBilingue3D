extends Control
class_name PSGames

signal exit_game

var mode := "Memória"
var level := 1
var question_index := 0
var correct_count := 0
var mistakes := 0
var selected := -1
var flipped: Array[int] = []
var matched: Array[int] = []
var deck: Array[int] = []
var sudoku_solution: Array[int] = []
var sudoku_board: Array[int] = []
var sudoku_fixed: Array[bool] = []
var sudoku_size := 4
var cells: Array[Button] = []
var busy := false
var title_label: Label
var status_label: Label
var board_grid: GridContainer
var body: VBoxContainer
var delay_timer: Timer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.07, 0.11, 0.22, 0.96)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)
    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 20)
    scroll.add_child(margin)
    body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 14)
    margin.add_child(body)
    var top := HBoxContainer.new()
    body.add_child(top)
    _button(top, "← Voltar ao mundo", func(): exit_game.emit())
    title_label = _label(body, "", 35)
    status_label = _label(body, "", 21)
    delay_timer = Timer.new()
    delay_timer.one_shot = true
    add_child(delay_timer)
    start_level()

func _label(parent: Node, value: String, font_size: int = 24) -> Label:
    var l := Label.new()
    l.text = value
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color("fef7e9"))
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _button(parent: Node, caption: String, action: Callable, min_height: float = 52) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(0, min_height)
    b.add_theme_font_size_override("font_size", 21)
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _clear_content() -> void:
    for i in range(body.get_child_count() - 1, 2, -1):
        body.get_child(i).queue_free()
    cells.clear()

func start_level() -> void:
    busy = false
    question_index = 0
    correct_count = 0
    mistakes = 0
    _clear_content()
    title_label.text = "%s  •  Nível %d/10" % [mode, level]
    status_label.text = ""
    if mode == "Memória":
        _start_memory()
    elif mode == "Sudoku":
        _start_sudoku()
    else:
        _start_quiz()

func _start_memory() -> void:
    var sizes := [2, 2, 4, 4, 6, 6, 8, 8, 10, 10]
    var side: int = sizes[level-1]
    var pair_count: int = int(side * side / 2)
    deck.clear()
    flipped.clear()
    matched.clear()
    for i in range(pair_count):
        deck.append(i)
        deck.append(i)
    deck.shuffle()
    status_label.text = "%d × %d  •  %d pares  •  Encontre todas as combinações" % [side,side,pair_count]
    var board := GridContainer.new()
    board.columns = side
    board_grid = board
    body.add_child(board)
    var icons := ["🐶", "🐱", "🐸", "🦊", "🐼", "🐯", "🐨", "🐵", "🐧", "🐢", "🦋", "🐝", "🐬", "🐳", "🦄", "🐷", "🐮", "🐴", "🦁", "🐻", "🦜", "🐠", "🦀", "🦕", "🦖", "🦉", "🐰", "🦓", "🦒", "🐘", "🦛", "🦏", "🐊", "🐍", "🦎", "🦩", "🦚", "🐿", "🦔", "🦦", "🦥", "🦘", "🦙", "🐐", "🐑", "🦌", "🐺", "🐔", "🦇", "🐞"]
    for i in range(deck.size()):
        var b := Button.new()
        b.text = "?"
        b.custom_minimum_size = Vector2(56 if side >= 8 else 76, 48 if side >= 8 else 70)
        b.add_theme_font_size_override("font_size", 24 if side < 8 else 18)
        b.pressed.connect(_flip.bind(i, icons))
        board.add_child(b)
        cells.append(b)
    _button(body, "Reiniciar nível", start_level)

func _flip(i: int, icons: Array) -> void:
    if busy or matched.has(i) or flipped.has(i):
        return
    cells[i].text = str(icons[deck[i] % icons.size()])
    flipped.append(i)
    if flipped.size() == 2:
        if deck[flipped[0]] == deck[flipped[1]]:
            matched.append_array(flipped)
            flipped.clear()
            status_label.text = "%d/%d pares encontrados" % [matched.size()/2, deck.size()/2]
            if matched.size() == deck.size():
                _win()
        else:
            mistakes += 1
            busy = true
            var first := flipped[0]
            var second := flipped[1]
            get_tree().create_timer(0.9).timeout.connect(func():
                if is_instance_valid(self) and first < cells.size() and is_instance_valid(cells[first]):
                    cells[first].text = "?"
                    cells[second].text = "?"
                    flipped.clear()
                    busy = false
            )

func _start_sudoku() -> void:
    sudoku_size = 4 if level <= 3 else (6 if level <= 6 else 9)
    var n := sudoku_size
    var box_rows := 2 if n == 4 or n == 6 else 3
    var box_cols: int = int(n / box_rows)
    var seed := level * 101 + randi_range(0, 100000)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    sudoku_solution.clear()
    sudoku_board.clear()
    sudoku_fixed.clear()
    var digits: Array[int] = []
    for i in range(n):
        digits.append(i + 1)
    digits.shuffle()
    for row in range(n):
        for col in range(n):
            var pattern := (box_cols * (row % box_rows) + int(row / box_rows) + col) % n
            sudoku_solution.append(digits[pattern])
    var clues: int = maxi(int(n*n/3), n*n - (level+3)*4)
    var indices := range(n*n)
    indices.shuffle()
    for i in range(n*n):
        var fixed: bool = i < clues
        sudoku_fixed.append(fixed)
        sudoku_board.append(sudoku_solution[indices[i]] if fixed else 0)
    # Permutação da ordem de pistas sem alterar as coordenadas do tabuleiro.
    sudoku_board.clear()
    sudoku_fixed.clear()
    for i in range(n*n):
        var fixed: bool = indices.find(i) < clues
        sudoku_fixed.append(fixed)
        sudoku_board.append(sudoku_solution[i] if fixed else 0)
    status_label.text = "%d×%d • Toque numa casa vazia e escolha o número" % [n,n]
    var board := GridContainer.new()
    board.columns = n
    body.add_child(board)
    for i in range(n*n):
        var b := Button.new()
        b.custom_minimum_size = Vector2(52 if n >= 9 else 75, 52 if n >= 9 else 70)
        b.text = str(sudoku_board[i]) if sudoku_board[i] != 0 else "·"
        b.disabled = sudoku_fixed[i]
        b.add_theme_font_size_override("font_size", 24)
        b.pressed.connect(_select_cell.bind(i))
        board.add_child(b)
        cells.append(b)
    var row := HBoxContainer.new()
    body.add_child(row)
    for value in range(1,n+1):
        _button(row, str(value), _enter_number.bind(value), 48)
    _button(row, "Apagar", _enter_number.bind(0), 48)
    _button(body, "✓ Verificar solução", _verify_sudoku)
    _button(body, "Novo tabuleiro", start_level)

func _select_cell(i: int) -> void:
    selected = i
    status_label.text = "Casa %d, coluna %d selecionada" % [int(i / sudoku_size)+1, i%sudoku_size+1]

func _enter_number(value: int) -> void:
    if selected < 0 or selected >= sudoku_board.size() or sudoku_fixed[selected]:
        status_label.text = "Selecione primeiro uma casa vazia."
        return
    sudoku_board[selected] = value
    cells[selected].text = str(value) if value > 0 else "·"

func _verify_sudoku() -> void:
    var n := sudoku_size
    if sudoku_board.has(0):
        status_label.text = "Ainda existem casas vazias. Continue!"
        return
    var box_rows := 2 if n <= 6 else 3
    var box_cols := int(n / box_rows)
    for r in range(n):
        var row_values: Array = []
        var col_values: Array = []
        for c in range(n):
            row_values.append(sudoku_board[r*n+c])
            col_values.append(sudoku_board[c*n+r])
        if _invalid_set(row_values,n) or _invalid_set(col_values,n):
            status_label.text = "Há números repetidos numa linha ou coluna."
            return
    for br in range(0,n,box_rows):
        for bc in range(0,n,box_cols):
            var values: Array = []
            for dr in range(box_rows):
                for dc in range(box_cols):
                    values.append(sudoku_board[(br+dr)*n+bc+dc])
            if _invalid_set(values,n):
                status_label.text = "Há números repetidos em uma região."
                return
    _win()

func _invalid_set(values: Array, n: int) -> bool:
    var seen := {}
    for v in values:
        if int(v) < 1 or int(v) > n or seen.has(v):
            return true
        seen[v] = true
    return false

func _start_quiz() -> void:
    _show_question()

func _show_question() -> void:
    _clear_content()
    status_label.text = "Questão %d/10  •  Acertos: %d" % [question_index+1, correct_count]
    var topic := PSContent.TOPICS.find(mode)
    var q := PSContent.question(topic, level, question_index)
    _label(body, str(q["prompt"]), 29)
    for option in q["options"]:
        _button(body, str(option), _answer.bind(str(option), str(q["answer"])), 64)

func _answer(value: String, answer: String) -> void:
    if busy:
        return
    busy = true
    if value == answer:
        correct_count += 1
        status_label.text = "Muito bem! Resposta correta."
    else:
        mistakes += 1
        status_label.text = "A resposta correta era: %s" % answer
    get_tree().create_timer(0.8).timeout.connect(func():
        if not is_instance_valid(self):
            return
        busy = false
        question_index += 1
        if question_index >= 10:
            _finish_quiz()
        else:
            _show_question()
    )

func _finish_quiz() -> void:
    _clear_content()
    if correct_count >= 7:
        _win()
    else:
        status_label.text = "Você acertou %d/10. Tente novamente para ganhar estrelas!" % correct_count
        _button(body, "Tentar novamente", start_level)

func _win() -> void:
    busy = true
    var stars := 3 if mistakes == 0 else (2 if mistakes <= 3 else 1)
    var data := PSProgress.complete(mode, level, stars)
    status_label.text = "🎉 Parabéns! %d estrela(s)! Total: %d ⭐" % [stars, int(data.get("stars",0))]
    _button(body, "Jogar novamente", start_level)
    if level < 10:
        _button(body, "Próximo nível →", func(): level += 1; start_level())
    else:
        _button(body, "Voltar ao mundo", func(): exit_game.emit())
