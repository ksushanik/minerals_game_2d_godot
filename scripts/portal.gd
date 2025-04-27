extends Area2D

# Добавляем экспорт переменной для указания конкретного следующего уровня
@export var next_level_path: String = ""
# <<< УДАЛЯЕМ ОПЦИЮ ПОРТАЛА ВОЗВРАТА >>>
# @export var is_return_portal: bool = false
# <<< НОВАЯ ОПЦИЯ: Требовать кристалл света для входа >>>
@export var require_light_crystal: bool = false

# --- Настройки анимации --- 
@export var pulse_scale_factor: float = 1.1 # Насколько увеличится масштаб
@export var pulse_duration: float = 0.5 # Длительность одной фазы пульсации (вверх или вниз)
@export var pulse_color: Color = Color(1.2, 1.2, 1.5, 1.0) # Цвет свечения (чуть ярче и синее)
# -------------------------

var game_manager = null
@onready var sprite: Sprite2D = $Sprite2D
@onready var proximity_detector: Area2D = $ProximityDetector # <<< ДОБАВЛЯЕМ ССЫЛКУ

var default_scale: Vector2
var default_modulate: Color
var pulse_tween: Tween = null

func _ready() -> void:
	print("Portal initialized! (Require Light Crystal: %s)" % require_light_crystal) # <<< Обновим лог
	
	# Сохраняем исходные значения спрайта
	default_scale = sprite.scale
	default_modulate = sprite.modulate
	
	# <<< УДАЛЯЕМ ВИЗУАЛЬНОЕ ОТЛИЧИЕ ДЛЯ ПОРТАЛА ВОЗВРАТА >>>
	# if is_return_portal:
	# 	default_modulate = Color(0.8, 0.9, 1.1) 
	# 	sprite.modulate = default_modulate 
	# -------------------------------------------
	
	# Получаем GameManager как синглтон
	find_game_manager()
	
	# Убедимся, что сигналы подключены
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	# <<< ПОДКЛЮЧАЕМ СИГНАЛЫ ОТ ProximityDetector (хотя они уже есть в .tscn, но для надежности) >>>
	if not proximity_detector.body_entered.is_connected(_on_ProximityDetector_body_entered):
		proximity_detector.body_entered.connect(_on_ProximityDetector_body_entered)
	if not proximity_detector.body_exited.is_connected(_on_ProximityDetector_body_exited):
		proximity_detector.body_exited.connect(_on_ProximityDetector_body_exited)
	
	print("Portal signals connected!")

# Находим GameManager сначала как синглтон, потом (если не найден) через группу
func find_game_manager() -> void:
	# Попытка найти GameManager как синглтон
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		print("Portal: Found GameManager as singleton")
		return
		
	# Резервный способ - через группу
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		print("Portal: Found GameManager in scene through group")
	else:
		print("Portal: WARNING - GameManager not found!")

# Определяем текущий уровень из имени сцены (например, Level_0, Level_1, и т.д.)
func get_current_level() -> int:
	var scene = get_tree().current_scene
	if scene == null:
		print("Portal: Current scene is null!")
		return 0  # Возвращаем 0 по умолчанию (или другое безопасное значение)
	
	var scene_node_name = scene.name # Используем имя узла
	print("Portal: Current scene node name:", scene_node_name)
	
	# Ищем номер уровня в имени УЗЛА (например, Level0, Level1)
	if scene_node_name.begins_with("Level"): # Проверяем префикс "Level"
		var level_string = scene_node_name.trim_prefix("Level")
		if level_string.is_valid_int():
			var level_number = level_string.to_int()
			print("Portal: Detected level number from node name:", level_number)
			return level_number
		else:
			print("Portal: Could not parse number after 'Level' in node name:", scene_node_name)
			return 0 # Возвращаем 0, если парсинг не удался
		
	# Если мы здесь, значит имя узла не начинается с 'Level'
	print("Portal: Scene node name does not start with 'Level':", scene_node_name)
	return 0  # Возвращаем 0 по умолчанию

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	if game_manager == null:
		find_game_manager()
		
	if game_manager == null:
		return

	if require_light_crystal:
		var light_crystal_path = "res://resources/items/light_crystal.tres"
		
		if game_manager.has_meta("LIGHT_CRYSTAL_PATH"):
			light_crystal_path = game_manager.get_meta("LIGHT_CRYSTAL_PATH")
		elif "LIGHT_CRYSTAL_PATH" in game_manager:
			light_crystal_path = game_manager.LIGHT_CRYSTAL_PATH
			
		if not game_manager.collected_item_ids.has(light_crystal_path):
			var hint_message = "Вы не можете войти сюда без Светящегося кристалла."
			if game_manager.has_method("show_notification"):
				game_manager.show_notification(hint_message, 3.0)
			return
	
	if next_level_path and not next_level_path.is_empty():
		if game_manager.has_method("go_to_level"):
			game_manager.go_to_level(-1, next_level_path)
		return
	
	var current_level = get_current_level()
	var next_level_num = current_level + 1
	var next_level_scene_path = "res://scenes/level_" + str(next_level_num) + ".tscn"
	
	var temp_total_levels = 4
	if next_level_num > temp_total_levels:
		if game_manager.has_method("next_level"):
			game_manager.current_level = temp_total_levels 
			game_manager.next_level()
		return
	
	if game_manager.has_method("go_to_level"):
		game_manager.go_to_level(next_level_num, next_level_scene_path)

# Обновление в процессе работы, чтобы гарантировать наличие GameManager
# Это полезно, если портал создается раньше GameManager
func _process(_delta: float) -> void:
	if game_manager == null and Engine.get_frames_drawn() % 60 == 0:  # Проверяем раз в секунду
		find_game_manager()
		
		# Если удалось найти GameManager, останавливаем процесс
		if game_manager != null:
			set_process(false)


# --- НОВЫЕ ФУНКЦИИ ДЛЯ ПУЛЬСАЦИИ ---

func _on_ProximityDetector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Portal: Player entered proximity zone.")
		start_pulsing()

func _on_ProximityDetector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Portal: Player exited proximity zone.")
		stop_pulsing()

# Запускает анимацию пульсации
func start_pulsing() -> void:
	# Останавливаем предыдущий tween, если он был
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	
	pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Анимация масштаба
	pulse_tween.tween_property(sprite, "scale", default_scale * pulse_scale_factor, pulse_duration)
	pulse_tween.tween_property(sprite, "scale", default_scale, pulse_duration)
	
	# Анимация цвета (свечение)
	pulse_tween.parallel().tween_property(sprite, "modulate", pulse_color, pulse_duration)
	pulse_tween.parallel().tween_property(sprite, "modulate", default_modulate, pulse_duration)
	
	pulse_tween.play()

# Останавливает анимацию пульсации и возвращает к дефолту
func stop_pulsing() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		pulse_tween = null
	
	# Плавно возвращаем к исходному состоянию на всякий случай
	var reset_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	reset_tween.tween_property(sprite, "scale", default_scale, pulse_duration / 2.0)
	reset_tween.parallel().tween_property(sprite, "modulate", default_modulate, pulse_duration / 2.0)
	reset_tween.play()

# --- ----------------------------- ---
