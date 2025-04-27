extends Node

# Загружаем сцену профессора
var professor_scene = preload("res://scenes/professor.tscn")

func _ready():
	print("Level0Controller: _ready() called")
	
	# Проверяем, существует ли уже профессор
	var existing_professor = get_node_or_null("../Professor")
	if existing_professor:
		print("Level0Controller: Professor already exists in scene")
		return
	
	# Создаем профессора
	var professor_instance = professor_scene.instantiate()
	
	# Устанавливаем позицию
	professor_instance.position = Vector2(110, 42)
	
	# Добавляем профессора в сцену (на тот же уровень, что и портал)
	get_parent().add_child(professor_instance)
	print("Level0Controller: Professor added to scene at position (110, 42)") 

	# Обновляем состояние света игрока после загрузки уровня
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.player_state_manager:
		print("Level0Controller: Calling PlayerStateManager.update_player_light_state")
		game_manager.player_state_manager.update_player_light_state()
	else:
		if not game_manager:
			print("Level0Controller: GameManager not found in _ready(), cannot update light state.")
		else:
			print("Level0Controller: ERROR - PlayerStateManager not found in GameManager!")

# --- ФУНКЦИЯ ПРОВЕРКИ ТЕМНОТЫ --- 
# Сообщает GameManager, темный ли этот уровень
func is_dark() -> bool:
	return false
# --- --------------------------- --- 