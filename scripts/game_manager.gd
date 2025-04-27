extends Node

# === СИГНАЛЫ ===
signal next_level_requested
signal game_over
signal game_completed
signal lives_visibility_changed(is_visible)
signal item_collected_signal(item_data: ItemData)
signal dialog_state_changed(is_active)

# === НАСТРОЙКИ UI В ИНСПЕКТОРЕ ===
# Настройки счётчика жизней
@export_group("Player UI")
@export var lives_font_size: int = 24
@export var lives_font: Font = null

# Настройки надписи Game Over
@export_group("Game Over")
@export var game_over_text: String = "ИГРА ОКОНЧЕНА!"
@export var game_over_font: Font = null
@export var game_over_font_size: int = 48
@export var game_over_color: Color = Color.RED
@export var game_over_offset_y: float = 0.0
@export var game_over_offset_x: float = 0.0

# Настройки уведомлений
@export_group("Notifications")
@export var notification_font: Font = null
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

# === ССЫЛКИ НА UI ЭЛЕМЕНТЫ ===
@onready var lives_label = $LivesLabel
@onready var notification_timer: Timer = $UILayer/NotificationTimer
@onready var ui_layer: CanvasLayer = null
var notification_panel: PanelContainer = null
var notification_label: Label = null
var game_over_label: Label = null
var canvas_modulate: CanvasModulate = null

# === КОНСТАНТЫ ===
const LIGHT_CRYSTAL_PATH = "res://resources/items/light_crystal.tres"
const IRON_RESOURCE_PATH = "res://resources/items/iron.tres"

# === ОСНОВНЫЕ ФУНКЦИИ ===
func _ready():
	add_to_group("game_manager")
	
	# Инициализация значений
	if lives <= 0:
		lives = max_lives
	
	next_level_requested.connect(next_level)
	
	# Настройка счётчика жизней
	if lives_label:
		if lives_font_size > 0:
			lives_label.add_theme_font_size_override("font_size", lives_font_size)
		if lives_font:
			lives_label.add_theme_font_override("font", lives_font)
	
	print("GameManager: Initialized on level", current_level, "with", lives, "lives")
	update_ui()
	notify_property_list_changed()

	# Создание UI слоя
	setup_ui_layer()
	update_ui()

func setup_ui_layer():
	# Создаём Canvas Layer для UI элементов
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	print("GameManager: UI CanvasLayer created.")
	
	# Связываем с UI компонентом
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("set_game_manager"):
		ui_node.set_game_manager(self)
		print("GameManager: Passed self reference to UI")
	else:
		print("GameManager: UI node not found or doesn't have set_game_manager method.")

	# Инициализация UI элементов
	if ui_layer:
		# Счётчик жизней
		if not lives_label:
			lives_label = ui_layer.get_node_or_null("LivesLabel")
			
		# Панель уведомлений
		create_notification_panel()
		create_notification_timer()
		create_game_over_label()

# === ФУНКЦИИ ИНИЦИАЛИЗАЦИИ UI ===
func create_notification_panel():
	if notification_panel:
		return
		
	notification_panel = PanelContainer.new()
	notification_panel.name = "NotificationPanel"
	
	# Стиль подложки
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = notification_panel_color
	style_box.content_margin_left = notification_panel_padding
	style_box.content_margin_right = notification_panel_padding
	style_box.content_margin_top = notification_panel_padding
	style_box.content_margin_bottom = notification_panel_padding
	notification_panel.add_theme_stylebox_override("panel", style_box)
	
	# Позиционирование и размер
	notification_panel.set_anchors_preset(Control.PRESET_TOP_WIDE, true)
	notification_panel.offset_top = notification_vertical_offset
	notification_panel.anchor_bottom = Control.ANCHOR_BEGIN
	notification_panel.offset_bottom = 0
	notification_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	notification_panel.visible = false
	
	# Создаём лейбл внутри панели
	notification_label = Label.new()
	notification_label.name = "NotificationLabel"
	notification_label.text = ""
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Стиль текста
	if notification_font:
		notification_label.add_theme_font_override("font", notification_font)
	notification_label.add_theme_color_override("font_color", notification_font_color)
	notification_label.add_theme_font_size_override("font_size", 22)
	notification_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification_label.add_theme_constant_override("shadow_offset_x", 1)
	notification_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Добавляем в иерархию
	notification_panel.add_child(notification_label)
	ui_layer.add_child(notification_panel)

