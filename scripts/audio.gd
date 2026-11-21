extends Node
class_name PSAudio
## Central de áudio: efeitos (WAV pré-sintetizados), músicas em loop, ambiente e leitura em voz alta (TTS do sistema).

static var inst: PSAudio = null

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _fountain: AudioStreamPlayer
var _cache: Dictionary = {}
var _music_name := ""
var _music_tween: Tween
var _bus_music := 0
var _bus_sfx := 0
var tts_voice_en := ""
var tts_voice_pt := ""
var tts_enabled := true
var tts_available := false
var _voice_manifests: Dictionary = {}
var _voice_player: AudioStreamPlayer

func _ready() -> void:
	inst = self
	_bus_music = _make_bus("Musica")
	_bus_sfx = _make_bus("Efeitos")
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Efeitos"
		add_child(p)
		_sfx_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Musica"
	add_child(_music)
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = "Efeitos"
	_ambient.volume_db = -10.0
	add_child(_ambient)
	_fountain = AudioStreamPlayer.new()
	_fountain.bus = "Efeitos"
	_fountain.volume_db = -22.0
	add_child(_fountain)
	set_music_volume(float(PSProgress.setting("music_vol", 0.55)))
	set_sfx_volume(float(PSProgress.setting("sfx_vol", 0.9)))
	tts_enabled = bool(PSProgress.setting("voice", true))
	_setup_tts()
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Efeitos"
	add_child(_voice_player)
	_load_voice_manifest()

func _make_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx

func _setup_tts() -> void:
	tts_available = false
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices: Array = DisplayServer.tts_get_voices()
	for v in voices:
		var d: Dictionary = v
		var lang := str(d.get("language", "")).replace("-", "_").to_lower()
		if tts_voice_en == "" and lang.begins_with("en"):
			tts_voice_en = str(d.get("id", ""))
		if lang.begins_with("pt") and (tts_voice_pt == "" or lang.begins_with("pt_br")):
			tts_voice_pt = str(d.get("id", ""))
	tts_available = tts_voice_en != ""
	if not tts_available:
		push_warning("Nenhuma voz inglesa encontrada no sistema. Instale uma voz English em Configurações > Hora e idioma > Fala.")

func _load_voice_manifest() -> void:
	for lang in ["en", "pt"]:
		var manifest_path: String = "res://assets/voice/" + str(lang) + "/manifest.json"
		if not FileAccess.file_exists(manifest_path):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if data is Dictionary:
			_voice_manifests[lang] = data.get("items", {})

func _play_recorded_voice(text: String, lang: String) -> bool:
	if not _voice_manifests.has(lang):
		return false
	var manifest: Dictionary = _voice_manifests[lang]
	if not manifest.has(text):
		return false
	var path: String = "res://assets/voice/" + lang + "/" + str(manifest[text])
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		return false
	_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.play()
	return true

func _load(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var path := "res://assets/audio/%s.wav" % sound
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	if s == null:
		push_warning("Som ausente: " + path)
	_cache[sound] = s
	return s

func _loop(stream: AudioStream) -> AudioStream:
	var w := stream as AudioStreamWAV
	if w != null:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.data.size() / 2)
	return stream

# ---- API estática (segura mesmo sem instância) --------------------------------
static func sfx(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if inst != null:
		inst._play_sfx(sound, volume_db, pitch)

static func sfx_rand(prefix: String, count: int, volume_db: float = 0.0) -> void:
	if inst != null:
		inst._play_sfx("%s_%d" % [prefix, randi_range(1, count)], volume_db, randf_range(0.93, 1.07))

static func music(sound: String) -> void:
	if inst != null:
		inst._play_music(sound)

static func ambient(on: bool) -> void:
	if inst != null:
		inst._set_ambient(on)

static func speak(text: String, lang: String = "en") -> void:
	if inst != null:
		inst._speak(text, lang)

static func can_speak() -> bool:
	return inst != null and inst.tts_enabled and (inst.tts_available or not inst._voice_manifests.is_empty())

func _play_sfx(sound: String, volume_db: float, pitch: float) -> void:
	var s := _load(sound)
	if s == null:
		return
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _play_music(sound: String) -> void:
	if sound == _music_name:
		return
	_music_name = sound
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	var s := _load(sound)
	if s == null:
		return
	_loop(s)
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, 0.5)
	_music_tween.tween_callback(_start_music_stream.bind(s))
	_music_tween.tween_property(_music, "volume_db", -6.0, 1.2)

func _start_music_stream(s: AudioStream) -> void:
	_music.stream = s
	_music.volume_db = -40.0
	_music.play()

func _set_ambient(on: bool) -> void:
	if on:
		if not _ambient.playing:
			_ambient.stream = _loop(_load("ambient_city"))
			_ambient.play()
		if not _fountain.playing:
			_fountain.stream = _loop(_load("fountain"))
			_fountain.play()
	else:
		_ambient.stop()
		_fountain.stop()

func _speak(text: String, lang: String) -> void:
	if not tts_enabled:
		return
	if _play_recorded_voice(text, lang):
		return
	if not tts_available:
		push_warning("Pronúncia indisponível: instale uma voz inglesa no sistema operacional.")
		return
	var voice := tts_voice_en if lang == "en" else tts_voice_pt
	if voice == "":
		voice = tts_voice_en
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice, 100, 1.0, 0.9, 0, true)

# ---- volume --------------------------------------------------------------------
func set_music_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(_bus_music, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(_bus_music, v <= 0.001)
	PSProgress.set_setting("music_vol", v)

func set_sfx_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(_bus_sfx, v <= 0.001)
	PSProgress.set_setting("sfx_vol", v)

func set_voice(on: bool) -> void:
	tts_enabled = on
	PSProgress.set_setting("voice", on)

func ducked(on: bool) -> void:
	## Abaixa o ambiente (usado quando um jogo está aberto).
	var target := -40.0 if on else -10.0
	create_tween().tween_property(_ambient, "volume_db", target, 0.4)
