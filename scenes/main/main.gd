extends Node2D

const SaveManager = preload("res://scripts/save_manager.gd")

enum GameState {
	MENU,
	INTRO,
	ACTIVE,
	CLEARED,
	GAME_OVER
}

@export var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")
@export var heavy_enemy_scene: PackedScene = preload("res://scenes/enemies/heavy_enemy.tscn")
@export var bile_spewer_scene: PackedScene = preload("res://scenes/enemies/bile_spewer.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/bosses/boss_waurior.tscn")
@export var dragon_roach_scene: PackedScene = preload("res://scenes/bosses/boss_ship.tscn")
@export var charger_roach_scene: PackedScene = preload("res://scenes/enemies/charger_roach.tscn")
@export var void_bile_scene: PackedScene = preload("res://scenes/enemies/void_bile.tscn")
@export var bile_breeder_scene: PackedScene = preload("res://scenes/enemies/bile_breeder.tscn")

const EnemyThemeManager = preload("res://scripts/enemy_theme_manager.gd")
const StageSpawnManager = preload("res://scripts/stage_spawn_manager.gd")
const MusicManager = preload("res://scripts/music_manager.gd")
const SoundManager = preload("res://scripts/sound_manager.gd")
const CombatBoundaryManager = preload("res://scripts/combat_boundary_manager.gd")

@export_group("Enemy Stage Theme Slots")
## Master Dictionary slots for every enemy type (Breeder, Spewer, Charger, Heavy/Tank, Void/Teleporter) across stage groups:
## - "1-5": Stages 1 to 5
## - "6-10": Stages 6 to 10
## - "11-15": Stages 11 to 15
## - "16-20": Stages 16 to 20
## Easily assign any custom PNG path ("res://...") or Texture2D in the Inspector.
@export var enemy_theme_slots: Dictionary = EnemyThemeManager.get_default_slots()

@export_group("Danger Boundary Settings")
## Horizontal ratio where danger boundary begins (0.05 to 0.95).
## 0.65 = starts at 65% of screen width from left (right 35% is danger zone).
## 0.60 = starts at 60% of screen width from left (right 40% is danger zone).
## 0.40 = starts at 40% of screen width from left (right 60% is danger zone).
@export var combat_boundary_ratio: float = 0.65
## Distance in pixels from the boundary line where the danger warning and line begin to smoothly fade in.
@export var boundary_approach_dist: float = 350.0
## Environmental damage per second dealt to the player while in the danger zone.
@export var boundary_hazard_dps: float = 10.0
## Base color for the perimeter warning line.
@export var boundary_line_color: Color = Color(1.0, 0.22, 0.22, 0.75)
## Base color for the hazard zone background overlay.
@export var boundary_hazard_color: Color = Color(0.9, 0.05, 0.05, 0.09)

@export_group("Stage Music Slots")
## Dedicated Stage Music Dictionary:
## Configure music for "menu", normal sectors ("1-4", "6-9", "11-14", "16-19"),
## and boss encounters ("5", "10", "15", "20").
## Easily assign any custom audio file path ("res://...") or AudioStream in the Inspector or via MusicManager.
@export var stage_music_slots: Dictionary = MusicManager.get_default_stage_music_slots()

# Backward compatibility accessor
var music_theme_slots: Dictionary:
	get:
		return MusicManager.get_all_tracks()
	set(val):
		for k in val.keys():
			var cfg = val[k]
			MusicManager.set_track_path(k, str(cfg.get("path", "")), float(cfg.get("volume_db", -8.0)))

var score: int = 0
var current_wave: int = 1
var game_over: bool = false
var current_state: GameState = GameState.MENU

# Economy & Upgrade Points (Every round gives 1, starts with 3 points for immediate purchases)
var upgrade_points: int = 3

var projectiles_spawned_in_wave: int = 0
var active_projectiles_count: int = 0
var active_heavy_enemies: int = 0
var active_bile_spewers: int = 0
var active_charger_roaches: int = 0
var active_void_biles: int = 0
var active_bile_breeders: int = 0
var active_bosses: Array[Area2D] = []

# Quota spawned tracking (strictly prevents infinite enemy respawn loops)
var heavy_enemies_spawned_in_wave: int = 0
var bile_spewers_spawned_in_wave: int = 0
var charger_roaches_spawned_in_wave: int = 0
var void_biles_spawned_in_wave: int = 0
var bile_breeders_spawned_in_wave: int = 0

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var starfield_background: CanvasLayer = $StarfieldBackground
@onready var starfield_canvas: Control = $StarfieldBackground/StarfieldCanvas

var wave_audio_player: AudioStreamPlayer = null
var music_manager: MusicManager = null
var sound_manager: SoundManager = null
var sfx_wave_start: AudioStreamWAV = null
var sfx_wave_clear: AudioStreamWAV = null
var sfx_purchase: AudioStreamWAV = null
var combat_boundary_line: Line2D = null
var combat_hazard_rect: ColorRect = null


class WaveConfig:
	var wave_num: int
	var title: String
	var total_projectiles: int
	var heavy_enemies_count: int
	var bile_spewers_count: int
	var charger_roaches_count: int
	var void_biles_count: int
	var bile_breeders_count: int = 0
	var is_boss_wave: bool
	var spawn_interval: float
	var min_speed: float
	var max_speed: float
	var max_spread_deg: float
	var allowed_types: Array[int]
	var allowed_patterns: Array[String]
	var heal_reward: int
	var score_reward: int


var current_wave_config: WaveConfig = null


var current_shop_context: String = "gameplay"


func _ready() -> void:
	_init_audio()

	var save_data: Dictionary = SaveManager.load_save_data()
	upgrade_points = int(save_data.get("upgrade_points", 3))

	if player:
		player.shield_level = int(save_data.get("shield_level", 0))
		player.speed_level = int(save_data.get("speed_level", 0))
		player.gun_level = int(save_data.get("gun_level", 0))
		player.speed = player.base_speed + float(player.speed_level) * 65.0
		player.current_shields = player.shield_level * 2
		if player.has_method("set_skin"):
			player.set_skin(str(save_data.get("selected_skin", "default")))
		player.health_changed.connect(_on_player_health_changed)
		player.shield_changed.connect(_on_player_shield_changed)
		player.player_died.connect(_on_player_died)
		player.set_physics_process(false)
		player.visible = false
		# Sync local main variables from centralized CombatBoundaryManager
		combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()
		boundary_hazard_dps = CombatBoundaryManager.get_damage_per_second()
		boundary_approach_dist = CombatBoundaryManager.get_approach_distance()
		boundary_line_color = CombatBoundaryManager.get_line_color()
		boundary_hazard_color = CombatBoundaryManager.get_hazard_color()

	if hud:
		hud.buy_upgrade_requested.connect(_on_buy_upgrade_requested)
		hud.reset_upgrades_requested.connect(_on_reset_upgrades_requested)
		hud.resume_wave_requested.connect(_on_resume_wave_requested)
		hud.start_game_requested.connect(_on_start_game_requested)
		hud.return_to_menu_requested.connect(_on_return_to_menu_requested)
		hud.level_selected.connect(_on_level_selected)
		hud.exit_to_level_select_requested.connect(_on_exit_to_level_select_requested)
		hud.open_upgrade_bay_requested.connect(_on_open_upgrade_bay_requested)
		hud.continue_to_next_level_requested.connect(_on_continue_to_next_level_requested)
		hud.replay_level_requested.connect(_on_replay_level_requested)
		hud.skin_selected.connect(_on_skin_selected)
		hud.comic_finished.connect(_on_comic_finished)
		hud.progress_reset_requested.connect(_on_progress_reset_requested)
		hud.update_upgrade_points(upgrade_points)
		hud.show_welcome_screen()

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.stop()
	current_wave = SaveManager.get_last_played_level()
	_update_background_for_stage(current_wave)
	_init_combat_boundary()
	pause_combat_boundary()


func _update_background_for_stage(stage_num: int) -> void:
	if is_instance_valid(starfield_canvas) and starfield_canvas.has_method("set_stage"):
		starfield_canvas.set_stage(stage_num)


func _get_enemy_texture_for_current_stage(enemy_type: String) -> Texture2D:
	return EnemyThemeManager.get_enemy_texture(enemy_theme_slots, enemy_type, current_wave)


