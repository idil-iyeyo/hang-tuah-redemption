# scripts/boss_name_manager.gd
class_name BossNameManager
extends RefCounted

## ==============================================================================
## BOSS NAME DICTIONARY & CUSTOMIZATION MANAGER
## ==============================================================================
## This manager centralizes all boss names, health bar titles, and stage titles
## across the entire game into a single, easily editable Dictionary.
##
## HOW TO CHANGE A BOSS NAME:
## 1. Locate the stage number key in BOSS_NAME_DICTIONARY below (e.g. 5, 10, 15, 20).
## 2. You can specify a full configuration dictionary:
##      5: {
##          "name": "Dreadnought Titan",
##          "bar_title": "DREADNOUGHT TITAN",
##          "stage_title": "BOSS ENCOUNTER - DREADNOUGHT TITAN",
##          "subtitle": "Armored Bio-Titan Flagship"
##      }
## 3. OR you can just use a simple string:
##      5: "Dreadnought Titan"
##    (The system will automatically generate the uppercase health bar title and stage title!)
##
## Changing names here will NOT break any game logic, physics, or scene spawning,
## because the engine internally uses technical identifiers ("dreadnought", "dragon_roach").
## ==============================================================================

## Master Boss Name Dictionary structured by stage number.
## Edit this dictionary directly to re-theme or rename any boss in the game.
const BOSS_NAME_DICTIONARY: Dictionary = {
	5: {
		"name": "WAURIOR",
		"bar_title": "WAURIOR (WAU MONARCH)",
		"stage_title": "SECTOR 1 BOSS - WAURIOR",
		"subtitle": "Ancient Autonomous War-Kite Titan"
	},
	10: {
		"name": "MINANGKABAU SHIP",
		"bar_title": "KAPAL MINANGKABAU",
		"stage_title": "SECTOR 2 BOSS - KAPAL MINANGKABAU",
		"subtitle": "Phantom Horned Dreadnought of the Stars"
	},
	15: {
		"name": "WAURIOR",
		"bar_title": "TWIN WAURIOR",
		"stage_title": "SECTOR 3 BOSS - TWIN WAURIOR",
		"subtitle": "Dual Vanguard Titans: Aiman & Usman",
		"bosses": [
			{"name": "WAURIOR AIMAN"},
			{"name": "WAURIOR USMAN"}
		]
	},
	20: {
		"name": "MINANGKABAU SHIP'S COALITION",
		"bar_title": "ANCIENT COALITION ARMADA",
		"stage_title": "FINAL BATTLE - ANCIENT COALITION",
		"subtitle": "Minangkabau Flagship & Waurior Prime",
		"bosses": [
			{"name": "Minangkabau Ship"},
			{"name": "Waurior"}
		]
	}
}

## Default generic names mapped to technical boss types (used as fallback for endless stages)
const TYPE_DEFAULT_NAMES: Dictionary = {
	"waurior": "Waurior",
	"ship": "Minangkabau Ship",
	"shiprior": "Coalition"
}

# Runtime override cache for dynamic modifications during gameplay, cheats, or tests
static var _runtime_name_overrides: Dictionary = {}


## Returns true if a boss configuration exists for the given stage
static func has_boss_config(stage_num: int) -> bool:
	if _runtime_name_overrides.has(stage_num):
		return true
	if BOSS_NAME_DICTIONARY.has(stage_num):
		return true
	return (stage_num % 5 == 0)


## Retrieves the complete, normalized boss info dictionary for a stage
static func get_boss_info(stage_num: int) -> Dictionary:
	var raw_entry: Variant = null

	# 1. Check runtime overrides
	if _runtime_name_overrides.has(stage_num):
		raw_entry = _runtime_name_overrides[stage_num]
	# 2. Check static master dictionary
	elif BOSS_NAME_DICTIONARY.has(stage_num):
		raw_entry = BOSS_NAME_DICTIONARY[stage_num]
	# 3. Endless / dynamic boss stages
	else:
		return _generate_endless_boss_info(stage_num)

	return _normalize_boss_entry(stage_num, raw_entry)


## Convenience accessor: get the primary boss display name (e.g. for victory modals or dialogs)
static func get_boss_display_name(stage_num: int, default_fallback: String = "Boss Titan") -> String:
	var info: Dictionary = get_boss_info(stage_num)
	var d_name: String = str(info.get("name", "")).strip_edges()
	return d_name if d_name != "" else default_fallback


## Convenience accessor: get the uppercase Boss Health Bar title
static func get_boss_bar_title(stage_num: int, default_fallback: String = "") -> String:
	var info: Dictionary = get_boss_info(stage_num)
	var title: String = str(info.get("bar_title", "")).strip_edges()
	if title != "":
		return title
	if default_fallback != "":
		return default_fallback
	return get_boss_display_name(stage_num).to_upper()


