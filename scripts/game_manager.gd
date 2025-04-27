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

# === НАСТРОЙКИ UI В ИНСПЕКТОРЕ ===
# Настройки счётчика жизней
@export_group("Player UI")
@export var lives_font_size: int = 24
@export var lives_font: Font = null

# Настройки надписи Game Over
@export_group("Game Over")
@export var game_over_text: String = "ИГРА ОКОНЧЕНА!"
@export var game_over_font: Font = null
@export var game_over_alt_fonts: Array[Font] = []
@export var game_over_font_size: int = 48
@export var game_over_color: Color = Color.RED
@export var game_over_offset_y: float = 0.0
@export var game_over_offset_x: float = 0.0
@export var game_over_shadow_color: Color = Color.BLACK
@export var game_over_shadow_offset: Vector2 = Vector2(2, 2)
@export var game_over_z_index: int = 50
@export var font_size_multiplier: float = 1.5
@export var custom_min_width: float = 600.0
@export var custom_min_height: float = 100.0

# Настройки уведомлений
@export_group("Notifications")
@export var notification_font: Font = preload("res://themes/pixi.ttf")
@export var notification_font_color: Color = Color.WHITE
@export var notification_vertical_offset: float = 10.0
@export var notification_panel_color: Color = Color(0, 0, 0, 0.6)
@export var notification_panel_padding: float = 5.0

# Настройки подсказки инвентаря
@export_group("Inventory")
@export var inventory_hint_text: String = "Предмет добавлен! Нажмите 'I', чтобы открыть инвентарь."
@export var inventory_hint_duration: float = 3.5
@export var inventory_scene: PackedScene

# Настройки уровней
@export_group("Game Settings")
@export var current_level: int = 1
@export var total_levels: int = 4
@export var max_lives: int = 3

# === ИГРОВЫЕ ПЕРЕМЕННЫЕ ===
var lives = 3
var show_lives_ui = true
var total_pickups = 0
var collected_items: Array[ItemData] = []
var collected_item_ids: Dictionary = {}
var last_inventory_split_offset: int = 120
var current_inventory_instance = null
var inventory_hint_shown_this_level: bool = false
var is_player_dead: bool = false
var is_player_light_active: bool = false
var current_level_is_dark: bool = false
var is_dialog_active: bool = false  # Новый флаг для состояния диалога
var needs_light_update: bool = false  # Флаг для обновления света после перезагрузки уровня
var light_update_timer: Timer = null  # Таймер для обновления света

# === ССЫЛКИ НА UI ЭЛЕМЕНТЫ ===
@onready var lives_label = $LivesLabel
@onready var notification_timer: Timer = $UILayer/NotificationTimer
@onready var ui_layer: CanvasLayer = null
var notification_panel: PanelContainer = null
var notification_label: Label = null
var game_over_label: Label = null
var canvas_modulate: CanvasModulate = null

# === КОМПОНЕНТЫ ИГРЫ ===
var ui_manager: UIManager
var inventory_system: InventorySystem
var level_system: LevelSystem
var player_state_manager: PlayerStateManager

# === ОСНОВНЫЕ ФУНКЦИИ ===
func _ready():
	add_to_group("game_manager")
	
	# Проверка загрузки сцены инвентаря
	if not inventory_scene:
		push_error("GameManager: Inventory scene is NOT loaded!")
	
	# Создаем и инициализируем компоненты
	_initialize_components()
	
	# Настраиваем обработку сигналов
	_connect_signals()
	
	# Создаем таймер для обновления света
	light_update_timer = Timer.new()
	light_update_timer.one_shot = true
	light_update_timer.wait_time = 0.8
	light_update_timer.timeout.connect(_on_light_update_timer_timeout)
	add_child(light_update_timer)