func set_enemy_theme_slot(enemy_type: String, stage_group: Variant, texture_or_path: Variant) -> void:
	EnemyThemeManager.set_enemy_texture_slot(enemy_theme_slots, enemy_type, stage_group, texture_or_path)


func _on_start_game_requested() -> void:
	score = 0
	game_over = false
	var save_data: Dictionary = SaveManager.load_save_data()
	upgrade_points = int(save_data.get("upgrade_points", 3))
	hud.update_upgrade_points(upgrade_points)
	if player:
		player.shield_level = int(save_data.get("shield_level", player.shield_level))
		player.speed_level = int(save_data.get("speed_level", player.speed_level))
		player.gun_level = int(save_data.get("gun_level", player.gun_level))
	current_wave = SaveManager.get_last_played_level()
	_update_background_for_stage(current_wave)


var _pending_level_to_launch: int = 0


func _on_level_selected(level_num: int) -> void:
	if level_num == 1 and not SaveManager.has_seen_intro_comic():
		_pending_level_to_launch = level_num
		hud.hide_select_level()
		hud.show_comic("prologue", "launch")
		return
	_start_level_combat(level_num)


func _start_level_combat(level_num: int) -> void:
	get_tree().paused = false
	score = 0
	current_wave = level_num
	game_over = false
	SaveManager.set_last_played_level(current_wave)
	_update_background_for_stage(current_wave)

	var save_data: Dictionary = SaveManager.load_save_data()
	upgrade_points = int(save_data.get("upgrade_points", 3))

	if player:
		player.shield_level = int(save_data.get("shield_level", player.shield_level))
		player.speed_level = int(save_data.get("speed_level", player.speed_level))
		player.gun_level = int(save_data.get("gun_level", player.gun_level))
		player.current_health = player.max_health
		player.is_alive = true
		player.speed = player.base_speed + float(player.speed_level) * 65.0
		player.current_shields = player.shield_level * 2
		player.has_emergency_gun = false
		player.position = Vector2(250.0, 540.0)
		player.visible = true
		player.set_physics_process(false)
		var active_skin: String = SaveManager.get_selected_skin()
		player.set_skin(active_skin)
		if player.has_method("_update_shield_visual"):
			player._update_shield_visual()
		if player.has_method("_update_gun_visual"):
			player._update_gun_visual()

		hud.update_health(player.current_health, player.max_health)
		hud.update_shield(player.current_shields, player.shield_level * 2)
		hud.update_gun_status(player.gun_level, player.has_emergency_gun)

	hud.update_score(score)
	hud.update_upgrade_points(upgrade_points)
	hud.set_hud_stats_visible(true)
	if hud.has_method("set_virtual_joystick_visible"):
		hud.set_virtual_joystick_visible(false, false)
	if hud.has_method("set_mobile_fire_button_visible"):
		hud.set_mobile_fire_button_visible(false, false)

	hud.fade_from_black(0.35, func():
		_start_wave_intro(current_wave)
	)


func _on_comic_finished(comic_id: String) -> void:
	if comic_id == "prologue":
		SaveManager.set_intro_comic_seen(true)
		if _pending_level_to_launch > 0:
			var target_lvl: int = _pending_level_to_launch
			_pending_level_to_launch = 0
			_start_level_combat(target_lvl)
		else:
			# Player reviewed story from Select Level menu!
			# Return cleanly to Select Level menu (do NOT launch combat)
			var save_data: Dictionary = SaveManager.load_save_data()
			var last_stage: int = SaveManager.get_last_played_level()
			_update_background_for_stage(last_stage)
			hud.show_select_level(
				int(save_data.get("unlocked_level", 1)),
				int(save_data.get("upgrade_points", 3))
			)
	elif comic_id == "epilogue":
		SaveManager.set_ending_comic_seen(true)
		current_state = GameState.CLEARED
		var save_res: Dictionary = SaveManager.record_game_result(score, current_wave)
		hud.show_victory(score, bool(save_res.get("is_new_record", false)))


func _on_exit_to_level_select_requested() -> void:
	get_tree().paused = false
	game_over = false
	current_state = GameState.MENU
	pause_combat_boundary()
	spawn_timer.stop()

	if music_manager:
		music_manager.play_menu_music(0.5)

	_clean_up_all_minions_and_projectiles()
	for b in active_bosses:
		if is_instance_valid(b):
			b.queue_free()
	active_bosses.clear()

	if player:
		player.set_physics_process(false)
		player.visible = false

	var save_data: Dictionary = SaveManager.load_save_data()
	var last_stage: int = SaveManager.get_last_played_level()
	_update_background_for_stage(last_stage)
	hud.show_select_level(
		int(save_data.get("unlocked_level", 1)),
		int(save_data.get("upgrade_points", 3))
	)


func _on_open_upgrade_bay_requested(context: String) -> void:
	current_shop_context = context
	if context == "level_completed":
		hud.hide_level_completed()
	elif context == "level_lost":
		hud.hide_level_lost()
	_refresh_shop()


func _on_replay_level_requested() -> void:
	get_tree().paused = false
	game_over = false
	current_state = GameState.MENU
	spawn_timer.stop()

	_clean_up_all_minions_and_projectiles()
	for b in active_bosses:
		if is_instance_valid(b):
			b.queue_free()
	active_bosses.clear()

	hud.fade_to_black(0.35, func():
		_on_level_selected(current_wave)
	)


func _on_continue_to_next_level_requested() -> void:
	if current_wave >= 20:
		hud.hide_level_completed()
		if player:
			player.set_physics_process(false)
			player.visible = false
		if music_manager:
			music_manager.play_menu_music(1.0)
		hud.show_comic("epilogue", "victory")
		return

	hud.fade_to_black(0.35, func():
		current_wave += 1
		SaveManager.set_last_played_level(current_wave)
		_update_background_for_stage(current_wave)
		if player:
			player.position = Vector2(250.0, 540.0)
			player.set_physics_process(false)
			player.current_health = player.max_health
			player.is_alive = true
			player.recharge_shield()
			var active_skin: String = SaveManager.get_selected_skin()
			player.set_skin(active_skin)
			hud.update_health(player.current_health, player.max_health)
			hud.update_shield(player.current_shields, player.shield_level * 2)

		# Ensure gameplay HUD and mobile controls are restored when continuing to next level
		hud.set_hud_stats_visible(true)
		if hud.has_method("set_virtual_joystick_visible"):
			hud.set_virtual_joystick_visible(false, false)
		if hud.has_method("set_mobile_fire_button_visible"):
			hud.set_mobile_fire_button_visible(false, false)

		hud.fade_from_black(0.35, func():
			_start_wave_intro(current_wave)
		)
	)


func _on_skin_selected(skin_id: String) -> void:
	SaveManager.set_selected_skin(skin_id)
	if player and player.has_method("set_skin"):
		player.set_skin(skin_id)


func _on_progress_reset_requested() -> void:
	var save_data: Dictionary = SaveManager.load_save_data()
	upgrade_points = int(save_data.get("upgrade_points", 3))
	hud.update_upgrade_points(upgrade_points)
	if player:
		player.shield_level = int(save_data.get("shield_level", 0))
		player.speed_level = int(save_data.get("speed_level", 0))
		player.gun_level = int(save_data.get("gun_level", 0))
		player.has_emergency_gun = false
		player.speed = player.base_speed
		player.current_shields = 0
		if player.has_method("set_skin"):
			player.set_skin("default")
		if player.has_method("_update_shield_visual"):
			player._update_shield_visual()
		if player.has_method("_update_gun_visual"):
			player._update_gun_visual()
	current_wave = 1
	_update_background_for_stage(1)



func _on_return_to_menu_requested() -> void:
	game_over = false
	current_state = GameState.MENU
	pause_combat_boundary()
	spawn_timer.stop()

	if music_manager:
		music_manager.play_menu_music(0.5)

	_clean_up_all_minions_and_projectiles()
	for b in active_bosses:
		if is_instance_valid(b):
			b.queue_free()
	active_bosses.clear()

	if player:
		player.set_physics_process(false)
		player.visible = false

	var last_stage: int = SaveManager.get_last_played_level()
	_update_background_for_stage(last_stage)

	if hud:
		hud.show_welcome_screen()


