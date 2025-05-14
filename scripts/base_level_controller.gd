extends Node

class_name BaseLevelController

# === ЭКСПОРТИРУЕМЫЕ НАСТРОЙКИ ===
@export var show_lives = true
@export var is_dark_level: bool = false

# === ПЕРЕМЕННЫЕ ===
var game_manager = null
var has_applied_setting = false

# === БАЗОВЫЕ МЕТОДЫ ===
func _ready():
	add_to_group("level_controller")
	find_game_manager()
	
	# Принудительно устанавливаем темный режим, если включен в инспекторе
	if is_dark_level:
		set_dark_level(true)
	
	apply_ui_settings()
	
	# Обновляем состояние света игрока после загрузки уровня
	call_deferred("_update_player_light")
	
	# Вызываем метод для специфичной инициализации уровня
	_level_specific_setup()

func _process(_delta):
	if game_manager == null:
		find_game_manager()
	
	if not has_applied_setting:
		if apply_ui_settings():
			set_process(false)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func find_game_manager():
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		game_manager = manager

func apply_ui_settings():
	if game_manager != null and not has_applied_setting:
		if is_instance_valid(game_manager):
			game_manager.set_lives_visibility(show_lives)
			
			if is_dark_level:
				var has_light_crystal = false
				
				if game_manager.inventory_system:
					has_light_crystal = game_manager.inventory_system.has_item(
						game_manager.light_crystal_resource.resource_path
					)
				
				if not has_light_crystal:
					var hint_message = "Здесь слишком темно... Вернитесь назад и найдите Светящийся кристалл."
					game_manager.show_notification(hint_message, 4.0)
			
			has_applied_setting = true
			return true
	return false

func is_dark() -> bool:
	return is_dark_level

# Метод для установки темного режима принудительно
func set_dark_level(dark: bool):
	is_dark_level = dark
	
	# Обновляем состояние в LevelSystem
	if game_manager and game_manager.level_system and game_manager.level_system.has_method("force_set_dark_level"):
		game_manager.level_system.force_set_dark_level(dark)
	
	# Применяем темный режим ко всем CanvasModulate в сцене
	_update_canvas_modulate_nodes(dark)
	
	# Обновляем свет игрока, если это возможно
	if game_manager and game_manager.player_facade:
		# Небольшая задержка, чтобы успели обновиться все значения
		await get_tree().create_timer(0.1).timeout
		game_manager.player_facade.update_player_light_state()

# === СЛУЖЕБНЫЕ МЕТОДЫ ===
# Отдельная функция для обновления света игрока
func _update_player_light():
	# Уменьшенная задержка для инициализации сцены
	await get_tree().create_timer(0.3).timeout
	
	# Сначала проверяем через GameManager
	if game_manager and game_manager.player_facade:
		game_manager.player_facade.update_player_light_state()

# === МЕТОДЫ ДЛЯ ПЕРЕОПРЕДЕЛЕНИЯ ===
# Метод для специфичной инициализации уровня, должен быть переопределен в дочерних классах
func _level_specific_setup():
	pass # Базовая реализация ничего не делает 

func _update_canvas_modulate_nodes(dark: bool):
	var dark_color = Color(0, 0, 0, 1)
	var light_color = Color(1, 1, 1, 1)
	var target_color = dark_color if dark else light_color
	
	# Обновляем все CanvasModulate в группе
	for cm in get_tree().get_nodes_in_group("canvas_modulate"):
		if cm is CanvasModulate:
			cm.color = target_color
	
	# Ищем CanvasModulate в UI элементах интерфейса
	for ui in get_tree().get_nodes_in_group("ui_layer"):
		if ui.has_node("CanvasModulate"):
			ui.get_node("CanvasModulate").color = target_color
	
	# Если есть CanvasModulate в корне сцены
	if get_tree().current_scene.has_node("CanvasModulate"):
		get_tree().current_scene.get_node("CanvasModulate").color = target_color 