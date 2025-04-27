extends NinePatchRect

# Сигнал, который испускается при закрытии окна диалога
signal dialog_closed

# Массив страниц диалога
var dialogue_pages: Array[String] = []
var current_page_index: int = 0
var game_manager = null # Ссылка на GameManager

@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var next_button = $MarginContainer/VBoxContainer/NextButton

func _ready():
	_find_game_manager()
	
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)

func _find_game_manager():
	game_manager = get_tree().get_first_node_in_group("game_manager") if get_tree() else null
	
	if not game_manager and has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# Функция для инициализации и показа диалога
func start_dialogue(pages: Array[String]):
	if pages.is_empty():
		_close_dialog()
		return
	
	if game_manager and game_manager.has_method("set_dialog_active"):
		game_manager.set_dialog_active(true)
		
	dialogue_pages = pages
	current_page_index = 0
	_update_display()
	show()
	
	if next_button:
		next_button.grab_focus()

# Обновляет отображаемый текст и кнопку
func _update_display():
	if description_label:
		description_label.text = dialogue_pages[current_page_index]
	
	if next_button:
		next_button.text = "Принять задание" if current_page_index == dialogue_pages.size() - 1 else "Далее >"

# Обработчик нажатия кнопки "Далее" / "Принять задание"
func _on_next_button_pressed():
	if not visible:
		return
	
	if current_page_index >= dialogue_pages.size() - 1:
		_absorb_input()
		_close_dialog()
	else:
		current_page_index += 1
		_update_display()
		_absorb_input()

func _absorb_input():
	if get_viewport():
		get_viewport().set_input_as_handled()

# Функция закрытия диалога
func _close_dialog():
	if not visible:
		return
	
	set_process_input(false)
	hide()
	
	if game_manager and game_manager.has_method("set_dialog_active"):
		game_manager.set_dialog_active(false)
	
	dialog_closed.emit()
	_absorb_input()
	queue_free()

# Обработка нажатия клавиш Enter или Escape для перехода/закрытия
func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_select"):
		_on_next_button_pressed()
		_absorb_input()
	elif event.is_action_pressed("ui_cancel"):
		_absorb_input()
		_close_dialog()
