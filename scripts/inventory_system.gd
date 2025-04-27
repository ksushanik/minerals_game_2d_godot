extends Node

class_name InventorySystem

# === СИГНАЛЫ ===
signal item_added(item_data)
signal inventory_opened
signal inventory_closed
signal inventory_hint_shown

# === НАСТРОЙКИ ИНВЕНТАРЯ ===
@export_group("Inventory Settings")
@export var inventory_scene: PackedScene
@export var inventory_hint_text: String = "Предмет добавлен! Нажмите 'I', чтобы открыть инвентарь."
@export var inventory_hint_duration: float = 3.5

# === ПЕРЕМЕННЫЕ ИНВЕНТАРЯ ===
var collected_items: Array[ItemData] = []
var collected_item_ids: Dictionary = {}
var current_inventory_instance = null
var last_inventory_split_offset: int = 120
var inventory_hint_shown_this_level: bool = false

# === ССЫЛКИ НА ВНЕШНИЕ КОМПОНЕНТЫ ===
var ui_manager: UIManager

# === МЕТОДЫ ИНИЦИАЛИЗАЦИИ ===
func _ready():
	pass

func setup_ui_manager(manager: UIManager):
	ui_manager = manager

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func add_item(item_data: ItemData) -> bool:
	if not collected_item_ids.has(item_data.resource_path):
		collected_items.append(item_data)
		collected_item_ids[item_data.resource_path] = true
		item_added.emit(item_data)
		check_inventory_hint()
		return true
	return false

func has_item(item_resource_path: String) -> bool:
	return collected_item_ids.has(item_resource_path)

func get_all_items() -> Array[ItemData]:
	return collected_items

func clear_inventory():
	collected_items.clear()
	collected_item_ids.clear()

func reset_hint_state():
	inventory_hint_shown_this_level = false

# === УПРАВЛЕНИЕ ОТОБРАЖЕНИЕМ ИНВЕНТАРЯ ===
func open_inventory():
	if is_instance_valid(current_inventory_instance):
		return
		
	if not inventory_scene:
		push_error("inventory_scene not set in InventorySystem")
		return
		
	if not ui_manager:
		push_error("ui_manager not set in InventorySystem")
		return
		
	current_inventory_instance = inventory_scene.instantiate()
	ui_manager.add_to_ui_layer(current_inventory_instance)
	
	# Настройка инвентаря
	current_inventory_instance.call_deferred("display_inventory", collected_items)
	current_inventory_instance.call_deferred("set_initial_split_offset", last_inventory_split_offset)
	
	# При закрытии должны очистить ссылку
	if current_inventory_instance.has_signal("closed"):
		current_inventory_instance.closed.connect(_on_inventory_closed)
	elif current_inventory_instance.has_method("connect_close_signal"):
		current_inventory_instance.connect_close_signal(self)
	
	inventory_opened.emit()

func close_inventory():
	if is_instance_valid(current_inventory_instance):
		# Вызываем метод закрытия, если он существует
		if current_inventory_instance.has_method("_on_close_button_pressed"):
			current_inventory_instance._on_close_button_pressed()
		elif current_inventory_instance.has_method("close"):
			current_inventory_instance.close()
		else:
			current_inventory_instance.queue_free()
			current_inventory_instance = null
			inventory_closed.emit()

func _on_inventory_closed():
	# Сохраняем последнее смещение, если доступно
	if is_instance_valid(current_inventory_instance) and current_inventory_instance.has_method("get_split_offset"):
		last_inventory_split_offset = current_inventory_instance.get_split_offset()
	
	current_inventory_instance = null
	inventory_closed.emit()

func check_inventory_hint():
	if not inventory_hint_shown_this_level:
		if ui_manager:
			ui_manager.show_notification(inventory_hint_text, inventory_hint_duration)
		inventory_hint_shown_this_level = true
		inventory_hint_shown.emit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_inventory"):
		if is_instance_valid(current_inventory_instance):
			close_inventory()
		else:
			open_inventory()
		get_viewport().set_input_as_handled() 