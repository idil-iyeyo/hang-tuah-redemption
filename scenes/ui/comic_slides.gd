# scenes/ui/comic_slides.gd
class_name ComicSlides
extends Control

## ==============================================================================
## FULL-SCREEN SEQUENTIAL COMIC SLIDES SYSTEM
## ==============================================================================
## Presents cinematic full-screen comic slides for:
## 1. "prologue" (Level 1 first-time intro cutscene)
## 2. "epilogue" (Level 20 victory cutscene upon defeating the Coalition)
##
## Features:
## - Full-screen layout (1920x1080) with dynamic pixel-art actor composition
## - Smooth slide transitions & subtle floating animations
## - Touch/click anywhere to advance, plus explicit Prev / Next / Skip controls
## - Mobile-friendly oversized touch buttons and page dots indicator
## ==============================================================================

signal comic_finished(comic_id: String)
signal comic_skipped(comic_id: String)

const SoundManager = preload("res://scripts/sound_manager.gd")

# Texture Paths (from assets/textures/comic/)
const BG_KLCC: String = "res://assets/textures/comic/Backgrounds/KlccBackground.png"
const BG_FAMOSA: String = "res://assets/textures/comic/Backgrounds/KotaAFamosaBackground.png"
const BG_MINANG: String = "res://assets/textures/comic/Backgrounds/RumahMinangKabauxIstanaAwanBackground.png"
const BG_LEDANG: String = "res://assets/textures/comic/Backgrounds/LembahKerisXGunungLedang.png"

const SHIP_TUAH: String = "res://assets/textures/comic/player ships/HangTuahJet_1.png"
const SHIP_JEBAT: String = "res://assets/textures/ships/HangJebatJetNoExhaust.png"
const SHIP_KASTURI: String = "res://assets/textures/comic/player ships/Hang Kasturi Jet - Player Right.png"
const SHIP_LEKIR: String = "res://assets/textures/comic/player ships/Hang Lekir Jet - Player.png"

const INV_MINANGKABAU: String = "res://assets/textures/comic/invaders/MinangKabau Ship - Enemy ( Boss 2 ).png"
const INV_WAURIOR: String = "res://assets/textures/comic/invaders/WauMonarch - ( Boss 1).png"
const INV_GASING: String = "res://assets/textures/comic/invaders/Gasing Trooper - Enemy Basic.png"
const INV_SONGKET: String = "res://assets/textures/comic/invaders/Songket Drone - Enemy.png"
const INV_RHINO: String = "res://assets/textures/comic/invaders/Rhino Horn - Enemy Basic.png"
const INV_BATIK: String = "res://assets/textures/enemies/BatikJellyfishSpitter.png"
const INV_GHOST: String = "res://assets/textures/comic/invaders/Malayan Ghost Army - Enemy Basic.png"

@onready var bg_texture_rect: TextureRect = $BackgroundRect
@onready var bg_dimmer: ColorRect = $DimmerRect
@onready var actors_container: Control = $ActorsContainer
@onready var top_bar: MarginContainer = $TopBarMargin
@onready var comic_title_label: Label = $TopBarMargin/TopBarHBox/ComicTitleLabel
@onready var page_label: Label = $TopBarMargin/TopBarHBox/PageLabel
@onready var skip_button: Button = $TopBarMargin/TopBarHBox/SkipButton
@onready var caption_panel: PanelContainer = $BottomMargin/CaptionVBox/CaptionPanel
@onready var speaker_label: Label = $BottomMargin/CaptionVBox/CaptionPanel/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $BottomMargin/CaptionVBox/CaptionPanel/Margin/VBox/TextLabel
@onready var nav_hbox: HBoxContainer = $BottomMargin/CaptionVBox/NavHBox
@onready var prev_button: Button = $BottomMargin/CaptionVBox/NavHBox/PrevButton
@onready var dots_hbox: HBoxContainer = $BottomMargin/CaptionVBox/NavHBox/DotsHBox
@onready var next_button: Button = $BottomMargin/CaptionVBox/NavHBox/NextButton
@onready var tap_hint_label: Label = get_node_or_null("BottomMargin/CaptionVBox/TapHintLabel")

var current_comic_id: String = "prologue"
var current_context: String = "review" # "launch" or "review"
var current_slide_index: int = 0
var slides_data: Array[Dictionary] = []
var active_actor_tweens: Array[Tween] = []
var sfx_chime: AudioStream
var sfx_click: AudioStream
var _audio_player: AudioStreamPlayer = null
var _last_action_timestamp: int = 0
const DEBOUNCE_THRESHOLD_MS: int = 280
var _last_tap_frame: int = -1


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_sfx()
	_connect_signals()
	_init_tap_hint()


