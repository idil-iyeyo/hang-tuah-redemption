extends CharacterBody2D

const SoundManager = preload("res://scripts/sound_manager.gd")
const CombatBoundaryManager = preload("res://scripts/combat_boundary_manager.gd")

signal health_changed(current: int, max_hp: int)
signal player_died
signal shield_changed(current: int, max_shield: int)
signal upgrade_applied(upgrade_type: String, new_level: int)

@export var base_speed: float = 400.0
@export var speed: float = 400.0
@export var max_health: int = 100
@export_group("Danger Boundary Settings")
## Horizontal forward airspace ratio (0.05 to 0.95). Default 0.65 means boundary begins at 65% from left (right 35% is danger zone).
## Set to 0.60 to have the boundary start at 60% of screen from left (40% danger zone).
@export var combat_boundary_ratio: float = 0.65 ## Maximum horizontal forward airspace ratio (default 65% ~ 1248px on 1920w)
@export var boundary_hazard_dps: float = 10.0 ## Damage per second applied while trespassing beyond the frontline line

signal combat_boundary_reached(clamped_position: Vector2)
signal boundary_hazard_changed(is_active: bool, dps: float)

var is_in_hazard_zone: bool = false
var hazard_damage_timer: float = 0.0
var is_boundary_hazard_enabled: bool = true

var current_health: int = 100
var is_alive: bool = true

# Character Upgrades
var speed_level: int = 0
var shield_level: int = 0 # 1 level = 2 shield, max level 3 = 6 shield
var current_shields: int = 0
var current_skin: String = "default"

@export var projectile_scene: PackedScene = preload("res://scenes/player/player_projectile.tscn")

# Thruster Mount Constants
const POS_THRUSTER_MOUNT: Vector2 = Vector2(-55.0, 2.5)
const POS_THRUSTER_SPRITE_DEFAULT: Vector2 = Vector2(-60.0, 0.0)
const SCALE_THRUSTER_DEFAULT: Vector2 = Vector2(5.0, 5.0)

# Thruster Slot Paths (Drop your PNG into either slot anytime!)
const THRUSTER_SLOT_CUSTOM: String = "res://assets/textures/thrusters/thruster_custom.png"
const THRUSTER_SLOT_DEFAULT: String = "res://assets/textures/thruster_flame.png"

# Cosmetic Thruster Configuration (Easily adjustable in Inspector or swapped with custom PNG)
@export_group("Thruster Decoration")
@export var custom_thruster_path: String = "" ## Custom PNG path (e.g. "res://assets/textures/thrusters/my_thruster.png"). If set or if thruster_custom.png exists, it is loaded automatically.
@export var thruster_texture: Texture2D:
	set(value):
		thruster_texture = value
		if thruster_sprite:
			thruster_sprite.texture = value if value else default_thruster_texture
@export var thruster_offset: Vector2 = POS_THRUSTER_SPRITE_DEFAULT:
	set(value):
		thruster_offset = value
		if thruster_sprite:
			thruster_sprite.position = value
@export var thruster_scale: Vector2 = SCALE_THRUSTER_DEFAULT:
	set(value):
		thruster_scale = value
		if thruster_sprite:
			thruster_sprite.scale = value
@export var hide_when_idle: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var thruster_mount: Node2D = get_node_or_null("ThrusterMount")
@onready var thruster_sprite: Sprite2D = get_node_or_null("ThrusterMount/ThrusterSprite")
var default_thruster_texture: Texture2D

# Modular Weapon Component Reference
@onready var gun: Node2D = get_node_or_null("Gun")

# Visible Weapon Mount Alignment Constants (Mirroring Gun component for external compatibility)
const SCALE_BARREL_STANDARD: Vector2 = Vector2(2.0, 2.0)
const SCALE_CANNON_STANDARD: Vector2 = Vector2(5.0, 5.0)

