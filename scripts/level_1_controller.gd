extends BaseLevelController

# Переопределение метода инициализации уровня
func _level_specific_setup():
	if game_manager and game_manager.inventory_system:
		var has_light_crystal = game_manager.inventory_system.has_item(
			game_manager.light_crystal_resource.resource_path
		)
		
		if not has_light_crystal:
			var hint_message = "Здесь очень темно... Найди Светящийся кристалл, чтобы осветить путь."
			game_manager.show_notification(hint_message, 5.0) 