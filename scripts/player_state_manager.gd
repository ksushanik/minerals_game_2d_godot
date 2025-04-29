extends Node

class_name PlayerStateManager

# === СИГНАЛЫ ===
signal player_died
signal lives_changed(lives)
signal game_over
signal dialog_state_changed(is_active)
signal player_light_state_changed(is_active)
signal request_player_flash

# === КОНСТАНТЫ ===
enum PlayerState {
	NORMAL,
	IN_DIALOG,
	DEAD
}

# === НАСТРОЙКИ ИГРОКА ===
@export_group("Player Settings")
@export var max_lives: int = 3
@export var game_over_delay: float = 2.0

# === НАСТРОЙКИ РЕСУРСОВ ===
@export_group("Resource Paths")
@export var light_crystal_resource: Resource # Заменяет хардкод пути

# === ПЕРЕМЕННЫЕ СОСТОЯНИЯ ===
var lives: int = 3
var current_state: PlayerState = PlayerState.NORMAL
var is_player_light_active: bool = false
var game_over_timer: Timer

# === ССЫЛКИ НА ВНЕШНИЕ КОМПОНЕНТЫ ===
var ui_manager: UIManager
var inventory_system: InventorySystem
var level_system: LevelSystem

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	game_over_timer = Timer.new()
	game_over_timer.one_shot = true
	add_child(game_over_timer)
	
	# Инициализация жизней
	lives = max_lives

# === НАСТРОЙКА КОМПОНЕНТОВ ===
func setup(ui: UIManager, inventory: InventorySystem, level: LevelSystem):
	ui_manager = ui
	inventory_system = inventory
	level_system = level
	
	# Обновляем отображение после подключения UI
	if ui_manager:
		ui_manager.update_lives_display(lives)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func decrease_lives() -> bool:
	# Проверим текущий уровень несколькими способами
	var current_level = -1
	var current_scene_name = ""
	
	if level_system:
		current_level = level_system.get_current_level()
		
	# Дополнительная проверка на нулевой уровень по имени сцены
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene_name = current_scene.name
		# Проверка разных форматов именования нулевого уровня
		var lowercase_name = current_scene_name.to_lower()
		if lowercase_name.contains("level_0") or lowercase_name == "level_0" or lowercase_name.contains("level0") or lowercase_name == "level0":
			print("PlayerStateManager: Tutorial level detected by name! No lives will be decreased.")
			return true
	
	# Отладочная информация
	print("PlayerStateManager: Current level from level_system: ", current_level)
	print("PlayerStateManager: Current scene name: ", current_scene_name)
			
	# В обучающем уровне (0) жизни не уменьшаются
	if level_system and current_level == 0:
		print("PlayerStateManager: Tutorial level detected by number! No lives will be decreased.")
		return true
		
	# Принудительная проверка для уровня с именем Level0
	if current_scene_name == "Level0":
		print("PlayerStateManager: Hard-coded check for Level0! No lives will be decreased.")
		return true
	
	# Обычная логика уменьшения жизней
	lives -= 1
	print("PlayerStateManager: Lives decreased to ", lives)
	
	if ui_manager:
		ui_manager.update_lives_display(lives)
	
	lives_changed.emit(lives)
	
	# <<< ЗАПРОС МЕРЦАНИЯ >>>
	request_player_flash.emit()
	
	if lives <= 0:
		set_player_state(PlayerState.DEAD)
		
		if ui_manager:
			ui_manager.show_game_over()
		
		# Устанавливаем таймер для сигнала game over
		game_over_timer.timeout.connect(_on_game_over_timer_timeout, CONNECT_ONE_SHOT)
		game_over_timer.start(game_over_delay)
		
		return false
	
	return true

func get_lives() -> int:
	return lives

func reset_player_state():
	lives = max_lives
	current_state = PlayerState.NORMAL
	is_player_light_active = false
	
	if ui_manager:
		ui_manager.update_lives_display(lives)
		ui_manager.hide_game_over()
	
	lives_changed.emit(lives)

func set_player_state(new_state: PlayerState):
	if current_state == new_state:
		return
		
	current_state = new_state
	
	match current_state:
		PlayerState.NORMAL:
			_toggle_player_input(true)
		PlayerState.IN_DIALOG:
			_toggle_player_input(false)
			dialog_state_changed.emit(true)
		PlayerState.DEAD:
			_toggle_player_input(false)
			player_died.emit()

func is_player_dead() -> bool:
	return current_state == PlayerState.DEAD

func set_dialog_active(active: bool):
	if active:
		set_player_state(PlayerState.IN_DIALOG)
	else:
		set_player_state(PlayerState.NORMAL)
		dialog_state_changed.emit(false)

func get_dialog_active() -> bool:
	return current_state == PlayerState.IN_DIALOG

func update_player_light_state():
	# Нужен доступ к инвентарю для проверки наличия кристалла
	if not inventory_system or not level_system:
		print("PlayerStateManager: Cannot update light state - missing InventorySystem or LevelSystem.")
		return
		
	var light_crystal_res_path = ""
	if light_crystal_resource:
		light_crystal_res_path = light_crystal_resource.resource_path
	else:
		print("PlayerStateManager: light_crystal_resource is not set!")
		# Попробуем использовать стандартный путь как запасной вариант
		light_crystal_res_path = "res://resources/items/light_crystal.tres"

	# Проверяем наличие кристалла и темноты уровня
	var has_light_crystal = inventory_system.has_item(light_crystal_res_path)
	var is_dark_level = level_system.is_level_dark()
	
	# <<< ИЗМЕНЕННАЯ ЛОГИКА: ВЫКЛЮЧАЕМ СВЕТ, ЕСЛИ УСЛОВИЯ НЕ ВЫПОЛНЕНЫ, НО НЕ ВКЛЮЧАЕМ >>>
	var should_disable_light = not has_light_crystal or not is_dark_level
	
	if should_disable_light and is_player_light_active:
		# Если свет активен, но не должен быть (нет кристалла или не темно), выключаем
		is_player_light_active = false
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("disable_light"):
			print("PlayerStateManager: Automatically disabling light (no crystal or not dark).")
			player.disable_light()
			
		player_light_state_changed.emit(is_player_light_active)
		
	# Важно: мы больше НЕ включаем свет здесь автоматически.
	# Включение происходит только через activate_selected_item_ability в player.gd.
	
	# Оставшаяся часть - проверка, если is_player_light_active стал false
	elif not is_player_light_active and not should_disable_light:
		# Это условие может возникнуть, если игрок вручную выключил свет,
		# но технически он должен быть активен (есть кристалл и темно).
		# В этом случае мы ничего не делаем, оставляя ручное управление.
		pass
	# elif is_player_light_active and not should_disable_light:
	# 	# Если свет активен и должен быть активен - ничего не делаем
	# 	pass
	# elif not is_player_light_active and should_disable_light:
	# 	# Если свет не активен и не должен быть активен - ничего не делаем
	# 	pass

# === ВНУТРЕННИЕ МЕТОДЫ ===
func _toggle_player_input(enable: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_input_enabled"):
		player.set_input_enabled(enable)

func _on_game_over_timer_timeout():
	# Убеждаемся, что Game Over сообщение не останется видимым на главном экране
	if ui_manager:
		# Небольшая задержка перед game_over сигналом, чтобы анимация скрытия успела отработать
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func(): game_over.emit()).set_delay(0.1)
	else:
		game_over.emit() 