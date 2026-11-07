class_name CombatBoundaryManager
extends RefCounted

## =============================================================================
## COMBAT BOUNDARY & DANGER ZONE CONFIGURATION (SINGLE SOURCE OF TRUTH)
## =============================================================================
## This is the unified central configuration file for the combat boundary and
## hazard damage zone in Hang Tuah Redemption.
##
## Both scenes/main/main.gd and scenes/player/player.gd read directly from this
## manager, guaranteeing that boundary positions, hazard zones, damage rates,
## and visual parameters ALWAYS tally 100% across the entire game.
##
## QUICK ADJUSTMENT GUIDE:
## -----------------------
## 1. Starting Point (Where the danger boundary begins):
##    - "start_ratio": 0.65  -> starts at 65% of screen width from the left (right 35% is danger zone).
##    - "start_ratio": 0.60  -> starts at 60% of screen width from the left (right 40% is danger zone).
##    - "start_ratio": 0.40  -> starts at 40% of screen width from the left (right 60% is danger zone).
##    * In code: CombatBoundaryManager.set_boundary_ratio(0.60)
##    * Or from the right: CombatBoundaryManager.set_boundary_from_right(0.60)
##
## 2. Damage (How much damage is dealt in the danger zone):
##    - "damage_per_second": 10.0  -> 10 DPS (deals 5 damage every 0.5s tick).
##    - "damage_per_second": 20.0  -> 20 DPS (deals 10 damage every 0.5s tick).
##    * In code: CombatBoundaryManager.set_damage_per_second(20.0)
##
## 3. Approach Distance & Visuals:
##    - "approach_distance": 350.0 px (distance at which the boundary fades into view).
##    - "line_color": neon crimson warning line.
##    - "hazard_color": translucent danger field overlay.
## =============================================================================

const DEFAULT_CONFIG: Dictionary = {
	# Starting ratio from left edge of screen (0.05 to 0.95)
	"start_ratio": 0.45,

	# Damage per second applied to player in the danger zone
	"damage_per_second": 20.0,

	# Time in seconds between damage ticks (0.5s = ticks twice per second)
	"tick_interval": 0.5,

	# Distance in pixels where the line and area smoothly fade in
	"approach_distance": 550.0,

	# Boundary line neon crimson color
	"line_color": Color(1.0, 0.22, 0.22, 0.75),

	# Hazard zone subtle red background tint
	"hazard_color": Color(0.9, 0.05, 0.05, 0.09),

	# Lore warning title
	"lore_title": "⚠️ WARNING!",

	# Lore warning message displayed in HUD
	"lore_text": "SOLARIAR VOID DISRUPTION! // RETREAT TO MALAY REALM AIRSPACE!"
}

# Active runtime overrides dictionary (empty by default; set_* methods populate it)
static var _runtime_overrides: Dictionary = {}


# -----------------------------------------------------------------------------
# STARTING POINT APIS
# -----------------------------------------------------------------------------

## Returns the starting ratio of the boundary measured from the LEFT edge (0.0 to 1.0).
static func get_boundary_ratio() -> float:
	if _runtime_overrides.has("start_ratio"):
		return float(_runtime_overrides["start_ratio"])
	return float(DEFAULT_CONFIG.get("start_ratio", 0.65))


## Sets the starting ratio of the boundary from the LEFT edge (clamped 0.05 to 0.95).
## Example: set_boundary_ratio(0.60) sets boundary at 60% from left (40% danger zone on right).
static func set_boundary_ratio(ratio: float) -> void:
	_runtime_overrides["start_ratio"] = clampf(ratio, 0.05, 0.95)


## Convenience method: Sets the boundary starting position by specifying the percentage
## or ratio measured from the RIGHT edge of the screen.
## Examples:
## - set_boundary_from_right(0.60) -> danger zone is 60% of screen from right (boundary at 40% from left).
## - set_boundary_from_right(40.0) -> danger zone is 40% of screen from right (boundary at 60% from left).
## - set_boundary_from_right(0.35) -> danger zone is 35% of screen from right (boundary at 65% from left).
static func set_boundary_from_right(percentage_or_ratio: float) -> void:
	var ratio_from_right: float = percentage_or_ratio
	if ratio_from_right > 1.0:
		ratio_from_right /= 100.0
	set_boundary_ratio(1.0 - ratio_from_right)


