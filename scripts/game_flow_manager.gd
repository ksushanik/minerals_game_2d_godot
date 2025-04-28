extends Node

class_name GameFlowManager

# === СИГНАЛЫ ===
signal next_level_requested
signal game_over
signal game_completed

# === ВНЕШНИЕ КОМПОНЕНТЫ ===
var level_system: LevelSystem
var player_state_manager: PlayerStateManager

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	add_to_group("game_flow_manager")

# === НАСТРОЙКА КОМПОНЕНТОВ ===
func setup(level_sys: LevelSystem, player_state: PlayerStateManager):
	level_system = level_sys
	player_state_manager = player_state
	
	# Подключаем сигналы
	if player_state_manager:
		player_state_manager.game_over.connect(_on_game_over)
	
	if level_system:
		level_system.all_levels_completed.connect(_on_all_levels_completed)

# === ОБРАБОТЧИКИ СИГНАЛОВ ===
func _on_game_over():
	game_over.emit()

func _on_all_levels_completed():
	game_completed.emit()

func _on_next_level_requested():
	if level_system:
		level_system.go_to_next_level()

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func go_to_level(level_number: int, custom_path: String = ""):
	if level_system:
		level_system.go_to_level(level_number, custom_path)

func set_current_level(level_num: int):
	if level_system:
		level_system.set_current_level(level_num)

func request_next_level():
	next_level_requested.emit()

func reset_game_flow():
	if level_system:
		level_system.reset_level_system() 