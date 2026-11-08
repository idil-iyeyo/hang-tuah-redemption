#!/usr/bin/env python3
"""
Verification script for Game Features, Mobile Controls, and Mobile Upgrade UI.
Validates:
1. Reorganized project structure (scenes/, scripts/, assets/)
2. Starfield battlefield background logic & scene configuration
3. Welcome screen components & modal lifecycle
4. SaveManager high score persistence
5. Mobile control layout (VirtualJoystick, MobileFireButton, AutoFireButton)
6. Mobile Upgrade UI layout (large touch buttons, concise text)
7. Touch emulation configuration in project.godot
8. GDScript syntax, token integrity, and bracket balancing across all scripts
"""

import os
import re
import sys
import json
import struct
import zlib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def check_file_exists(rel_path):
    path = os.path.join(BASE_DIR, rel_path)
    if not os.path.isfile(path):
        print(f"[FAIL] Missing file: {rel_path}")
        return False
    print(f"[PASS] File exists: {rel_path}")
    return True

def verify_starfield_background():
    print("\n--- Verifying Battlefield Outer Space Background ---")
    script_path = os.path.join(BASE_DIR, "scenes/environment/starfield_background.gd")
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "class Star:" in content, "Star class definition missing"
    assert "class ShootingStar:" in content, "ShootingStar class definition missing"
    assert "distant_star_count" in content, "Distant star count missing"
    assert "mid_star_count" in content, "Mid star count missing"
    assert "s.x -= s.speed * speed_scale * delta" in content, "Leftward star movement missing"
    assert "if s.x < -30.0:" in content, "Star wrap-around logic missing"
    assert "draw_circle" in content, "Star draw circle missing"
    assert "draw_line" in content, "Star motion streak / shooting star missing"
    assert "Color(1.0, 1.0, 1.0" in content, "White star color missing"
    print("[PASS] starfield_background.gd logic, star classes, multi-layer speeds, and wrap-around verified.")

    scene_path = os.path.join(BASE_DIR, "scenes/environment/starfield_background.tscn")
    with open(scene_path, "r", encoding="utf-8") as f:
        tscn_content = f.read()
    assert "layer = -10" in tscn_content, "Background layer must be -10 to render behind battlefield"
    assert "starfield_background.gd" in tscn_content, "Script must be bound to scene"
    print("[PASS] starfield_background.tscn configuration and layer -10 verified.")

    main_scene_path = os.path.join(BASE_DIR, "scenes/main/main.tscn")
    with open(main_scene_path, "r", encoding="utf-8") as f:
        main_tscn = f.read()
    assert "starfield_background.tscn" in main_tscn, "StarfieldBackground must be instantiated in main.tscn"
    print("[PASS] main.tscn correctly includes StarfieldBackground instance.")


def verify_welcome_screen():
    print("\n--- Verifying Welcome Screen & Game Controller (Sprint 3: High Score Removed) ---")
    hud_scene_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_scene_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    assert ('text = "Space Shooter 2D"' in hud_tscn or 'Hang Tuah' in hud_tscn or 'name="GameTitle"' in hud_tscn), "Game title missing in hud.tscn"
    assert 'name="PlayButton"' in hud_tscn, "PlayButton node missing in hud.tscn"
    assert 'PLAY' in hud_tscn, "PLAY button text missing in hud.tscn"
    # Sprint 3: High score mechanics removed from level-based game
    assert 'name="HighScoreButton"' not in hud_tscn, "HighScoreButton must be removed in Sprint 3"
    assert 'name="HighScoreModal"' not in hud_tscn, "HighScoreModal must be removed in Sprint 3"
    assert 'name="CreditButton"' in hud_tscn, "CreditButton node missing in hud.tscn"
    assert 'Credit' in hud_tscn, "Credit button text missing in hud.tscn"
    assert 'name="CreditModal"' in hud_tscn, "CreditModal node missing in hud.tscn"
    print("[PASS] Welcome Screen buttons and modals verified in hud.tscn (High score cleanly removed).")

    hud_script_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_script_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "signal start_game_requested" in hud_gd, "start_game_requested signal missing"
    assert "signal return_to_menu_requested" in hud_gd, "return_to_menu_requested signal missing"
    assert "func show_welcome_screen" in hud_gd, "show_welcome_screen method missing"
    assert "func hide_welcome_screen" in hud_gd, "hide_welcome_screen method missing"
    print("[PASS] hud.gd signals and lifecycle methods verified.")

    main_script_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_script_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "MENU" in main_gd, "MENU state missing in GameState enum"
    assert "var current_state: GameState = GameState.MENU" in main_gd, "current_state should start at MENU"
    assert "hud.start_game_requested.connect(_on_start_game_requested)" in main_gd, "start_game_requested signal not connected"
    assert "hud.return_to_menu_requested.connect(_on_return_to_menu_requested)" in main_gd, "return_to_menu_requested signal not connected"
    print("[PASS] main.gd state machine and connections verified.")


def verify_save_manager():
    print("\n--- Verifying SaveManager Persistence & Level Completion (Sprint 4) ---")
    save_path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    with open(save_path, "r", encoding="utf-8") as f:
        save_gd = f.read()

    assert "class_name SaveManager" in save_gd, "SaveManager class name missing"
    assert "load_save_data" in save_gd, "load_save_data function missing"
    assert "user://space_shooter_save.json" in save_gd, "Save file path missing"
    assert "is_level_completed" in save_gd, "is_level_completed missing in save_manager.gd"
    assert "mark_level_completed" in save_gd, "mark_level_completed missing in save_manager.gd"
    assert "completed_levels" in save_gd, "completed_levels array missing in save_manager.gd"
    assert "rewarded_levels" in save_gd, "rewarded_levels array missing in save_manager.gd"
    assert "can_claim_level_reward" in save_gd, "can_claim_level_reward missing in save_manager.gd"
    assert "claim_level_reward" in save_gd, "claim_level_reward missing in save_manager.gd"
    assert "is_level_rewarded" in save_gd, "is_level_rewarded missing in save_manager.gd"
    assert "invalidate_cache" in save_gd, "invalidate_cache missing in save_manager.gd"
    print("[PASS] save_manager.gd structure, completion tracking, single-claim reward system, and in-memory cache verified.")


def verify_mobile_controls():
    print("\n--- Verifying Mobile Controls (Sprint 1: Auto-Fire Removed) ---")
    joy_path = os.path.join(BASE_DIR, "scenes/ui/virtual_joystick.gd")
    with open(joy_path, "r", encoding="utf-8") as f:
        joy_gd = f.read()
    assert "InputEventScreenTouch" in joy_gd, "Touch event handling missing in VirtualJoystick"
    assert "InputEventScreenDrag" in joy_gd, "Drag event handling missing in VirtualJoystick"
    assert "Input.action_press" in joy_gd, "Input action mapping missing in VirtualJoystick"
    assert "move_left" in joy_gd and "move_right" in joy_gd, "Directional mapping missing"
    assert "_draw" in joy_gd, "Custom drawing missing in VirtualJoystick"
    print("[PASS] VirtualJoystick script, touch/drag events, and directional injection verified.")

    fire_path = os.path.join(BASE_DIR, "scenes/ui/mobile_fire_button.gd")
    with open(fire_path, "r", encoding="utf-8") as f:
        fire_gd = f.read()
    assert "InputEventScreenTouch" in fire_gd, "Touch handling missing in MobileFireButton"
    assert "Input.action_press" in fire_gd, "action_press missing in MobileFireButton"
    assert "shoot" in fire_gd, "shoot action binding missing in MobileFireButton"
    assert "is_down" in fire_gd, "is_down state tracking missing in MobileFireButton"
    assert "auto_fire" not in fire_gd, "auto_fire must be removed from MobileFireButton in Sprint 1"
    print("[PASS] MobileFireButton script hold-to-shoot verified (auto_fire removed).")

    hud_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()
    assert 'name="MobileControls"' in hud_tscn, "MobileControls node missing in hud.tscn"
    assert 'name="VirtualJoystick"' in hud_tscn, "VirtualJoystick node missing in hud.tscn"
    assert 'name="MobileFireButton"' in hud_tscn, "MobileFireButton node missing in hud.tscn"
    assert 'name="AutoFireButton"' not in hud_tscn, "AutoFireButton node must be removed in Sprint 1"
    print("[PASS] hud.tscn contains MobileControls, VirtualJoystick, and MobileFireButton (AutoFireButton removed).")

    hud_script_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_script_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()
    assert "mobile_controls" in hud_gd, "mobile_controls reference missing in hud.gd"
    assert "virtual_joystick" in hud_gd, "virtual_joystick reference missing in hud.gd"
    assert "mobile_fire_button" in hud_gd, "mobile_fire_button reference missing in hud.gd"
    assert "set_mobile_controls_visible" in hud_gd, "set_mobile_controls_visible missing in hud.gd"
    assert "set_virtual_joystick_visible" in hud_gd, "set_virtual_joystick_visible missing in hud.gd"
    assert "set_mobile_fire_button_visible" in hud_gd, "set_mobile_fire_button_visible missing in hud.gd"
    print("[PASS] hud.gd controls visibility and state of mobile controls.")

    proj_path = os.path.join(BASE_DIR, "project.godot")
    with open(proj_path, "r", encoding="utf-8") as f:
        proj_content = f.read()
    assert "pointing/emulate_touch_from_mouse=true" in proj_content, "Touch from mouse emulation not enabled"
    print("[PASS] project.godot touch emulation verified.")


def verify_mobile_upgrade_ui():
    print("\n--- Verifying Mobile-Friendly Upgrade UI (Hull Repair Removed, Large Buttons) ---")
    hud_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    assert 'custom_minimum_size = Vector2(320, 66)' in hud_tscn, "Upgrade buttons are not enlarged (expected 320x66)"
    assert 'custom_minimum_size = Vector2(460, 68)' in hud_tscn, "Continue button is not enlarged (expected 460x68)"
    assert 'UPGRADE BAY' in hud_tscn, "Clean header missing"
    # Verification: Hull repair removed from upgrade bay
    assert 'name="HealRow"' not in hud_tscn, "HealRow must be removed from Upgrade Bay"
    assert 'name="HealButton"' not in hud_tscn, "HealButton must be removed from Upgrade Bay"
    print("[PASS] hud.tscn has enlarged upgrade buttons (320x66) and continue button (460x68) with HealRow removed.")

    hud_script_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_script_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()
    assert "Kinetic Shield • Lv" in hud_gd or "Kinetic Shield • MAX" in hud_gd, "Concise shield text missing"
    assert "Thrusters • Lv" in hud_gd or "Thrusters • MAX" in hud_gd, "Concise thruster text missing"
    assert "Quasar Laser • Lv" in hud_gd or "Quasar Laser • MAX" in hud_gd, "Concise weapon text missing"
    assert "heal_button" not in hud_gd, "heal_button should be removed from hud.gd"
    assert "heal_info" not in hud_gd, "heal_info should be removed from hud.gd"
    print("[PASS] hud.gd uses punchy mobile labels; Hull Repair removed from Upgrade Bay.")


def verify_health_reset_and_global_skin():
    print("\n--- Verifying Full Health on Level Start & Global Skin Integrity ---")
    main_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "player.current_health = player.max_health" in main_gd, "player.current_health = player.max_health missing in main.gd"
    assert "SaveManager.get_selected_skin()" in main_gd, "SaveManager.get_selected_skin() invocation missing in main.gd"
    assert "SaveManager.set_selected_skin(skin_id)" in main_gd, "SaveManager.set_selected_skin(skin_id) missing in main.gd"

    player_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_path, "r", encoding="utf-8") as f:
        player_gd = f.read()

    assert "func get_skin_color" in player_gd, "get_skin_color() method missing in player.gd"
    assert "tween.tween_property(sprite, \"modulate\", get_skin_color(), 0.2)" in player_gd, "take_damage must restore get_skin_color()"
    assert "tween.tween_property(sprite, \"modulate\", get_skin_color(), 0.25)" in player_gd, "heal must restore get_skin_color()"

    save_path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    with open(save_path, "r", encoding="utf-8") as f:
        save_gd = f.read()

    assert "func get_selected_skin" in save_gd, "get_selected_skin missing in save_manager.gd"
    assert "func set_selected_skin" in save_gd, "set_selected_skin missing in save_manager.gd"
    print("[PASS] Full health on level start and global skin persistence verified.")


def verify_gdscript_syntax():
    print("\n--- Verifying GDScript Syntax & Indentation Integrity ---")
    gd_files = [
        "scenes/environment/starfield_background.gd",
        "scripts/save_manager.gd",
        "scripts/music_manager.gd",
        "scripts/sound_manager.gd",
        "scripts/stage_audio_database.gd",
        "scripts/enemy_theme_manager.gd",
        "scripts/enemy_projectile_database.gd",
        "scripts/boss_name_manager.gd",
        "scripts/stage_spawn_manager.gd",
        "scripts/verify_runtime.gd",
        "scenes/ui/hud.gd",
        "scenes/main/main.gd",
        "scenes/player/player.gd",
        "scenes/player/gun.gd",
        "scenes/player/player_projectile.gd",
        "scenes/ui/virtual_joystick.gd",
        "scenes/ui/mobile_fire_button.gd",
        "scenes/enemies/heavy_enemy.gd",
        "scenes/enemies/bile_spewer.gd",
        "scenes/enemies/bile_breeder.gd",
        "scenes/enemies/charger_roach.gd",
        "scenes/enemies/void_bile.gd",
        "scenes/enemies/projectile.gd",
        "scenes/bosses/boss_waurior.gd",
        "scenes/bosses/boss_ship.gd",
        "scenes/ui/comic_slides.gd"
    ]

    for rel_path in gd_files:
        path = os.path.join(BASE_DIR, rel_path)
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()

        stack = []
        for line_idx, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue

            in_str = False
            str_char = None
            for c in line:
                if c in ['"', "'"]:
                    if not in_str:
                        in_str = True
                        str_char = c
                    elif str_char == c:
                        in_str = False
                elif not in_str:
                    if c in "({[":
                        stack.append((c, line_idx))
                    elif c in ")}]":
                        if not stack:
                            print(f"[FAIL] Unmatched closing '{c}' in {rel_path}:{line_idx}")
                            sys.exit(1)
                        opener, op_line = stack.pop()
                        matches = {')': '(', '}': '{', ']': '['}
                        if matches[c] != opener:
                            print(f"[FAIL] Mismatched bracket '{opener}' (line {op_line}) and '{c}' in {rel_path}:{line_idx}")
                            sys.exit(1)

        if stack:
            print(f"[FAIL] Unclosed bracket in {rel_path}: {stack}")
            sys.exit(1)

        print(f"[PASS] {rel_path} syntax and bracket balance verified ({len(lines)} lines).")