func _process(_delta: float) -> void:
	if current_state == GameState.ACTIVE and current_wave_config and not current_wave_config.is_boss_wave:
		_check_wave_completion()
	_update_combat_boundary_visual()


func _init_combat_boundary() -> void:
	var v_size: Vector2 = get_viewport_rect().size if get_viewport_rect().size.x > 0.0 else Vector2(1920.0, 1080.0)
	var total_h: float = maxf(v_size.y, 4000.0)
	var total_w: float = maxf(v_size.x, 4000.0)
	var bound_ratio: float = CombatBoundaryManager.get_boundary_ratio()
	var bound_x: float = v_size.x * bound_ratio

	# 1. Hazard Zone Background Overlay (Translucent danger field over right sector, fills to bottom)
	if combat_hazard_rect == null:
		combat_hazard_rect = ColorRect.new()
		combat_hazard_rect.name = "CombatHazardRect"
		combat_hazard_rect.position = Vector2(bound_x, -500.0)
		combat_hazard_rect.size = Vector2(total_w - bound_x + 1000.0, total_h + 1000.0)
		combat_hazard_rect.color = Color(0.9, 0.05, 0.05, 0.0)
		combat_hazard_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combat_hazard_rect.z_index = -2
		combat_hazard_rect.visible = false
		add_child(combat_hazard_rect)

	# 2. Polished Neon Crimson Perimeter Line (initially invisible, reveals on approach)
	if combat_boundary_line == null:
		combat_boundary_line = Line2D.new()
		combat_boundary_line.name = "CombatBoundaryLine"
		combat_boundary_line.width = 3.5
		combat_boundary_line.default_color = Color(1.0, 0.22, 0.22, 0.0) # Initially invisible
		combat_boundary_line.add_point(Vector2(bound_x, -2000.0))
		combat_boundary_line.add_point(Vector2(bound_x, total_h + 500.0))
		combat_boundary_line.z_index = -1
		combat_boundary_line.visible = false
		add_child(combat_boundary_line)


func _update_combat_boundary_visual() -> void:
	if combat_boundary_line == null:
		return

	if current_state == GameState.ACTIVE or current_state == GameState.INTRO:
		var v_size: Vector2 = get_viewport_rect().size if get_viewport_rect().size.x > 0.0 else Vector2(1920.0, 1080.0)
		var total_h: float = maxf(v_size.y, 4000.0)
		var total_w: float = maxf(v_size.x, 4000.0)
		var bound_ratio: float = CombatBoundaryManager.get_boundary_ratio()
		var bound_x: float = v_size.x * bound_ratio
		combat_boundary_ratio = bound_ratio

		# Dynamically ensure boundary line and hazard area always fill the full gap to the very bottom
		if combat_boundary_line.get_point_count() >= 2:
			combat_boundary_line.set_point_position(0, Vector2(bound_x, -500.0))
			combat_boundary_line.set_point_position(1, Vector2(bound_x, total_h + 500.0))
		if combat_hazard_rect:
			combat_hazard_rect.position = Vector2(bound_x, -500.0)
			combat_hazard_rect.size = Vector2(total_w - bound_x + 1000.0, total_h + 1000.0)

		if player and is_instance_valid(player):
			var is_crossed: bool = player.position.x > bound_x
			if is_crossed:
				# Beyond perimeter: line and hazard field fully active with pulsing warning alarm
				combat_boundary_line.visible = true
				if combat_hazard_rect:
					combat_hazard_rect.visible = true
				var pulse_hazard: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.010)
				combat_boundary_line.default_color = Color(1.0, 0.1, 0.1, 0.85 + 0.15 * pulse_hazard)
				combat_boundary_line.width = 4.0 + 1.5 * pulse_hazard
				if combat_hazard_rect:
					combat_hazard_rect.color = Color(0.95, 0.05, 0.05, 0.10 + 0.05 * pulse_hazard)
				if hud and hud.has_method("set_airspace_warning_visible"):
					hud.set_airspace_warning_visible(true)
			else:
				var approach_dist: float = 350.0
				var mgr_approach_dist: float = CombatBoundaryManager.get_approach_distance()
				if mgr_approach_dist > 0.0:
					approach_dist = mgr_approach_dist
				var line_col: Color = CombatBoundaryManager.get_line_color()
				var haz_col: Color = CombatBoundaryManager.get_hazard_color()
				var dist_to_line: float = bound_x - player.position.x
				if dist_to_line <= approach_dist and dist_to_line >= 0.0:
					# Approaching perimeter: line and hazard area gradually fade into view
					var proximity: float = clampf(1.0 - (dist_to_line / approach_dist), 0.0, 1.0)
					var alpha_factor: float = proximity * proximity # Smooth ease-in
					combat_boundary_line.visible = true
					combat_boundary_line.default_color = Color(line_col.r, line_col.g, line_col.b, line_col.a * alpha_factor)
					combat_boundary_line.width = lerpf(1.5, 3.5, alpha_factor)
					if combat_hazard_rect:
						combat_hazard_rect.visible = true
						combat_hazard_rect.color = Color(haz_col.r, haz_col.g, haz_col.b, haz_col.a * alpha_factor)
				else:
					# Far away in safe airspace: line and hazard area are completely invisible
					combat_boundary_line.visible = false
					combat_boundary_line.default_color = Color(1.0, 0.22, 0.22, 0.0)
					if combat_hazard_rect:
						combat_hazard_rect.visible = false
						combat_hazard_rect.color = Color(0.9, 0.05, 0.05, 0.0)

				if hud and hud.has_method("set_airspace_warning_visible"):
					hud.set_airspace_warning_visible(false)
	else:
		pause_combat_boundary()


## Sets the boundary starting ratio from the left edge of the screen (0.05 to 0.95).
## Example: 0.60 sets boundary at 60% from left (40% danger zone on right).
func set_combat_boundary_ratio(ratio: float) -> void:
	CombatBoundaryManager.set_boundary_ratio(ratio)
	combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()
	_update_combat_boundary_visual()


## Sets the boundary starting position by specifying the percentage or ratio from the right edge of the screen.
## Examples:
## - set_boundary_from_right(0.40) or set_boundary_from_right(40.0): boundary starts 40% from right (line at 60% from left).
## - set_boundary_from_right(0.60) or set_boundary_from_right(60.0): boundary starts 60% from right (line at 40% from left).
func set_boundary_from_right(percentage_or_ratio: float) -> void:
	CombatBoundaryManager.set_boundary_from_right(percentage_or_ratio)
	combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()
	_update_combat_boundary_visual()


## Returns the active boundary ratio measured from the left edge (0.0 to 1.0).
func get_combat_boundary_ratio() -> float:
	return CombatBoundaryManager.get_boundary_ratio()


## Returns the active danger zone coverage ratio from the right edge (0.0 to 1.0).
func get_danger_zone_from_right_ratio() -> float:
	return CombatBoundaryManager.get_danger_zone_from_right_ratio()


## Returns the absolute X position in pixels where the danger boundary begins.
func get_combat_boundary_x() -> float:
	var v_size: Vector2 = get_viewport_rect().size if get_viewport_rect().size.x > 0.0 else Vector2(1920.0, 1080.0)
	return CombatBoundaryManager.get_boundary_x(v_size.x)


## Pauses the combat boundary hazard field (environmental damage, line, and warnings)
func pause_combat_boundary() -> void:
	if player and player.has_method("pause_boundary_hazard"):
		player.pause_boundary_hazard()
	if combat_boundary_line:
		combat_boundary_line.visible = false
	if combat_hazard_rect:
		combat_hazard_rect.visible = false
	if hud and hud.has_method("set_airspace_warning_visible"):
		hud.set_airspace_warning_visible(false)


## Resumes the combat boundary hazard field when active combat resumes
func resume_combat_boundary() -> void:
	if player and player.has_method("resume_boundary_hazard"):
		player.resume_boundary_hazard()


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.physical_keycode == KEY_M:
			_on_return_to_menu_requested()


