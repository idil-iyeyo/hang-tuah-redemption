# scripts/enemy_projectile_database.gd
class_name EnemyProjectileDatabase
extends RefCounted

## Master Enemy Projectile Database & Extensible Dictionary System
## Provides centralized Dictionary slots for enemy projectiles across all enemy archetypes:
## - Spewer (Bile Spewer - toxic radial spread / bile shots)
## - Heavy / Tank (Heavy Enemy - heavy plasma bolts)
## - Void / Teleporter (Void Bile - high speed void darts)
## - Breeder (Bile Breeder - optional spore projectiles)
## - Charger (Charger Roach - optional ramming darts)
## - Boss / Dreadnought Titan (Direct spread, wavy bolts, fast darts)
## - Dragon Roach Queen (Radial fan fireballs, stream embers)
## - Ambient / Wave (Environmental stage projectiles)
##
## Mapped across 4 stage groups (matching the 4 sector backgrounds):
## - Stages 1-5 (Sector 1: Deep Nebula)
## - Stages 6-10 (Sector 2: Cosmic Rift)
## - Stages 11-15 (Sector 3: Asteroid Belt)
## - Stages 16-20 (Sector 4: Void Citadel)

# Canonical Enemy Type Constants
const TYPE_SPEWER: String = "spewer"
const TYPE_HEAVY: String = "heavy"
const TYPE_VOID: String = "void"
const TYPE_BREEDER: String = "breeder"
const TYPE_CHARGER: String = "charger"
const TYPE_BOSS: String = "boss"
const TYPE_DRAGON_ROACH: String = "dragon_roach"
const TYPE_AMBIENT: String = "ambient"

const ALL_PROJECTILE_ENEMY_TYPES: Array[String] = [
	TYPE_SPEWER,
	TYPE_HEAVY,
	TYPE_VOID,
	TYPE_BREEDER,
	TYPE_CHARGER,
	TYPE_BOSS,
	TYPE_DRAGON_ROACH,
	TYPE_AMBIENT
]

const ALL_STAGE_BRACKETS: Array[String] = [
	"1-5",
	"6-10",
	"11-15",
	"16-20"
]

# MovementType Mirror (0: DIRECT, 1: WAVY, 2: ACCELERATING, 3: FAST_DART)
const MOVE_DIRECT: int = 0
const MOVE_WAVY: int = 1
const MOVE_ACCELERATING: int = 2
const MOVE_FAST_DART: int = 3

## Master Archetype Profiles
const DEFAULT_PROJECTILE_PROFILES: Dictionary = {
	"spewer_bile": {
		"name": "Spewer Acidic Bile",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png", # Empty string defaults to icon.svg / base sprite
		"scale": Vector2(0.32, 0.32),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 430.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "laser_shoot",
		"is_bile_shot": true,
		"is_zoning_shot": false
	},
	"heavy_plasma": {
		"name": "Heavy Plasma Bolt",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
		"scale": Vector2(0.30, 0.30),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 420.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "cannon_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"void_dart": {
		"name": "Void Dart",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
		"scale": Vector2(0.35, 0.22),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 490.0,
		"movement_type": MOVE_FAST_DART,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "laser_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": true
	},
	"breeder_spore": {
		"name": "Breeder Spore",
		"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
		"scale": Vector2(0.28, 0.28),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 15,
		"speed": 360.0,
		"movement_type": MOVE_WAVY,
		"wave_frequency": 4.0,
		"wave_amplitude": 40.0,
		"acceleration_rate": 300.0,
		"sound_id": "laser_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"charger_dart": {
		"name": "Charger Dart",
		"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
		"scale": Vector2(0.30, 0.30),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 25,
		"speed": 520.0,
		"movement_type": MOVE_ACCELERATING,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 420.0,
		"sound_id": "cannon_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"boss_direct": {
		"name": "Titan Heavy Salvo",
		"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
		"scale": Vector2(0.35, 0.35),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 440.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.8,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "cannon_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"boss_dart": {
		"name": "Titan Enraged Dart",
		"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
		"scale": Vector2(0.38, 0.24),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 560.0,
		"movement_type": MOVE_FAST_DART,
		"wave_frequency": 4.8,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "laser_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": true
	},
	"boss_wavy": {
		"name": "Titan Plasma Wave",
		"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
		"scale": Vector2(0.36, 0.36),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 400.0,
		"movement_type": MOVE_WAVY,
		"wave_frequency": 4.8,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "cannon_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"dragon_volley": {
		"name": "Dragon Flame Volley",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
		"scale": Vector2(0.36, 0.36),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 460.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "cannon_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"dragon_stream": {
		"name": "Dragon Flame Stream",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
		"scale": Vector2(0.32, 0.32),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 520.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "laser_shoot",
		"is_bile_shot": false,
		"is_zoning_shot": false
	},
	"ambient_wave": {
		"name": "Ambient Wave Bullet",
		"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
		"scale": Vector2(0.30, 0.30),
		"modulate": Color(1.0, 1.0, 1.0, 1.0),
		"damage": 20,
		"speed": 450.0,
		"movement_type": MOVE_DIRECT,
		"wave_frequency": 4.5,
		"wave_amplitude": 45.0,
		"acceleration_rate": 380.0,
		"sound_id": "",
		"is_bile_shot": false,
		"is_zoning_shot": false
	}
}