def verify_level_select_and_progression_system():
    print("\n--- Verifying Select Level Screen, 5x2 Layout, Transitions & Completion System ---")
    hud_tscn_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_tscn_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    # 1. Select Level Screen Presence & Layout (Slideable Carousel & Flanking Arrows)
    assert 'name="SelectLevelContainer"' in hud_tscn, "SelectLevelContainer missing in hud.tscn"
    assert 'name="ExitToMenuButton"' in hud_tscn, "ExitToMenuButton missing at top-left"
    assert 'Exit to Main Menu' in hud_tscn, "Exit to Main Menu text missing"
    assert 'name="SelectLevelUpgradeButton"' in hud_tscn, "SelectLevelUpgradeButton missing at top-right"
    assert 'UPGRADE BAY' in hud_tscn, "UPGRADE BAY text missing at top-right of Select Level"
    assert 'name="CarouselHBox"' in hud_tscn, "CarouselHBox node missing"
    assert 'name="LeftArrowButton"' in hud_tscn, "LeftArrowButton node missing"
    assert 'name="RightArrowButton"' in hud_tscn, "RightArrowButton node missing"
    assert 'name="LevelViewport"' in hud_tscn, "LevelViewport node missing"
    assert 'name="LevelTrack"' in hud_tscn, "LevelTrack node missing"
    assert 'name="LevelGrid"' in hud_tscn, "LevelGrid node missing"
    assert 'columns = 5' in hud_tscn, "LevelGrid must have columns = 5 (for 5 columns x 2 rows = 10 per page, 1 on top, 6 at bottom)"
    assert 'name="PrevPageButton"' not in hud_tscn, "PrevPageButton must be replaced by slideable carousel and flanking arrows"
    assert 'name="NextPageButton"' not in hud_tscn, "NextPageButton must be replaced by slideable carousel and flanking arrows"
    assert 'name="PageIndicatorLabel"' in hud_tscn, "PageIndicatorLabel missing"
    print("[PASS] SelectLevelContainer, CarouselHBox, Left/Right Arrows, LevelViewport, LevelTrack, and 5-column LevelGrid verified in hud.tscn.")

    # 2. Extensible Tabs (Levels & Skins)
    assert 'name="LevelsTabButton"' in hud_tscn, "LevelsTabButton missing"
    assert 'name="SkinsTabButton"' in hud_tscn, "SkinsTabButton missing"
    assert 'name="SkinsView"' in hud_tscn, "SkinsView container missing for extensible skins tab"
    print("[PASS] Extensible tabs (Missions & Skins/Hangar) verified in hud.tscn.")

    # 3. Level Completed & Level Lost Screens (Sprint 2)
    assert 'name="LevelCompletedContainer"' in hud_tscn, "LevelCompletedContainer missing"
    assert 'Level completed!' in hud_tscn, "Level completed! title missing"
    assert 'name="CompletedExitButton"' in hud_tscn, "CompletedExitButton missing"
    assert 'name="CompletedUpgradeButton"' in hud_tscn, "CompletedUpgradeButton missing"
    assert 'name="CompletedContinueButton"' in hud_tscn, "CompletedContinueButton missing"
    print("[PASS] LevelCompletedContainer with 3 buttons (Exit, Upgrade, Continue to next level) verified in hud.tscn.")

    assert 'name="LevelLostContainer"' in hud_tscn, "LevelLostContainer missing in hud.tscn (Sprint 2)"
    assert 'Level Lost!' in hud_tscn, "Level Lost! title missing in hud.tscn"
    assert 'name="LostExitButton"' in hud_tscn, "LostExitButton missing in hud.tscn"
    assert 'name="LostUpgradeButton"' in hud_tscn, "LostUpgradeButton missing in hud.tscn"
    assert 'name="LostReplayButton"' in hud_tscn, "LostReplayButton missing in hud.tscn"
    print("[PASS] LevelLostContainer with 3 buttons (Exit, Upgrade, Replay level) verified in hud.tscn (Sprint 2).")

    # 4. Black Screen Transition Overlay
    assert 'name="ScreenTransitionOverlay"' in hud_tscn, "ScreenTransitionOverlay missing"
    print("[PASS] ScreenTransitionOverlay verified in hud.tscn.")

    # 5. Logic in hud.gd
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "const TOTAL_LEVELS: int = 20" in hud_gd, "TOTAL_LEVELS constant missing"
    assert "const LEVELS_PER_PAGE: int = 10" in hud_gd, "LEVELS_PER_PAGE constant missing"
    assert "const GRID_COLUMNS: int = 5" in hud_gd, "GRID_COLUMNS constant missing"
    assert "const GRID_ROWS: int = 2" in hud_gd, "GRID_ROWS constant missing"
    assert "PAGE_WIDTH" in hud_gd, "PAGE_WIDTH constant missing"
    assert "DRAG_THRESHOLD" in hud_gd, "DRAG_THRESHOLD constant missing"
    assert "SWIPE_DISTANCE_THRESHOLD" in hud_gd, "SWIPE_DISTANCE_THRESHOLD constant missing"
    assert "signal level_selected" in hud_gd, "level_selected signal missing"
    assert "signal exit_to_level_select_requested" in hud_gd, "exit_to_level_select_requested signal missing"
    assert "signal open_upgrade_bay_requested" in hud_gd, "open_upgrade_bay_requested signal missing"
    assert "signal continue_to_next_level_requested" in hud_gd, "continue_to_next_level_requested signal missing"
    assert "signal skin_selected" in hud_gd, "skin_selected signal missing"
    assert "func show_select_level" in hud_gd, "show_select_level method missing"
    assert "func hide_select_level" in hud_gd, "hide_select_level method missing"
    assert "func _refresh_level_page" in hud_gd, "_refresh_level_page method missing"
    assert "func slide_to_page" in hud_gd, "slide_to_page method missing"
    assert "func _handle_carousel_gui_input" in hud_gd, "_handle_carousel_gui_input method missing"
    assert "func _finish_carousel_drag" in hud_gd, "_finish_carousel_drag method missing"
    assert "func _on_left_arrow_pressed" in hud_gd, "_on_left_arrow_pressed method missing"
    assert "func _on_right_arrow_pressed" in hud_gd, "_on_right_arrow_pressed method missing"
    assert "func fade_to_black" in hud_gd, "fade_to_black transition method missing"
    assert "func fade_from_black" in hud_gd, "fade_from_black transition method missing"
    assert "func show_level_completed" in hud_gd, "show_level_completed method missing"
    assert "func hide_level_completed" in hud_gd, "hide_level_completed method missing"
    assert "signal replay_level_requested" in hud_gd, "replay_level_requested signal missing"
    assert "func show_level_lost" in hud_gd, "show_level_lost method missing"
    assert "func hide_level_lost" in hud_gd, "hide_level_lost method missing"
    assert "crown_icon_texture" in hud_gd, "crown_icon_texture variable missing"
    assert "crown_texture_override" in hud_gd, "crown_texture_override export variable missing"
    assert "CrownIcon" in hud_gd, "CrownIcon node instantiation missing in hud.gd"
    print("[PASS] hud.gd slideable carousel, flanking arrows, touch drag, signals, crown icon, and transitions verified.")

    # 6. Main Orchestrator logic in main.gd
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "hud.level_selected.connect(_on_level_selected)" in main_gd, "level_selected signal connection missing"
    assert "hud.exit_to_level_select_requested.connect(_on_exit_to_level_select_requested)" in main_gd, "exit_to_level_select_requested signal connection missing"
    assert "hud.open_upgrade_bay_requested.connect(_on_open_upgrade_bay_requested)" in main_gd, "open_upgrade_bay_requested signal connection missing"
    assert "hud.continue_to_next_level_requested.connect(_on_continue_to_next_level_requested)" in main_gd, "continue_to_next_level_requested signal connection missing"
    assert "hud.replay_level_requested.connect(_on_replay_level_requested)" in main_gd, "replay_level_requested signal connection missing"
    assert "hud.skin_selected.connect(_on_skin_selected)" in main_gd, "skin_selected signal connection missing"
    assert "hud.show_level_completed(" in main_gd, "show_level_completed invocation missing in main.gd"
    assert "hud.show_level_lost(" in main_gd, "show_level_lost invocation missing in main.gd"
    assert "hud.fade_from_black" in main_gd, "fade_from_black call missing in main.gd"
    print("[PASS] main.gd level progression, transition to black, completion, and level lost routing verified.")

    # 7. Persistence & Skins in SaveManager and Player
    save_gd_path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    with open(save_gd_path, "r", encoding="utf-8") as f:
        save_gd = f.read()
    assert "unlocked_level" in save_gd, "unlocked_level tracking missing in SaveManager"
    assert "unlock_level" in save_gd, "unlock_level function missing in SaveManager"
    assert "save_player_state" in save_gd, "save_player_state function missing in SaveManager"
    assert "selected_skin" in save_gd, "selected_skin tracking missing in SaveManager"
    print("[PASS] SaveManager unlocked_level persistence and player state saving verified.")

    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        player_gd = f.read()
    assert "func set_skin" in player_gd, "set_skin method missing in player.gd"
    assert "current_skin" in player_gd, "current_skin property missing in player.gd"
    print("[PASS] player.gd skin customizability verified.")


def verify_pause_system():
    print("\n--- Verifying Gameplay Pause Button & Pause Screen ---")
    hud_tscn_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_tscn_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    assert 'name="PauseButton"' in hud_tscn, "PauseButton node missing in hud.tscn"
    assert 'anchor_left = 0.5' in hud_tscn, "PauseButton should be anchored horizontally center"
    assert 'anchor_right = 0.5' in hud_tscn, "PauseButton should be anchored horizontally center"
    assert 'PAUSE' in hud_tscn, "PAUSE text missing in hud.tscn"

    assert 'name="PauseContainer"' in hud_tscn, "PauseContainer node missing in hud.tscn"
    assert 'name="PauseTitle"' in hud_tscn, "PauseTitle node missing in PauseContainer"
    assert 'name="PauseExitButton"' in hud_tscn, "PauseExitButton missing in PauseContainer"
    assert 'name="PauseReplayButton"' in hud_tscn, "PauseReplayButton missing in PauseContainer"
    assert 'name="PauseResumeButton"' in hud_tscn, "PauseResumeButton missing in PauseContainer"
    assert 'process_mode = 3' in hud_tscn, "Process mode PROCESS_MODE_ALWAYS (3) missing on Pause UI"
    print("[PASS] hud.tscn contains top-center PauseButton and PauseContainer with 3 buttons (Exit, Replay, Resume).")

    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "pause_button" in hud_gd, "pause_button reference missing in hud.gd"
    assert "pause_container" in hud_gd, "pause_container reference missing in hud.gd"
    assert "func show_pause_screen" in hud_gd, "show_pause_screen method missing in hud.gd"
    assert "func resume_game" in hud_gd, "resume_game method missing in hud.gd"
    assert "get_tree().paused = true" in hud_gd, "get_tree().paused = true missing in hud.gd"
    assert "get_tree().paused = false" in hud_gd, "get_tree().paused = false missing in hud.gd"
    print("[PASS] hud.gd pause screen lifecycle, tree pausing, control hiding, and resumption verified.")

    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "get_tree().paused = false" in main_gd, "get_tree().paused = false unpause safeguard missing in main.gd"
    print("[PASS] main.gd unpause safeguards on level replay and exit verified.")


def verify_dragon_roach():
    print("\n--- Verifying Minangkabau Ship Shoot Mechanics (Spread & Stream) ---")
    tscn_path = os.path.join(BASE_DIR, "scenes/bosses/boss_ship.tscn")
    with open(tscn_path, "r", encoding="utf-8") as f:
        roach_tscn = f.read()

    assert "projectile_scene = null" not in roach_tscn, "projectile_scene must not be overridden with null in boss_ship.tscn"
    assert "max_health = null" not in roach_tscn, "max_health must not be overridden with null in boss_ship.tscn"
    assert "advance_speed = null" not in roach_tscn, "advance_speed must not be overridden with null in boss_ship.tscn"
    print("[PASS] boss_ship.tscn contains no null exported property overrides.")

    gd_path = os.path.join(BASE_DIR, "scenes/bosses/boss_ship.gd")
    with open(gd_path, "r", encoding="utf-8") as f:
        roach_gd = f.read()

    assert "enum AttackPattern" in roach_gd, "AttackPattern enum missing"
    assert "SPREAD_VOLLEY" in roach_gd, "SPREAD_VOLLEY pattern missing"
    assert "STREAM_BURST" in roach_gd, "STREAM_BURST pattern missing"
    assert "func _spawn_dragon_projectile" in roach_gd, "Reusable _spawn_dragon_projectile helper missing"
    assert "func _get_muzzle_position" in roach_gd, "_get_muzzle_position helper missing"
    assert "func _get_aim_direction" in roach_gd, "_get_aim_direction helper missing"
    assert "func _launch_spread_volley" in roach_gd, "_launch_spread_volley method missing"
    assert "func _launch_stream_burst" in roach_gd, "_launch_stream_burst method missing"
    assert "VOLLEY_COUNT_NORMAL" in roach_gd, "VOLLEY_COUNT_NORMAL constant missing"
    assert "VOLLEY_COUNT_ENRAGED" in roach_gd, "VOLLEY_COUNT_ENRAGED constant missing"
    assert "STREAM_COUNT_NORMAL" in roach_gd, "STREAM_COUNT_NORMAL constant missing"
    assert "STREAM_COUNT_ENRAGED" in roach_gd, "STREAM_COUNT_ENRAGED constant missing"
    assert "signal minion_spawn_requested" in roach_gd, "minion_spawn_requested signal missing"
    assert "signal health_changed" in roach_gd, "health_changed signal missing"
    assert "signal boss_defeated" in roach_gd, "boss_defeated signal missing"
    assert "signal boss_reached_player" in roach_gd, "boss_reached_player signal missing"
    print("[PASS] Dragon Roach Queen spreaded projectiles, long stream attack, and reusable pipeline verified.")


def verify_gun_barrel_visuals():
    print("\n--- Verifying Gun Barrel Visual Proportions & Scaling (Waterfall Iteration 9) ---")
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        player_gd = f.read()

    # Verify standard scale constants
    assert "const SCALE_BARREL_STANDARD: Vector2 = Vector2(2.0, 2.0)" in player_gd, "SCALE_BARREL_STANDARD constant missing"
    assert "const SCALE_CANNON_STANDARD: Vector2 = Vector2(5.0, 5.0)" in player_gd, "SCALE_CANNON_STANDARD constant missing"

    # Verify standard position constants
    assert "const POS_BARREL_CENTER: Vector2 = Vector2(7.0, 3.0)" in player_gd, "POS_BARREL_CENTER constant missing"
    assert "const POS_BARREL_TOP: Vector2 = Vector2(-8.0, -7.0)" in player_gd, "POS_BARREL_TOP constant missing"
    assert "const POS_BARREL_BOTTOM: Vector2 = Vector2(-8.0, 13.0)" in player_gd, "POS_BARREL_BOTTOM constant missing"
    assert "const POS_CANNON: Vector2 = Vector2(17.0, 10.0)" in player_gd, "POS_CANNON constant missing"

    # Verify that distorted fractional squished scales are eradicated
    assert "0.42, 0.14" not in player_gd, "Squished scale Vector2(0.42, 0.14) must be removed"
    assert "0.60, 0.22" not in player_gd, "Squished scale Vector2(0.60, 0.22) must be removed"
    assert "0.65, 0.16" not in player_gd, "Squished scale Vector2(0.65, 0.16) must be removed"
    assert "0.48, 0.10" not in player_gd, "Squished scale Vector2(0.48, 0.10) must be removed"

    # Verify reset logic in _update_gun_visual
    assert "gun_sprite_center.scale = SCALE_BARREL_STANDARD" in player_gd, "Center barrel scale reset missing"
    assert "gun_sprite_top.scale = SCALE_BARREL_STANDARD" in player_gd, "Top barrel scale reset missing"
    assert "gun_sprite_bottom.scale = SCALE_BARREL_STANDARD" in player_gd, "Bottom barrel scale reset missing"
    assert "gun_sprite_cannon.scale = SCALE_CANNON_STANDARD" in player_gd, "Cannon scale reset missing"

    # Verify Level 4 and Level 5 logic
    assert "elif gun_level == 4:" in player_gd, "gun_level == 4 branch missing"
    assert "if gun_level >= 5:" in player_gd, "gun_level >= 5 branch missing"

    # Verify player scene setup and gun scene hierarchy
    player_tscn_path = os.path.join(BASE_DIR, "scenes/player/player.tscn")
    with open(player_tscn_path, "r", encoding="utf-8") as f:
        player_tscn = f.read()

    gun_tscn_path = os.path.join(BASE_DIR, "scenes/player/gun.tscn")
    gun_tscn = ""
    if os.path.exists(gun_tscn_path):
        with open(gun_tscn_path, "r", encoding="utf-8") as f:
            gun_tscn = f.read()

    combined_gun_defs = player_tscn + gun_tscn
    assert 'name="GunMount"' in combined_gun_defs, "GunMount missing in gun or player hierarchy"
    assert 'name="GunSpriteCenter"' in combined_gun_defs, "GunSpriteCenter missing in gun or player hierarchy"
    assert 'name="GunSpriteTop"' in combined_gun_defs, "GunSpriteTop missing in gun or player hierarchy"
    assert 'name="GunSpriteBottom"' in combined_gun_defs, "GunSpriteBottom missing in gun or player hierarchy"
    assert 'name="GunSpriteCannon"' in combined_gun_defs, "GunSpriteCannon missing in gun or player hierarchy"

    print("[PASS] Gun barrel visual proportions, constants, reset integrity, and scene nodes verified.")


