extends BaseLevelController

# Загружаем сцену профессора
var professor_scene = preload("res://scenes/professor.tscn")

# Переопределяем метод для специфичной инициализации уровня
func _level_specific_setup():
	# Проверяем, существует ли уже профессор
	var existing_professor = get_node_or_null("../Professor")
	if existing_professor:
		return
	
	# Создаем профессора и добавляем в сцену
	var professor_instance = professor_scene.instantiate()
	professor_instance.position = Vector2(110, 42)
	get_parent().add_child(professor_instance)

	# Обновляем состояние света игрока
	if game_manager and game_manager.player_state_manager:
		game_manager.player_state_manager.update_player_light_state()

# Переопределяем метод проверки темноты из базового класса
func is_dark() -> bool:
	return false # Нулевой уровень не темный 