func _init_sfx() -> void:
	sfx_chime = SoundManager.get_sound_stream("modal_chime")
	sfx_click = SoundManager.get_sound_stream("button_click")
	if not _audio_player:
		_audio_player = AudioStreamPlayer.new()
		_audio_player.bus = "SFX"
		_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_audio_player)


func _play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	if not _audio_player:
		_init_sfx()
	_audio_player.stream = stream
	_audio_player.play()


func _init_tap_hint() -> void:
	if tap_hint_label:
		var t_hint: Tween = create_tween().set_loops()
		t_hint.tween_property(tap_hint_label, "modulate:a", 0.45, 0.75).set_trans(Tween.TRANS_SINE)
		t_hint.tween_property(tap_hint_label, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)


func _connect_signals() -> void:
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)


func _input(event: InputEvent) -> void:
	if not visible or modulate.a <= 0.05:
		return

	var is_tap: bool = false
	var tap_pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		is_tap = true
		tap_pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_tap = true
		tap_pos = event.position

	if not is_tap:
		return

	# Drop identical-frame emulated touch/mouse duplicates
	var cur_frame: int = Engine.get_process_frames()
	if cur_frame == _last_tap_frame:
		get_viewport().set_input_as_handled()
		return
	_last_tap_frame = cur_frame

	# Check debounce time to prevent hardware/software double-taps
	var now: int = Time.get_ticks_msec()
	if now - _last_action_timestamp < DEBOUNCE_THRESHOLD_MS:
		get_viewport().set_input_as_handled()
		return

	# If tap is inside the Skip button, handle skip
	if skip_button and skip_button.is_visible_in_tree() and skip_button.get_global_rect().has_point(tap_pos):
		_play_sfx(sfx_click)
		_on_skip_pressed()
		get_viewport().set_input_as_handled()
		return

	# If tap is inside the Prev button, handle prev
	if prev_button and prev_button.is_visible_in_tree() and prev_button.get_global_rect().has_point(tap_pos):
		_play_sfx(sfx_click)
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
		return

	# Otherwise, tapping ANYWHERE on screen advances to the next slide!
	_play_sfx(sfx_click)
	_on_next_pressed()
	get_viewport().set_input_as_handled()


## Opens and starts the comic sequence ("prologue" or "epilogue")
func start_comic(comic_id: String, context: String = "review") -> void:
	current_comic_id = comic_id
	current_context = context
	current_slide_index = 0
	_last_action_timestamp = Time.get_ticks_msec() + 250
	_last_tap_frame = Engine.get_process_frames()
	slides_data = _build_slides(comic_id, context)

	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.3)

	_show_slide(current_slide_index)


## Builds the 4 full-screen sequential slides for the chosen comic
func _build_slides(comic_id: String, context: String = "review") -> Array[Dictionary]:
	if comic_id == "epilogue":
		return _build_epilogue_slides()
	return _build_prologue_slides(context)