## Master Default Projectile Slots per Stage Group (1-5, 6-10, 11-15, 16-20)
## Users can easily alter any slot or set custom texture paths ("res://...").
const DEFAULT_ENEMY_PROJECTILE_SLOTS: Dictionary = {
	"1-5": {
		"spewer": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.32, 0.32),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 430.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": true,
			"is_zoning_shot": false
		},
		"heavy": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 420.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"void": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.22),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 490.0,
			"movement_type": MOVE_FAST_DART,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": true
		},
		"breeder": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.28, 0.28),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 15,
			"speed": 360.0,
			"movement_type": MOVE_WAVY,
			"wave_frequency": 4.0,
			"wave_amplitude": 40.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"charger": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 25,
			"speed": 520.0,
			"movement_type": MOVE_ACCELERATING,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"boss": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.35),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 440.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.8,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"dragon_roach": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.36, 0.36),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 460.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"ambient": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 450.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "",
			"is_bile_shot": false,
			"is_zoning_shot": false
		}
	},
	"6-10": {
		"spewer": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.32, 0.32),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 430.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": true,
			"is_zoning_shot": false
		},
		"heavy": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 420.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"void": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.22),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 490.0,
			"movement_type": MOVE_FAST_DART,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": true
		},
		"breeder": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.28, 0.28),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 15,
			"speed": 360.0,
			"movement_type": MOVE_WAVY,
			"wave_frequency": 4.0,
			"wave_amplitude": 40.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"charger": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 25,
			"speed": 520.0,
			"movement_type": MOVE_ACCELERATING,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"boss": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.35),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 440.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.8,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"dragon_roach": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.36, 0.36),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 460.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"ambient": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 450.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "",
			"is_bile_shot": false,
			"is_zoning_shot": false
		}
	},
	"11-15": {
		"spewer": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.32, 0.32),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 430.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": true,
			"is_zoning_shot": false
		},
		"heavy": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 420.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"void": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.35, 0.22),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 490.0,
			"movement_type": MOVE_FAST_DART,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": true
		},
		"breeder": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.28, 0.28),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 15,
			"speed": 360.0,
			"movement_type": MOVE_WAVY,
			"wave_frequency": 4.0,
			"wave_amplitude": 40.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"charger": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 25,
			"speed": 520.0,
			"movement_type": MOVE_ACCELERATING,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"boss": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.35),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 440.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.8,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"dragon_roach": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.36, 0.36),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 460.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"ambient": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 450.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "",
			"is_bile_shot": false,
			"is_zoning_shot": false
		}
	},
	"16-20": {
		"spewer": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.32, 0.32),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 430.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": true,
			"is_zoning_shot": false
		},
		"heavy": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 420.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"void": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.35, 0.22),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 490.0,
			"movement_type": MOVE_FAST_DART,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": true
		},
		"breeder": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.28, 0.28),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 15,
			"speed": 360.0,
			"movement_type": MOVE_WAVY,
			"wave_frequency": 4.0,
			"wave_amplitude": 40.0,
			"sound_id": "laser_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"charger": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 25,
			"speed": 520.0,
			"movement_type": MOVE_ACCELERATING,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"boss": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.35, 0.35),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 440.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.8,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"dragon_roach": {
			"texture": "res://assets/textures/projectiles/Bullet 2 - Enemy.png",
			"scale": Vector2(0.36, 0.36),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 460.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "cannon_shoot",
			"is_bile_shot": false,
			"is_zoning_shot": false
		},
		"ambient": {
			"texture": "res://assets/textures/projectiles/Bullet 1 - Enemy.png",
			"scale": Vector2(0.30, 0.30),
			"modulate": Color(1.0, 1.0, 1.0, 1.0),
			"damage": 20,
			"speed": 450.0,
			"movement_type": MOVE_DIRECT,
			"wave_frequency": 4.5,
			"wave_amplitude": 45.0,
			"sound_id": "",
			"is_bile_shot": false,
			"is_zoning_shot": false
		}
	}
}

# Runtime overrides cache & dynamic state
static var runtime_overrides: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var current_stage: int = 1


## Returns a deep copy of the default slot dictionary.
static func get_default_slots() -> Dictionary:
	return DEFAULT_ENEMY_PROJECTILE_SLOTS.duplicate(true)