const POS_BARREL_CENTER: Vector2 = Vector2(7.0, 3.0)
const POS_BARREL_TOP: Vector2 = Vector2(-8.0, -7.0)
const POS_BARREL_BOTTOM: Vector2 = Vector2(-8.0, 13.0)
const POS_CANNON: Vector2 = Vector2(17.0, 10.0)

# Backward-Compatible Property Wrappers forwarding to Gun component
var gun_level: int:
	get:
		return int(gun.gun_level) if gun else _local_gun_level
	set(value):
		_local_gun_level = value
		if gun:
			gun.gun_level = value
var _local_gun_level: int = 0

var has_emergency_gun: bool:
	get:
		return bool(gun.has_emergency_gun) if gun else _local_has_emergency_gun
	set(value):
		_local_has_emergency_gun = value
		if gun:
			gun.has_emergency_gun = value
var _local_has_emergency_gun: bool = false

var shoot_cooldown_timer: float:
	get:
		return float(gun.cooldown_timer) if gun else _local_shoot_cooldown_timer
	set(value):
		_local_shoot_cooldown_timer = value
		if gun:
			gun.cooldown_timer = value
var _local_shoot_cooldown_timer: float = 0.0

var level2_alt_top: bool:
	get:
		return bool(gun.level2_alt_top) if gun else _local_level2_alt_top
	set(value):
		_local_level2_alt_top = value
		if gun:
			gun.level2_alt_top = value
var _local_level2_alt_top: bool = false

# Backward-Compatible Node Accessors
var gun_mount: Node2D:
	get:
		if gun and gun.has_node("GunMount"):
			return gun.get_node("GunMount") as Node2D
		return get_node_or_null("GunMount") as Node2D

var gun_sprite_center: Sprite2D:
	get:
		if gun and gun.has_node("GunMount/GunSpriteCenter"):
			return gun.get_node("GunMount/GunSpriteCenter") as Sprite2D
		return get_node_or_null("GunMount/GunSpriteCenter") as Sprite2D

var gun_sprite_top: Sprite2D:
	get:
		if gun and gun.has_node("GunMount/GunSpriteTop"):
			return gun.get_node("GunMount/GunSpriteTop") as Sprite2D
		return get_node_or_null("GunMount/GunSpriteTop") as Sprite2D

var gun_sprite_bottom: Sprite2D:
	get:
		if gun and gun.has_node("GunMount/GunSpriteBottom"):
			return gun.get_node("GunMount/GunSpriteBottom") as Sprite2D
		return get_node_or_null("GunMount/GunSpriteBottom") as Sprite2D

var gun_sprite_cannon: Sprite2D:
	get:
		if gun and gun.has_node("GunMount/GunSpriteCannon"):
			return gun.get_node("GunMount/GunSpriteCannon") as Sprite2D
		return get_node_or_null("GunMount/GunSpriteCannon") as Sprite2D

var shoot_sound_player: AudioStreamPlayer:
	get:
		if gun and gun.has_node("ShootSoundPlayer"):
			return gun.get_node("ShootSoundPlayer") as AudioStreamPlayer
		return get_node_or_null("ShootSoundPlayer") as AudioStreamPlayer

var cannon_sound_player: AudioStreamPlayer:
	get:
		if gun and gun.has_node("CannonSoundPlayer"):
			return gun.get_node("CannonSoundPlayer") as AudioStreamPlayer
		return get_node_or_null("CannonSoundPlayer") as AudioStreamPlayer

@onready var hit_sound_player: AudioStreamPlayer = get_node_or_null("HitSoundPlayer")
@onready var shield_sound_player: AudioStreamPlayer = get_node_or_null("ShieldSoundPlayer")


func _ready() -> void:
	current_health = max_health
	speed = base_speed
	health_changed.emit(current_health, max_health)
	shield_changed.emit(current_shields, shield_level * 2)
	_setup_input_actions()
	_init_sounds()
	_init_thruster()
	_init_boundary_from_manager()
	_update_shield_visual()
	_update_gun_visual()


