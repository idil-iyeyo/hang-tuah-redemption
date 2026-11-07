# scripts/enemy_theme_manager.gd
class_name EnemyThemeManager
extends RefCounted

## Master Enemy Theme & Texture Slot System
## Provides extensible Dictionary slots for each non-boss enemy type:
## - Breeder (Bile Breeder)
## - Spewer (Bile Spewer)
## - Charger (Charger Roach)
## - Heavy / Tank (Heavy Enemy)
## - Void / Teleporter (Void Bile)
##
## Mapped across 4 stage groups (matching the 4 background sectors):
## - Stages 1-5 (Sector 1: Deep Nebula)
## - Stages 6-10 (Sector 2: Cosmic Rift)
## - Stages 11-15 (Sector 3: Asteroid Belt)
## - Stages 16-20 (Sector 4: Void Citadel)

const TYPE_BREEDER: String = "breeder"
const TYPE_SPEWER: String = "spewer"
const TYPE_CHARGER: String = "charger"
const TYPE_HEAVY: String = "heavy"
const TYPE_VOID: String = "void"

const ALL_ENEMY_TYPES: Array[String] = [
	TYPE_BREEDER,
	TYPE_SPEWER,
	TYPE_CHARGER,
	TYPE_HEAVY,
	TYPE_VOID
]

const ALL_STAGE_BRACKETS: Array[String] = [
	"1-5",
	"6-10",
	"11-15",
	"16-20"
]

const DEFAULT_TEXTURE_PATHS: Dictionary = {
	TYPE_BREEDER: "res://assets/textures/enemies/Gasing Trooper - Enemy Basic.png",
	TYPE_SPEWER: "res://assets/textures/enemies/BatikJellyfishSpitter.png",
	TYPE_CHARGER: "res://assets/textures/enemies/Rhino Horn - Enemy Basic.png",
	TYPE_HEAVY: "res://assets/textures/enemies/Songket Drone - Enemy.png",
	TYPE_VOID: "res://assets/textures/enemies/Malayan Ghost Army - Enemy Basic.png"
}

## Master default dictionary slots structured per stage group and enemy type.
## Users can assign Texture2D instances or file path Strings ("res://...") to any slot.
const DEFAULT_ENEMY_THEMES: Dictionary = {
	"1-5": {
		"breeder": "",
		"spewer": "",
		"charger": "",
		"heavy": "",
		"void": ""
	},
	"6-10": {
		"breeder": "",
		"spewer": "",
		"charger": "",
		"heavy": "",
		"void": ""
	},
	"11-15": {
		"breeder": "",
		"spewer": "",
		"charger": "",
		"heavy": "",
		"void": ""
	},
	"16-20": {
		"breeder": "",
		"spewer": "",
		"charger": "",
		"heavy": "",
		"void": ""
	}
}

static var _texture_cache: Dictionary = {}


## Returns a fresh, deep copy of the default theme dictionary slots.
static func get_default_slots() -> Dictionary:
	return DEFAULT_ENEMY_THEMES.duplicate(true)


## Normalizes raw enemy type strings or aliases to canonical keys.
## e.g. "tank" -> "heavy", "teleporter" -> "void", "spitter" -> "spewer"
static func normalize_enemy_type(raw_type: String) -> String:
	var clean: String = raw_type.strip_edges().to_lower()
	match clean:
		"breeder", "bile_breeder", "bilebreeder":
			return TYPE_BREEDER
		"spewer", "bile_spewer", "bilespewer", "spitter", "jellyfish":
			return TYPE_SPEWER
		"charger", "charger_roach", "chargerroach", "roach":
			return TYPE_CHARGER
		"heavy", "tank", "heavy_enemy", "heavyenemy", "armored":
			return TYPE_HEAVY
		"void", "teleporter", "void_bile", "voidbile":
			return TYPE_VOID
		_:
			return clean


