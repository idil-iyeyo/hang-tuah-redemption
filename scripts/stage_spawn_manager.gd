class_name StageSpawnManager
extends RefCounted

## ==============================================================================
## STAGE ENEMY SPAWN DATABASE & CONFIGURATION MANAGER
## ==============================================================================
## This script defines and manages the exact enemy spawns, boss encounters,
## and wave progression tuning for every stage (Stages 1 through 20+).
##
## HOW TO CUSTOMIZE STAGE ENEMY SPAWNS:
## 1. Locate the stage number key in STAGE_SPAWN_DATABASE below (e.g. 1:, 6:, 10:).
## 2. Adjust the enemy counts:
##    - "heavy_enemies"  : Number of Heavy Armored Tanks (12 HP)
##    - "bile_spewers"   : Number of Bile Spewers (8 HP)
##    - "charger_roaches": Number of Charger Roaches (30 HP)
##    - "void_biles"     : Number of Void Biles (8 HP, Teleporters)
##    - "bile_breeders"  : Number of Bile Breeders (20 HP, Breeds 3 Void Biles)
## 3. For Boss Stages (is_boss_stage = true):
##    - Adjust or add boss entries in the "bosses" array:
##      {
##          "type": StageSpawnManager.BOSS_TYPE_DREADNOUGHT (or "dragon_roach"),
##          "name": "Dreadnought Titan",
##          "health": 50,
##          "position": Vector2(1950.0, 540.0),
##          "target_y": 540.0,
##          "speed_multiplier": 1.0,
##          "minion_summon": false
##      }
## ==============================================================================

# Canonical Enemy Type Keys
const KEY_HEAVY: String = "heavy_enemies"
const KEY_SPEWER: String = "bile_spewers"
const KEY_CHARGER: String = "charger_roaches"
const KEY_VOID: String = "void_biles"
const KEY_BREEDER: String = "bile_breeders"
const KEY_PROJECTILES: String = "projectiles"

# Canonical Boss Identifiers
const BOSS_TYPE_DREADNOUGHT: String = "dreadnought"
const BOSS_TYPE_DRAGON_ROACH: String = "dragon_roach"

const BossNameManager = preload("res://scripts/boss_name_manager.gd")

