class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://space_shooter_save.json"

# In-memory save cache to prevent redundant disk I/O and race condition overwrites
static var _cached_save_data: Dictionary = {}
static var _is_cache_loaded: bool = false


## Loads save data with in-memory caching and disk fallback
static func load_save_data() -> Dictionary:
	if _is_cache_loaded and not _cached_save_data.is_empty():
		return _cached_save_data.duplicate(true)

	if not FileAccess.file_exists(SAVE_PATH):
		_cached_save_data = _get_default_save_dict()
		_is_cache_loaded = true
		return _cached_save_data.duplicate(true)

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_cached_save_data = _get_default_save_dict()
		_is_cache_loaded = true
		return _cached_save_data.duplicate(true)

	var json_str: String = file.get_as_text()
	file.close()

	var test_json: JSON = JSON.new()
	var err: Error = test_json.parse(json_str)
	if err == OK and test_json.data is Dictionary:
		var data: Dictionary = test_json.data
		_ensure_keys_exist(data)
		_cached_save_data = data.duplicate(true)
		_is_cache_loaded = true
		return _cached_save_data.duplicate(true)

	_cached_save_data = _get_default_save_dict()
	_is_cache_loaded = true
	return _cached_save_data.duplicate(true)


static func _get_default_save_dict() -> Dictionary:
	return {
		"high_score": 0,
		"highest_wave": 1,
		"games_played": 0,
		"unlocked_level": 1,
		"completed_levels": [],
		"rewarded_levels": [],
		"upgrade_points": 3,
		"shield_level": 0,
		"speed_level": 0,
		"gun_level": 0,
		"selected_skin": "default",
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"last_played_level": 1,
		"intro_comic_seen": false,
		"ending_comic_seen": false,
		"huawei_player_id": "",
		"huawei_display_name": "",
		"huawei_signed_in": false
	}


static func _ensure_keys_exist(data: Dictionary) -> void:
	if not data.has("high_score"):
		data["high_score"] = 0
	if not data.has("highest_wave"):
		data["highest_wave"] = 1
	if not data.has("games_played"):
		data["games_played"] = 0
	if not data.has("unlocked_level"):
		data["unlocked_level"] = 1
	if not data.has("completed_levels"):
		data["completed_levels"] = []
	else:
		data["completed_levels"] = _sanitize_int_array(data["completed_levels"])

	if not data.has("rewarded_levels"):
		# Backwards compatibility: seed rewarded_levels from completed_levels
		data["rewarded_levels"] = data["completed_levels"].duplicate()
	else:
		data["rewarded_levels"] = _sanitize_int_array(data["rewarded_levels"])

	if not data.has("upgrade_points"):
		data["upgrade_points"] = 3
	if not data.has("shield_level"):
		data["shield_level"] = 0
	if not data.has("speed_level"):
		data["speed_level"] = 0
	if not data.has("gun_level"):
		data["gun_level"] = 0
	if not data.has("selected_skin"):
		data["selected_skin"] = "default"
	if not data.has("master_volume"):
		data["master_volume"] = 1.0
	if not data.has("music_volume"):
		data["music_volume"] = 1.0
	if not data.has("sfx_volume"):
		data["sfx_volume"] = 1.0
	if not data.has("last_played_level"):
		data["last_played_level"] = int(data.get("last_wave", 1))
	if not data.has("intro_comic_seen"):
		data["intro_comic_seen"] = false
	if not data.has("ending_comic_seen"):
		data["ending_comic_seen"] = false
	if not data.has("huawei_player_id"):
		data["huawei_player_id"] = ""
	if not data.has("huawei_display_name"):
		data["huawei_display_name"] = ""
	if not data.has("huawei_signed_in"):
		data["huawei_signed_in"] = false


## Sanitizes array of level numbers into a unique, sorted array of integers (eliminating JSON float artifacts)
static func _sanitize_int_array(arr) -> Array:
	var result: Array = []
	if arr is Array:
		for item in arr:
			var lvl: int = int(item)
			if lvl > 0 and not result.has(lvl):
				result.append(lvl)
	result.sort()
	return result


