extends Node

class_name PlayerFacade

# === СИГНАЛЫ ===
signal lives_visibility_changed(is_visible)
signal dialog_state_changed(is_active)
signal light_update_needed

# === ВНЕШНИЕ КОМПОНЕНТЫ ===
var player_state_manager: PlayerStateManager
var ui_manager: UIManager

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _light_update_timer: Timer = null
var _needs_light_update: bool = false

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	add_to_group("player_facade")
	
	# Создаем таймер для обновления света
	_light_update_timer = Timer.new()
	_light_update_timer.one_shot = true
	_light_update_timer.wait_time = 0.5
	_light_update_timer.timeout.connect(_on_light_update_timer_timeout)
	add_child(_light_update_timer)

# === НАСТРОЙКА КОМПОНЕНТОВ ===
func setup(player_state: PlayerStateManager, ui: UIManager):
	player_state_manager = player_state
	ui_manager = ui
	
	# Подключаем сигналы
	if player_state_manager:
		player_state_manager.dialog_state_changed.connect(_on_dialog_state_changed)
		
	# Если PlayerStateManager не был полностью инициализирован, инициализируем его
	initialize_player_state_manager()

# Полная инициализация PlayerStateManager
func initialize_player_state_manager():
	if not player_state_manager:
		return
		
	# Получаем ссылки на необходимые компоненты через дерево сцены
	var inventory_system = null
	var level_system = null
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		inventory_system = game_manager.inventory_system
		level_system = game_manager.level_system
		
	# Инициализируем PlayerStateManager
	if ui_manager and inventory_system and level_system:
		player_state_manager.setup(ui_manager, inventory_system, level_system)

# === ОБРАБОТЧИКИ СИГНАЛОВ ===
func _on_dialog_state_changed(is_active: bool):
	dialog_state_changed.emit(is_active)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func decrease_lives() -> bool:
	if player_state_manager:
		return player_state_manager.decrease_lives()
	return true  # По умолчанию считаем, что все в порядке

func set_lives_visibility(visible: bool):
	if ui_manager:
		ui_manager.set_lives_visibility(visible)
	lives_visibility_changed.emit(visible)

func hide_lives():
	set_lives_visibility(false)

func show_lives():
	set_lives_visibility(true)

func set_dialog_active(active: bool):
	if player_state_manager:
		player_state_manager.set_dialog_active(active)

func get_dialog_active() -> bool:
	if player_state_manager:
		return player_state_manager.get_dialog_active()
	return false

func reset_player():
	if player_state_manager:
		player_state_manager.reset_player_state()
		
	# Сбрасываем состояние самого игрока
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("reset_state"):
			player.reset_state()
		# Прямой сброс важных переменных игрока для исправления бага с зависанием
		if "is_player_dead" in player:
			player.is_player_dead = false
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(true)
		# Восстанавливаем коллизии
		if player.has_method("set_collision_layer_value"):
			player.set_collision_layer_value(1, true)
			player.set_collision_mask_value(1, true)

# === МЕТОДЫ ДЛЯ ОБНОВЛЕНИЯ СВЕТА ИГРОКА ===
## Обновляет состояние света игрока на основе наличия кристалла
## и текущего уровня (темный или светлый)
func update_player_light_state():
	if player_state_manager:
		player_state_manager.update_player_light_state()

## Возвращает true, если свет игрока активен
func is_player_light_active() -> bool:
	if player_state_manager:
		return player_state_manager.is_player_light_active
	return false
	
## Отмечает необходимость обновления света, запускает 
## отложенное обновление через таймер
func request_light_update():
	_needs_light_update = true
	if _light_update_timer.is_stopped():
		_light_update_timer.start()
	light_update_needed.emit()
	
## Устаревший метод для совместимости, использует новый метод request_light_update
func mark_for_light_update():
	request_light_update()
	
## Обновляет свет игрока и его представление на всех уровнях
func update_player_light():
	if player_state_manager:
		player_state_manager.update_player_light_state()
		
	# Дополнительно вызываем обновление на уровне
	var level_controller = get_tree().get_first_node_in_group("level_controller")
	if level_controller and level_controller.has_method("_update_player_light"):
		level_controller._update_player_light()

## Обработчик таймера обновления света
func _on_light_update_timer_timeout():
	_needs_light_update = false
	update_player_light()
	_light_update_timer.stop()
	
## Обрабатывает обновление света в каждом кадре, если необходимо
func _process(_delta):
	if _needs_light_update and _light_update_timer.is_stopped():
		_light_update_timer.start()

# === МЕТОДЫ ДЛЯ СОСТОЯНИЯ ИГРОКА ===
func is_player_dead() -> bool:
	if player_state_manager:
		return player_state_manager.is_player_dead()
	return false 