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

	# <<< ВЫЗЫВАЕМ ОБНОВЛЕНИЕ СОСТОЯНИЯ СВЕТА ПОСЛЕ ЗАГРУЗКИ УРОВНЯ >>>
	var game_manager = get_node_or_null("/root/GameManager") # Попробуем найти снова
	if game_manager and game_manager.has_method("update_player_light_state"):
		print("Level0Controller: Calling GameManager.update_player_light_state deferred")
		game_manager.update_player_light_state.call_deferred()
	else:
		if not game_manager:
			print("Level0Controller: GameManager not found in _ready(), cannot update light state.")
		else:
			print("Level0Controller: ERROR - GameManager found, but missing update_player_light_state method!")
	# --------------------------------------------------------------

# --- ФУНКЦИЯ ПРОВЕРКИ ТЕМНОТЫ --- 
# Сообщает GameManager, темный ли этот уровень
func is_dark() -> bool:
	return false
# --- --------------------------- --- 