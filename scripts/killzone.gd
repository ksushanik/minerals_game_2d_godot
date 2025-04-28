extends Area2D

var game_manager = null
# Добавим эффект вспышки урона
var flash_color = Color(1, 0, 0, 0.3)
var flash_rect : ColorRect

func _ready():
	print("Killzone initialized, looking for GameManager...")
	find_game_manager()
	
	# Создаем эффект вспышки урона (красный экран)
	flash_rect = ColorRect.new()
	flash_rect.color = Color(0, 0, 0, 0)  # Изначально прозрачный
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Не перехватывает клики
	
	# Добавляем на верхний уровень канваса, чтобы был поверх всего
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Высокий слой, чтобы был поверх всего
	add_child(canvas_layer)
	canvas_layer.add_child(flash_rect)
	
	# Устанавливаем размер на весь экран
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Подключаем сигнал
	body_entered.connect(_on_body_entered)

# Находим GameManager в сцене
func find_game_manager():
	# Проверяем, есть ли GameManager на текущем уровне
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		game_manager = manager
		print("Killzone: Found GameManager in scene")
		
		# Подписываемся на сигналы GameManager
		if not game_manager.game_over.is_connected(_on_game_over):
			game_manager.game_over.connect(_on_game_over)
		return
		
	print("Killzone: WARNING - GameManager not found!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered killzone!")
		
		# Показываем эффект вспышки урона
		flash_damage()
		
		# На всякий случай ищем менеджер снова, если его нет
		if not game_manager or game_manager == null or not game_manager.is_inside_tree():
			find_game_manager()
			
		# Отключаем коллизию игрока для предотвращения повторного срабатывания
		if body.has_node("CollisionShape2D"):
			body.get_node("CollisionShape2D").set_deferred("disabled", true)
			
		# Проверяем, является ли текущий уровень нулевым
		var is_tutorial_level = false
		var current_scene = get_tree().current_scene
		if current_scene:
			var scene_name = current_scene.name
			var lowercase_name = scene_name.to_lower()
			# Проверяем разные варианты именования нулевого уровня
			if lowercase_name.contains("level_0") or lowercase_name == "level_0" or lowercase_name.contains("level0") or lowercase_name == "level0" or scene_name == "Level0":
				is_tutorial_level = true
				print("Killzone: Tutorial level detected! Player will be respawned without life loss.")
		
		# Если это нулевой уровень, просто перезагружаем сцену без уменьшения жизней
		if is_tutorial_level:
			print("Killzone: Reloading tutorial level in 1 second...")
			await get_tree().create_timer(1.0).timeout
			print("Killzone: Reloading tutorial level NOW!")
			call_deferred("_reload_scene")
			return
				
		# Уменьшаем количество жизней
		if game_manager:
			print("Killzone: Found game_manager, decreasing lives...")
			var has_lives = await game_manager.decrease_lives()
			print("Killzone: Decreased lives result: ", has_lives)
			
			if has_lives:
				# Если жизни остались, перезагружаем текущую сцену через секунду
				print("Killzone: Player has lives left, reloading scene in 1 second...")
				await get_tree().create_timer(1.0).timeout
				print("Killzone: Reloading current scene NOW!")
				call_deferred("_reload_scene")
			else:
				print("Killzone: Player has no lives left, game over!")
		else:
			print("Killzone: No GameManager found, reloading scene directly")
			# Если не нашли GameManager, просто перезагружаем сцену с небольшой задержкой
			await get_tree().create_timer(1.0).timeout
			call_deferred("_reload_scene")

# Обработчик сигнала game_over от GameManager
func _on_game_over():
	print("Killzone: Received game_over signal")
	
	# Проверка на валидность get_tree() и сцены
	if not is_inside_tree():
		print("Killzone: Node is no longer valid, can't change scene")
		return
		
	# Безопасное изменение сцены
	if get_tree():
		# Переход на главное меню с задержкой
		await get_tree().create_timer(2.0).timeout  # Задержка для отображения Game Over
		
		# Явно скрываем Game Over перед сменой сцены
		if game_manager and game_manager.ui_manager:
			game_manager.ui_manager.hide_game_over()
			# Даем небольшую задержку, чтобы анимация скрытия отработала
			await get_tree().create_timer(0.4).timeout
		
		# Сбрасываем состояние игры перед переходом в главное меню
		if game_manager and game_manager.has_method("reset_game_state"):
			print("Killzone: Resetting game state before returning to main menu")
			game_manager.reset_game_state()
		
		# Еще раз проверяем, что get_tree() валиден
		if get_tree():
			get_tree().change_scene_to_file("res://scenes/main_title.tscn")
		else:
			print("Killzone: SceneTree is no longer valid after timeout")
	else:
		print("Killzone: SceneTree not available, can't change scene")

func flash_damage():
	if flash_rect:
		# Устанавливаем красный цвет
		flash_rect.color = flash_color
		
		# Создаем анимацию затухания
		var tween = create_tween()
		tween.tween_property(flash_rect, "color", Color(0, 0, 0, 0), 0.5)
		tween.play()

# Отдельная функция для перезагрузки сцены
func _reload_scene():
	print("Killzone: Actually reloading scene now...")
	# Отправляем сигнал GameManager'у о необходимости обновить свет после перезагрузки
	if game_manager and game_manager.has_method("mark_for_light_update"):
		game_manager.mark_for_light_update()
		print("Killzone: Requested light update from GameManager")
	
	get_tree().reload_current_scene()

# Обновляем состояние света игрока после перезагрузки уровня
func _update_player_light():
	print("Killzone: Updating player light state after reload...")
	# Находим GameManager, если он еще не найден
	if not game_manager:
		find_game_manager()
	
	# Обновляем состояние света
	if game_manager and game_manager.player_facade:
		game_manager.player_facade.update_player_light_state()
		print("Killzone: Player light state updated successfully")
	else:
		print("Killzone: Could not update player light, GameManager or PlayerFacade not found")