func _init_boundary_from_manager() -> void:
	if CombatBoundaryManager:
		combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()
		boundary_hazard_dps = CombatBoundaryManager.get_damage_per_second()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Decrement weapon cooldown timer via Gun component or local fallback
	if gun and gun.has_method("process_cooldown"):
		gun.process_cooldown(delta)
	elif _local_shoot_cooldown_timer > 0.0:
		_local_shoot_cooldown_timer -= delta

	# Full 4-way omnidirectional movement (Up, Down, Left, Right)
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()

	# Dynamic decorative thruster visual activation during movement
	var is_moving: bool = input_vector != Vector2.ZERO or velocity.length_squared() > 100.0
	_update_thruster_visual(is_moving)


	# Screen boundaries (player stays within visible viewport)
	var half_width: float = 64.0
	var half_height: float = 64.0
	var screen_rect: Rect2 = get_viewport_rect()
	var screen_w: float = screen_rect.size.x if screen_rect.size.x > 0.0 else 1920.0
	var screen_h: float = screen_rect.size.y if screen_rect.size.y > 0.0 else 1080.0
	var screen_max_x: float = screen_w - half_width

	position.x = clampf(position.x, half_width, screen_max_x)
	position.y = clampf(position.y, half_height, screen_h - half_height)

	# Tactical combat airspace perimeter & hazard zone damage (10 DPS beyond red line)
	if CombatBoundaryManager:
		combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()
		boundary_hazard_dps = CombatBoundaryManager.get_damage_per_second()
	var bound_x: float = screen_w * combat_boundary_ratio
	if is_boundary_hazard_enabled and position.x > bound_x:
		is_in_hazard_zone = true
		if is_alive:
			hazard_damage_timer += delta
			var tick_time: float = CombatBoundaryManager.get_tick_interval() if CombatBoundaryManager else 0.5
			if hazard_damage_timer >= tick_time:
				hazard_damage_timer -= tick_time
				var tick_dmg: int = CombatBoundaryManager.get_damage_per_tick() if CombatBoundaryManager else 5
				if tick_dmg == 5:
					take_damage(5) # Baseline default 10 DPS (5 dmg per 0.5s)
				else:
					take_damage(tick_dmg)
		combat_boundary_reached.emit(position)
		boundary_hazard_changed.emit(true, boundary_hazard_dps)
	else:
		if is_in_hazard_zone:
			is_in_hazard_zone = false
			hazard_damage_timer = 0.0
			boundary_hazard_changed.emit(false, 0.0)

	# Firing weapon via modular Gun component (player always starts armed with Starter Blaster)
	var can_fire: bool = gun.can_shoot() if (gun and gun.has_method("can_shoot")) else (_local_shoot_cooldown_timer <= 0.0)
	if can_fire and Input.is_action_pressed("shoot"):
		shoot()


func equip_free_emergency_gun() -> void:
	if gun_level <= 0:
		if gun and gun.has_method("equip_free_emergency_gun"):
			gun.equip_free_emergency_gun()
		else:
			has_emergency_gun = true
			_update_gun_visual()
		upgrade_applied.emit("free_gun", 1)


const SKIN_TEXTURES: Dictionary = {
	"default": preload("res://assets/textures/ships/HangTuahJet_1.png"),
	"crimson": preload("res://assets/textures/ships/HangJebatJetNoExhaust.png"),
	"void": preload("res://assets/textures/ships/Hang Lekir Jet - Player.png"),
	"gold": preload("res://assets/textures/ships/Hang Kasturi Jet - Player Right.png"),
}

# The 4 Dedicated Thruster Slots (Cyan, Crimson, Void, Gold)
const THRUSTER_TEXTURES: Dictionary = {
	"default": preload("res://assets/textures/thrusters/thruster_cyan.png"),
	"cyan": preload("res://assets/textures/thrusters/thruster_cyan.png"),
	"crimson": preload("res://assets/textures/thrusters/thruster_crimson.png"),
	"void": preload("res://assets/textures/thrusters/thruster_void.png"),
	"gold": preload("res://assets/textures/thrusters/thruster_gold.png"),
}