## Convenience accessor: get the full Stage Title for wave announcements
static func get_boss_stage_title(stage_num: int, default_fallback: String = "") -> String:
	var info: Dictionary = get_boss_info(stage_num)
	var title: String = str(info.get("stage_title", "")).strip_edges()
	if title != "":
		return title
	if default_fallback != "":
		return default_fallback
	return "BOSS ENCOUNTER - %s" % get_boss_display_name(stage_num).to_upper()


## Retrieves the name for an individual boss unit in a multi-boss encounter
static func get_individual_boss_name(stage_num: int, boss_index: int = 0, boss_type: String = "") -> String:
	var info: Dictionary = get_boss_info(stage_num)
	var bosses_list: Array = info.get("bosses", [])

	if boss_index >= 0 and boss_index < bosses_list.size():
		var b_item: Variant = bosses_list[boss_index]
		if b_item is Dictionary and b_item.has("name"):
			var b_name: String = str(b_item["name"]).strip_edges()
			if b_name != "":
				return b_name
		elif b_item is String and str(b_item).strip_edges() != "":
			return str(b_item).strip_edges()

	# Fallback to general boss name
	var general_name: String = str(info.get("name", "")).strip_edges()
	if general_name != "":
		return general_name

	# Fallback to type default name
	var norm_type: String = boss_type.strip_edges().to_lower()
	if TYPE_DEFAULT_NAMES.has(norm_type):
		return TYPE_DEFAULT_NAMES[norm_type]

	return "Titan Boss"


## Set or override a boss name at runtime without modifying code
## Accepts either:
##   - String: e.g. set_boss_name(5, "Mega Behemoth")
##   - Dictionary: e.g. set_boss_name(5, {"name": "Mega Behemoth", "bar_title": "MEGA BEHEMOTH"})
static func set_boss_name(stage_num: int, name_or_dict: Variant, custom_bar_title: String = "", custom_stage_title: String = "") -> void:
	if name_or_dict is String:
		var s_name: String = str(name_or_dict).strip_edges()
		var b_title: String = custom_bar_title.strip_edges() if custom_bar_title.strip_edges() != "" else s_name.to_upper()
		var s_title: String = custom_stage_title.strip_edges() if custom_stage_title.strip_edges() != "" else ("BOSS ENCOUNTER - " + s_name.to_upper())
		_runtime_name_overrides[stage_num] = {
			"name": s_name,
			"bar_title": b_title,
			"stage_title": s_title
		}
	elif name_or_dict is Dictionary:
		_runtime_name_overrides[stage_num] = (name_or_dict as Dictionary).duplicate(true)


## Resets all runtime overrides back to BOSS_NAME_DICTIONARY defaults
static func reset_boss_names() -> void:
	_runtime_name_overrides.clear()


## Normalizes raw dictionary or string entries into a complete specification
static func _normalize_boss_entry(stage_num: int, raw_entry: Variant) -> Dictionary:
	var result: Dictionary = {
		"name": "Boss Titan",
		"bar_title": "BOSS ENCOUNTER",
		"stage_title": "BOSS ENCOUNTER",
		"subtitle": "",
		"bosses": []
	}

	if raw_entry is String:
		var name_str: String = str(raw_entry).strip_edges()
		result["name"] = name_str
		result["bar_title"] = name_str.to_upper()
		result["stage_title"] = "BOSS ENCOUNTER - %s" % name_str.to_upper()
		result["bosses"] = [{"name": name_str}]
		return result

	if raw_entry is Dictionary:
		var dict: Dictionary = raw_entry
		var b_name: String = str(dict.get("name", "Boss Titan")).strip_edges()
		result["name"] = b_name

		if dict.has("bar_title") and str(dict["bar_title"]).strip_edges() != "":
			result["bar_title"] = str(dict["bar_title"]).strip_edges()
		else:
			result["bar_title"] = b_name.to_upper()

		if dict.has("stage_title") and str(dict["stage_title"]).strip_edges() != "":
			result["stage_title"] = str(dict["stage_title"]).strip_edges()
		else:
			result["stage_title"] = "BOSS ENCOUNTER - %s" % result["bar_title"]

		if dict.has("subtitle"):
			result["subtitle"] = str(dict["subtitle"]).strip_edges()

		if dict.has("bosses") and dict["bosses"] is Array:
			result["bosses"] = (dict["bosses"] as Array).duplicate(true)
		else:
			result["bosses"] = [{"name": b_name}]

		return result

	return _generate_endless_boss_info(stage_num)


## Default generator for endless boss encounters (Stage 25, 30, ...)
static func _generate_endless_boss_info(stage_num: int) -> Dictionary:
	var tier: int = stage_num / 5
	var name_str: String = "Titan Cluster Mk.%d" % tier
	return {
		"name": name_str,
		"bar_title": "TITAN ENCOUNTER (TIER %d)" % tier,
		"stage_title": "BOSS ENCOUNTER - TITAN CLUSTER",
		"subtitle": "Endless Void Entity",
		"bosses": [{"name": "Dragon Roach Titan"}]
	}