## Persists save data to both in-memory cache and disk storage
static func save_data(data: Dictionary) -> void:
	_cached_save_data = data.duplicate(true)
	_is_cache_loaded = true
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.flush()
		file.close()


## Invalidates the in-memory cache (primarily used in automated tests)
static func invalidate_cache() -> void:
	_cached_save_data.clear()
	_is_cache_loaded = false


static func unlock_level(level_num: int) -> int:
	var data: Dictionary = load_save_data()
	var current_unlocked: int = int(data.get("unlocked_level", 1))
	if level_num > current_unlocked:
		data["unlocked_level"] = level_num
		save_data(data)
		return level_num
	return current_unlocked


## Checks if the level has ever been completed by the player
static func is_level_completed(level_num: int) -> bool:
	var data: Dictionary = load_save_data()
	var completed: Array = data.get("completed_levels", [])
	for item in completed:
		if int(item) == level_num:
			return true
	return false


## Checks if the level has already granted its one-time upgrade points
static func is_level_rewarded(level_num: int) -> bool:
	var data: Dictionary = load_save_data()
	var rewarded: Array = data.get("rewarded_levels", [])
	for item in rewarded:
		if int(item) == level_num:
			return true
	return false


## Determines if a level is eligible to award upgrade points (must not be rewarded or completed)
static func can_claim_level_reward(level_num: int) -> bool:
	return not is_level_rewarded(level_num) and not is_level_completed(level_num)


## Claims the upgrade points for a level once. Returns points awarded (0 if already claimed).
static func claim_level_reward(level_num: int, point_amount: int) -> int:
	if not can_claim_level_reward(level_num):
		return 0

	var data: Dictionary = load_save_data()
	var target_lvl: int = int(level_num)
	var rewarded: Array = data.get("rewarded_levels", [])
	if not rewarded.has(target_lvl):
		rewarded.append(target_lvl)
		rewarded.sort()
		data["rewarded_levels"] = rewarded

	var completed: Array = data.get("completed_levels", [])
	if not completed.has(target_lvl):
		completed.append(target_lvl)
		completed.sort()
		data["completed_levels"] = completed

	data["upgrade_points"] = int(data.get("upgrade_points", 3)) + point_amount
	save_data(data)
	return point_amount


## Marks a level as completed in the save file. Returns true if first-time, false on replay.
static func mark_level_completed(level_num: int) -> bool:
	var target_lvl: int = int(level_num)
	var is_already_done: bool = is_level_completed(target_lvl)
	if is_already_done:
		return false # Replay completion

	var data: Dictionary = load_save_data()
	var completed: Array = data.get("completed_levels", [])
	if not completed.has(target_lvl):
		completed.append(target_lvl)
		completed.sort()
		data["completed_levels"] = completed

	var rewarded: Array = data.get("rewarded_levels", [])
	if not rewarded.has(target_lvl):
		rewarded.append(target_lvl)
		rewarded.sort()
		data["rewarded_levels"] = rewarded

	save_data(data)
	return true # First-time completion!


static func get_completed_levels() -> Array:
	var data: Dictionary = load_save_data()
	return data.get("completed_levels", [])


static func get_rewarded_levels() -> Array:
	var data: Dictionary = load_save_data()
	return data.get("rewarded_levels", [])


static func get_selected_skin() -> String:
	var data: Dictionary = load_save_data()
	return str(data.get("selected_skin", "default"))


static func set_selected_skin(skin_id: String) -> void:
	var data: Dictionary = load_save_data()
	data["selected_skin"] = skin_id
	save_data(data)


static func save_player_state(points: int, shield_lvl: int, speed_lvl: int, gun_lvl: int, skin: String = "") -> void:
	var data: Dictionary = load_save_data()
	data["upgrade_points"] = points
	data["shield_level"] = shield_lvl
	data["speed_level"] = speed_lvl
	data["gun_level"] = gun_lvl
	if not skin.is_empty():
		data["selected_skin"] = skin
	save_data(data)