func get_skin_color(skin_id: String = "") -> Color:
	# Skins now possess rich native pixel art colors! Modulate to pure white to render cleanly.
	return Color(1.0, 1.0, 1.0, 1.0)


func set_skin(skin_id: String) -> void:
	current_skin = skin_id
	if sprite:
		if SKIN_TEXTURES.has(skin_id):
			sprite.texture = SKIN_TEXTURES[skin_id]
		else:
			sprite.texture = SKIN_TEXTURES["default"]
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Automatically equip the matching thematic thruster style if not custom-overridden
	if THRUSTER_TEXTURES.has(skin_id) and custom_thruster_path.is_empty():
		set_thruster_by_key(skin_id)


## Fires weapon by delegating cleanly to the independent Gun scene
func shoot() -> void:
	if not is_alive:
		return

	if gun and gun.has_method("shoot"):
		gun.shoot(get_parent(), global_position)
		return

	# Fallback shooting implementation in case Gun scene is detached
	if projectile_scene == null or get_parent() == null:
		return

	if gun_level <= 0:
		_local_shoot_cooldown_timer = 0.48
		_spawn_blaster_bolt(position + Vector2(76.0, 0.0), Vector2.RIGHT, 2, 1, 750.0, false, true)
	elif gun_level == 1:
		_local_shoot_cooldown_timer = 0.35
		_spawn_blaster_bolt(position + Vector2(76.0, 0.0), Vector2.RIGHT, 3, 2, 950.0, false, false)
	elif gun_level == 2:
		_local_shoot_cooldown_timer = 0.22
		var y_off: float = -12.0 if _local_level2_alt_top else 12.0
		_local_level2_alt_top = not _local_level2_alt_top
		_spawn_blaster_bolt(position + Vector2(76.0, y_off), Vector2.RIGHT, 5, 2, 950.0, false, false)
	elif gun_level == 3:
		_local_shoot_cooldown_timer = 0.65
		_spawn_blaster_bolt(position + Vector2(85.0, 0.0), Vector2.RIGHT, 8, 5, 800.0, true, false)
	elif gun_level == 4:
		_local_shoot_cooldown_timer = 0.12
		_spawn_blaster_bolt(position + Vector2(80.0, 0.0), Vector2.RIGHT, 5, 3, 1150.0, false, false, true)
	elif gun_level >= 5:
		_local_shoot_cooldown_timer = 0.055
		_spawn_blaster_bolt(position + Vector2(90.0, 0.0), Vector2.RIGHT, 7, 1, 2600.0, false, false, false, true)


func _spawn_blaster_bolt(
	spawn_pos: Vector2,
	dir: Vector2,
	dmg: int,
	prc: int,
	spd: float,
	is_cannon: bool = false,
	is_emergency: bool = false,
	is_gatling: bool = false,
	is_laser: bool = false
) -> void:
	if gun and gun.has_method("spawn_blaster_bolt"):
		gun.spawn_blaster_bolt(spawn_pos, dir, dmg, prc, spd, is_cannon, is_emergency, is_gatling, is_laser, get_parent())
		return

	if projectile_scene == null:
		return
	var bolt: Area2D = projectile_scene.instantiate() as Area2D
	if bolt:
		bolt.position = spawn_pos
		bolt.set("direction", dir)
		get_parent().add_child(bolt)
		if bolt.has_method("setup_projectile"):
			bolt.setup_projectile(dmg, prc, spd, is_cannon, is_emergency, is_gatling, is_laser)
		elif is_emergency and bolt.has_method("set_emergency_style"):
			bolt.set_emergency_style()