func _get_wave_config(wave_num: int) -> WaveConfig:
	var cfg_dict: Dictionary = StageSpawnManager.get_stage_config(wave_num)
	var cfg: WaveConfig = WaveConfig.new()
	cfg.wave_num = wave_num
	cfg.is_boss_wave = bool(cfg_dict.get("is_boss_stage", false))
	cfg.title = str(cfg_dict.get("title", "Wave %d" % wave_num))
	cfg.total_projectiles = int(cfg_dict.get("projectiles", 0))
	cfg.heavy_enemies_count = int(cfg_dict.get("heavy_enemies", 0))
	cfg.bile_spewers_count = int(cfg_dict.get("bile_spewers", 0))
	cfg.charger_roaches_count = int(cfg_dict.get("charger_roaches", 0))
	cfg.void_biles_count = int(cfg_dict.get("void_biles", 0))
	cfg.bile_breeders_count = int(cfg_dict.get("bile_breeders", 0))
	cfg.spawn_interval = float(cfg_dict.get("spawn_interval", 1.0))
	cfg.min_speed = float(cfg_dict.get("min_speed", 350.0))
	cfg.max_speed = float(cfg_dict.get("max_speed", 550.0))
	cfg.max_spread_deg = float(cfg_dict.get("max_spread_deg", 15.0))
	var raw_types: Array = cfg_dict.get("allowed_types", [0])
	var typed_types: Array[int] = []
	for t in raw_types:
		typed_types.append(int(t))
	cfg.allowed_types = typed_types
	var raw_patterns: Array = cfg_dict.get("allowed_patterns", ["single"])
	var typed_patterns: Array[String] = []
	for p in raw_patterns:
		typed_patterns.append(str(p))
	cfg.allowed_patterns = typed_patterns
	cfg.heal_reward = int(cfg_dict.get("heal_reward", 20))
	cfg.score_reward = int(cfg_dict.get("score_reward", wave_num * 100))
	return cfg


func _start_wave_intro(wave_num: int) -> void:
	if game_over:
		return

	current_state = GameState.INTRO
	current_wave = wave_num
	current_wave_config = _get_wave_config(wave_num)
	SaveManager.set_last_played_level(wave_num)
	EnemyProjectileDatabase.set_current_stage(wave_num)
	_update_background_for_stage(wave_num)
	projectiles_spawned_in_wave = 0
	active_projectiles_count = 0
	active_heavy_enemies = 0
	active_bile_spewers = 0
	active_charger_roaches = 0
	active_void_biles = 0
	active_bile_breeders = 0
	heavy_enemies_spawned_in_wave = 0
	bile_spewers_spawned_in_wave = 0
	charger_roaches_spawned_in_wave = 0
	void_biles_spawned_in_wave = 0
	bile_breeders_spawned_in_wave = 0
	active_bosses.clear()

	for child in get_children():
		if child is Area2D and (child.is_in_group("enemy_projectiles") or child.is_in_group("heavy_enemies") or child.is_in_group("bile_spewers") or child.is_in_group("charger_roach") or child.is_in_group("void_bile") or child.is_in_group("bile_breeders") or child.is_in_group("boss")):
			child.queue_free()

	if player:
		player.set_physics_process(false)
		player.position = Vector2(250.0, 540.0)
		player.current_health = player.max_health
		player.is_alive = true
		player.recharge_shield()
		var active_skin: String = SaveManager.get_selected_skin()
		player.set_skin(active_skin)
		hud.update_health(player.current_health, player.max_health)
		hud.update_shield(player.current_shields, player.shield_level * 2)

		# Emergency Blaster check before Boss Battle
		if current_wave_config.is_boss_wave and player.gun_level <= 0:
			player.equip_free_emergency_gun()

		hud.update_gun_status(player.gun_level, player.has_emergency_gun)

	# Ensure combat boundary is loaded and presented immediately as stage loads
	resume_combat_boundary()
	_update_combat_boundary_visual()

	hud.update_wave(wave_num, current_wave_config.title)
	hud.set_hud_stats_visible(true)
	if hud.has_method("set_virtual_joystick_visible"):
		hud.set_virtual_joystick_visible(false, false)
	if hud.has_method("set_mobile_fire_button_visible"):
		hud.set_mobile_fire_button_visible(false, false)

	var subtitle: String = current_wave_config.title.to_upper()
	if current_wave_config.is_boss_wave:
		subtitle = "DESTROY THE ENEMY COMMAND BEFORE THEY ARRIVE!"

	hud.show_wave_banner(
		"WAVE %d" % wave_num,
		subtitle,
		2.4,
		Color(1.0, 0.25, 0.25) if current_wave_config.is_boss_wave else Color(1.0, 0.9, 0.25)
	)

	if current_wave_config.is_boss_wave:
		hud.update_wave_progress(1, 1)
	else:
		hud.update_wave_progress(current_wave_config.total_projectiles, current_wave_config.total_projectiles)

	if music_manager:
		music_manager.play_stage_music(wave_num, current_wave_config.is_boss_wave)

	if current_wave_config.is_boss_wave:
		SoundManager.play_sfx("boss_warning")
	_play_sfx(sfx_wave_start)

	var intro_timer: SceneTreeTimer = get_tree().create_timer(2.4)
	intro_timer.timeout.connect(func():
		if not game_over and current_state == GameState.INTRO:
			_start_wave_active()
	)


func _start_wave_active() -> void:
	if game_over:
		return

	current_state = GameState.ACTIVE
	if player and is_instance_valid(player):
		player.set_physics_process(true)
	resume_combat_boundary()
	hud.set_hud_stats_visible(true)
	if hud.has_method("set_virtual_joystick_visible"):
		hud.set_virtual_joystick_visible(true, true)
	if hud.has_method("set_mobile_fire_button_visible"):
		hud.set_mobile_fire_button_visible(true, true)

	if current_wave_config.is_boss_wave:
		_spawn_boss_encounter()
	else:
		spawn_timer.wait_time = current_wave_config.spawn_interval
		spawn_timer.start()


func _spawn_boss_encounter() -> void:
	active_bosses.clear()

	var stage_cfg: Dictionary = StageSpawnManager.get_stage_config(current_wave)
	var boss_list: Array = stage_cfg.get("bosses", [])
	var bar_title: String = str(stage_cfg.get("boss_bar_title", stage_cfg.get("title", "BOSS ENCOUNTER")))
	var stage_level_minion_summon: bool = bool(stage_cfg.get("minion_summon", false))

	for boss_data: Dictionary in boss_list:
		var b_type: String = str(boss_data.get("type", "dreadnought")).to_lower()
		var b_pos: Vector2 = boss_data.get("position", Vector2(1950.0, 540.0))
		var b_hp: int = int(boss_data.get("health", 200))
		var b_speed: float = float(boss_data.get("speed_multiplier", 1.0))
		var b_target_y: float = float(boss_data.get("target_y", b_pos.y))
		var minion_summon: bool = bool(boss_data.get("minion_summon", stage_level_minion_summon))

		var boss_inst: Area2D = null
		if b_type == "dragon_roach" or b_type == "roach" or b_type == "ship" or b_type == "boss_ship":
			if dragon_roach_scene:
				boss_inst = dragon_roach_scene.instantiate() as Area2D
		else:
			# Default to dreadnought / standard boss
			if boss_scene:
				boss_inst = boss_scene.instantiate() as Area2D

		if boss_inst:
			boss_inst.position = b_pos

			# Universal minion summoning hook for ANY boss
			if minion_summon and boss_inst.has_signal("minion_spawn_requested"):
				boss_inst.minion_spawn_requested.connect(_on_boss_minion_spawn_requested)

			if "minion_summon" in boss_inst:
				boss_inst.set("minion_summon", minion_summon)

			if boss_inst.has_method("setup_boss"):
				boss_inst.setup_boss(b_hp, b_target_y, b_speed, minion_summon)
			elif "max_health" in boss_inst:
				boss_inst.set("max_health", b_hp)

			_register_boss_instance(boss_inst)
			add_child(boss_inst)

	hud.show_boss_bar(bar_title, _get_total_boss_hp(), _get_total_boss_max_hp())


func _register_boss_instance(boss: Area2D) -> void:
	active_bosses.append(boss)
	boss.health_changed.connect(func(_c, _m):
		hud.update_boss_health(_get_total_boss_hp(), _get_total_boss_max_hp())
	)
	boss.boss_defeated.connect(func():
		_on_individual_boss_defeated(boss)
	)
	boss.boss_reached_player.connect(_on_boss_reached_player)


func _get_total_boss_hp() -> int:
	var total: int = 0
	for b in active_bosses:
		if is_instance_valid(b):
			total += int(b.get("current_health"))
	return total


