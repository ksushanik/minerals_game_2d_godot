extends Node

# Сигналы
signal next_level_requested
signal game_over
signal game_completed
signal lives_visibility_changed(is_visible)
signal item_collected_signal(item_data: ItemData)
signal dialog_state_changed(is_active)

# Настройки компонентов
@export_group("Manager Components")
@export var ui_manager_scene: PackedScene
@export var inventory_system_scene: PackedScene
@export var level_system_scene: PackedScene
@export var player_state_manager_scene: PackedScene

@export var game_flow_manager_scene: PackedScene
@export var player_facade_scene: PackedScene
@export var ui_facade_scene: PackedScene
@export var inventory_facade_scene: PackedScene

@export_group("Resources")
@export var light_crystal_resource: Resource
@export var iron_resource: Resource

# Компоненты игры
var ui_manager: UIManager
var inventory_system: InventorySystem
var level_system: LevelSystem
var _player_state_manager: PlayerStateManager

# Фасады
var game_flow_manager: GameFlowManager
var player_facade: PlayerFacade
var ui_facade: UIFacade  
var inventory_facade: InventoryFacade

func _ready():
	add_to_group("game_manager")
	_initialize_components()
	_connect_signals()

func _initialize_components():
	_initialize_base_systems()
	_initialize_facades()
	_setup_connections()

func _initialize_base_systems():
	if ui_manager_scene:
		ui_manager = ui_manager_scene.instantiate()
		add_child(ui_manager)
	else:
		push_error("GameManager: UI Manager scene not set!")
	
	if inventory_system_scene:
		inventory_system = inventory_system_scene.instantiate()
		add_child(inventory_system)
	else:
		push_error("GameManager: Inventory System scene not set!")
	
	if level_system_scene:
		level_system = level_system_scene.instantiate()
		add_child(level_system)
	else:
		push_error("GameManager: Level System scene not set!")
	
	if player_state_manager_scene:
		_player_state_manager = player_state_manager_scene.instantiate()
		add_child(_player_state_manager)
	else:
		push_error("GameManager: Player State Manager scene not set!")

func _initialize_facades():
	if game_flow_manager_scene:
		game_flow_manager = game_flow_manager_scene.instantiate()
		add_child(game_flow_manager)
	else:
		game_flow_manager = GameFlowManager.new()
		add_child(game_flow_manager)
	
	if player_facade_scene:
		player_facade = player_facade_scene.instantiate()
		add_child(player_facade)
	else:
		player_facade = PlayerFacade.new()
		add_child(player_facade)
	
	if ui_facade_scene:
		ui_facade = ui_facade_scene.instantiate()
		add_child(ui_facade)
	else:
		ui_facade = UIFacade.new()
		add_child(ui_facade)
	
	if inventory_facade_scene:
		inventory_facade = inventory_facade_scene.instantiate()
		add_child(inventory_facade)
	else:
		inventory_facade = InventoryFacade.new()
		add_child(inventory_facade)

func _setup_connections():
	if ui_manager and inventory_system:
		inventory_system.setup_ui_manager(ui_manager)
	
	if _player_state_manager and light_crystal_resource:
		_player_state_manager.light_crystal_resource = light_crystal_resource
	
	if game_flow_manager and level_system:
		game_flow_manager.setup(level_system, _player_state_manager)
	
	if player_facade and _player_state_manager and ui_manager:
		player_facade.setup(_player_state_manager, ui_manager)
	
	if ui_facade and ui_manager:
		ui_facade.setup(ui_manager)
	
	if inventory_facade and inventory_system:
		inventory_facade.setup(inventory_system)

func _connect_signals():
	if game_flow_manager:
		game_flow_manager.game_over.connect(_on_game_over)
		game_flow_manager.game_completed.connect(_on_game_completed)
		next_level_requested.connect(game_flow_manager._on_next_level_requested)
	
	if player_facade:
		player_facade.dialog_state_changed.connect(_on_dialog_state_changed)
		player_facade.lives_visibility_changed.connect(_on_lives_visibility_changed)
	
	if inventory_facade:
		inventory_facade.item_collected_signal.connect(_on_item_collected_signal)