## Returns the danger zone coverage ratio from the RIGHT edge (0.0 to 1.0).
## Example: if start_ratio is 0.65, this returns 0.35.
static func get_danger_zone_from_right_ratio() -> float:
	return 1.0 - get_boundary_ratio()


## Returns the absolute X position in pixels where the danger boundary begins.
static func get_boundary_x(screen_w: float = 1920.0) -> float:
	var w: float = screen_w if screen_w > 0.0 else 1920.0
	return w * get_boundary_ratio()


# -----------------------------------------------------------------------------
# DAMAGE APIS
# -----------------------------------------------------------------------------

## Returns the environmental damage per second (DPS) in the danger zone.
static func get_damage_per_second() -> float:
	if _runtime_overrides.has("damage_per_second"):
		return float(_runtime_overrides["damage_per_second"])
	return float(DEFAULT_CONFIG.get("damage_per_second", 10.0))


## Sets the environmental damage per second (DPS) in the danger zone.
static func set_damage_per_second(dps: float) -> void:
	var safe_dps: float = maxf(0.0, dps)
	_runtime_overrides["damage_per_second"] = safe_dps
	_runtime_overrides["lore_text"] = "SOLARIAR VOID DISRUPTION!// RETREAT TO MALAY REALM AIRSPACE!" % int(safe_dps)


## Returns the tick interval in seconds (default: 0.5s).
static func get_tick_interval() -> float:
	if _runtime_overrides.has("tick_interval"):
		return float(_runtime_overrides["tick_interval"])
	return float(DEFAULT_CONFIG.get("tick_interval", 0.5))


## Returns the damage dealt per tick (dps * tick_interval).
## Example: 10.0 DPS * 0.5s = 5 damage per tick.
static func get_damage_per_tick() -> int:
	var dps: float = get_damage_per_second()
	var interval: float = get_tick_interval()
	return maxi(1, int(round(dps * interval)))


# -----------------------------------------------------------------------------
# VISUAL & LORE APIS
# -----------------------------------------------------------------------------

## Returns the proximity reveal distance in pixels.
static func get_approach_distance() -> float:
	if _runtime_overrides.has("approach_distance"):
		return float(_runtime_overrides["approach_distance"])
	return float(DEFAULT_CONFIG.get("approach_distance", 350.0))


## Sets the proximity reveal distance in pixels.
static func set_approach_distance(dist: float) -> void:
	_runtime_overrides["approach_distance"] = maxf(10.0, dist)


## Returns the perimeter line color.
static func get_line_color() -> Color:
	if _runtime_overrides.has("line_color"):
		return _runtime_overrides["line_color"]
	return DEFAULT_CONFIG.get("line_color", Color(1.0, 0.22, 0.22, 0.75))


## Returns the hazard zone background color.
static func get_hazard_color() -> Color:
	if _runtime_overrides.has("hazard_color"):
		return _runtime_overrides["hazard_color"]
	return DEFAULT_CONFIG.get("hazard_color", Color(0.9, 0.05, 0.05, 0.09))


## Returns the lore title for the HUD warning panel.
static func get_lore_title() -> String:
	if _runtime_overrides.has("lore_title"):
		return str(_runtime_overrides["lore_title"])
	return str(DEFAULT_CONFIG.get("lore_title", "⚠️ WARNING!"))


## Returns the lore restriction warning text.
static func get_lore_text() -> String:
	if _runtime_overrides.has("lore_text"):
		return str(_runtime_overrides["lore_text"])
	return str(DEFAULT_CONFIG.get("lore_text", "SOLARIAR VOID DISRUPTION: 20 DMG/SEC // RETREAT TO MALAY REALM AIRSPACE!"))


# -----------------------------------------------------------------------------
# CONFIGURATION MANAGEMENT
# -----------------------------------------------------------------------------

## Resets all combat boundary settings back to default values.
static func reset_to_defaults() -> void:
	_runtime_overrides.clear()


## Returns a complete copy of the current configuration dictionary.
static func get_all_config() -> Dictionary:
	var cfg: Dictionary = DEFAULT_CONFIG.duplicate(true)
	for k in _runtime_overrides:
		cfg[k] = _runtime_overrides[k]
	return cfg


## Merges a dictionary of settings into the active configuration.
static func set_config(cfg: Dictionary) -> void:
	for key in cfg:
		_runtime_overrides[key] = cfg[key]
