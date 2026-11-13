class_name DataLoader
extends RefCounted
## Helpers for reading the JSON data files under res://data/.

const DATA_ROOT := "res://data/"


## Parses a JSON file that must contain an object. Returns {} (and logs an
## error) if the file is missing or isn't a JSON object.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Data file not found: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Data file is not a JSON object: %s" % path)
		return {}
	return parsed


## Loads data/<category>/<id>.json, e.g. load_entry("units", &"us_rifle_squad").
static func load_entry(category: String, id: StringName) -> Dictionary:
	return load_json(DATA_ROOT + category + "/" + String(id) + ".json")


## Reads a [x, y] JSON array as a Vector2.
static func to_vector2(value: Variant, fallback := Vector2.ZERO) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


## Reads [[x, y], ...] as a PackedVector2Array.
static func to_polygon(value: Variant) -> PackedVector2Array:
	var points := PackedVector2Array()
	if value is Array:
		for p: Variant in value:
			points.append(to_vector2(p))
	return points