# Обработчики сигналов
func _on_game_over():
	game_over.emit()

func _on_game_completed():
	game_completed.emit()

func _on_dialog_state_changed(is_active: bool):
	dialog_state_changed.emit(is_active)

func _on_lives_visibility_changed(is_visible: bool):
	lives_visibility_changed.emit(is_visible)

func _on_item_collected_signal(item_data: ItemData):
	item_collected_signal.emit(item_data)
	
	if player_facade:
		player_facade.update_player_light_state()

# API для обратной совместимости
## Возвращает слой пользовательского интерфейса
func get_ui_layer() -> CanvasLayer:
	if ui_facade:
		return ui_facade.get_ui_layer()
	return null

## Возвращает последнее смещение разделителя инвентаря
func get_last_inventory_split_offset() -> int:
	if inventory_facade:
		return inventory_facade.get_last_inventory_split_offset()
	return 120

## Устанавливает смещение разделителя инвентаря
func set_last_inventory_split_offset(value: int) -> void:
	if inventory_facade:
		inventory_facade.set_last_inventory_split_offset(value)

## Возвращает словарь собранных предметов по их ID
func get_collected_item_ids() -> Dictionary:
	if inventory_facade:
		return inventory_facade.get_collected_item_ids()
	return {}

## Возвращает true, если свет игрока активен
func is_player_light_active() -> bool:
	if player_facade:
		return player_facade.is_player_light_active()
	return false

## Возвращает true, если игрок мёртв
func is_player_dead() -> bool:
	if player_facade:
		return player_facade.is_player_dead()
	return false

## Метод для добавления предмета в инвентарь
func _on_item_collected(item_data: ItemData, _item_node = null):
	if inventory_facade:
		inventory_facade.add_item_to_inventory(item_data)

# Публичные методы API
## Уменьшает количество жизней игрока
func decrease_lives() -> bool:
	if player_facade:
		return player_facade.decrease_lives()
	return true

## Устанавливает видимость счетчика жизней
func set_lives_visibility(visible: bool):
	if player_facade:
		player_facade.set_lives_visibility(visible)

## Скрывает счетчик жизней
func hide_lives():
	if player_facade:
		player_facade.hide_lives()

## Показывает счетчик жизней
func show_lives():
	if player_facade:
		player_facade.show_lives()

## Загружает указанный уровень
func go_to_level(level_number: int, custom_path: String = ""):
	if game_flow_manager:
		game_flow_manager.go_to_level(level_number, custom_path)

## Устанавливает текущий номер уровня
func set_current_level(level_num: int):
	if game_flow_manager:
		game_flow_manager.set_current_level(level_num)

## Запрашивает переход на следующий уровень
func request_next_level():
	if game_flow_manager:
		game_flow_manager.request_next_level()

## Включает или выключает режим диалога
func set_dialog_active(active: bool):
	if player_facade:
		player_facade.set_dialog_active(active)

## Возвращает состояние режима диалога
func get_dialog_active() -> bool:
	if player_facade:
		return player_facade.get_dialog_active()
	return false

## Показывает уведомление игроку
func show_notification(text: String, duration: float = 2.0):
	if ui_facade:
		ui_facade.show_notification(text, duration)

## Сбрасывает все игровые системы
func reset_game_state():
	if game_flow_manager:
		game_flow_manager.reset_game_flow()
	
	if player_facade:
		player_facade.reset_player()
	
	if inventory_facade:
		inventory_facade.reset_inventory()
	
	if ui_facade:
		ui_facade.reset_ui()

## Запрашивает обновление света игрока
func mark_for_light_update():
	if player_facade:
		player_facade.request_light_update()