func _get_total_boss_max_hp() -> int:
	var total: int = 0
	for b in active_bosses:
		if is_instance_valid(b):
			total += int(b.get("max_health"))
	return total


func _on_individual_boss_defeated(boss: Area2D) -> void:
	if active_bosses.has(boss):
		active_bosses.erase(boss)

	SoundManager.play_sfx("boss_explode")
	hud.update_boss_health(_get_total_boss_hp(), _get_total_boss_max_hp())

	if active_bosses.is_empty():
		_on_all_bosses_defeated()


func _on_all_bosses_defeated() -> void:
	if current_state != GameState.ACTIVE:
		return

	current_state = GameState.CLEARED
	pause_combat_boundary()

	# Sprint 1: In boss rounds, immediately destroy all remaining minions and stray projectiles
	_clean_up_all_minions_and_projectiles()

	hud.hide_boss_bar()

	score += current_wave_config.score_reward

	# Balancing: Upgrade points are strictly one-time per level (cannot earn points on replay)
	var can_claim: bool = SaveManager.can_claim_level_reward(current_wave)
	var pts_reward: int = 0
	if can_claim:
		pts_reward = SaveManager.claim_level_reward(current_wave, 3)
		upgrade_points += pts_reward
	else:
		pts_reward = 0

	var is_first_time: bool = SaveManager.mark_level_completed(current_wave)
	SaveManager.unlock_level(current_wave + 1)
	if player:
		SaveManager.save_player_state(
			upgrade_points,
			player.shield_level,
			player.speed_level,
			player.gun_level,
			player.current_skin
		)
	hud.update_score(score)
	hud.update_upgrade_points(upgrade_points)

	if player and player.has_method("heal"):
		player.heal(current_wave_config.heal_reward)

	_play_sfx(sfx_wave_clear)

	# Round 20 Galactic Victory Condition - Epilogue Comic Cutscene
	if current_wave == 20:
		current_state = GameState.CLEARED
		if music_manager:
			music_manager.play_menu_music(1.2)
		var epilogue_title: String = "FINAL TITANS DESTROYED!"
		var epilogue_subtitle: String = "MALAY'S REALM SAVED!  |  +%d BONUS PTS" % current_wave_config.score_reward
		hud.show_wave_banner(
			epilogue_title,
			epilogue_subtitle,
			2.2,
			Color(0.3, 1.0, 0.45)
		)
		var epilogue_timer: SceneTreeTimer = get_tree().create_timer(1.8)
		epilogue_timer.timeout.connect(func():
			if not game_over and current_state == GameState.CLEARED:
				if player:
					player.set_physics_process(false)
					player.visible = false
				hud.show_comic("epilogue", "victory")
		)
		return

	var banner_title: String = "BOSS DESTROYED!"
	match current_wave:
		5: banner_title = "WAURIOR DESTROYED!"
		10: banner_title = "MINANGKABAU SHIP DESTROYED!"
		15: banner_title = "TWIN WAURIOR DESTROYED!"
		_: banner_title = "VENGENCE CRUSHED!"

	var banner_subtitle: String = ""
	if can_claim:
		banner_subtitle = "+3 UPGRADE POINTS  |  +%d BONUS PTS" % current_wave_config.score_reward
	else:
		banner_subtitle = "BOSS RE-DEFEATED  |  +0 UPGRADE PTS (ALREADY CLAIMED)  |  +%d BONUS PTS" % current_wave_config.score_reward

	hud.show_wave_banner(
		banner_title,
		banner_subtitle,
		2.4,
		Color(0.3, 1.0, 0.45)
	)

	current_state = GameState.CLEARED
	var completion_timer: SceneTreeTimer = get_tree().create_timer(2.0)
	completion_timer.timeout.connect(func():
		if not game_over and current_state == GameState.CLEARED:
			hud.show_level_completed(
				current_wave,
				score,
				pts_reward,
				current_wave < 20,
				can_claim or is_first_time
			)
	)


func _clean_up_all_minions_and_projectiles() -> void:
	for child in get_children():
		if not is_instance_valid(child):
			continue
		if child is Area2D:
			if child.is_in_group("enemy_projectiles"):
				if child.has_method("hit_by_player_projectile"):
					child.hit_by_player_projectile()
				else:
					child.queue_free()
			elif child.is_in_group("enemy_units") and not child.is_in_group("boss"):
				if child.has_method("die"):
					child.die()
				else:
					child.queue_free()

	active_heavy_enemies = 0
	active_bile_spewers = 0
	active_charger_roaches = 0
	active_void_biles = 0
	active_bile_breeders = 0
	active_projectiles_count = 0


func _on_boss_reached_player() -> void:
	if player and player.has_method("take_damage"):
		player.take_damage(100)


func _is_wave_spawning_complete() -> bool:
	if not current_wave_config or current_wave_config.is_boss_wave:
		return true
	var projs_done: bool = projectiles_spawned_in_wave >= current_wave_config.total_projectiles
	var heavy_done: bool = heavy_enemies_spawned_in_wave >= current_wave_config.heavy_enemies_count
	var bile_done: bool = bile_spewers_spawned_in_wave >= current_wave_config.bile_spewers_count
	var charger_done: bool = charger_roaches_spawned_in_wave >= current_wave_config.charger_roaches_count
	var void_done: bool = void_biles_spawned_in_wave >= current_wave_config.void_biles_count
	var breeder_done: bool = bile_breeders_spawned_in_wave >= current_wave_config.bile_breeders_count
	return projs_done and heavy_done and bile_done and charger_done and void_done and breeder_done


func _on_spawn_timer_timeout() -> void:
	if game_over or current_state != GameState.ACTIVE or not is_instance_valid(player):
		return

	# If all quota for the wave has already been spawned, stop timer and check completion
	if _is_wave_spawning_complete():
		spawn_timer.stop()
		_check_wave_completion()
		return

	# 1. Spawn scheduled Heavy Enemy (Tank)
	if current_wave_config.heavy_enemies_count > 0 and heavy_enemies_spawned_in_wave < current_wave_config.heavy_enemies_count:
		var heavy_threshold: int = current_wave_config.total_projectiles / (current_wave_config.heavy_enemies_count + 1)
		if projectiles_spawned_in_wave >= heavy_threshold:
			_spawn_heavy_enemy()

	# 2. Spawn scheduled Bile Spewer
	if current_wave_config.bile_spewers_count > 0 and bile_spewers_spawned_in_wave < current_wave_config.bile_spewers_count:
		var bile_threshold: int = (current_wave_config.total_projectiles * 2) / (current_wave_config.bile_spewers_count + 2)
		if projectiles_spawned_in_wave >= bile_threshold:
			_spawn_bile_spewer()

	# 3. Spawn scheduled Charger Roach (Waves 6++)
	if current_wave_config.charger_roaches_count > 0 and charger_roaches_spawned_in_wave < current_wave_config.charger_roaches_count:
		var charger_threshold: int = (current_wave_config.total_projectiles * 1) / (current_wave_config.charger_roaches_count + 1)
		if projectiles_spawned_in_wave >= charger_threshold:
			_spawn_charger_roach()

	# 4. Spawn scheduled Void Bile (Waves 6++)
	if current_wave_config.void_biles_count > 0 and void_biles_spawned_in_wave < current_wave_config.void_biles_count:
		var void_threshold: int = (current_wave_config.total_projectiles * 2) / (current_wave_config.void_biles_count + 1)
		if projectiles_spawned_in_wave >= void_threshold:
			_spawn_void_bile()

	# 5. Spawn scheduled Bile Breeder (Waves 8++)
	if current_wave_config.bile_breeders_count > 0 and bile_breeders_spawned_in_wave < current_wave_config.bile_breeders_count:
		var breeder_threshold: int = (current_wave_config.total_projectiles * 1) / (current_wave_config.bile_breeders_count + 1)
		if projectiles_spawned_in_wave >= breeder_threshold:
			_spawn_bile_breeder()

	# 6. Spawn projectile quota
	var remaining_projectiles: int = current_wave_config.total_projectiles - projectiles_spawned_in_wave
	if remaining_projectiles > 0:
		var candidate_patterns: Array[String] = []
		for p: String in current_wave_config.allowed_patterns:
			match p:
				"single", "zone_denial":
					candidate_patterns.append(p)
				"twin_spread", "stream", "pincer_trap":
					if remaining_projectiles >= 2:
						candidate_patterns.append(p)
				"fan_burst":
					if remaining_projectiles >= 3:
						candidate_patterns.append(p)

		if candidate_patterns.is_empty():
			candidate_patterns.append("single")

		var selected_pattern: String = candidate_patterns.pick_random()
		_execute_spawn_pattern(selected_pattern, remaining_projectiles)

	if _is_wave_spawning_complete():
		spawn_timer.stop()
		_check_wave_completion()


