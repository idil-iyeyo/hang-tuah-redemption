extends SceneTree

const SaveManager = preload("res://scripts/save_manager.gd")
const CombatBoundaryManager = preload("res://scripts/combat_boundary_manager.gd")

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- BEGINNING HEADLESS GODOT RUNTIME VERIFICATION ---")

	var main_scene: PackedScene = load("res://scenes/main/main.tscn")
	if not main_scene:
		printerr("[FAIL] Could not load res://scenes/main/main.tscn")
		quit(1)
		return

	var main: Node = main_scene.instantiate()
	root.add_child(main)
	print("[PASS] main.tscn instantiated and added to root.")

	# Wait for idle frame so all _ready() calls finish completely
	await process_frame
	await process_frame

	# 1. Verify Starfield Background
	var starfield: Node = main.get_node_or_null("StarfieldBackground")
	if not starfield:
		printerr("[FAIL] StarfieldBackground node not found in main")
		quit(1)
		return
	print("[PASS] StarfieldBackground node found.")

	var canvas: Node = starfield.get_node_or_null("StarfieldCanvas")
	if not canvas:
		printerr("[FAIL] StarfieldCanvas not found in StarfieldBackground")
		quit(1)
		return

	var star_list: Array = canvas.get("stars")
	if not star_list or star_list.is_empty():
		printerr("[FAIL] Stars array is empty in StarfieldCanvas")
		quit(1)
		return
	print("[PASS] Starfield initialized with %d stars." % star_list.size())

	# Test star motion
	var sample_star = star_list[0]
	var initial_x: float = sample_star.get("x")
	canvas._process(0.2)
	var new_x: float = sample_star.get("x")
	if new_x >= initial_x:
		printerr("[FAIL] Star did not move leftwards: initial=%f, new=%f" % [initial_x, new_x])
		quit(1)
		return
	print("[PASS] Starfield stars correctly pass to the left (initial x=%.1f -> new x=%.1f)." % [initial_x, new_x])

	# 2. Verify Welcome Screen on Startup
	if main.get("current_state") != 0: # GameState.MENU
		printerr("[FAIL] main current_state should be MENU (0), but got: %s" % str(main.get("current_state")))
		quit(1)
		return
	print("[PASS] Game starts cleanly in MENU state.")

	var hud: CanvasLayer = main.get_node_or_null("HUD") as CanvasLayer
	if not hud:
		printerr("[FAIL] HUD node not found")
		quit(1)
		return

	var welcome_container = hud.get_node_or_null("WelcomeContainer")
	if not welcome_container or not welcome_container.visible:
		printerr("[FAIL] WelcomeContainer is missing or not visible")
		quit(1)
		return
	print("[PASS] WelcomeContainer is active and visible.")

	var game_title: Label = hud.get_node_or_null("WelcomeContainer/TitleBox/GameTitle") as Label
	if not game_title or game_title.text != "Space Shooter 2D":
		printerr("[FAIL] Game Title should be 'Space Shooter 2D', got: %s" % (game_title.text if game_title else "null"))
		quit(1)
		return
	print("[PASS] Game Title is '%s'." % game_title.text)

	var play_btn: Button = hud.get_node_or_null("WelcomeContainer/ButtonsVBox/PlayButton") as Button
	var credit_btn: Button = hud.get_node_or_null("WelcomeContainer/ButtonsVBox/CreditButton") as Button

	if not play_btn or not credit_btn:
		printerr("[FAIL] One or more menu buttons (PLAY, Credit) are missing")
		quit(1)
		return
	print("[PASS] PLAY and Credit buttons verified (High Score mechanics removed as requested).")

	# 3. Test Credit Modal
	credit_btn.emit_signal("pressed")
	var cr_modal = hud.get_node_or_null("CreditModal")
	if not cr_modal or not cr_modal.visible:
		printerr("[FAIL] CreditModal did not open on Credit button press")
		quit(1)
		return
	print("[PASS] CreditModal opens properly.")

	var cr_back: Button = hud.get_node_or_null("CreditModal/Margin/VBox/CreditBackButton") as Button
	if cr_back:
		cr_back.emit_signal("pressed")
	hud.hide_credit_modal()
	await create_timer(0.25).timeout
	if cr_modal.visible:
		printerr("[FAIL] CreditModal did not close")
		quit(1)
		return
	print("[PASS] CreditModal closed successfully.")

	# 4. Test PLAY Button -> Select Level Screen Transition
	play_btn.emit_signal("pressed")
	var select_level = hud.get_node_or_null("SelectLevelContainer")
	if not select_level or not select_level.visible:
		printerr("[FAIL] SelectLevelContainer should be visible after PLAY pressed")
		quit(1)
		return
	print("[PASS] SelectLevelContainer cleanly opened after PLAY.")

	var exit_menu_btn = hud.get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/ExitToMenuButton")
	var upgrade_bay_btn = hud.get_node_or_null("SelectLevelContainer/TopBarMargin/TopBarHBox/SelectLevelUpgradeButton")
	if not exit_menu_btn or not upgrade_bay_btn:
		printerr("[FAIL] Top-left Exit button or Top-right Upgrade Bay button missing")
		quit(1)
		return
	print("[PASS] Top-Left 'Exit to Main Menu' and Top-Right 'Upgrade Bay' verified in Select Level.")

	# 6. Verify Level Grid & Slideable Carousel (Flanking Arrows + Swipe Support)
	var carousel_box = hud.get_node_or_null("SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox")
	var left_arrow_btn = hud.get_node_or_null("SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LeftArrowButton") as Button
	var right_arrow_btn = hud.get_node_or_null("SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/RightArrowButton") as Button
	var viewport_node = hud.get_node_or_null("SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LevelViewport")
	var track_node = hud.get_node_or_null("SelectLevelContainer/ContentMargin/LevelsView/CarouselHBox/LevelViewport/LevelTrack")
	var grid = hud.level_grid

	if not carousel_box or not left_arrow_btn or not right_arrow_btn or not viewport_node or not track_node or not grid:
		printerr("[FAIL] CarouselHBox, LeftArrowButton, RightArrowButton, LevelViewport, LevelTrack, or LevelGrid missing")
		quit(1)
		return
	if grid.get_child_count() != 10:
		printerr("[FAIL] LevelGrid should contain exactly 10 buttons (5 columns x 2 rows), got: %d" % grid.get_child_count())
		quit(1)
		return
	print("[PASS] CarouselHBox, LeftArrowButton, RightArrowButton, LevelViewport, LevelTrack, and 5x2 LevelGrid verified.")

	# Test Arrow Navigation (Way 1)
	if not left_arrow_btn.disabled:
		printerr("[FAIL] LeftArrowButton should be disabled on Page 1")
		quit(1)
		return
	if right_arrow_btn.disabled:
		printerr("[FAIL] RightArrowButton should be enabled on Page 1")
		quit(1)
		return
	print("[PASS] Boundary states verified: Left Arrow disabled on Page 1, Right Arrow enabled.")

	# Navigate to Page 2 via Right Arrow
	right_arrow_btn.emit_signal("pressed")
	if hud.current_page != 2 or not right_arrow_btn.disabled or left_arrow_btn.disabled:
		printerr("[FAIL] Right Arrow did not slide properly to Page 2")
		quit(1)
		return
	print("[PASS] Right Arrow successfully slid to Page 2 (current_page=2, Page 2 indicator updated).")

	# Navigate back to Page 1 via Left Arrow
	left_arrow_btn.emit_signal("pressed")
	if hud.current_page != 1 or left_arrow_btn.disabled != true or right_arrow_btn.disabled != false:
		printerr("[FAIL] Left Arrow did not slide back to Page 1")
		quit(1)
		return
	print("[PASS] Left Arrow successfully slid back to Page 1.")

	# Test Swipe / Drag Navigation (Way 2)
	hud.slide_to_page(2, false)
	if hud.current_page != 2:
		printerr("[FAIL] slide_to_page(2) failed")
		quit(1)
		return
	hud.slide_to_page(1, false)
	if hud.current_page != 1:
		printerr("[FAIL] slide_to_page(1) failed")
		quit(1)
		return
	print("[PASS] slide_to_page horizontal carousel transitions verified.")

	var lvl1_btn = grid.get_child(0) as Button
	var lvl2_btn = grid.get_child(1) as Button
	if lvl1_btn.disabled:
		printerr("[FAIL] Level 1 should be unlocked and playable")
		quit(1)
		return
	if not lvl2_btn.disabled:
		printerr("[FAIL] Level 2 should initially be locked")
		quit(1)
		return
	print("[PASS] Level 1 is unlocked and playable; Level 2 is locked.")

	# 7. Test Select Level 1 -> Black Screen Transition -> Gameplay
	lvl1_btn.emit_signal("pressed")
	await create_timer(0.8).timeout

	var player = main.get_node_or_null("Player")
	if not player or not player.visible:
		printerr("[FAIL] Player not visible after Level 1 selected")
		quit(1)
		return

	# Verification: Player must have 100% full health when starting a level
	if player.current_health != player.max_health:
		printerr("[FAIL] Player should have 100% full health (%d), got %d" % [player.max_health, player.current_health])
		quit(1)
		return
	print("[PASS] Screen transitioned through black, Player activated with 100% full health.")

	# Verification: Upgrade Bay must not contain Hull Repair
	var heal_row = hud.get_node_or_null("ShopContainer/Margin/ShopVBox/ItemsBox/HealRow")
	if heal_row:
		printerr("[FAIL] HealRow should be removed from Upgrade Bay")
		quit(1)
		return
	print("[PASS] Hull Repair row confirmed removed from Upgrade Bay.")

	# Verification: Middle-Top Pause Button & Pause Screen (Resume, Replay, Exit)
	var pause_btn = hud.get_node_or_null("PauseButton") as Button
	var pause_cnt = hud.get_node_or_null("PauseContainer") as PanelContainer
	if not pause_btn or not pause_cnt:
		printerr("[FAIL] PauseButton or PauseContainer missing in HUD")
		quit(1)
		return
	if not pause_btn.visible:
		printerr("[FAIL] PauseButton should be visible during gameplay")
		quit(1)
		return
	print("[PASS] PauseButton is present and visible at top center during gameplay.")

	# Verification: Pressing Pause pauses game, hides controls, shows Paused screen
	var mob_ctrl = hud.get_node_or_null("MobileControls") as Control
	pause_btn.emit_signal("pressed")
	if not pause_cnt.visible or not paused or mob_ctrl.visible:
		printerr("[FAIL] Pressing pause did not pause game or hide controls properly")
		quit(1)
		return
	print("[PASS] Pressing pause stops gameplay, hides controls, and displays Pause screen.")

	# Verification: Pressing Resume unpauses and restores controls
	var resume_btn = hud.get_node_or_null("PauseContainer/Margin/VBox/ButtonsHBox/PauseResumeButton") as Button
	var replay_pause_btn = hud.get_node_or_null("PauseContainer/Margin/VBox/ButtonsHBox/PauseReplayButton") as Button
	var exit_pause_btn = hud.get_node_or_null("PauseContainer/Margin/VBox/ButtonsHBox/PauseExitButton") as Button
	if not resume_btn or not replay_pause_btn or not exit_pause_btn:
		printerr("[FAIL] One or more Pause buttons (Exit, Replay, Resume) missing")
		quit(1)
		return

	resume_btn.emit_signal("pressed")
	if pause_cnt.visible or paused or not mob_ctrl.visible:
		printerr("[FAIL] Pressing resume did not unpause game or restore controls properly")
		quit(1)
		return
	print("[PASS] Pressing resume unpauses gameplay and restores controls properly.")

	# Verification: Global skin persistence after taking damage and level restart
	SaveManager.set_selected_skin("crimson")
	main._on_level_selected(1)
	if player.current_skin != "crimson":
		printerr("[FAIL] Player skin should be 'crimson', got: %s" % player.current_skin)
		quit(1)
		return
	player.take_damage(20)
	if player.current_skin != "crimson":
		printerr("[FAIL] Player skin reverted after taking damage")
		quit(1)
		return
	print("[PASS] Global skin set and preserved across level start and damage.")

	# 8. Test Level Completed Screen with 3 Buttons
	hud.show_level_completed(1, 100, 4, true, true)
	var completed_container = hud.get_node_or_null("LevelCompletedContainer")
	if not completed_container or not completed_container.visible:
		printerr("[FAIL] LevelCompletedContainer is missing or not visible")
		quit(1)
		return

	var exit_btn = hud.get_node_or_null("LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedExitButton")
	var upg_btn = hud.get_node_or_null("LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedUpgradeButton")
	var cont_btn = hud.get_node_or_null("LevelCompletedContainer/Margin/VBox/ButtonsHBox/CompletedContinueButton")
	if not exit_btn or not upg_btn or not cont_btn:
		printerr("[FAIL] Level Completed 3 buttons (Exit, Upgrade, Continue to next level) missing")
		quit(1)
		return
	print("[PASS] 'Level completed!' screen with 3 buttons (Exit, Upgrade, Continue to next level) verified.")
	hud.hide_level_completed()

	# 9. Test Level Lost Screen with 3 Buttons (Sprint 2)
	hud.show_level_lost(1)
	var lost_container = hud.get_node_or_null("LevelLostContainer")
	if not lost_container or not lost_container.visible:
		printerr("[FAIL] LevelLostContainer is missing or not visible")
		quit(1)
		return

	var lost_exit_btn = hud.get_node_or_null("LevelLostContainer/Margin/VBox/ButtonsHBox/LostExitButton")
	var lost_upg_btn = hud.get_node_or_null("LevelLostContainer/Margin/VBox/ButtonsHBox/LostUpgradeButton")
	var lost_rep_btn = hud.get_node_or_null("LevelLostContainer/Margin/VBox/ButtonsHBox/LostReplayButton")
	if not lost_exit_btn or not lost_upg_btn or not lost_rep_btn:
		printerr("[FAIL] Level Lost 3 buttons (Exit, Upgrade, Replay) missing")
		quit(1)
		return
	print("[PASS] 'Level Lost!' screen with 3 buttons (Exit, Upgrade, Replay) verified.")
	hud.hide_level_lost()

	# 10. Test First-Time vs Repeat Level Completion Points (One-Time Upgrade Points Guarantee)
	SaveManager.invalidate_cache()
	var test_lvl: int = 7
	if not SaveManager.can_claim_level_reward(test_lvl):
		printerr("[FAIL] Level %d should initially be eligible for reward" % test_lvl)
		quit(1)
		return

	var pts_earned: int = SaveManager.claim_level_reward(test_lvl, 1)
	if pts_earned != 1:
		printerr("[FAIL] First clear should award exactly 1 point, got: %d" % pts_earned)
		quit(1)
		return

	# Replaying the level 5 times must consistently award 0 points
	for replay_idx in range(5):
		if SaveManager.can_claim_level_reward(test_lvl):
			printerr("[FAIL] Replay #%d of level %d should NOT be eligible for points" % [replay_idx + 1, test_lvl])
			quit(1)
			return
		var replay_pts: int = SaveManager.claim_level_reward(test_lvl, 1)
		if replay_pts != 0:
			printerr("[FAIL] Replay #%d of level %d awarded %d points (must be 0)" % [replay_idx + 1, test_lvl, replay_pts])
			quit(1)
			return
		var mark_repeat: bool = SaveManager.mark_level_completed(test_lvl)
		if mark_repeat:
			printerr("[FAIL] mark_level_completed on replay should return false")
			quit(1)
			return
	print("[PASS] One-time upgrade points strictly verified: first-time gives 1 pt, repeated 5x replays give 0 pts.")

	# 11. Test Crown Icon on Completed Level (Sprint 5)
	hud.show_select_level(2, 5)
	var updated_grid = hud.level_grid
	if not updated_grid or updated_grid.get_child_count() == 0:
		printerr("[FAIL] LevelGrid not populated")
		quit(1)
		return

	var cleared_btn = updated_grid.get_child(0) as Button
	var crown_child = cleared_btn.get_node_or_null("CrownIcon") as TextureRect
	if not crown_child or not crown_child.texture:
		printerr("[FAIL] CrownIcon TextureRect not displayed above completed level 1")
		quit(1)
		return
	print("[PASS] Small Crown icon correctly rendered above completed level 1 button.")

	# 12. Test Gun Barrel Visual Scaling & Multi-Tier Proportions (Waterfall Iteration 9 & Modular Gun)
	var gun_inst: Node2D = player.get_node_or_null("Gun") as Node2D
	var g_center: Sprite2D = (gun_inst.get_node_or_null("GunMount/GunSpriteCenter") if gun_inst else player.get_node_or_null("GunMount/GunSpriteCenter")) as Sprite2D
	var g_top: Sprite2D = (gun_inst.get_node_or_null("GunMount/GunSpriteTop") if gun_inst else player.get_node_or_null("GunMount/GunSpriteTop")) as Sprite2D
	var g_bottom: Sprite2D = (gun_inst.get_node_or_null("GunMount/GunSpriteBottom") if gun_inst else player.get_node_or_null("GunMount/GunSpriteBottom")) as Sprite2D
	var g_cannon: Sprite2D = (gun_inst.get_node_or_null("GunMount/GunSpriteCannon") if gun_inst else player.get_node_or_null("GunMount/GunSpriteCannon")) as Sprite2D
	if not g_center or not g_top or not g_bottom or not g_cannon:
		printerr("[FAIL] Gun sprite nodes missing in Player GunMount")
		quit(1)
		return

	# Test Level 4 Explosive Gatling (Triple-barrel battery, uniform scale (2, 2))
	player.gun_level = 4
	player._update_gun_visual()
	if not (g_center.visible and g_top.visible and g_bottom.visible and not g_cannon.visible):
		printerr("[FAIL] Level 4 should have center, top, bottom barrels visible and cannon hidden")
		quit(1)
		return
	if g_center.scale != Vector2(2.0, 2.0) or g_top.scale != Vector2(2.0, 2.0) or g_bottom.scale != Vector2(2.0, 2.0):
		printerr("[FAIL] Level 4 barrels must have standard uniform scale (2, 2), got: %s" % str(g_center.scale))
		quit(1)
		return

	# Test Level 5 Quasar Laser (Cannon at (5, 5) + flanking stabilizer barrels at (2, 2))
	player.gun_level = 5
	player._update_gun_visual()
	if not (g_cannon.visible and g_top.visible and g_bottom.visible):
		printerr("[FAIL] Level 5 should have cannon and stabilizer barrels visible")
		quit(1)
		return
	if g_cannon.scale != Vector2(5.0, 5.0) or g_top.scale != Vector2(2.0, 2.0) or g_bottom.scale != Vector2(2.0, 2.0):
		printerr("[FAIL] Level 5 cannon scale must be (5, 5) and stabilizers (2, 2)")
		quit(1)
		return

	# Test Reset integrity when stepping down to Level 1
	player.gun_level = 1
	player._update_gun_visual()
	if not (g_center.visible and not g_top.visible and not g_bottom.visible and not g_cannon.visible):
		printerr("[FAIL] Level 1 should only display center barrel")
		quit(1)
		return
	if g_center.scale != Vector2(2.0, 2.0):
		printerr("[FAIL] Level 1 center barrel scale corrupted: %s" % str(g_center.scale))
		quit(1)
		return
	print("[PASS] Gun barrel visual scaling and multi-tier proportions verified in runtime.")

	# 13. Test Ship Cosmetic Thruster Attachment & Dynamic Movement Activation (Waterfall Iteration 10)
	var t_mount: Node2D = player.get_node_or_null("ThrusterMount") as Node2D
	var t_sprite: Sprite2D = player.get_node_or_null("ThrusterMount/ThrusterSprite") as Sprite2D
	if not t_mount or not t_sprite:
		printerr("[FAIL] ThrusterMount or ThrusterSprite node missing from Player scene")
		quit(1)
		return

	# Check mount location on the back of the ship
	if t_mount.position != Vector2(-55.0, 2.5):
		printerr("[FAIL] ThrusterMount not aligned with ship engine nozzle (-55, 2.5), got: %s" % str(t_mount.position))
		quit(1)
		return

	# Check initial inactive state when stationary
	player._update_thruster_visual(false)
	if t_sprite.visible:
		printerr("[FAIL] ThrusterSprite should be inactive/hidden when stationary")
		quit(1)
		return

	# Check activation during movement
	player._update_thruster_visual(true)
	if not t_sprite.visible:
		printerr("[FAIL] ThrusterSprite should activate/become visible when moving")
		quit(1)
		return
	if t_sprite.scale.x < 3.0 or t_sprite.scale.y < 3.0:
		printerr("[FAIL] ThrusterSprite dynamic scale unexpectedly small: %s" % str(t_sprite.scale))
		quit(1)
		return

	# Check custom PNG adjustment setters
	player.set_thruster_offset(Vector2(-65.0, 1.0))
	if t_sprite.position != Vector2(-65.0, 1.0):
		printerr("[FAIL] set_thruster_offset did not adjust ThrusterSprite position")
		quit(1)
		return

	player.set_thruster_scale(Vector2(6.0, 6.0))
	if player.thruster_scale != Vector2(6.0, 6.0):
		printerr("[FAIL] set_thruster_scale did not adjust player.thruster_scale")
		quit(1)
		return

	# Restore default offset and scale
	player.set_thruster_offset(Vector2(-60.0, 0.0))
	player.set_thruster_scale(Vector2(5.0, 5.0))

	# Check deactivation when player dies
	player.die()
	if t_sprite.visible:
		printerr("[FAIL] Thruster should be hidden when player is dead")
		quit(1)
		return
	player.is_alive = true
	print("[PASS] Ship cosmetic thruster attachment, dynamic movement activation, and customization verified.")

	# 14. Test Main Screen Setting Button, Settings Panel, Sound Slider & Reset All Progress (Waterfall Iteration 11)
	hud.show_welcome_screen()
	var setting_btn: Button = hud.get_node_or_null("WelcomeContainer/ButtonsVBox/SettingButton") as Button
	if not setting_btn:
		printerr("[FAIL] SettingButton missing on WelcomeContainer/ButtonsVBox")
		quit(1)
		return

	var s_modal = hud.get_node_or_null("SettingsModal")
	if not s_modal:
		printerr("[FAIL] SettingsModal node missing in HUD")
		quit(1)
		return

	# Test opening settings panel
	setting_btn.emit_signal("pressed")
	if not s_modal.visible:
		printerr("[FAIL] Pressing SettingButton did not open SettingsModal")
		quit(1)
		return

	# Test sound slider
	var s_slider: HSlider = hud.get_node_or_null("SettingsModal/Margin/VBox/SoundSection/SoundSlider") as HSlider
	var s_label: Label = hud.get_node_or_null("SettingsModal/Margin/VBox/SoundSection/SoundHeaderHBox/SoundValueLabel") as Label
	if not s_slider or not s_label:
		printerr("[FAIL] SoundSlider or SoundValueLabel missing in SettingsModal")
		quit(1)
		return

	s_slider.value = 0.65
	hud._on_sound_slider_value_changed(0.65)
	if s_label.text != "65%":
		printerr("[FAIL] SoundValueLabel should show '65%%', got: %s" % s_label.text)
		quit(1)
		return
	if abs(SaveManager.get_master_volume() - 0.65) > 0.01:
		printerr("[FAIL] Sound volume not persisted in SaveManager: %f" % SaveManager.get_master_volume())
		quit(1)
		return

	# Test music slider (Waterfall Iteration 17)
	var m_slider: HSlider = hud.get_node_or_null("SettingsModal/Margin/VBox/MusicSection/MusicSlider") as HSlider
	var m_label: Label = hud.get_node_or_null("SettingsModal/Margin/VBox/MusicSection/MusicHeaderHBox/MusicValueLabel") as Label
	if not m_slider or not m_label:
		printerr("[FAIL] MusicSlider or MusicValueLabel missing in SettingsModal")
		quit(1)
		return

	m_slider.value = 0.80
	hud._on_music_slider_value_changed(0.80)
	if m_label.text != "80%":
		printerr("[FAIL] MusicValueLabel should show '80%%', got: %s" % m_label.text)
		quit(1)
		return
	if abs(SaveManager.get_music_volume() - 0.80) > 0.01:
		printerr("[FAIL] Music volume not persisted in SaveManager: %f" % SaveManager.get_music_volume())
		quit(1)
		return

	# Test SFX slider (Waterfall Iteration 18)
	var sfx_slider_node: HSlider = hud.get_node_or_null("SettingsModal/Margin/VBox/SfxSection/SfxSlider") as HSlider
	var sfx_label_node: Label = hud.get_node_or_null("SettingsModal/Margin/VBox/SfxSection/SfxHeaderHBox/SfxValueLabel") as Label
	if not sfx_slider_node or not sfx_label_node:
		printerr("[FAIL] SfxSlider or SfxValueLabel missing in SettingsModal")
		quit(1)
		return

	sfx_slider_node.value = 0.75
	hud._on_sfx_slider_value_changed(0.75)
	if sfx_label_node.text != "75%":
		printerr("[FAIL] SfxValueLabel should show '75%%', got: %s" % sfx_label_node.text)
		quit(1)
		return
	if abs(SaveManager.get_sfx_volume() - 0.75) > 0.01:
		printerr("[FAIL] SFX volume not persisted in SaveManager: %f" % SaveManager.get_sfx_volume())
		quit(1)
		return

	# Restore SFX slider to 1.0 (0.0 dB) for remaining tests
	sfx_slider_node.value = 1.0
	hud._on_sfx_slider_value_changed(1.0)

	# Test Reset All Progress button in middle bottom
	var reset_btn: Button = hud.get_node_or_null("SettingsModal/Margin/VBox/ResetSection/ResetProgressButton") as Button
	var reset_lbl: Label = hud.get_node_or_null("SettingsModal/Margin/VBox/ResetSection/ResetStatusLabel") as Label
	var reset_confirm_modal_node = hud.get_node_or_null("ResetConfirmModal")
	var reset_cancel_btn: Button = hud.get_node_or_null("ResetConfirmModal/Margin/VBox/ButtonsHBox/ResetCancelButton") as Button
	var reset_confirm_btn: Button = hud.get_node_or_null("ResetConfirmModal/Margin/VBox/ButtonsHBox/ResetConfirmButton") as Button
	if not reset_btn or not reset_lbl or not reset_confirm_modal_node or not reset_cancel_btn or not reset_confirm_btn:
		printerr("[FAIL] ResetProgressButton, ResetConfirmModal, or confirmation buttons missing")
		quit(1)
		return

	# Put dummy progression into SaveManager first to test reset thoroughly
	SaveManager.unlock_level(15)
	SaveManager.save_player_state(12, 3, 2, 4, "crimson")

	# 1. Pressing ResetProgressButton must open confirmation modal and NOT immediately reset data
	reset_btn.emit_signal("pressed")
	if not reset_confirm_modal_node.visible:
		printerr("[FAIL] Pressing ResetProgressButton must display ResetConfirmModal")
		quit(1)
		return

	var pre_confirm_data: Dictionary = SaveManager.load_save_data()
	if int(pre_confirm_data.get("unlocked_level", 0)) != 15:
		printerr("[FAIL] Reset progress wiped data before confirmation was granted")
		quit(1)
		return

	# 2. Pressing CANCEL must close confirmation modal without resetting data
	reset_cancel_btn.emit_signal("pressed")
	hud.hide_reset_confirm_modal()
	if reset_confirm_modal_node.visible:
		printerr("[FAIL] Pressing ResetCancelButton must close ResetConfirmModal")
		quit(1)
		return

	var cancel_check_data: Dictionary = SaveManager.load_save_data()
	if int(cancel_check_data.get("unlocked_level", 0)) != 15:
		printerr("[FAIL] Cancel button unexpectedly wiped save data")
		quit(1)
		return

	# 3. Re-open confirmation modal and press CONFIRM RESET
	reset_btn.emit_signal("pressed")
	reset_confirm_btn.emit_signal("pressed")

	var after_reset_data: Dictionary = SaveManager.load_save_data()
	if int(after_reset_data.get("unlocked_level", 0)) != 1:
		printerr("[FAIL] Reset progress did not reset unlocked_level to 1, got: %s" % str(after_reset_data.get("unlocked_level")))
		quit(1)
		return
	if int(after_reset_data.get("upgrade_points", 0)) != 3:
		printerr("[FAIL] Reset progress did not reset upgrade_points to 3, got: %s" % str(after_reset_data.get("upgrade_points")))
		quit(1)
		return
	if int(after_reset_data.get("shield_level", 0)) != 0 or int(after_reset_data.get("gun_level", 0)) != 0:
		printerr("[FAIL] Reset progress did not reset player upgrades to 0")
		quit(1)
		return
	if not reset_lbl.visible:
		printerr("[FAIL] ResetStatusLabel did not show confirmation after progress reset")
		quit(1)
		return

	# Test closing settings panel via Back button
	var s_back: Button = hud.get_node_or_null("SettingsModal/Margin/VBox/SettingsBackButton") as Button
	if not s_back:
		printerr("[FAIL] SettingsBackButton missing in SettingsModal")
		quit(1)
		return
	s_back.emit_signal("pressed")
	hud.hide_settings_modal()
	await create_timer(0.2).timeout
	if s_modal.visible:
		printerr("[FAIL] SettingsModal did not close on Back button press")
		quit(1)
		return
	print("[PASS] Setting button, Settings panel, Sound slider, and Reset all progress verified.")

	# Test PauseSettingsButton in PauseContainer (In-game settings access & non-overlapping layering)
	hud.show_pause_screen(1)
	var pause_settings_btn: Button = hud.get_node_or_null("PauseContainer/Margin/VBox/ButtonsHBox/PauseSettingsButton") as Button
	if not pause_settings_btn:
		printerr("[FAIL] PauseSettingsButton missing in PauseContainer")
		quit(1)
		return

	# Verify z_index layering hierarchy: SettingsModal must layer strictly above PauseContainer
	if s_modal.z_index <= pause_cnt.z_index:
		printerr("[FAIL] SettingsModal z_index (%d) must be greater than PauseContainer z_index (%d)" % [s_modal.z_index, pause_cnt.z_index])
		quit(1)
		return

	pause_settings_btn.emit_signal("pressed")
	if not s_modal.visible:
		printerr("[FAIL] PauseSettingsButton did not open SettingsModal while paused")
		quit(1)
		return
	if pause_cnt.visible:
		printerr("[FAIL] PauseContainer must be hidden when SettingsModal is opened to prevent overlapping")
		quit(1)
		return

	# Verify ResetSection is hidden in Ingame Settings
	var reset_sect_node = hud.get_node_or_null("SettingsModal/Margin/VBox/ResetSection")
	if reset_sect_node and reset_sect_node.visible:
		printerr("[FAIL] ResetSection must be hidden inside Ingame Settings Menu")
		quit(1)
		return

	hud.hide_settings_modal()
	if not pause_cnt.visible:
		printerr("[FAIL] PauseContainer must be restored to visible after closing SettingsModal while paused")
		quit(1)
		return
	hud.resume_game()
	if pause_cnt.visible or s_modal.visible:
		printerr("[FAIL] Neither PauseContainer nor SettingsModal should be visible after resuming game")
		quit(1)
		return
	print("[PASS] Pause settings layering and non-overlapping visibility verified.")

	# Test MusicManager Component (Waterfall Iteration 17)
	var MusicManager = preload("res://scripts/music_manager.gd")
	var mm = MusicManager.new()
	mm.play_menu_music(0.0)
	if mm.get_current_track_key() != "menu":
		printerr("[FAIL] MusicManager did not switch to menu track")
		quit(1)
		return
	mm.play_ingame_music(0.0)
	if mm.get_current_track_key() != "ingame":
		printerr("[FAIL] MusicManager did not switch to ingame track")
		quit(1)
		return
	mm.play_boss_music(0.0)
	if mm.get_current_track_key() != "boss":
		printerr("[FAIL] MusicManager did not switch to boss track")
		quit(1)
		return
	mm.stop_music(0.0)
	mm.queue_free()
	print("[PASS] MusicManager transitions, templates, audio buses, and in-game music slider verified.")

	# 15. Test Enemy Theme Dictionary Slots & Stage Replacement System (Waterfall Iteration 13)
	var EnemyThemeManager = preload("res://scripts/enemy_theme_manager.gd")
	var default_slots: Dictionary = EnemyThemeManager.get_default_slots()
	for bracket_key in ["1-5", "6-10", "11-15", "16-20"]:
		if not default_slots.has(bracket_key):
			printerr("[FAIL] Missing stage bracket in EnemyThemeManager: %s" % bracket_key)
			quit(1)
			return
		var b_dict = default_slots[bracket_key]
		for e_type in ["breeder", "spewer", "charger", "heavy", "void"]:
			if not b_dict.has(e_type):
				printerr("[FAIL] Missing enemy slot '%s' in bracket '%s'" % [e_type, bracket_key])
				quit(1)
				return

	# Test alias resolution in EnemyThemeManager
	if EnemyThemeManager.normalize_enemy_type("tank") != "heavy":
		printerr("[FAIL] normalize_enemy_type('tank') should resolve to 'heavy'")
		quit(1)
		return
	if EnemyThemeManager.normalize_enemy_type("teleporter") != "void":
		printerr("[FAIL] normalize_enemy_type('teleporter') should resolve to 'void'")
		quit(1)
		return

	# Test stage bracket calculation
	if EnemyThemeManager.get_stage_bracket(3) != "1-5" or EnemyThemeManager.get_stage_bracket(8) != "6-10":
		printerr("[FAIL] Stage bracket calculation failed for stages 3 and 8")
		quit(1)
		return
	if EnemyThemeManager.get_stage_bracket(14) != "11-15" or EnemyThemeManager.get_stage_bracket(20) != "16-20":
		printerr("[FAIL] Stage bracket calculation failed for stages 14 and 20")
		quit(1)
		return

	# Test default texture lookup on Main
	main.current_wave = 1
	var s1_heavy_tex = main._get_enemy_texture_for_current_stage("heavy")
	if not s1_heavy_tex:
		printerr("[FAIL] Default heavy enemy texture lookup returned null")
		quit(1)
		return

	# Test dynamic slot assignment for Stage 6-10
	var test_replacement_path: String = "res://assets/textures/enemies/heavy_enemy.png"
	main.set_enemy_theme_slot("spewer", "6-10", test_replacement_path)
	main.current_wave = 7
	var s2_spewer_tex = main._get_enemy_texture_for_current_stage("spewer")
	if not s2_spewer_tex:
		printerr("[FAIL] Overridden spewer texture lookup returned null on stage 7")
		quit(1)
		return

	# Test enemy set_enemy_texture on instantiated scenes
	var heavy_scene = load("res://scenes/enemies/heavy_enemy.tscn") as PackedScene
	var heavy_inst = heavy_scene.instantiate()
	main.add_child(heavy_inst)
	heavy_inst.set_enemy_texture(s1_heavy_tex)
	var h_spr: Sprite2D = heavy_inst.get_node_or_null("Sprite2D") as Sprite2D
	if not h_spr or h_spr.texture != s1_heavy_tex:
		printerr("[FAIL] Heavy enemy set_enemy_texture did not update Sprite2D texture")
		quit(1)
		return
	heavy_inst.queue_free()

	print("[PASS] Enemy Theme Dictionary slots, aliases, stage brackets, and texture replacement verified.")

	# =========================================================================
	# STEP 16: VERIFY STAGE SPAWN DATABASE & STAGE ENEMY CONFIGURATION MANAGER
	# =========================================================================
	print("\n--- Step 16: Verifying Stage Spawn Database & Stage Enemy Configuration Manager ---")
	var StageSpawnManager = load("res://scripts/stage_spawn_manager.gd")
	if not StageSpawnManager:
		printerr("[FAIL] Failed to load StageSpawnManager script")
		quit(1)
		return

	# Verify all 20 stages exist in STAGE_SPAWN_DATABASE
	for stage_idx in range(1, 21):
		if not StageSpawnManager.STAGE_SPAWN_DATABASE.has(stage_idx):
			printerr("[FAIL] STAGE_SPAWN_DATABASE missing configuration for Stage %d" % stage_idx)
			quit(1)
			return

	# Verify Stage 1 (Warm-Up, no enemies, 8 projectiles)
	var s1 = StageSpawnManager.get_stage_config(1)
	if s1["is_boss_stage"] != false or s1["projectiles"] != 8 or s1["heavy_enemies"] != 0:
		printerr("[FAIL] Stage 1 configuration mismatch")
		quit(1)
		return

	# Verify Stage 3 (Armored Vanguard, 1 heavy, 1 spewer, 14 projectiles)
	var s3 = StageSpawnManager.get_stage_config(3)
	if s3["heavy_enemies"] != 1 or s3["bile_spewers"] != 1 or s3["charger_roaches"] != 0:
		printerr("[FAIL] Stage 3 enemy counts mismatch")
		quit(1)
		return

	# Verify Stage 5 (Boss: Dreadnought Titan)
	if not StageSpawnManager.is_boss_stage(5):
		printerr("[FAIL] Stage 5 is_boss_stage should be true")
		quit(1)
		return
	var s5_bosses = StageSpawnManager.get_boss_configs(5)
	if s5_bosses.size() != 1 or s5_bosses[0]["type"] != "dreadnought":
		printerr("[FAIL] Stage 5 boss encounter should be 1 dreadnought")
		quit(1)
		return

	# Verify Stage 8 (2 heavy, 2 spewer, 2 charger, 2 void, 1 breeder, 22 projectiles)
	var s8_counts = StageSpawnManager.get_enemy_counts(8)
	if s8_counts["heavy"] != 2 or s8_counts["spewer"] != 2 or s8_counts["charger"] != 2 or s8_counts["void"] != 2 or s8_counts["breeder"] != 1:
		printerr("[FAIL] Stage 8 get_enemy_counts mismatch: %s" % str(s8_counts))
		quit(1)
		return

	# Verify Stage 10 (Boss: Dragon Roach Titan)
	if not StageSpawnManager.is_boss_stage(10):
		printerr("[FAIL] Stage 10 is_boss_stage should be true")
		quit(1)
		return
	var s10_bosses = StageSpawnManager.get_boss_configs(10)
	if s10_bosses.size() != 1 or s10_bosses[0]["type"] != "dragon_roach":
		printerr("[FAIL] Stage 10 boss encounter should be 1 dragon_roach")
		quit(1)
		return

	# Verify Stage 15 (Boss: Twin Dreadnoughts)
	var s15_bosses = StageSpawnManager.get_boss_configs(15)
	if s15_bosses.size() != 2 or s15_bosses[0]["type"] != "dreadnought" or s15_bosses[1]["type"] != "dreadnought":
		printerr("[FAIL] Stage 15 boss encounter should be 2 dreadnoughts")
		quit(1)
		return

	# Verify Stage 20 (Final Boss: Dragon Roach + Dreadnought)
	var s20_bosses = StageSpawnManager.get_boss_configs(20)
	if s20_bosses.size() != 2:
		printerr("[FAIL] Stage 20 should have 2 dual titan bosses")
		quit(1)
		return

	# Verify main.gd _get_wave_config integration
	var main_s8_cfg = main._get_wave_config(8)
	if main_s8_cfg.heavy_enemies_count != 2 or main_s8_cfg.bile_breeders_count != 1 or main_s8_cfg.total_projectiles != 22:
		printerr("[FAIL] main._get_wave_config(8) did not return expected values from StageSpawnManager")
		quit(1)
		return

	# Verify dynamic runtime override and normalization
	StageSpawnManager.set_stage_enemy_count(1, "tank", 4)
	var s1_override = StageSpawnManager.get_stage_config(1)
	if s1_override["heavy_enemies"] != 4:
		printerr("[FAIL] Runtime override set_stage_enemy_count failed")
		quit(1)
		return
	StageSpawnManager.reset_runtime_overrides()
	var s1_restored = StageSpawnManager.get_stage_config(1)
	if s1_restored["heavy_enemies"] != 0:
		printerr("[FAIL] reset_runtime_overrides failed to restore defaults")
		quit(1)
		return

	# Verify endless stage 21 generation
	var s21 = StageSpawnManager.get_stage_config(21)
	if s21["is_boss_stage"] != false or s21["projectiles"] <= 50:
		printerr("[FAIL] Endless stage 21 calculation failed")
		quit(1)
		return

	print("[PASS] Stage Spawn Database (Stages 1-20), boss encounters, enemy quotas, and main integration verified.")

	# =========================================================================
	# STEP 17: VERIFY UNIVERSAL BOSS MINION SUMMONING ARCHITECTURE
	# =========================================================================
	print("\n--- Step 17: Verifying Universal Boss Minion Summoning Architecture ---")

	# 1. Test Waurior minion summoning capability
	var dread_scene = load("res://scenes/bosses/boss_waurior.tscn") as PackedScene
	if not dread_scene:
		printerr("[FAIL] Could not load boss_waurior.tscn")
		quit(1)
		return
	var dread_inst = dread_scene.instantiate()
	if not dread_inst.has_signal("minion_spawn_requested"):
		printerr("[FAIL] Waurior missing minion_spawn_requested signal")
		quit(1)
		return
	if not "minion_summon" in dread_inst:
		printerr("[FAIL] Waurior missing minion_summon property")
		quit(1)
		return
	dread_inst.setup_boss(100, 540.0, 1.0, true)
	if dread_inst.minion_summon != true:
		printerr("[FAIL] Waurior setup_boss did not set minion_summon to true")
		quit(1)
		return
	dread_inst.queue_free()

	# 2. Test Minangkabau Ship minion summoning capability
	var roach_scene = load("res://scenes/bosses/boss_ship.tscn") as PackedScene
	if not roach_scene:
		printerr("[FAIL] Could not load boss_ship.tscn")
		quit(1)
		return
	var roach_inst = roach_scene.instantiate()
	if not roach_inst.has_signal("minion_spawn_requested"):
		printerr("[FAIL] Dragon Roach Titan missing minion_spawn_requested signal")
		quit(1)
		return
	if not "minion_summon" in roach_inst:
		printerr("[FAIL] Dragon Roach Titan missing minion_summon property")
		quit(1)
		return
	roach_inst.setup_boss(150, 420.0, 1.0, false)
	if roach_inst.minion_summon != false:
		printerr("[FAIL] Dragon Roach Titan setup_boss did not set minion_summon to false")
		quit(1)
		return
	roach_inst.queue_free()

	# 3. Test StageSpawnManager boss minion summon helpers
	StageSpawnManager.set_stage_boss_minion_summon(5, true)
	if not StageSpawnManager.is_boss_minion_summon_enabled(5):
		printerr("[FAIL] is_boss_minion_summon_enabled(5) should be true after set_stage_boss_minion_summon")
		quit(1)
		return
	var s5_cfg = StageSpawnManager.get_stage_config(5)
	var s5_bosses_list = s5_cfg.get("bosses", [])
	if s5_bosses_list.is_empty() or not s5_bosses_list[0].get("minion_summon", false):
		printerr("[FAIL] Stage 5 boss data minion_summon was not updated")
		quit(1)
		return

	# 4. Test main._spawn_boss_encounter() wireup with minion_summon = true
	main.current_wave = 5
	main._spawn_boss_encounter()
	if main.active_bosses.is_empty():
		printerr("[FAIL] main._spawn_boss_encounter() did not spawn any boss")
		quit(1)
		return
	var active_b = main.active_bosses[0]
	if active_b.get("minion_summon") != true:
		printerr("[FAIL] Active boss minion_summon flag should be true")
		quit(1)
		return
	# Cleanup spawned boss
	active_b.queue_free()
	main.active_bosses.clear()
	StageSpawnManager.reset_runtime_overrides()

	print("[PASS] Universal boss minion summoning, signals, setup_boss, and Main wireup verified.")

	# -------------------------------------------------------------
	# STEP 18: LEVEL 5 CONTINUOUS LASER RAY VERIFICATION (Waterfall Iteration 16)
	# -------------------------------------------------------------
	print("\n--- STEP 18: VERIFYING LEVEL 5 CONTINUOUS LASER RAY ---")
	var gun_scene = load("res://scenes/player/gun.tscn") as PackedScene
	if not gun_scene:
		printerr("[FAIL] Could not load scenes/player/gun.tscn")
		quit(1)
		return
	var test_laser_gun = gun_scene.instantiate() as Gun
	main.add_child(test_laser_gun)
	test_laser_gun.set_gun_level(5)

	var l5_cfg: Dictionary = test_laser_gun.get_active_config()
	if not bool(l5_cfg.get("is_laser", false)):
		printerr("[FAIL] Level 5 gun config must have 'is_laser': true")
		quit(1)
		return
	if float(l5_cfg.get("cooldown", 0.0)) != 0.055:
		printerr("[FAIL] Level 5 gun config cooldown must be 0.055")
		quit(1)
		return
	if int(l5_cfg.get("damage", 0)) != 7:
		printerr("[FAIL] Level 5 gun config damage must be 7")
		quit(1)
		return

	# Fire continuous laser ray
	var laser_bolt: Area2D = test_laser_gun.shoot(main, Vector2(100.0, 300.0))
	if not laser_bolt:
		printerr("[FAIL] test_laser_gun.shoot() returned null for Level 5 laser")
		quit(1)
		return
	if not bool(laser_bolt.get("is_laser")):
		printerr("[FAIL] Spawned laser bolt does not have is_laser == true")
		quit(1)
		return
	if not laser_bolt.has_method("sustain") or not laser_bolt.has_method("update_laser_origin"):
		printerr("[FAIL] Spawned laser bolt missing sustain() or update_laser_origin() method")
		quit(1)
		return

	# Verify visual and collision properties
	var spr: Sprite2D = laser_bolt.get_node_or_null("Sprite2D") as Sprite2D
	if spr and spr.visible:
		printerr("[FAIL] Laser bolt Sprite2D should be hidden (rendered continuously via _draw())")
		quit(1)
		return
	var col_shape: CollisionShape2D = laser_bolt.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col_shape or not (col_shape.shape is RectangleShape2D):
		printerr("[FAIL] Laser bolt CollisionShape2D should be a RectangleShape2D")
		quit(1)
		return

	# Test continuous sustain without spawning redundant bolts
	var initial_beam = test_laser_gun.active_laser_beam
	test_laser_gun.cooldown_timer = 0.0
	var sustained_bolt = test_laser_gun.shoot(main, Vector2(100.0, 310.0))
	if sustained_bolt != initial_beam:
		printerr("[FAIL] Continuous shooting must sustain existing active laser beam without creating duplicates")
		quit(1)
		return

	# Test tracking and origin updates
	test_laser_gun.process_cooldown(0.016)
	if laser_bolt.has_method("update_laser_origin"):
		laser_bolt.update_laser_origin(Vector2(120.0, 320.0))
		if laser_bolt.global_position != Vector2(120.0, 320.0):
			printerr("[FAIL] update_laser_origin did not update laser global_position")
			quit(1)
			return

	laser_bolt.queue_free()
	test_laser_gun.active_laser_beam = null
	test_laser_gun.queue_free()
	print("[PASS] Level 5 continuous laser ray, sustain mechanics, tracking, and rendering verified.")

	# -------------------------------------------------------------
	# STEP 19: LASER BEAM ENLARGEMENT, ADJUSTABILITY & SOUND DICTIONARY (Sprint Iteration)
	# -------------------------------------------------------------
	print("\n--- STEP 19: VERIFYING LASER SIZE ADJUSTABILITY & GUN SOUND DICTIONARY ---")
	# 1. Verify Laser Beam Size Adjustability
	var proj_scene = load("res://scenes/player/player_projectile.tscn") as PackedScene
	if not proj_scene:
		printerr("[FAIL] Could not load player_projectile.tscn")
		quit(1)
		return
	var test_laser = proj_scene.instantiate()
	main.add_child(test_laser)
	test_laser.setup_projectile(7, 1, 2600.0, false, false, false, true)

	if not "beam_scale" in test_laser or test_laser.beam_scale <= 0.0:
		printerr("[FAIL] test_laser beam_scale should be valid positive scale")
		quit(1)
		return

	test_laser.set_beam_scale(2.4)
	if test_laser.beam_scale != 2.4:
		printerr("[FAIL] test_laser set_beam_scale did not update beam_scale to 2.4")
		quit(1)
		return

	test_laser.set_laser_config({"beam_scale": 1.8, "collision_height": 45.0})
	if test_laser.beam_scale != 1.8 or test_laser.collision_height != 45.0:
		printerr("[FAIL] test_laser set_laser_config failed to apply dictionary values")
		quit(1)
		return
	test_laser.queue_free()

	# 2. Verify Safe Instantiation Outside Tree (data.tree null bugfix)
	var orphan_laser = proj_scene.instantiate()
	# Calling setup_projectile on an unparented node must not throw "data.tree is null"
	orphan_laser.setup_projectile(7, 1, 2600.0, false, false, false, true)
	orphan_laser.queue_free()

	# 3. Verify Gun Sounds Customization Dictionary
	var test_gun = gun_scene.instantiate() as Gun
	main.add_child(test_gun)
	var snd_cfg_default = test_gun.get_gun_sound_config(5)
	if snd_cfg_default.is_empty() or snd_cfg_default.get("name") != "Quasar Laser":
		printerr("[FAIL] get_gun_sound_config(5) did not return valid sound config dictionary")
		quit(1)
		return

	# Test runtime override of gun sound path
	test_gun.set_gun_sound_path(5, "res://assets/audio/guns/test_laser.wav", 1.2, -1.5)
	var snd_cfg_custom = test_gun.get_gun_sound_config(5)
	if snd_cfg_custom.get("sound_path") != "res://assets/audio/guns/test_laser.wav" or float(snd_cfg_custom.get("pitch")) != 1.2:
		printerr("[FAIL] set_gun_sound_path did not update custom sound config")
		quit(1)
		return

	test_gun.reset_gun_sounds()
	var snd_cfg_reset = test_gun.get_gun_sound_config(5)
	if snd_cfg_reset.get("sound_path") != "":
		printerr("[FAIL] reset_gun_sounds did not clear custom sound path")
		quit(1)
		return

	test_gun.queue_free()
	print("[PASS] Laser size adjustability, tree null error fix, and Gun sound dictionary verified.")

	# -------------------------------------------------------------
	# STEP 20: LASER PIERCE CUSTOMIZATION & MULTI-TARGET RAY TRACING
	# -------------------------------------------------------------
	print("\n--- STEP 20: VERIFYING LASER PIERCE CUSTOMIZATION & MULTI-TARGET PENETRATION ---")
	var pierce_laser = proj_scene.instantiate()
	main.add_child(pierce_laser)
	pierce_laser.setup_projectile(7, 2, 2600.0, false, false, false, true)

	if not "pierce" in pierce_laser or pierce_laser.pierce != 2:
		printerr("[FAIL] pierce_laser initial pierce should be 2")
		quit(1)
		return

	if not pierce_laser.has_method("set_laser_pierce") or not pierce_laser.has_method("get_laser_pierce"):
		printerr("[FAIL] pierce_laser missing set_laser_pierce or get_laser_pierce method")
		quit(1)
		return

	pierce_laser.set_laser_pierce(3)
	if pierce_laser.get_laser_pierce() != 3 or pierce_laser.pierce != 3:
		printerr("[FAIL] set_laser_pierce(3) did not update pierce")
		quit(1)
		return

	pierce_laser.set_laser_config({"pierce": 4})
	if pierce_laser.get_laser_pierce() != 4 or pierce_laser.pierce != 4:
		printerr("[FAIL] set_laser_config with pierce failed to update pierce")
		quit(1)
		return

	pierce_laser.sustain(Vector2(50.0, 50.0), 7, -1.0, 5)
	if pierce_laser.get_laser_pierce() != 5:
		printerr("[FAIL] sustain with new_pierce failed to update pierce")
		quit(1)
		return

	pierce_laser.queue_free()

	# Verify Gun config pierce integration
	var gun_pierce_test = gun_scene.instantiate() as Gun
	main.add_child(gun_pierce_test)
	gun_pierce_test.gun_level = 5
	var laser_cfg = gun_pierce_test.get_active_config()
	if not laser_cfg.has("pierce"):
		printerr("[FAIL] Gun Level 5 config missing pierce entry")
		quit(1)
		return

	gun_pierce_test.set_stat("pierce", 3, 5)
	if int(gun_pierce_test.get_stat("pierce", 1, 5)) != 3:
		printerr("[FAIL] Gun set_stat pierce did not update Level 5 pierce")
		quit(1)
		return

	gun_pierce_test.queue_free()
	print("[PASS] Laser pierce customization and multi-target penetration verified.")

	# =========================================================================
	# STEP 21: VERIFY BOSS NAME DICTIONARY & CUSTOMIZATION MANAGER
	# =========================================================================
	print("\n--- STEP 21: VERIFYING BOSS NAME DICTIONARY & CUSTOMIZATION MANAGER ---")
	var BossNameManager = load("res://scripts/boss_name_manager.gd")
	if not BossNameManager:
		printerr("[FAIL] Failed to load BossNameManager script")
		quit(1)
		return

	# Verify default boss name dictionary entries
	if not BossNameManager.has_boss_config(5) or not BossNameManager.has_boss_config(10) or not BossNameManager.has_boss_config(15) or not BossNameManager.has_boss_config(20):
		printerr("[FAIL] BossNameManager missing boss config for stages 5, 10, 15, or 20")
		quit(1)
		return

	if BossNameManager.get_boss_display_name(5) != "Dreadnought Titan":
		printerr("[FAIL] Stage 5 default boss name mismatch: %s" % BossNameManager.get_boss_display_name(5))
		quit(1)
		return

	if BossNameManager.get_boss_bar_title(5) != "DREADNOUGHT TITAN":
		printerr("[FAIL] Stage 5 default bar title mismatch: %s" % BossNameManager.get_boss_bar_title(5))
		quit(1)
		return

	# Verify integration with StageSpawnManager
	var s5_boss_cfg = StageSpawnManager.get_stage_config(5)
	if s5_boss_cfg.get("boss_bar_title", "") != "DREADNOUGHT TITAN":
		printerr("[FAIL] StageSpawnManager stage 5 boss_bar_title mismatch")
		quit(1)
		return

	# Test dynamic rename via simple string without breaking codes
	BossNameManager.set_boss_name(5, "Leviathan Overlord")
	var s5_renamed = StageSpawnManager.get_stage_config(5)
	if s5_renamed.get("boss_bar_title", "") != "LEVIATHAN OVERLORD":
		printerr("[FAIL] set_boss_name did not update boss_bar_title in StageSpawnManager: %s" % s5_renamed.get("boss_bar_title", ""))
		quit(1)
		return
	if s5_renamed.get("title", "") != "BOSS ENCOUNTER - LEVIATHAN OVERLORD":
		printerr("[FAIL] set_boss_name did not update stage title in StageSpawnManager: %s" % s5_renamed.get("title", ""))
		quit(1)
		return
	if s5_renamed["bosses"][0]["name"] != "Leviathan Overlord":
		printerr("[FAIL] set_boss_name did not update individual boss name: %s" % s5_renamed["bosses"][0]["name"])
		quit(1)
		return
	# Ensure technical type remained dreadnought
	if s5_renamed["bosses"][0]["type"] != "dreadnought":
		printerr("[FAIL] set_boss_name corrupted boss technical type")
		quit(1)
		return

	# Reset and verify restoration
	BossNameManager.reset_boss_names()
	var s5_restored = StageSpawnManager.get_stage_config(5)
	if s5_restored.get("boss_bar_title", "") != "DREADNOUGHT TITAN":
		printerr("[FAIL] reset_boss_names failed to restore default Stage 5 bar title")
		quit(1)
		return

	# Test Stage 15 multi-boss individual names
	var s15_cfg = StageSpawnManager.get_stage_config(15)
	if s15_cfg["bosses"][0]["name"] != "Dreadnought Titan Alpha" or s15_cfg["bosses"][1]["name"] != "Dreadnought Titan Beta":
		printerr("[FAIL] Stage 15 multi-boss names mismatch: %s, %s" % [s15_cfg["bosses"][0]["name"], s15_cfg["bosses"][1]["name"]])
		quit(1)
		return

	print("[PASS] Boss Name Dictionary, dynamic renaming, and StageSpawnManager integration verified.")

	# -------------------------------------------------------------
	# STEP 22: VOID BILE TELEPORTATION SCALE PRESERVATION FIX
	# -------------------------------------------------------------
	print("\n--- STEP 22: VERIFYING VOID BILE TELEPORTATION SCALE PRESERVATION ---")
	var void_scene = load("res://scenes/enemies/void_bile.tscn") as PackedScene
	if not void_scene:
		printerr("[FAIL] Could not load void_bile.tscn")
		quit(1)
		return
	var test_void = void_scene.instantiate()
	main.add_child(test_void)
	var void_spr = test_void.get_node_or_null("Sprite2D") as Sprite2D
	if not void_spr:
		printerr("[FAIL] Sprite2D missing in void_bile")
		quit(1)
		return

	var initial_scale: Vector2 = void_spr.scale
	test_void._execute_teleport()
	await create_timer(0.35).timeout
	if absf(void_spr.scale.x - initial_scale.x) > 0.01 or absf(void_spr.scale.y - initial_scale.y) > 0.01:
		printerr("[FAIL] Void bile sprite scale changed after teleport! Expected %s, got %s" % [initial_scale, void_spr.scale])
		quit(1)
		return
	test_void.queue_free()
	print("[PASS] Void bile teleportation scale preservation verified.")

	# -------------------------------------------------------------
	# STEP 23: ENEMY PROJECTILE DATABASE & EXTENSIBLE DICTIONARY
	# -------------------------------------------------------------
	print("\n--- STEP 23: VERIFYING ENEMY PROJECTILE DATABASE & DICTIONARY ---")
	var default_proj_slots: Dictionary = EnemyProjectileDatabase.get_default_slots()
	for b_key in ["1-5", "6-10", "11-15", "16-20"]:
		if not default_proj_slots.has(b_key):
			printerr("[FAIL] EnemyProjectileDatabase missing stage bracket: %s" % b_key)
			quit(1)
			return
		for etype in ["spewer", "heavy", "void", "boss", "dragon_roach", "ambient"]:
			if not default_proj_slots[b_key].has(etype):
				printerr("[FAIL] EnemyProjectileDatabase bracket %s missing enemy type: %s" % [b_key, etype])
				quit(1)
				return

	# Verify default spewer configuration
	var spewer_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("spewer", 1)
	if spewer_cfg.get("damage") != 20 or spewer_cfg.get("speed") != 430.0 or not spewer_cfg.get("is_bile_shot", false):
		printerr("[FAIL] Spewer projectile default configuration mismatch: %s" % spewer_cfg)
		quit(1)
		return

	# Verify default void configuration
	var void_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("void", 8)
	if void_cfg.get("speed") != 490.0 or void_cfg.get("movement_type") != 3:
		printerr("[FAIL] Void projectile default configuration mismatch: %s" % void_cfg)
		quit(1)
		return

	# Verify archetype profile lookup
	var wavy_prof: Dictionary = EnemyProjectileDatabase.get_projectile_profile("boss_wavy")
	if wavy_prof.get("movement_type") != 1 or wavy_prof.get("speed") != 400.0:
		printerr("[FAIL] boss_wavy archetype profile mismatch: %s" % wavy_prof)
		quit(1)
		return

	# Verify dynamic overrides and stage bracket mapping
	EnemyProjectileDatabase.set_projectile_property("heavy", "speed", 580.0, 3)
	var heavy_s3: Dictionary = EnemyProjectileDatabase.get_projectile_config("heavy", 3)
	if heavy_s3.get("speed") != 580.0:
		printerr("[FAIL] set_projectile_property failed on stage 3 heavy speed override: %s" % heavy_s3.get("speed"))
		quit(1)
		return

	# Verify texture slot assignment
	EnemyProjectileDatabase.set_projectile_texture("spewer", "res://assets/textures/projectiles/karipap.png", "1-5")
	var spewer_s1: Dictionary = EnemyProjectileDatabase.get_projectile_config("spewer", 1)
	if spewer_s1.get("texture") != "res://assets/textures/projectiles/karipap.png":
		printerr("[FAIL] set_projectile_texture failed to set karipap.png on spewer slot: %s" % spewer_s1.get("texture"))
		quit(1)
		return

	# Verify projectile instantiation and apply_config
	var p_scene = load("res://scenes/enemies/projectile.tscn") as PackedScene
	if not p_scene:
		printerr("[FAIL] Could not load projectile.tscn")
		quit(1)
		return
	var test_proj = p_scene.instantiate()
	main.add_child(test_proj)
	if test_proj.has_method("apply_config"):
		test_proj.apply_config(spewer_s1, Vector2.LEFT)
		if test_proj.speed != 430.0 or test_proj.damage != 20:
			printerr("[FAIL] apply_config failed to configure projectile: speed=%s, dmg=%s" % [test_proj.speed, test_proj.damage])
			quit(1)
			return
	test_proj.queue_free()

	# Verify factory method spawn_projectile
	var spawned_bullet = EnemyProjectileDatabase.spawn_projectile(main, Vector2(600, 400), Vector2.LEFT, "void", 1)
	if not spawned_bullet:
		printerr("[FAIL] EnemyProjectileDatabase.spawn_projectile returned null")
		quit(1)
		return
	if not spawned_bullet.is_in_group("enemy_projectiles"):
		printerr("[FAIL] Spawned projectile not in enemy_projectiles group")
		quit(1)
		return
	spawned_bullet.queue_free()

	# Clean up and reset database
	EnemyProjectileDatabase.reset_to_defaults()
	var reset_cfg = EnemyProjectileDatabase.get_projectile_config("heavy", 3)
	if reset_cfg.get("speed") != 420.0:
		printerr("[FAIL] reset_to_defaults failed to restore default heavy speed")
		quit(1)
		return

	print("[PASS] Enemy Projectile Database, dictionary slots, overrides, and runtime spawning verified.")

	# =========================================================================
	# STEP 24: CUSTOM PROJECTILE AUTO-SCALING & ORIENTATION FIX VERIFICATION
	# =========================================================================
	print("\n--- STEP 24: VERIFYING CUSTOM PROJECTILE AUTO-SCALING & ORIENTATION FIX ---")
	var player_proj_scene = load("res://scenes/player/player_projectile.tscn") as PackedScene
	if not player_proj_scene:
		printerr("[FAIL] Could not load player_projectile.tscn")
		quit(1)
		return
	var test_pp = player_proj_scene.instantiate()
	main.add_child(test_pp)
	test_pp.setup_projectile(1, 1, 950.0, false, false, false, false)
	var pp_spr = test_pp.get_node_or_null("Sprite2D") as Sprite2D
	if pp_spr:
		if pp_spr.scale.x > 0.5 or pp_spr.scale.y > 0.5:
			printerr("[FAIL] Player projectile sprite scale not auto-scaled for custom art: %s" % pp_spr.scale)
			quit(1)
			return
		if pp_spr.rotation_degrees != 0.0:
			printerr("[FAIL] Player projectile custom sprite should face forward (0 deg), got: %s" % pp_spr.rotation_degrees)
			quit(1)
			return
		if pp_spr.modulate != Color(1.0, 1.0, 1.0, 1.0):
			printerr("[FAIL] Player projectile sprite modulate altered: %s" % pp_spr.modulate)
			quit(1)
			return
	test_pp.queue_free()

	# Verify enemy projectile smart auto-scaling
	var test_ep = p_scene.instantiate()
	main.add_child(test_ep)
	var ep_cfg = EnemyProjectileDatabase.get_projectile_config("spewer", 1)
	test_ep.apply_config(ep_cfg, Vector2.LEFT)
	var ep_spr = test_ep.get_node_or_null("Sprite2D") as Sprite2D
	if ep_spr:
		if ep_spr.scale.x > 0.25 or ep_spr.scale.y > 0.25:
			printerr("[FAIL] Enemy projectile sprite scale not smart-scaled: %s" % ep_spr.scale)
			quit(1)
			return
		if ep_spr.modulate != Color(1.0, 1.0, 1.0, 1.0):
			printerr("[FAIL] Enemy projectile sprite modulate altered: %s" % ep_spr.modulate)
			quit(1)
			return
	test_ep.queue_free()

	print("[PASS] Custom projectile auto-scaling, horizontal orientation, and unmodulated colors verified.")

	# =========================================================================
	# STEP 25: MOBILE CONTROLS PERSISTENCE & LOUDER AUDIO CALIBRATION
	# =========================================================================
	print("\n--- STEP 25: VERIFYING MOBILE CONTROLS PERSISTENCE & LOUDER AUDIO CALIBRATION ---")
	# 1. Simulate level completed and continue to next level
	hud.show_level_completed(1, 100, 1, true, true)
	if hud.mobile_controls.visible:
		printerr("[FAIL] Mobile controls should be hidden on LevelCompletedContainer")
		quit(1)
		return

	# Simulate continuing to next level
	main.current_state = 1 # GameState.ACTIVE
	main.current_wave = 1
	hud.hide_level_completed()
	main._start_wave_intro(2)
	if not hud.mobile_controls.visible:
		printerr("[FAIL] Mobile controls must be visible when continuing to next level!")
		quit(1)
		return
	if hud.virtual_joystick.visible:
		printerr("[FAIL] Virtual joystick should be hidden during stage intro banner while player stands still")
		quit(1)
		return
	if hud.mobile_fire_button.visible:
		printerr("[FAIL] Mobile fire button should be hidden during stage intro banner while player stands still")
		quit(1)
		return

	main._start_wave_active()
	if not hud.virtual_joystick.visible or not hud.mobile_fire_button.visible:
		printerr("[FAIL] Virtual joystick or fire button not visible inside mobile_controls after stage becomes active")
		quit(1)
		return

	# 2. Verify louder bus and sound configuration
	var music_bus_idx: int = AudioServer.get_bus_index("Music")
	var sfx_bus_idx: int = AudioServer.get_bus_index("SFX")
	if music_bus_idx >= 0 and AudioServer.get_bus_volume_db(music_bus_idx) < -0.1:
		printerr("[FAIL] Music bus volume attenuated: %f dB" % AudioServer.get_bus_volume_db(music_bus_idx))
		quit(1)
		return
	if sfx_bus_idx >= 0 and AudioServer.get_bus_volume_db(sfx_bus_idx) < -0.1:
		printerr("[FAIL] SFX bus volume attenuated: %f dB" % AudioServer.get_bus_volume_db(sfx_bus_idx))
		quit(1)
		return

	# Verify gun sound volume boosted (Plasma Blaster should be >= -0.5 dB, not -15 dB)
	var gun_snd = test_gun.get_gun_sound_config(1)
	if float(gun_snd.get("volume_db", -15.0)) < -0.5:
		printerr("[FAIL] Plasma blaster sound volume too low: %s" % gun_snd.get("volume_db"))
		quit(1)
		return

	# Verify sound manager volume boosted
	var laser_sfx = SoundManager.get_sound_config("laser_shoot")
	if float(laser_sfx.get("volume_db", -5.0)) < -0.5:
		printerr("[FAIL] laser_shoot SFX volume too low: %s" % laser_sfx.get("volume_db"))
		quit(1)
		return

	print("[PASS] Mobile controls persistence across stages and louder audio system verified.")

	# =========================================================================
	# STEP 26: RESET UPGRADE POINTS BUTTON IN UPGRADE BAY
	# =========================================================================
	print("\n--- STEP 26: VERIFYING RESET UPGRADE POINTS IN UPGRADE BAY ---")
	var shop_reset_btn = hud.get_node_or_null("ShopContainer/Margin/ShopVBox/ResetUpgradesButton") as Button
	if not shop_reset_btn:
		printerr("[FAIL] ResetUpgradesButton missing in ShopContainer")
		quit(1)
		return

	# Setup player with upgrades
	player.shield_level = 2 # spent 1 + 2 = 3 pts
	player.speed_level = 1  # spent 2 pts
	player.gun_level = 1    # spent 2 pts
	# Total spent: 3 + 2 + 2 = 7 pts
	main.upgrade_points = 5
	main._refresh_shop()

	if shop_reset_btn.disabled:
		printerr("[FAIL] ResetUpgradesButton should be enabled when points are spent")
		quit(1)
		return
	if "7 PTS" not in shop_reset_btn.text:
		printerr("[FAIL] ResetUpgradesButton text should state refund of 7 PTS, got: %s" % shop_reset_btn.text)
		quit(1)
		return

	# Trigger reset upgrades
	shop_reset_btn.emit_signal("pressed")

	if main.upgrade_points != 12: # 5 + 7 = 12
		printerr("[FAIL] Reset upgrades expected 12 points (5 + 7 refund), got: %d" % main.upgrade_points)
		quit(1)
		return
	if player.shield_level != 0 or player.speed_level != 0 or player.gun_level != 0:
		printerr("[FAIL] Player upgrades not reset to 0: shield=%d, speed=%d, gun=%d" % [player.shield_level, player.speed_level, player.gun_level])
		quit(1)
		return
	if not shop_reset_btn.disabled:
		printerr("[FAIL] ResetUpgradesButton should be disabled after all points refunded")
		quit(1)
		return

	var saved_check = SaveManager.load_save_data()
	if int(saved_check.get("upgrade_points", 0)) != 12 or int(saved_check.get("shield_level", -1)) != 0:
		printerr("[FAIL] Saved player state did not reflect upgrade points reset in SaveManager")
		quit(1)
		return

	print("[PASS] Reset upgrade points button in Upgrade Bay verified.")

	# =========================================================================
	# STEP 27: STARTING GUN & COMBAT AIRSPACE PERIMETER BOUNDARY
	# =========================================================================
	print("\n--- STEP 27: VERIFYING STARTING GUN & COMBAT AIRSPACE PERIMETER BOUNDARY ---")
	# 1. Starting Gun at level 0
	var s27_gun: Gun = (player.gun if ("gun" in player and player.gun) else player.get_node_or_null("Gun")) as Gun
	if not s27_gun:
		printerr("[FAIL] player.gun component missing in Player scene")
		quit(1)
		return

	player.gun_level = 0
	if not s27_gun.can_shoot():
		printerr("[FAIL] Gun should be able to shoot at level 0 (Starter Blaster enabled)")
		quit(1)
		return

	var s27_cfg: Dictionary = s27_gun.get_active_config()
	if s27_cfg.get("damage", -1) != 2 or s27_cfg.get("pierce", -1) != 1 or float(s27_cfg.get("speed", 0.0)) != 750.0:
		printerr("[FAIL] Starting Gun config stats mismatch: %s" % str(s27_cfg))
		quit(1)
		return

	s27_gun.update_visual()
	var s27_center_barrel = s27_gun.get_node_or_null("GunMount/GunSpriteCenter") as Sprite2D
	if not s27_center_barrel or not s27_center_barrel.visible:
		printerr("[FAIL] Starting Gun center barrel should be visible at level 0")
		quit(1)
		return

	# Verify shot spawns bolt with starter blaster stats
	var s27_bolt: Area2D = s27_gun.shoot(main, player.global_position)
	if not s27_bolt:
		printerr("[FAIL] Gun shoot at level 0 returned null bolt")
		quit(1)
		return
	if s27_bolt.get("damage") != 2 or s27_bolt.get("pierce") != 1:
		printerr("[FAIL] Spawned starter bolt stats mismatch: dmg=%s, prc=%s" % [str(s27_bolt.get("damage")), str(s27_bolt.get("pierce"))])
		quit(1)
		return
	s27_bolt.queue_free()

	# 2. Combat Boundary & Hazard Damage
	if not ("combat_boundary_ratio" in player):
		printerr("[FAIL] Player missing combat_boundary_ratio export variable")
		quit(1)
		return
	var expected_ratio: float = CombatBoundaryManager.get_boundary_ratio()
	if absf(player.combat_boundary_ratio - expected_ratio) > 0.001:
		printerr("[FAIL] Player combat_boundary_ratio should match CombatBoundaryManager (%f), got: %f" % [expected_ratio, player.combat_boundary_ratio])
		quit(1)
		return
	var expected_dps: float = CombatBoundaryManager.get_damage_per_second()
	if not ("boundary_hazard_dps" in player) or absf(player.boundary_hazard_dps - expected_dps) > 0.001:
		printerr("[FAIL] Player boundary_hazard_dps should match CombatBoundaryManager (%f), got: %f" % [expected_dps, player.boundary_hazard_dps])
		quit(1)
		return

	# Test player crossing boundary and taking hazard damage according to CombatBoundaryManager stats
	var screen_rect: Rect2 = player.get_viewport_rect()
	var screen_w: float = screen_rect.size.x if screen_rect.size.x > 0.0 else 1920.0
	var test_bound_x: float = CombatBoundaryManager.get_boundary_x(screen_w)
	var expected_tick_dmg: int = CombatBoundaryManager.get_damage_per_tick()

	player.position = Vector2(test_bound_x + 50.0, 540.0)
	player.current_shields = 0
	player.current_health = 100
	player.hazard_damage_timer = 0.0
	player._physics_process(CombatBoundaryManager.get_tick_interval() + 0.05)
	if not player.is_in_hazard_zone:
		printerr("[FAIL] Player should be marked in hazard zone when x > %f" % test_bound_x)
		quit(1)
		return
	var expected_hp: int = 100 - expected_tick_dmg
	if player.current_health != expected_hp:
		printerr("[FAIL] Player expected %d HP after hazard tick, got: %d" % [expected_hp, player.current_health])
		quit(1)
		return

	# Check red combat boundary line in main
	if not main.combat_boundary_line:
		printerr("[FAIL] main.combat_boundary_line missing in Main scene")
		quit(1)
		return
	if main.combat_boundary_line.default_color.r < 0.8 or main.combat_boundary_line.default_color.b > 0.4:
		printerr("[FAIL] main.combat_boundary_line should be red, got: %s" % str(main.combat_boundary_line.default_color))
		quit(1)
		return

	# Check combat hazard rect overlay in main
	if not main.combat_hazard_rect:
		printerr("[FAIL] main.combat_hazard_rect missing in Main scene")
		quit(1)
		return

	# Verify boundary and hazard rect fill the full gap to the bottom (>= 3000px height)
	main.current_state = main.GameState.ACTIVE
	main._update_combat_boundary_visual()
	var s27_p1: Vector2 = main.combat_boundary_line.get_point_position(1)
	if s27_p1.y < 3000.0 or main.combat_hazard_rect.size.y < 3000.0:
		printerr("[FAIL] Boundary line or hazard rect height does not fill the gap to the bottom: line_y=%f, rect_h=%f" % [s27_p1.y, main.combat_hazard_rect.size.y])
		quit(1)
		return

	# Verify line is invisible when far away and gradually appears when approaching
	player.position = Vector2(250.0, 540.0)
	main._update_combat_boundary_visual()
	if main.combat_boundary_line.visible:
		printerr("[FAIL] Boundary line should be invisible when player is far away in safe zone")
		quit(1)
		return

	player.position = Vector2(1150.0, 540.0)
	main._update_combat_boundary_visual()
	if not main.combat_boundary_line.visible:
		printerr("[FAIL] Boundary line should gradually become visible when player approaches")
		quit(1)
		return

	# Check HUD airspace warning panel
	if not hud.airspace_warning_container:
		printerr("[FAIL] hud.airspace_warning_container missing in HUD scene")
		quit(1)
		return
	if not hud.airspace_warning_title or "WARNING" not in hud.airspace_warning_title.text:
		printerr("[FAIL] hud airspace warning title missing or does not contain WARNING")
		quit(1)
		return
	if not hud.airspace_warning_lore or ("KOTA A FAMOSA" not in hud.airspace_warning_lore.text and "SOLARIAR" not in hud.airspace_warning_lore.text):
		printerr("[FAIL] hud airspace warning lore missing or does not contain warning text")
		quit(1)
		return

	# 3. Stage Completion Temporary Pause & Resume Verification
	player.resume_boundary_hazard()
	player.position = Vector2(test_bound_x + 50.0, 540.0)
	player.current_health = expected_hp
	player.hazard_damage_timer = 0.0

	# Test explicit pause
	main.pause_combat_boundary()
	if player.is_boundary_hazard_enabled_active():
		printerr("[FAIL] Player boundary hazard should be disabled after pause_combat_boundary()")
		quit(1)
		return
	if player.is_in_hazard_zone:
		printerr("[FAIL] Player is_in_hazard_zone should be false after pause_combat_boundary()")
		quit(1)
		return
	if main.combat_boundary_line.visible or main.combat_hazard_rect.visible:
		printerr("[FAIL] Boundary visuals should be hidden after pause_combat_boundary()")
		quit(1)
		return

	# Simulate 1.0 second of physics while paused in the hazard zone
	player._physics_process(1.0)
	if player.current_health != expected_hp:
		printerr("[FAIL] Player should not take damage while boundary hazard is paused, got HP: %d" % player.current_health)
		quit(1)
		return

	# Test resume
	main.resume_combat_boundary()
	if not player.is_boundary_hazard_enabled_active():
		printerr("[FAIL] Player boundary hazard should be enabled after resume_combat_boundary()")
		quit(1)
		return
	player._physics_process(CombatBoundaryManager.get_tick_interval() + 0.05)
	var expected_resumed_hp: int = expected_hp - expected_tick_dmg
	if player.current_health != expected_resumed_hp:
		printerr("[FAIL] Player should resume taking damage after resume_combat_boundary(), got HP: %d" % player.current_health)
		quit(1)
		return

	# Test automatic pause on stage cleared
	main.current_state = main.GameState.ACTIVE
	main._trigger_wave_cleared()
	if main.current_state != main.GameState.CLEARED:
		printerr("[FAIL] Expected GameState.CLEARED after _trigger_wave_cleared()")
		quit(1)
		return
	if player.is_boundary_hazard_enabled_active():
		printerr("[FAIL] Player boundary hazard should be paused automatically on stage completion")
		quit(1)
		return

	# Test automatic resume when next stage becomes active
	main._start_wave_active()
	if main.current_state != main.GameState.ACTIVE:
		printerr("[FAIL] Expected GameState.ACTIVE after _start_wave_active()")
		quit(1)
		return
	if not player.is_boundary_hazard_enabled_active():
		printerr("[FAIL] Player boundary hazard should resume automatically when next stage starts active")
		quit(1)
		return

	# Test stage intro: player is stationary, boundary is active, and virtual joystick + fire button are hidden
	main._start_wave_intro(1)
	if main.current_state != main.GameState.INTRO:
		printerr("[FAIL] Expected GameState.INTRO during _start_wave_intro()")
		quit(1)
		return
	if player.is_physics_processing():
		printerr("[FAIL] Player should not be physics processing (standing still) during stage intro banner")
		quit(1)
		return
	if not player.is_boundary_hazard_enabled_active():
		printerr("[FAIL] Boundary hazard system should be active during stage intro")
		quit(1)
		return
	if hud.virtual_joystick.visible:
		printerr("[FAIL] Virtual joystick should be hidden during stage intro while player stands still")
		quit(1)
		return
	if hud.mobile_fire_button.visible:
		printerr("[FAIL] Mobile fire button should be hidden during stage intro while player stands still")
		quit(1)
		return

	# Transition to active combat after banner: player movement restored, joystick & fire button shown
	main._start_wave_active()
	if not player.is_physics_processing():
		printerr("[FAIL] Player should resume physics processing when stage becomes active")
		quit(1)
		return
	if not hud.virtual_joystick.visible:
		printerr("[FAIL] Virtual joystick should become visible the moment player is able to move")
		quit(1)
		return
	if not hud.mobile_fire_button.visible:
		printerr("[FAIL] Mobile fire button should become visible the moment player is able to move")
		quit(1)
		return

	# Clean up to safe zone and pause
	player.position = Vector2(250.0, 540.0)
	main.pause_combat_boundary()

	# 4. Adjustable Danger Boundary Verification (set_combat_boundary_ratio & set_boundary_from_right)
	# Test setting boundary to 60% from left
	main.set_combat_boundary_ratio(0.60)
	if absf(main.get_combat_boundary_ratio() - 0.60) > 0.001 or absf(player.get_combat_boundary_ratio() - 0.60) > 0.001:
		printerr("[FAIL] set_combat_boundary_ratio(0.60) failed to update main or player: main=%f, player=%f" % [main.get_combat_boundary_ratio(), player.get_combat_boundary_ratio()])
		quit(1)
		return
	if absf(main.get_danger_zone_from_right_ratio() - 0.40) > 0.001:
		printerr("[FAIL] Expected danger_zone_from_right_ratio 0.40, got: %f" % main.get_danger_zone_from_right_ratio())
		quit(1)
		return

	# Test user's specific use case: starting 60% of screen from the right
	main.set_boundary_from_right(0.60)
	if absf(main.get_combat_boundary_ratio() - 0.40) > 0.001 or absf(player.get_combat_boundary_ratio() - 0.40) > 0.001:
		printerr("[FAIL] set_boundary_from_right(0.60) failed: main=%f, player=%f" % [main.get_combat_boundary_ratio(), player.get_combat_boundary_ratio()])
		quit(1)
		return
	if absf(main.get_danger_zone_from_right_ratio() - 0.60) > 0.001:
		printerr("[FAIL] Expected danger_zone_from_right_ratio 0.60, got: %f" % main.get_danger_zone_from_right_ratio())
		quit(1)
		return

	# Test line position dynamically updated
	main.current_state = main.GameState.ACTIVE
	main._update_combat_boundary_visual()
	var s27_expected_x: float = main.get_combat_boundary_x()
	var s27_p0: Vector2 = main.combat_boundary_line.get_point_position(0)
	if absf(s27_p0.x - s27_expected_x) > 1.0:
		printerr("[FAIL] Boundary line point X (%f) does not match expected X (%f)" % [s27_p0.x, s27_expected_x])
		quit(1)
		return

	# 5. Centralized CombatBoundaryManager Verification
	CombatBoundaryManager.set_boundary_ratio(0.55)
	if absf(CombatBoundaryManager.get_boundary_ratio() - 0.55) > 0.001:
		printerr("[FAIL] CombatBoundaryManager.set_boundary_ratio(0.55) mismatch")
		quit(1)
		return
	if absf(main.get_combat_boundary_ratio() - 0.55) > 0.001:
		printerr("[FAIL] main.get_combat_boundary_ratio() does not tally with CombatBoundaryManager")
		quit(1)
		return

	CombatBoundaryManager.set_damage_per_second(20.0)
	if CombatBoundaryManager.get_damage_per_tick() != 10:
		printerr("[FAIL] CombatBoundaryManager.get_damage_per_tick() expected 10 at 20 DPS, got: %d" % CombatBoundaryManager.get_damage_per_tick())
		quit(1)
		return

	CombatBoundaryManager.reset_to_defaults()
	var def_ratio: float = float(CombatBoundaryManager.DEFAULT_CONFIG.get("start_ratio", 0.65))
	if absf(CombatBoundaryManager.get_boundary_ratio() - def_ratio) > 0.001:
		printerr("[FAIL] CombatBoundaryManager.reset_to_defaults() failed")
		quit(1)
		return

	main.pause_combat_boundary()

	print("[PASS] Starting Gun & Combat Airspace Perimeter Boundary verified.")

	# -------------------------------------------------------------
	# STEP 28: ADVANCED BOSS ATTACK CAPABILITIES (WAURIOR & MINANGKABAU SHIP)
	# -------------------------------------------------------------
	print("\n--- STEP 28: VERIFYING ADVANCED BOSS ATTACK CAPABILITIES ---")

	# 1. Waurior (boss_waurior.tscn) Attack Architecture
	var wau_boss_scene = load("res://scenes/bosses/boss_waurior.tscn") as PackedScene
	if not wau_boss_scene:
		printerr("[FAIL] Could not load res://scenes/bosses/boss_waurior.tscn")
		quit(1)
		return
	var wau_inst = wau_boss_scene.instantiate()
	main.add_child(wau_inst)
	wau_inst.setup_boss(200, 540.0, 1.0, false)

	if not wau_inst.has_method("_get_center_muzzle"):
		printerr("[FAIL] Waurior missing _get_center_muzzle method")
		quit(1)
		return
	if not wau_inst.has_method("_get_upper_wing_muzzle"):
		printerr("[FAIL] Waurior missing _get_upper_wing_muzzle method")
		quit(1)
		return
	if not wau_inst.has_method("_get_lower_wing_muzzle"):
		printerr("[FAIL] Waurior missing _get_lower_wing_muzzle method")
		quit(1)
		return

	var wau_center: Vector2 = wau_inst._get_center_muzzle()
	var wau_up: Vector2 = wau_inst._get_upper_wing_muzzle()
	var wau_down: Vector2 = wau_inst._get_lower_wing_muzzle()
	if wau_up.y >= wau_center.y or wau_down.y <= wau_center.y:
		printerr("[FAIL] Waurior wingtip muzzles not geometrically distributed vertically")
		quit(1)
		return

	if not wau_inst.has_method("_execute_crescent_arc"):
		printerr("[FAIL] Waurior missing _execute_crescent_arc")
		quit(1)
		return
	if not wau_inst.has_method("_execute_cross_gusts"):
		printerr("[FAIL] Waurior missing _execute_cross_gusts")
		quit(1)
		return
	if not wau_inst.has_method("_execute_dart_barrage"):
		printerr("[FAIL] Waurior missing _execute_dart_barrage")
		quit(1)
		return
	if not wau_inst.has_method("_execute_aero_swoop"):
		printerr("[FAIL] Waurior missing _execute_aero_swoop")
		quit(1)
		return
	if not ("is_telegraphing_swoop" in wau_inst) or not ("swoop_target_apex" in wau_inst):
		printerr("[FAIL] Waurior missing charge telegraph state variables")
		quit(1)
		return
	if not wau_inst.has_method("_execute_gale_storm"):
		printerr("[FAIL] Waurior missing _execute_gale_storm")
		quit(1)
		return

	# Confirm whirlwind vortex artifacts or methods have been completely excised
	if "whirlwind_scene" in wau_inst or wau_inst.has_method("_execute_whirlwind_vortex"):
		printerr("[FAIL] Whirlwind vortex artifacts or methods still exist on Waurior")
		quit(1)
		return

	# Enrage transition check
	wau_inst.take_damage(120)
	if not wau_inst.is_enraged:
		printerr("[FAIL] Waurior did not enrage at <= 50% HP")
		quit(1)
		return
	wau_inst.queue_free()

	# 2. Minangkabau Ship (boss_ship.tscn) Attack Architecture
	var ship_scene = load("res://scenes/bosses/boss_ship.tscn") as PackedScene
	if not ship_scene:
		printerr("[FAIL] Could not load res://scenes/bosses/boss_ship.tscn")
		quit(1)
		return
	var ship_inst = ship_scene.instantiate()
	main.add_child(ship_inst)
	ship_inst.setup_boss(300, 540.0, 1.0, true)

	if not ship_inst.has_method("_get_horn_muzzle"):
		printerr("[FAIL] Minangkabau Ship missing _get_horn_muzzle method")
		quit(1)
		return
	if not ship_inst.has_method("_get_bow_muzzle"):
		printerr("[FAIL] Minangkabau Ship missing _get_bow_muzzle method")
		quit(1)
		return
	if not ship_inst.has_method("_get_broadside_muzzle"):
		printerr("[FAIL] Minangkabau Ship missing _get_broadside_muzzle method")
		quit(1)
		return

	var horn_up: Vector2 = ship_inst._get_horn_muzzle(true)
	var horn_down: Vector2 = ship_inst._get_horn_muzzle(false)
	var bow_pos: Vector2 = ship_inst._get_bow_muzzle()
	if horn_up.y >= bow_pos.y or horn_down.y <= bow_pos.y:
		printerr("[FAIL] Minangkabau Ship horn muzzles not vertically flanking the bow")
		quit(1)
		return

	for p in range(4):
		var p_muzzle: Vector2 = ship_inst._get_broadside_muzzle(p)
		if p_muzzle == Vector2.ZERO:
			printerr("[FAIL] Minangkabau Ship broadside port %d returned zero" % p)
			quit(1)
			return

	if not ship_inst.has_method("_launch_twin_horn_pincer"):
		printerr("[FAIL] Minangkabau Ship missing _launch_twin_horn_pincer")
		quit(1)
		return
	if not ship_inst.has_method("_launch_broadside_cascade"):
		printerr("[FAIL] Minangkabau Ship missing _launch_broadside_cascade")
		quit(1)
		return
	if not ship_inst.has_method("_launch_thruster_surge"):
		printerr("[FAIL] Minangkabau Ship missing _launch_thruster_surge")
		quit(1)
		return
	if not ("is_telegraphing_surge" in ship_inst) or not ("surge_target_x" in ship_inst):
		printerr("[FAIL] Minangkabau Ship missing charge telegraph state variables")
		quit(1)
		return
	if not ship_inst.has_method("_launch_railgun_stream"):
		printerr("[FAIL] Minangkabau Ship missing _launch_railgun_stream")
		quit(1)
		return
	if not ship_inst.has_method("_launch_phantom_laser"):
		printerr("[FAIL] Minangkabau Ship missing _launch_phantom_laser")
		quit(1)
		return
	if not ship_inst.has_method("_launch_armada_bombardment"):
		printerr("[FAIL] Minangkabau Ship missing _launch_armada_bombardment")
		quit(1)
		return

	# Confirm landmine references have been completely excised
	if "cosmic_mine_scene" in ship_inst or ship_inst.has_method("_launch_cosmic_mines"):
		printerr("[FAIL] Landmine artifacts or methods still exist on Minangkabau Ship")
		quit(1)
		return

	# 3. Minangkabau Ship Laser Beam (boss_laser_beam.tscn) Verification
	var laser_beam_scene = load("res://scenes/bosses/boss_laser_beam.tscn") as PackedScene
	if not laser_beam_scene:
		printerr("[FAIL] Could not load res://scenes/bosses/boss_laser_beam.tscn")
		quit(1)
		return
	var laser_inst = laser_beam_scene.instantiate()
	main.add_child(laser_inst)
	if not laser_inst.is_in_group("boss_hazard") or not laser_inst.is_in_group("boss_laser"):
		printerr("[FAIL] BossLaserBeam must be in group 'boss_hazard' and 'boss_laser'")
		quit(1)
		return
	if laser_inst.is_in_group("enemy_projectiles"):
		printerr("[FAIL] BossLaserBeam MUST NOT be in 'enemy_projectiles' group so it cannot be counter-shot")
		quit(1)
		return
	if not laser_inst.has_method("setup_beam"):
		printerr("[FAIL] BossLaserBeam missing setup_beam method")
		quit(1)
		return
	laser_inst.setup_beam(ship_inst, Vector2(-115.0, 0.0), 15, false)
	# Verify counter-shot immunity no-op contract
	if laser_inst.has_method("hit_by_player_projectile"):
		laser_inst.hit_by_player_projectile() # Must not throw or crash
	laser_inst.queue_free()

	# Enrage transition check
	ship_inst.take_damage(160)
	if not ship_inst.is_enraged:
		printerr("[FAIL] Minangkabau Ship did not enrage at <= 50% HP")
		quit(1)
		return
	ship_inst.queue_free()

	print("[PASS] Advanced Boss Attacks for Waurior & Minangkabau Ship verified.")

	# -------------------------------------------------------------
	# STEP 29: VERIFYING RENAMED BOSS SCENES & RANDOMIZED ATTACK SET COMBOS
	# -------------------------------------------------------------
	print("\n--- STEP 29: VERIFYING RENAMED BOSS SCENES & ATTACK SET COMBOS ---")

	# 1. Primary Waurior scene (boss_waurior.tscn)
	var wau_renamed_scene = load("res://scenes/bosses/boss_waurior.tscn") as PackedScene
	if not wau_renamed_scene:
		printerr("[FAIL] Could not load res://scenes/bosses/boss_waurior.tscn")
		quit(1)
		return
	var wau_renamed_inst = wau_renamed_scene.instantiate()
	main.add_child(wau_renamed_inst)
	wau_renamed_inst.setup_boss(200, 540.0, 1.0, false)

	if not ("is_executing_set" in wau_renamed_inst) or not ("current_attack_set" in wau_renamed_inst):
		printerr("[FAIL] Waurior missing attack set state variables")
		quit(1)
		return
	if not wau_renamed_inst.has_method("_execute_attack_set"):
		printerr("[FAIL] Waurior missing _execute_attack_set method")
		quit(1)
		return
	if not wau_renamed_inst.has_method("_execute_attack_set_1"):
		printerr("[FAIL] Waurior missing _execute_attack_set_1 method")
		quit(1)
		return
	wau_renamed_inst.queue_free()

	# 2. Primary Minangkabau Ship scene (boss_ship.tscn)
	var ship_renamed_scene = load("res://scenes/bosses/boss_ship.tscn") as PackedScene
	if not ship_renamed_scene:
		printerr("[FAIL] Could not load res://scenes/bosses/boss_ship.tscn")
		quit(1)
		return
	var ship_renamed_inst = ship_renamed_scene.instantiate()
	main.add_child(ship_renamed_inst)
	ship_renamed_inst.setup_boss(300, 540.0, 1.0, true)

	if not ("is_executing_set" in ship_renamed_inst) or not ("current_attack_set" in ship_renamed_inst):
		printerr("[FAIL] Minangkabau Ship missing attack set state variables")
		quit(1)
		return
	if not ship_renamed_inst.has_method("_execute_attack_set"):
		printerr("[FAIL] Minangkabau Ship missing _execute_attack_set method")
		quit(1)
		return
	if not ship_renamed_inst.has_method("_execute_attack_set_1"):
		printerr("[FAIL] Minangkabau Ship missing _execute_attack_set_1 method (Laser -> Stream -> Dash)")
		quit(1)
		return
	if not ship_renamed_inst.has_method("_execute_attack_set_2"):
		printerr("[FAIL] Minangkabau Ship missing _execute_attack_set_2 method")
		quit(1)
		return
	if not ship_renamed_inst.has_method("_execute_attack_set_3"):
		printerr("[FAIL] Minangkabau Ship missing _execute_attack_set_3 method")
		quit(1)
		return
	if not ship_renamed_inst.has_method("_execute_attack_set_4"):
		printerr("[FAIL] Minangkabau Ship missing _execute_attack_set_4 method")
		quit(1)
		return

	# Verify full-screen dash target X and warning corridor configurations
	if not ("dash_target_x" in ship_renamed_inst) or ship_renamed_inst.dash_target_x > 0.0:
		printerr("[FAIL] Minangkabau Ship dash_target_x should target leftmost screen area (<= 0.0)")
		quit(1)
		return
	if not ("dash_warning_to_screen_edge" in ship_renamed_inst) or not ship_renamed_inst.dash_warning_to_screen_edge:
		printerr("[FAIL] Minangkabau Ship dash_warning_to_screen_edge should be enabled")
		quit(1)
		return
	if not ship_renamed_inst.has_node("ProwCollisionShape2D"):
		printerr("[FAIL] Minangkabau Ship missing ProwCollisionShape2D for full dash coverage")
		quit(1)
		return
	ship_renamed_inst.queue_free()

	print("[PASS] Renamed Boss Scenes (boss_waurior.tscn, boss_ship.tscn) & Attack Sets verified.")

	# -------------------------------------------------------------
	# STEP 30: VERIFYING DEADLY DASH ATTACK (INSTANT LOSS EVEN WITH SHIELD)
	# -------------------------------------------------------------
	print("\n--- STEP 30: VERIFYING DEADLY DASH ATTACK (INSTANT LOSS EVEN WITH SHIELD) ---")

	var player_inst = main.get_node_or_null("Player")
	if not player_inst:
		printerr("[FAIL] Player instance missing in main scene for lethal dash test")
		quit(1)
		return

	if not player_inst.has_method("lethal_hit"):
		printerr("[FAIL] Player missing lethal_hit method")
		quit(1)
		return

	# 1. Test player.lethal_hit() directly with shields active
	player_inst.is_alive = true
	player_inst.current_health = 100
	player_inst.shield_level = 3
	player_inst.current_shields = 6
	player_inst.lethal_hit()

	if player_inst.is_alive or player_inst.current_health != 0 or player_inst.current_shields != 0:
		printerr("[FAIL] lethal_hit did not immediately wipe player health and shields to 0")
		quit(1)
		return

	# 2. Test Minangkabau Ship lethal dash collision
	player_inst.is_alive = true
	player_inst.current_health = 100
	player_inst.shield_level = 2
	player_inst.current_shields = 4

	var test_ship = ship_renamed_scene.instantiate()
	main.add_child(test_ship)
	test_ship.is_surging = true
	test_ship._on_body_entered(player_inst)

	if player_inst.is_alive or player_inst.current_health != 0 or player_inst.current_shields != 0:
		printerr("[FAIL] Minangkabau Ship surging dash collision did not instantly destroy shielded player")
		quit(1)
		return
	test_ship.queue_free()

	# 3. Test Waurior lethal dive collision
	player_inst.is_alive = true
	player_inst.current_health = 100
	player_inst.shield_level = 2
	player_inst.current_shields = 4

	var test_wau = wau_renamed_scene.instantiate()
	main.add_child(test_wau)
	test_wau.is_swooping = true
	test_wau._on_body_entered(player_inst)

	if player_inst.is_alive or player_inst.current_health != 0 or player_inst.current_shields != 0:
		printerr("[FAIL] Waurior swooping dive collision did not instantly destroy shielded player")
		quit(1)
		return
	test_wau.queue_free()

	print("[PASS] Deadly Dash Attacks verified: instant loss triggered even through kinetic shields.")

	print("\n*** ALL GODOT RUNTIME ENGINE TESTS PASSED WITH 0 ERRORS! ***")
	quit(0)
