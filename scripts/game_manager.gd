extends Node

# === СИГНАЛЫ ===
signal next_level_requested
signal game_over
signal game_completed
signal lives_visibility_changed(is_visible)
signal item_collected_signal(item_data: ItemData)
signal dialog_state_changed(is_active)

# === НАСТРОЙКИ КОМПОНЕНТОВ ===
@export_group("Manager Components")
@export var ui_manager_scene: PackedScene
@export var inventory_system_scene: PackedScene
@export var level_system_scene: PackedScene
@export var player_state_manager_scene: PackedScene

# === НАСТРОЙКИ РЕСУРСОВ ===
@export_group("Resources")
@export var light_crystal_resource: Resource
@export var iron_resource: Resource

# === ИГРОВЫЕ ПЕРЕМЕННЫЕ ===
var needs_light_update: bool = false  # Флаг для обновления света после перезагрузки уровня
var light_update_timer: Timer = null  # Таймер для обновления света

# === КОМПОНЕНТЫ ИГРЫ ===
var ui_manager: UIManager
var inventory_system: InventorySystem
var level_system: LevelSystem
var player_state_manager: PlayerStateManager

# === ОСНОВНЫЕ ФУНКЦИИ ===
func _ready():
	add_to_group("game_manager")
	
	# Создаем и инициализируем компоненты
	_initialize_components()
	
	# Настраиваем обработку сигналов
	_connect_signals()
	
	# Создаем таймер для обновления света
	light_update_timer = Timer.new()
	light_update_timer.one_shot = true
	light_update_timer.wait_time = 0.5
	light_update_timer.timeout.connect(_on_light_update_timer_timeout)
	add_child(light_update_timer)

# === ИНИЦИАЛИЗАЦИЯ КОМПОНЕНТОВ ===
func _initialize_components():
	# UI Manager
	if ui_manager_scene:
		ui_manager = ui_manager_scene.instantiate()
		add_child(ui_manager)
	else:
		push_error("GameManager: UI Manager scene not set!")
	
	# Inventory System
	if inventory_system_scene:
		inventory_system = inventory_system_scene.instantiate()
		add_child(inventory_system)
		
		# Устанавливаем ссылку на UI Manager
		if ui_manager:
			inventory_system.setup_ui_manager(ui_manager)
	else:
		push_error("GameManager: Inventory System scene not set!")
	
	# Level System
	if level_system_scene:
		level_system = level_system_scene.instantiate()
		add_child(level_system)
	else:
		push_error("GameManager: Level System scene not set!")
	
	# Player State Manager
	if player_state_manager_scene:
		player_state_manager = player_state_manager_scene.instantiate()
		add_child(player_state_manager)
		
		# Передаем ресурсы
		if light_crystal_resource:
			player_state_manager.light_crystal_resource = light_crystal_resource
		
		# Настраиваем компоненты
		if ui_manager and inventory_system and level_system:
			player_state_manager.setup(ui_manager, inventory_system, level_system)
	else:
		push_error("GameManager: Player State Manager scene not set!")

# === ПОДКЛЮЧЕНИЕ СИГНАЛОВ ===
func _connect_signals():
	# Подключаем UI Manager
	if ui_manager:
		# В данном случае, нет прямых сигналов от UI к GameManager
		pass
	
	# Подключаем Inventory System
	if inventory_system:
		inventory_system.item_added.connect(_on_item_added)
	
	# Подключаем Level System
	if level_system:
		level_system.level_changed.connect(_on_level_changed)
		level_system.all_levels_completed.connect(_on_all_levels_completed)
	
	# Подключаем Player State Manager
	if player_state_manager:
		player_state_manager.player_died.connect(_on_player_died)
		player_state_manager.game_over.connect(_on_game_over)
		player_state_manager.dialog_state_changed.connect(_on_dialog_state_changed)
		player_state_manager.player_light_state_changed.connect(_on_player_light_state_changed)
		
		# Делегируем сигналы наверх
		next_level_requested.connect(_on_next_level_requested)

# === ОБРАБОТЧИКИ СИГНАЛОВ ===
func _on_item_added(item_data: ItemData):
	item_collected_signal.emit(item_data)
	
	# Обновляем состояние света игрока при получении предметов
	if player_state_manager:
		player_state_manager.update_player_light_state()