func take_damage(amount: int = 20, bypass_shield: bool = false) -> void:
	if not is_alive:
		return

	# Kinetic Shield Absorption (absorbs 1 damage instance per shield point unless bypassed by lethal strikes)
	if not bypass_shield and current_shields > 0:
		current_shields -= 1
		shield_changed.emit(current_shields, shield_level * 2)
		_flash_shield()
		if shield_sound_player:
			shield_sound_player.play()
		else:
			SoundManager.play_sfx("shield_hit")
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	# Play impact sound effect
	if hit_sound_player:
		hit_sound_player.play()
	else:
		SoundManager.play_sfx("player_hit")

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), 0.1)
		tween.tween_property(sprite, "modulate", get_skin_color(), 0.2)

	if current_health <= 0:
		die()


## Instantly obliterates the player, stripping all shields and health regardless of upgrades
func lethal_hit() -> void:
	if not is_alive:
		return
	current_shields = 0
	current_health = 0
	shield_changed.emit(0, shield_level * 2)
	health_changed.emit(0, max_health)
	die()


func heal(amount: int) -> void:
	if not is_alive:
		return

	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.2, 1.0, 0.4), 0.15)
		tween.tween_property(sprite, "modulate", get_skin_color(), 0.25)


func recharge_shield() -> void:
	current_shields = shield_level * 2
	shield_changed.emit(current_shields, shield_level * 2)
	_update_shield_visual()


func _flash_shield() -> void:
	if not shield_sprite:
		return
	shield_sprite.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(shield_sprite, "modulate", Color(0.6, 1.0, 1.0, 0.9), 0.08)
	tween.tween_property(shield_sprite, "modulate", Color(0.2, 0.8, 1.0, 0.5), 0.15)
	if current_shields <= 0:
		tween.tween_property(shield_sprite, "visible", false, 0.1)


func _init_thruster() -> void:
	if not thruster_sprite:
		return
	default_thruster_texture = thruster_sprite.texture

	if not custom_thruster_path.is_empty() and ResourceLoader.exists(custom_thruster_path):
		var custom_tex: Texture2D = load(custom_thruster_path) as Texture2D
		if custom_tex:
			thruster_texture = custom_tex
	elif thruster_texture == null and ResourceLoader.exists(THRUSTER_SLOT_CUSTOM):
		var slot_tex: Texture2D = load(THRUSTER_SLOT_CUSTOM) as Texture2D
		if slot_tex:
			thruster_texture = slot_tex

	if thruster_texture:
		thruster_sprite.texture = thruster_texture
	thruster_sprite.position = thruster_offset
	thruster_sprite.scale = thruster_scale
	thruster_sprite.visible = false


func _update_thruster_visual(is_moving: bool) -> void:
	if not thruster_sprite or not is_alive:
		if thruster_sprite:
			thruster_sprite.visible = false
		return

	if is_moving:
		thruster_sprite.visible = true
		var flicker_x: float = thruster_scale.x * randf_range(0.88, 1.15)
		var flicker_y: float = thruster_scale.y * randf_range(0.92, 1.08)
		thruster_sprite.scale = Vector2(flicker_x, flicker_y)
	else:
		if hide_when_idle:
			thruster_sprite.visible = false
		else:
			thruster_sprite.visible = true
			thruster_sprite.scale = thruster_scale * 0.4


func load_thruster_from_path(file_path: String) -> bool:
	if ResourceLoader.exists(file_path):
		var tex: Texture2D = load(file_path) as Texture2D
		if tex:
			set_thruster_texture(tex)
			return true
	return false


func set_thruster_by_key(thruster_key: String) -> void:
	if THRUSTER_TEXTURES.has(thruster_key):
		set_thruster_texture(THRUSTER_TEXTURES[thruster_key])
	else:
		set_thruster_texture(THRUSTER_TEXTURES["default"])


func set_thruster_texture(tex: Texture2D) -> void:
	thruster_texture = tex
	if thruster_sprite:
		thruster_sprite.texture = tex if tex else default_thruster_texture


func set_thruster_offset(offset: Vector2) -> void:
	thruster_offset = offset
	if thruster_sprite:
		thruster_sprite.position = offset


func set_thruster_scale(scale_vec: Vector2) -> void:
	thruster_scale = scale_vec
	if thruster_sprite:
		thruster_sprite.scale = scale_vec