func _build_prologue_slides(context: String = "review") -> Array[Dictionary]:
	var final_action: String = "LAUNCH MISSION 1 🚀" if context == "launch" else "BACK TO MENU ➔"
	return [
		{
			"title": "PROLOGUE: Malay's Realm Invasion",
			"page_text": "PANEL 1 / 4",
			"bg": BG_KLCC,
			"tint": Color(0.0, 0.0, 0.0, 0.25),
			"speaker": "The Narrator",
			"speaker_color": Color(0.4, 0.9, 1.0),
			"text": "The year 2505. The Malay Realms looks Clear from any threats. Citizen lives in a very peaceful state, while maintains their culture",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": SHIP_TUAH,
					"pos": Vector2(400, 480),
					"scale": Vector2(0.55, 0.55),
					"anim": "float"
				}
			]
		},
		{
			"title": "PROLOGUE: Malay's Realm Invasion",
			"page_text": "PANEL 2 / 4",
			"bg": BG_KLCC,
			"tint": Color(0.5, 0.05, 0.15, 0.45), # Alarm crimson sky tint
			"speaker": "RADAR AMARAN KRITIKAL",
			"speaker_color": Color(1.0, 0.3, 0.3),
			"text": "ALERT! Wormhole Detected in Solariar Sector! Ancient Waurior and Minangkabau Ship inbound!",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": INV_MINANGKABAU,
					"pos": Vector2(1400, 360),
					"scale": Vector2(1.1, 1.1),
					"anim": "shake"
				},
				{
					"texture": INV_WAURIOR,
					"pos": Vector2(980, 240),
					"scale": Vector2(0.85, 0.85),
					"anim": "float"
				},
				{
					"texture": INV_GASING,
					"pos": Vector2(1650, 520),
					"scale": Vector2(0.5, 0.5),
					"anim": "float"
				},
				{
					"texture": INV_SONGKET,
					"pos": Vector2(750, 420),
					"scale": Vector2(0.55, 0.55),
					"anim": "float"
				}
			]
		},
		{
			"title": "PROLOGUE: Malay's Realm Invasion",
			"page_text": "PANEL 3 / 4",
			"bg": BG_FAMOSA,
			"tint": Color(0.05, 0.1, 0.2, 0.35),
			"speaker": "Malay's Earth (HIGH COMMAND)",
			"speaker_color": Color(1.0, 0.85, 0.2),
			"text": "Kota A Famosa shield is breaking! We have launched 'PROJEK EMPAT PENDEKAR'! Hang Tuah, Hang Jebat, Hang Kasturi, Hang Lekir—Activate 'Keris Plasma' Reactor!",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": SHIP_TUAH,
					"pos": Vector2(300, 480),
					"scale": Vector2(0.48, 0.48),
					"anim": "float"
				},
				{
					"texture": SHIP_JEBAT,
					"pos": Vector2(720, 430),
					"scale": Vector2(0.48, 0.48),
					"anim": "float"
				},
				{
					"texture": SHIP_KASTURI,
					"pos": Vector2(1180, 450),
					"scale": Vector2(0.48, 0.48),
					"anim": "float"
				},
				{
					"texture": SHIP_LEKIR,
					"pos": Vector2(1600, 490),
					"scale": Vector2(0.48, 0.48),
					"anim": "float"
				}
			]
		},
		{
			"title": "PROLOGUE: Malay's Realm Invasion",
			"page_text": "PANEL 4 / 4",
			"bg": BG_KLCC,
			"tint": Color(0.1, 0.2, 0.3, 0.3),
			"speaker": "SANG LAKSAMANA (HANG TUAH JET)",
			"speaker_color": Color(0.3, 0.95, 1.0),
			"text": "Enemy has Passed the border! As the chaos ensued, the pilot chants 'Tak'kan Melayu Hilang Di Angkasa! BERSEDIA UNTUK BERTEMPUR!'",
			"action_text": final_action,
			"actors": [
				{
					"texture": SHIP_TUAH,
					"pos": Vector2(500, 460),
					"scale": Vector2(0.65, 0.65),
					"anim": "drift_right"
				},
				{
					"texture": INV_RHINO,
					"pos": Vector2(1380, 380),
					"scale": Vector2(0.55, 0.55),
					"anim": "shake"
				},
				{
					"texture": INV_BATIK,
					"pos": Vector2(1620, 520),
					"scale": Vector2(0.45, 0.45),
					"anim": "float"
				}
			]
		}
	]


