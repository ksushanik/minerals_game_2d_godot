extends Node

class_name InventoryFacade

# === СИГНАЛЫ ===
signal item_collected_signal(item_data: ItemData)

# === ВНЕШНИЕ КОМПОНЕНТЫ ===
var inventory_system: InventorySystem

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	add_to_group("inventory_facade")

# === НАСТРОЙКА КОМПОНЕНТОВ ===
func setup(inventory: InventorySystem):
	inventory_system = inventory
	
	# Подключаем сигналы
	if inventory_system:
		inventory_system.item_added.connect(_on_item_added)

# === ОБРАБОТЧИКИ СИГНАЛОВ ===
func _on_item_added(item_data: ItemData):
	item_collected_signal.emit(item_data)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func add_item_to_inventory(item_data: ItemData) -> bool:
	if inventory_system:
		return inventory_system.add_item(item_data)
	return false

func has_item(resource_path: String) -> bool:
	if inventory_system:
		return inventory_system.has_item(resource_path)
	return false
	
func get_all_items() -> Array[ItemData]:
	if inventory_system:
		return inventory_system.get_all_items()
	var empty_array: Array[ItemData] = []
	return empty_array
	
func get_last_inventory_split_offset() -> int:
	if inventory_system:
		return inventory_system.last_inventory_split_offset
	return 120
	
func set_last_inventory_split_offset(value: int) -> void:
	if inventory_system:
		inventory_system.last_inventory_split_offset = value
		
func get_collected_item_ids() -> Dictionary:
	if inventory_system:
		return inventory_system.collected_item_ids
	return {}

func open_inventory():
	if inventory_system:
		inventory_system.open_inventory()
		
func close_inventory():
	if inventory_system:
		inventory_system.close_inventory()
		
func reset_inventory():
	if inventory_system:
		inventory_system.clear_inventory()

# <<< НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С ВЫБРАННЫМ ПРЕДМЕТОМ >>>
func set_selected_inventory_item(item_data: ItemData):
	if inventory_system:
		inventory_system.set_selected_item(item_data)

func get_selected_inventory_item() -> ItemData:
	if inventory_system:
		return inventory_system.get_selected_item()
	return null

# === СТАРЫЕ МЕТОДЫ ===
# ... (если есть) 