func _update_shield_visual() -> void:
	if not shield_sprite:
		return
	shield_sprite.visible = (current_shields > 0 and is_alive)
	if shield_sprite.visible:
		shield_sprite.modulate = Color(0.2, 0.85, 1.0, 0.5)


## Delegates visual updates to Gun component while maintaining reset guarantees
func _update_gun_visual() -> void:
	if gun and gun.has_method("update_visual"):
		gun.update_visual()
		return

	# Fallback visual update if Gun component is not present
	if gun_sprite_center:
		gun_sprite_center.visible = false
		gun_sprite_center.scale = SCALE_BARREL_STANDARD
		gun_sprite_center.position = POS_BARREL_CENTER
		gun_sprite_center.modulate = Color.WHITE

	if gun_sprite_top:
		gun_sprite_top.visible = false
		gun_sprite_top.scale = SCALE_BARREL_STANDARD
		gun_sprite_top.position = POS_BARREL_TOP
		gun_sprite_top.modulate = Color.WHITE

	if gun_sprite_bottom:
		gun_sprite_bottom.visible = false
		gun_sprite_bottom.scale = SCALE_BARREL_STANDARD
		gun_sprite_bottom.position = POS_BARREL_BOTTOM
		gun_sprite_bottom.modulate = Color.WHITE

	if gun_sprite_cannon:
		gun_sprite_cannon.visible = false
		gun_sprite_cannon.scale = SCALE_CANNON_STANDARD
		gun_sprite_cannon.position = POS_CANNON
		gun_sprite_cannon.modulate = Color.WHITE

	if gun_level >= 5:
		if gun_sprite_cannon:
			gun_sprite_cannon.visible = true
			gun_sprite_cannon.modulate = Color(1.0, 0.25, 0.4)
		if gun_sprite_top:
			gun_sprite_top.visible = true
			gun_sprite_top.modulate = Color(1.0, 0.25, 0.4)
		if gun_sprite_bottom:
			gun_sprite_bottom.visible = true
			gun_sprite_bottom.modulate = Color(1.0, 0.25, 0.4)
	elif gun_level == 4:
		if gun_sprite_center:
			gun_sprite_center.visible = true
			gun_sprite_center.modulate = Color(1.0, 0.45, 0.2)
		if gun_sprite_top:
			gun_sprite_top.visible = true
			gun_sprite_top.modulate = Color(1.0, 0.45, 0.2)
		if gun_sprite_bottom:
			gun_sprite_bottom.visible = true
			gun_sprite_bottom.modulate = Color(1.0, 0.45, 0.2)
	elif gun_level == 3:
		if gun_sprite_cannon:
			gun_sprite_cannon.visible = true
			gun_sprite_cannon.modulate = Color(1.0, 1.0, 1.0)
	elif gun_level == 2:
		if gun_sprite_top:
			gun_sprite_top.visible = true
			gun_sprite_top.modulate = Color(1.0, 0.85, 0.3)
		if gun_sprite_bottom:
			gun_sprite_bottom.visible = true
			gun_sprite_bottom.modulate = Color(1.0, 0.85, 0.3)
	elif gun_level == 1:
		if gun_sprite_center:
			gun_sprite_center.visible = true
			gun_sprite_center.modulate = Color(0.2, 0.9, 1.0)
	elif gun_level <= 0 or has_emergency_gun:
		if gun_sprite_center:
			gun_sprite_center.visible = true
			gun_sprite_center.modulate = Color(1.0, 0.75, 0.2)