func _spawn_heavy_enemy() -> void:
	if not heavy_enemy_scene or game_over:
		return

	var heavy: Area2D = heavy_enemy_scene.instantiate() as Area2D
	if not heavy:
		return

	var heavy_tex: Texture2D = _get_enemy_texture_for_current_stage("heavy")
	if heavy_tex and heavy.has_method("set_enemy_texture"):
		heavy.set_enemy_texture(heavy_tex)

	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(160.0, viewport_size.y - 160.0)
	heavy.position = Vector2(viewport_size.x + 60.0, spawn_y)

	heavy_enemies_spawned_in_wave += 1
	active_heavy_enemies += 1
	heavy.destroyed.connect(func():
		SoundManager.play_sfx("heavy_explode")
		score += 50
		hud.update_score(score)
		active_heavy_enemies = maxi(0, active_heavy_enemies - 1)
		_check_wave_completion()
	)
	heavy.escaped.connect(func():
		active_heavy_enemies = maxi(0, active_heavy_enemies - 1)
		_check_wave_completion()
	)

	add_child(heavy)


func _spawn_bile_spewer() -> void:
	if not bile_spewer_scene or game_over:
		return

	var spewer: Area2D = bile_spewer_scene.instantiate() as Area2D
	if not spewer:
		return

	var spewer_tex: Texture2D = _get_enemy_texture_for_current_stage("spewer")
	if spewer_tex and spewer.has_method("set_enemy_texture"):
		spewer.set_enemy_texture(spewer_tex)

	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(160.0, viewport_size.y - 160.0)
	spewer.position = Vector2(viewport_size.x + 60.0, spawn_y)

	bile_spewers_spawned_in_wave += 1
	active_bile_spewers += 1
	spewer.destroyed.connect(func():
		SoundManager.play_sfx("enemy_explode")
		score += 40
		hud.update_score(score)
		active_bile_spewers = maxi(0, active_bile_spewers - 1)
		_check_wave_completion()
	)
	spewer.escaped.connect(func():
		active_bile_spewers = maxi(0, active_bile_spewers - 1)
		_check_wave_completion()
	)

	add_child(spewer)


func _spawn_charger_roach() -> void:
	if not charger_roach_scene or game_over:
		return

	var charger: Area2D = charger_roach_scene.instantiate() as Area2D
	if not charger:
		return

	var charger_tex: Texture2D = _get_enemy_texture_for_current_stage("charger")
	if charger_tex and charger.has_method("set_enemy_texture"):
		charger.set_enemy_texture(charger_tex)

	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(160.0, viewport_size.y - 160.0)
	charger.position = Vector2(viewport_size.x + 60.0, spawn_y)

	charger_roaches_spawned_in_wave += 1
	active_charger_roaches += 1
	charger.destroyed.connect(func():
		SoundManager.play_sfx("enemy_explode")
		score += 60
		hud.update_score(score)
		active_charger_roaches = maxi(0, active_charger_roaches - 1)
		_check_wave_completion()
	)
	charger.escaped.connect(func():
		active_charger_roaches = maxi(0, active_charger_roaches - 1)
		_check_wave_completion()
	)

	add_child(charger)


func _spawn_void_bile() -> void:
	if not void_bile_scene or game_over:
		return

	var void_enemy: Area2D = void_bile_scene.instantiate() as Area2D
	if not void_enemy:
		return

	var void_tex: Texture2D = _get_enemy_texture_for_current_stage("void")
	if void_tex and void_enemy.has_method("set_enemy_texture"):
		void_enemy.set_enemy_texture(void_tex)

	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(160.0, viewport_size.y - 160.0)
	void_enemy.position = Vector2(viewport_size.x + 60.0, spawn_y)

	void_biles_spawned_in_wave += 1
	active_void_biles += 1
	void_enemy.destroyed.connect(func():
		SoundManager.play_sfx("enemy_explode")
		score += 50
		hud.update_score(score)
		active_void_biles = maxi(0, active_void_biles - 1)
		_check_wave_completion()
	)
	void_enemy.escaped.connect(func():
		active_void_biles = maxi(0, active_void_biles - 1)
		_check_wave_completion()
	)

	add_child(void_enemy)


func _spawn_bile_breeder() -> void:
	if not bile_breeder_scene or game_over:
		return

	var breeder: Area2D = bile_breeder_scene.instantiate() as Area2D
	if not breeder:
		return

	var breeder_tex: Texture2D = _get_enemy_texture_for_current_stage("breeder")
	if breeder_tex and breeder.has_method("set_enemy_texture"):
		breeder.set_enemy_texture(breeder_tex)

	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(160.0, viewport_size.y - 160.0)
	breeder.position = Vector2(viewport_size.x + 60.0, spawn_y)

	bile_breeders_spawned_in_wave += 1
	active_bile_breeders += 1
	breeder.destroyed.connect(func():
		SoundManager.play_sfx("heavy_explode")
		score += 80
		hud.update_score(score)
		active_bile_breeders = maxi(0, active_bile_breeders - 1)
		_check_wave_completion()
	)
	breeder.escaped.connect(func():
		active_bile_breeders = maxi(0, active_bile_breeders - 1)
		_check_wave_completion()
	)

	add_child(breeder)


func spawn_bred_void_bile(spawn_pos: Vector2) -> void:
	if not void_bile_scene or game_over or current_state != GameState.ACTIVE:
		return

	var baby: Area2D = void_bile_scene.instantiate() as Area2D
	if not baby:
		return

	var void_tex: Texture2D = _get_enemy_texture_for_current_stage("void")
	if void_tex and baby.has_method("set_enemy_texture"):
		baby.set_enemy_texture(void_tex)

	baby.position = spawn_pos
	active_void_biles += 1
	baby.destroyed.connect(func():
		SoundManager.play_sfx("enemy_explode")
		score += 50
		hud.update_score(score)
		active_void_biles = maxi(0, active_void_biles - 1)
		_check_wave_completion()
	)
	baby.escaped.connect(func():
		active_void_biles = maxi(0, active_void_biles - 1)
		_check_wave_completion()
	)

	add_child(baby)


func _on_boss_minion_spawn_requested(group_id: int) -> void:
	if game_over or current_state != GameState.ACTIVE:
		return

	match group_id:
		0:
			# Greeting: 2 tanks and 1 bile spewer
			_spawn_heavy_enemy()
			_spawn_heavy_enemy()
			_spawn_bile_spewer()
		1:
			# Group 1: 1 Tank, 1 Bile Spewer, 1 Charger, 1 Void Bile
			_spawn_heavy_enemy()
			_spawn_bile_spewer()
			_spawn_charger_roach()
			_spawn_void_bile()
		2:
			# Group 2: 3 Charger, 2 Void
			_spawn_charger_roach()
			_spawn_charger_roach()
			_spawn_charger_roach()
			_spawn_void_bile()
			_spawn_void_bile()
		3:
			# Group 3: 3 Bile Spewer, 1 Tank
			_spawn_bile_spewer()
			_spawn_bile_spewer()
			_spawn_bile_spewer()
			_spawn_heavy_enemy()
		4:
			# Group 4: 5 Void Bile
			for i in range(5):
				_spawn_void_bile()


func _on_dragon_minion_spawn_requested(group_id: int) -> void:
	_on_boss_minion_spawn_requested(group_id)