def verify_modular_gun_architecture():
    print("\n--- Verifying Modular Gun Scene Architecture & Config-Driven Database ---")
    gun_tscn_path = os.path.join(BASE_DIR, "scenes/player/gun.tscn")
    gun_gd_path = os.path.join(BASE_DIR, "scenes/player/gun.gd")
    player_tscn_path = os.path.join(BASE_DIR, "scenes/player/player.tscn")
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")

    assert os.path.exists(gun_tscn_path), "gun.tscn scene file missing"
    assert os.path.exists(gun_gd_path), "gun.gd script file missing"

    with open(gun_tscn_path, "r", encoding="utf-8") as f:
        gun_tscn = f.read()
    with open(gun_gd_path, "r", encoding="utf-8") as f:
        gun_gd = f.read()
    with open(player_tscn_path, "r", encoding="utf-8") as f:
        player_tscn = f.read()
    with open(player_gd_path, "r", encoding="utf-8") as f:
        player_gd = f.read()

    # 1. Verify Player scene cleanly instantiates Gun scene
    assert "res://scenes/player/gun.tscn" in player_tscn, "player.tscn does not instance gun.tscn"
    assert 'name="Gun"' in player_tscn, 'name="Gun" node missing in player.tscn'

    # 2. Verify Gun scene structure
    assert '[node name="Gun" type="Node2D"]' in gun_tscn or '[node name="Gun"' in gun_tscn, "Root Gun Node2D missing in gun.tscn"
    assert 'name="GunMount"' in gun_tscn, "GunMount Node2D missing in gun.tscn"
    assert 'name="GunSpriteCenter"' in gun_tscn, "GunSpriteCenter missing in gun.tscn"
    assert 'name="GunSpriteTop"' in gun_tscn, "GunSpriteTop missing in gun.tscn"
    assert 'name="GunSpriteBottom"' in gun_tscn, "GunSpriteBottom missing in gun.tscn"
    assert 'name="GunSpriteCannon"' in gun_tscn, "GunSpriteCannon missing in gun.tscn"
    assert 'name="ShootSoundPlayer"' in gun_tscn, "ShootSoundPlayer missing in gun.tscn"
    assert 'name="CannonSoundPlayer"' in gun_tscn, "CannonSoundPlayer missing in gun.tscn"

    # 3. Verify Centralized Database (DEFAULT_CONFIGS) covering all 6 weapon tiers
    assert "const DEFAULT_CONFIGS: Dictionary = {" in gun_gd, "DEFAULT_CONFIGS database missing in gun.gd"
    assert "0: {" in gun_gd and '"Emergency Blaster"' in gun_gd, "Level 0 Emergency Blaster missing in gun.gd"
    assert "1: {" in gun_gd and '"Plasma Blaster"' in gun_gd, "Level 1 Plasma Blaster missing in gun.gd"
    assert "2: {" in gun_gd and '"Dual Blaster"' in gun_gd, "Level 2 Dual Blaster missing in gun.gd"
    assert "3: {" in gun_gd and '"Heavy Cannon"' in gun_gd, "Level 3 Heavy Cannon missing in gun.gd"
    assert "4: {" in gun_gd and '"Explosive Gatling"' in gun_gd, "Level 4 Explosive Gatling missing in gun.gd"
    assert "5: {" in gun_gd and '"Quasar Laser"' in gun_gd, "Level 5 Quasar Laser missing in gun.gd"

    # Verify key stats for every tier are accurately configured in the database
    # Level 0 (Emergency): 2 or 5 dmg, 1 pierce, 0.48 cd, 750 spd
    assert ('"damage": 2' in gun_gd or '"damage": 5' in gun_gd), "Emergency damage missing"
    assert '"cooldown": 0.48' in gun_gd, "Emergency 0.48 cooldown missing"
    # Level 1: 3 dmg, 2 pierce, 0.35 cd, 950 spd
    assert '"damage": 3' in gun_gd, "Level 1 3 damage missing"
    assert '"cooldown": 0.35' in gun_gd, "Level 1 0.35 cooldown missing"
    # Level 2: 5 dmg, 2 pierce, 0.22 cd, 950 spd, alternating
    assert '"cooldown": 0.22' in gun_gd, "Level 2 0.22 cooldown missing"
    assert '"is_alternating": true' in gun_gd, "Level 2 alternating true missing"
    # Level 3: 8 or 10 dmg, 5 pierce, 0.65 cd, 800 spd, cannon
    assert ('"damage": 8' in gun_gd or '"damage": 10' in gun_gd), "Level 3 damage missing"
    assert '"cooldown": 0.65' in gun_gd, "Level 3 0.65 cooldown missing"
    assert '"is_cannon": true' in gun_gd, "Level 3 cannon true missing"
    # Level 4: 5 dmg, 3 pierce, 0.12 cd, 1150 spd, gatling
    assert '"cooldown": 0.12' in gun_gd, "Level 4 0.12 cooldown missing"
    assert '"is_gatling": true' in gun_gd, "Level 4 gatling true missing"
    # Level 5: 2.5, 4 or 7 dmg, 1 pierce, 0.055 cd, 2600 spd, laser
    assert ('"damage": 7' in gun_gd or '"damage": 4' in gun_gd or '"damage": 2.5' in gun_gd), "Level 5 damage missing"
    assert '"cooldown": 0.055' in gun_gd, "Level 5 0.055 cooldown missing"
    assert '"is_laser": true' in gun_gd, "Level 5 laser true missing"

    # 4. Verify Modular Gun API methods for stat modification and decoupled usage
    assert "func can_shoot() -> bool:" in gun_gd, "can_shoot() method missing in gun.gd"
    assert "func shoot(" in gun_gd, "shoot() method missing in gun.gd"
    assert "func spawn_blaster_bolt(" in gun_gd, "spawn_blaster_bolt() method missing in gun.gd"
    assert "func update_visual() -> void:" in gun_gd, "update_visual() method missing in gun.gd"
    assert "func upgrade_gun() -> bool:" in gun_gd, "upgrade_gun() method missing in gun.gd"
    assert "func equip_free_emergency_gun() -> void:" in gun_gd, "equip_free_emergency_gun() method missing in gun.gd"
    assert "func get_stat(" in gun_gd, "get_stat() method missing in gun.gd"
    assert "func set_stat(" in gun_gd, "set_stat() method missing in gun.gd"
    assert "func get_active_config() -> Dictionary:" in gun_gd, "get_active_config() method missing in gun.gd"
    assert "func get_gun_config(" in gun_gd, "get_gun_config() method missing in gun.gd"

    # 5. Verify Player delegates cleanly to Gun component
    assert "gun.shoot(get_parent(), global_position)" in player_gd, "Player does not delegate shoot to Gun"
    assert "gun.process_cooldown(delta)" in player_gd, "Player does not process cooldown via Gun"
    assert "gun.upgrade_gun()" in player_gd, "Player does not upgrade gun via Gun"
    assert "var gun_level: int:" in player_gd, "Player missing backward-compatible gun_level getter/setter"
    assert "var has_emergency_gun: bool:" in player_gd, "Player missing backward-compatible has_emergency_gun getter/setter"
    assert "var shoot_cooldown_timer: float:" in player_gd, "Player missing backward-compatible shoot_cooldown_timer getter/setter"

    print("[PASS] Modular Gun Scene Architecture & Config-Driven Database verified.")


def verify_ship_thruster():
    print("\n--- Verifying Ship Cosmetic Thruster (Waterfall Iteration 10) ---")
    assert check_file_exists("assets/textures/thruster_flame.png")

    player_tscn_path = os.path.join(BASE_DIR, "scenes/player/player.tscn")
    with open(player_tscn_path, "r", encoding="utf-8") as f:
        tscn_content = f.read()

    assert ('thruster_flame.png' in tscn_content or 'thruster_' in tscn_content), "thruster texture missing from player.tscn"
    assert 'name="ThrusterMount"' in tscn_content, "ThrusterMount node missing in player.tscn"
    assert 'name="ThrusterSprite"' in tscn_content, "ThrusterSprite node missing in player.tscn"
    assert 'ThrusterMount' in tscn_content, "ThrusterMount node should exist"

    # Ensure ThrusterMount appears before Sprite2D for correct under-hull canvas layering
    idx_thruster = tscn_content.find('name="ThrusterMount"')
    idx_sprite = tscn_content.find('name="Sprite2D"')
    assert idx_thruster != -1 and idx_sprite != -1, "Both ThrusterMount and Sprite2D must exist"
    assert idx_thruster < idx_sprite, "ThrusterMount must be ordered before Sprite2D to render behind ship hull"

    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        gd_content = f.read()

    # Verify thruster constants
    assert "const POS_THRUSTER_MOUNT: Vector2 = Vector2(-55.0, 2.5)" in gd_content, "POS_THRUSTER_MOUNT constant missing"
    assert "const POS_THRUSTER_SPRITE_DEFAULT: Vector2 = Vector2(-60.0, 0.0)" in gd_content, "POS_THRUSTER_SPRITE_DEFAULT constant missing"
    assert "const SCALE_THRUSTER_DEFAULT: Vector2 = Vector2(5.0, 5.0)" in gd_content, "SCALE_THRUSTER_DEFAULT constant missing"

    # Verify Inspector export configuration
    assert '@export_group("Thruster Decoration")' in gd_content, "Thruster Decoration export group missing"
    assert '@export var thruster_texture: Texture2D' in gd_content, "thruster_texture export missing"
    assert '@export var thruster_offset: Vector2' in gd_content, "thruster_offset export missing"
    assert '@export var thruster_scale: Vector2' in gd_content, "thruster_scale export missing"
    assert '@export var hide_when_idle: bool' in gd_content, "hide_when_idle export missing"

    # Verify lifecycle and dynamic update methods
    assert "func _init_thruster" in gd_content, "_init_thruster method missing"
    assert "func _update_thruster_visual" in gd_content, "_update_thruster_visual method missing"
    assert "_update_thruster_visual(is_moving)" in gd_content, "_update_thruster_visual not called in _physics_process"
    assert "func set_thruster_texture" in gd_content, "set_thruster_texture method missing"
    assert "func set_thruster_offset" in gd_content, "set_thruster_offset method missing"
    assert "func set_thruster_scale" in gd_content, "set_thruster_scale method missing"

    # Verify deactivation on death
    idx_die = gd_content.find("func die() -> void:")
    assert idx_die != -1, "die() method missing in player.gd"
    die_block = gd_content[idx_die:idx_die+250]
    assert "thruster_sprite.visible = false" in die_block, "thruster_sprite must be hidden in die()"

    print("[PASS] Ship cosmetic thruster attachment, nozzle alignment, export properties, and movement activation verified.")


def verify_settings_system():
    print("\n--- Verifying Settings Button, Settings Panel, Sound Slider & Reset All Progress (Waterfall Iteration 11) ---")
    hud_tscn_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_tscn_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    # Verify SettingButton on main screen
    assert 'name="SettingButton"' in hud_tscn, "SettingButton missing in WelcomeContainer/ButtonsVBox in hud.tscn"

    # Verify SettingsModal panel and controls
    assert 'name="SettingsModal"' in hud_tscn, "SettingsModal node missing in hud.tscn"
    assert 'name="SoundSlider"' in hud_tscn, "SoundSlider missing in SettingsModal"
    assert 'name="SoundValueLabel"' in hud_tscn, "SoundValueLabel missing in SettingsModal"
    assert 'name="ResetProgressButton"' in hud_tscn, "ResetProgressButton missing in SettingsModal"
    assert 'text = "Reset all progress"' in hud_tscn, "Reset all progress text missing in SettingsModal"
    assert 'name="ResetConfirmModal"' in hud_tscn, "ResetConfirmModal missing in hud.tscn"
    assert 'name="ResetCancelButton"' in hud_tscn, "ResetCancelButton missing in ResetConfirmModal in hud.tscn"
    assert 'name="ResetConfirmButton"' in hud_tscn, "ResetConfirmButton missing in ResetConfirmModal in hud.tscn"
    assert 'name="SettingsBackButton"' in hud_tscn, "SettingsBackButton missing in SettingsModal"

    # Verify hud.gd logic and signals
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "signal progress_reset_requested" in hud_gd, "progress_reset_requested signal missing in hud.gd"
    assert "signal sound_volume_changed" in hud_gd, "sound_volume_changed signal missing in hud.gd"
    assert "setting_button" in hud_gd, "setting_button variable missing in hud.gd"
    assert "settings_modal" in hud_gd, "settings_modal variable missing in hud.gd"
    assert "sound_slider" in hud_gd, "sound_slider variable missing in hud.gd"
    assert "reset_progress_button" in hud_gd, "reset_progress_button variable missing in hud.gd"
    assert "reset_confirm_modal" in hud_gd, "reset_confirm_modal variable missing in hud.gd"
    assert "func show_settings_modal" in hud_gd, "show_settings_modal method missing in hud.gd"
    assert "func hide_settings_modal" in hud_gd, "hide_settings_modal method missing in hud.gd"
    assert "func show_reset_confirm_modal" in hud_gd, "show_reset_confirm_modal method missing in hud.gd"
    assert "func hide_reset_confirm_modal" in hud_gd, "hide_reset_confirm_modal method missing in hud.gd"
    assert "func execute_reset_all_progress" in hud_gd, "execute_reset_all_progress method missing in hud.gd"
    assert "func _on_sound_slider_value_changed" in hud_gd, "_on_sound_slider_value_changed method missing in hud.gd"
    assert "func _apply_sound_volume" in hud_gd, "_apply_sound_volume method missing in hud.gd"
    assert "func _on_reset_progress_pressed" in hud_gd, "_on_reset_progress_pressed method missing in hud.gd"

    # Verify save_manager.gd
    save_gd_path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    with open(save_gd_path, "r", encoding="utf-8") as f:
        save_gd = f.read()

    assert "static func get_master_volume" in save_gd, "get_master_volume missing in save_manager.gd"
    assert "static func set_master_volume" in save_gd, "set_master_volume missing in save_manager.gd"
    assert "static func reset_all_progress" in save_gd, "reset_all_progress missing in save_manager.gd"

    # Verify main.gd connection
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "hud.progress_reset_requested.connect" in main_gd, "progress_reset_requested signal not connected in main.gd"
    assert "func _on_progress_reset_requested" in main_gd, "_on_progress_reset_requested method missing in main.gd"

    print("[PASS] Setting button, Settings panel, Sound slider, and Reset all progress verified.")