func apply_upgrade(type: String) -> bool:
	match type:
		"heal_all":
			if current_health < max_health:
				current_health = max_health
				health_changed.emit(current_health, max_health)
				upgrade_applied.emit("heal_all", 1)
				if sprite:
					var t: Tween = create_tween()
					t.tween_property(sprite, "modulate", Color(0.2, 1.0, 0.4), 0.15)
					t.tween_property(sprite, "modulate", Color.WHITE, 0.2)
				return true
			return false

		"speed":
			speed_level += 1
			speed = base_speed + float(speed_level) * 65.0
			upgrade_applied.emit("speed", speed_level)
			if sprite:
				var t_speed: Tween = create_tween()
				t_speed.tween_property(sprite, "modulate", Color(0.4, 0.9, 1.0), 0.15)
				t_speed.tween_property(sprite, "modulate", get_skin_color(), 0.2)
			return true

		"shield":
			# Absorbs 2 damage for every upgrade, up to 6 damage at max level 3
			if shield_level < 3:
				shield_level += 1
				current_shields = shield_level * 2
				shield_changed.emit(current_shields, shield_level * 2)
				_update_shield_visual()
				upgrade_applied.emit("shield", shield_level)
				return true

		"gun":
			if gun_level < 5:
				if gun and gun.has_method("upgrade_gun"):
					gun.upgrade_gun()
				else:
					gun_level += 1
					has_emergency_gun = false
					_update_gun_visual()
				upgrade_applied.emit("gun", gun_level)
				if sprite:
					var t_gun: Tween = create_tween()
					var flash_c: Color = Color(3.5, 0.25, 0.3) if gun_level == 5 else (Color(1.0, 0.2, 0.6) if gun_level == 4 else (Color(1.0, 0.48, 0.1) if gun_level == 3 else Color(1.0, 0.85, 0.3)))
					t_gun.tween_property(sprite, "modulate", flash_c, 0.15)
					t_gun.tween_property(sprite, "modulate", get_skin_color(), 0.2)
				return true

	return false


## Resets all player upgrades (speed, shield, gun) back to baseline levels and updates visuals.
func reset_all_upgrades() -> void:
	speed_level = 0
	speed = base_speed
	shield_level = 0
	current_shields = 0
	is_in_hazard_zone = false
	hazard_damage_timer = 0.0
	gun_level = 0
	has_emergency_gun = false
	if gun and gun.has_method("update_visual"):
		gun.gun_level = 0
	_update_gun_visual()
	_update_shield_visual()
	shield_changed.emit(0, 0)
	if sprite:
		sprite.modulate = get_skin_color()


func die() -> void:
	is_alive = false
	pause_boundary_hazard()
	velocity = Vector2.ZERO
	if shield_sprite:
		shield_sprite.visible = false
	if thruster_sprite:
		thruster_sprite.visible = false
	SoundManager.play_sfx("player_die")
	player_died.emit()


func get_combat_boundary_x() -> float:
	var screen_rect: Rect2 = get_viewport_rect()
	var screen_w: float = screen_rect.size.x if screen_rect.size.x > 0.0 else 1920.0
	return CombatBoundaryManager.get_boundary_x(screen_w)


## Sets the boundary starting ratio measured from the left edge of the screen (0.05 to 0.95).
## Example: 0.60 sets the boundary at 60% from the left, leaving 40% on the right as the danger zone.
func set_combat_boundary_ratio(ratio: float) -> void:
	CombatBoundaryManager.set_boundary_ratio(ratio)
	combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()


## Sets the boundary starting position by specifying the percentage or ratio from the right edge of the screen.
## Examples:
## - set_boundary_from_right(0.40) or set_boundary_from_right(40.0): boundary starts 40% from right (line at 60% from left).
## - set_boundary_from_right(0.60) or set_boundary_from_right(60.0): boundary starts 60% from right (line at 40% from left).
func set_boundary_from_right(percentage_or_ratio: float) -> void:
	CombatBoundaryManager.set_boundary_from_right(percentage_or_ratio)
	combat_boundary_ratio = CombatBoundaryManager.get_boundary_ratio()


## Returns the active boundary ratio measured from the left edge (0.0 to 1.0).
func get_combat_boundary_ratio() -> float:
	return CombatBoundaryManager.get_boundary_ratio()


## Returns the active danger zone coverage ratio from the right edge (0.0 to 1.0).
func get_danger_zone_from_right_ratio() -> float:
	return CombatBoundaryManager.get_danger_zone_from_right_ratio()