func create_notification_timer():
	if notification_timer:
		return
		
	notification_timer = Timer.new()
	notification_timer.name = "NotificationTimer"
	notification_timer.one_shot = true
	notification_timer.timeout.connect(_on_NotificationTimer_timeout)
	ui_layer.add_child(notification_timer)

func create_game_over_label():
	if game_over_label:
		return
		
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = game_over_text
	
	# Позиционирование
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.set_anchors_preset(Control.PRESET_CENTER, false)
	game_over_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	game_over_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	game_over_label.position.x += game_over_offset_x
	game_over_label.position.y += game_over_offset_y
	
	# Стиль
	if game_over_font:
		game_over_label.add_theme_font_override("font", game_over_font)
	game_over_label.add_theme_font_size_override("font_size", game_over_font_size)
	game_over_label.add_theme_color_override("font_color", game_over_color)
	game_over_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	game_over_label.add_theme_constant_override("shadow_offset_x", 2)
	game_over_label.add_theme_constant_override("shadow_offset_y", 2)
	game_over_label.z_index = 50
	game_over_label.visible = false
	
	ui_layer.add_child(game_over_label)

# === ФУНКЦИИ ОБНОВЛЕНИЯ UI ===
func update_ui():
	if lives_label:
		lives_label.text = "Lives: " + str(lives)
		lives_label.visible = show_lives_ui
		
		# Меняем цвет в зависимости от количества жизней
		if lives <= 1:
			lives_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))  # Красный
		elif lives == 2:
			lives_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2, 1))  # Желтый
		else:
			lives_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))  # Зеленый

# === ФУНКЦИИ ЖИЗНЕЙ И СМЕРТИ ===
func decrease_lives():
	# Проверяем, находимся ли мы в обучающем уровне (уровень 0)
	if current_level == 0:
		print("GameManager: In tutorial level (level 0). Lives decrease ignored.")
		return true

	lives -= 1
	print("Lives decreased! Remaining:", lives)
	notify_property_list_changed()
	
	# Если жизни закончились
	if lives <= 0:
		is_player_dead = true
		print("Game Over! No lives left.")
		
		if is_instance_valid(game_over_label):
			game_over_label.visible = true
		
		if lives_label:
			lives_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			lives_label.visible = true
		
		# Проверяем SceneTree
		if not get_tree():
			print("GameManager: SceneTree not available, cannot create timer")
			game_over.emit()
			return false
			
		await get_tree().create_timer(2.0).timeout
		
		if not is_instance_valid(self) or not is_inside_tree():
			print("GameManager: Node is no longer valid after timeout")
			return false
		
		game_over.emit()
		return false  # Жизни закончились
	else:
		print("Lives left: " + str(lives))
		update_ui()
		return true  # Еще есть жизни

func _on_player_death():
	print("GameManager: Received _on_player_death signal.")
	is_player_dead = true
	decrease_lives()

# === ФУНКЦИИ УРОВНЕЙ ===
func request_next_level():
	print("GameManager: Next level requested")
	next_level_requested.emit()

func next_level():
	current_level += 1
	print("GameManager: Going to next level:", current_level)
	
	inventory_hint_shown_this_level = false
	
	if not get_tree():
		print("GameManager: SceneTree not available, cannot change scene")
		return
	
	if current_level <= total_levels:
		notify_property_list_changed()
		
		var next_scene_path = "res://scenes/level_" + str(current_level) + ".tscn"
		go_to_level(current_level, next_scene_path)
	else:
		# Все уровни пройдены
		print("Game Complete! All levels finished.")
		if lives_label:
			lives_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
			lives_label.visible = true
		
		if not get_tree():
			print("GameManager: SceneTree not available, cannot create timer")
			game_completed.emit()
			return
		
		await get_tree().create_timer(3.0).timeout
		
		if not is_instance_valid(self) or not is_inside_tree():
			print("GameManager: Node is no longer valid after timeout")
			return
			
		game_completed.emit()
		
		if get_tree():
			get_tree().change_scene_to_file("res://scenes/main_title.tscn")
		else:
			print("GameManager: SceneTree not available after timeout, cannot change scene")

