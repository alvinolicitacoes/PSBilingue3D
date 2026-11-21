extends Control
class_name PSPronunciation
## Laboratório de fala: escuta, grava e reproduz a voz da criança.
## IMPORTANTE: não atribui nota automática sem um motor de reconhecimento validado.

signal closed

const NAVY := Color("1d2b53")
const LEVEL_NAMES := ["Fácil", "Intermediário", "Desafio"]
var _language := "en"
var _level := 0
var _index := 0
var _phrases: Array = []
var _recording: AudioEffectRecord
var _microphone: AudioStreamPlayer
var _playback: AudioStreamPlayer
var _recorded: AudioStreamWAV
var _recording_active := false
var _bus_index := -1
var _title: Label
var _translation: Label
var _status: Label
var _record_button: Button
var _listen_button: Button
var _evaluate_button: Button
var _recognizers: Dictionary = {}
var _effect_index := -1
var _closing := false
var _models: Dictionary = {}
const MODEL_PATHS := {"en": "res://assets/speech/vosk-model-small-en-us-0.15.vosk", "pt": "res://assets/speech/vosk-model-small-pt-0.3.vosk"}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("e8f2eb")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Botão fixo: permanece visível mesmo quando o painel excede a altura da tela.
	var back := Button.new()
	back.text = "← Voltar ao mapa"
	back.custom_minimum_size = Vector2(185, 48)
	back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back.position = Vector2(16, 12)
	back.z_index = 10
	add_child(back)
	back.pressed.connect(_close_practice)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(520, 0)
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	stack.add_child(PSUI.label("Minha Pronúncia", 36, NAVY))
	var language_row := HBoxContainer.new()
	stack.add_child(language_row)
	for lang in ["en", "pt"]:
		var language_button := Button.new()
		language_button.text = "🇺🇸 Inglês" if lang == "en" else "🇧🇷 Português"
		language_row.add_child(language_button)
		language_button.pressed.connect(_select_language.bind(lang))
	var level_row := HBoxContainer.new()
	stack.add_child(level_row)
	for i in range(3):
		var b := Button.new()
		b.text = LEVEL_NAMES[i]
		level_row.add_child(b)
		b.pressed.connect(_select_level.bind(i))
	_title = PSUI.label("", 27, NAVY)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_title)
	_translation = PSUI.label("", 21, Color("45616b"))
	_translation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_translation)
	var hear_en := Button.new()
	hear_en.text = "🔊 Ouvir em inglês"
	stack.add_child(hear_en)
	hear_en.pressed.connect(func(): PSAudio.speak(str(_phrases[_index]["en"]), "en"))
	var hear_pt := Button.new()
	hear_pt.text = "🔊 Ouvir em português"
	stack.add_child(hear_pt)
	hear_pt.pressed.connect(func(): PSAudio.speak(str(_phrases[_index]["pt"]), "pt"))
	_record_button = Button.new()
	_record_button.text = "🎤 Começar gravação"
	stack.add_child(_record_button)
	_record_button.pressed.connect(_toggle_record)
	_listen_button = Button.new()
	_listen_button.text = "▶ Ouvir minha gravação"
	_listen_button.disabled = true
	stack.add_child(_listen_button)
	_listen_button.pressed.connect(_listen)
	_evaluate_button = Button.new()
	_evaluate_button.text = "✅ Corrigir minha fala"
	_evaluate_button.disabled = true
	stack.add_child(_evaluate_button)
	_evaluate_button.pressed.connect(_evaluate_recording)
	_status = PSUI.label("Ouça, fale e compare sua gravação com o modelo.", 18, NAVY)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_status)
	var next := Button.new()
	next.text = "Próxima frase"
	stack.add_child(next)
	next.pressed.connect(_next)
	var close := Button.new()
	close.text = "Voltar à cidade"
	stack.add_child(close)
	close.pressed.connect(_close_practice)
	_setup_microphone()
	_select_level(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_practice()

func _close_practice() -> void:
	if _closing:
		return
	_closing = true
	_stop_record()
	if _playback != null:
		_playback.stop()
	closed.emit()

func _setup_microphone() -> void:
	if not AudioServer.get_input_device_list().is_empty():
		_bus_index = AudioServer.get_bus_index("Gravacao")
		if _bus_index == -1:
			AudioServer.add_bus()
			_bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(_bus_index, "Gravacao")
		AudioServer.set_bus_mute(_bus_index, true)
		_recording = AudioEffectRecord.new()
		AudioServer.add_bus_effect(_bus_index, _recording)
		_effect_index = AudioServer.get_bus_effect_count(_bus_index) - 1
		_microphone = AudioStreamPlayer.new()
		_microphone.bus = "Gravacao"
		_microphone.stream = AudioStreamMicrophone.new()
		add_child(_microphone)
		_playback = AudioStreamPlayer.new()
		add_child(_playback)
	else:
		_record_button.disabled = true
		_status.text = "Microfone indisponível. Verifique a permissão de acesso ao microfone."

func _exit_tree() -> void:
	_stop_record()
	if _bus_index >= 0 and _recording != null:
		for i in range(AudioServer.get_bus_effect_count(_bus_index) - 1, -1, -1):
			if AudioServer.get_bus_effect(_bus_index, i) == _recording:
				AudioServer.remove_bus_effect(_bus_index, i)
				break

func _select_language(lang: String) -> void:
	_language = lang
	_select_level(_level)

func _select_level(value: int) -> void:
	_stop_record()
	_level = value
	_index = 0
	_phrases.clear()
	for p in PSNpc.all_phrases():
		if int(p.get("level", 1)) == value + 1:
			_phrases.append(p)
	_phrases.shuffle()
	if _phrases.size() > 10:
		_phrases.resize(10)
	_show_phrase()

func _show_phrase() -> void:
	if _phrases.is_empty():
		return
	_recorded = null
	_listen_button.disabled = true
	_evaluate_button.disabled = true
	_title.text = "%d/10 • %s" % [_index + 1, str(_phrases[_index][_language])]
	_translation.text = str(_phrases[_index]["pt" if _language == "en" else "en"])
	_status.text = "Ouça, grave sua voz e compare. Ouça e grave. A correção compara as palavras reconhecidas, não a precisão dos sons."

func _toggle_record() -> void:
	if _recording_active:
		_stop_record()
		return
	if _recording == null or _microphone == null:
		return
	_recorded = null
	_listen_button.disabled = true
	_evaluate_button.disabled = true
	_recording.set_recording_active(true)
	_microphone.play()
	_recording_active = true
	_record_button.text = "⏹ Parar gravação"
	_status.text = "Gravando... fale a frase e toque em Parar."

func _stop_record() -> void:
	if not _recording_active:
		return
	_recording.set_recording_active(false)
	_recorded = _recording.get_recording()
	_microphone.stop()
	_recording_active = false
	_record_button.text = "🎤 Gravar novamente"
	_listen_button.disabled = _recorded == null
	_evaluate_button.disabled = _recorded == null or not _recognition_available()
	_status.text = "Gravação concluída. Ouça sua voz e compare com a pronúncia."

func _listen() -> void:
	if _recorded == null:
		return
	_playback.stop()
	_playback.stream = _recorded
	_playback.play()

func _next() -> void:
	_stop_record()
	if _phrases.is_empty():
		return
	_index = (_index + 1) % _phrases.size()
	_show_phrase()

func _recognition_available() -> bool:
	return ClassDB.class_exists("VoskRecognizer") and ClassDB.class_exists("VoskModel") and ResourceLoader.exists(str(MODEL_PATHS[_language]))

func _get_model() -> Resource:
	if _models.has(_language):
		return _models[_language]
	var path := str(MODEL_PATHS[_language])
	if not ResourceLoader.exists(path):
		return null
	var model := ResourceLoader.load(path)
	if model != null:
		_models[_language] = model
	return model

func _evaluate_recording() -> void:
	if _recorded == null or _phrases.is_empty():
		return
	if not ClassDB.class_exists("VoskRecognizer") or not ClassDB.class_exists("VoskModel"):
		_status.text = "GDVOSK não carregou. Confira as bibliotecas da extensão."
		return
	if not _recognition_available():
		_status.text = "Modelo %s ausente. Coloque o ZIP renomeado para .vosk em assets/speech." % _language.to_upper()
		return
	_evaluate_button.disabled = true
	_status.text = "Reconhecendo sua fala offline..."
	await get_tree().process_frame
	var model := _get_model()
	if model == null:
		_status.text = "Não foi possível carregar o modelo de voz."
		_evaluate_button.disabled = false
		return
	var recognizer: Object = ClassDB.instantiate("VoskRecognizer")
	if recognizer == null:
		_status.text = "Falha ao criar reconhecedor GDVOSK."
		_evaluate_button.disabled = false
		return
	var error_code: int = recognizer.call("setup", model, int(_recorded.mix_rate), null)
	if error_code != OK:
		_status.text = "Falha ao configurar o reconhecimento (código %d)." % error_code
		_evaluate_button.disabled = false
		return
	recognizer.call("accept_stream", _recorded)
	var result: Dictionary = recognizer.call("get_final_result")
	var recognized := str(result.get("text", "")).strip_edges()
	var expected := str(_phrases[_index][_language])
	if recognized.is_empty():
		_status.text = "Não identifiquei palavras. Fale perto do microfone e tente novamente."
	else:
		var score := _word_similarity(expected, recognized)
		PSProgress.pronunciation_result(_language, _level + 1, expected, score)
		var best := roundi(PSProgress.pronunciation_best(_language, _level + 1, expected) * 100.0)
		if score >= 0.85:
			_status.text = "Muito bem! Reconheci: '%s'. Palavras: %d%% (melhor: %d%%)." % [recognized, roundi(score * 100), best]
		else:
			_status.text = "Reconheci: '%s'. Esperado: '%s'. Palavras: %d%% (melhor: %d%%). Tente novamente!" % [recognized, expected, roundi(score * 100), best]
	_evaluate_button.disabled = false

func _word_similarity(expected: String, recognized: String) -> float:
	var clean := RegEx.new()
	clean.compile("[^a-z0-9áàâãéêíóôõúüç ]")
	var a := clean.sub(expected.to_lower(), "", true).split(" ", false)
	var b := clean.sub(recognized.to_lower(), "", true).split(" ", false)
	if a.is_empty() or b.is_empty():
		return 0.0
	var previous: Array[int] = []
	for j in range(b.size() + 1):
		previous.append(j)
	for i in range(a.size()):
		var current: Array[int] = [i + 1]
		for j in range(b.size()):
			var cost := 0 if a[i] == b[j] else 1
			current.append(mini(mini(previous[j + 1] + 1, current[j] + 1), previous[j] + cost))
		previous = current
	return clampf(1.0 - float(previous[b.size()]) / float(maxi(a.size(), b.size())), 0.0, 1.0)