func _build_epilogue_slides() -> Array[Dictionary]:
	return [
		{
			"title": "EPILOGUE: MALAY'S REALM PEACE",
			"page_text": "PANEL 1 / 4",
			"bg": BG_LEDANG,
			"tint": Color(0.4, 0.1, 0.05, 0.45), # Fiery explosive tint
			"speaker": "BATTLE RADAR (LEDANG SECTOR)",
			"speaker_color": Color(1.0, 0.4, 0.2),
			"text": "Minangkabau Ship and the Waurior have been defeated!",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": INV_MINANGKABAU,
					"pos": Vector2(1250, 400),
					"scale": Vector2(1.1, 1.1),
					"anim": "shake",
					"modulate": Color(1.0, 0.5, 0.4)
				},
				{
					"texture": INV_WAURIOR,
					"pos": Vector2(700, 320),
					"scale": Vector2(0.85, 0.85),
					"anim": "shake",
					"modulate": Color(1.0, 0.6, 0.5)
				}
			]
		},
		{
			"title": "EPILOGUE: MALAY'S REALM PEACE",
			"page_text": "PANEL 2 / 4",
			"bg": BG_MINANG,
			"tint": Color(0.1, 0.15, 0.3, 0.4),
			"speaker": "NARRATOR (HIKAYAT ANGKASA)",
			"speaker_color": Color(0.7, 0.8, 1.0),
			"text": "Watching their titan fall, remnants of army fleeing back to the wormhole in Solariar Sector. The siege upon Malay's Realm has been broken!",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": INV_GASING,
					"pos": Vector2(1450, 320),
					"scale": Vector2(0.45, 0.45),
					"anim": "drift_right"
				},
				{
					"texture": INV_SONGKET,
					"pos": Vector2(1650, 480),
					"scale": Vector2(0.5, 0.5),
					"anim": "drift_right"
				},
				{
					"texture": INV_GHOST,
					"pos": Vector2(1250, 520),
					"scale": Vector2(0.45, 0.45),
					"anim": "drift_right"
				}
			]
		},
		{
			"title": "EPILOGUE: MALAY'S REALM PEACE",
			"page_text": "PANEL 3 / 4",
			"bg": BG_LEDANG,
			"tint": Color(0.0, 0.1, 0.2, 0.2), # Golden dawn atmosphere
			"speaker": "Malay's Earth (HIGH COMMAND)",
			"speaker_color": Color(1.0, 0.85, 0.2),
			"text": "The win is ours! The Malay's Society will truly be grateful for your bravery",
			"action_text": "NEXT ➔",
			"actors": [
				{
					"texture": SHIP_TUAH,
					"pos": Vector2(400, 440),
					"scale": Vector2(0.5, 0.5),
					"anim": "float"
				},
				{
					"texture": SHIP_JEBAT,
					"pos": Vector2(800, 410),
					"scale": Vector2(0.5, 0.5),
					"anim": "float"
				},
				{
					"texture": SHIP_KASTURI,
					"pos": Vector2(1200, 430),
					"scale": Vector2(0.5, 0.5),
					"anim": "float"
				},
				{
					"texture": SHIP_LEKIR,
					"pos": Vector2(1580, 460),
					"scale": Vector2(0.5, 0.5),
					"anim": "float"
				}
			]
		},
		{
			"title": "EPILOGUE: MALAY'S REALM PEACE",
			"page_text": "PANEL 4 / 4",
			"bg": BG_KLCC,
			"tint": Color(0.05, 0.15, 0.1, 0.2), # Peaceful green & gold
			"speaker": "SANG LAKSAMANA",
			"speaker_color": Color(0.3, 1.0, 0.6),
			"text": "Kedaulatan terpelihara. 'TAKKAN MELAYU HILANG DI DUNIA!' Congrats, 'Pendekar Angkasa'! You have saved the whole galaxy from the squids! Oops I mean invader!",
			"action_text": "Claim Victory 🏆",
			"actors": [
				{
					"texture": SHIP_TUAH,
					"pos": Vector2(960, 440),
					"scale": Vector2(0.7, 0.7),
					"anim": "float"
				}
			]
		}
	]


## Displays the slide at index `idx` with visual animations
func _show_slide(idx: int) -> void:
	if idx < 0 or idx >= slides_data.size():
		_finish_comic()
		return
	
	current_slide_index = idx
	var data: Dictionary = slides_data[idx]
	
	# Update labels
	if comic_title_label:
		comic_title_label.text = str(data.get("title", ""))
	if page_label:
		page_label.text = str(data.get("page_text", "PANEL %d / %d" % [idx + 1, slides_data.size()]))
	if speaker_label:
		speaker_label.text = "🗣️ " + str(data.get("speaker", "NARRATOR"))
		speaker_label.set("theme_override_colors/font_color", data.get("speaker_color", Color.WHITE))
	if text_label:
		text_label.text = str(data.get("text", ""))
	
	# Update buttons
	if prev_button:
		prev_button.visible = (idx > 0)
	if next_button:
		next_button.text = str(data.get("action_text", "NEXT ➔"))

	if tap_hint_label:
		if idx == slides_data.size() - 1:
			tap_hint_label.text = "👆 TAP TO FINISH ➔"
		else:
			tap_hint_label.text = "👆 TAP ANYWHERE TO CONTINUE ➔"

	_play_sfx(sfx_chime)

	# Update Dots indicator
	_update_dots(idx)
	
	# Update Background with cross-fade
	var bg_path: String = str(data.get("bg", ""))
	if bg_texture_rect and not bg_path.is_empty():
		var tex: Texture2D = load(bg_path) as Texture2D
		if tex:
			bg_texture_rect.texture = tex
	
	if bg_dimmer:
		bg_dimmer.color = data.get("tint", Color(0.0, 0.0, 0.0, 0.3))
	
	# Clean up previous actor sprites and tweens
	_clear_actor_tweens()
	for child in actors_container.get_children():
		child.queue_free()
	
	# Spawn Actors
	var actors: Array = data.get("actors", [])
	for act_info in actors:
		_spawn_actor(act_info)
	
	# Slide Entry Tween for caption
	if caption_panel:
		caption_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var t_cap: Tween = create_tween()
		t_cap.tween_property(caption_panel, "modulate:a", 1.0, 0.25)