# === ИНИЦИАЛИЗАЦИЯ КОМПОНЕНТОВ ===
func _initialize_components():
	# UI Manager
	if ui_manager_scene:
		ui_manager = ui_manager_scene.instantiate()
		add_child(ui_manager)
		
		# Передаем настройки Game Over в UI Manager
		ui_manager.game_over_text = game_over_text
		ui_manager.game_over_font = game_over_font
		ui_manager.game_over_alt_fonts = game_over_alt_fonts
		ui_manager.game_over_font_size = game_over_font_size
		ui_manager.game_over_color = game_over_color
		ui_manager.game_over_offset_x = game_over_offset_x
		ui_manager.game_over_offset_y = game_over_offset_y
		ui_manager.game_over_shadow_color = game_over_shadow_color
		ui_manager.game_over_shadow_offset = game_over_shadow_offset
		ui_manager.game_over_z_index = game_over_z_index
		ui_manager.font_size_multiplier = font_size_multiplier
		ui_manager.custom_min_width = custom_min_width
		ui_manager.custom_min_height = custom_min_height
		
		# Передаем настройки уведомлений
		ui_manager.notification_font = notification_font
		ui_manager.notification_font_color = notification_font_color
		ui_manager.notification_vertical_offset = notification_vertical_offset
		ui_manager.notification_panel_color = notification_panel_color
		ui_manager.notification_panel_padding = notification_panel_padding
	else:
		push_error("GameManager: UI Manager scene not set!")
	
	# Inventory System
	if inventory_system_scene:
		inventory_system = inventory_system_scene.instantiate()
		add_child(inventory_system)
		
		# Устанавливаем ссылку на UI Manager
		if ui_manager:
			inventory_system.setup_ui_manager(ui_manager)
		
		# Устанавливаем сцену инвентаря
		if inventory_scene:
			inventory_system.inventory_scene = inventory_scene
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

# --- Управление инвентарем ---
func add_item_to_inventory(item_data: ItemData) -> bool:
	if inventory_system:
		return inventory_system.add_item(item_data)
	return false

# Сохраняем для обратной совместимости
func _on_item_collected(item_data: ItemData, _item_node: Node):
	if inventory_system:
		inventory_system.add_item(item_data)

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
func _unhandled_input(event):
	if event.is_action_pressed("ui_inventory"):
		if inventory_system:
			if is_instance_valid(inventory_system.current_inventory_instance):
				inventory_system.close_inventory()
			else:
				inventory_system.open_inventory()
			# Помечаем ввод как обработанный
			get_viewport().set_input_as_handled()
	# Остальной ввод обрабатывается в соответствующих системах

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
	print("GameManager: Updating player light after level reload")
	
	# Проверяем, темный ли это уровень
	var is_dark_level = false
	var level_controller = get_tree().get_first_node_in_group("level_controller")
	if level_controller and level_controller.has_method("is_dark_level"):
		is_dark_level = level_controller.is_dark_level
		print("GameManager: Current level dark state:", is_dark_level)
	
	# Проверяем наличие светового кристалла
	var has_light_crystal = false
	if inventory_system and light_crystal_resource:
		has_light_crystal = inventory_system.has_item(light_crystal_resource.resource_path)
		print("GameManager: Player has light crystal:", has_light_crystal)
	
	# Обновляем состояние света через PlayerStateManager
	if player_state_manager:
		player_state_manager.update_player_light_state()
		print("GameManager: Player light state updated successfully")
	
	# Дополнительная прямая проверка для надежности
	if is_dark_level and has_light_crystal:
		print("GameManager: Direct light management - dark level and has crystal")
		
		# Находим игрока и его свет
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("PointLight2D"):
			var player_light = player.get_node("PointLight2D")
			print("GameManager: Directly enabling player light")
			player_light.visible = true
			player_light.enabled = true
			
			# Эффект включения света для визуальной обратной связи
			var tween = create_tween()
			tween.tween_property(player_light, "energy", 1.2, 0.3)
			tween.tween_property(player_light, "energy", 1.0, 0.2)
		else:
			print("GameManager: PointLight2D node not found on player")
			# Если игрок или свет не найден, попробуем снова через некоторое время
			var retry_timer = get_tree().create_timer(0.3)
			await retry_timer.timeout
			
			player = get_tree().get_first_node_in_group("player")
			if player and player.has_node("PointLight2D"):
				var player_light = player.get_node("PointLight2D")
				print("GameManager: Retry - enabling player light")
				player_light.visible = true
				player_light.enabled = true
				
				var tween = create_tween()
				tween.tween_property(player_light, "energy", 1.2, 0.3)
				tween.tween_property(player_light, "energy", 1.0, 0.2)
			else:
				print("GameManager: Retry failed - PointLight2D still not found on player")
	
	# Запрашиваем обновление от LevelController для дополнительной надежности
	if level_controller:
		print("GameManager: Requested light update from level controller")
		level_controller._update_player_light()
	
	light_update_timer.stop()
