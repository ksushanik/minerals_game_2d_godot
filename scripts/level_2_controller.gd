extends BaseLevelController

# Переопределение метода инициализации уровня
func _level_specific_setup():
	# Проверка собранных минералов
	if game_manager and game_manager.inventory_system:
		var num_minerals = _count_collected_minerals()
		
		if num_minerals < 2:
			var hint_message = "Тебе нужно собрать больше минералов для решения загадок на этом уровне."
			game_manager.show_notification(hint_message, 4.0)

# Подсчет количества собранных минералов
func _count_collected_minerals() -> int:
	var count = 0
	var inventory = game_manager.inventory_system
	
	if inventory:
		# Можно добавить проверку конкретных минералов при необходимости
		count = inventory.get_items_count()
		
	return count 