func _on_level_changed(_level_number: int):
	# Сбрасываем состояние подсказки инвентаря
	if inventory_system:
		inventory_system.reset_hint_state()
	
	# Обновляем состояние света игрока при смене уровня
	if player_state_manager:
		player_state_manager.update_player_light_state()
	
	# Проверяем все коллектибл-предметы на уровне после загрузки
	call_deferred("check_all_collectibles")

func check_all_collectibles():
	# Ждем один кадр, чтобы уровень полностью загрузился
	await get_tree().process_frame
	
	# Найти все коллектиблы на уровне
	var collectibles = get_tree().get_nodes_in_group("coins")
	
	# Вызвать метод проверки для каждого коллектибла
	for collectible in collectibles:
		if collectible.has_method("check_if_already_collected"):
			collectible.check_if_already_collected()

func _on_all_levels_completed():
	game_completed.emit()

func _on_player_died():
	# Логика уже обрабатывается в PlayerStateManager
	# Но добавляем проверку коллектиблов после смерти игрока
	call_deferred("check_all_collectibles")

func _on_game_over():
	game_over.emit()

func _on_dialog_state_changed(is_active: bool):
	dialog_state_changed.emit(is_active)

func _on_player_light_state_changed(_is_active: bool):
	# Можно добавить дополнительную логику при необходимости
	pass

func _on_next_level_requested():
	if level_system:
		level_system.go_to_next_level()

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
# Эти методы используют соответствующие системы

# Свойство для обратной совместимости
var ui_layer: CanvasLayer:
	get:
		if ui_manager:
			return ui_manager.get_ui_layer()
		return null

# Свойство для обратной совместимости
var last_inventory_split_offset: int:
	get:
		if inventory_system:
			return inventory_system.last_inventory_split_offset
		return 120
	set(value):
		if inventory_system:
			inventory_system.last_inventory_split_offset = value

# Свойство для обратной совместимости
var collected_item_ids: Dictionary:
	get:
		if inventory_system:
			return inventory_system.collected_item_ids
		return {}

# Свойство для обратной совместимости
var is_player_light_active: bool:
	get:
		if player_state_manager:
			return player_state_manager.is_player_light_active
		return false

# Свойство для обратной совместимости
var is_player_dead: bool:
	get:
		if player_state_manager:
			return player_state_manager.is_player_dead()
		return false

# --- Управление жизнями ---
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

# --- Управление уровнями ---
func go_to_level(level_number: int, custom_path: String = ""):
	if level_system:
		level_system.go_to_level(level_number, custom_path)

func set_current_level(level_num: int):
	if level_system:
		level_system.set_current_level(level_num)

func request_next_level():
	next_level_requested.emit()

# --- Управление диалогами ---
func set_dialog_active(active: bool):
	if player_state_manager:
		player_state_manager.set_dialog_active(active)

func get_dialog_active() -> bool:
	if player_state_manager:
		return player_state_manager.get_dialog_active()
	return false

# --- Управление уведомлениями ---
func show_notification(text: String, duration: float = 2.0):
	if ui_manager:
		ui_manager.show_notification(text, duration)

# --- Сброс игры ---
func reset_game_state():
	if player_state_manager:
		player_state_manager.reset_player_state()
	
	if inventory_system:
		inventory_system.clear_inventory()
	
	if level_system:
		level_system.reset_level_system()
	
	if ui_manager:
		ui_manager.hide_game_over()

# === ОБРАБОТКА ВВОДА ===
func _unhandled_input(_event):
	# Обработка ввода делегирована соответствующим системам
	pass

func _process(_delta):
	# Проверяем, нужно ли обновить свет после перезагрузки уровня
	if needs_light_update and not light_update_timer.is_stopped():
		# Таймер уже запущен, ничего не делаем
		pass
	elif needs_light_update:
		# Запускаем таймер на обновление света
		light_update_timer.start()
		needs_light_update = false

# Отмечаем, что свет нужно обновить после перезагрузки уровня
func mark_for_light_update():
	needs_light_update = true
	
# Обработчик таймера обновления света
func _on_light_update_timer_timeout():
	# Обновляем состояние света через PlayerStateManager
	if player_state_manager:
		player_state_manager.update_player_light_state()
	
	# Запрашиваем обновление от LevelController для дополнительной надежности
	var level_controller = get_tree().get_first_node_in_group("level_controller")
	if level_controller and level_controller.has_method("_update_player_light"):
		level_controller._update_player_light()
	
	light_update_timer.stop()

# Делегирующий метод для обратной совместимости
func _on_item_collected(item_data: ItemData, _item_node = null):
	if inventory_system:
		inventory_system.add_item(item_data)