func set_current_level(level_num: int):
	current_level = level_num
	print("GameManager: Current level set to", current_level, " by scene.")
	
	inventory_hint_shown_this_level = false
	is_player_dead = false
	print("GameManager: Reset death state")
	
	if is_instance_valid(game_over_label):
		game_over_label.visible = false
		
	update_ui()

func go_to_level(level_number: int, scene_path: String):
	print("GameManager: Requesting transition to Level %d (%s)" % [level_number, scene_path])
	
	if level_number >= 0: 
		current_level = level_number
		print("GameManager: Set current_level to %d" % current_level)
	else:
		print("GameManager: Invalid level number (%d) provided, current_level not updated." % level_number)
	
	inventory_hint_shown_this_level = false
	is_player_dead = false
	
	if is_instance_valid(game_over_label): 
		game_over_label.visible = false
	
	print("GameManager: Initiating scene change to '%s'" % scene_path)
	if get_tree():
		var error = get_tree().change_scene_to_file(scene_path)
		if error == OK:
			print("GameManager: Scene change initiated.")
		else:
			print("GameManager: ERROR changing scene to '%s', error code: %s" % [scene_path, error])
	else:
		print("GameManager: ERROR - SceneTree not available, cannot change scene.")

func reset_game_state():
	lives = max_lives
	total_pickups = 0
	current_level = 1
	clear_inventory()
	inventory_hint_shown_this_level = false
	is_player_dead = false
	
	if is_instance_valid(game_over_label):
		game_over_label.visible = false
		
	print("GameManager: Game state reset to defaults.")
	update_ui()
	notify_property_list_changed()

# === ФУНКЦИИ УПРАВЛЕНИЯ UI ===
func hide_lives():
	show_lives_ui = false
	lives_visibility_changed.emit(false)
	update_ui()

func show_lives():
	show_lives_ui = true
	lives_visibility_changed.emit(true)
	update_ui()

func set_lives_visibility(visible):
	show_lives_ui = visible
	lives_visibility_changed.emit(visible)
	update_ui()

func hide_ui():
	hide_lives()

func show_ui():
	show_lives()

func show_notification(text: String, duration: float = 2.0):
	if notification_panel and notification_label and notification_timer:
		print("GameManager: Showing notification: %s" % text)
		notification_label.text = text
		notification_panel.visible = true
		notification_timer.start(duration)
	else:
		print("GameManager: ERROR - Cannot show notification, panel, label or timer missing!")

func _on_NotificationTimer_timeout():
	if notification_panel:
		notification_panel.visible = false

# === ФУНКЦИИ ИНВЕНТАРЯ ===
func add_to_inventory(description: String):
	if not collected_items.has(description):
		collected_items.append(description)
		print("GameManager: Added to inventory -", description)
		notify_property_list_changed()
	else:
		print("GameManager: Item already in inventory -", description)

func get_collected_items() -> Array[ItemData]:
	return collected_items

func clear_inventory():
	collected_items.clear()
	collected_item_ids.clear()
	print("GameManager: Inventory and collected item IDs cleared.")
	notify_property_list_changed()

func add_item_to_inventory(item_data: ItemData) -> bool:
	if not collected_item_ids.has(item_data.resource_path):
		collected_items.append(item_data)
		collected_item_ids[item_data.resource_path] = true
		print("GameManager: Added UNIQUE ItemData: %s" % item_data.item_name)
		notify_property_list_changed()
		return true
	else:
		return false

func check_inventory_hint():
	if not inventory_hint_shown_this_level:
		print("GameManager: First unique item collected this level. Showing inventory hint.")
		var hint_message = inventory_hint_text
		var hint_duration = inventory_hint_duration
		
		if has_method("show_notification"):
			show_notification(hint_message, hint_duration)
		else:
			print("GameManager: ERROR - Cannot show inventory hint, missing show_notification method!")
		
		inventory_hint_shown_this_level = true

func _on_inventory_closed():
	print("GameManager: _on_inventory_closed called.")
	current_inventory_instance = null

