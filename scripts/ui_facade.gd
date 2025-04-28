extends Node

class_name UIFacade

# === ВНЕШНИЕ КОМПОНЕНТЫ ===
var ui_manager: UIManager

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	add_to_group("ui_facade")

# === НАСТРОЙКА КОМПОНЕНТОВ ===
func setup(ui: UIManager):
	ui_manager = ui

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func show_notification(text: String, duration: float = 2.0):
	if ui_manager:
		ui_manager.show_notification(text, duration)

func show_game_over():
	if ui_manager:
		ui_manager.show_game_over()
		
func hide_game_over():
	if ui_manager:
		ui_manager.hide_game_over()
		
func get_ui_layer() -> CanvasLayer:
	if ui_manager:
		return ui_manager.get_ui_layer()
	return null
	
func reset_ui():
	if ui_manager:
		ui_manager.hide_game_over() 