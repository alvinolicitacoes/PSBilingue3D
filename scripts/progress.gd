extends RefCounted
class_name PSProgress
## Progresso salvo em user://psbilingue_progress.json (compatível com a versão anterior).

const PATH := "user://psbilingue_progress.json"
static var _data: Dictionary = {}
static var _loaded := false

static func _default() -> Dictionary:
	return {"stars": 0, "wins": {}, "best": {}, "profile": "Pietro", "settings": {}, "outfit": {}, "quests": {}, "flags": {}}

const BACKUP_PATH := "user://psbilingue_progress.backup.json"
const TEMP_PATH := "user://psbilingue_progress.tmp.json"

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}

static func load_data() -> Dictionary:
	if _loaded:
		return _data
	var primary := _read_json(PATH)
	if primary.is_empty():
		primary = _read_json(BACKUP_PATH)
	_data = _default()
	for key in primary:
		_data[key] = primary[key]
	_loaded = true
	return _data

static func save_data(data: Dictionary = {}) -> void:
	if not _loaded:
		load_data()
	if not data.is_empty():
		_data = data
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("PSProgress: falha ao abrir arquivo temporário: " + str(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(_data, "  "))
	f.flush()
	f.close()
	var temp_data := _read_json(TEMP_PATH)
	if temp_data.is_empty():
		push_error("PSProgress: arquivo temporário inválido; progresso anterior preservado")
		return
	if FileAccess.file_exists(PATH) and not _read_json(PATH).is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(PATH))
	if result != OK:
		push_error("PSProgress: falha ao salvar progresso, código " + str(result))

static func pronunciation_result(lang: String, level: int, phrase: String, score: float) -> void:
	var d := load_data()
	var records: Dictionary = d.get("pronunciation", {})
	var key := lang + ":" + str(level) + ":" + phrase
	var entry: Dictionary = records.get(key, {"attempts": 0, "best": 0.0})
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	entry["best"] = maxf(float(entry.get("best", 0.0)), clampf(score, 0.0, 1.0))
	entry["last"] = clampf(score, 0.0, 1.0)
	records[key] = entry
	d["pronunciation"] = records
	save_data()

static func pronunciation_best(lang: String, level: int, phrase: String) -> float:
	var records: Dictionary = load_data().get("pronunciation", {})
	var entry: Dictionary = records.get(lang + ":" + str(level) + ":" + phrase, {})
	return float(entry.get("best", 0.0))

static func stars() -> int:
	return int(load_data().get("stars", 0))

static func add_stars(n: int) -> int:
	var d := load_data()
	d["stars"] = int(d.get("stars", 0)) + n
	save_data()
	return int(d["stars"])

static func complete(mode: String, level: int, score: int = 3) -> Dictionary:
	var d := load_data()
	var wins: Dictionary = d.get("wins", {})
	var key := "%s_%d" % [mode, level]
	var previous := int(wins.get(key, 0))
	var best := maxi(previous, score)
	wins[key] = best
	d["wins"] = wins
	d["stars"] = int(d.get("stars", 0)) + maxi(0, best - previous)
	save_data()
	return d

static func level_stars(mode: String, level: int) -> int:
	var wins: Dictionary = load_data().get("wins", {})
	return int(wins.get("%s_%d" % [mode, level], 0))

## Maior nível liberado (1..10): o nível seguinte ao último concluído.
static func unlocked_level(mode: String) -> int:
	var top := 0
	for l in range(1, 11):
		if level_stars(mode, l) > 0:
			top = l
	return mini(10, top + 1)

static func mode_stars(mode: String) -> int:
	var total := 0
	for l in range(1, 11):
		total += level_stars(mode, l)
	return total

# ---- opções / estado simples -------------------------------------------------
static func setting(key: String, default: Variant) -> Variant:
	var s: Dictionary = load_data().get("settings", {})
	return s.get(key, default)

static func set_setting(key: String, value: Variant) -> void:
	var d := load_data()
	var s: Dictionary = d.get("settings", {})
	s[key] = value
	d["settings"] = s
	save_data()

static func outfit_get(key: String, default: Variant) -> Variant:
	var s: Dictionary = load_data().get("outfit", {})
	return s.get(key, default)

static func outfit_set(key: String, value: Variant) -> void:
	var d := load_data()
	var s: Dictionary = d.get("outfit", {})
	s[key] = value
	d["outfit"] = s
	save_data()

static func flag(key: String) -> bool:
	var s: Dictionary = load_data().get("flags", {})
	return bool(s.get(key, false))

static func set_flag(key: String, value: bool = true) -> void:
	var d := load_data()
	var s: Dictionary = d.get("flags", {})
	s[key] = value
	d["flags"] = s
	save_data()

# ---- missões --------------------------------------------------------------------
static func quest_count(id: String) -> int:
	var q: Dictionary = load_data().get("quests", {})
	var e: Dictionary = q.get(id, {})
	return int(e.get("n", 0))

static func quest_tier(id: String) -> int:
	var q: Dictionary = load_data().get("quests", {})
	var e: Dictionary = q.get(id, {})
	return int(e.get("tier", 0))

## Soma progresso; devolve true se a missão foi concluída agora (e avança de nível).
static func quest_add(id: String, base_goal: int, amount: int = 1) -> bool:
	var d := load_data()
	var q: Dictionary = d.get("quests", {})
	var e: Dictionary = q.get(id, {"n": 0, "tier": 0})
	e["n"] = int(e.get("n", 0)) + amount
	var goal := base_goal * (int(e.get("tier", 0)) + 1)
	var done := false
	if int(e["n"]) >= goal:
		e["n"] = 0
		e["tier"] = int(e.get("tier", 0)) + 1
		done = true
	q[id] = e
	d["quests"] = q
	save_data()
	return done
