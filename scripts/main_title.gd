extends Control

# Переменные
var tween_running = false

# При готовности
func _ready():
	# Из-за изменения структуры сцены, мы на одном уровне выше чем было
	if get_parent().name == "MainTitle":
		print("Main Title UI: Ready")
	else:
		push_error("Main Title UI: Unexpected parent " + get_parent().name)

# Обработчик нажатия на кнопку "Начать игру"
func _on_start_button_pressed():
	if not tween_running:
		tween_running = true
		
		# Сбрасываем состояние игры
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager and game_manager.has_method("reset_game_state"):
			game_manager.reset_game_state()
			print("Main Title: Resetting game state before starting new game")
		
		# Создаем эффект анимации перехода
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(func(): 
			# Запускаем первый уровень
			get_tree().change_scene_to_file("res://scenes/level_0.tscn")
			tween_running = false
		)

# Обработчик нажатия на кнопку "Выход"
func _on_quit_button_pressed():
	# Плавно затемняем экран перед выходом
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func(): 
		# Выходим из игры
		get_tree().quit()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func hide_ui():
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.hide_lives()
		
		# Больше не обращаемся напрямую к UI элементам
		if game_manager.ui_manager:
			game_manager.ui_manager.hide_game_over()