## Master Stage Spawn Database (Stages 1 - 20)
const STAGE_SPAWN_DATABASE: Dictionary = {
	# ==========================================================================
	# SECTOR 1: DEEP NEBULA (Stages 1 to 5)
	# ==========================================================================
	1: {
		"title": "Warm-Up",
		"is_boss_stage": false,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 8,
		"spawn_interval": 1.15,
		"min_speed": 380.0,
		"max_speed": 460.0,
		"max_spread_deg": 8.0,
		"allowed_types": [0], # DIRECT
		"allowed_patterns": ["single"],
		"heal_reward": 20,
		"score_reward": 100,
		"bosses": []
	},
	2: {
		"title": "Twin Crossfire & Zoning",
		"is_boss_stage": false,
		"heavy_enemies": 1,
		"bile_spewers": 1,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 12,
		"spawn_interval": 0.95,
		"min_speed": 340.0,
		"max_speed": 580.0,
		"max_spread_deg": 12.0,
		"allowed_types": [0, 3], # DIRECT, FAST_DART
		"allowed_patterns": ["single", "twin_spread", "zone_denial"],
		"heal_reward": 20,
		"score_reward": 200,
		"bosses": []
	},
	3: {
		"title": "Armored Guards Call",
		"is_boss_stage": false,
		"heavy_enemies": 2,   # 1 Heavy Tank (12 HP)
		"bile_spewers": 2,    # 1 Bile Spewer (8 HP)
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 14,
		"spawn_interval": 0.88,
		"min_speed": 350.0,
		"max_speed": 620.0,
		"max_spread_deg": 14.0,
		"allowed_types": [0, 1, 3], # DIRECT, WAVY, FAST_DART
		"allowed_patterns": ["single", "twin_spread", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 20,
		"score_reward": 300,
		"bosses": []
	},
	4: {
		"title": "Mini Militia Assault",
		"is_boss_stage": false,
		"heavy_enemies": 3,   # 2 Heavy Tanks
		"bile_spewers": 3,    # 2 Bile Spewers
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 18,
		"spawn_interval": 0.78,
		"min_speed": 320.0,
		"max_speed": 660.0,
		"max_spread_deg": 16.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 25,
		"score_reward": 400,
		"bosses": []
	},
	5: {
		"title": "BOSS ENCOUNTER - WAURIOR",
		"is_boss_stage": true,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 0,
		"spawn_interval": 2.0,
		"min_speed": 420.0,
		"max_speed": 580.0,
		"max_spread_deg": 15.0,
		"allowed_types": [0, 1, 3],
		"allowed_patterns": ["single"],
		"heal_reward": 35,
		"score_reward": 500,
		"boss_bar_title": "DREADNOUGHT TITAN",
		"bosses": [
			{
				"type": "dreadnought",
				"name": "Dreadnought Titan",
				"health": 225,
				"position": Vector2(1950.0, 540.0),
				"target_y": 540.0,
				"speed_multiplier": 0.75,
				"minion_summon": false
			}
		]
	},

	# ==========================================================================
	# SECTOR 2: COSMIC RIFT (Stages 6 to 10)
	# ==========================================================================
	6: {
		"title": "Blitzkrieg Strategy",
		"is_boss_stage": false,
		"heavy_enemies": 3,
		"bile_spewers": 4,
		"charger_roaches": 3, # 1 Charger Roach (30 HP)
		"void_biles": 3,      # 1 Void Bile (8 HP, Teleporter)
		"bile_breeders": 0,
		"projectiles": 18,
		"spawn_interval": 0.76,
		"min_speed": 330.0,
		"max_speed": 660.0,
		"max_spread_deg": 16.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 25,
		"score_reward": 600,
		"bosses": []
	},
	7: {
		"title": "Abyssal Incursion",
		"is_boss_stage": false,
		"heavy_enemies": 3,
		"bile_spewers": 2,
		"charger_roaches": 4,
		"void_biles": 4,
		"bile_breeders": 0,
		"projectiles": 20,
		"spawn_interval": 0.72,
		"min_speed": 340.0,
		"max_speed": 680.0,
		"max_spread_deg": 16.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 25,
		"score_reward": 700,
		"bosses": []
	},
	8: {
		"title": "Menacing Output",
		"is_boss_stage": false,
		"heavy_enemies": 4,
		"bile_spewers": 4,
		"charger_roaches": 4,
		"void_biles": 4,
		"bile_breeders": 2,   # 1 Bile Breeder (20 HP, breeds 3 Void Biles)
		"projectiles": 22,
		"spawn_interval": 0.68,
		"min_speed": 340.0,
		"max_speed": 700.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 800,
		"bosses": []
	},
	9: {
		"title": "Cataclysmic Fleet",
		"is_boss_stage": false,
		"heavy_enemies": 5,
		"bile_spewers": 4,
		"charger_roaches": 5,
		"void_biles": 5,
		"bile_breeders": 2,
		"projectiles": 24,
		"spawn_interval": 0.64,
		"min_speed": 350.0,
		"max_speed": 720.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 900,
		"bosses": []
	},
	10: {
		"title": "BOSS ENCOUNTER - MINANGKABAU SHIP",
		"is_boss_stage": true,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 0,
		"spawn_interval": 2.0,
		"min_speed": 420.0,
		"max_speed": 580.0,
		"max_spread_deg": 15.0,
		"allowed_types": [0, 1, 3],
		"allowed_patterns": ["single"],
		"heal_reward": 40,
		"score_reward": 1000,
		"boss_bar_title": "DRAGON ROACH TITAN",
		"bosses": [
			{
				"type": "dragon_roach",
				"name": "Dragon Roach Titan",
				"health": 500,
				"position": Vector2(1950.0, 540.0),
				"target_y": 540.0,
				"speed_multiplier": 0.6,
				"minion_summon": true
			}
		]
	},

	# ==========================================================================
	# SECTOR 3: ASTEROID BELT (Stages 11 to 15)
	# ==========================================================================
	11: {
		"title": "MinangKabau Sky Fortress",
		"is_boss_stage": false,
		"heavy_enemies": 9,
		"bile_spewers": 6,
		"charger_roaches": 9,
		"void_biles": 6,
		"bile_breeders": 3,
		"projectiles": 30, #  cap projectiles at 75
		"spawn_interval": 0.75, # cap spawn interval at 0.75 from now on
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1100,
		"bosses": []
	},
	12: {
		"title": "Chaos Protocol",
		"is_boss_stage": false,
		"heavy_enemies": 9,
		"bile_spewers": 6,
		"charger_roaches": 9,
		"void_biles": 6,
		"bile_breeders": 3,
		"projectiles": 30,
		"spawn_interval": 0.75,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1200,
		"bosses": []
	},
	
	13: {
		"title": "Tank Parade",
		"is_boss_stage": false,
		"heavy_enemies": 24,
		"bile_spewers": 24,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 30,
		"spawn_interval": 0.75,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1300,
		"bosses": []
	},
	
	14: {
		"title": "Horned Onslaught",
		"is_boss_stage": false,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 40,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 30,
		"spawn_interval": 0.7,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1400,
		"bosses": []
	},
	
	15: {
		"title": "BOSS ENCOUNTER - TWIN MINANGKABAU",
		"is_boss_stage": true,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 0,
		"spawn_interval": 2.0,
		"min_speed": 420.0,
		"max_speed": 580.0,
		"max_spread_deg": 15.0,
		"allowed_types": [0, 1, 3],
		"allowed_patterns": ["single"],
		"heal_reward": 50,
		"score_reward": 1500,
		"boss_bar_title": "TWIN DREADNOUGHT TITANS (2x 100 HP)",
		"bosses": [
			{
				"type": "dreadnought",
				"name": "Dreadnought Titan Alpha",
				"health": 600,
				"position": Vector2(1950.0, 340.0),
				"target_y": 340.0,
				"speed_multiplier": 0.6,
				"minion_summon": true
			},
			{
				"type": "dreadnought",
				"name": "Dreadnought Titan Beta",
				"health": 600,
				"position": Vector2(2050.0, 740.0),
				"target_y": 740.0,
				"speed_multiplier": 0.5,
				"minion_summon": true
			}
		]
	},

	# ==========================================================================
	# SECTOR 4: VOID CITADEL (Stages 16 to 20)
	# ==========================================================================
	16: {
		"title": "No Keris's Land",
		"is_boss_stage": false,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 10,
		"projectiles": 30,
		"spawn_interval": 0.70,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1600,
		"bosses": []
	},
	17: {
		"title": "Spewer Madness",
		"is_boss_stage": false,
		"heavy_enemies": 2,
		"bile_spewers": 30,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 30,
		"spawn_interval": 0.60,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1700,
		"bosses": []
	},
	18: {
		"title": "Horned Madness Returns!",
		"is_boss_stage": false,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 32,
		"void_biles": 0,
		"bile_breeders": 32,
		"projectiles": 32,
		"spawn_interval": 0.8,
		"min_speed": 230.0,
		"max_speed": 460.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1800,
		"bosses": []
	},
	19: {
		"title": "Invader's Last Stand",
		"is_boss_stage": false,
		"heavy_enemies": 16,
		"bile_spewers": 16,
		"charger_roaches": 20,
		"void_biles": 8,
		"bile_breeders": 6,
		"projectiles": 30,
		"spawn_interval": 0.8,
		"min_speed": 330.0,
		"max_speed": 760.0,
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": 1900,
		"bosses": []
	},
	20: {
		"title": "FINAL BOSS ENCOUNTER - MINANGKABAU AND SHIP",
		"is_boss_stage": true,
		"heavy_enemies": 0,
		"bile_spewers": 0,
		"charger_roaches": 0,
		"void_biles": 0,
		"bile_breeders": 0,
		"projectiles": 0,
		"spawn_interval": 2.0,
		"min_speed": 420.0,
		"max_speed": 580.0,
		"max_spread_deg": 15.0,
		"allowed_types": [0, 1, 3],
		"allowed_patterns": ["single"],
		"heal_reward": 60,
		"score_reward": 2500,
		"boss_bar_title": "DUAL TITANS: DRAGON ROACH & DREADNOUGHT (400 HP)",
		"bosses": [
			{
				"type": "dragon_roach",
				"name": "Dragon Roach Titan",
				"health": 1000,
				"position": Vector2(1950.0, 420.0),
				"target_y": 420.0,
				"speed_multiplier": 0.35,
				"minion_summon": true
			},
			{
				"type": "dreadnought",
				"name": "Dreadnought Titan",
				"health": 950,
				"position": Vector2(2080.0, 680.0),
				"target_y": 680.0,
				"speed_multiplier": 0.35,
				"minion_summon": true
			}
		]
	}
}

# Runtime override cache for dynamic code alterations
static var _runtime_stage_overrides: Dictionary = {}


## Get full configuration for a stage. Applies overrides and falls back to formula for stage > 20.
static func get_stage_config(stage_num: int) -> Dictionary:
	var cfg: Dictionary = {}
	# 1. Check runtime override
	if _runtime_stage_overrides.has(stage_num):
		cfg = (_runtime_stage_overrides[stage_num] as Dictionary).duplicate(true)
	# 2. Check master database
	elif STAGE_SPAWN_DATABASE.has(stage_num):
		cfg = (STAGE_SPAWN_DATABASE[stage_num] as Dictionary).duplicate(true)
	# 3. Dynamic scaling for endless waves beyond Stage 20
	else:
		cfg = _generate_endless_stage_config(stage_num)

	# Harmonize minion_summon: if stage defines minion_summon, propagate to bosses if not explicitly set
	if cfg.has("minion_summon"):
		var stage_ms: bool = bool(cfg["minion_summon"])
		var bosses_list: Array = cfg.get("bosses", [])
		for b in bosses_list:
			if b is Dictionary and not b.has("minion_summon"):
				b["minion_summon"] = stage_ms
		cfg["bosses"] = bosses_list

	# Harmonize boss names, bar titles, and stage titles from BossNameManager
	if cfg.get("is_boss_stage", false) or not (cfg.get("bosses", []) as Array).is_empty():
		if BossNameManager.has_boss_config(stage_num):
			var boss_info: Dictionary = BossNameManager.get_boss_info(stage_num)
			if boss_info.get("bar_title", "") != "":
				cfg["boss_bar_title"] = boss_info["bar_title"]
			if boss_info.get("stage_title", "") != "":
				cfg["title"] = boss_info["stage_title"]

			var named_bosses_list: Array = cfg.get("bosses", [])
			for i in range(named_bosses_list.size()):
				var b = named_bosses_list[i]
				if b is Dictionary:
					var b_type: String = str(b.get("type", ""))
					b["name"] = BossNameManager.get_individual_boss_name(stage_num, i, b_type)
			cfg["bosses"] = named_bosses_list

	return cfg


## Get enemy counts breakdown for a given stage: {"heavy": int, "spewer": int, "charger": int, "void": int, "breeder": int}
static func get_enemy_counts(stage_num: int) -> Dictionary:
	var cfg: Dictionary = get_stage_config(stage_num)
	return {
		"heavy": int(cfg.get("heavy_enemies", 0)),
		"spewer": int(cfg.get("bile_spewers", 0)),
		"charger": int(cfg.get("charger_roaches", 0)),
		"void": int(cfg.get("void_biles", 0)),
		"breeder": int(cfg.get("bile_breeders", 0)),
		"projectiles": int(cfg.get("projectiles", 0))
	}


## Returns true if the stage is configured as a boss encounter.
static func is_boss_stage(stage_num: int) -> bool:
	var cfg: Dictionary = get_stage_config(stage_num)
	return bool(cfg.get("is_boss_stage", false))


## Returns the array of boss encounter dictionaries for the stage.
static func get_boss_configs(stage_num: int) -> Array:
	var cfg: Dictionary = get_stage_config(stage_num)
	return cfg.get("bosses", []).duplicate(true)


## Set boss minion summoning for a specific stage at runtime
static func set_stage_boss_minion_summon(stage_num: int, minion_summon: bool) -> void:
	var cfg: Dictionary = get_stage_config(stage_num)
	cfg["minion_summon"] = minion_summon
	var bosses_list: Array = cfg.get("bosses", [])
	for b in bosses_list:
		if b is Dictionary:
			b["minion_summon"] = minion_summon
	cfg["bosses"] = bosses_list
	_runtime_stage_overrides[stage_num] = cfg


## Check if boss minion summoning is enabled for a stage
static func is_boss_minion_summon_enabled(stage_num: int) -> bool:
	var cfg: Dictionary = get_stage_config(stage_num)
	if bool(cfg.get("minion_summon", false)):
		return true
	var bosses_list: Array = cfg.get("bosses", [])
	for b in bosses_list:
		if b is Dictionary and bool(b.get("minion_summon", false)):
			return true
	return false


## Set a specific enemy count for a stage at runtime
static func set_stage_enemy_count(stage_num: int, enemy_type: String, count: int) -> void:
	var cfg: Dictionary = get_stage_config(stage_num)
	var norm_type: String = _normalize_enemy_type_key(enemy_type)
	if norm_type != "":
		cfg[norm_type] = maxi(0, count)
		_runtime_stage_overrides[stage_num] = cfg


## Set full stage configuration override at runtime
static func set_stage_config(stage_num: int, config: Dictionary) -> void:
	_runtime_stage_overrides[stage_num] = config.duplicate(true)


## Reset all runtime overrides back to STAGE_SPAWN_DATABASE defaults
static func reset_runtime_overrides() -> void:
	_runtime_stage_overrides.clear()


## Normalize various enemy key synonyms to canonical keys
static func _normalize_enemy_type_key(enemy_type: String) -> String:
	var lower: String = enemy_type.strip_edges().to_lower()
	match lower:
		"heavy", "heavy_enemy", "heavy_enemies", "tank", "tanks":
			return KEY_HEAVY
		"spewer", "bile_spewer", "bile_spewers", "spitter", "spitters":
			return KEY_SPEWER
		"charger", "charger_roach", "charger_roaches", "roach", "roaches":
			return KEY_CHARGER
		"void", "void_bile", "void_biles", "teleporter", "teleporters":
			return KEY_VOID
		"breeder", "bile_breeder", "bile_breeders":
			return KEY_BREEDER
		"projectile", "projectiles", "bullets":
			return KEY_PROJECTILES
		_:
			return ""


## Dynamic endless stage configuration generator matching existing scaling logic
static func _generate_endless_stage_config(stage_num: int) -> Dictionary:
	var is_boss: bool = (stage_num % 5 == 0)
	if is_boss:
		return {
			"title": "BOSS ENCOUNTER - TITAN CLUSTER",
			"is_boss_stage": true,
			"heavy_enemies": 0,
			"bile_spewers": 0,
			"charger_roaches": 0,
			"void_biles": 0,
			"bile_breeders": 0,
			"projectiles": 0,
			"spawn_interval": 2.0,
			"min_speed": 420.0,
			"max_speed": 580.0,
			"max_spread_deg": 15.0,
			"allowed_types": [0, 1, 3],
			"allowed_patterns": ["single"],
			"heal_reward": 50,
			"score_reward": stage_num * 100,
			"boss_bar_title": "TITAN ENCOUNTER",
			"bosses": [
				{
					"type": "dragon_roach",
					"name": "Dragon Roach Titan",
					"health": 200,
					"position": Vector2(1950.0, 540.0),
					"target_y": 540.0,
					"speed_multiplier": 1.0,
					"minion_summon": true
				}
			]
		}

	var tier: int = stage_num - 5
	return {
		"title": "Chaos Protocol %d" % tier,
		"is_boss_stage": false,
		"heavy_enemies": mini(4, 1 + tier / 3),
		"bile_spewers": mini(3, 1 + tier / 4),
		"charger_roaches": mini(4, 1 + tier / 3),
		"void_biles": mini(4, 1 + tier / 3),
		"bile_breeders": mini(2, 1 + tier / 5),
		"projectiles": 22 + tier * 3,
		"spawn_interval": maxf(0.50, 0.72 - float(tier) * 0.03),
		"min_speed": 330.0,
		"max_speed": minf(760.0, 660.0 + float(tier) * 18.0),
		"max_spread_deg": 18.0,
		"allowed_types": [0, 1, 2, 3],
		"allowed_patterns": ["single", "twin_spread", "fan_burst", "stream", "zone_denial", "pincer_trap"],
		"heal_reward": 30,
		"score_reward": stage_num * 100,
		"bosses": []
	}


## Convenience delegators to BossNameManager
static func get_boss_name(stage_num: int) -> String:
	return BossNameManager.get_boss_display_name(stage_num)


static func get_boss_bar_title(stage_num: int) -> String:
	return BossNameManager.get_boss_bar_title(stage_num)


static func set_boss_name(stage_num: int, name_or_dict: Variant, custom_bar_title: String = "", custom_stage_title: String = "") -> void:
	BossNameManager.set_boss_name(stage_num, name_or_dict, custom_bar_title, custom_stage_title)


static func reset_boss_names() -> void:
	BossNameManager.reset_boss_names()
