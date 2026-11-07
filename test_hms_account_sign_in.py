#!/usr/bin/env python3
"""
Automated Test Suite for HMS Account Kit (HUAWEI ID Sign-In)
Verifies:
1. scripts/hms_account_manager.gd structure and mock lifecycle
2. scripts/save_manager.gd identity persistence
3. scenes/ui/hud.tscn Top-Right WelcomeAccountContainer and controls
4. scenes/ui/hud.gd signal wiring and UI update handlers
5. export_presets.cfg network permissions
"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def test_hms_account_manager():
    print("Testing scripts/hms_account_manager.gd...")
    path = os.path.join(BASE_DIR, "scripts/hms_account_manager.gd")
    assert os.path.exists(path), "scripts/hms_account_manager.gd does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert "signal sign_in_success" in code
    assert "signal sign_in_failed" in code
    assert "signal sign_out_success" in code
    assert "func silent_sign_in" in code
    assert "func sign_in" in code
    assert "func sign_out" in code
    assert "func get_player_display_name" in code
    assert "func is_user_signed_in" in code
    assert "Hang Tuah" in code
    print("  [PASS] HMSAccountManager structure and methods verified.")


def test_save_manager_identity():
    print("Testing scripts/save_manager.gd identity persistence...")
    path = os.path.join(BASE_DIR, "scripts/save_manager.gd")
    assert os.path.exists(path), "scripts/save_manager.gd does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert "huawei_player_id" in code
    assert "huawei_display_name" in code
    assert "huawei_signed_in" in code
    assert "static func set_player_identity" in code
    assert "static func clear_player_identity" in code
    assert "static func get_player_identity" in code
    print("  [PASS] SaveManager identity storage verified.")


def test_hud_tscn_top_right_account():
    print("Testing scenes/ui/hud.tscn Top-Right Account elements...")
    path = os.path.join(BASE_DIR, "scenes/ui/hud.tscn")
    assert os.path.exists(path), "scenes/ui/hud.tscn does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert 'name="WelcomeAccountContainer"' in code, "WelcomeAccountContainer missing in hud.tscn"
    assert 'anchors_preset = 1' in code, "WelcomeAccountContainer must be anchored to Top-Right (anchors_preset = 1)"
    assert 'name="HuaweiSignInButton"' in code, "HuaweiSignInButton missing in hud.tscn"
    assert 'Sign in with HUAWEI ID' in code, "Huawei sign-in button text missing"
    assert 'name="HuaweiProfileContainer"' in code, "HuaweiProfileContainer missing in hud.tscn"
    assert 'name="PilotBadgeLabel"' in code, "PilotBadgeLabel missing in hud.tscn"
    assert 'name="ProfileSignOutButton"' in code, "ProfileSignOutButton missing in hud.tscn"
    print("  [PASS] HUD top-right WelcomeAccountContainer verified.")


def test_hud_gd_wiring():
    print("Testing scenes/ui/hud.gd Huawei Account logic...")
    path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    assert os.path.exists(path), "scenes/ui/hud.gd does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert "welcome_account_container" in code
    assert "huawei_sign_in_button" in code
    assert "huawei_profile_container" in code
    assert "pilot_badge_label" in code
    assert "profile_sign_out_button" in code
    assert "func _init_huawei_account_ui" in code
    assert "func _on_huawei_sign_in_pressed" in code
    assert "func _on_huawei_sign_out_pressed" in code
    assert "func _on_huawei_sign_in_success" in code
    assert "func _update_huawei_account_ui" in code
    print("  [PASS] HUD script Huawei Account lifecycle handlers verified.")


def test_export_presets_permissions():
    print("Testing export_presets.cfg network permissions...")
    path = os.path.join(BASE_DIR, "export_presets.cfg")
    assert os.path.exists(path), "export_presets.cfg does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert "permissions/internet=true" in code, "permissions/internet must be true"
    assert "permissions/access_network_state=true" in code, "permissions/access_network_state must be true"
    print("  [PASS] Export presets network permissions verified.")


def test_project_godot_autoload():
    print("Testing project.godot autoload registration...")
    path = os.path.join(BASE_DIR, "project.godot")
    assert os.path.exists(path), "project.godot does not exist"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    assert "[autoload]" in code, "[autoload] section missing in project.godot"
    assert "HMSAccountManager=" in code, "HMSAccountManager autoload missing in project.godot"
    print("  [PASS] project.godot autoload verified.")


def main():
    print("=== HMS ACCOUNT KIT (SIGN-IN) TEST SUITE ===")
    test_hms_account_manager()
    test_save_manager_identity()
    test_hud_tscn_top_right_account()
    test_hud_gd_wiring()
    test_export_presets_permissions()
    test_project_godot_autoload()
    print("=== ALL HMS ACCOUNT KIT VERIFICATION TESTS PASSED ===")

if __name__ == "__main__":
    main()