func _execute_spawn_pattern(pattern: String, remaining_quota: int) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = randf_range(70.0, viewport_size.y - 70.0)
	var spawn_pos: Vector2 = Vector2(viewport_size.x + 30.0, spawn_y)

	var player_y: float = player.global_position.y if player else 540.0
	var player_x: float = player.global_position.x if player else 250.0

	var lead_offset: float = 0.0
	if player:
		lead_offset = player.velocity.y * randf_range(0.12, 0.28)
	var direct_target_y: float = clampf(player_y + lead_offset, 70.0, viewport_size.y - 70.0)
	var direct_target_pos: Vector2 = Vector2(player_x, direct_target_y)
	var base_direction: Vector2 = (direct_target_pos - spawn_pos).normalized()
	var base_angle: float = base_direction.angle()

	match pattern:
		"zone_denial":
			var escape_y: float = _calculate_expected_empty_space_y(player_y, viewport_size.y)
			var zoning_pos: Vector2 = Vector2(player_x, escape_y)
			var zoning_dir: Vector2 = (zoning_pos - spawn_pos).normalized()
			_spawn_single_projectile(spawn_pos, zoning_dir, false, true)

		"pincer_trap":
			var pincer_escape_y: float = _calculate_expected_empty_space_y(player_y, viewport_size.y)
			var pincer_zoning_pos: Vector2 = Vector2(player_x, pincer_escape_y)
			var pincer_zoning_dir: Vector2 = (pincer_zoning_pos - spawn_pos).normalized()

			_spawn_single_projectile(spawn_pos, base_direction, false, false)
			var pincer_spawn_y: float = clampf(spawn_y + (60.0 if pincer_escape_y > player_y else -60.0), 70.0, viewport_size.y - 70.0)
			var pincer_spawn_pos: Vector2 = Vector2(viewport_size.x + 30.0, pincer_spawn_y)
			_spawn_single_projectile(pincer_spawn_pos, pincer_zoning_dir, false, true)

		"twin_spread":
			var spread_deg: float = randf_range(10.0, 14.0)
			_spawn_single_projectile(spawn_pos, Vector2.from_angle(base_angle + deg_to_rad(spread_deg)))
			_spawn_single_projectile(spawn_pos, Vector2.from_angle(base_angle - deg_to_rad(spread_deg)))

		"fan_burst":
			var fan_deg: float = 13.0
			_spawn_single_projectile(spawn_pos, Vector2.from_angle(base_angle - deg_to_rad(fan_deg)))
			_spawn_single_projectile(spawn_pos, base_direction)
			_spawn_single_projectile(spawn_pos, Vector2.from_angle(base_angle + deg_to_rad(fan_deg)))

		"stream":
			_spawn_single_projectile(spawn_pos, base_direction)
			if remaining_quota >= 2 and not game_over:
				var burst_timer: SceneTreeTimer = get_tree().create_timer(0.14)
				burst_timer.timeout.connect(func():
					if not game_over and current_state == GameState.ACTIVE:
						var offset_y: float = clampf(spawn_y + randf_range(-40.0, 40.0), 70.0, viewport_size.y - 70.0)
						var p2_pos: Vector2 = Vector2(viewport_size.x + 30.0, offset_y)
						var p2_dir: Vector2 = (direct_target_pos - p2_pos).normalized()
						_spawn_single_projectile(p2_pos, p2_dir, true)
				)

		_: # "single"
			var max_spread: float = current_wave_config.max_spread_deg
			var angle_offset: float = deg_to_rad(randf_range(-max_spread, max_spread))
			_spawn_single_projectile(spawn_pos, Vector2.from_angle(base_angle + angle_offset))


func _calculate_expected_empty_space_y(current_y: float, screen_height: float) -> float:
	var predicted_y: float = current_y

	if player and absf(player.velocity.y) > 20.0:
		var evasion_distance: float = randf_range(190.0, 260.0)
		predicted_y += signf(player.velocity.y) * evasion_distance
	else:
		if current_y < screen_height * 0.45:
			predicted_y = randf_range(screen_height * 0.55, screen_height * 0.85)
		elif current_y > screen_height * 0.55:
			predicted_y = randf_range(screen_height * 0.15, screen_height * 0.45)
		else:
			predicted_y = screen_height * 0.25 if randf() < 0.5 else screen_height * 0.75

	return clampf(predicted_y, 80.0, screen_height - 80.0)


func _spawn_single_projectile(
	spawn_pos: Vector2,
	dir: Vector2,
	force_fast: bool = false,
	is_zoning: bool = false
) -> void:
	if game_over or not projectile_scene or projectiles_spawned_in_wave >= current_wave_config.total_projectiles:
		return

	var projectile: Area2D = projectile_scene.instantiate() as Area2D
	if not projectile:
		return

	projectile.position = spawn_pos

	var ptype: int = current_wave_config.allowed_types.pick_random()
	if force_fast and current_wave_config.allowed_types.has(3):
		ptype = 3 # FAST_DART

	var base_spd: float = randf_range(current_wave_config.min_speed, current_wave_config.max_speed)
	if ptype == 3:
		base_spd = maxf(base_spd, current_wave_config.max_speed * 0.95)
	elif ptype == 1:
		base_spd = clampf(base_spd * 0.9, 340.0, 520.0)

	var wave_freq: float = randf_range(4.0, 5.2)
	var wave_amp: float = randf_range(35.0, 50.0)

	var amb_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("ambient", current_wave)
	if amb_cfg.get("texture", "") != "":
		if projectile.has_method("apply_config"):
			var cfg_copy: Dictionary = amb_cfg.duplicate()
			cfg_copy["movement_type"] = ptype
			cfg_copy["speed"] = base_spd
			cfg_copy["wave_frequency"] = wave_freq
			cfg_copy["wave_amplitude"] = wave_amp
			cfg_copy["is_zoning_shot"] = is_zoning
			projectile.apply_config(cfg_copy, dir)
		elif projectile.has_method("setup"):
			projectile.setup(ptype, base_spd, dir, 20, wave_freq, wave_amp, is_zoning)
		else:
			projectile.direction = dir
			projectile.speed = base_spd
	elif projectile.has_method("setup"):
		projectile.setup(ptype, base_spd, dir, 20, wave_freq, wave_amp, is_zoning)
	else:
		projectile.direction = dir
		projectile.speed = base_spd

	projectile.evaded.connect(_on_projectile_evaded)
	projectile.destroyed.connect(_on_projectile_resolved)

	projectiles_spawned_in_wave += 1
	active_projectiles_count += 1

	var remaining: int = current_wave_config.total_projectiles - projectiles_spawned_in_wave
	hud.update_wave_progress(remaining, current_wave_config.total_projectiles)

	add_child(projectile)


func _on_projectile_evaded() -> void:
	if game_over:
		return
	score += 10
	hud.update_score(score)


func _on_projectile_resolved() -> void:
	active_projectiles_count = maxi(0, active_projectiles_count - 1)
	_check_wave_completion()


func _get_live_enemy_unit_count() -> int:
	var count: int = 0
	for child in get_children():
		if child is Area2D and child.is_in_group("enemy_units") and not child.is_in_group("boss"):
			if not child.is_queued_for_deletion():
				var hp: int = int(child.get("current_health"))
				if hp > 0:
					count += 1
	return count


func _get_live_projectile_count() -> int:
	var count: int = 0
	for child in get_children():
		if child is Area2D and child.is_in_group("enemy_projectiles"):
			if not child.is_queued_for_deletion() and not bool(child.get("has_hit_target")):
				count += 1
	return count


func _check_wave_completion() -> void:
	if current_state != GameState.ACTIVE or not current_wave_config or current_wave_config.is_boss_wave or game_over:
		return

	# Only check completion once all quota has been launched into the arena
	if not _is_wave_spawning_complete():
		return

	var live_projectiles: int = _get_live_projectile_count()
	var live_enemies: int = _get_live_enemy_unit_count()

	# Wave is finished either due to no more projectile in the screen, enemy killed, or both
	if live_projectiles == 0 and live_enemies == 0:
		_trigger_wave_cleared()


func _trigger_wave_cleared() -> void:
	if current_state != GameState.ACTIVE:
		return

	current_state = GameState.CLEARED
	pause_combat_boundary()
	spawn_timer.stop()

	# Balancing: Upgrade points are strictly one-time per level (cannot earn points on replay)
	var can_claim: bool = SaveManager.can_claim_level_reward(current_wave)
	var pts_reward: int = 0
	if can_claim:
		pts_reward = SaveManager.claim_level_reward(current_wave, 1)
		upgrade_points += pts_reward
	else:
		pts_reward = 0

	var is_first_time: bool = SaveManager.mark_level_completed(current_wave)
	SaveManager.unlock_level(current_wave + 1)
	if player:
		SaveManager.save_player_state(
			upgrade_points,
			player.shield_level,
			player.speed_level,
			player.gun_level,
			player.current_skin
		)

	if player and player.has_method("heal"):
		player.heal(current_wave_config.heal_reward)

	score += current_wave_config.score_reward
	hud.update_score(score)
	hud.update_upgrade_points(upgrade_points)

	var banner_subtitle: String = ""
	if can_claim:
		banner_subtitle = "+1 UPGRADE POINT  |  +HP HEAL  |  +%d PTS" % current_wave_config.score_reward
	else:
		banner_subtitle = "LEVEL RECLEARED  |  +0 UPGRADE PTS (ALREADY CLAIMED)  |  +HP HEAL  |  +%d PTS" % current_wave_config.score_reward

	hud.show_wave_banner(
		"WAVE %d CLEARED!" % current_wave,
		banner_subtitle,
		2.0,
		Color(0.3, 1.0, 0.45)
	)

	_play_sfx(sfx_wave_clear)

	var completion_timer: SceneTreeTimer = get_tree().create_timer(1.8)
	completion_timer.timeout.connect(func():
		if not game_over and current_state == GameState.CLEARED:
			if current_wave >= 20:
				if player:
					player.set_physics_process(false)
					player.visible = false
				if music_manager:
					music_manager.play_menu_music(1.2)
				hud.show_comic("epilogue", "victory")
			else:
				hud.show_level_completed(
					current_wave,
					score,
					pts_reward,
					current_wave < 20,
					can_claim or is_first_time
				)
	)


func _refresh_shop() -> void:
	var shield_cost: int = _get_upgrade_cost("shield")
	var speed_cost: int = _get_upgrade_cost("speed")
	var gun_cost: int = _get_upgrade_cost("gun")

	var sh_lvl: int = player.shield_level if player else 0
	var sp_lvl: int = player.speed_level if player else 0
	var sp_val: float = player.speed if player else 400.0
	var gn_lvl: int = player.gun_level if player else 0

	hud.open_shop(
		upgrade_points,
		sh_lvl,
		shield_cost,
		sp_lvl,
		sp_val,
		speed_cost,
		gn_lvl,
		gun_cost,
		current_shop_context
	)


func _get_upgrade_cost(type: String) -> int:
	match type:
		"shield": # Shield: Absorbs 2 damage per upgrade, up to 6 damage at max level 3 (costs: 1, 2, 3)
			match player.shield_level:
				0: return 1
				1: return 2
				2: return 3
				_: return 999
		"speed": # Speed: 2 pts base, 3 pts upgrade, 4 pts max
			match player.speed_level:
				0: return 2
				1: return 3
				2: return 4
				_: return 999
		"gun": # Gun: Lv 1: 2 pts, Lv 2: 3 pts, Lv 3 (Cannon): 3 pts, Lv 4 (Gatling): 5 pts, Lv 5 (Quasar Laser): 5 pts
			match player.gun_level:
				0: return 2
				1: return 3
				2: return 4
				3: return 5
				4: return 8
				_: return 999
	return 999


func _on_buy_upgrade_requested(upgrade_type: String) -> void:
	if not player or not is_instance_valid(player):
		return

	var cost: int = _get_upgrade_cost(upgrade_type)
	if upgrade_points >= cost and cost < 999:
		upgrade_points -= cost
		player.apply_upgrade(upgrade_type)
		_play_sfx(sfx_purchase)
		SaveManager.save_player_state(
			upgrade_points,
			player.shield_level,
			player.speed_level,
			player.gun_level,
			player.current_skin
		)
		_refresh_shop()
		hud.update_shield(player.current_shields, player.shield_level * 2)
		hud.update_health(player.current_health, player.max_health)
		hud.update_gun_status(player.gun_level, player.has_emergency_gun)
		hud.update_upgrade_points(upgrade_points)


func _on_reset_upgrades_requested() -> void:
	if not player or not is_instance_valid(player):
		return

	var sh_lvl: int = player.shield_level
	var sp_lvl: int = player.speed_level
	var gn_lvl: int = player.gun_level

	var refund: int = hud.calculate_spent_upgrade_points(sh_lvl, sp_lvl, gn_lvl)
	if refund <= 0:
		return

	upgrade_points += refund
	player.reset_all_upgrades()
	_play_sfx(sfx_purchase)

	SaveManager.save_player_state(
		upgrade_points,
		player.shield_level,
		player.speed_level,
		player.gun_level,
		player.current_skin
	)

	_refresh_shop()
	hud.update_shield(player.current_shields, player.shield_level * 2)
	hud.update_health(player.current_health, player.max_health)
	hud.update_gun_status(player.gun_level, player.has_emergency_gun)
	hud.update_upgrade_points(upgrade_points)
	hud.show_shop_status("Refunded %d Upgrade Points!" % refund)


func _on_resume_wave_requested() -> void:
	if game_over or current_state != GameState.CLEARED:
		return

	hud.close_shop()
	current_wave += 1
	hud.set_hud_stats_visible(true)
	_start_wave_intro(current_wave)


func _on_player_health_changed(current: int, max_hp: int) -> void:
	hud.update_health(current, max_hp)


func _on_player_shield_changed(current: int, max_shield: int) -> void:
	hud.update_shield(current, max_shield)


func _on_player_died() -> void:
	game_over = true
	current_state = GameState.GAME_OVER
	pause_combat_boundary()
	spawn_timer.stop()
	_clean_up_all_minions_and_projectiles()
	for b in active_bosses:
		if is_instance_valid(b):
			b.set_physics_process(false)

	var _save_res: Dictionary = SaveManager.record_game_result(score, current_wave)
	hud.show_level_lost(current_wave)


func _init_audio() -> void:
	MusicManager.ensure_audio_buses()

	# Initialize Universal Sound Manager
	sound_manager = SoundManager.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

	wave_audio_player = AudioStreamPlayer.new()
	wave_audio_player.bus = "SFX"
	add_child(wave_audio_player)

	sfx_wave_start = SoundManager.get_sound_stream("wave_start")
	sfx_wave_clear = SoundManager.get_sound_stream("wave_clear")
	sfx_purchase = SoundManager.get_sound_stream("purchase")

	# Initialize Music Manager
	music_manager = MusicManager.new()
	music_manager.name = "MusicManager"
	add_child(music_manager)

	# Apply customized stage track slots from inspector if present
	for key in stage_music_slots.keys():
		var cfg: Dictionary = stage_music_slots[key]
		var path_str: String = str(cfg.get("path", ""))
		var vol_db: float = float(cfg.get("volume_db", -8.0))
		if not path_str.is_empty():
			MusicManager.set_track_path(key, path_str, vol_db)

	# Apply initial saved volume and play Main Menu music
	var initial_vol: float = SaveManager.get_music_volume()
	MusicManager.apply_music_volume(initial_vol)
	var initial_sfx_vol: float = SaveManager.get_sfx_volume()
	SoundManager.apply_sfx_volume(initial_sfx_vol)
	music_manager.play_menu_music(0.3)


func _play_sfx(stream: AudioStreamWAV) -> void:
	if wave_audio_player and stream:
		wave_audio_player.stream = stream
		wave_audio_player.play()


func _generate_tone_stream(frequencies: Array[float], total_duration: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * total_duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	var note_count: int = frequencies.size()

	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var note_idx: int = clampi(int(progress * float(note_count)), 0, note_count - 1)
		var freq: float = frequencies[note_idx]

		phase += freq / 22050.0
		var tone: float = sin(phase * TAU)
		var note_sub_progress: float = fmod(progress * float(note_count), 1.0)
		var env: float = (1.0 - note_sub_progress) * 0.9

		var sample_val: int = clampi(int(128.0 + tone * env * 48.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream


func set_music_track(track_key: String, file_path: String, volume_db: float = 0.0) -> bool:
	var success: bool = MusicManager.set_track_path(track_key, file_path, volume_db)
	music_theme_slots = MusicManager.get_all_tracks()
	return success


func set_music_stream(track_key: String, stream: AudioStream, volume_db: float = 0.0) -> void:
	MusicManager.set_track_stream(track_key, stream, volume_db)
	music_theme_slots = MusicManager.get_all_tracks()


func get_music_track_config(track_key: String) -> Dictionary:
	return MusicManager.get_track_config(track_key)