## Returns a deep copy of the default profiles dictionary.
static func get_default_profiles() -> Dictionary:
	return DEFAULT_PROJECTILE_PROFILES.duplicate(true)


## Normalizes raw enemy type strings or aliases to canonical keys.
static func normalize_enemy_type(raw_type: String) -> String:
	var clean: String = raw_type.strip_edges().to_lower()
	match clean:
		"spewer", "bile_spewer", "bilespewer", "spitter", "jellyfish":
			return TYPE_SPEWER
		"heavy", "tank", "heavy_enemy", "heavyenemy", "armored":
			return TYPE_HEAVY
		"void", "teleporter", "void_bile", "voidbile":
			return TYPE_VOID
		"breeder", "bile_breeder", "bilebreeder":
			return TYPE_BREEDER
		"charger", "charger_roach", "chargerroach", "roach":
			return TYPE_CHARGER
		"boss", "dreadnought", "titan", "dreadnought_titan":
			return TYPE_BOSS
		"dragon_roach", "dragonroach", "queen", "dragon":
			return TYPE_DRAGON_ROACH
		"ambient", "wave", "bullet", "projectile":
			return TYPE_AMBIENT
		_:
			return clean


## Converts stage number or identifier to standard stage bracket string ("1-5", "6-10", "11-15", "16-20").
static func get_stage_bracket(stage_or_bracket: Variant) -> String:
	if stage_or_bracket == null:
		return get_stage_bracket(current_stage)

	if stage_or_bracket is int or stage_or_bracket is float:
		var st_num: int = int(stage_or_bracket)
		if st_num <= 5:
			return "1-5"
		elif st_num <= 10:
			return "6-10"
		elif st_num <= 15:
			return "11-15"
		else:
			return "16-20"

	var s_key: String = str(stage_or_bracket).strip_edges().to_lower()
	if s_key == "1" or s_key == "1-5" or s_key == "sector_1" or s_key == "sector 1":
		return "1-5"
	elif s_key == "2" or s_key == "6-10" or s_key == "sector_2" or s_key == "sector 2":
		return "6-10"
	elif s_key == "3" or s_key == "11-15" or s_key == "sector_3" or s_key == "sector 3":
		return "11-15"
	elif s_key == "4" or s_key == "16-20" or s_key == "sector_4" or s_key == "sector 4":
		return "16-20"

	if s_key.begins_with("stage_") or s_key.begins_with("stage "):
		var num_part: String = s_key.replace("stage_", "").replace("stage ", "").strip_edges()
		if num_part.is_valid_int():
			return get_stage_bracket(num_part.to_int())

	if s_key.is_valid_int():
		return get_stage_bracket(s_key.to_int())

	return "1-5"


## Updates the globally active stage number.
static func set_current_stage(stage_num: int) -> void:
	current_stage = maxi(1, stage_num)


## Retrieves the complete projectile configuration dictionary for a given enemy type and stage.
static func get_projectile_config(enemy_type: String, stage_or_bracket: Variant = null, variant_key: String = "") -> Dictionary:
	var norm_type: String = normalize_enemy_type(enemy_type)
	var bracket: String = get_stage_bracket(stage_or_bracket)

	# 1. Start with base default for this stage bracket and type
	var result: Dictionary = {}
	if DEFAULT_ENEMY_PROJECTILE_SLOTS.has(bracket) and DEFAULT_ENEMY_PROJECTILE_SLOTS[bracket].has(norm_type):
		result = (DEFAULT_ENEMY_PROJECTILE_SLOTS[bracket][norm_type] as Dictionary).duplicate(true)
	elif DEFAULT_ENEMY_PROJECTILE_SLOTS["1-5"].has(norm_type):
		result = (DEFAULT_ENEMY_PROJECTILE_SLOTS["1-5"][norm_type] as Dictionary).duplicate(true)
	else:
		# Fallback to default direct bullet
		result = (DEFAULT_PROJECTILE_PROFILES["ambient_wave"] as Dictionary).duplicate(true)

	# 2. Check archetype profile variant if specified (e.g. "boss_wavy", "boss_dart", "dragon_stream")
	if not variant_key.is_empty() and DEFAULT_PROJECTILE_PROFILES.has(variant_key):
		var profile: Dictionary = (DEFAULT_PROJECTILE_PROFILES[variant_key] as Dictionary).duplicate(true)
		for k in profile.keys():
			result[k] = profile[k]

	# 3. Apply runtime overrides if present
	# Check specific bracket: runtime_overrides[bracket][norm_type]
	if runtime_overrides.has(bracket) and runtime_overrides[bracket] is Dictionary:
		var b_overrides: Dictionary = runtime_overrides[bracket]
		if b_overrides.has(norm_type) and b_overrides[norm_type] is Dictionary:
			var b_dict_override: Dictionary = b_overrides[norm_type]
			for k in b_dict_override.keys():
				result[k] = b_dict_override[k]

	# Check global type overrides: runtime_overrides["global"][norm_type]
	if runtime_overrides.has("global") and runtime_overrides["global"] is Dictionary:
		var g_overrides: Dictionary = runtime_overrides["global"]
		if g_overrides.has(norm_type) and g_overrides[norm_type] is Dictionary:
			var g_dict_override: Dictionary = g_overrides[norm_type]
			for k in g_dict_override.keys():
				result[k] = g_dict_override[k]

	return result