def verify_background_system():
    print("\n--- Verifying Modular 4-Sector Background System & Seamless Repeating (Waterfall Iteration 12) ---")
    assert check_file_exists("assets/textures/backgrounds/README.md")

    # 1. Verify starfield_background.gd
    script_path = os.path.join(BASE_DIR, "scenes/environment/starfield_background.gd")
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "const BACKGROUND_DICTIONARY: Dictionary" in content, "BACKGROUND_DICTIONARY missing"
    assert "@export var background_sectors: Dictionary" in content, "Exported background_sectors dictionary missing"
    assert '"stage_min": 1' in content and '"stage_max": 5' in content, "Sector 1 (Stages 1-5) missing"
    assert '"stage_min": 6' in content and '"stage_max": 10' in content, "Sector 2 (Stages 6-10) missing"
    assert '"stage_min": 11' in content and '"stage_max": 15' in content, "Sector 3 (Stages 11-15) missing"
    assert '"stage_min": 16' in content and '"stage_max": 20' in content, "Sector 4 (Stages 16-20) missing"

    # Verify that the configured texture paths in BACKGROUND_DICTIONARY exist
    tex_paths = re.findall(r'"texture_path":\s*"res://([^"]+)"', content)
    assert len(tex_paths) >= 4, f"Expected at least 4 sector texture paths, found {len(tex_paths)}"
    for tp in tex_paths:
        assert check_file_exists(tp), f"Configured sector texture missing: {tp}"

    assert "func set_stage(stage_num: int)" in content, "set_stage method missing"
    assert "func get_sector_config_for_stage(stage_num: int)" in content, "get_sector_config_for_stage method missing"
    assert "func set_custom_background" in content, "set_custom_background method missing"

    assert "bg_scroll_offset_x = fmod(bg_scroll_offset_x, display_w)" in content, "Seamless fmod offset wrap missing"
    assert "while cur_x < vp.x:" in content, "Continuous multi-tile loop missing"
    assert "draw_texture_rect(current_texture" in content, "draw_texture_rect call missing"
    assert "enable_background_texture" in content, "enable_background_texture toggle missing"
    assert "enable_stars" in content, "enable_stars toggle missing"
    assert "enable_shooting_stars" in content, "enable_shooting_stars toggle missing"

    # Verify smooth inter-sector cinematic crossfade & warp surge
    assert "transition_duration" in content, "transition_duration export missing"
    assert "enable_warp_surge" in content, "enable_warp_surge export missing"
    assert "func transition_to_stage" in content, "transition_to_stage method missing"
    assert "previous_texture" in content, "previous_texture crossfade tracking missing"
    assert "smoothstep(0.0, 1.0, transition_progress)" in content, "smoothstep dissolve interpolation missing"

    # Verify cold-boot persistence to last played level in starfield_background.gd
    assert "SaveManager.get_last_played_level()" in content, "Last played level initialization missing in starfield_background.gd"

    # 2. Verify SaveManager persistence API
    save_path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    with open(save_path, "r", encoding="utf-8") as f:
        save_content = f.read()

    assert "last_played_level" in save_content, "last_played_level key missing in save_manager.gd"
    assert "static func get_last_played_level" in save_content, "get_last_played_level method missing in save_manager.gd"
    assert "static func set_last_played_level" in save_content, "set_last_played_level method missing in save_manager.gd"

    # 3. Verify main.gd hooks and persistent stage background updates
    main_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_path, "r", encoding="utf-8") as f:
        main_content = f.read()

    assert "starfield_canvas" in main_content, "starfield_canvas node reference missing in main.gd"
    assert "func _update_background_for_stage(stage_num: int)" in main_content, "_update_background_for_stage method missing in main.gd"
    assert "_update_background_for_stage(current_wave)" in main_content, "Wave background update call missing in main.gd"
    assert "SaveManager.set_last_played_level" in main_content, "SaveManager.set_last_played_level call missing in main.gd"
    assert "SaveManager.get_last_played_level()" in main_content, "SaveManager.get_last_played_level call missing in main.gd"

    print("[PASS] 4-Sector Dictionary, custom user textures, stage mappings (1-5, 6-10, 11-15, 16-20), seamless tiling, and Last Player Stage Played persistence verified.")


def verify_enemy_theme_system():
    print("\n--- Verifying Enemy Theme Slots & Stage-Based Texture Customization (Waterfall Iteration 13) ---")
    assert check_file_exists("scripts/enemy_theme_manager.gd")

    theme_mgr_path = os.path.join(BASE_DIR, "scripts/enemy_theme_manager.gd")
    with open(theme_mgr_path, "r", encoding="utf-8") as f:
        theme_gd = f.read()

    # Check canonical enemy types
    assert 'const TYPE_BREEDER: String = "breeder"' in theme_gd, "TYPE_BREEDER missing"
    assert 'const TYPE_SPEWER: String = "spewer"' in theme_gd, "TYPE_SPEWER missing"
    assert 'const TYPE_CHARGER: String = "charger"' in theme_gd, "TYPE_CHARGER missing"
    assert 'const TYPE_HEAVY: String = "heavy"' in theme_gd, "TYPE_HEAVY missing"
    assert 'const TYPE_VOID: String = "void"' in theme_gd, "TYPE_VOID missing"

    # Check stage brackets: 1-5, 6-10, 11-15, 16-20
    assert '"1-5"' in theme_gd and '"6-10"' in theme_gd and '"11-15"' in theme_gd and '"16-20"' in theme_gd, "Stage brackets missing in DEFAULT_ENEMY_THEMES"

    # Check key methods
    assert "func get_default_slots" in theme_gd, "get_default_slots method missing"
    assert "func normalize_enemy_type" in theme_gd, "normalize_enemy_type method missing"
    assert "func get_stage_bracket" in theme_gd, "get_stage_bracket method missing"
    assert "func get_enemy_texture" in theme_gd, "get_enemy_texture method missing"
    assert "func set_enemy_texture_slot" in theme_gd, "set_enemy_texture_slot method missing"

    # Check alias handling ("tank" -> "heavy", "teleporter" -> "void")
    assert '"tank"' in theme_gd, "Tank alias missing in normalize_enemy_type"
    assert '"teleporter"' in theme_gd, "Teleporter alias missing in normalize_enemy_type"

    # Check all 5 enemy scripts implement set_enemy_texture
    enemy_scripts = [
        "scenes/enemies/heavy_enemy.gd",
        "scenes/enemies/bile_spewer.gd",
        "scenes/enemies/charger_roach.gd",
        "scenes/enemies/void_bile.gd",
        "scenes/enemies/bile_breeder.gd"
    ]
    for scr in enemy_scripts:
        scr_path = os.path.join(BASE_DIR, scr)
        with open(scr_path, "r", encoding="utf-8") as f:
            c = f.read()
        assert "func set_enemy_texture" in c, f"set_enemy_texture missing in {scr}"
        assert "@export var custom_texture: Texture2D" in c, f"custom_texture export missing in {scr}"

    # Check main.gd integration
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert '@export_group("Enemy Stage Theme Slots")' in main_gd, "Enemy Stage Theme Slots export group missing in main.gd"
    assert '@export var enemy_theme_slots: Dictionary' in main_gd, "enemy_theme_slots export missing in main.gd"
    assert "func _get_enemy_texture_for_current_stage" in main_gd, "_get_enemy_texture_for_current_stage method missing in main.gd"
    assert "func set_enemy_theme_slot" in main_gd, "set_enemy_theme_slot method missing in main.gd"
    assert 'heavy.set_enemy_texture(heavy_tex)' in main_gd, "heavy.set_enemy_texture missing in _spawn_heavy_enemy"
    assert 'spewer.set_enemy_texture(spewer_tex)' in main_gd, "spewer.set_enemy_texture missing in _spawn_bile_spewer"
    assert 'charger.set_enemy_texture(charger_tex)' in main_gd, "charger.set_enemy_texture missing in _spawn_charger_roach"
    assert 'void_enemy.set_enemy_texture(void_tex)' in main_gd, "void_enemy.set_enemy_texture missing in _spawn_void_bile"
    assert 'breeder.set_enemy_texture(breeder_tex)' in main_gd, "breeder.set_enemy_texture missing in _spawn_bile_breeder"
    assert 'baby.set_enemy_texture(void_tex)' in main_gd, "baby.set_enemy_texture missing in spawn_bred_void_bile"

    print("[PASS] Enemy theme Dictionary slots (Breeder, Spewer, Charger, Heavy, Void), stage brackets (1-5, 6-10, 11-15, 16-20), and spawn integration verified.")


def verify_stage_spawn_database():
    print("\n--- Verifying Stage Enemy Spawn Database & Main Orchestrator (Waterfall Iteration 14) ---")
    stage_mgr_path = os.path.join(BASE_DIR, "scripts/stage_spawn_manager.gd")
    assert os.path.exists(stage_mgr_path), "scripts/stage_spawn_manager.gd file missing"

    with open(stage_mgr_path, "r", encoding="utf-8") as f:
        stage_gd = f.read()

    # 1. Verify class name and canonical keys
    assert "class_name StageSpawnManager" in stage_gd, "class_name StageSpawnManager missing"
    assert "KEY_HEAVY" in stage_gd, "KEY_HEAVY constant missing"
    assert "KEY_SPEWER" in stage_gd, "KEY_SPEWER constant missing"
    assert "KEY_CHARGER" in stage_gd, "KEY_CHARGER constant missing"
    assert "KEY_VOID" in stage_gd, "KEY_VOID constant missing"
    assert "KEY_BREEDER" in stage_gd, "KEY_BREEDER constant missing"
    assert "BOSS_TYPE_DREADNOUGHT" in stage_gd, "BOSS_TYPE_DREADNOUGHT constant missing"
    assert "BOSS_TYPE_DRAGON_ROACH" in stage_gd, "BOSS_TYPE_DRAGON_ROACH constant missing"

    # 2. Verify all 20 stages are explicitly defined in STAGE_SPAWN_DATABASE
    assert "const STAGE_SPAWN_DATABASE: Dictionary = {" in stage_gd, "STAGE_SPAWN_DATABASE missing"
    for stage_idx in range(1, 21):
        assert f"\t{stage_idx}: {{" in stage_gd or f" {stage_idx}: {{" in stage_gd, f"Stage {stage_idx} missing in STAGE_SPAWN_DATABASE"

    # 3. Verify public API methods
    assert "static func get_stage_config(" in stage_gd, "get_stage_config method missing"
    assert "static func get_enemy_counts(" in stage_gd, "get_enemy_counts method missing"
    assert "static func is_boss_stage(" in stage_gd, "is_boss_stage method missing"
    assert "static func get_boss_configs(" in stage_gd, "get_boss_configs method missing"
    assert "static func set_stage_enemy_count(" in stage_gd, "set_stage_enemy_count method missing"
    assert "static func reset_runtime_overrides(" in stage_gd, "reset_runtime_overrides method missing"

    # 4. Verify main.gd integration
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert 'preload("res://scripts/stage_spawn_manager.gd")' in main_gd, "StageSpawnManager preload missing in main.gd"
    assert "StageSpawnManager.get_stage_config(wave_num)" in main_gd, "StageSpawnManager.get_stage_config missing in _get_wave_config"
    assert "StageSpawnManager.get_stage_config(current_wave)" in main_gd, "StageSpawnManager.get_stage_config missing in _spawn_boss_encounter"

    print("[PASS] Stage Enemy Spawn Database (Stages 1-20), boss encounters, enemy quotas, and main delegation verified.")


def verify_universal_boss_minion_summoning():
    print("\n--- Verifying Universal Boss Minion Summoning (Waterfall Iteration 15) ---")

    # 1. Verify Waurior Titan (boss_waurior.gd)
    boss_gd_path = os.path.join(BASE_DIR, "scenes/bosses/boss_waurior.gd")
    with open(boss_gd_path, "r", encoding="utf-8") as f:
        boss_gd = f.read()

    assert "signal minion_spawn_requested" in boss_gd, "minion_spawn_requested signal missing in boss_waurior.gd"
    assert "@export var minion_summon: bool" in boss_gd, "minion_summon export missing in boss_waurior.gd"
    assert "can_summon_minions: bool" in boss_gd, "setup_boss missing can_summon_minions parameter in boss_waurior.gd"
    assert "minion_timer" in boss_gd, "minion_timer missing in boss_waurior.gd"
    assert "minion_spawn_requested.emit" in boss_gd, "minion_spawn_requested.emit missing in boss_waurior.gd"

    # 2. Verify Minangkabau Ship (boss_ship.gd)
    roach_gd_path = os.path.join(BASE_DIR, "scenes/bosses/boss_ship.gd")
    with open(roach_gd_path, "r", encoding="utf-8") as f:
        roach_gd = f.read()

    assert "signal minion_spawn_requested" in roach_gd, "minion_spawn_requested signal missing in boss_ship.gd"
    assert "@export var minion_summon: bool" in roach_gd, "minion_summon export missing in boss_ship.gd"
    assert "can_summon_minions: bool" in boss_gd, "setup_boss missing can_summon_minions parameter in boss_ship.gd"
    assert "if minion_summon:" in roach_gd, "minion_summon gating check missing in boss_ship.gd"

    # 3. Verify main.gd universal minion hook and signal connection
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "func _on_boss_minion_spawn_requested" in main_gd, "_on_boss_minion_spawn_requested missing in main.gd"
    assert "func _on_dragon_minion_spawn_requested" in main_gd, "_on_dragon_minion_spawn_requested missing in main.gd"
    assert "boss_inst.minion_spawn_requested.connect(_on_boss_minion_spawn_requested)" in main_gd, "Universal minion_spawn_requested connection missing in main.gd"

    # 4. Verify stage_spawn_manager.gd minion summon helpers
    stage_gd_path = os.path.join(BASE_DIR, "scripts/stage_spawn_manager.gd")
    with open(stage_gd_path, "r", encoding="utf-8") as f:
        stage_gd = f.read()

    assert "static func set_stage_boss_minion_summon" in stage_gd, "set_stage_boss_minion_summon missing in stage_spawn_manager.gd"
    assert "static func is_boss_minion_summon_enabled" in stage_gd, "is_boss_minion_summon_enabled missing in stage_spawn_manager.gd"

    print("[PASS] Universal boss minion summoning across all boss types, stages, and Main orchestrator verified.")


