extends CanvasLayer

@onready var lives_label = $Control/LivesContainer/LivesLabel
var game_manager = null
var warn_count = 0  # Счетчик предупреждений

func _ready():
	# Находим GameManager
	find_game_manager()
	
	# Скрываем UI на главном экране 
	if is_on_main_menu():
		if lives_label:
			lives_label.visible = false
		print("UI: On main menu, hiding lives")
		return
	
	# Если GameManager не найден, скрываем метку жизней
	if not game_manager and lives_label:
		lives_label.visible = false
		print("UI: GameManager not found in _ready, hiding lives label.")
		return

func _process(_delta):
	# На главном экране всегда скрываем UI
	if is_on_main_menu() and lives_label and lives_label.visible:
		lives_label.visible = false
		return
	
	# Проверяем, валиден ли GameManager
	if game_manager != null and (not game_manager.is_inside_tree()):
		game_manager = null
		if lives_label:
			lives_label.visible = false
		print("UI: GameManager was freed, hiding lives counter")
		return
		
	# Если GameManager не найден, попробуем найти его снова, но не чаще 1 раза в секунду
	if game_manager == null and Engine.get_frames_drawn() % 60 == 0:
		find_game_manager()
	
	# Обновляем UI, только если GameManager найден и валиден и мы не на главном экране
	if game_manager != null and game_manager.is_inside_tree() and not is_on_main_menu():
		update_lives_display()

func update_lives_display():
	if game_manager != null and game_manager.is_inside_tree() and lives_label:
		# На главном экране всегда скрываем счетчик
		if is_on_main_menu():
			lives_label.visible = false
			return
			
		# Показываем метку в зависимости от настройки в GameManager
		lives_label.visible = game_manager.show_lives_ui
		
		# Обновляем текст количества жизней
		lives_label.text = "Lives: " + str(game_manager.lives)
		
		# Обновляем цвет в зависимости от количества жизней
		if game_manager.lives <= 1:
			lives_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))  # Красный
		elif game_manager.lives == 2:
			lives_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2, 1))  # Жёлтый
		else:
			lives_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))  # Зеленый

# Обработчик сигнала изменения видимости жизней
func _on_lives_visibility_changed(visible):
	if lives_label:
		lives_label.visible = visible
		print("UI: Lives visibility changed to", visible)

func update_ui():
	if not game_manager:
		print("UI: update_ui called, but GameManager not found.")
		# Если нет GameManager, скрываем UI
		if lives_label:
			lives_label.visible = false
		return 
		
	print("UI: update_ui called.")
	# Обновляем отображение жизней
	if lives_label:
		# На главном экране всегда скрываем
		if is_on_main_menu():
			lives_label.visible = false
		else:
			# Показываем/скрываем в зависимости от настроек GameManager
			lives_label.visible = game_manager.show_lives_ui
			# Обновляем текст
			lives_label.text = "Lives: " + str(game_manager.lives)
			# Обновляем цвет
			if game_manager.lives <= 1:
				lives_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			elif game_manager.lives == 2:
				lives_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2, 1))
			else:
				lives_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
	else:
		print("UI: update_ui - lives_label not found.")

	# <<< УДАЛЕНА ЛОГИКА ОБНОВЛЕНИЯ score_label >>>

# <<< КОНЕЦ ВОССТАНОВЛЕННОЙ ФУНКЦИИ >>>

func find_game_manager():
	# Ищем GameManager через группу - теперь это основной способ
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		print("UI: Found GameManager in scene")
		game_manager = manager
		
		# Обновляем дисплей, если нашли GameManager
		update_lives_display()

		# Подключаемся к сигналам изменения видимости
		if not game_manager.lives_visibility_changed.is_connected(_on_lives_visibility_changed):
			game_manager.lives_visibility_changed.connect(_on_lives_visibility_changed)

		return
	
	# Выводим предупреждение только первый раз, чтобы не спамить консоль
	if warn_count == 0:
		print("UI: WARNING - GameManager not found! Lives display will be hidden.")
		warn_count += 1

# Проверка, находимся ли мы на главном экране
func is_on_main_menu() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "MainTitle":
		return true
	return false