## Converts a stage number or input key into canonical bracket string ("1-5", "6-10", "11-15", "16-20").
static func get_stage_bracket(stage_or_bracket: Variant) -> String:
	if stage_or_bracket is int or stage_or_bracket is float:
		var st_num: int = int(stage_or_bracket)
		if st_num <= 5:
			return "1-5"
		elif st_num <= 10:
			return "6-10"
		elif st_num <= 15:
			return "11-15"
		else:
			return "16-20"

	var s_key: String = str(stage_or_bracket).strip_edges().to_lower()
	if s_key == "1" or s_key == "sector_1" or s_key == "sector 1" or s_key == "1-5":
		return "1-5"
	elif s_key == "2" or s_key == "sector_2" or s_key == "sector 2" or s_key == "6-10":
		return "6-10"
	elif s_key == "3" or s_key == "sector_3" or s_key == "sector 3" or s_key == "11-15":
		return "11-15"
	elif s_key == "4" or s_key == "sector_4" or s_key == "sector 4" or s_key == "16-20":
		return "16-20"

	# If formatted like "stage_7" or "7"
	if s_key.begins_with("stage_") or s_key.begins_with("stage "):
		var num_part: String = s_key.replace("stage_", "").replace("stage ", "").strip_edges()
		if num_part.is_valid_int():
			return get_stage_bracket(num_part.to_int())

	if s_key.is_valid_int():
		return get_stage_bracket(s_key.to_int())

	return "1-5"


## Resolves and loads the appropriate Texture2D for the requested enemy type and stage.
## Looks up in slots dictionary with fallback to bracket 1-5, and finally base game defaults.
static func get_enemy_texture(slots: Dictionary, enemy_type: String, stage_num: int) -> Texture2D:
	var norm_type: String = normalize_enemy_type(enemy_type)
	var bracket: String = get_stage_bracket(stage_num)

	var found_entry: Variant = null

	# 1. Lookup in stage bracket mapping: slots[bracket][norm_type]
	if slots.has(bracket) and slots[bracket] is Dictionary:
		var bracket_dict: Dictionary = slots[bracket]
		if bracket_dict.has(norm_type) and _is_valid_texture_entry(bracket_dict[norm_type]):
			found_entry = bracket_dict[norm_type]

	# 2. Check alternative orientation: slots[norm_type][bracket]
	if found_entry == null and slots.has(norm_type) and slots[norm_type] is Dictionary:
		var type_dict: Dictionary = slots[norm_type]
		if type_dict.has(bracket) and _is_valid_texture_entry(type_dict[bracket]):
			found_entry = type_dict[bracket]

	# 3. Check exact stage number override if present: slots[stage_num][norm_type]
	if found_entry == null and slots.has(stage_num) and slots[stage_num] is Dictionary:
		var stage_dict: Dictionary = slots[stage_num]
		if stage_dict.has(norm_type) and _is_valid_texture_entry(stage_dict[norm_type]):
			found_entry = stage_dict[norm_type]

	# 4. Fallback: check Sector 1 ("1-5") if higher sector slot is empty
	if found_entry == null and bracket != "1-5":
		if slots.has("1-5") and slots["1-5"] is Dictionary:
			var s1_dict: Dictionary = slots["1-5"]
			if s1_dict.has(norm_type) and _is_valid_texture_entry(s1_dict[norm_type]):
				found_entry = s1_dict[norm_type]

	# 5. Ultimate fallback to base default asset
	if found_entry == null:
		if DEFAULT_TEXTURE_PATHS.has(norm_type):
			found_entry = DEFAULT_TEXTURE_PATHS[norm_type]

	return _load_texture_from_entry(found_entry)


## Sets a specific slot in the theme dictionary. Accepts Texture2D or string path.
static func set_enemy_texture_slot(slots: Dictionary, enemy_type: String, stage_or_bracket: Variant, texture_or_path: Variant) -> void:
	var norm_type: String = normalize_enemy_type(enemy_type)
	var bracket: String = get_stage_bracket(stage_or_bracket)

	if not slots.has(bracket) or not (slots[bracket] is Dictionary):
		slots[bracket] = {}

	slots[bracket][norm_type] = texture_or_path

	# If cached path is being overwritten, clear cache entry
	if texture_or_path is String and _texture_cache.has(texture_or_path):
		_texture_cache.erase(texture_or_path)


static func _is_valid_texture_entry(entry: Variant) -> bool:
	if entry is Texture2D:
		return true
	if entry is String:
		return not (entry as String).strip_edges().is_empty()
	return false


static func _load_texture_from_entry(entry: Variant) -> Texture2D:
	if entry is Texture2D:
		return entry

	if entry is String:
		var path: String = (entry as String).strip_edges()
		if path.is_empty():
			return null
		if _texture_cache.has(path):
			return _texture_cache[path]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				_texture_cache[path] = tex
				return tex
		else:
			push_warning("[EnemyThemeManager] Texture file not found at: %s" % path)

	return null
