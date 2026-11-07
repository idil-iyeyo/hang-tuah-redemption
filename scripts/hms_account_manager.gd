class_name HMSAccountManagerNode
extends Node

## Signals for Huawei Mobile Services (HMS) Account Kit
signal sign_in_success(display_name: String, open_id: String)
signal sign_in_failed(error_code: int, error_message: String)
signal sign_out_success()

var is_signed_in: bool = false
var player_name: String = ""
var player_id: String = ""
var is_mock_mode: bool = true

var _android_plugin: Object = null


func _ready() -> void:
	_init_plugin()


func _init_plugin() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("HMSAccountPlugin"):
		_android_plugin = Engine.get_singleton("HMSAccountPlugin")
		is_mock_mode = false
		if _android_plugin.has_signal("sign_in_success"):
			_android_plugin.connect("sign_in_success", Callable(self, "_on_native_sign_in_success"))
		if _android_plugin.has_signal("sign_in_failed"):
			_android_plugin.connect("sign_in_failed", Callable(self, "_on_native_sign_in_failed"))
		if _android_plugin.has_signal("sign_out_success"):
			_android_plugin.connect("sign_out_success", Callable(self, "_on_native_sign_out_success"))
	else:
		is_mock_mode = true


## Silent sign-in: Checks cached login or asks HMS Core without user prompt
func silent_sign_in() -> void:
	var saved_identity: Dictionary = SaveManager.get_player_identity()
	if saved_identity.get("huawei_signed_in", false) and not saved_identity.get("huawei_display_name", "").is_empty():
		player_name = saved_identity.get("huawei_display_name", "")
		player_id = saved_identity.get("huawei_player_id", "")
		is_signed_in = true
		sign_in_success.emit(player_name, player_id)
		return

	if not is_mock_mode and _android_plugin and _android_plugin.has_method("silentSignIn"):
		_android_plugin.call("silentSignIn")
	else:
		# In Mock Mode on Desktop/Editor, do not force-login if no identity was saved.
		# Waiting for explicit button tap allows full testing of the Sign-In button flow.
		pass


## Interactive sign-in: Opens Huawei ID authorization UI or simulates auth in mock mode
func sign_in() -> void:
	if not is_mock_mode and _android_plugin and _android_plugin.has_method("signIn"):
		_android_plugin.call("signIn")
		return

	# Mock Mode: Simulates realistic 350ms network / token resolution latency
	var tree: SceneTree = get_tree()
	if tree:
		var timer: SceneTreeTimer = tree.create_timer(0.35)
		timer.timeout.connect(func():
			player_name = "Hang Tuah"
			player_id = "hw_pilot_00192"
			is_signed_in = true
			SaveManager.set_player_identity(player_id, player_name)
			sign_in_success.emit(player_name, player_id)
		)
	else:
		player_name = "Hang Tuah"
		player_id = "hw_pilot_00192"
		is_signed_in = true
		SaveManager.set_player_identity(player_id, player_name)
		sign_in_success.emit(player_name, player_id)


## Signs out of Huawei ID session
func sign_out() -> void:
	if not is_mock_mode and _android_plugin and _android_plugin.has_method("signOut"):
		_android_plugin.call("signOut")
		return

	player_name = ""
	player_id = ""
	is_signed_in = false
	SaveManager.clear_player_identity()
	sign_out_success.emit()


func get_player_display_name() -> String:
	return player_name


func is_user_signed_in() -> bool:
	return is_signed_in


# -----------------------------------------------------------------------------
# Native Plugin Callbacks
# -----------------------------------------------------------------------------

func _on_native_sign_in_success(p_display_name: String, p_open_id: String) -> void:
	player_name = p_display_name
	player_id = p_open_id
	is_signed_in = true
	SaveManager.set_player_identity(player_id, player_name)
	sign_in_success.emit(player_name, player_id)


func _on_native_sign_in_failed(error_code: int, error_msg: String) -> void:
	is_signed_in = false
	sign_in_failed.emit(error_code, error_msg)


func _on_native_sign_out_success() -> void:
	player_name = ""
	player_id = ""
	is_signed_in = false
	SaveManager.clear_player_identity()
	sign_out_success.emit()
