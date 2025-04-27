extends Node

@export var show_lives = true
@export var is_dark_level: bool = false

var game_manager = null
var has_applied_setting = false

func _ready():
	find_game_manager()
	apply_ui_settings()
	
	if game_manager and game_manager.has_method("update_player_light_state"):
		game_manager.update_player_light_state.call_deferred()
	
	if is_dark_level and game_manager:
		var light_crystal_path = game_manager.LIGHT_CRYSTAL_PATH
		
		if not game_manager.collected_item_ids.has(light_crystal_path):
			var hint_message = "Здесь слишком темно... Вернитесь назад и найдите Светящийся кристалл."
			if game_manager.has_method("show_notification"):
				game_manager.show_notification(hint_message, 4.0)

func find_game_manager():
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		game_manager = manager

func apply_ui_settings():
	if game_manager != null and not has_applied_setting:
		if is_instance_valid(game_manager):
			game_manager.set_lives_visibility(show_lives)
			game_manager.update_player_light_state.call_deferred()
			has_applied_setting = true
			return true
	return false

func _process(_delta):
	if game_manager == null:
		find_game_manager()
	
	if not has_applied_setting:
		if apply_ui_settings():
			set_process(false)

func is_dark() -> bool:
	return is_dark_level
