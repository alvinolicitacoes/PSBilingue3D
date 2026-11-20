extends RefCounted
class_name PSProgress
## Progresso salvo em user://psbilingue_progress.json (compatível com a versão anterior).

const PATH := "user://psbilingue_progress.json"
static var _data: Dictionary = {}
static var _loaded := false

static func _default() -> Dictionary:
	return {"stars": 0, "wins": {}, "best": {}, "profile": "Pietro", "settings": {}, "outfit": {}, "quests": {}, "flags": {}}

static func load_data() -> Dictionary:
	if _loaded:
		return _data
	_loaded = true
	_data = _default()
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in parsed:
					_data[k] = parsed[k]
	return _data

static func save_data(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_data = data
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_data, "  "))

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
