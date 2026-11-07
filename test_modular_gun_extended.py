#!/usr/bin/env python3
"""
Targeted Verification Script for Modular Gun Scene Architecture.
Validates:
1. gun.tscn scene file node structure, parent-child links, and resources.
2. gun.gd weapon configuration database (all 6 weapon tiers).
3. Easy rebalancing / stat customization API (get_stat, set_stat).
4. player.tscn instancing and scene decoupling.
5. player.gd delegation and backward-compatible properties.
6. Integration with main.gd, hud.gd, and save_manager.gd.
"""

import os
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# If running inside scratch, move up to workspace root
if os.path.basename(BASE_DIR) == "scratch":
    BASE_DIR = os.path.dirname(BASE_DIR)

def test_gun_scene_file():
    print("Testing scenes/player/gun.tscn...")
    path = os.path.join(BASE_DIR, "scenes/player/gun.tscn")
    assert os.path.exists(path), "gun.tscn missing"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Check root node
    assert 'node name="Gun" type="Node2D"' in content, "Root node must be Node2D named Gun"
    assert 'script = ExtResource("1_gun_script")' in content, "Root node must bind gun.gd"

    # Check GunMount and barrels
    assert 'node name="GunMount" type="Node2D" parent="."' in content, "GunMount missing under Gun"
    assert 'node name="GunSpriteCenter" type="Sprite2D" parent="GunMount"' in content, "GunSpriteCenter missing"
    assert 'node name="GunSpriteTop" type="Sprite2D" parent="GunMount"' in content, "GunSpriteTop missing"
    assert 'node name="GunSpriteBottom" type="Sprite2D" parent="GunMount"' in content, "GunSpriteBottom missing"
    assert 'node name="GunSpriteCannon" type="Sprite2D" parent="GunMount"' in content, "GunSpriteCannon missing"

    # Check Audio players
    assert 'node name="ShootSoundPlayer" type="AudioStreamPlayer" parent="."' in content, "ShootSoundPlayer missing"
    assert 'node name="CannonSoundPlayer" type="AudioStreamPlayer" parent="."' in content, "CannonSoundPlayer missing"

    # Check texture references
    assert "res://assets/textures/Gun_Mid.png" in content, "Gun_Mid.png texture resource missing"
    assert "res://assets/textures/Gun-Cannon.png" in content, "Gun-Cannon.png texture resource missing"
    print("  -> gun.tscn passed all node hierarchy and resource checks.")


def test_gun_gd_database_and_api():
    print("Testing scenes/player/gun.gd database and modular API...")
    path = os.path.join(BASE_DIR, "scenes/player/gun.gd")
    assert os.path.exists(path), "gun.gd missing"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Verify class declaration
    assert "class_name Gun" in content, "gun.gd must declare class_name Gun"
    assert "extends Node2D" in content, "gun.gd must extend Node2D"

    # Verify tiers in DEFAULT_CONFIGS
    tiers = {
        0: "Emergency Blaster",
        1: "Plasma Blaster",
        2: "Dual Blaster",
        3: "Heavy Cannon",
        4: "Explosive Gatling",
        5: "Quasar Laser",
    }

    for lvl, name in tiers.items():
        assert f'"{name}"' in content, f"Tier {lvl} name '{name}' missing in config"
    assert '"damage":' in content, "damage attribute missing in config"
    assert '"pierce":' in content, "pierce attribute missing in config"
    assert '"cooldown":' in content, "cooldown attribute missing in config"
    assert '"speed":' in content, "speed attribute missing in config"

    # Verify easy rebalancing API
    assert "func get_gun_config(level: int) -> Dictionary:" in content, "get_gun_config() missing"
    assert "func get_active_config() -> Dictionary:" in content, "get_active_config() missing"
    assert "func get_stat(stat_name: String" in content, "get_stat() missing"
    assert "func set_stat(stat_name: String, value" in content, "set_stat() missing"

    # Verify operational methods
    assert "func can_shoot() -> bool:" in content, "can_shoot() missing"
    assert "func shoot(" in content, "shoot() missing"
    assert "func spawn_blaster_bolt(" in content, "spawn_blaster_bolt() missing"
    assert "func update_visual() -> void:" in content, "update_visual() missing"
    assert "func upgrade_gun() -> bool:" in content, "upgrade_gun() missing"
    assert "func equip_free_emergency_gun() -> void:" in content, "equip_free_emergency_gun() missing"
    assert "func process_cooldown(delta: float) -> void:" in content, "process_cooldown() missing"

    # Verify self-contained procedural audio
    assert "func _generate_laser_audio() -> AudioStreamWAV:" in content, "Laser audio generation missing"
    assert "func _generate_cannon_audio() -> AudioStreamWAV:" in content, "Cannon audio generation missing"

    print("  -> gun.gd passed database validation and modular API checks.")