func is_in_boundary_hazard() -> bool:
	return is_in_hazard_zone


func get_boundary_hazard_dps() -> float:
	return boundary_hazard_dps


## Pauses boundary hazard damage and resets accumulated tick timer.
func pause_boundary_hazard() -> void:
	var was_active: bool = is_boundary_hazard_enabled or is_in_hazard_zone
	is_boundary_hazard_enabled = false
	hazard_damage_timer = 0.0
	is_in_hazard_zone = false
	if was_active:
		boundary_hazard_changed.emit(false, 0.0)


## Resumes boundary hazard damage for active combat.
func resume_boundary_hazard() -> void:
	is_boundary_hazard_enabled = true


## Explicit setter for boundary hazard state
func set_boundary_hazard_enabled(enabled: bool) -> void:
	if enabled:
		resume_boundary_hazard()
	else:
		pause_boundary_hazard()


## Returns whether the boundary hazard is currently enabled
func is_boundary_hazard_enabled_active() -> bool:
	return is_boundary_hazard_enabled


func _setup_input_actions() -> void:
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var event_w: InputEventKey = InputEventKey.new()
		event_w.physical_keycode = KEY_W
		InputMap.action_add_event("move_up", event_w)
		var event_up: InputEventKey = InputEventKey.new()
		event_up.physical_keycode = KEY_UP
		InputMap.action_add_event("move_up", event_up)

	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var event_s: InputEventKey = InputEventKey.new()
		event_s.physical_keycode = KEY_S
		InputMap.action_add_event("move_down", event_s)
		var event_down: InputEventKey = InputEventKey.new()
		event_down.physical_keycode = KEY_DOWN
		InputMap.action_add_event("move_down", event_down)

	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var event_a: InputEventKey = InputEventKey.new()
		event_a.physical_keycode = KEY_A
		InputMap.action_add_event("move_left", event_a)
		var event_left: InputEventKey = InputEventKey.new()
		event_left.physical_keycode = KEY_LEFT
		InputMap.action_add_event("move_left", event_left)

	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var event_d: InputEventKey = InputEventKey.new()
		event_d.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", event_d)
		var event_right: InputEventKey = InputEventKey.new()
		event_right.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("move_right", event_right)

	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var event_space: InputEventKey = InputEventKey.new()
		event_space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("shoot", event_space)

		var event_enter: InputEventKey = InputEventKey.new()
		event_enter.physical_keycode = KEY_ENTER
		InputMap.action_add_event("shoot", event_enter)


func _init_sounds() -> void:
	if hit_sound_player:
		hit_sound_player.bus = "SFX"
		if hit_sound_player.stream == null:
			var sfx_stream: AudioStream = SoundManager.get_sound_stream("player_hit")
			hit_sound_player.stream = sfx_stream if sfx_stream != null else _generate_hit_audio()

	if shield_sound_player:
		shield_sound_player.bus = "SFX"
		if shield_sound_player.stream == null:
			var sfx_shield_stream: AudioStream = SoundManager.get_sound_stream("shield_hit")
			shield_sound_player.stream = sfx_shield_stream if sfx_shield_stream != null else _generate_shield_audio()


func _generate_hit_audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * 0.16)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(170.0, 45.0, progress)
		phase += freq / 22050.0

		var wave: float = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		var noise: float = randf_range(-1.0, 1.0)
		var mixed: float = wave * 0.65 + noise * 0.35

		var envelope: float = pow(1.0 - progress, 2.5)
		var sample_byte: int = clampi(int(128.0 + mixed * envelope * 110.0), 0, 255)
		data[i] = sample_byte

	stream.data = data
	return stream


func _generate_shield_audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * 0.20)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(440.0, 880.0, progress)
		phase += freq / 22050.0

		var wave: float = sin(phase * TAU) * 0.7 + sin(phase * TAU * 1.5) * 0.3
		var env: float = sin(progress * PI)
		var sample_val: int = clampi(int(128.0 + wave * env * 90.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream
