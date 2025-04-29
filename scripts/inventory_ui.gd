extends PanelContainer

# Импортируем класс ItemData для подсказки типов
# const ItemData = preload("res://scripts/ItemData.gd")

# --- Предзагрузка постоянных элементов инвентаря ---
# Закомментированы, так как больше не используются
# const PYRITE_DATA = preload("res://resources/items/pyrite_info.tres")
# const CHALCEDONY_DATA = preload("res://resources/items/chalcedony_info.tres")
# ----------------------------------------------------

# Сигнал, испускаемый при закрытии инвентаря
signal inventory_closed

# Изменяем ссылку на ItemList
@onready var item_list = $MarginContainer/VBoxContainer/HSplitContainer/ScrollContainer/ItemList
# Добавляем ссылку на область описания
@onready var description_display = $MarginContainer/VBoxContainer/HSplitContainer/DescriptionPanel/MarginContainer/DescriptionDisplay
# Добавляем ссылку на метку имени
@onready var item_name_label = $MarginContainer/VBoxContainer/HSplitContainer/DescriptionPanel/MarginContainer/ItemNameLabel
# Добавляем ссылку на разделитель
@onready var h_split_container = $MarginContainer/VBoxContainer/HSplitContainer

var game_manager = null

# Словарь для хранения полных описаний
# var item_details = {} # Больше не нужно, берем из ItemData

# Переопределяем _gui_input для отладки
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		pass

func _ready():
	if item_list == null:
		return
	else:
		item_list.item_selected.connect(_on_item_selected)

	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# Функция для установки начального смещения разделителя
func set_initial_split_offset(offset: int):
	if h_split_container:
		h_split_container.split_offset = offset

# Метод для подключения сигнала закрытия инвентаря к InventorySystem
func connect_close_signal(inventory_system):
	if inventory_system and inventory_system.has_method("_on_inventory_closed"):
		inventory_closed.connect(inventory_system._on_inventory_closed)

# Вызывается извне для показа и заполнения инвентаря
# Принимает массив РЕСУРСОВ ItemData собранных предметов
func display_inventory(collected_items: Array[ItemData]): # Тип изменен на Array[ItemData]
	if item_list == null or description_display == null or item_name_label == null:
		return
	
	item_list.clear()
	description_display.text = "Выберите предмет слева для описания..."
	item_name_label.text = ""
	
	var current_index = 0
	var selected_item_index = -1 # <<< Индекс для авто-выбора
	var current_selected_item: ItemData = null

	# <<< Получаем текущий выбранный предмет ДО заполнения списка >>>
	if game_manager and game_manager.inventory_facade:
		current_selected_item = game_manager.inventory_facade.get_selected_inventory_item()

	if collected_items.is_empty():
		item_list.add_item("(Пусто)", null, false)
		item_list.set_item_disabled(0, true)
	else:
		for item_data in collected_items:
			if item_data and typeof(item_data) == TYPE_OBJECT and item_data.has_method("get_script"):
				var item_icon = item_data.item_icon if item_data.item_icon else null
				item_list.add_item("", item_icon, true)
				item_list.set_item_metadata(current_index, item_data)
				
				# <<< Проверяем, совпадает ли добавляемый предмет с сохраненным выбранным >>>
				if current_selected_item and item_data == current_selected_item:
					selected_item_index = current_index
					
				current_index += 1
			else:
				item_list.add_item("ОШИБКА ДАННЫХ")
				item_list.set_item_disabled(current_index, true)
				current_index += 1
	
	show()
	if item_list:
		item_list.grab_focus()
		# <<< Выбираем сохраненный предмет в списке, если он был >>>
		if selected_item_index != -1:
			item_list.select(selected_item_index)
			# Дополнительно вызываем _on_item_selected, чтобы обновить описание
			_on_item_selected(selected_item_index)
		else:
			# Если ничего не было выбрано, выбираем первый элемент (если есть)
			if item_list.item_count > 0 and not item_list.is_item_disabled(0):
				item_list.select(0)
				_on_item_selected(0)

# Вызывается при выборе элемента в ItemList
func _on_item_selected(index: int):
	if description_display == null or item_name_label == null:
		return
	
	var selected_item_data = item_list.get_item_metadata(index)
	
	if selected_item_data and typeof(selected_item_data) == TYPE_OBJECT and selected_item_data.has_method("get_script"):
		var item_name_text = selected_item_data.item_name if selected_item_data.item_name else "(Без имени)"
		item_name_label.text = item_name_text
		
		var description_text = selected_item_data.item_description if selected_item_data.item_description else "(Описание не задано)"
		description_display.text = description_text
		
		# <<< СОХРАНЯЕМ ВЫБРАННЫЙ ПРЕДМЕТ В InventorySystem >>>
		if game_manager and game_manager.inventory_facade:
			game_manager.inventory_facade.set_selected_inventory_item(selected_item_data)
		
	else:
		item_name_label.text = ""
		description_display.text = "Ошибка: Не удалось получить данные для выбранного элемента."
		# <<< Сбрасываем выбранный предмет, если данные некорректны >>>
		if game_manager and game_manager.inventory_facade:
			game_manager.inventory_facade.set_selected_inventory_item(null)

# Вызывается при нажатии кнопки "Закрыть"
func _on_close_button_pressed():
	if game_manager and h_split_container:
		game_manager.set_last_inventory_split_offset(h_split_container.split_offset)
	
	hide()
	inventory_closed.emit()
	queue_free()