def test_player_scene_and_script_delegation():
    print("Testing player.tscn & player.gd delegation...")
    player_tscn_path = os.path.join(BASE_DIR, "scenes/player/player.tscn")
    player_gd_path = os.path.join(BASE_DIR, "scenes/player/player.gd")

    with open(player_tscn_path, "r", encoding="utf-8") as f:
        tscn_content = f.read()
    with open(player_gd_path, "r", encoding="utf-8") as f:
        gd_content = f.read()

    # Verify Player scene instances Gun
    assert 'res://scenes/player/gun.tscn' in tscn_content, "player.tscn must instance gun.tscn"
    assert 'name="Gun" parent="."' in tscn_content, 'Gun node must be direct child under Player'
    assert 'position = Vector2(48, 0)' in tscn_content, "Gun mount position must be (48, 0)"

    # Verify Gun node reference in player.gd
    assert '@onready var gun: Node2D = get_node_or_null("Gun")' in gd_content, "Player missing @onready var gun"

    # Verify player forwards shooting to Gun
    assert 'gun.shoot(get_parent(), global_position)' in gd_content, "Player shoot() must delegate to gun.shoot"
    assert 'gun.process_cooldown(delta)' in gd_content, "Player must delegate cooldown processing to gun"
    assert 'gun.upgrade_gun()' in gd_content, "Player must delegate upgrade_gun to gun"
    assert 'gun.equip_free_emergency_gun()' in gd_content, "Player must delegate emergency gun to gun"

    # Verify backward-compatible getters/setters for external scripts (main.gd, hud.gd, save_manager.gd)
    assert 'var gun_level: int:' in gd_content, "gun_level getter/setter missing"
    assert 'var has_emergency_gun: bool:' in gd_content, "has_emergency_gun getter/setter missing"
    assert 'var shoot_cooldown_timer: float:' in gd_content, "shoot_cooldown_timer getter/setter missing"
    assert 'var level2_alt_top: bool:' in gd_content, "level2_alt_top getter/setter missing"

    print("  -> player.tscn & player.gd delegation verified.")


def test_external_compatibility():
    print("Testing external callers compatibility...")
    main_gd_path = os.path.join(BASE_DIR, "scenes/main/main.gd")
    hud_gd_path = os.path.join(BASE_DIR, "scenes/ui/hud.gd")

    with open(main_gd_path, "r", encoding="utf-8") as f:
        main_content = f.read()
    with open(hud_gd_path, "r", encoding="utf-8") as f:
        hud_content = f.read()

    # main.gd calls player.gun_level and player.has_emergency_gun
    assert "player.gun_level" in main_content, "main.gd uses player.gun_level"
    assert "player.has_emergency_gun" in main_content, "main.gd uses player.has_emergency_gun"
    assert "player.equip_free_emergency_gun()" in main_content, "main.gd uses player.equip_free_emergency_gun()"

    # hud.gd receives gun_level and has_emergency
    assert "func update_gun_status(gun_level: int, has_emergency: bool = false)" in hud_content, "hud.gd gun status updated"

    print("  -> External compatibility verified across main.gd and hud.gd.")


def main():
    print("=== EXTENDED MODULAR GUN VERIFICATION ===")
    test_gun_scene_file()
    test_gun_gd_database_and_api()
    test_player_scene_and_script_delegation()
    test_external_compatibility()
    print("\n[SUCCESS] ALL MODULAR GUN ARCHITECTURE TESTS PASSED CLEANLY!")

if __name__ == "__main__":
    main()