## Updates page dot indicators
func _update_dots(active_idx: int) -> void:
	if not dots_hbox:
		return
	var total: int = slides_data.size()
	while dots_hbox.get_child_count() < total:
		var dot: Label = Label.new()
		dot.text = "●"
		dot.set("theme_override_font_sizes/font_size", 20)
		dots_hbox.add_child(dot)
	
	for i in range(dots_hbox.get_child_count()):
		var dot_node: Control = dots_hbox.get_child(i) as Control
		if i < total:
			dot_node.visible = true
			if i == active_idx:
				dot_node.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.25))
			else:
				dot_node.set("theme_override_colors/font_color", Color(0.4, 0.45, 0.55))
		else:
			dot_node.visible = false


## Spawns an actor sprite and assigns a subtle breathing/floating tween
func _spawn_actor(info: Dictionary) -> void:
	var tex_path: String = str(info.get("texture", ""))
	if tex_path.is_empty():
		return
	
	var tex: Texture2D = load(tex_path) as Texture2D
	if not tex:
		return
	
	var sprite: TextureRect = TextureRect.new()
	sprite.texture = tex
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Target dimensions
	var base_w: float = 400.0
	var base_h: float = 300.0
	var sc: Vector2 = info.get("scale", Vector2.ONE)
	sprite.custom_minimum_size = Vector2(base_w * sc.x, base_h * sc.y)
	sprite.size = sprite.custom_minimum_size
	
	# Centered around target position
	var pos: Vector2 = info.get("pos", Vector2(960, 540))
	sprite.position = pos - (sprite.size * 0.5)
	
	if info.has("modulate"):
		sprite.modulate = info.get("modulate")
	
	actors_container.add_child(sprite)
	
	# Assign subtle idle animation
	var anim_type: String = str(info.get("anim", "float"))
	var tween: Tween = create_tween().set_loops()
	active_actor_tweens.append(tween)
	
	match anim_type:
		"float":
			var origin_y: float = sprite.position.y
			tween.tween_property(sprite, "position:y", origin_y - 14.0, 1.4).set_trans(Tween.TRANS_SINE)
			tween.tween_property(sprite, "position:y", origin_y + 14.0, 1.4).set_trans(Tween.TRANS_SINE)
		"shake":
			var origin_pos: Vector2 = sprite.position
			tween.tween_property(sprite, "position", origin_pos + Vector2(6, -4), 0.08)
			tween.tween_property(sprite, "position", origin_pos + Vector2(-6, 4), 0.08)
			tween.tween_property(sprite, "position", origin_pos, 0.08)
			tween.tween_interval(0.5)
		"drift_right":
			var origin_x: float = sprite.position.x
			tween.tween_property(sprite, "position:x", origin_x + 30.0, 1.8).set_trans(Tween.TRANS_SINE)
			tween.tween_property(sprite, "position:x", origin_x, 1.8).set_trans(Tween.TRANS_SINE)


func _clear_actor_tweens() -> void:
	for t in active_actor_tweens:
		if is_instance_valid(t):
			t.kill()
	active_actor_tweens.clear()


func _on_prev_pressed() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_action_timestamp < DEBOUNCE_THRESHOLD_MS:
		return
	_last_action_timestamp = now
	if current_slide_index > 0:
		_show_slide(current_slide_index - 1)


func _on_next_pressed() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_action_timestamp < DEBOUNCE_THRESHOLD_MS:
		return
	_last_action_timestamp = now
	if current_slide_index < slides_data.size() - 1:
		_show_slide(current_slide_index + 1)
	else:
		_finish_comic()


func _on_skip_pressed() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_action_timestamp < DEBOUNCE_THRESHOLD_MS:
		return
	_last_action_timestamp = now
	comic_skipped.emit(current_comic_id)
	_finish_comic()


func _finish_comic() -> void:
	_clear_actor_tweens()
	var t: Tween = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func():
		visible = false
		comic_finished.emit(current_comic_id)
	)
