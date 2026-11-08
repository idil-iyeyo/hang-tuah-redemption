extends CanvasLayer

const SaveManager = preload("res://scripts/save_manager.gd")
const MusicManager = preload("res://scripts/music_manager.gd")
const SoundManager = preload("res://scripts/sound_manager.gd")
const CombatBoundaryManager = preload("res://scripts/combat_boundary_manager.gd")

# Core Game Signals
signal buy_upgrade_requested(upgrade_type: String)
signal reset_upgrades_requested
signal resume_wave_requested
signal start_game_requested
signal return_to_menu_requested

# Level Select & Progression Signals
signal level_selected(level_num: int)
signal exit_to_level_select_requested
signal open_upgrade_bay_requested(context: String)
signal continue_to_next_level_requested
signal replay_level_requested
signal skin_selected(skin_id: String)
signal comic_finished(comic_id: String)
signal progress_reset_requested
signal sound_volume_changed(volume: float)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

# Configuration Constants (Extensible for future expansions)
const TOTAL_LEVELS: int = 20
const LEVELS_PER_PAGE: int = 10
const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 2
const PAGE_WIDTH: float = 1320.0
const DRAG_THRESHOLD: float = 12.0
const SWIPE_DISTANCE_THRESHOLD: float = 75.0
const CROWN_TEXTURE_PATH: String = "res://assets/textures/crown_icon.svg"

@export var crown_texture_override: Texture2D = null
var crown_icon_texture: Texture2D = null

# Carousel slide & touch drag state
var carousel_tween: Tween = null
var is_touch_down: bool = false
var is_carousel_dragging: bool = false
var was_carousel_dragged: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var base_track_x: float = 0.0

@onready var stats_margin_container: MarginContainer = $MarginContainer
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var shield_label: Label = $MarginContainer/VBoxContainer/HealthContainer/ShieldLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel
@onready var points_label: Label = $MarginContainer/VBoxContainer/PointsLabel
@onready var gun_status_label: Label = $MarginContainer/VBoxContainer/GunStatusLabel

@onready var boss_bar_container: VBoxContainer = $BossBarContainer
@onready var boss_title_label: Label = $BossBarContainer/BossTitleLabel
@onready var boss_progress_bar: ProgressBar = $BossBarContainer/BossProgressBar

@onready var banner_container: VBoxContainer = $BannerContainer
@onready var banner_title: Label = $BannerContainer/BannerTitle
@onready var banner_subtitle: Label = $BannerContainer/BannerSubtitle

@onready var shop_container: PanelContainer = $ShopContainer
@onready var shop_header: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopHeader")
@onready var shop_points: Label = $ShopContainer/Margin/ShopVBox/ShopPoints
@onready var shop_tab_bar: HBoxContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopTabBar")
@onready var shop_upgrades_tab_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopTabBar/ShopUpgradesTabButton")
@onready var shop_skins_tab_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopTabBar/ShopSkinsTabButton")
@onready var items_box: VBoxContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox")
@onready var shield_info: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/ShieldRow/ShieldInfo")
@onready var shield_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/ShieldRow/ShieldButton")
@onready var speed_info: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/SpeedRow/SpeedInfo")
@onready var speed_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/SpeedRow/SpeedButton")
@onready var gun_info: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/GunRow/GunInfo")
@onready var gun_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/GunRow/GunButton")
@onready var shop_separator2: HSeparator = get_node_or_null("ShopContainer/Margin/ShopVBox/HSeparator2")
@onready var reset_upgrades_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/ResetUpgradesButton")
@onready var shop_status_label: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopStatusLabel")
@onready var continue_button: Button = $ShopContainer/Margin/ShopVBox/ContinueButton

@onready var game_over_container: VBoxContainer = $GameOverContainer
@onready var game_over_title: Label = $GameOverContainer/GameOverTitle
@onready var game_over_stats: Label = $GameOverContainer/GameOverStats
@onready var high_score_alert: Label = $GameOverContainer/HighScoreAlert
@onready var game_over_menu_button: Button = $GameOverContainer/GameOverMenuButton

# Welcome Screen Elements
@onready var welcome_container: VBoxContainer = $WelcomeContainer
@onready var game_title_label: Label = $WelcomeContainer/TitleBox/GameTitle
@onready var play_button: Button = $WelcomeContainer/ButtonsVBox/PlayButton
@onready var setting_button: Button = $WelcomeContainer/ButtonsVBox/SettingButton
@onready var credit_button: Button = $WelcomeContainer/ButtonsVBox/CreditButton

# Huawei ID Account Elements (Top-Right on Welcome Screen)
@onready var welcome_account_container: MarginContainer = get_node_or_null("WelcomeAccountContainer")
@onready var huawei_sign_in_button: Button = get_node_or_null("WelcomeAccountContainer/HuaweiSignInButton")
@onready var huawei_profile_container: PanelContainer = get_node_or_null("WelcomeAccountContainer/HuaweiProfileContainer")
@onready var pilot_badge_label: Label = get_node_or_null("WelcomeAccountContainer/HuaweiProfileContainer/ProfileMargin/ProfileHBox/PilotBadgeLabel")
@onready var profile_sign_out_button: Button = get_node_or_null("WelcomeAccountContainer/HuaweiProfileContainer/ProfileMargin/ProfileHBox/ProfileSignOutButton")

# Modals
@onready var credit_modal: PanelContainer = $CreditModal
@onready var credit_back_button: Button = $CreditModal/Margin/VBox/CreditBackButton
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var sound_slider: HSlider = $SettingsModal/Margin/VBox/SoundSection/SoundSlider
@onready var sound_value_label: Label = $SettingsModal/Margin/VBox/SoundSection/SoundHeaderHBox/SoundValueLabel
@onready var music_slider: HSlider = get_node_or_null("SettingsModal/Margin/VBox/MusicSection/MusicSlider")
@onready var music_value_label: Label = get_node_or_null("SettingsModal/Margin/VBox/MusicSection/MusicHeaderHBox/MusicValueLabel")
@onready var sfx_slider: HSlider = get_node_or_null("SettingsModal/Margin/VBox/SfxSection/SfxSlider")
@onready var sfx_value_label: Label = get_node_or_null("SettingsModal/Margin/VBox/SfxSection/SfxHeaderHBox/SfxValueLabel")
@onready var reset_section: VBoxContainer = get_node_or_null("SettingsModal/Margin/VBox/ResetSection")
@onready var reset_separator: HSeparator = get_node_or_null("SettingsModal/Margin/VBox/HSeparator2")
@onready var reset_progress_button: Button = $SettingsModal/Margin/VBox/ResetSection/ResetProgressButton
@onready var reset_status_label: Label = $SettingsModal/Margin/VBox/ResetSection/ResetStatusLabel
@onready var settings_back_button: Button = $SettingsModal/Margin/VBox/SettingsBackButton

# Reset Confirmation Modal
@onready var reset_confirm_modal: PanelContainer = get_node_or_null("ResetConfirmModal")
@onready var reset_cancel_button: Button = get_node_or_null("ResetConfirmModal/Margin/VBox/ButtonsHBox/ResetCancelButton")
@onready var reset_confirm_button: Button = get_node_or_null("ResetConfirmModal/Margin/VBox/ButtonsHBox/ResetConfirmButton")

# Mobile Controls
@onready var mobile_controls: Control = $MobileControls
@onready var virtual_joystick: Control = $MobileControls/VirtualJoystick
@onready var mobile_fire_button: Control = $MobileControls/MobileFireButton

# Select Level Screen Elements
@onready var select_level_container: Control = $SelectLevelContainer
@onready var exit_to_menu_button: Button = $SelectLevelContainer/TopBarMargin/TopBarHBox/ExitToMenuButton
@onready var levels_tab_button: Button = $SelectLevelContainer/TopBarMargin/TopBarHBox/TabBarHBox/LevelsTabButton
@onready var skins_tab_button: Button = $SelectLevelContainer/TopBarMargin/TopBarHBox/TabBarHBox/SkinsTabButton
@onready var select_level_upgrade_button: Button = get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/SelectLevelUpgradeButton")
@onready var select_level_story_button: Button = get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/SelectLevelStoryButton")
@onready var spacer_left_balance: Control = get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/SpacerLeftBalance")
@onready var spacer_right_balance: Control = get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/SpacerRightBalance")
@onready var comic_slides: ComicSlides = get_node_or_null("ComicSlides")
@onready var levels_view: VBoxContainer = $SelectLevelContainer/ContentMargin/LevelsView
@onready var carousel_hbox: HBoxContainer = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox
@onready var left_arrow_button: Button = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LeftArrowButton
@onready var right_arrow_button: Button = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/RightArrowButton
@onready var level_viewport: Control = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LevelViewport
@onready var level_track: Control = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LevelViewport/LevelTrack
@onready var level_grid: GridContainer = $SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LevelViewport/LevelTrack/LevelGrid
@onready var page_indicator_label: Label = $SelectLevelContainer/ContentMargin/LevelsView/PaginationHBox/PageIndicatorLabel
@onready var prev_page_button: Button = left_arrow_button
@onready var next_page_button: Button = right_arrow_button

# Skins Screen Elements (Visual Hangar Cards inside ShopContainer)
@onready var skins_view: VBoxContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView")
@onready var skins_title: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/ShopHeader")
@onready var skins_subtitle: Label = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsSubtitle")
@onready var skin_default_card: PanelContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinDefaultCard")
@onready var skin_crimson_card: PanelContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinCrimsonCard")
@onready var skin_void_card: PanelContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinVoidCard")
@onready var skin_gold_card: PanelContainer = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinGoldCard")
@onready var skin_default_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinDefaultCard/Margin/HBox/VBox/SkinDefaultButton")
@onready var skin_crimson_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinCrimsonCard/Margin/HBox/VBox/SkinCrimsonButton")
@onready var skin_void_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinVoidCard/Margin/HBox/VBox/SkinVoidButton")
@onready var skin_gold_button: Button = get_node_or_null("ShopContainer/Margin/ShopVBox/SkinsView/SkinsCenter/SkinsGrid/SkinGoldCard/Margin/HBox/VBox/SkinGoldButton")

# Level Completed Screen Elements
@onready var level_completed_container: PanelContainer = $LevelCompletedContainer
@onready var completed_title: Label = $LevelCompletedContainer/Margin/VBox/CompletedTitle
@onready var completed_stats: Label = $LevelCompletedContainer/Margin/VBox/CompletedStats
@onready var completed_exit_button: Button = $LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedExitButton
@onready var completed_upgrade_button: Button = $LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedUpgradeButton
@onready var completed_continue_button: Button = $LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedContinueButton

# Level Lost Screen Elements
@onready var level_lost_container: PanelContainer = $LevelLostContainer
@onready var lost_title: Label = $LevelLostContainer/Margin/VBox/LostTitle
@onready var lost_stats: Label = $LevelLostContainer/Margin/VBox/LostStats
@onready var lost_exit_button: Button = $LevelLostContainer/Margin/VBox/ButtonsHBox/LostExitButton
@onready var lost_upgrade_button: Button = $LevelLostContainer/Margin/VBox/ButtonsHBox/LostUpgradeButton
@onready var lost_replay_button: Button = $LevelLostContainer/Margin/VBox/ButtonsHBox/LostReplayButton

# Pause Screen Elements
@onready var pause_button: Button = $PauseButton
@onready var pause_container: PanelContainer = $PauseContainer
@onready var pause_title: Label = $PauseContainer/Margin/VBox/PauseTitle
@onready var pause_stats: Label = $PauseContainer/Margin/VBox/PauseStats
@onready var pause_exit_button: Button = $PauseContainer/Margin/VBox/ButtonsHBox/PauseExitButton
@onready var pause_settings_button: Button = get_node_or_null("PauseContainer/Margin/VBox/ButtonsHBox/PauseSettingsButton")
@onready var pause_replay_button: Button = $PauseContainer/Margin/VBox/ButtonsHBox/PauseReplayButton
@onready var pause_resume_button: Button = $PauseContainer/Margin/VBox/ButtonsHBox/PauseResumeButton

# Screen Transition Overlay
@onready var screen_transition_overlay: ColorRect = $ScreenTransitionOverlay

# Airspace Boundary Warning UI (Red Lore Warning)
var airspace_warning_container: PanelContainer = null
var airspace_warning_title: Label = null
var airspace_warning_lore: Label = null

# State variables
var banner_tween: Tween = null
var is_shop_open: bool = false
var is_welcome_active: bool = true
var is_select_level_active: bool = false
var is_level_completed_active: bool = false
var is_level_lost_active: bool = false
var is_paused: bool = false
var current_wave_num: int = 1
var title_anim_time: float = 0.0

var current_page: int = 1
var max_unlocked_level: int = 1
var cached_upgrade_points: int = 3
var current_skin_id: String = "default"
var shop_opened_from: String = "gameplay" # "gameplay", "select_level", "level_completed"
var settings_opened_from: String = "welcome" # "welcome", "pause"
var current_shop_tab: String = "upgrades" # "upgrades", "skins"
var shop_default_tab: String = "upgrades"

const SHIP_SKIN_TEXTURES: Dictionary = {
	"default": preload("res://assets/textures/ships/HangTuahJet_1.png"),
	"crimson": preload("res://assets/textures/ships/HangJebatJetNoExhaust.png"),
	"void": preload("res://assets/textures/ships/Hang Lekir Jet - Player.png"),
	"gold": preload("res://assets/textures/ships/Hang Kasturi Jet - Player Right.png"),
}

var ui_audio_player: AudioStreamPlayer = null
var sfx_btn_click: AudioStream = null
var sfx_play_start: AudioStream = null
var sfx_modal_chime: AudioStream = null
var sfx_level_complete: AudioStream = null


func _ready() -> void:
	_init_ui_audio()

	# Crown icon loading for completed levels
	if crown_texture_override:
		crown_icon_texture = crown_texture_override
	elif ResourceLoader.exists(CROWN_TEXTURE_PATH):
		crown_icon_texture = load(CROWN_TEXTURE_PATH)

	# Shop Buttons
	if shield_button:
		shield_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			buy_upgrade_requested.emit("shield")
		)
	if speed_button:
		speed_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			buy_upgrade_requested.emit("speed")
		)
	if gun_button:
		gun_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			buy_upgrade_requested.emit("gun")
		)
	if reset_upgrades_button:
		reset_upgrades_button.pressed.connect(_on_reset_upgrades_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_shop_continue_pressed)
	if shop_upgrades_tab_button:
		shop_upgrades_tab_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			_switch_shop_tab("upgrades")
		)
	if shop_skins_tab_button:
		shop_skins_tab_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			_switch_shop_tab("skins")
		)

	# Welcome Screen Buttons
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
	if setting_button:
		setting_button.pressed.connect(_on_setting_button_pressed)
	if credit_button:
		credit_button.pressed.connect(_on_credit_button_pressed)

	# Settings Modal Controls
	if sound_slider:
		var init_vol: float = SaveManager.get_master_volume()
		sound_slider.value = init_vol
		_update_sound_slider_ui(init_vol)
		_apply_sound_volume(init_vol)
		sound_slider.value_changed.connect(_on_sound_slider_value_changed)

	if music_slider:
		var init_music_vol: float = SaveManager.get_music_volume()
		music_slider.value = init_music_vol
		_update_music_slider_ui(init_music_vol)
		_apply_music_volume(init_music_vol)
		music_slider.value_changed.connect(_on_music_slider_value_changed)

	if sfx_slider:
		var init_sfx_vol: float = SaveManager.get_sfx_volume()
		sfx_slider.value = init_sfx_vol
		_update_sfx_slider_ui(init_sfx_vol)
		_apply_sfx_volume(init_sfx_vol)
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

	if reset_progress_button:
		reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	if reset_cancel_button:
		reset_cancel_button.pressed.connect(_on_reset_cancel_pressed)
	if reset_confirm_button:
		reset_confirm_button.pressed.connect(_on_reset_confirm_pressed)

	if settings_back_button:
		settings_back_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_settings_modal()
		)

	# Modal Back Buttons
	if credit_back_button:
		credit_back_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_credit_modal()
		)

	# Game Over Menu Button
	if game_over_menu_button:
		game_over_menu_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			return_to_menu_requested.emit()
		)

	# Select Level Screen Connections
	if exit_to_menu_button:
		exit_to_menu_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_select_level()
			show_welcome_screen()
			return_to_menu_requested.emit()
		)
	if levels_tab_button:
		levels_tab_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			_switch_tab("levels")
		)
	if skins_tab_button:
		skins_tab_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			_switch_tab("skins")
		)
	if select_level_upgrade_button:
		select_level_upgrade_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			open_upgrade_bay_requested.emit("select_level")
		)
	if select_level_story_button:
		select_level_story_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			show_comic("prologue", "review")
		)
	if comic_slides:
		comic_slides.comic_finished.connect(func(cid: String):
			comic_finished.emit(cid)
		)
	if left_arrow_button:
		left_arrow_button.pressed.connect(_on_left_arrow_pressed)
	if right_arrow_button:
		right_arrow_button.pressed.connect(_on_right_arrow_pressed)
	if level_viewport:
		level_viewport.gui_input.connect(_handle_carousel_gui_input)

	# Style Flanking Navigation Arrows
	var arrow_normal: StyleBoxFlat = StyleBoxFlat.new()
	arrow_normal.bg_color = Color(0.04, 0.12, 0.20, 0.85)
	arrow_normal.set_border_width_all(2)
	arrow_normal.border_color = Color(0.25, 0.85, 1.0, 0.7)
	arrow_normal.set_corner_radius_all(10)

	var arrow_hover: StyleBoxFlat = StyleBoxFlat.new()
	arrow_hover.bg_color = Color(0.08, 0.22, 0.35, 0.95)
	arrow_hover.set_border_width_all(2)
	arrow_hover.border_color = Color(0.55, 1.0, 1.0, 1.0)
	arrow_hover.set_corner_radius_all(10)

	var arrow_pressed: StyleBoxFlat = StyleBoxFlat.new()
	arrow_pressed.bg_color = Color(0.12, 0.30, 0.45, 1.0)
	arrow_pressed.set_border_width_all(2)
	arrow_pressed.border_color = Color(0.8, 1.0, 1.0, 1.0)
	arrow_pressed.set_corner_radius_all(10)

	var arrow_disabled: StyleBoxFlat = StyleBoxFlat.new()
	arrow_disabled.bg_color = Color(0.08, 0.10, 0.14, 0.35)
	arrow_disabled.set_border_width_all(1)
	arrow_disabled.border_color = Color(0.25, 0.3, 0.35, 0.35)
	arrow_disabled.set_corner_radius_all(10)

	for arrow_btn in [left_arrow_button, right_arrow_button]:
		if arrow_btn:
			arrow_btn.add_theme_stylebox_override("normal", arrow_normal)
			arrow_btn.add_theme_stylebox_override("hover", arrow_hover)
			arrow_btn.add_theme_stylebox_override("pressed", arrow_pressed)
			arrow_btn.add_theme_stylebox_override("disabled", arrow_disabled)
			arrow_btn.set("theme_override_colors/font_color", Color(0.3, 0.9, 1.0))
			arrow_btn.set("theme_override_colors/font_hover_color", Color(0.7, 1.0, 1.0))
			arrow_btn.set("theme_override_colors/font_disabled_color", Color(0.35, 0.4, 0.45))

	# Skins Buttons Connections
	if skin_default_button:
		skin_default_button.pressed.connect(func(): _select_skin("default"))
	if skin_crimson_button:
		skin_crimson_button.pressed.connect(func(): _select_skin("crimson"))
	if skin_void_button:
		skin_void_button.pressed.connect(func(): _select_skin("void"))
	if skin_gold_button:
		skin_gold_button.pressed.connect(func(): _select_skin("gold"))

	for card_data in [
		[skin_default_card, "default"],
		[skin_crimson_card, "crimson"],
		[skin_void_card, "void"],
		[skin_gold_card, "gold"]
	]:
		var scard: PanelContainer = card_data[0]
		var skid: String = card_data[1]
		if scard:
			scard.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_select_skin(skid)
			)

	# Dialog Panels Styling (Solid backgrounds to prevent any transparency bleed-through)
	if level_completed_container:
		var comp_panel: StyleBoxFlat = StyleBoxFlat.new()
		comp_panel.bg_color = Color(0.06, 0.08, 0.14, 0.98)
		comp_panel.set_border_width_all(2)
		comp_panel.border_color = Color(0.3, 0.95, 0.65, 1.0)
		comp_panel.set_corner_radius_all(14)
		comp_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		comp_panel.shadow_size = 12
		level_completed_container.add_theme_stylebox_override("panel", comp_panel)

	if level_lost_container:
		var lost_panel: StyleBoxFlat = StyleBoxFlat.new()
		lost_panel.bg_color = Color(0.08, 0.04, 0.06, 0.98)
		lost_panel.set_border_width_all(2)
		lost_panel.border_color = Color(1.0, 0.35, 0.35, 1.0)
		lost_panel.set_corner_radius_all(14)
		lost_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		lost_panel.shadow_size = 12
		level_lost_container.add_theme_stylebox_override("panel", lost_panel)

	if shop_container:
		var shop_panel: StyleBoxFlat = StyleBoxFlat.new()
		shop_panel.bg_color = Color(0.06, 0.08, 0.14, 0.98)
		shop_panel.set_border_width_all(2)
		shop_panel.border_color = Color(1.0, 0.85, 0.25, 1.0)
		shop_panel.set_corner_radius_all(14)
		shop_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		shop_panel.shadow_size = 12
		shop_container.add_theme_stylebox_override("panel", shop_panel)

	if pause_container:
		var pause_panel: StyleBoxFlat = StyleBoxFlat.new()
		pause_panel.bg_color = Color(0.06, 0.08, 0.14, 0.98)
		pause_panel.set_border_width_all(2)
		pause_panel.border_color = Color(0.3, 0.9, 1.0, 1.0)
		pause_panel.set_corner_radius_all(14)
		pause_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		pause_panel.shadow_size = 12
		pause_container.add_theme_stylebox_override("panel", pause_panel)

	if settings_modal:
		var settings_panel: StyleBoxFlat = StyleBoxFlat.new()
		settings_panel.bg_color = Color(0.03, 0.04, 0.08, 1.0)
		settings_panel.set_border_width_all(2)
		settings_panel.border_color = Color(0.25, 0.85, 1.0, 1.0)
		settings_panel.set_corner_radius_all(14)
		settings_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
		settings_panel.shadow_size = 24
		settings_modal.add_theme_stylebox_override("panel", settings_panel)

	if credit_modal:
		var credit_panel: StyleBoxFlat = StyleBoxFlat.new()
		credit_panel.bg_color = Color(0.03, 0.04, 0.08, 1.0)
		credit_panel.set_border_width_all(2)
		credit_panel.border_color = Color(0.3, 0.9, 1.0, 1.0)
		credit_panel.set_corner_radius_all(14)
		credit_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
		credit_panel.shadow_size = 24
		credit_modal.add_theme_stylebox_override("panel", credit_panel)

	if reset_confirm_modal:
		var confirm_panel: StyleBoxFlat = StyleBoxFlat.new()
		confirm_panel.bg_color = Color(0.03, 0.04, 0.08, 1.0)
		confirm_panel.set_border_width_all(2)
		confirm_panel.border_color = Color(1.0, 0.35, 0.35, 1.0)
		confirm_panel.set_corner_radius_all(14)
		confirm_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.9)
		confirm_panel.shadow_size = 28
		reset_confirm_modal.add_theme_stylebox_override("panel", confirm_panel)

	if reset_cancel_button:
		var c_norm: StyleBoxFlat = StyleBoxFlat.new()
		c_norm.bg_color = Color(0.08, 0.12, 0.18, 0.95)
		c_norm.set_border_width_all(2)
		c_norm.border_color = Color(0.3, 0.85, 1.0, 0.9)
		c_norm.set_corner_radius_all(8)
		reset_cancel_button.add_theme_stylebox_override("normal", c_norm)
		var c_hov: StyleBoxFlat = c_norm.duplicate()
		c_hov.bg_color = Color(0.12, 0.18, 0.28, 1.0)
		c_hov.border_color = Color(0.5, 0.95, 1.0, 1.0)
		reset_cancel_button.add_theme_stylebox_override("hover", c_hov)

	if reset_confirm_button:
		var r_norm: StyleBoxFlat = StyleBoxFlat.new()
		r_norm.bg_color = Color(0.25, 0.05, 0.05, 0.95)
		r_norm.set_border_width_all(2)
		r_norm.border_color = Color(1.0, 0.35, 0.35, 0.95)
		r_norm.set_corner_radius_all(8)
		reset_confirm_button.add_theme_stylebox_override("normal", r_norm)
		var r_hov: StyleBoxFlat = r_norm.duplicate()
		r_hov.bg_color = Color(0.4, 0.08, 0.08, 1.0)
		r_hov.border_color = Color(1.0, 0.6, 0.6, 1.0)
		reset_confirm_button.add_theme_stylebox_override("hover", r_hov)

	if reset_upgrades_button:
		var u_norm: StyleBoxFlat = StyleBoxFlat.new()
		u_norm.bg_color = Color(0.2, 0.06, 0.06, 0.95)
		u_norm.set_border_width_all(2)
		u_norm.border_color = Color(0.9, 0.35, 0.35, 0.9)
		u_norm.set_corner_radius_all(8)
		reset_upgrades_button.add_theme_stylebox_override("normal", u_norm)

		var u_hov: StyleBoxFlat = u_norm.duplicate()
		u_hov.bg_color = Color(0.32, 0.1, 0.1, 1.0)
		u_hov.border_color = Color(1.0, 0.55, 0.55, 1.0)
		reset_upgrades_button.add_theme_stylebox_override("hover", u_hov)

		var u_dis: StyleBoxFlat = StyleBoxFlat.new()
		u_dis.bg_color = Color(0.08, 0.08, 0.1, 0.5)
		u_dis.set_border_width_all(1)
		u_dis.border_color = Color(0.25, 0.25, 0.3, 0.4)
		u_dis.set_corner_radius_all(8)
		reset_upgrades_button.add_theme_stylebox_override("disabled", u_dis)

	if pause_button:
		var p_btn_norm: StyleBoxFlat = StyleBoxFlat.new()
		p_btn_norm.bg_color = Color(0.06, 0.12, 0.18, 0.88)
		p_btn_norm.set_border_width_all(2)
		p_btn_norm.border_color = Color(0.3, 0.85, 1.0, 0.9)
		p_btn_norm.set_corner_radius_all(8)
		pause_button.add_theme_stylebox_override("normal", p_btn_norm)

		var p_btn_hov: StyleBoxFlat = StyleBoxFlat.new()
		p_btn_hov.bg_color = Color(0.12, 0.22, 0.32, 0.95)
		p_btn_hov.set_border_width_all(2)
		p_btn_hov.border_color = Color(0.6, 1.0, 1.0, 1.0)
		p_btn_hov.set_corner_radius_all(8)
		pause_button.add_theme_stylebox_override("hover", p_btn_hov)
		pause_button.add_theme_stylebox_override("pressed", p_btn_hov)
		pause_button.pressed.connect(_on_pause_button_pressed)

	# Huawei ID Account Styling
	if huawei_sign_in_button:
		var sign_in_box: StyleBoxFlat = StyleBoxFlat.new()
		sign_in_box.bg_color = Color(0.78, 0.0, 0.05, 0.95)
		sign_in_box.set_corner_radius_all(10)
		sign_in_box.set_border_width_all(2)
		sign_in_box.border_color = Color(1.0, 0.25, 0.25, 1.0)
		sign_in_box.content_margin_left = 16
		sign_in_box.content_margin_right = 16
		sign_in_box.content_margin_top = 8
		sign_in_box.content_margin_bottom = 8
		huawei_sign_in_button.add_theme_stylebox_override("normal", sign_in_box)

		var sign_in_hov: StyleBoxFlat = sign_in_box.duplicate()
		sign_in_hov.bg_color = Color(0.92, 0.05, 0.1, 1.0)
		sign_in_hov.border_color = Color(1.0, 0.5, 0.5, 1.0)
		huawei_sign_in_button.add_theme_stylebox_override("hover", sign_in_hov)
		huawei_sign_in_button.add_theme_stylebox_override("pressed", sign_in_hov)

	if huawei_profile_container:
		var profile_panel: StyleBoxFlat = StyleBoxFlat.new()
		profile_panel.bg_color = Color(0.04, 0.08, 0.16, 0.95)
		profile_panel.set_corner_radius_all(10)
		profile_panel.set_border_width_all(2)
		profile_panel.border_color = Color(0.2, 0.75, 1.0, 0.8)
		huawei_profile_container.add_theme_stylebox_override("panel", profile_panel)

	if profile_sign_out_button:
		var so_norm: StyleBoxFlat = StyleBoxFlat.new()
		so_norm.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		so_norm.set_corner_radius_all(6)
		so_norm.set_border_width_all(1)
		so_norm.border_color = Color(0.4, 0.5, 0.65, 0.8)
		profile_sign_out_button.add_theme_stylebox_override("normal", so_norm)
		var so_hov: StyleBoxFlat = so_norm.duplicate()
		so_hov.bg_color = Color(0.25, 0.08, 0.08, 1.0)
		so_hov.border_color = Color(1.0, 0.4, 0.4, 1.0)
		profile_sign_out_button.add_theme_stylebox_override("hover", so_hov)

	_init_huawei_account_ui()

	if pause_resume_button:
		pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	if pause_settings_button:
		pause_settings_button.pressed.connect(_on_pause_settings_pressed)
	if pause_replay_button:
		pause_replay_button.pressed.connect(_on_pause_replay_pressed)
	if pause_exit_button:
		pause_exit_button.pressed.connect(_on_pause_exit_pressed)

	# Explicit Z-Index hierarchy to guarantee modals layer cleanly above game containers
	if mobile_controls:
		mobile_controls.z_index = 5
	if pause_container:
		pause_container.z_index = 10
	if settings_modal:
		settings_modal.z_index = 25
	if credit_modal:
		credit_modal.z_index = 25
	if screen_transition_overlay:
		screen_transition_overlay.z_index = 50

	# Level Completed Buttons Connections
	if completed_exit_button:
		completed_exit_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_level_completed()
			exit_to_level_select_requested.emit()
		)
	if completed_upgrade_button:
		completed_upgrade_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_level_completed()
			shop_default_tab = "upgrades"
			open_upgrade_bay_requested.emit("level_completed")
		)
	if completed_continue_button:
		completed_continue_button.pressed.connect(func():
			_play_ui_sfx(sfx_play_start)
			hide_level_completed()
			continue_to_next_level_requested.emit()
		)

	# Level Lost Buttons Connections
	if lost_exit_button:
		lost_exit_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_level_lost()
			exit_to_level_select_requested.emit()
		)
	if lost_upgrade_button:
		lost_upgrade_button.pressed.connect(func():
			_play_ui_sfx(sfx_btn_click)
			hide_level_lost()
			shop_default_tab = "upgrades"
			open_upgrade_bay_requested.emit("level_lost")
		)
	if lost_replay_button:
		lost_replay_button.pressed.connect(func():
			_play_ui_sfx(sfx_play_start)
			hide_level_lost()
			replay_level_requested.emit()
		)

	_init_airspace_warning()


func _init_airspace_warning() -> void:
	if airspace_warning_container != null:
		return

	airspace_warning_container = PanelContainer.new()
	airspace_warning_container.name = "AirspaceWarningContainer"
	airspace_warning_container.visible = false
	airspace_warning_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	airspace_warning_container.custom_minimum_size = Vector2(760.0, 74.0)

	# Anchored Top-Center (below top HUD score/health bars, above action space)
	airspace_warning_container.anchor_left = 0.5
	airspace_warning_container.anchor_right = 0.5
	airspace_warning_container.anchor_top = 0.11
	airspace_warning_container.anchor_bottom = 0.11
	airspace_warning_container.offset_left = -380.0
	airspace_warning_container.offset_right = 380.0
	airspace_warning_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	airspace_warning_container.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.02, 0.02, 0.92)
	style.border_color = Color(1.0, 0.15, 0.15, 0.98)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(1.0, 0.0, 0.0, 0.35)
	style.shadow_size = 14
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	airspace_warning_container.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	airspace_warning_container.add_child(vbox)

	airspace_warning_title = Label.new()
	airspace_warning_title.name = "WarningTitle"
	airspace_warning_title.text = "⚠️ WARNING!"
	airspace_warning_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	airspace_warning_title.set("theme_override_colors/font_color", Color(1.0, 0.22, 0.22, 1.0))
	airspace_warning_title.set("theme_override_font_sizes/font_size", 24)
	vbox.add_child(airspace_warning_title)

	airspace_warning_lore = Label.new()
	airspace_warning_lore.name = "WarningLore"
	airspace_warning_lore.text = "KOTA A FAMOSA DEFENSE PERIMETER BREACHED // SOLARIAR VOID DISRUPTION: 10 DMG/SEC // RETREAT TO MALAY REALM AIRSPACE!"
	airspace_warning_lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	airspace_warning_lore.set("theme_override_colors/font_color", Color(1.0, 0.88, 0.88, 0.95))
	airspace_warning_lore.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(airspace_warning_lore)

	add_child(airspace_warning_container)


func set_airspace_warning_visible(is_active: bool, custom_lore_text: String = "") -> void:
	if airspace_warning_container == null:
		_init_airspace_warning()

	if not is_active:
		if airspace_warning_container and airspace_warning_container.visible:
			airspace_warning_container.visible = false
		return

	if custom_lore_text.is_empty() and CombatBoundaryManager:
		custom_lore_text = CombatBoundaryManager.get_lore_text()

	if not custom_lore_text.is_empty() and airspace_warning_lore:
		airspace_warning_lore.text = custom_lore_text

	if airspace_warning_title and CombatBoundaryManager:
		airspace_warning_title.text = CombatBoundaryManager.get_lore_title()

	if airspace_warning_container:
		airspace_warning_container.visible = true


func _process(delta: float) -> void:
	if airspace_warning_container and airspace_warning_container.visible:
		var pulse_warn: float = 0.82 + 0.18 * sin(Time.get_ticks_msec() * 0.009)
		airspace_warning_container.modulate = Color(1.0, 1.0, 1.0, pulse_warn)
	if is_welcome_active and welcome_container and welcome_container.visible and game_title_label:
		title_anim_time += delta
		var pulse: float = 1.0 + 0.04 * sin(title_anim_time * 2.8)
		game_title_label.scale = Vector2(pulse, pulse)
		game_title_label.pivot_offset = game_title_label.size * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if is_touch_down:
		if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_touch_down = false
			_finish_carousel_drag(event.global_position)
		elif event is InputEventScreenTouch and not event.pressed:
			is_touch_down = false
			_finish_carousel_drag(event.position)

	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return

	# Welcome screen shortcuts
	if is_welcome_active and welcome_container and welcome_container.visible:
		if credit_modal and credit_modal.visible:
			if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
				hide_credit_modal()
				return
		else:
			if event.physical_keycode in [KEY_SPACE, KEY_ENTER]:
				_on_play_button_pressed()
				return

	# Select Level screen shortcuts
	if is_select_level_active and select_level_container and select_level_container.visible:
		if is_shop_open:
			# Shop shortcuts take priority when opened from select level
			_handle_shop_input(event)
			return
		match event.physical_keycode:
			KEY_ESCAPE, KEY_M:
				exit_to_menu_button.emit_signal("pressed")
				return
			KEY_U:
				open_upgrade_bay_requested.emit("select_level")
				return
			KEY_LEFT, KEY_A:
				_on_prev_page_pressed()
				return
			KEY_RIGHT, KEY_D:
				_on_next_page_pressed()
				return
			KEY_TAB:
				if levels_view and levels_view.visible:
					_switch_tab("skins")
				else:
					_switch_tab("levels")
				return

	# Modal shortcuts (ESC closes confirm/settings/credits cleanly without triggering pause resume or exit)
	if reset_confirm_modal and reset_confirm_modal.visible:
		if event.physical_keycode == KEY_ESCAPE:
			_play_ui_sfx(sfx_btn_click)
			hide_reset_confirm_modal()
			return

	if settings_modal and settings_modal.visible:
		if event.physical_keycode == KEY_ESCAPE:
			_play_ui_sfx(sfx_btn_click)
			hide_settings_modal()
			return

	if credit_modal and credit_modal.visible:
		if event.physical_keycode == KEY_ESCAPE:
			_play_ui_sfx(sfx_btn_click)
			hide_credit_modal()
			return

	# Pause screen shortcuts
	if is_paused and pause_container and pause_container.visible:
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P, KEY_SPACE, KEY_ENTER, KEY_C:
				_on_pause_resume_pressed()
				return
			KEY_R:
				_on_pause_replay_pressed()
				return
			KEY_E, KEY_M:
				_on_pause_exit_pressed()
				return

	# Level Completed screen shortcuts
	if is_level_completed_active and level_completed_container and level_completed_container.visible:
		if is_shop_open:
			_handle_shop_input(event)
			return
		match event.physical_keycode:
			KEY_ESCAPE, KEY_E, KEY_M:
				completed_exit_button.emit_signal("pressed")
				return
			KEY_U:
				completed_upgrade_button.emit_signal("pressed")
				return
			KEY_SPACE, KEY_ENTER, KEY_C:
				completed_continue_button.emit_signal("pressed")
				return

	# Level Lost screen shortcuts
	if is_level_lost_active and level_lost_container and level_lost_container.visible:
		if is_shop_open:
			_handle_shop_input(event)
			return
		match event.physical_keycode:
			KEY_ESCAPE, KEY_E, KEY_M:
				lost_exit_button.emit_signal("pressed")
				return
			KEY_U:
				lost_upgrade_button.emit_signal("pressed")
				return
			KEY_SPACE, KEY_ENTER, KEY_R:
				lost_replay_button.emit_signal("pressed")
				return

	# Shop shortcuts
	if is_shop_open:
		_handle_shop_input(event)
		return

	# Game over shortcuts
	if game_over_container and game_over_container.visible:
		if event.physical_keycode == KEY_M:
			return_to_menu_requested.emit()

	# Active Gameplay shortcuts (Pause trigger)
	if stats_margin_container and stats_margin_container.visible and not is_paused and not is_welcome_active and not is_select_level_active and not is_level_completed_active and not is_level_lost_active and not is_shop_open:
		if event.physical_keycode in [KEY_ESCAPE, KEY_P]:
			_on_pause_button_pressed()
			return


func _handle_shop_input(event: InputEvent) -> void:
	match event.physical_keycode:
		KEY_TAB:
			_play_ui_sfx(sfx_btn_click)
			if current_shop_tab == "upgrades":
				_switch_shop_tab("skins")
			else:
				_switch_shop_tab("upgrades")
			return
		KEY_SPACE, KEY_ENTER, KEY_ESCAPE:
			_on_shop_continue_pressed()
			return

	if current_shop_tab == "upgrades":
		match event.physical_keycode:
			KEY_1:
				buy_upgrade_requested.emit("shield")
			KEY_2:
				buy_upgrade_requested.emit("speed")
			KEY_3:
				buy_upgrade_requested.emit("gun")
	elif current_shop_tab == "skins":
		match event.physical_keycode:
			KEY_1:
				_select_skin("default")
			KEY_2:
				_select_skin("crimson")
			KEY_3:
				_select_skin("void")
			KEY_4:
				_select_skin("gold")


func _on_play_button_pressed() -> void:
	_play_ui_sfx(sfx_play_start)
	hide_welcome_screen()
	var data: Dictionary = SaveManager.load_save_data()
	show_select_level(int(data.get("unlocked_level", 1)), int(data.get("upgrade_points", 3)))
	start_game_requested.emit()


func _on_setting_button_pressed() -> void:
	_play_ui_sfx(sfx_modal_chime)
	settings_opened_from = "welcome"
	show_settings_modal()


func _on_pause_settings_pressed() -> void:
	_play_ui_sfx(sfx_modal_chime)
	settings_opened_from = "pause"
	show_settings_modal()


func _on_credit_button_pressed() -> void:
	_play_ui_sfx(sfx_modal_chime)
	show_credit_modal()


func show_welcome_screen() -> void:
	is_welcome_active = true
	is_select_level_active = false
	is_level_completed_active = false
	is_level_lost_active = false
	is_paused = false
	get_tree().paused = false
	set_hud_stats_visible(false)
	set_mobile_controls_visible(false)
	if pause_button:
		pause_button.visible = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if banner_container:
		banner_container.visible = false
	if shop_container:
		shop_container.visible = false
	if game_over_container:
		game_over_container.visible = false
	if credit_modal:
		credit_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	if select_level_container:
		select_level_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false

	if welcome_container:
		welcome_container.visible = true
		welcome_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(welcome_container, "modulate:a", 1.0, 0.35)

	if welcome_account_container:
		welcome_account_container.visible = true
		welcome_account_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween_acc: Tween = create_tween()
		tween_acc.tween_property(welcome_account_container, "modulate:a", 1.0, 0.35)


func hide_welcome_screen() -> void:
	is_welcome_active = false
	if welcome_container:
		welcome_container.visible = false
	if welcome_account_container:
		welcome_account_container.visible = false
	if credit_modal:
		credit_modal.visible = false
	if settings_modal:
		settings_modal.visible = false


# -----------------------------------------------------------------------------
# SELECT LEVEL SCREEN IMPLEMENTATION
# -----------------------------------------------------------------------------

func show_select_level(unlocked_level: int = 1, points: int = 0) -> void:
	is_select_level_active = true
	is_welcome_active = false
	is_level_completed_active = false
	is_level_lost_active = false
	is_paused = false
	get_tree().paused = false

	max_unlocked_level = maxi(1, unlocked_level)
	cached_upgrade_points = points

	set_hud_stats_visible(false)
	set_mobile_controls_visible(false)
	if pause_button:
		pause_button.visible = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false

	if banner_container:
		banner_container.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if game_over_container:
		game_over_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false
	if welcome_container:
		welcome_container.visible = false
	if welcome_account_container:
		welcome_account_container.visible = false

	# Ensure correct page fits unlocked level
	var page_for_level: int = ceili(float(max_unlocked_level) / float(LEVELS_PER_PAGE))
	current_page = clampi(page_for_level, 1, _get_total_pages())

	_update_select_level_upgrade_button()
	_switch_tab("levels")
	_refresh_level_page()
	slide_to_page(current_page, false)

	var data: Dictionary = SaveManager.load_save_data()
	current_skin_id = str(data.get("selected_skin", "default"))
	_refresh_skins_view()

	if select_level_container:
		select_level_container.visible = true
		select_level_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(select_level_container, "modulate:a", 1.0, 0.25)


func hide_select_level() -> void:
	is_select_level_active = false
	if select_level_container:
		select_level_container.visible = false


func update_select_level_stats(unlocked_level: int, points: int) -> void:
	max_unlocked_level = maxi(max_unlocked_level, unlocked_level)
	cached_upgrade_points = points
	_update_select_level_upgrade_button()
	if is_select_level_active and levels_view and levels_view.visible:
		_refresh_level_page()
		slide_to_page(current_page, false)


func _update_select_level_upgrade_button() -> void:
	if skins_tab_button:
		skins_tab_button.text = "🚀 HANGAR & UPGRADES (%d PTS)" % cached_upgrade_points
	if select_level_upgrade_button:
		select_level_upgrade_button.text = "💎 UPGRADE BAY (%d PTS)" % cached_upgrade_points
	_update_top_bar_centering()


func _update_top_bar_centering() -> void:
	if not exit_to_menu_button:
		return
	var left_w: float = exit_to_menu_button.size.x
	var right_w: float = 0.0
	if select_level_story_button and select_level_story_button.visible:
		right_w += select_level_story_button.size.x
	if select_level_upgrade_button and select_level_upgrade_button.visible:
		right_w += select_level_upgrade_button.size.x + 12.0
	if spacer_left_balance:
		spacer_left_balance.custom_minimum_size.x = maxf(0.0, right_w - left_w)
	if spacer_right_balance:
		spacer_right_balance.custom_minimum_size.x = maxf(0.0, left_w - right_w)


func _get_total_pages() -> int:
	return maxi(1, ceili(float(TOTAL_LEVELS) / float(LEVELS_PER_PAGE)))


func slide_to_page(target_page: int, animated: bool = true) -> void:
	var total_p: int = _get_total_pages()
	current_page = clampi(target_page, 1, total_p)
	var target_x: float = -(current_page - 1) * PAGE_WIDTH

	if page_indicator_label:
		page_indicator_label.text = "PAGE %d / %d" % [current_page, total_p]
	_update_arrow_buttons()

	if carousel_tween and carousel_tween.is_valid():
		carousel_tween.kill()

	if animated and level_track and is_inside_tree():
		carousel_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		carousel_tween.tween_property(level_track, "position:x", target_x, 0.32)
	elif level_track:
		level_track.position.x = target_x


func _update_arrow_buttons() -> void:
	var total_p: int = _get_total_pages()
	if left_arrow_button:
		left_arrow_button.disabled = (current_page <= 1)
		left_arrow_button.modulate.a = 0.35 if (current_page <= 1) else 1.0
	if right_arrow_button:
		right_arrow_button.disabled = (current_page >= total_p)
		right_arrow_button.modulate.a = 0.35 if (current_page >= total_p) else 1.0


func _on_left_arrow_pressed() -> void:
	if current_page > 1:
		_play_ui_sfx(sfx_btn_click)
		slide_to_page(current_page - 1, true)


func _on_right_arrow_pressed() -> void:
	if current_page < _get_total_pages():
		_play_ui_sfx(sfx_btn_click)
		slide_to_page(current_page + 1, true)


func _on_prev_page_pressed() -> void:
	_on_left_arrow_pressed()


func _on_next_page_pressed() -> void:
	_on_right_arrow_pressed()


func _handle_carousel_gui_input(event: InputEvent) -> void:
	if not is_select_level_active or not levels_view or not levels_view.visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_touch_down = true
				drag_start_pos = event.global_position
				base_track_x = level_track.position.x if level_track else 0.0
				is_carousel_dragging = false
				was_carousel_dragged = false
				if carousel_tween and carousel_tween.is_valid():
					carousel_tween.kill()
			else:
				if is_touch_down:
					is_touch_down = false
					_finish_carousel_drag(event.global_position)

	elif event is InputEventMouseMotion:
		if is_touch_down:
			var mouse_delta_x: float = event.global_position.x - drag_start_pos.x
			if not is_carousel_dragging and absf(mouse_delta_x) >= DRAG_THRESHOLD:
				is_carousel_dragging = true
				was_carousel_dragged = true
			if is_carousel_dragging and level_track:
				var mouse_pages: int = _get_total_pages()
				if current_page <= 1 and mouse_delta_x > 0.0:
					mouse_delta_x *= 0.25
				elif current_page >= mouse_pages and mouse_delta_x < 0.0:
					mouse_delta_x *= 0.25
				level_track.position.x = base_track_x + mouse_delta_x

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_touch_down = true
			drag_start_pos = event.position
			base_track_x = level_track.position.x if level_track else 0.0
			is_carousel_dragging = false
			was_carousel_dragged = false
			if carousel_tween and carousel_tween.is_valid():
				carousel_tween.kill()
		else:
			if is_touch_down:
				is_touch_down = false
				_finish_carousel_drag(event.position)

	elif event is InputEventScreenDrag:
		if is_touch_down:
			var drag_delta_x: float = event.position.x - drag_start_pos.x
			if not is_carousel_dragging and absf(drag_delta_x) >= DRAG_THRESHOLD:
				is_carousel_dragging = true
				was_carousel_dragged = true
			if is_carousel_dragging and level_track:
				var drag_pages: int = _get_total_pages()
				if current_page <= 1 and drag_delta_x > 0.0:
					drag_delta_x *= 0.25
				elif current_page >= drag_pages and drag_delta_x < 0.0:
					drag_delta_x *= 0.25
				level_track.position.x = base_track_x + drag_delta_x


func _finish_carousel_drag(release_pos: Vector2) -> void:
	if not is_carousel_dragging:
		return
	is_carousel_dragging = false
	var total_delta_x: float = release_pos.x - drag_start_pos.x
	var total_p: int = _get_total_pages()

	if total_delta_x < -SWIPE_DISTANCE_THRESHOLD and current_page < total_p:
		_play_ui_sfx(sfx_btn_click)
		slide_to_page(current_page + 1, true)
	elif total_delta_x > SWIPE_DISTANCE_THRESHOLD and current_page > 1:
		_play_ui_sfx(sfx_btn_click)
		slide_to_page(current_page - 1, true)
	else:
		slide_to_page(current_page, true)

	var snap_timer: SceneTreeTimer = get_tree().create_timer(0.08)
	snap_timer.timeout.connect(func(): was_carousel_dragged = false)


func _refresh_level_page() -> void:
	if not level_track or not page_indicator_label:
		return

	var total_p: int = _get_total_pages()
	current_page = clampi(current_page, 1, total_p)

	page_indicator_label.text = "PAGE %d / %d" % [current_page, total_p]
	_update_arrow_buttons()

	# Reusable Cyan Style for Unlocked Levels
	var cyan_normal: StyleBoxFlat = StyleBoxFlat.new()
	cyan_normal.bg_color = Color(0.04, 0.14, 0.22, 0.95)
	cyan_normal.set_border_width_all(2)
	cyan_normal.border_color = Color(0.25, 0.90, 1.0, 1.0) # Bright Cyan
	cyan_normal.set_corner_radius_all(10)

	var cyan_hover: StyleBoxFlat = StyleBoxFlat.new()
	cyan_hover.bg_color = Color(0.08, 0.24, 0.36, 0.98)
	cyan_hover.set_border_width_all(3)
	cyan_hover.border_color = Color(0.55, 1.0, 1.0, 1.0)
	cyan_hover.set_corner_radius_all(10)

	# Boss Unlocked Style
	var boss_normal: StyleBoxFlat = StyleBoxFlat.new()
	boss_normal.bg_color = Color(0.18, 0.06, 0.10, 0.95)
	boss_normal.set_border_width_all(2)
	boss_normal.border_color = Color(1.0, 0.35, 0.35, 1.0)
	boss_normal.set_corner_radius_all(10)

	var boss_hover: StyleBoxFlat = StyleBoxFlat.new()
	boss_hover.bg_color = Color(0.28, 0.09, 0.14, 0.98)
	boss_hover.set_border_width_all(3)
	boss_hover.border_color = Color(1.0, 0.6, 0.6, 1.0)
	boss_hover.set_corner_radius_all(10)

	# Greyed-out Style for Locked Levels
	var grey_style: StyleBoxFlat = StyleBoxFlat.new()
	grey_style.bg_color = Color(0.14, 0.15, 0.18, 0.92) # Visible solid slate grey
	grey_style.set_border_width_all(2)
	grey_style.border_color = Color(0.35, 0.38, 0.44, 1.0) # Distinct grey border
	grey_style.set_corner_radius_all(10)

	# Populate all pages in level_track
	# Page 1 uses level_grid; Page 2+ uses dynamically created GridContainers
	for p in range(1, total_p + 1):
		var page_grid: GridContainer = null
		if p == 1:
			page_grid = level_grid
		else:
			var node_name: String = "LevelGridPage%d" % p
			page_grid = level_track.get_node_or_null(node_name) as GridContainer
			if not page_grid:
				page_grid = GridContainer.new()
				page_grid.name = node_name
				page_grid.columns = GRID_COLUMNS
				page_grid.add_theme_constant_override("h_separation", 24)
				page_grid.add_theme_constant_override("v_separation", 24)
				page_grid.mouse_filter = Control.MOUSE_FILTER_PASS
				level_track.add_child(page_grid)

		if not page_grid:
			continue

		page_grid.position = Vector2((p - 1) * PAGE_WIDTH + 12.0, 16.0)
		page_grid.size = Vector2(1296.0, 284.0)

		# Clean existing buttons in this page_grid immediately
		for child in page_grid.get_children():
			page_grid.remove_child(child)
			child.queue_free()

		var start_idx: int = (p - 1) * LEVELS_PER_PAGE
		for i in range(LEVELS_PER_PAGE):
			var lvl: int = start_idx + i + 1
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(240, 130)
			btn.set("theme_override_font_sizes/font_size", 22)
			btn.gui_input.connect(_handle_carousel_gui_input)

			if lvl <= TOTAL_LEVELS:
				var is_unlocked: bool = (lvl <= max_unlocked_level)
				var is_boss: bool = (lvl % 5 == 0)

				if is_unlocked:
					btn.disabled = false
					btn.mouse_filter = Control.MOUSE_FILTER_STOP
					if is_boss:
						var boss_tag: String = "BOSS"
						match lvl:
							5:
								boss_tag = "WAURIOR"
							10:
								boss_tag = "MINANGKABAU"
							15:
								boss_tag = "TWIN WAURIOR"
							20:
								boss_tag = "COALITION"
						btn.text = "LEVEL %d\n💀 %s" % [lvl, boss_tag]
						btn.add_theme_stylebox_override("normal", boss_normal)
						btn.add_theme_stylebox_override("hover", boss_hover)
						btn.add_theme_stylebox_override("pressed", boss_hover)
						btn.set("theme_override_colors/font_color", Color(1.0, 0.45, 0.45))
						btn.set("theme_override_colors/font_hover_color", Color(1.0, 0.75, 0.75))
					else:
						btn.text = "LEVEL %d\n★" % lvl
						btn.add_theme_stylebox_override("normal", cyan_normal)
						btn.add_theme_stylebox_override("hover", cyan_hover)
						btn.add_theme_stylebox_override("pressed", cyan_hover)
						btn.set("theme_override_colors/font_color", Color(0.25, 0.95, 1.0))
						btn.set("theme_override_colors/font_hover_color", Color(0.65, 1.0, 1.0))

					btn.pressed.connect(func():
						_on_level_button_clicked(lvl)
					)
				else:
					btn.disabled = true
					btn.mouse_filter = Control.MOUSE_FILTER_PASS
					btn.add_theme_stylebox_override("disabled", grey_style)
					btn.add_theme_stylebox_override("normal", grey_style)
					if is_boss:
						btn.text = "LEVEL %d\n💀 LOCKED" % lvl
					else:
						btn.text = "LEVEL %d\n🔒" % lvl
					btn.set("theme_override_colors/font_disabled_color", Color(0.72, 0.76, 0.82))
					btn.set("theme_override_colors/font_color", Color(0.72, 0.76, 0.82))

				# Sprint 5: Small crown above the level box if the player has completed this level
				if SaveManager.is_level_completed(lvl) and crown_icon_texture:
					var crown_rect: TextureRect = TextureRect.new()
					crown_rect.name = "CrownIcon"
					crown_rect.texture = crown_icon_texture
					crown_rect.custom_minimum_size = Vector2(30, 22)
					crown_rect.size = Vector2(30, 22)
					crown_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					crown_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					crown_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					# Centered horizontally and placed neatly above the top edge of the button
					crown_rect.position = Vector2((btn.custom_minimum_size.x - 30.0) * 0.5, -14.0)
					btn.add_child(crown_rect)
			else:
				btn.text = "SECTOR %d\nOFFLINE" % lvl
				btn.disabled = true
				btn.mouse_filter = Control.MOUSE_FILTER_PASS
				btn.add_theme_stylebox_override("disabled", grey_style)
				btn.set("theme_override_colors/font_disabled_color", Color(0.45, 0.48, 0.52))

			page_grid.add_child(btn)


func _on_level_button_clicked(level_num: int) -> void:
	if was_carousel_dragged or is_carousel_dragging:
		return
	_play_ui_sfx(sfx_play_start)
	# Smooth fade transition to black, then emit signal to proceed to gameplay screen
	fade_to_black(0.35, func():
		hide_select_level()
		level_selected.emit(level_num)
	)


func _switch_tab(tab_name: String) -> void:
	if tab_name == "levels":
		if levels_view:
			levels_view.visible = true
		if levels_tab_button:
			levels_tab_button.set("theme_override_colors/font_color", Color(0.3, 0.95, 1.0))
		if skins_tab_button:
			skins_tab_button.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7))
	elif tab_name in ["skins", "hangar", "upgrades"]:
		if levels_tab_button:
			levels_tab_button.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7))
		if skins_tab_button:
			skins_tab_button.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.25))
		if tab_name == "skins":
			shop_default_tab = "skins"
		elif tab_name == "upgrades":
			shop_default_tab = "upgrades"
		else:
			shop_default_tab = current_shop_tab
		open_upgrade_bay_requested.emit("select_level")


func _switch_shop_tab(tab_name: String) -> void:
	current_shop_tab = tab_name
	var is_upg: bool = (tab_name == "upgrades")
	if items_box:
		items_box.visible = is_upg
	if reset_upgrades_button:
		reset_upgrades_button.visible = is_upg
	if shop_separator2:
		shop_separator2.visible = is_upg
	if shop_status_label and not is_upg:
		shop_status_label.visible = false
	if skins_view:
		skins_view.visible = not is_upg

	if shop_upgrades_tab_button:
		_style_shop_tab_button(shop_upgrades_tab_button, is_upg)
	if shop_skins_tab_button:
		_style_shop_tab_button(shop_skins_tab_button, not is_upg)

	if not is_upg:
		_refresh_skins_view()


func _style_shop_tab_button(btn: Button, is_active: bool) -> void:
	if not btn:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	if is_active:
		style.bg_color = Color(0.08, 0.22, 0.35, 0.95)
		style.set_border_width_all(2)
		style.border_color = Color(0.3, 0.95, 1.0, 1.0)
		btn.set("theme_override_colors/font_color", Color(0.3, 0.95, 1.0))
		btn.set("theme_override_colors/font_hover_color", Color(0.6, 1.0, 1.0))
	else:
		style.bg_color = Color(0.05, 0.08, 0.14, 0.8)
		style.set_border_width_all(1)
		style.border_color = Color(0.3, 0.35, 0.45, 0.6)
		btn.set("theme_override_colors/font_color", Color(0.65, 0.7, 0.78))
		btn.set("theme_override_colors/font_hover_color", Color(0.9, 0.95, 1.0))
	btn.add_theme_stylebox_override("normal", style)
	var hov: StyleBoxFlat = style.duplicate()
	hov.bg_color = Color(0.12, 0.28, 0.42, 1.0)
	hov.border_color = Color(0.5, 1.0, 1.0, 1.0)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)


func _style_skin_card(card: PanelContainer, is_equipped: bool, accent_color: Color) -> void:
	if not card:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	if is_equipped:
		style.bg_color = Color(accent_color.r * 0.14, accent_color.g * 0.14, accent_color.b * 0.14, 0.95)
		style.set_border_width_all(2)
		style.border_color = accent_color
		style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.4)
		style.shadow_size = 10
	else:
		style.bg_color = Color(0.04, 0.06, 0.10, 0.90)
		style.set_border_width_all(1)
		style.border_color = Color(0.25, 0.3, 0.4, 0.5)
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 4
	card.add_theme_stylebox_override("panel", style)


func _style_skin_button(btn: Button, is_equipped: bool, accent_color: Color) -> void:
	if not btn:
		return
	var norm: StyleBoxFlat = StyleBoxFlat.new()
	norm.set_corner_radius_all(6)
	if is_equipped:
		btn.text = "✓ EQUIPPED"
		norm.bg_color = Color(accent_color.r * 0.25, accent_color.g * 0.25, accent_color.b * 0.25, 0.95)
		norm.set_border_width_all(2)
		norm.border_color = accent_color
		btn.set("theme_override_colors/font_color", accent_color)
		btn.set("theme_override_colors/font_hover_color", Color(1, 1, 1))
	else:
		btn.text = "EQUIP SHIP"
		norm.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		norm.set_border_width_all(1)
		norm.border_color = Color(0.4, 0.5, 0.65, 0.8)
		btn.set("theme_override_colors/font_color", Color(0.85, 0.9, 0.95))
		btn.set("theme_override_colors/font_hover_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", norm)

	var hov: StyleBoxFlat = norm.duplicate()
	hov.bg_color = Color(accent_color.r * 0.35 + 0.1, accent_color.g * 0.35 + 0.1, accent_color.b * 0.35 + 0.1, 1.0)
	hov.border_color = Color(1, 1, 1, 0.9)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)


func _select_skin(skin_id: String) -> void:
	_play_ui_sfx(sfx_btn_click)
	current_skin_id = skin_id
	var data: Dictionary = SaveManager.load_save_data()
	data["selected_skin"] = skin_id
	SaveManager.save_data(data)
	_refresh_skins_view()
	skin_selected.emit(skin_id)


func _refresh_skins_view() -> void:
	if skins_title:
		skins_title.text = "FLEET HANGAR & UPGRADE BAY"
	if skins_subtitle:
		match current_skin_id:
			"crimson":
				skins_subtitle.text = "🗡️ Hang Jebat Jet: Sang Pemberontak — 'Raja Adil Disembah, Raja Zalim Disanggah'"
			"void":
				skins_subtitle.text = "🥷 Hang Lekir Jet: Sang Bayang — 'Gerak Kilat, Musuh Tersirat'"
			"gold":
				skins_subtitle.text = "👑 Hang Kasturi Jet: Sang Kesatria — 'Biar Putih Tulang, Jangan Putih Mata'"
			_:
				skins_subtitle.text = "🌙 Hang Tuah Jet: Sang Laksamana — 'Tak Melayu Hilang di Angkasa'"

	var is_def: bool = (current_skin_id == "default")
	var is_crim: bool = (current_skin_id == "crimson")
	var is_void: bool = (current_skin_id == "void")
	var is_gold: bool = (current_skin_id == "gold")

	_style_skin_card(skin_default_card, is_def, Color(0.3, 0.95, 1.0))
	_style_skin_card(skin_crimson_card, is_crim, Color(1.0, 0.4, 0.4))
	_style_skin_card(skin_void_card, is_void, Color(1.0, 0.85, 0.25))
	_style_skin_card(skin_gold_card, is_gold, Color(0.75, 0.45, 1.0))

	_style_skin_button(skin_default_button, is_def, Color(0.3, 0.95, 1.0))
	_style_skin_button(skin_crimson_button, is_crim, Color(1.0, 0.4, 0.4))
	_style_skin_button(skin_void_button, is_void, Color(1.0, 0.85, 0.25))
	_style_skin_button(skin_gold_button, is_gold, Color(0.75, 0.45, 1.0))


# -----------------------------------------------------------------------------
# SCREEN TRANSITION OVERLAY (FADE TO / FROM BLACK)
# -----------------------------------------------------------------------------

func fade_to_black(duration: float = 0.35, on_complete: Callable = Callable()) -> void:
	if not screen_transition_overlay:
		if on_complete.is_valid():
			on_complete.call()
		return

	screen_transition_overlay.visible = true
	screen_transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

	var tween: Tween = create_tween()
	tween.tween_property(screen_transition_overlay, "color:a", 1.0, duration)
	tween.tween_callback(func():
		if on_complete.is_valid():
			on_complete.call()
	)


func fade_from_black(duration: float = 0.35, on_complete: Callable = Callable()) -> void:
	if not screen_transition_overlay:
		if on_complete.is_valid():
			on_complete.call()
		return

	screen_transition_overlay.visible = true
	screen_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_transition_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

	var tween: Tween = create_tween()
	tween.tween_property(screen_transition_overlay, "color:a", 0.0, duration)
	tween.tween_callback(func():
		if screen_transition_overlay:
			screen_transition_overlay.visible = false
		if on_complete.is_valid():
			on_complete.call()
	)


# -----------------------------------------------------------------------------
# LEVEL COMPLETED SCREEN (3 BUTTONS: EXIT, UPGRADE, CONTINUE TO NEXT LEVEL)
# -----------------------------------------------------------------------------

func show_level_completed(
	wave_num: int,
	total_score: int,
	pts: int,
	has_next: bool = true,
	is_first_time: bool = true
) -> void:
	is_level_completed_active = true
	is_paused = false
	get_tree().paused = false
	set_mobile_controls_visible(false)
	set_airspace_warning_visible(false)
	set_airspace_warning_visible(false)
	if pause_button:
		pause_button.visible = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false

	if banner_container:
		banner_container.visible = false
	if shop_container:
		shop_container.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false
	if game_over_container:
		game_over_container.visible = false

	if completed_title:
		completed_title.text = "Level completed!"
	if completed_stats:
		if is_first_time and pts > 0:
			completed_stats.text = "Level %d Cleared  •  Score: %d PTS  •  Upgrade Points: +%d 💎" % [wave_num, total_score, pts]
		else:
			completed_stats.text = "Level %d Cleared (Repeat)  •  Score: %d PTS  •  Upgrade Points: +0 💎 (Already Claimed)" % [wave_num, total_score]

	if completed_continue_button:
		completed_continue_button.visible = true
		if not has_next:
			completed_continue_button.text = "CAMPAIGN VICTORY 🏆"
		else:
			completed_continue_button.text = "CONTINUE TO NEXT LEVEL ➔"

	_play_ui_sfx(sfx_level_complete)

	if level_completed_container:
		level_completed_container.visible = true
		level_completed_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(level_completed_container, "modulate:a", 1.0, 0.3)


func hide_level_completed() -> void:
	is_level_completed_active = false
	if level_completed_container:
		var tween: Tween = create_tween()
		tween.tween_property(level_completed_container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			if level_completed_container:
				level_completed_container.visible = false
		)


# -----------------------------------------------------------------------------
# LEVEL LOST SCREEN (3 BUTTONS: EXIT, UPGRADE, REPLAY LEVEL)
# -----------------------------------------------------------------------------

func show_level_lost(wave_num: int) -> void:
	is_level_lost_active = true
	is_paused = false
	get_tree().paused = false
	set_mobile_controls_visible(false)
	set_airspace_warning_visible(false)
	if pause_button:
		pause_button.visible = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false

	if banner_container:
		banner_container.visible = false
	if shop_container:
		shop_container.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if game_over_container:
		game_over_container.visible = false

	if lost_title:
		lost_title.text = "Level Lost!"
	if lost_stats:
		lost_stats.text = "Defeated on Level %d • Upgrade your ship and try again!" % wave_num
	if lost_upgrade_button:
		lost_upgrade_button.text = "💎 UPGRADE (%d PTS)" % cached_upgrade_points

	if level_lost_container:
		level_lost_container.visible = true
		level_lost_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(level_lost_container, "modulate:a", 1.0, 0.3)


func hide_level_lost() -> void:
	is_level_lost_active = false
	if level_lost_container:
		var tween: Tween = create_tween()
		tween.tween_property(level_lost_container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			if level_lost_container:
				level_lost_container.visible = false
		)


# -----------------------------------------------------------------------------
# PAUSE SCREEN IMPLEMENTATION (EXIT, REPLAY, RESUME)
# -----------------------------------------------------------------------------

func show_pause_screen(wave_num: int = -1) -> void:
	is_paused = true
	get_tree().paused = true
	set_mobile_controls_visible(false)
	if pause_button:
		pause_button.visible = false

	if wave_num > 0:
		current_wave_num = wave_num

	if pause_title:
		pause_title.text = "Paused"
	if pause_stats:
		pause_stats.text = "Level %d in Progress • Tactical Standby" % current_wave_num

	if pause_container:
		pause_container.visible = true
		pause_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(pause_container, "modulate:a", 1.0, 0.2)


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false
	settings_opened_from = ""
	set_mobile_controls_visible(true)
	if pause_button:
		pause_button.visible = true
	var p = get_parent()
	if p and "current_state" in p and p.current_state == 2: # GameState.INTRO
		set_virtual_joystick_visible(false, false)
		set_mobile_fire_button_visible(false, false)


func _on_pause_button_pressed() -> void:
	_play_ui_sfx(sfx_modal_chime)
	show_pause_screen(current_wave_num)


func _on_pause_resume_pressed() -> void:
	_play_ui_sfx(sfx_play_start)
	resume_game()


func _on_pause_replay_pressed() -> void:
	_play_ui_sfx(sfx_play_start)
	is_paused = false
	get_tree().paused = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false
	settings_opened_from = ""
	replay_level_requested.emit()


func _on_pause_exit_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	is_paused = false
	get_tree().paused = false
	if pause_container:
		pause_container.visible = false
	if settings_modal:
		settings_modal.visible = false
	settings_opened_from = ""
	exit_to_level_select_requested.emit()


func _on_shop_continue_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	match shop_opened_from:
		"select_level":
			close_shop()
			if select_level_container:
				select_level_container.visible = true
				_update_select_level_upgrade_button()
				if levels_view:
					levels_view.visible = true
				_switch_tab("levels")
		"level_completed":
			close_shop()
			if level_completed_container:
				level_completed_container.visible = true
				level_completed_container.modulate = Color(1.0, 1.0, 1.0, 1.0)
				is_level_completed_active = true
		"level_lost":
			close_shop()
			if level_lost_container:
				level_lost_container.visible = true
				level_lost_container.modulate = Color(1.0, 1.0, 1.0, 1.0)
				is_level_lost_active = true
				if lost_upgrade_button:
					lost_upgrade_button.text = "💎 UPGRADE (%d PTS)" % cached_upgrade_points
		_: # "gameplay"
			_play_ui_sfx(sfx_play_start)
			resume_wave_requested.emit()


# -----------------------------------------------------------------------------
# EXISTING MODALS & HUD ELEMENTS
# -----------------------------------------------------------------------------


func show_credit_modal() -> void:
	if credit_modal:
		if welcome_container:
			var tw_w: Tween = create_tween()
			tw_w.tween_property(welcome_container, "modulate:a", 0.2, 0.2)
		if welcome_account_container and is_welcome_active:
			var tw_wa: Tween = create_tween()
			tw_wa.tween_property(welcome_account_container, "modulate:a", 0.2, 0.2)
		credit_modal.visible = true
		credit_modal.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(credit_modal, "modulate:a", 1.0, 0.2)


func hide_credit_modal() -> void:
	if welcome_container and is_welcome_active:
		var tw_w: Tween = create_tween()
		tw_w.tween_property(welcome_container, "modulate:a", 1.0, 0.15)
	if welcome_account_container and is_welcome_active:
		var tw_wa: Tween = create_tween()
		tw_wa.tween_property(welcome_account_container, "modulate:a", 1.0, 0.15)
	if credit_modal:
		var tween: Tween = create_tween()
		tween.tween_property(credit_modal, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): credit_modal.visible = false)


func show_settings_modal() -> void:
	if settings_modal:
		var current_vol: float = SaveManager.get_master_volume()
		if sound_slider:
			sound_slider.value = current_vol
		_update_sound_slider_ui(current_vol)

		var current_music_vol: float = SaveManager.get_music_volume()
		if music_slider:
			music_slider.value = current_music_vol
		_update_music_slider_ui(current_music_vol)

		var current_sfx_vol: float = SaveManager.get_sfx_volume()
		if sfx_slider:
			sfx_slider.value = current_sfx_vol
		_update_sfx_slider_ui(current_sfx_vol)

		if reset_status_label:
			reset_status_label.visible = false
		if reset_confirm_modal:
			reset_confirm_modal.visible = false

		# Ingame vs Main Menu Settings differentiation:
		# Reset progress section ONLY exists in Main Menu Settings, NEVER in Ingame Settings
		var is_ingame: bool = (settings_opened_from == "pause" or is_paused)
		if reset_section:
			reset_section.visible = not is_ingame
		if reset_separator:
			reset_separator.visible = not is_ingame

		# Layering & Overlap Fix: Cleanly hide the originating menu so it does not overlap with Settings
		if is_ingame:
			if pause_container:
				pause_container.visible = false
		elif welcome_container and is_welcome_active:
			welcome_container.visible = false
			if welcome_account_container:
				welcome_account_container.visible = false

		settings_modal.z_index = 25
		settings_modal.visible = true
		settings_modal.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(settings_modal, "modulate:a", 1.0, 0.2)


func hide_settings_modal() -> void:
	var from_screen: String = settings_opened_from
	settings_opened_from = ""

	if reset_confirm_modal and reset_confirm_modal.visible:
		hide_reset_confirm_modal()

	# Layering & Overlap Fix: Restore previous menu cleanly without overlapping
	if from_screen == "pause" or is_paused:
		if pause_container and is_paused:
			pause_container.visible = true
			pause_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tw_p: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_p.tween_property(pause_container, "modulate:a", 1.0, 0.15)
	elif welcome_container and is_welcome_active:
		welcome_container.visible = true
		welcome_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tw_w: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_w.tween_property(welcome_container, "modulate:a", 1.0, 0.15)
		if welcome_account_container:
			welcome_account_container.visible = true
			welcome_account_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tw_wa: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_wa.tween_property(welcome_account_container, "modulate:a", 1.0, 0.15)

	if settings_modal:
		var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(settings_modal, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): settings_modal.visible = false)


func _on_sound_slider_value_changed(val: float) -> void:
	_update_sound_slider_ui(val)
	_apply_sound_volume(val)
	SaveManager.set_master_volume(val)
	sound_volume_changed.emit(val)


func _update_sound_slider_ui(val: float) -> void:
	if sound_value_label:
		sound_value_label.text = "%d%%" % int(round(val * 100.0))


func _on_music_slider_value_changed(val: float) -> void:
	_update_music_slider_ui(val)
	_apply_music_volume(val)
	SaveManager.set_music_volume(val)
	music_volume_changed.emit(val)


func _update_music_slider_ui(val: float) -> void:
	if music_value_label:
		music_value_label.text = "%d%%" % int(round(val * 100.0))


func _on_sfx_slider_value_changed(val: float) -> void:
	_update_sfx_slider_ui(val)
	_apply_sfx_volume(val)
	SaveManager.set_sfx_volume(val)
	sfx_volume_changed.emit(val)
	_play_ui_sfx(sfx_btn_click)


func _update_sfx_slider_ui(val: float) -> void:
	if sfx_value_label:
		sfx_value_label.text = "%d%%" % int(round(val * 100.0))


func _apply_music_volume(linear_vol: float) -> void:
	MusicManager.apply_music_volume(linear_vol)


func _apply_sfx_volume(linear_vol: float) -> void:
	SoundManager.apply_sfx_volume(linear_vol)


func _apply_sound_volume(linear_vol: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx < 0:
		bus_idx = 0
	linear_vol = clampf(linear_vol, 0.0, 1.0)
	if linear_vol <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db_vol: float = linear_to_db(linear_vol)
		AudioServer.set_bus_volume_db(bus_idx, db_vol)


func _on_reset_progress_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	show_reset_confirm_modal()


func show_reset_confirm_modal() -> void:
	if reset_confirm_modal:
		reset_confirm_modal.z_index = 30
		reset_confirm_modal.visible = true
		reset_confirm_modal.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(reset_confirm_modal, "modulate:a", 1.0, 0.15)


func hide_reset_confirm_modal() -> void:
	if reset_confirm_modal and reset_confirm_modal.visible:
		var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(reset_confirm_modal, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func(): reset_confirm_modal.visible = false)
	elif reset_confirm_modal:
		reset_confirm_modal.visible = false


func _on_reset_cancel_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	hide_reset_confirm_modal()


func _on_reset_confirm_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	hide_reset_confirm_modal()
	execute_reset_all_progress()


func execute_reset_all_progress() -> void:
	var reset_dict: Dictionary = SaveManager.reset_all_progress()
	cached_upgrade_points = int(reset_dict.get("upgrade_points", 3))
	max_unlocked_level = int(reset_dict.get("unlocked_level", 1))
	current_skin_id = "default"
	current_page = 1
	update_upgrade_points(cached_upgrade_points)
	_refresh_skins_view()

	if reset_status_label:
		reset_status_label.visible = true
		reset_status_label.text = "All progress has been reset!"
		reset_status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var t_reset: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t_reset.tween_interval(1.8)
		t_reset.tween_property(reset_status_label, "modulate:a", 0.0, 0.5)
		t_reset.tween_callback(func(): reset_status_label.visible = false)

	progress_reset_requested.emit()


func set_hud_stats_visible(is_visible: bool) -> void:
	if stats_margin_container:
		stats_margin_container.visible = is_visible
	set_mobile_controls_visible(is_visible)
	if pause_button:
		pause_button.visible = is_visible and not is_paused


func set_mobile_controls_visible(is_visible: bool) -> void:
	if mobile_controls:
		mobile_controls.visible = is_visible
		if is_visible:
			if virtual_joystick:
				virtual_joystick.visible = true
				if virtual_joystick.has_method("_release"):
					virtual_joystick._release()
			if mobile_fire_button:
				mobile_fire_button.visible = true
				if mobile_fire_button.has_method("reset_state"):
					mobile_fire_button.reset_state()
		else:
			if virtual_joystick and virtual_joystick.has_method("_release"):
				virtual_joystick._release()
			if mobile_fire_button and mobile_fire_button.has_method("reset_state"):
				mobile_fire_button.reset_state()


var _joystick_fade_tween: Tween = null
var _fire_button_fade_tween: Tween = null


func set_virtual_joystick_visible(is_visible: bool, animate: bool = true) -> void:
	if virtual_joystick:
		if _joystick_fade_tween and _joystick_fade_tween.is_valid():
			_joystick_fade_tween.kill()
		if is_visible:
			virtual_joystick.visible = true
			if virtual_joystick.has_method("_release"):
				virtual_joystick._release()
			if animate:
				virtual_joystick.modulate.a = 0.0
				_joystick_fade_tween = create_tween()
				_joystick_fade_tween.tween_property(virtual_joystick, "modulate:a", 1.0, 0.25)
			else:
				virtual_joystick.modulate.a = 1.0
		else:
			if virtual_joystick.has_method("_release"):
				virtual_joystick._release()
			virtual_joystick.visible = false
			virtual_joystick.modulate.a = 1.0


func set_mobile_fire_button_visible(is_visible: bool, animate: bool = true) -> void:
	if mobile_fire_button:
		if _fire_button_fade_tween and _fire_button_fade_tween.is_valid():
			_fire_button_fade_tween.kill()
		if is_visible:
			mobile_fire_button.visible = true
			if mobile_fire_button.has_method("reset_state"):
				mobile_fire_button.reset_state()
			if animate:
				mobile_fire_button.modulate.a = 0.0
				_fire_button_fade_tween = create_tween()
				_fire_button_fade_tween.tween_property(mobile_fire_button, "modulate:a", 1.0, 0.25)
			else:
				mobile_fire_button.modulate.a = 1.0
		else:
			if mobile_fire_button.has_method("reset_state"):
				mobile_fire_button.reset_state()
			mobile_fire_button.visible = false
			mobile_fire_button.modulate.a = 1.0


func set_mobile_touch_controls_visible(is_visible: bool, animate: bool = true) -> void:
	set_virtual_joystick_visible(is_visible, animate)
	set_mobile_fire_button_visible(is_visible, animate)


func is_virtual_joystick_visible() -> bool:
	return virtual_joystick != null and virtual_joystick.visible


func is_mobile_fire_button_visible() -> bool:
	return mobile_fire_button != null and mobile_fire_button.visible


func update_health(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = float(max_hp)
		health_bar.value = float(current)


func update_shield(current: int, max_shield: int) -> void:
	if shield_label:
		if max_shield <= 0:
			shield_label.text = "Shield: [0]"
			shield_label.modulate = Color(0.6, 0.6, 0.6)
		else:
			shield_label.text = "Shield: [%d/%d]" % [current, max_shield]
			shield_label.modulate = Color(0.2, 0.85, 1.0) if current > 0 else Color(0.7, 0.3, 0.3)


func update_score(points: int, _level: int = 1) -> void:
	if score_label:
		score_label.text = "Score: %d" % points


func update_wave(wave_num: int, wave_title: String = "") -> void:
	current_wave_num = wave_num
	if wave_label:
		if wave_title.is_empty():
			wave_label.text = "Wave: %d" % wave_num
		else:
			wave_label.text = "Wave: %d - %s" % [wave_num, wave_title]


func update_wave_progress(remaining: int, total: int) -> void:
	if progress_label:
		progress_label.text = "Remaining: %d / %d" % [maxi(0, remaining), total]


func update_upgrade_points(points: int) -> void:
	cached_upgrade_points = points
	if points_label:
		points_label.text = "Upgrade Points: %d 💎" % points
	if shop_points:
		shop_points.text = "💎 Upgrade Points: %d" % points
	_update_select_level_upgrade_button()


func update_gun_status(gun_level: int, has_emergency: bool = false) -> void:
	if gun_status_label:
		if gun_level <= 0:
			gun_status_label.text = "Starter Blaster (1 Pierce, 2 Dmg)"
			gun_status_label.modulate = Color(1.0, 0.75, 0.2)
		elif gun_level == 1:
			gun_status_label.text = "Blaster Lv 1: Single (2 Pierce, 3 Dmg)"
			gun_status_label.modulate = Color(0.3, 0.9, 0.6)
		elif gun_level == 2:
			gun_status_label.text = "Blaster Lv 2: Dual Rapid (2 Pierce, 5 Dmg)"
			gun_status_label.modulate = Color(1.0, 0.85, 0.25)
		elif gun_level == 3:
			gun_status_label.text = "Cannon Lv 3: Heavy Shell (5 Pierce, 8 Dmg)"
			gun_status_label.modulate = Color(1.0, 0.48, 0.1)
		elif gun_level == 4:
			gun_status_label.text = "Gatling Lv 4: Explosive (3 Pierce, 5 Dmg, AOE)"
			gun_status_label.modulate = Color(1.0, 0.35, 0.15)
		else:
			gun_status_label.text = "Laser Lv 5: Quasar Beam (1 Pierce, 7 Dmg)"
			gun_status_label.modulate = Color(1.0, 0.2, 0.25)


func show_boss_bar(title: String, current_hp: int, max_hp: int) -> void:
	if boss_bar_container and boss_title_label and boss_progress_bar:
		boss_title_label.text = title
		boss_progress_bar.max_value = float(max_hp)
		boss_progress_bar.value = float(current_hp)
		boss_bar_container.visible = true
		boss_bar_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)


func update_boss_health(current_hp: int, max_hp: int) -> void:
	if boss_progress_bar:
		boss_progress_bar.max_value = float(max_hp)
		boss_progress_bar.value = float(current_hp)


func hide_boss_bar() -> void:
	if boss_bar_container:
		var tween: Tween = create_tween()
		tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func(): boss_bar_container.visible = false)


func open_shop(
	points: int,
	shield_lvl: int,
	shield_cost: int,
	speed_lvl: int,
	speed_val: float,
	speed_cost: int,
	gun_lvl: int,
	gun_cost: int,
	opened_from_context: String = "gameplay"
) -> void:
	is_shop_open = true
	shop_opened_from = opened_from_context
	set_mobile_controls_visible(false)
	update_upgrade_points(points)

	# Strictly prevent overlap: hide any other active containers
	if level_completed_container:
		level_completed_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false
	if shop_opened_from == "select_level" and select_level_container:
		select_level_container.visible = false

	# Configure Continue / Close button text depending on context
	if continue_button:
		match shop_opened_from:
			"select_level":
				continue_button.text = "◀ RETURN TO LEVEL SELECT"
			"level_completed":
				continue_button.text = "◀ RETURN TO RESULTS"
			"level_lost":
				continue_button.text = "◀ RETURN TO LEVEL LOST"
			_:
				continue_button.text = "CONTINUE TO NEXT WAVE ➔"

	# [1] Shield
	if shield_lvl >= 3:
		shield_info.text = "Kinetic Shield • MAX (6 HP)"
		shield_button.text = "MAXED"
		shield_button.disabled = true
	elif shield_lvl == 2:
		shield_info.text = "Kinetic Shield • Lv 3 (6 HP)"
		shield_button.text = "UPGRADE [%d PTS]" % shield_cost
		shield_button.disabled = (points < shield_cost)
	elif shield_lvl == 1:
		shield_info.text = "Kinetic Shield • Lv 2 (4 HP)"
		shield_button.text = "UPGRADE [%d PTS]" % shield_cost
		shield_button.disabled = (points < shield_cost)
	else:
		shield_info.text = "Kinetic Shield • Lv 1 (2 HP)"
		shield_button.text = "UNLOCK [%d PT]" % shield_cost
		shield_button.disabled = (points < shield_cost)

	# [2] Speed
	if speed_lvl >= 3:
		speed_info.text = "Thrusters • MAX (%.0f px/s)" % speed_val
		speed_button.text = "MAXED"
		speed_button.disabled = true
	else:
		speed_info.text = "Thrusters • Lv %d (+65 Speed)" % (speed_lvl + 1)
		speed_button.text = "UPGRADE [%d PTS]" % speed_cost
		speed_button.disabled = (points < speed_cost)

	# [3] Gun
	if gun_lvl >= 5:
		gun_info.text = "Quasar Laser • MAX (Beam)"
		gun_button.text = "MAXED"
		gun_button.disabled = true
	elif gun_lvl == 4:
		gun_info.text = "Quasar Laser • Lv 5 (Beam)"
		gun_button.text = "UPGRADE [%d PTS]" % gun_cost
		gun_button.disabled = (points < gun_cost)
	elif gun_lvl == 3:
		gun_info.text = "Explosive Gatling • Lv 4 (AOE)"
		gun_button.text = "UPGRADE [%d PTS]" % gun_cost
		gun_button.disabled = (points < gun_cost)
	elif gun_lvl == 2:
		gun_info.text = "Heavy Cannon • Lv 3 (Shell)"
		gun_button.text = "UPGRADE [%d PTS]" % gun_cost
		gun_button.disabled = (points < gun_cost)
	elif gun_lvl == 1:
		gun_info.text = "Dual Blaster • Lv 2 (Rapid)"
		gun_button.text = "UPGRADE [%d PTS]" % gun_cost
		gun_button.disabled = (points < gun_cost)
	else:
		gun_info.text = "Plasma Blaster • Lv 1"
		gun_button.text = "UPGRADE [%d PTS]" % gun_cost
		gun_button.disabled = (points < gun_cost)

	# [4] Reset Upgrades Button (Refund spent points)
	var spent_pts: int = calculate_spent_upgrade_points(shield_lvl, speed_lvl, gun_lvl)
	if reset_upgrades_button:
		if spent_pts > 0:
			reset_upgrades_button.disabled = false
			reset_upgrades_button.text = "↺ RESET UPGRADES (REFUND %d PTS)" % spent_pts
			reset_upgrades_button.set("theme_override_colors/font_color", Color(1.0, 0.45, 0.45, 1.0))
		else:
			reset_upgrades_button.disabled = true
			reset_upgrades_button.text = "↺ RESET UPGRADES (0 PTS SPENT)"
			reset_upgrades_button.set("theme_override_colors/font_color", Color(0.55, 0.55, 0.6, 0.6))

	if shop_status_label:
		shop_status_label.visible = false

	# Refresh skins view and activate target tab
	var target_tab: String = shop_default_tab if not shop_default_tab.is_empty() else "upgrades"
	shop_default_tab = "upgrades" # reset for next time
	_switch_shop_tab(target_tab)

	if shop_container:
		shop_container.visible = true
		shop_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(shop_container, "modulate:a", 1.0, 0.2)


func _on_reset_upgrades_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	reset_upgrades_requested.emit()


func show_shop_status(msg: String, is_success: bool = true) -> void:
	if shop_status_label:
		shop_status_label.text = msg
		shop_status_label.set("theme_override_colors/font_color", Color(0.3, 1.0, 0.5) if is_success else Color(1.0, 0.4, 0.4))
		shop_status_label.visible = true
		shop_status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var t_st: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t_st.tween_interval(1.8)
		t_st.tween_property(shop_status_label, "modulate:a", 0.0, 0.4)
		t_st.tween_callback(func(): shop_status_label.visible = false)


static func calculate_spent_upgrade_points(sh_lvl: int, sp_lvl: int, gn_lvl: int) -> int:
	var total: int = 0
	# Shield: Lv1: 1, Lv2: 2, Lv3: 3
	if sh_lvl >= 1: total += 1
	if sh_lvl >= 2: total += 2
	if sh_lvl >= 3: total += 3
	# Speed: Lv1: 2, Lv2: 3, Lv3: 4
	if sp_lvl >= 1: total += 2
	if sp_lvl >= 2: total += 3
	if sp_lvl >= 3: total += 4
	# Gun: Lv1: 2, Lv2: 3, Lv3: 3, Lv4: 5, Lv5: 5
	if gn_lvl >= 1: total += 2
	if gn_lvl >= 2: total += 3
	if gn_lvl >= 3: total += 3
	if gn_lvl >= 4: total += 5
	if gn_lvl >= 5: total += 5
	return total


func close_shop() -> void:
	is_shop_open = false
	if shop_opened_from == "gameplay":
		set_mobile_controls_visible(true)
	if shop_container:
		var tween: Tween = create_tween()
		tween.tween_property(shop_container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): shop_container.visible = false)


func show_wave_banner(
	title: String,
	subtitle: String,
	duration: float = 2.0,
	title_color: Color = Color(1.0, 1.0, 1.0)
) -> void:
	if not banner_container or not banner_title or not banner_subtitle:
		return

	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	banner_title.text = title
	banner_title.set("theme_override_colors/font_color", title_color)
	banner_subtitle.text = subtitle
	banner_container.visible = true
	banner_container.modulate = Color(1.0, 1.0, 1.0, 0.0)

	banner_tween = create_tween()
	banner_tween.tween_property(banner_container, "modulate:a", 1.0, 0.25)
	banner_tween.tween_interval(maxf(0.4, duration - 0.5))
	banner_tween.tween_property(banner_container, "modulate:a", 0.0, 0.25)
	banner_tween.tween_callback(func():
		if banner_container:
			banner_container.visible = false
	)


func show_game_over(final_score: int = 0, final_wave: int = 1, is_new_record: bool = false) -> void:
	set_mobile_controls_visible(false)
	set_airspace_warning_visible(false)
	if banner_container:
		banner_container.visible = false
	if shop_container:
		shop_container.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false

	if game_over_container:
		if game_over_title:
			game_over_title.text = "GAME OVER"
			game_over_title.set("theme_override_colors/font_color", Color(1.0, 0.25, 0.25))
		if game_over_stats:
			game_over_stats.text = "Wave Reached: %d  |  Final Score: %d" % [final_wave, final_score]
		if high_score_alert:
			high_score_alert.visible = is_new_record
		game_over_container.visible = true
		game_over_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(game_over_container, "modulate:a", 1.0, 0.4)


func show_victory(final_score: int = 0, is_new_record: bool = false) -> void:
	set_mobile_controls_visible(false)
	if banner_container:
		banner_container.visible = false
	if shop_container:
		shop_container.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if level_lost_container:
		level_lost_container.visible = false

	if game_over_container:
		if game_over_title:
			game_over_title.text = "You saved the Malay's Realm!"
			game_over_title.set("theme_override_colors/font_color", Color(0.3, 1.0, 0.5))
		if game_over_stats:
			game_over_stats.text = "You saved the Malay's Realm!"
		if high_score_alert:
			high_score_alert.visible = is_new_record
		game_over_container.visible = true
		game_over_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(game_over_container, "modulate:a", 1.0, 0.5)


func show_comic(comic_id: String, context: String = "review") -> void:
	set_mobile_controls_visible(false)
	set_hud_stats_visible(false)
	if pause_button:
		pause_button.visible = false
	if banner_container:
		banner_container.visible = false
	if level_completed_container:
		level_completed_container.visible = false
	if comic_slides:
		comic_slides.start_comic(comic_id, context)


func _init_ui_audio() -> void:
	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.bus = "SFX"
	ui_audio_player.volume_db = 0.0
	ui_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_audio_player)

	sfx_btn_click = SoundManager.get_sound_stream("button_click")
	sfx_play_start = SoundManager.get_sound_stream("play_start")
	sfx_modal_chime = SoundManager.get_sound_stream("modal_chime")
	sfx_level_complete = SoundManager.get_sound_stream("level_complete")


func _play_ui_sfx(stream: AudioStream = null) -> void:
	var target_stream: AudioStream = stream
	if target_stream == null:
		if sfx_btn_click != null:
			target_stream = sfx_btn_click
		else:
			sfx_btn_click = SoundManager.get_sound_stream("button_click")
			target_stream = sfx_btn_click

	if ui_audio_player and target_stream:
		ui_audio_player.stream = target_stream
		ui_audio_player.play()
	else:
		SoundManager.play_sfx("button_click")


func _generate_tone(frequencies: Array[float], duration: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
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
		var env: float = pow(1.0 - progress, 1.3)

		var sample_val: int = clampi(int(128.0 + tone * env * 42.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream


# -----------------------------------------------------------------------------
# HUAWEI MOBILE SERVICES (HMS) ACCOUNT KIT INTEGRATION
# -----------------------------------------------------------------------------

func _init_huawei_account_ui() -> void:
	var hms_manager = get_node_or_null("/root/HMSAccountManager")
	if hms_manager:
		hms_manager.sign_in_success.connect(_on_huawei_sign_in_success)
		hms_manager.sign_in_failed.connect(_on_huawei_sign_in_failed)
		hms_manager.sign_out_success.connect(_on_huawei_sign_out_success)

	if huawei_sign_in_button:
		huawei_sign_in_button.pressed.connect(_on_huawei_sign_in_pressed)
	if profile_sign_out_button:
		profile_sign_out_button.pressed.connect(_on_huawei_sign_out_pressed)

	if hms_manager:
		_update_huawei_account_ui(hms_manager.is_signed_in, hms_manager.player_name)
		hms_manager.silent_sign_in()


func _on_huawei_sign_in_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	if huawei_sign_in_button:
		huawei_sign_in_button.disabled = true
		huawei_sign_in_button.text = "Authenticating..."
	var hms_manager = get_node_or_null("/root/HMSAccountManager")
	if hms_manager:
		hms_manager.sign_in()


func _on_huawei_sign_out_pressed() -> void:
	_play_ui_sfx(sfx_btn_click)
	var hms_manager = get_node_or_null("/root/HMSAccountManager")
	if hms_manager:
		hms_manager.sign_out()


func _on_huawei_sign_in_success(display_name: String, _open_id: String) -> void:
	_update_huawei_account_ui(true, display_name)


func _on_huawei_sign_in_failed(_error_code: int, _error_msg: String) -> void:
	_update_huawei_account_ui(false, "")


func _on_huawei_sign_out_success() -> void:
	_update_huawei_account_ui(false, "")


func _update_huawei_account_ui(signed_in: bool, display_name: String) -> void:
	if huawei_sign_in_button:
		huawei_sign_in_button.disabled = false
		huawei_sign_in_button.text = "🔴  Sign in with HUAWEI ID"
		huawei_sign_in_button.visible = not signed_in
	if huawei_profile_container:
		huawei_profile_container.visible = signed_in
	if pilot_badge_label and signed_in:
		pilot_badge_label.text = "👨‍🚀 Cadet %s" % (display_name if not display_name.is_empty() else "Hang Tuah")
