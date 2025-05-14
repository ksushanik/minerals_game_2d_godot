extends Node

class_name LevelFacade

# === СИГНАЛЫ ===
signal level_changed(level_number)
signal dark_level_changed(is_dark)
signal level_completed

# === ВНЕШНИЕ КОМПОНЕНТЫ ===
var _level_system: LevelSystem

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	add_to_group("level_facade")

# === НАСТРОЙКА КОМПОНЕНТОВ ===
## Инициализирует фасад, передавая ссылку на LevelSystem
func setup(level_system: LevelSystem):
	_level_system = level_system
	
	# Подключаем сигналы от LevelSystem
	if _level_system:
		if _level_system.has_signal("level_changed"):
			_level_system.level_changed.connect(_on_level_changed)
		if _level_system.has_signal("level_completed"):
			_level_system.level_completed.connect(_on_level_completed)

# === ОБРАБОТЧИКИ СИГНАЛОВ ===
func _on_level_changed(level_number: int):
	level_changed.emit(level_number)
	
	# Проверяем темный ли уровень
	if _level_system:
		var is_dark = _level_system.is_level_dark()
		dark_level_changed.emit(is_dark)
		
func _on_level_completed():
	level_completed.emit()

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
## Загружает указанный уровень. Если custom_path не пуст, используется он вместо стандартного пути
func go_to_level(level_number: int, custom_path: String = ""):
	if _level_system:
		_level_system.go_to_level(level_number, custom_path)
	
	# Проверяем коллекционные предметы после загрузки уровня
	call_deferred("_check_collectibles")

## Устанавливает текущий номер уровня
func set_current_level(level_num: int):
	if _level_system:
		_level_system.set_current_level(level_num)

## Запрашивает переход на следующий уровень
func request_next_level():
	if _level_system:
		_level_system.request_next_level()

## Возвращает true, если текущий уровень темный
func is_level_dark() -> bool:
	if _level_system:
		return _level_system.is_level_dark()
	return false

## Принудительно устанавливает темный режим уровня
func force_set_dark_level(is_dark: bool):
	if _level_system:
		_level_system.force_set_dark_level(is_dark)

## Сбрасывает состояние системы уровней
func reset_level_system():
	if _level_system:
		_level_system.reset_level_state()

# === ВНУТРЕННИЕ МЕТОДЫ ===
## Проверяет все коллекционные предметы на уровне после его загрузки
func _check_collectibles():
	# Ждем немного, чтобы уровень полностью загрузился
	await get_tree().create_timer(0.1).timeout
	
	# Проверяем все коллекционные предметы
	var collectibles = get_tree().get_nodes_in_group("collectible")
	for item in collectibles:
		if item.has_method("check_if_already_collected"):
			item.check_if_already_collected() 