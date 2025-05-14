extends BaseLevelController

# Время до показа подсказки
@export var show_hint_after_seconds: float = 10.0

var _hint_timer: Timer

# Переопределение метода инициализации уровня
func _level_specific_setup():
	# Создаем таймер для подсказки
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	_hint_timer.wait_time = show_hint_after_seconds
	_hint_timer.timeout.connect(_on_hint_timer_timeout)
	add_child(_hint_timer)
	_hint_timer.start()
	
	# Проверка наличия движущихся платформ
	var platforms = get_tree().get_nodes_in_group("moving_platform")
	if platforms.size() > 0:
		# Здесь можно добавить специфическую логику для работы с платформами
		pass

# Показ подсказки после таймера
func _on_hint_timer_timeout():
	if game_manager:
		var hint_message = "На этом уровне тебе пригодятся прыжки с платформ для достижения высоких мест."
		game_manager.show_notification(hint_message, 4.0) 