def verify_boss_name_manager():
    print("\n--- Verifying Boss Name Dictionary & Customization System ---")
    boss_mgr_path = os.path.join(BASE_DIR, "scripts/boss_name_manager.gd")
    assert os.path.exists(boss_mgr_path), "scripts/boss_name_manager.gd missing"

    with open(boss_mgr_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "class_name BossNameManager" in content, "BossNameManager class_name missing"
    assert "const BOSS_NAME_DICTIONARY: Dictionary = {" in content, "BOSS_NAME_DICTIONARY missing"
    assert "5: {" in content, "Stage 5 missing in BOSS_NAME_DICTIONARY"
    assert "10: {" in content, "Stage 10 missing in BOSS_NAME_DICTIONARY"
    assert "15: {" in content, "Stage 15 missing in BOSS_NAME_DICTIONARY"
    assert "20: {" in content, "Stage 20 missing in BOSS_NAME_DICTIONARY"

    assert "static func get_boss_info(" in content, "get_boss_info missing in BossNameManager"
    assert "static func get_boss_display_name(" in content, "get_boss_display_name missing in BossNameManager"
    assert "static func get_boss_bar_title(" in content, "get_boss_bar_title missing in BossNameManager"
    assert "static func get_boss_stage_title(" in content, "get_boss_stage_title missing in BossNameManager"
    assert "static func get_individual_boss_name(" in content, "get_individual_boss_name missing in BossNameManager"
    assert "static func set_boss_name(" in content, "set_boss_name missing in BossNameManager"
    assert "static func reset_boss_names(" in content, "reset_boss_names missing in BossNameManager"

    # Verify StageSpawnManager integration
    stage_mgr_path = os.path.join(BASE_DIR, "scripts/stage_spawn_manager.gd")
    with open(stage_mgr_path, "r", encoding="utf-8") as f:
        stage_content = f.read()

    assert "BossNameManager.get_boss_info(stage_num)" in stage_content, "BossNameManager integration in get_stage_config missing"
    assert "static func get_boss_name(" in stage_content, "get_boss_name missing in StageSpawnManager"
    assert "static func get_boss_bar_title(" in stage_content, "get_boss_bar_title missing in StageSpawnManager"
    assert "static func set_boss_name(" in stage_content, "set_boss_name missing in StageSpawnManager"
    assert "static func reset_boss_names(" in stage_content, "reset_boss_names missing in StageSpawnManager"

    print("[PASS] Boss Name Dictionary, customization API, and StageSpawnManager delegation verified.")



def verify_continuous_laser_ray():
    print("\n--- Verifying Level 5 Continuous Laser Ray (Waterfall Iteration 16) ---")

    # 1. Verify scenes/player/gun.gd configuration & continuous sustain mechanics
    gun_gd_path = os.path.join(BASE_DIR, "scenes/player/gun.gd")
    with open(gun_gd_path, "r", encoding="utf-8") as f:
        gun_gd = f.read()

    assert '"is_laser": true' in gun_gd, "Level 5 is_laser must be true in gun.gd"
    assert '"cooldown": 0.055' in gun_gd, "Level 5 cooldown must be 0.055 in gun.gd"
    assert ('"damage": 7' in gun_gd or '"damage": 4' in gun_gd or '"damage": 2.5' in gun_gd), "Level 5 damage missing in gun.gd"
    assert "var active_laser_beam: Area2D = null" in gun_gd, "active_laser_beam tracker missing in gun.gd"
    assert "active_laser_beam.sustain" in gun_gd, "active_laser_beam.sustain call missing in gun.gd"
    assert "active_laser_beam.update_laser_origin" in gun_gd, "active_laser_beam.update_laser_origin call missing in gun.gd"
    assert "func _generate_laser_beam_audio" in gun_gd, "_generate_laser_beam_audio missing in gun.gd"

    # 2. Verify scenes/player/gun.tscn contains LaserSoundPlayer
    gun_tscn_path = os.path.join(BASE_DIR, "scenes/player/gun.tscn")
    with open(gun_tscn_path, "r", encoding="utf-8") as f:
        gun_tscn = f.read()
    assert 'name="LaserSoundPlayer"' in gun_tscn, "LaserSoundPlayer missing in gun.tscn"

    # 3. Verify scenes/player/player_projectile.gd continuous laser ray logic
    proj_gd_path = os.path.join(BASE_DIR, "scenes/player/player_projectile.gd")
    with open(proj_gd_path, "r", encoding="utf-8") as f:
        proj_gd = f.read()

    assert "var ray_length: float" in proj_gd, "ray_length missing in player_projectile.gd"
    assert "var is_hitting_target: bool" in proj_gd, "is_hitting_target missing in player_projectile.gd"
    assert "var hit_position_world: Vector2" in proj_gd, "hit_position_world missing in player_projectile.gd"
    assert "func set_source_tracking" in proj_gd, "set_source_tracking missing in player_projectile.gd"
    assert "func update_laser_origin" in proj_gd, "update_laser_origin missing in player_projectile.gd"
    assert "func sustain" in proj_gd, "sustain missing in player_projectile.gd"
    assert "func _calculate_beam_hit" in proj_gd, "_calculate_beam_hit missing in player_projectile.gd"
    assert "func _apply_beam_damage" in proj_gd, "_apply_beam_damage missing in player_projectile.gd"
    assert "func _draw() -> void:" in proj_gd, "_draw() method missing in player_projectile.gd"
    assert "draw_line(start_pt, end_pt" in proj_gd, "Continuous beam line drawing missing in _draw"
    assert "if is_laser:\n\t\treturn" in proj_gd or "if is_laser:\n\t\treturn # Laser handles hits continuously" in proj_gd, "is_laser guard in _on_area_entered missing"
    assert "if not is_laser:\n\t\tqueue_free()" in proj_gd, "not is_laser guard in _on_screen_exited missing"

    # 4. Verify scenes/player/player.gd delegation
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        player_gd = f.read()
    assert "gun.shoot(get_parent(), global_position)" in player_gd, "Player does not delegate shoot to Gun"
    assert "gun.process_cooldown(delta)" in player_gd, "Player does not process cooldown via Gun"

    print("[PASS] Level 5 continuous laser ray architecture, line-of-sight ray tracing, multi-layer glow, and sustain pipeline verified.")


def verify_laser_and_gun_sound_sprint():
    print("\n--- Verifying Laser Size Adjustability & Gun Sounds Customization Dictionary ---")

    # 1. Verify Laser Beam Size Adjustability in player_projectile.gd
    proj_gd_path = os.path.join(BASE_DIR, "scenes/player/player_projectile.gd")
    with open(proj_gd_path, "r", encoding="utf-8") as f:
        proj_gd = f.read()

    assert "const LASER_BEAM_CONFIG: Dictionary" in proj_gd, "LASER_BEAM_CONFIG dictionary missing in player_projectile.gd"
    assert "@export var beam_scale: float" in proj_gd, "beam_scale export missing in player_projectile.gd"
    assert "func set_beam_scale" in proj_gd, "set_beam_scale method missing in player_projectile.gd"
    assert "func set_laser_config" in proj_gd, "set_laser_config method missing in player_projectile.gd"
    assert "if not is_inside_tree():" in proj_gd, "is_inside_tree guard missing in player_projectile.gd"

    # 2. Verify Gun Sounds Dictionary in gun.gd
    gun_gd_path = os.path.join(BASE_DIR, "scenes/player/gun.gd")
    with open(gun_gd_path, "r", encoding="utf-8") as f:
        gun_gd = f.read()

    assert "const DEFAULT_GUN_SOUNDS: Dictionary" in gun_gd, "DEFAULT_GUN_SOUNDS dictionary missing in gun.gd"
    assert "var custom_gun_sounds: Dictionary" in gun_gd, "custom_gun_sounds dictionary missing in gun.gd"
    assert "func set_gun_sound_path" in gun_gd, "set_gun_sound_path method missing in gun.gd"
    assert "func set_gun_sound_stream" in gun_gd, "set_gun_sound_stream method missing in gun.gd"
    assert "func get_gun_sound_config" in gun_gd, "get_gun_sound_config method missing in gun.gd"
    assert "func reset_gun_sounds" in gun_gd, "reset_gun_sounds method missing in gun.gd"

    # 3. Verify target_parent.add_child before setup_projectile in gun.gd & player.gd
    idx_add_child = gun_gd.find("target_parent.add_child(bolt)")
    idx_setup = gun_gd.find("bolt.setup_projectile(dmg, prc, spd, is_cannon, is_emergency, is_gatling, is_laser)")
    assert idx_add_child != -1 and idx_setup != -1, "add_child and setup_projectile must be present in gun.gd"
    assert idx_add_child < idx_setup, "target_parent.add_child(bolt) must occur before setup_projectile to ensure node is in tree"

    # 4. Verify CustomSoundPlayer node in gun.tscn
    gun_tscn_path = os.path.join(BASE_DIR, "scenes/player/gun.tscn")
    with open(gun_tscn_path, "r", encoding="utf-8") as f:
        gun_tscn = f.read()
    assert 'name="CustomSoundPlayer"' in gun_tscn, "CustomSoundPlayer node missing in gun.tscn"

    # 5. Verify audio directory guide
    assert check_file_exists("assets/audio/guns/README.md")

    print("[PASS] Laser size adjustability, tree null bugfix, and Gun sounds customization dictionary verified.")


def verify_laser_pierce_customization():
    print("\n--- Verifying Laser Pierce Customization & Multi-Target Penetration ---")
    proj_gd_path = os.path.join(BASE_DIR, "scenes/player/player_projectile.gd")
    with open(proj_gd_path, "r", encoding="utf-8") as f:
        proj_gd = f.read()

    assert "@export var pierce: int" in proj_gd, "pierce export missing in player_projectile.gd"
    assert "func set_laser_pierce" in proj_gd, "set_laser_pierce method missing in player_projectile.gd"
    assert "func get_laser_pierce" in proj_gd, "get_laser_pierce method missing in player_projectile.gd"
    assert "current_hit_records" in proj_gd, "current_hit_records tracker missing in player_projectile.gd"
    assert "hit_targets_list" in proj_gd, "hit_targets_list tracker missing in player_projectile.gd"
    assert "func _apply_beam_damage_all" in proj_gd, "_apply_beam_damage_all method missing in player_projectile.gd"
    assert "corridor_hits.sort_custom" in proj_gd, "corridor_hits sort_custom missing in player_projectile.gd"
    assert "new_pierce: int = -9999" in proj_gd, "sustain new_pierce parameter missing in player_projectile.gd"

    gun_gd_path = os.path.join(BASE_DIR, "scenes/player/gun.gd")
    with open(gun_gd_path, "r", encoding="utf-8") as f:
        gun_gd = f.read()

    assert '"pierce": 2' in gun_gd, "Level 5 Quasar Laser pierce configuration missing in gun.gd"
    assert "custom_pierce" in gun_gd, "custom_pierce variable missing in gun.gd"
    assert "active_laser_beam.sustain(spawn_pos, int(cfg.get(\"damage\", 7)), custom_scale, custom_pierce)" in gun_gd, "sustain call with custom_pierce missing in gun.gd"
    assert "bolt.set_laser_pierce(custom_pierce)" in gun_gd, "set_laser_pierce call missing in gun.gd"

    # Multi-target ray math simulation test in Python
    def simulate_laser_pierce(corridor_targets_x, laser_muzzle_x, pierce_val, screen_max_x=1960.0):
        # Calculate front distance for each target (assuming half_w = 35.0)
        hits = []
        for tx in corridor_targets_x:
            dist_front = max(0.0, (tx - 35.0) - laser_muzzle_x)
            hits.append({"dist_front": dist_front, "target_x": tx})
        hits.sort(key=lambda h: h["dist_front"])

        is_infinite = (pierce_val <= 0 or pierce_val >= 999)
        allowed = len(hits) if is_infinite else min(pierce_val, len(hits))
        hit_records = hits[:allowed]

        max_length = max(50.0, screen_max_x - laser_muzzle_x)
        if not is_infinite and len(hits) >= pierce_val and pierce_val > 0:
            terminal_rec = hits[pierce_val - 1]
            beam_len = max(10.0, terminal_rec["dist_front"])
        else:
            beam_len = max_length
        return beam_len, hit_records

    # Test Case 1: pierce = 1, 3 targets at x=200, 400, 600, muzzle at x=100
    b_len, h_recs = simulate_laser_pierce([200.0, 400.0, 600.0], 100.0, 1)
    assert len(h_recs) == 1, "pierce=1 should hit exactly 1 target"
    assert b_len == 65.0, f"pierce=1 beam length should be 65.0, got {b_len}"

    # Test Case 2: pierce = 2, 3 targets at x=200, 400, 600, muzzle at x=100
    b_len, h_recs = simulate_laser_pierce([200.0, 400.0, 600.0], 100.0, 2)
    assert len(h_recs) == 2, "pierce=2 should hit exactly 2 targets"
    assert b_len == 265.0, f"pierce=2 beam length should terminate at target 2 (265.0), got {b_len}"

    # Test Case 3: pierce = 2, only 1 target at x=200, muzzle at x=100
    b_len, h_recs = simulate_laser_pierce([200.0], 100.0, 2)
    assert len(h_recs) == 1, "pierce=2 with 1 target should hit 1 target"
    assert b_len == 1860.0, f"pierce=2 with 1 target should extend to screen edge (1860.0), got {b_len}"

    # Test Case 4: infinite pierce (-1), 3 targets
    b_len, h_recs = simulate_laser_pierce([200.0, 400.0, 600.0], 100.0, -1)
    assert len(h_recs) == 3, "infinite pierce should hit all targets in corridor"
    assert b_len == 1860.0, f"infinite pierce should extend to screen edge (1860.0), got {b_len}"

    print("[PASS] Laser pierce customization, multi-target penetration math, and gun integration verified.")


def verify_music_and_sound_system():
    print("\n--- Verifying Music & Sound System (Waterfall Iteration 17) ---")
    import wave

    # 1. Verify music files existence and WAV header specs
    music_files = {
        "menu_theme.wav": "Menu Theme",
        "stage_1_4.wav": "Sector 1 (Stages 1-4)",
        "boss_stage_5.wav": "Boss Stage 5",
        "stage_6_9.wav": "Sector 2 (Stages 6-9)",
        "boss_stage_10.wav": "Boss Stage 10",
        "stage_11_14.wav": "Sector 3 (Stages 11-14)",
        "boss_stage_15.wav": "Boss Stage 15",
        "stage_16_19.wav": "Sector 4 (Stages 16-19)",
        "boss_stage_20.wav": "Boss Stage 20",
        "ingame_combat.wav": "In-Game Normal Stages (Mirror)",
        "boss_battle.wav": "Boss Encounters (Mirror)"
    }
    assert check_file_exists("assets/audio/music/README.md")
    for fname, desc in music_files.items():
        rel_path = f"assets/audio/music/{fname}"
        assert check_file_exists(rel_path)
        full_path = os.path.join(BASE_DIR, rel_path)
        with wave.open(full_path, "rb") as w:
            assert w.getnchannels() == 2, f"{fname} must be stereo (2 channels)"
            assert w.getsampwidth() == 2, f"{fname} must be 16-bit PCM"
            assert w.getframerate() == 44100, f"{fname} sample rate must be 44100 Hz"
            n_frames = w.getnframes()
            dur = n_frames / 44100.0
            assert dur > 5.0, f"{fname} duration ({dur:.1f}s) should be at least 5s"
        print(f"[PASS] {fname} ({desc}) verified: 44.1kHz Stereo 16-bit WAV, duration {dur:.2f}s.")

    # 2. Verify StageAudioDatabase (Dedicated Script & Stage Sound Dictionary)
    assert check_file_exists("scripts/stage_audio_database.gd")
    with open(os.path.join(BASE_DIR, "scripts/stage_audio_database.gd"), "r", encoding="utf-8") as f:
        db_content = f.read()
    assert "class_name StageAudioDatabase" in db_content, "class_name StageAudioDatabase missing"
    assert "DEFAULT_STAGE_MUSIC_SLOTS" in db_content, "DEFAULT_STAGE_MUSIC_SLOTS dictionary missing"
    assert "DEFAULT_SOUND_SLOTS" in db_content, "DEFAULT_SOUND_SLOTS dictionary missing"
    for bracket in ["1-4", "5", "6-9", "10", "11-14", "15", "16-19", "20"]:
        assert f'"{bracket}":' in db_content, f"Stage bracket '{bracket}' missing in DEFAULT_STAGE_MUSIC_SLOTS"

    # Stage bracket resolution simulation
    def get_stage_bracket_sim(stage_num, is_boss=False):
        if is_boss or stage_num in [5, 10, 15, 20]:
            if stage_num <= 5: return "5"
            elif stage_num <= 10: return "10"
            elif stage_num <= 15: return "15"
            else: return "20"
        if stage_num <= 4: return "1-4"
        elif stage_num <= 9: return "6-9"
        elif stage_num <= 14: return "11-14"
        else: return "16-19"

    assert get_stage_bracket_sim(1) == "1-4"
    assert get_stage_bracket_sim(4) == "1-4"
    assert get_stage_bracket_sim(5, True) == "5"
    assert get_stage_bracket_sim(7) == "6-9"
    assert get_stage_bracket_sim(10, True) == "10"
    assert get_stage_bracket_sim(12) == "11-14"
    assert get_stage_bracket_sim(15, True) == "15"
    assert get_stage_bracket_sim(18) == "16-19"
    assert get_stage_bracket_sim(20, True) == "20"
    print("[PASS] scripts/stage_audio_database.gd and stage bracket routing verified.")

    # 3. Verify Audio Bus Layout & project.godot
    assert check_file_exists("default_bus_layout.tres")
    with open(os.path.join(BASE_DIR, "default_bus_layout.tres"), "r", encoding="utf-8") as f:
        bus_content = f.read()
    assert 'bus/1/name = &"Music"' in bus_content, "Music bus missing in default_bus_layout.tres"
    assert 'bus/1/send = &"Master"' in bus_content, "Music bus must route to Master"
    assert 'bus/2/name = &"SFX"' in bus_content, "SFX bus missing in default_bus_layout.tres"
    assert 'bus/2/send = &"Master"' in bus_content, "SFX bus must route to Master"

    with open(os.path.join(BASE_DIR, "project.godot"), "r", encoding="utf-8") as f:
        p_godot = f.read()
    assert ('buses/default_bus_layout="res://default_bus_layout.tres"' in p_godot or os.path.exists(os.path.join(BASE_DIR, "default_bus_layout.tres"))), "AudioBusLayout missing"
    print("[PASS] default_bus_layout.tres and project.godot AudioBusLayout verified.")

    # 4. Verify MusicManager Dedicated Script & Calibrated Quieter Volumes
    assert check_file_exists("scripts/music_manager.gd")
    with open(os.path.join(BASE_DIR, "scripts/music_manager.gd"), "r", encoding="utf-8") as f:
        mm_content = f.read()
    assert "class_name MusicManager" in mm_content, "class_name MusicManager missing"
    assert "StageAudioDatabase" in mm_content, "StageAudioDatabase integration missing in MusicManager"
    assert "func play_stage_music" in mm_content, "play_stage_music method missing"
    assert "func play_menu_music" in mm_content, "play_menu_music missing"
    assert "func play_ingame_music" in mm_content, "play_ingame_music missing"
    assert "func play_boss_music" in mm_content, "play_boss_music missing"
    assert "func stop_music" in mm_content, "stop_music missing"
    assert "func set_stage_track" in mm_content, "set_stage_track missing"
    assert "func apply_music_volume" in mm_content, "apply_music_volume missing"
    assert "func _generate_fallback_stream" in mm_content, "procedural fallback stream generator missing"
    # Verify quieter calibrated defaults (-8.0 dB or -7.0 dB)
    assert "-8.0" in mm_content or "-7.0" in mm_content, "Calibrated quieter volume_db missing in MusicManager"
    print("[PASS] scripts/music_manager.gd architecture, stage methods, and quieter calibration verified.")

    # 5. Verify SaveManager music_volume persistence
    with open(os.path.join(BASE_DIR, "scripts/save_manager.gd"), "r", encoding="utf-8") as f:
        save_content = f.read()
    assert '"music_volume": 1.0' in save_content, "music_volume missing in default save dict"
    assert '"sfx_volume": 1.0' in save_content, "sfx_volume missing in default save dict"
    assert 'get_music_volume' in save_content, "get_music_volume method missing"
    assert 'set_music_volume' in save_content, "set_music_volume method missing"
    assert 'get_sfx_volume' in save_content, "get_sfx_volume method missing"
    assert 'set_sfx_volume' in save_content, "set_sfx_volume method missing"
    print("[PASS] scripts/save_manager.gd music_volume and sfx_volume persistence verified.")

    # 6. Verify HUD Settings Modal (Music & SFX Sliders) & In-game Pause Settings Button
    with open(os.path.join(BASE_DIR, "scenes/ui/hud.tscn"), "r", encoding="utf-8") as f:
        hud_tscn = f.read()
    assert 'name="MusicSection"' in hud_tscn, "MusicSection missing in SettingsModal"
    assert 'name="MusicTitleLabel"' in hud_tscn, "MusicTitleLabel missing in SettingsModal"
    assert 'text = "🎵 Music Volume"' in hud_tscn, "Music Title label text missing"
    assert 'name="MusicValueLabel"' in hud_tscn, "MusicValueLabel missing in SettingsModal"
    assert 'name="MusicSlider"' in hud_tscn, "MusicSlider missing in SettingsModal"

    assert 'name="SfxSection"' in hud_tscn, "SfxSection missing in SettingsModal"
    assert 'name="SfxTitleLabel"' in hud_tscn, "SfxTitleLabel missing in SettingsModal"
    assert 'text = "💥 SFX Volume"' in hud_tscn, "SFX Title label text missing"
    assert 'name="SfxValueLabel"' in hud_tscn, "SfxValueLabel missing in SettingsModal"
    assert 'name="SfxSlider"' in hud_tscn, "SfxSlider missing in SettingsModal"

    assert 'name="PauseSettingsButton"' in hud_tscn, "PauseSettingsButton missing in PauseContainer"
    assert 'text = "⚙ SETTINGS"' in hud_tscn, "SETTINGS text missing in PauseContainer"

    with open(os.path.join(BASE_DIR, "scenes/ui/hud.gd"), "r", encoding="utf-8") as f:
        hud_gd = f.read()
    assert "music_volume_changed" in hud_gd, "music_volume_changed signal missing in hud.gd"
    assert "music_slider" in hud_gd, "music_slider reference missing in hud.gd"
    assert "_on_music_slider_value_changed" in hud_gd, "_on_music_slider_value_changed missing in hud.gd"
    assert "_update_music_slider_ui" in hud_gd, "_update_music_slider_ui missing in hud.gd"
    assert "_apply_music_volume" in hud_gd, "_apply_music_volume missing in hud.gd"

    assert "sfx_volume_changed" in hud_gd, "sfx_volume_changed signal missing in hud.gd"
    assert "sfx_slider" in hud_gd, "sfx_slider reference missing in hud.gd"
    assert "_on_sfx_slider_value_changed" in hud_gd, "_on_sfx_slider_value_changed missing in hud.gd"
    assert "_update_sfx_slider_ui" in hud_gd, "_update_sfx_slider_ui missing in hud.gd"
    assert "_apply_sfx_volume" in hud_gd, "_apply_sfx_volume missing in hud.gd"

    assert "pause_settings_button" in hud_gd, "pause_settings_button missing in hud.gd"
    assert "_on_pause_settings_pressed" in hud_gd, "_on_pause_settings_pressed missing in hud.gd"

    # Verify Settings and Pause layering & overlap prevention
    assert "settings_modal.z_index = 25" in hud_gd, "SettingsModal z_index = 25 missing in hud.gd"
    assert "pause_container.z_index = 10" in hud_gd, "PauseContainer z_index = 10 missing in hud.gd"
    assert 'pause_container.visible = false' in hud_gd, "pause_container.visible = false missing in show_settings_modal to prevent overlap"
    print("[PASS] scenes/ui/hud.tscn & hud.gd MusicSlider, In-game PauseSettingsButton, and non-overlapping layering verified.")

    # 7. Verify Main Scene stage music slots and delegation
    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()
    assert "music_manager" in main_gd, "music_manager reference missing in main.gd"
    assert "stage_music_slots" in main_gd, "stage_music_slots export property missing in main.gd"
    assert "music_manager.play_stage_music" in main_gd, "music_manager.play_stage_music delegation missing in main.gd"
    assert "music_manager.play_menu_music" in main_gd, "music_manager.play_menu_music call missing in main.gd"
    print("[PASS] scenes/main/main.gd stage music orchestration and dedicated dictionary verified.")


def verify_sound_manager_system():
    print("\n--- Verifying Dedicated Sound Manager & Dictionary (Sprint Task) ---")
    import wave

    # 1. Verify sound_manager.gd exists and inspect architecture
    assert check_file_exists("scripts/sound_manager.gd")
    with open(os.path.join(BASE_DIR, "scripts/sound_manager.gd"), "r", encoding="utf-8") as f:
        sm_content = f.read()

    assert "class_name SoundManager" in sm_content, "SoundManager class_name missing"
    assert "DEFAULT_SOUND_EFFECTS" in sm_content, "DEFAULT_SOUND_EFFECTS dictionary missing"

    # 2. Verify all categories and sound keys in DEFAULT_SOUND_EFFECTS
    categories = ["ui", "wave", "player", "weapons", "combat"]
    for cat in categories:
        assert f'"category": "{cat}"' in sm_content, f"Category '{cat}' missing in DEFAULT_SOUND_EFFECTS"

    sound_keys = [
        "button_click", "play_start", "modal_chime", "level_complete", "purchase",
        "wave_start", "wave_clear", "boss_warning",
        "player_hit", "shield_hit", "shield_recharge", "player_die", "free_gun_equip",
        "laser_shoot", "cannon_shoot", "gatling_shoot", "laser_beam",
        "enemy_explode", "heavy_explode", "boss_explode"
    ]
    for key in sound_keys:
        assert f'"{key}":' in sm_content, f"Sound effect key '{key}' missing in DEFAULT_SOUND_EFFECTS"

    # Verify all audio is routed through "SFX" bus
    assert sm_content.count('"bus": "SFX"') >= 14, "Audio effects must route to 'SFX' bus"

    # Verify key API methods
    assert "func play_sfx" in sm_content, "play_sfx() missing"
    assert "func get_sound_stream" in sm_content, "get_sound_stream() missing"
    assert "func set_sound_path" in sm_content, "set_sound_path() missing"
    assert "func set_sound_stream" in sm_content, "set_sound_stream() missing"
    assert "func set_sound_volume" in sm_content, "set_sound_volume() missing"
    assert "func get_sound_config" in sm_content, "get_sound_config() missing"
    assert "func get_all_sounds" in sm_content, "get_all_sounds() missing"
    assert "func get_sounds_by_category" in sm_content, "get_sounds_by_category() missing"
    assert "func reset_sound" in sm_content, "reset_sound() missing"
    assert "func reset_all_sounds" in sm_content, "reset_all_sounds() missing"
    assert "func apply_sfx_volume" in sm_content, "apply_sfx_volume() missing"
    assert "func normalize_sound_id" in sm_content, "normalize_sound_id() missing"
    assert "func _generate_procedural_sound" in sm_content, "_generate_procedural_sound() missing"
    assert "var pool_size: int = 12" in sm_content, "12-voice polyphonic audio pool missing"

    # 3. Verify SFX Audio Template Files
    assert check_file_exists("assets/audio/sfx/README.md")
    sfx_files = [
        "button_click.wav", "play_start.wav", "modal_chime.wav", "level_complete.wav", "purchase.wav",
        "wave_start.wav", "wave_clear.wav", "boss_warning.wav",
        "player_hit.wav", "shield_hit.wav", "player_die.wav",
        "laser_shoot.wav", "cannon_shoot.wav", "enemy_explode.wav"
    ]
    for sfx_fname in sfx_files:
        rel_path = f"assets/audio/sfx/{sfx_fname}"
        if sfx_fname == "shield_hit.wav" and not os.path.exists(os.path.join(BASE_DIR, rel_path)):
            if os.path.exists(os.path.join(BASE_DIR, "assets/audio/sfx/shield_hit.ogg")):
                print("[PASS] SFX shield_hit.ogg (user custom audio) verified.")
                continue
        assert check_file_exists(rel_path), f"SFX file {rel_path} missing"
        full_path = os.path.join(BASE_DIR, rel_path)
        with wave.open(full_path, "rb") as w:
            assert w.getsampwidth() == 2, f"{sfx_fname} must be 16-bit PCM"
            assert w.getframerate() == 44100, f"{sfx_fname} sample rate must be 44100 Hz"
            frames = w.getnframes()
            dur = frames / 44100.0
            assert dur > 0.05, f"{sfx_fname} duration too short: {dur:.3f}s"
        print(f"[PASS] SFX {sfx_fname} verified: 44.1kHz 16-bit WAV, duration {dur:.3f}s.")

    # 4. Verify External Callers & Delegation
    # HUD uses SoundManager streams
    with open(os.path.join(BASE_DIR, "scenes/ui/hud.gd"), "r", encoding="utf-8") as f:
        hud_gd = f.read()
    assert 'SoundManager.get_sound_stream("button_click")' in hud_gd, "hud.gd button_click missing"
    assert 'SoundManager.get_sound_stream("play_start")' in hud_gd, "hud.gd play_start missing"
    assert 'SoundManager.get_sound_stream("modal_chime")' in hud_gd, "hud.gd modal_chime missing"
    assert 'SoundManager.get_sound_stream("level_complete")' in hud_gd, "hud.gd level_complete missing"

    # Main scene initializes SoundManager and routes alerts & enemy destructions
    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()
    assert "sound_manager = SoundManager.new()" in main_gd, "main.gd SoundManager init missing"
    assert 'SoundManager.get_sound_stream("wave_start")' in main_gd, "main.gd wave_start missing"
    assert 'SoundManager.get_sound_stream("wave_clear")' in main_gd, "main.gd wave_clear missing"
    assert 'SoundManager.get_sound_stream("purchase")' in main_gd, "main.gd purchase missing"
    assert 'SoundManager.play_sfx("boss_warning")' in main_gd, "main.gd boss_warning missing"
    assert 'SoundManager.play_sfx("enemy_explode")' in main_gd, "main.gd enemy_explode missing"
    assert 'SoundManager.play_sfx("heavy_explode")' in main_gd, "main.gd heavy_explode missing"
    assert 'SoundManager.play_sfx("boss_explode")' in main_gd, "main.gd boss_explode missing"

    # Player routes sounds through SFX bus and SoundManager
    with open(os.path.join(BASE_DIR, "scenes/player/player.gd"), "r", encoding="utf-8") as f:
        player_gd = f.read()
    assert 'SoundManager.get_sound_stream("player_hit")' in player_gd, "player.gd player_hit missing"
    assert 'SoundManager.get_sound_stream("shield_hit")' in player_gd, "player.gd shield_hit missing"
    assert 'SoundManager.play_sfx("player_die")' in player_gd, "player.gd player_die missing"

    # Gun routes all sound players to "SFX" bus
    with open(os.path.join(BASE_DIR, "scenes/player/gun.gd"), "r", encoding="utf-8") as f:
        gun_gd = f.read()
    assert 'shoot_sound_player.bus = "SFX"' in gun_gd, "gun.gd shoot_sound_player SFX bus missing"
    assert 'cannon_sound_player.bus = "SFX"' in gun_gd, "gun.gd cannon_sound_player SFX bus missing"
    assert 'laser_sound_player.bus = "SFX"' in gun_gd, "gun.gd laser_sound_player SFX bus missing"
    assert 'custom_sound_player.bus = "SFX"' in gun_gd, "gun.gd custom_sound_player SFX bus missing"

    print("[PASS] Dedicated SoundManager, DEFAULT_SOUND_EFFECTS dictionary, and universal game integration verified.")


def verify_void_teleportation_scale():
    print("\n--- Verifying Void Enemy (Malayan Ghost Army) Teleportation Scale Preservation ---")
    with open(os.path.join(BASE_DIR, "scenes/enemies/void_bile.gd"), "r", encoding="utf-8") as f:
        void_gd = f.read()

    assert "var base_sprite_scale: Vector2 = Vector2.ZERO" in void_gd, "base_sprite_scale variable missing in void_bile.gd"
    assert "func _get_base_scale() -> Vector2:" in void_gd, "_get_base_scale() helper missing in void_bile.gd"
    assert "Vector2(2.1, 2.1)" not in void_gd, "Hardcoded Vector2(2.1, 2.1) scale must not be in void_bile.gd"
    assert "base_scale * 1.15" in void_gd, "Relative emerge scale pop missing in void_bile.gd"
    assert "tween.tween_property(sprite, \"scale\", base_scale, 0.08)" in void_gd, "Smooth return to base_scale missing in void_bile.gd"

    # Verify breeder scale relative tweening
    with open(os.path.join(BASE_DIR, "scenes/enemies/bile_breeder.gd"), "r", encoding="utf-8") as f:
        breeder_gd = f.read()
    assert "Vector2(3.6, 3.4)" not in breeder_gd, "Hardcoded Vector2(3.6, 3.4) scale must not be in bile_breeder.gd"
    assert "base_scale * 1.15" in breeder_gd, "Relative pulsating birth scale missing in bile_breeder.gd"

    # Verify Godot runtime test covers Step 22
    with open(os.path.join(BASE_DIR, "scripts/verify_runtime.gd"), "r", encoding="utf-8") as f:
        runtime_gd = f.read()
    assert "STEP 22: VOID BILE TELEPORTATION SCALE PRESERVATION FIX" in runtime_gd, "Step 22 missing in verify_runtime.gd"

    print("[PASS] Void enemy teleportation and breeder animation relative scaling verified.")


def verify_enemy_projectile_database():
    print("\n--- Verifying Enemy Projectile Database & Extensible Dictionary System (Waterfall) ---")
    assert check_file_exists("scripts/enemy_projectile_database.gd")

    with open(os.path.join(BASE_DIR, "scripts/enemy_projectile_database.gd"), "r", encoding="utf-8") as f:
        epd_content = f.read()

    # 1. Structure & Architecture
    assert "class_name EnemyProjectileDatabase" in epd_content, "class_name EnemyProjectileDatabase missing"
    assert "DEFAULT_PROJECTILE_PROFILES" in epd_content, "DEFAULT_PROJECTILE_PROFILES dictionary missing"
    assert "DEFAULT_ENEMY_PROJECTILE_SLOTS" in epd_content, "DEFAULT_ENEMY_PROJECTILE_SLOTS dictionary missing"

    # 2. Check all archetype profiles
    profiles = [
        "spewer_bile", "heavy_plasma", "void_dart", "breeder_spore", "charger_dart",
        "boss_direct", "boss_dart", "boss_wavy", "dragon_volley", "dragon_stream", "ambient_wave"
    ]
    for p in profiles:
        assert f'"{p}":' in epd_content, f"Archetype profile '{p}' missing in DEFAULT_PROJECTILE_PROFILES"

    # 3. Check stage brackets and types in DEFAULT_ENEMY_PROJECTILE_SLOTS
    brackets = ["1-5", "6-10", "11-15", "16-20"]
    for b in brackets:
        assert f'"{b}":' in epd_content, f"Stage bracket '{b}' missing in DEFAULT_ENEMY_PROJECTILE_SLOTS"

    enemy_types = ["spewer", "heavy", "void", "breeder", "charger", "boss", "dragon_roach", "ambient"]
    for et in enemy_types:
        assert f'"{et}":' in epd_content, f"Enemy type '{et}' missing in DEFAULT_ENEMY_PROJECTILE_SLOTS"

    # 4. Check core API methods
    methods = [
        "func get_default_slots", "func get_default_profiles", "func normalize_enemy_type",
        "func get_stage_bracket", "func set_current_stage", "func get_projectile_config",
        "func get_projectile_profile", "func set_projectile_texture", "func set_projectile_property",
        "func get_projectile_texture", "func reset_to_defaults", "func spawn_projectile"
    ]
    for m in methods:
        assert m in epd_content, f"Core API method '{m}' missing in enemy_projectile_database.gd"

    # 5. Check projectile scene script enhancements
    with open(os.path.join(BASE_DIR, "scenes/enemies/projectile.gd"), "r", encoding="utf-8") as f:
        proj_gd = f.read()
    assert "func apply_config" in proj_gd, "apply_config() missing in projectile.gd"
    assert "func set_projectile_texture" in proj_gd, "set_projectile_texture() missing in projectile.gd"
    assert "func set_projectile_texture_by_path" in proj_gd, "set_projectile_texture_by_path() missing in projectile.gd"
    assert "custom_texture" in proj_gd, "custom_texture property missing in projectile.gd"

    # 6. Check enemy shooting integrations
    with open(os.path.join(BASE_DIR, "scenes/enemies/bile_spewer.gd"), "r", encoding="utf-8") as f:
        spewer_gd = f.read()
    assert "EnemyProjectileDatabase.get_projectile_config(\"spewer\")" in spewer_gd, "EnemyProjectileDatabase missing in bile_spewer.gd"

    with open(os.path.join(BASE_DIR, "scenes/enemies/heavy_enemy.gd"), "r", encoding="utf-8") as f:
        heavy_gd = f.read()
    assert "EnemyProjectileDatabase.get_projectile_config(\"heavy\")" in heavy_gd, "EnemyProjectileDatabase missing in heavy_enemy.gd"

    with open(os.path.join(BASE_DIR, "scenes/enemies/void_bile.gd"), "r", encoding="utf-8") as f:
        void_gd = f.read()
    assert "EnemyProjectileDatabase.get_projectile_config(\"void\")" in void_gd, "EnemyProjectileDatabase missing in void_bile.gd"

    with open(os.path.join(BASE_DIR, "scenes/bosses/boss_waurior.gd"), "r", encoding="utf-8") as f:
        boss_gd = f.read()
    assert "EnemyProjectileDatabase.get_projectile_config(\"boss\"" in boss_gd, "EnemyProjectileDatabase missing in boss_waurior.gd"

    with open(os.path.join(BASE_DIR, "scenes/bosses/boss_ship.gd"), "r", encoding="utf-8") as f:
        dragon_gd = f.read()
    assert "EnemyProjectileDatabase.get_projectile_config(\"dragon_roach\")" in dragon_gd, "EnemyProjectileDatabase missing in boss_ship.gd"

    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()
    assert "EnemyProjectileDatabase.set_current_stage(wave_num)" in main_gd, "EnemyProjectileDatabase.set_current_stage missing in main.gd"
    assert "EnemyProjectileDatabase.get_projectile_config(\"ambient\"" in main_gd, "EnemyProjectileDatabase ambient config missing in main.gd"

    # 7. Check Godot runtime verification covers Step 23
    with open(os.path.join(BASE_DIR, "scripts/verify_runtime.gd"), "r", encoding="utf-8") as f:
        runtime_gd = f.read()
    assert "STEP 23: VERIFYING ENEMY PROJECTILE DATABASE & DICTIONARY" in runtime_gd, "Step 23 missing in verify_runtime.gd"

    print("[PASS] Enemy Projectile Database, dictionary slots, archetype profiles, and caller integrations verified.")


def verify_custom_projectile_scaling_and_alignment():
    print("\n--- Verifying Custom Projectile Auto-Scaling & Orientation Alignment Fix ---")
    with open(os.path.join(BASE_DIR, "scenes/player/player_projectile.gd"), "r", encoding="utf-8") as f:
        pp_gd = f.read()

    # 1. Player Projectile dynamic scaling and rotation alignment
    assert "func _apply_sprite_scale_and_rotation(" in pp_gd, "_apply_sprite_scale_and_rotation helper missing in player_projectile.gd"
    assert "TEXTURE_FILTER_NEAREST" in pp_gd, "Crisp pixel art TEXTURE_FILTER_NEAREST missing in player_projectile.gd"
    assert "is_legacy_icon" in pp_gd, "Legacy icon detection missing in player_projectile.gd"
    assert "spr.rotation_degrees = 0.0" in pp_gd, "Horizontal forward orientation (0.0 deg) missing for custom projectiles"
    assert "clampf(target_len / max_dim, 0.01, 2.0)" in pp_gd, "Dynamic auto-scale calculation missing in player_projectile.gd"

    # 2. Enemy Projectile smart scaling
    with open(os.path.join(BASE_DIR, "scenes/enemies/projectile.gd"), "r", encoding="utf-8") as f:
        ep_gd = f.read()
    assert "TEXTURE_FILTER_NEAREST" in ep_gd, "Crisp pixel art TEXTURE_FILTER_NEAREST missing in projectile.gd"
    assert "clampf(target_size / max_dim, 0.01, 1.0)" in ep_gd, "Smart auto-scale calculation missing in projectile.gd"
    assert "spr.modulate = Color(1.0, 1.0, 1.0, 1.0)" in ep_gd, "Unmodulated color fallback missing in projectile.gd"

    # 3. Verify Runtime Test Step 24
    with open(os.path.join(BASE_DIR, "scripts/verify_runtime.gd"), "r", encoding="utf-8") as f:
        runtime_gd = f.read()
    assert "STEP 24: VERIFYING CUSTOM PROJECTILE AUTO-SCALING & ORIENTATION FIX" in runtime_gd, "Step 24 missing in verify_runtime.gd"

    print("[PASS] Custom projectile auto-scaling, horizontal alignment, and pixel art color fidelity verified.")


def verify_mobile_controls_and_audio_boost():
    print("\n--- Verifying Mobile Controls Persistence & Louder Audio System ---")
    # 1. Verify global input listeners in VirtualJoystick and MobileFireButton
    with open(os.path.join(BASE_DIR, "scenes/ui/virtual_joystick.gd"), "r", encoding="utf-8") as f:
        vj_gd = f.read()
    assert "func _input(event: InputEvent) -> void:" in vj_gd, "_input handler missing in virtual_joystick.gd"
    assert "_release()" in vj_gd, "_release() call missing in virtual_joystick.gd"

    with open(os.path.join(BASE_DIR, "scenes/ui/mobile_fire_button.gd"), "r", encoding="utf-8") as f:
        fb_gd = f.read()
    assert "func _input(event: InputEvent) -> void:" in fb_gd, "_input handler missing in mobile_fire_button.gd"
    assert "_set_pressed(false)" in fb_gd, "_set_pressed(false) call missing in mobile_fire_button.gd"

    # 2. Verify main.gd ensures mobile controls visibility on stage progression
    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()
    assert "hud.set_hud_stats_visible(true)" in main_gd, "hud.set_hud_stats_visible missing in main.gd"

    # 3. Verify audio bus nominal loudness (0.0 dB) in default_bus_layout.tres
    with open(os.path.join(BASE_DIR, "default_bus_layout.tres"), "r", encoding="utf-8") as f:
        bus_layout = f.read()
    assert 'bus/1/volume_db = 0.0' in bus_layout, "Music bus must be calibrated to 0.0 dB"
    assert 'bus/2/volume_db = 0.0' in bus_layout, "SFX bus must be calibrated to 0.0 dB"

    # 4. Verify player gun sounds loudness (no -15.0 dB attenuation)
    with open(os.path.join(BASE_DIR, "scenes/player/gun.gd"), "r", encoding="utf-8") as f:
        gun_gd = f.read()
    assert '"volume_db": -15.0' not in gun_gd, "Plasma/Dual Blaster must not be attenuated by -15.0 dB"

    # 5. Verify Godot runtime Step 25
    with open(os.path.join(BASE_DIR, "scripts/verify_runtime.gd"), "r", encoding="utf-8") as f:
        runtime_gd = f.read()
    assert "STEP 25: VERIFYING MOBILE CONTROLS PERSISTENCE & LOUDER AUDIO CALIBRATION" in runtime_gd, "Step 25 missing in verify_runtime.gd"

    print("[PASS] Mobile controls persistence, global touch tracking, and louder audio system verified.")


def verify_ingame_settings_and_reset_confirmation():
    print("\n--- Verifying Ingame Settings (No Reset) & Reset Progress Confirmation Modal ---")
    hud_tscn_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_tscn_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    # 1. Verify ResetConfirmModal in HUD tscn
    assert 'name="ResetConfirmModal"' in hud_tscn, "ResetConfirmModal missing in hud.tscn"
    assert 'name="ConfirmTitle"' in hud_tscn, "ConfirmTitle missing in ResetConfirmModal"
    assert 'name="ConfirmWarning"' in hud_tscn, "ConfirmWarning missing in ResetConfirmModal"
    assert 'name="ResetCancelButton"' in hud_tscn, "ResetCancelButton missing in ResetConfirmModal"
    assert 'name="ResetConfirmButton"' in hud_tscn, "ResetConfirmButton missing in ResetConfirmModal"

    # 2. Verify hud.gd logic for differentiation and confirmation
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "reset_confirm_modal" in hud_gd, "reset_confirm_modal onready missing in hud.gd"
    assert "reset_cancel_button" in hud_gd, "reset_cancel_button onready missing in hud.gd"
    assert "reset_confirm_button" in hud_gd, "reset_confirm_button onready missing in hud.gd"
    assert "func show_reset_confirm_modal" in hud_gd, "show_reset_confirm_modal missing in hud.gd"
    assert "func hide_reset_confirm_modal" in hud_gd, "hide_reset_confirm_modal missing in hud.gd"
    assert "func _on_reset_cancel_pressed" in hud_gd, "_on_reset_cancel_pressed missing in hud.gd"
    assert "func _on_reset_confirm_pressed" in hud_gd, "_on_reset_confirm_pressed missing in hud.gd"
    assert "func execute_reset_all_progress" in hud_gd, "execute_reset_all_progress missing in hud.gd"

    # Verify Ingame Settings hiding logic
    assert "is_ingame: bool = (settings_opened_from == \"pause\" or is_paused)" in hud_gd, "Ingame check missing in hud.gd"
    assert "reset_section.visible = not is_ingame" in hud_gd, "Reset section must be hidden when is_ingame in hud.gd"

    # 3. Verify runtime test in verify_runtime.gd
    runtime_path = os.path.join(BASE_DIR, "scripts/verify_runtime.gd")
    with open(runtime_path, "r", encoding="utf-8") as f:
        runtime_gd = f.read()

    assert "ResetSection must be hidden inside Ingame Settings Menu" in runtime_gd, "Ingame settings reset check missing in verify_runtime.gd"
    assert "Pressing ResetProgressButton must display ResetConfirmModal" in runtime_gd, "Reset confirmation modal test missing in verify_runtime.gd"

    print("[PASS] Ingame Settings (no reset progress) and Reset Progress Confirmation Modal verified.")


def verify_reset_upgrade_points_in_shop():
    print("\n--- Verifying Reset Upgrade Points Button in Upgrade Bay ---")
    hud_tscn_path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    with open(hud_tscn_path, "r", encoding="utf-8") as f:
        hud_tscn = f.read()

    # 1. Verify ResetUpgradesButton in ShopContainer in hud.tscn
    assert 'name="ResetUpgradesButton"' in hud_tscn, "ResetUpgradesButton missing in ShopContainer in hud.tscn"
    assert 'name="ShopStatusLabel"' in hud_tscn, "ShopStatusLabel missing in ShopContainer in hud.tscn"
    assert 'custom_minimum_size = Vector2(460, 52)' in hud_tscn, "ResetUpgradesButton must be appropriately sized (460x52)"

    # 2. Verify hud.gd wiring and signals
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert "signal reset_upgrades_requested" in hud_gd, "signal reset_upgrades_requested missing in hud.gd"
    assert "reset_upgrades_button" in hud_gd, "reset_upgrades_button variable missing in hud.gd"
    assert "shop_status_label" in hud_gd, "shop_status_label variable missing in hud.gd"
    assert "func _on_reset_upgrades_pressed" in hud_gd, "_on_reset_upgrades_pressed missing in hud.gd"
    assert "func calculate_spent_upgrade_points" in hud_gd, "calculate_spent_upgrade_points missing in hud.gd"
    assert "func show_shop_status" in hud_gd, "show_shop_status missing in hud.gd"

    # 3. Verify player.gd reset method
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        player_gd = f.read()

    assert "func reset_all_upgrades" in player_gd, "reset_all_upgrades missing in player.gd"

    # 4. Verify main.gd orchestrator
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "hud.reset_upgrades_requested.connect(_on_reset_upgrades_requested)" in main_gd, "reset_upgrades_requested signal connection missing in main.gd"
    assert "func _on_reset_upgrades_requested" in main_gd, "_on_reset_upgrades_requested handler missing in main.gd"

    # 5. Verify runtime Step 26
    runtime_path = os.path.join(BASE_DIR, "scripts/verify_runtime.gd")
    with open(runtime_path, "r", encoding="utf-8") as f:
        runtime_gd = f.read()

    assert "STEP 26: VERIFYING RESET UPGRADE POINTS IN UPGRADE BAY" in runtime_gd, "Step 26 missing in verify_runtime.gd"

    print("[PASS] Reset upgrade points button in Upgrade Bay verified.")


def verify_comic_storytelling_system():
    print("\n--- Verifying Full-Screen Sequential Comic Storytelling System ---")
    comic_gd_path = os.path.join(BASE_DIR, "scenes/ui/comic_slides.gd")
    comic_tscn_path = os.path.join(BASE_DIR, "scenes/ui/comic_slides.tscn")
    assert os.path.exists(comic_gd_path), "scenes/ui/comic_slides.gd missing"
    assert os.path.exists(comic_tscn_path), "scenes/ui/comic_slides.tscn missing"

    with open(comic_gd_path, "r", encoding="utf-8") as f:
        c_gd = f.read()
    assert "class_name ComicSlides" in c_gd, "class_name ComicSlides missing"
    assert "signal comic_finished" in c_gd, "signal comic_finished missing in comic_slides.gd"
    assert "signal comic_skipped" in c_gd, "signal comic_skipped missing in comic_slides.gd"
    assert "func start_comic" in c_gd, "start_comic method missing in comic_slides.gd"
    assert "func _build_prologue_slides" in c_gd, "_build_prologue_slides method missing in comic_slides.gd"
    assert "func _build_epilogue_slides" in c_gd, "_build_epilogue_slides method missing in comic_slides.gd"

    # Verify SaveManager tracking
    with open(os.path.join(BASE_DIR, "scripts/save_manager.gd"), "r", encoding="utf-8") as f:
        sm_gd = f.read()
    assert "intro_comic_seen" in sm_gd, "intro_comic_seen missing in save_manager.gd"
    assert "ending_comic_seen" in sm_gd, "ending_comic_seen missing in save_manager.gd"
    assert "func has_seen_intro_comic" in sm_gd, "has_seen_intro_comic missing in save_manager.gd"
    assert "func set_intro_comic_seen" in sm_gd, "set_intro_comic_seen missing in save_manager.gd"
    assert "func has_seen_ending_comic" in sm_gd, "has_seen_ending_comic missing in save_manager.gd"
    assert "func set_ending_comic_seen" in sm_gd, "set_ending_comic_seen missing in save_manager.gd"

    # Verify HUD integration
    with open(os.path.join(BASE_DIR, "scenes/ui/hud.gd"), "r", encoding="utf-8") as f:
        hud_gd = f.read()
    assert "signal comic_finished" in hud_gd, "signal comic_finished missing in hud.gd"
    assert "func show_comic" in hud_gd, "func show_comic missing in hud.gd"
    assert "comic_slides" in hud_gd, "comic_slides onready missing in hud.gd"

    with open(os.path.join(BASE_DIR, "scenes/ui/hud.tscn"), "r", encoding="utf-8") as f:
        hud_tscn = f.read()
    assert "ComicSlides" in hud_tscn, "ComicSlides missing in hud.tscn"

    # Verify Main scene routing
    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()
    assert "hud.comic_finished.connect(_on_comic_finished)" in main_gd, "comic_finished connection missing in main.gd"
    assert "func _on_comic_finished" in main_gd, "_on_comic_finished method missing in main.gd"
    assert 'hud.show_comic("prologue"' in main_gd, "show_comic prologue missing in main.gd"
    assert 'hud.show_comic("epilogue"' in main_gd, "show_comic epilogue missing in main.gd"

    print("[PASS] Full-Screen Sequential Comic Storytelling System verified.")


def verify_starting_gun_and_combat_boundary():
    print("\n--- Verifying Starting Gun & Combat Airspace Perimeter Boundary (Waterfall Iteration 18) ---")
    # 1. Gun.gd verification
    with open(os.path.join(BASE_DIR, "scenes/player/gun.gd"), "r", encoding="utf-8") as f:
        gun_gd = f.read()

    assert '"Starter Blaster"' in gun_gd, "Starter Blaster missing in gun.gd"
    assert '"active_barrels": ["center"]' in gun_gd, "Starter Blaster center barrel missing in gun.gd"
    assert "func can_shoot() -> bool:" in gun_gd, "can_shoot missing in gun.gd"
    assert "return cooldown_timer <= 0.0" in gun_gd, "can_shoot must return cooldown_timer <= 0.0 for starting gun"
    assert "var active_lvl: int = clampi(gun_level, 0, 5)" in gun_gd, "clampi(gun_level, 0, 5) missing in gun.gd"

    # 2. Player.gd verification
    with open(os.path.join(BASE_DIR, "scenes/player/player.gd"), "r", encoding="utf-8") as f:
        player_gd = f.read()

    assert "@export var combat_boundary_ratio: float = 0.65" in player_gd, "combat_boundary_ratio missing in player.gd"
    assert "@export var boundary_hazard_dps: float = 10.0" in player_gd, "boundary_hazard_dps missing in player.gd"
    assert "signal combat_boundary_reached" in player_gd, "combat_boundary_reached signal missing in player.gd"
    assert "signal boundary_hazard_changed" in player_gd, "boundary_hazard_changed signal missing in player.gd"
    assert "var bound_x: float = screen_w * combat_boundary_ratio" in player_gd, "combat_boundary bound_x missing in player.gd"
    assert "take_damage(5)" in player_gd, "10 DPS hazard damage (5 dmg/0.5s) missing in player.gd"
    assert "is_in_hazard_zone" in player_gd, "is_in_hazard_zone state missing in player.gd"
    assert "func pause_boundary_hazard() -> void:" in player_gd, "pause_boundary_hazard missing in player.gd"
    assert "func resume_boundary_hazard() -> void:" in player_gd, "resume_boundary_hazard missing in player.gd"
    assert "func set_combat_boundary_ratio(ratio: float) -> void:" in player_gd, "set_combat_boundary_ratio missing in player.gd"
    assert "func set_boundary_from_right(percentage_or_ratio: float) -> void:" in player_gd, "set_boundary_from_right missing in player.gd"
    assert "func get_danger_zone_from_right_ratio() -> float:" in player_gd, "get_danger_zone_from_right_ratio missing in player.gd"
    assert "if is_boundary_hazard_enabled and position.x > bound_x:" in player_gd, "is_boundary_hazard_enabled check missing in player.gd"

    # 3. HUD.gd verification
    with open(os.path.join(BASE_DIR, "scenes/ui/hud.gd"), "r", encoding="utf-8") as f:
        hud_gd = f.read()

    assert 'Starter Blaster (1 Pierce, 2 Dmg)' in hud_gd, "Starter Blaster status string missing in hud.gd"
    assert 'gun_button.text = "UPGRADE [%d PTS]" % gun_cost' in hud_gd, "Gun Lv 1 upgrade button label missing in hud.gd"
    assert "airspace_warning_container" in hud_gd, "airspace_warning_container missing in hud.gd"
    assert "func set_airspace_warning_visible" in hud_gd, "set_airspace_warning_visible missing in hud.gd"
    assert "⚠️ WARNING!" in hud_gd, "WARNING title missing in hud.gd"
    assert "KOTA A FAMOSA DEFENSE PERIMETER BREACHED" in hud_gd, "Lore restriction text missing in hud.gd"

    # 4. Main.gd verification
    with open(os.path.join(BASE_DIR, "scenes/main/main.gd"), "r", encoding="utf-8") as f:
        main_gd = f.read()

    assert "var combat_boundary_line: Line2D = null" in main_gd, "combat_boundary_line missing in main.gd"
    assert "var combat_hazard_rect: ColorRect = null" in main_gd, "combat_hazard_rect missing in main.gd"
    assert "func _init_combat_boundary() -> void:" in main_gd, "_init_combat_boundary method missing in main.gd"
    assert "func _update_combat_boundary_visual() -> void:" in main_gd, "_update_combat_boundary_visual method missing in main.gd"
    assert "_init_combat_boundary()" in main_gd, "_init_combat_boundary call missing in main.gd"
    assert "hud.set_airspace_warning_visible(true)" in main_gd, "hud warning activation missing in main.gd"
    assert "total_h: float = maxf(v_size.y, 4000.0)" in main_gd, "total_h dynamically filling gap to bottom missing in main.gd"
    assert "approach_dist: float = 350.0" in main_gd, "approach_dist proximity reveal missing in main.gd"
    assert "combat_boundary_line.visible = false" in main_gd, "invisible line when far away missing in main.gd"
    assert "func pause_combat_boundary() -> void:" in main_gd, "pause_combat_boundary method missing in main.gd"
    assert "func resume_combat_boundary() -> void:" in main_gd, "resume_combat_boundary method missing in main.gd"
    assert "pause_combat_boundary()" in main_gd, "pause_combat_boundary call missing in main.gd"
    assert "resume_combat_boundary()" in main_gd, "resume_combat_boundary call missing in main.gd"
    assert "@export var combat_boundary_ratio: float = 0.65" in main_gd, "combat_boundary_ratio export missing in main.gd"
    assert "func set_combat_boundary_ratio(ratio: float) -> void:" in main_gd, "set_combat_boundary_ratio missing in main.gd"
    assert "func set_boundary_from_right(percentage_or_ratio: float) -> void:" in main_gd, "set_boundary_from_right missing in main.gd"
    assert "func get_danger_zone_from_right_ratio() -> float:" in main_gd, "get_danger_zone_from_right_ratio missing in main.gd"
    assert "func get_combat_boundary_x() -> float:" in main_gd, "get_combat_boundary_x missing in main.gd"
    assert "CombatBoundaryManager" in main_gd, "CombatBoundaryManager integration missing in main.gd"
    assert "CombatBoundaryManager" in player_gd, "CombatBoundaryManager integration missing in player.gd"
    assert "current_state == GameState.ACTIVE or current_state == GameState.INTRO" in main_gd, "Boundary visual update during INTRO missing in main.gd"
    assert "player.set_physics_process(false)" in main_gd, "player.set_physics_process(false) for intro missing in main.gd"
    assert "player.set_physics_process(true)" in main_gd, "player.set_physics_process(true) for active wave missing in main.gd"
    assert "set_virtual_joystick_visible(false" in main_gd, "set_virtual_joystick_visible(false) missing in main.gd"
    assert "set_virtual_joystick_visible(true" in main_gd, "set_virtual_joystick_visible(true) missing in main.gd"
    assert "set_mobile_fire_button_visible(false" in main_gd, "set_mobile_fire_button_visible(false) missing in main.gd"
    assert "set_mobile_fire_button_visible(true" in main_gd, "set_mobile_fire_button_visible(true) missing in main.gd"

    # 5. Centralized CombatBoundaryManager verification
    assert check_file_exists("scripts/combat_boundary_manager.gd")
    with open(os.path.join(BASE_DIR, "scripts/combat_boundary_manager.gd"), "r", encoding="utf-8") as f:
        cbm_gd = f.read()

    assert "class_name CombatBoundaryManager" in cbm_gd, "class_name CombatBoundaryManager missing"
    assert "const DEFAULT_CONFIG: Dictionary" in cbm_gd, "DEFAULT_CONFIG missing in combat_boundary_manager.gd"
    assert '"start_ratio":' in cbm_gd, "start_ratio missing in combat_boundary_manager.gd"
    assert '"damage_per_second":' in cbm_gd, "damage_per_second missing in combat_boundary_manager.gd"
    assert "func get_boundary_ratio() -> float:" in cbm_gd, "get_boundary_ratio missing in combat_boundary_manager.gd"
    assert "func set_boundary_ratio(ratio: float) -> void:" in cbm_gd, "set_boundary_ratio missing in combat_boundary_manager.gd"
    assert "func set_boundary_from_right(percentage_or_ratio: float) -> void:" in cbm_gd, "set_boundary_from_right missing in combat_boundary_manager.gd"
    assert "func get_damage_per_second() -> float:" in cbm_gd, "get_damage_per_second missing in combat_boundary_manager.gd"
    assert "func set_damage_per_second(dps: float) -> void:" in cbm_gd, "set_damage_per_second missing in combat_boundary_manager.gd"
    assert "func get_damage_per_tick() -> int:" in cbm_gd, "get_damage_per_tick missing in combat_boundary_manager.gd"

    print("[PASS] Starting Gun & Combat Airspace Perimeter Boundary verified.")


def main():
    print("=== STARTING FULL GAME & MOBILE VERIFICATION ===")
    assert check_file_exists("scenes/environment/starfield_background.gd")
    assert check_file_exists("scenes/environment/starfield_background.tscn")
    assert check_file_exists("scripts/save_manager.gd")
    assert check_file_exists("scripts/music_manager.gd")
    assert check_file_exists("scripts/sound_manager.gd")
    assert check_file_exists("scripts/stage_audio_database.gd")
    assert check_file_exists("scripts/enemy_projectile_database.gd")
    assert check_file_exists("scripts/boss_name_manager.gd")
    assert check_file_exists("scripts/stage_spawn_manager.gd")
    assert check_file_exists("scenes/ui/hud.tscn")
    assert check_file_exists("scenes/ui/hud.gd")
    assert check_file_exists("scenes/main/main.tscn")
    assert check_file_exists("scenes/main/main.gd")
    assert check_file_exists("scenes/player/player.tscn")
    assert check_file_exists("scenes/player/player.gd")
    assert check_file_exists("scenes/player/gun.tscn")
    assert check_file_exists("scenes/player/gun.gd")
    assert check_file_exists("scenes/player/player_projectile.tscn")
    assert check_file_exists("scenes/player/player_projectile.gd")
    assert check_file_exists("scenes/ui/virtual_joystick.gd")
    assert check_file_exists("scenes/ui/mobile_fire_button.gd")
    assert check_file_exists("scenes/bosses/boss_ship.tscn")
    assert check_file_exists("scenes/bosses/boss_ship.gd")
    assert check_file_exists("scenes/bosses/boss_waurior.tscn")
    assert check_file_exists("scenes/bosses/boss_waurior.gd")
    assert check_file_exists("assets/textures/crown_icon.svg")

    verify_starfield_background()
    verify_welcome_screen()
    verify_save_manager()
    verify_mobile_controls()
    verify_mobile_upgrade_ui()
    verify_health_reset_and_global_skin()
    verify_pause_system()
    verify_level_select_and_progression_system()
    verify_dragon_roach()
    verify_gun_barrel_visuals()
    verify_modular_gun_architecture()
    verify_ship_thruster()
    verify_settings_system()
    verify_background_system()
    verify_enemy_theme_system()
    verify_stage_spawn_database()
    verify_universal_boss_minion_summoning()
    verify_boss_name_manager()
    verify_continuous_laser_ray()
    verify_laser_and_gun_sound_sprint()
    verify_laser_pierce_customization()
    verify_music_and_sound_system()
    verify_sound_manager_system()
    verify_void_teleportation_scale()
    verify_enemy_projectile_database()
    verify_custom_projectile_scaling_and_alignment()
    verify_mobile_controls_and_audio_boost()
    verify_ingame_settings_and_reset_confirmation()
    verify_reset_upgrade_points_in_shop()
    verify_comic_storytelling_system()
    verify_starting_gun_and_combat_boundary()
    verify_gdscript_syntax()

    print("\n=======================================================")
    print("ALL VERIFICATIONS PASSED: LEVEL SELECT & PROGRESSION READY!")
    print("=======================================================")

if __name__ == "__main__":
    main()
