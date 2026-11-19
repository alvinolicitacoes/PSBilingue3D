extends RefCounted
class_name PSProgress

const PATH := "user://psbilingue_progress.json"
static func load_data() -> Dictionary:
    if not FileAccess.file_exists(PATH):
        return {"stars": 0, "wins": {}, "best": {}, "profile": "Pietro"}
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return {"stars": 0, "wins": {}, "best": {}, "profile": "Pietro"}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        return parsed
    return {"stars": 0, "wins": {}, "best": {}, "profile": "Pietro"}

static func save_data(data: Dictionary) -> void:
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data, "  "))

static func complete(mode: String, level: int, score: int = 3) -> Dictionary:
    var data := load_data()
    var wins: Dictionary = data.get("wins", {})
    var key := "%s_%d" % [mode, level]
    var previous := int(wins.get(key, 0))
    var best := maxi(previous, score)
    wins[key] = best
    data["wins"] = wins
    data["stars"] = int(data.get("stars", 0)) + maxi(0, best - previous)
    save_data(data)
    return data