## Returns an archetype profile by profile key (e.g. "void_dart", "spewer_bile").
static func get_projectile_profile(profile_key: String) -> Dictionary:
	if DEFAULT_PROJECTILE_PROFILES.has(profile_key):
		return (DEFAULT_PROJECTILE_PROFILES[profile_key] as Dictionary).duplicate(true)
	return (DEFAULT_PROJECTILE_PROFILES["ambient_wave"] as Dictionary).duplicate(true)


## Sets a projectile texture for an enemy type.
## Can set globally (stage_or_bracket = null or "") or per stage bracket.
static func set_projectile_texture(enemy_type: String, texture_or_path: Variant, stage_or_bracket: Variant = null) -> void:
	set_projectile_property(enemy_type, "texture", texture_or_path, stage_or_bracket)


## Sets an arbitrary projectile property (e.g. "speed", "damage", "scale", "modulate", "sound_id").
static func set_projectile_property(enemy_type: String, property: String, value: Variant, stage_or_bracket: Variant = null) -> void:
	var norm_type: String = normalize_enemy_type(enemy_type)
	var target_bracket: String = "global" if stage_or_bracket == null or str(stage_or_bracket).strip_edges().is_empty() else get_stage_bracket(stage_or_bracket)

	if not runtime_overrides.has(target_bracket):
		runtime_overrides[target_bracket] = {}
	if not runtime_overrides[target_bracket].has(norm_type):
		runtime_overrides[target_bracket][norm_type] = {}

	runtime_overrides[target_bracket][norm_type][property] = value

	# Invalidate texture cache if path altered
	if property == "texture" and value is String and _texture_cache.has(value):
		_texture_cache.erase(value)


## Resolves and loads the Texture2D assigned to an enemy projectile.
static func get_projectile_texture(enemy_type: String, stage_or_bracket: Variant = null) -> Texture2D:
	var cfg: Dictionary = get_projectile_config(enemy_type, stage_or_bracket)
	var tex_entry: Variant = cfg.get("texture", null)
	return load_texture(tex_entry)


## Loads a Texture2D from either a Texture2D reference or a string file path.
static func load_texture(entry: Variant) -> Texture2D:
	if entry is Texture2D:
		return entry
	if entry is String:
		var path: String = (entry as String).strip_edges()
		if path.is_empty():
			return null
		if _texture_cache.has(path):
			return _texture_cache[path]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				_texture_cache[path] = tex
				return tex
		else:
			push_warning("[EnemyProjectileDatabase] Projectile texture file not found: %s" % path)
	return null


## Resets all runtime overrides back to factory defaults.
static func reset_to_defaults() -> void:
	runtime_overrides.clear()
	_texture_cache.clear()
	current_stage = 1


## Factory method to spawn, configure, and add an enemy projectile in one line.
static func spawn_projectile(
	parent_node: Node,
	spawn_pos: Vector2,
	fire_dir: Vector2,
	enemy_type: String,
	stage_or_bracket: Variant = null,
	variant_key: String = "",
	custom_overrides: Dictionary = {}
) -> Area2D:
	if not parent_node:
		return null

	var proj_scene: PackedScene = load("res://scenes/enemies/projectile.tscn") as PackedScene
	if not proj_scene:
		return null

	var bullet: Area2D = proj_scene.instantiate() as Area2D
	if not bullet:
		return null

	bullet.position = spawn_pos

	var cfg: Dictionary = get_projectile_config(enemy_type, stage_or_bracket, variant_key)
	for k in custom_overrides.keys():
		cfg[k] = custom_overrides[k]

	if bullet.has_method("apply_config"):
		bullet.apply_config(cfg, fire_dir)
	elif bullet.has_method("setup"):
		bullet.setup(
			cfg.get("movement_type", 0),
			cfg.get("speed", 450.0),
			fire_dir,
			cfg.get("damage", 20),
			cfg.get("wave_frequency", 4.5),
			cfg.get("wave_amplitude", 45.0),
			cfg.get("is_zoning_shot", false),
			cfg.get("is_bile_shot", false)
		)

	parent_node.add_child(bullet)
	return bullet