static func record_game_result(score: int, wave: int) -> Dictionary:
	var data: Dictionary = load_save_data()
	var is_new_record: bool = false
	if score > int(data.get("high_score", 0)):
		data["high_score"] = score
		is_new_record = true
	if wave > int(data.get("highest_wave", 1)):
		data["highest_wave"] = wave
	data["games_played"] = int(data.get("games_played", 0)) + 1
	data["last_score"] = score
	data["last_wave"] = wave
	data["last_played_level"] = clampi(wave, 1, 20)
	data["is_new_record"] = is_new_record

	save_data(data)
	return data


## Returns the last stage/level number played by the user (clamped 1..20)
static func get_last_played_level() -> int:
	var data: Dictionary = load_save_data()
	return clampi(int(data.get("last_played_level", 1)), 1, 20)


## Persists the last stage/level number played by the user
static func set_last_played_level(level_num: int) -> void:
	var target_lvl: int = clampi(level_num, 1, 20)
	var data: Dictionary = load_save_data()
	data["last_played_level"] = target_lvl
	save_data(data)


static func get_master_volume() -> float:
	var data: Dictionary = load_save_data()
	return float(data.get("master_volume", 1.0))


static func set_master_volume(volume: float) -> void:
	var data: Dictionary = load_save_data()
	data["master_volume"] = clampf(volume, 0.0, 1.0)
	save_data(data)


static func get_music_volume() -> float:
	var data: Dictionary = load_save_data()
	return float(data.get("music_volume", 1.0))


static func set_music_volume(volume: float) -> void:
	var data: Dictionary = load_save_data()
	data["music_volume"] = clampf(volume, 0.0, 1.0)
	save_data(data)


static func get_sfx_volume() -> float:
	var data: Dictionary = load_save_data()
	return float(data.get("sfx_volume", 1.0))


static func set_sfx_volume(volume: float) -> void:
	var data: Dictionary = load_save_data()
	data["sfx_volume"] = clampf(volume, 0.0, 1.0)
	save_data(data)


static func has_seen_intro_comic() -> bool:
	var data: Dictionary = load_save_data()
	return bool(data.get("intro_comic_seen", false))


static func set_intro_comic_seen(seen: bool) -> void:
	var data: Dictionary = load_save_data()
	data["intro_comic_seen"] = seen
	save_data(data)


static func has_seen_ending_comic() -> bool:
	var data: Dictionary = load_save_data()
	return bool(data.get("ending_comic_seen", false))


static func set_ending_comic_seen(seen: bool) -> void:
	var data: Dictionary = load_save_data()
	data["ending_comic_seen"] = seen
	save_data(data)


## Resets all player progression, unlocked levels, rewards, upgrades, and skins back to initial default state
static func reset_all_progress() -> Dictionary:
	var current_vol: float = float(load_save_data().get("master_volume", 1.0))
	var current_music_vol: float = float(load_save_data().get("music_volume", 1.0))
	var current_sfx_vol: float = float(load_save_data().get("sfx_volume", 1.0))
	var reset_data: Dictionary = _get_default_save_dict()
	reset_data["master_volume"] = current_vol
	reset_data["music_volume"] = current_music_vol
	reset_data["sfx_volume"] = current_sfx_vol
	save_data(reset_data)
	return reset_data


## Stores Huawei ID identity for pilot profile synchronization
static func set_player_identity(open_id: String, display_name: String) -> void:
	var data: Dictionary = load_save_data()
	data["huawei_player_id"] = open_id
	data["huawei_display_name"] = display_name
	data["huawei_signed_in"] = not open_id.is_empty()
	save_data(data)


## Clears local Huawei ID identity upon sign out
static func clear_player_identity() -> void:
	var data: Dictionary = load_save_data()
	data["huawei_player_id"] = ""
	data["huawei_display_name"] = ""
	data["huawei_signed_in"] = false
	save_data(data)


## Retrieves stored Huawei ID profile information
static func get_player_identity() -> Dictionary:
	var data: Dictionary = load_save_data()
	return {
		"huawei_player_id": data.get("huawei_player_id", ""),
		"huawei_display_name": data.get("huawei_display_name", ""),
		"huawei_signed_in": bool(data.get("huawei_signed_in", false))
	}