func _unhandled_input(event):
	if event.is_action_pressed("ui_inventory"):
		print("GameManager: Action 'ui_inventory' pressed!")
		
		# Если инвентарь уже открыт, закрываем его
		if is_instance_valid(current_inventory_instance):
			print("GameManager: Inventory already open. Closing it...")
			current_inventory_instance._on_close_button_pressed()
			get_tree().get_root().set_input_as_handled()
			return
			
		# Проверяем, задана ли сцена инвентаря
		if not inventory_scene:
			print("GameManager: ERROR - Inventory Scene not set in inspector!")
			return
			
		print("GameManager: Opening inventory...")
		current_inventory_instance = inventory_scene.instantiate()
		ui_layer.add_child(current_inventory_instance)
		print("GameManager: Inventory instance created and added to UI layer.")

		# Отложенно вызываем показ и установку смещения
		current_inventory_instance.call_deferred("display_inventory", collected_items)
		current_inventory_instance.call_deferred("set_initial_split_offset", last_inventory_split_offset)
		
		get_tree().get_root().set_input_as_handled()

# === ФУНКЦИИ УПРАВЛЕНИЯ СВЕТОМ ===
func _on_item_collected(item_data: ItemData, _item_node: Node):
	print("GameManager: _on_item_collected called for item: %s" % item_data.item_name if item_data else "NULL")
	if not item_data:
		print("GameManager: ERROR - Received null ItemData!")
		return
		
	var is_new_item = add_item_to_inventory(item_data)
	if is_new_item:
		total_pickups += 1
		print("GameManager: Total unique pickups: ", total_pickups)
		check_inventory_hint()
		print("GameManager: Emitting item_collected_signal for: %s" % item_data.item_name)
		item_collected_signal.emit(item_data)
		
		# Проверка на светящийся кристалл
		if item_data.resource_path == LIGHT_CRYSTAL_PATH:
			print("GameManager: Light Crystal collected! Will update light state.")
			update_player_light_state()
	else:
		print("GameManager: Item '%s' already collected." % item_data.item_name)

func update_player_light_state():
	print("GameManager: Updating player light state")
	await get_tree().process_frame
	
	var player_node = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player_node):
		print("GameManager: Player node not valid.")
		return
		
	# Проверяем, есть ли у игрока кристалл
	var has_light_crystal = collected_item_ids.has(LIGHT_CRYSTAL_PATH)
	print("GameManager: Has Light Crystal?", has_light_crystal)
	
	# Проверяем, темный ли текущий уровень
	current_level_is_dark = false
	var current_scene = get_tree().current_scene
	if is_instance_valid(current_scene) and current_scene.has_method("is_dark"):
		current_level_is_dark = current_scene.is_dark()
		print("GameManager: Level darkness:", current_level_is_dark)
	elif is_instance_valid(current_scene):
		print("GameManager: Current scene doesn't have is_dark() method.")
	else:
		print("GameManager: Current scene is not valid.")
		
	# Включаем или выключаем свет
	if has_light_crystal and current_level_is_dark:
		if player_node.has_method("enable_light"):
			print("GameManager: Enabling player light.")
			player_node.enable_light()
			is_player_light_active = true
		else:
			print("GameManager: ERROR - Player missing enable_light() method!")
	else:
		# Выключаем свет, если нет кристалла ИЛИ уровень светлый
		if player_node.has_method("disable_light"):
			print("GameManager: Disabling player light.")
			player_node.disable_light()
			is_player_light_active = false
		elif is_player_light_active:
			print("GameManager: WARNING - Player missing disable_light() method!")
			is_player_light_active = false

# === СЛУЖЕБНЫЕ ФУНКЦИИ ===
func is_valid_node(node):
	return node != null and node.is_inside_tree()

func _process(_delta: float) -> void:
	if not is_valid_node(self) or not is_inside_tree():
		return

# === НОВЫЕ ФУНКЦИИ ДЛЯ УПРАВЛЕНИЯ ДИАЛОГАМИ ===
func set_dialog_active(active: bool) -> void:
	if is_dialog_active == active:
		return
		
	is_dialog_active = active
	print("GameManager: Dialog active state set to %s" % is_dialog_active)
	
	toggle_player_input(!active)
	dialog_state_changed.emit(active)

func toggle_player_input(enable: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(enable)
			print("GameManager: Player input %s during dialog" % ("disabled" if !enable else "enabled"))
		else:
			print("GameManager: Player missing set_input_enabled method! Cannot toggle input.")

func get_dialog_active() -> bool:
	return is_dialog_active
