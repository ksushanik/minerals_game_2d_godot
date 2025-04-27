extends Node

class_name LevelSystem

# === СИГНАЛЫ ===
signal level_changed(level_number)
signal all_levels_completed

# === НАСТРОЙКИ УРОВНЕЙ ===
@export_group("Level Settings")
@export var current_level: int = 1
@export var total_levels: int = 4
@export var main_menu_scene: String = "res://scenes/main_title.tscn"
@export var level_scene_prefix: String = "res://scenes/level_"
@export var level_scene_suffix: String = ".tscn"
@export var game_complete_delay: float = 3.0

# === СОСТОЯНИЕ УРОВНЕЙ ===
var is_current_level_dark: bool = false
var level_transition_timer: Timer
var custom_level_paths: Dictionary = {}  # Для особых случаев, когда путь не соответствует шаблону

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	level_transition_timer = Timer.new()
	level_transition_timer.one_shot = true
	add_child(level_transition_timer)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func set_current_level(level_num: int):
	current_level = level_num
	is_current_level_dark = _check_current_level_darkness()
	level_changed.emit(current_level)

func get_current_level() -> int:
	# Проверяем имя текущей сцены для определения нулевого уровня
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		if scene_name == "Level0" or scene_name.to_lower().contains("level0") or scene_name.to_lower().contains("level_0"):
			print("LevelSystem: Detected Level0 by name, returning 0 instead of", current_level)
			return 0
	
	return current_level

func is_level_dark() -> bool:
	return is_current_level_dark

func go_to_next_level():
	var next_level = current_level + 1
	
	if next_level <= total_levels:
		go_to_level(next_level)
	else:
		complete_game()

func go_to_level(level_number: int, custom_path: String = ""):
	# Проверяем, есть ли кастомный путь для этого уровня
	var scene_path = ""
	
	if custom_path:
		scene_path = custom_path
	elif custom_level_paths.has(level_number):
		scene_path = custom_level_paths[level_number]
	else:
		scene_path = level_scene_prefix + str(level_number) + level_scene_suffix
	
	set_current_level(level_number)
	
	# Переключаем сцену
	if get_tree():
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			push_error("Failed to change scene to: " + scene_path)
	else:
		push_error("SceneTree not available, cannot change scene")

func register_custom_level_path(level_number: int, scene_path: String):
	custom_level_paths[level_number] = scene_path

func complete_game():
	if level_transition_timer:
		level_transition_timer.timeout.connect(_on_game_complete_timer_timeout, CONNECT_ONE_SHOT)
		level_transition_timer.start(game_complete_delay)

func reset_level_system():
	current_level = 1
	is_current_level_dark = false

# === СЛУЖЕБНЫЕ МЕТОДЫ ===
func _check_current_level_darkness() -> bool:
	# Попытка определить, темный ли текущий уровень
	
	# Метод 1: Проверяем, есть ли у текущей сцены метод is_dark()
	var current_scene = get_tree().current_scene
	if is_instance_valid(current_scene) and current_scene.has_method("is_dark"):
		var is_dark = current_scene.is_dark()
		return is_dark
		
	# Метод 2: Ищем LevelController в сцене
	var level_controller = get_tree().get_first_node_in_group("level_controller")
	if level_controller and level_controller.has_method("is_dark"):
		var is_dark = level_controller.is_dark()
		return is_dark
	
	# Метод 3: Прямая проверка наличия CanvasModulate с тёмным цветом
	var canvas_modulate = get_tree().get_first_node_in_group("dark_canvas")
	if canvas_modulate and canvas_modulate is CanvasModulate:
		var is_dark = canvas_modulate.color.r < 0.3 and canvas_modulate.color.g < 0.3 and canvas_modulate.color.b < 0.3
		return is_dark
		
	# Метод 4: Поиск CanvasModulate в дереве сцены
	var canvas_nodes = get_tree().get_nodes_in_group("canvas_modulate")
	if canvas_nodes.size() > 0:
		for node in canvas_nodes:
			if node is CanvasModulate:
				var is_dark = node.color.r < 0.3 and node.color.g < 0.3 and node.color.b < 0.3
				return is_dark
				
	# Если всё ещё не определили, ищем любой CanvasModulate
	var all_canvas_modulates = []
	_find_canvas_modulates(get_tree().current_scene, all_canvas_modulates)
	
	if all_canvas_modulates.size() > 0:
		for cm in all_canvas_modulates:
			var is_dark = cm.color.r < 0.3 and cm.color.g < 0.3 and cm.color.b < 0.3
			if is_dark:
				return true
	
	return false

# Вспомогательная функция для рекурсивного поиска CanvasModulate в сцене
func _find_canvas_modulates(node: Node, result: Array):
	if node is CanvasModulate:
		result.append(node)
		
	for child in node.get_children():
		_find_canvas_modulates(child, result)

func _on_game_complete_timer_timeout():
	all_levels_completed.emit()
	
	if get_tree():
		get_tree().change_scene_to_file(main_menu_scene)

# Метод для принудительной установки темного режима
func force_set_dark_level(is_dark: bool):
	is_current_level_dark = is_dark 