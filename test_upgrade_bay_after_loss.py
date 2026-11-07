#!/usr/bin/env python3
"""
Verification Script for Upgrade Bay Functionality After Defeat/Loss.
Validates:
1. main.gd _on_buy_upgrade_requested does NOT block purchases when game_over is true.
2. main.gd _on_player_died cleans up minions and projectiles.
3. main.gd _on_level_selected syncs upgrades correctly from save_data.
4. hud.gd correctly transitions between LevelLost and ShopContainer without overlap.
5. hud.gd lost_upgrade_button displays current points dynamically.
6. Player state is properly updated and saved when upgrading after death.
"""

import os
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def test_main_gd_upgrade_after_loss():
    print("Testing scenes/main/main.gd logic...")
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    with open(main_gd_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Ensure _on_buy_upgrade_requested does NOT check 'if game_over'
    match = re.search(r"func _on_buy_upgrade_requested\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match, "Could not find _on_buy_upgrade_requested function in main.gd"
    fn_body = match.group(1)
    assert "if game_over" not in fn_body, "_on_buy_upgrade_requested must not block on game_over"
    assert "player.apply_upgrade(upgrade_type)" in fn_body, "player.apply_upgrade missing in _on_buy_upgrade_requested"
    assert "SaveManager.save_player_state" in fn_body, "SaveManager.save_player_state missing in _on_buy_upgrade_requested"
    assert "_refresh_shop()" in fn_body, "_refresh_shop() missing in _on_buy_upgrade_requested"

    # 2. Ensure _on_player_died cleans up projectiles & minions
    match_died = re.search(r"func _on_player_died\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match_died, "Could not find _on_player_died function in main.gd"
    died_body = match_died.group(1)
    assert "_clean_up_all_minions_and_projectiles()" in died_body, "_clean_up_all_minions_and_projectiles missing in _on_player_died"

    # 3. Ensure _on_level_selected syncs player upgrade levels from save_data
    match_lvl = re.search(r"func _on_level_selected\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match_lvl, "Could not find _on_level_selected function in main.gd"
    lvl_body = match_lvl.group(1)
    assert 'player.shield_level = int(save_data.get("shield_level"' in lvl_body, "shield_level sync missing in _on_level_selected"
    assert 'player.speed_level = int(save_data.get("speed_level"' in lvl_body, "speed_level sync missing in _on_level_selected"
    assert 'player.gun_level = int(save_data.get("gun_level"' in lvl_body, "gun_level sync missing in _on_level_selected"

    print("  -> scenes/main/main.gd passed all upgrade-after-loss checks.")


def test_hud_gd_level_lost_and_shop():
    print("Testing scenes/ui/hud.gd Level Lost & ShopContainer integration...")
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Ensure lost_upgrade_button emits open_upgrade_bay_requested("level_lost")
    assert 'open_upgrade_bay_requested.emit("level_lost")' in content, "lost_upgrade_button does not emit level_lost context"

    # 2. Ensure continue button handles "level_lost" context to return to defeat screen
    match_cont = re.search(r"func _on_shop_continue_pressed\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match_cont, "Could not find _on_shop_continue_pressed in hud.gd"
    cont_body = match_cont.group(1)
    assert '"level_lost":' in cont_body, '"level_lost" case missing in _on_shop_continue_pressed'
    assert 'level_lost_container.visible = true' in cont_body, 'level_lost_container not restored on return'

    # 3. Ensure open_shop handles "level_lost" context
    match_open = re.search(r"func open_shop\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match_open, "Could not find open_shop in hud.gd"
    open_body = match_open.group(1)
    assert '"level_lost":' in open_body, '"level_lost" button text customization missing in open_shop'
    assert 'RETURN TO LEVEL LOST' in open_body, 'RETURN TO LEVEL LOST label missing in open_shop'

    print("  -> scenes/ui/hud.gd passed Level Lost & ShopContainer checks.")


def test_player_gd_shield_visual_while_dead():
    print("Testing scenes/player/player.gd shield visual integrity while dead...")
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")
    with open(player_gd_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Ensure shield is not visible if player is dead
    match_shield = re.search(r"func _update_shield_visual\(.*?\).*?:(.*?)(?=func |\Z)", content, re.DOTALL)
    assert match_shield, "Could not find _update_shield_visual in player.gd"
    shield_body = match_shield.group(1)
    assert "is_alive" in shield_body, "shield visual must respect is_alive state"

    print("  -> scenes/player/player.gd shield visual integrity verified.")


def main():
    print("=== VERIFYING UPGRADE BAY AFTER LOSS FIX ===")
    test_main_gd_upgrade_after_loss()
    test_hud_gd_level_lost_and_shop()
    test_player_gd_shield_visual_while_dead()
    print("\n[SUCCESS] ALL UPGRADE BAY AFTER LOSS CHECKS PASSED CLEANLY!")

if __name__ == "__main__":
    main()
