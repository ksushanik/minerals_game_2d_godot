extends Node

class_name UIManager

# === СИГНАЛЫ ===
signal notification_shown(text, duration)
signal notification_hidden

# === НАСТРОЙКИ UI ===
@export_group("Lives UI")
@export var lives_font_size: int = 24
@export var lives_font: Font = null
@export var lives_low_color: Color = Color(0.8, 0.2, 0.2, 1)  # Красный
@export var lives_medium_color: Color = Color(0.8, 0.8, 0.2, 1)  # Желтый
@export var lives_high_color: Color = Color(0.2, 0.8, 0.2, 1)  # Зеленый

@export_group("Game Over")
@export var game_over_text: String = "ИГРА ОКОНЧЕНА!"
@export var game_over_font: Font = null  # Будем использовать шрифт из темы
@export var game_over_alt_fonts: Array[Font] = []
@export var game_over_font_size: int = 48
@export var game_over_color: Color = Color.RED
@export var game_over_offset_y: float = 0.0
@export var game_over_offset_x: float = 0.0
@export var game_over_shadow_color: Color = Color.BLACK
@export var game_over_shadow_offset: Vector2 = Vector2(2, 2)
@export var game_over_z_index: int = 50
@export var game_over_flash_colors: Array[Color] = [
	Color.RED,
	Color.ORANGE_RED,
	Color.DARK_RED
]
@export var flash_speed: float = 0.5
@export var shake_amount: float = 5.0
@export var shake_duration: float = 0.1
@export var custom_min_width: float = 600.0
@export var custom_min_height: float = 100.0
@export var font_size_multiplier: float = 1.5

@export_group("Notifications")
@export var notification_font: Font = null
@export var notification_font_color: Color = Color.WHITE
@export var notification_font_size: int = 22
@export var notification_vertical_offset: float = 10.0
@export var notification_panel_color: Color = Color(0, 0, 0, 0.6)
@export var notification_panel_padding: float = 5.0
@export var notification_shadow_color: Color = Color.BLACK
@export var notification_shadow_offset: Vector2 = Vector2(1, 1)

# === UI ЭЛЕМЕНТЫ ===
var ui_layer: CanvasLayer
var lives_label: Label
var notification_panel: PanelContainer
var notification_label: Label
var notification_timer: Timer
var game_over_label: Label
var game_over_bg: ColorRect
var game_over_sound: AudioStreamPlayer

# === СОСТОЯНИЕ UI ===
var show_lives_ui: bool = true

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	_create_ui_layer()
	_create_lives_label()
	_create_notification_panel()
	_create_notification_timer()
	_create_game_over_label()
	_create_game_over_sound()
	
	# Скрываем счетчик жизней на главном экране
	if is_on_main_menu():
		if lives_label:
			lives_label.visible = false

# Проверяем на каждом кадре, не находимся ли мы на главном экране
func _process(_delta):
	# Постоянно проверяем, не на главном ли мы экране
	if is_on_main_menu():
		# Скрываем счетчик жизней на главном экране
		if lives_label and lives_label.visible:
			lives_label.visible = false
		
		# Скрываем game over на главном экране
		if game_over_label and game_over_label.visible:
			hide_game_over()

# Проверка, находимся ли мы на главном экране
func is_on_main_menu() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene and (current_scene.name == "MainTitle" or current_scene.name.begins_with("MainTitle")):
		return true
	return false
	
func _create_ui_layer():
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.add_to_group("ui_layer")  # Добавляем в группу для обнаружения
	add_child(ui_layer)

func _create_lives_label():
	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lives_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lives_label.text = "Lives: 3"
	lives_label.add_theme_font_size_override("font_size", lives_font_size)
	
	if lives_font:
		lives_label.add_theme_font_override("font", lives_font)
	
	lives_label.add_theme_color_override("font_color", lives_high_color)
	
	# Позиционирование
	lives_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lives_label.position = Vector2(10, 10)
	
	ui_layer.add_child(lives_label)

func _create_notification_panel():
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
	
	# Стиль текста - используем шрифт PIXY или другой шрифт из темы
	var font_to_use = _select_notification_font()
	if font_to_use:
		notification_label.add_theme_font_override("font", font_to_use)
		print("UIManager: Применен шрифт для уведомлений: ", font_to_use.resource_path if font_to_use.resource_path else "Встроенный шрифт")
	
	notification_label.add_theme_color_override("font_color", notification_font_color)
	notification_label.add_theme_font_size_override("font_size", notification_font_size)
	notification_label.add_theme_color_override("font_shadow_color", notification_shadow_color)
	notification_label.add_theme_constant_override("shadow_offset_x", notification_shadow_offset.x)
	notification_label.add_theme_constant_override("shadow_offset_y", notification_shadow_offset.y)
	
	# Добавляем в иерархию
	notification_panel.add_child(notification_label)
	ui_layer.add_child(notification_panel)

func _create_notification_timer():
	notification_timer = Timer.new()
	notification_timer.name = "NotificationTimer"
	notification_timer.one_shot = true
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	add_child(notification_timer)

func _create_game_over_label():
	# Создаем фоновую панель на весь экран
	game_over_bg = ColorRect.new()
	game_over_bg.name = "GameOverBackground"
	game_over_bg.color = Color(0, 0, 0, 0.7)  # Полупрозрачный черный
	game_over_bg.set_anchors_preset(Control.PRESET_FULL_RECT)  # На весь экран
	game_over_bg.z_index = game_over_z_index - 1  # Чтобы был под текстом
	game_over_bg.visible = false
	ui_layer.add_child(game_over_bg)
	
	# Создаем контейнер на весь экран с центрированием содержимого
	var center_container = CenterContainer.new()
	center_container.name = "GameOverCenterContainer"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)  # На весь экран
	center_container.z_index = game_over_z_index
	ui_layer.add_child(center_container)
	
	# Создаем надпись Game Over внутри центрирующего контейнера
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = game_over_text
	
	# Настраиваем выравнивание текста внутри метки
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Принудительно задаем минимальную ширину для надписи, используя настраиваемые параметры
	game_over_label.custom_minimum_size = Vector2(custom_min_width, custom_min_height)
	
	# Применяем шрифт
	var font_to_use = _select_game_over_font()
	if font_to_use:
		game_over_label.add_theme_font_override("font", font_to_use)
		print("UIManager: Применяем шрифт из инспектора: ", font_to_use.resource_path if font_to_use.resource_path else "Встроенный шрифт")
	else:
		print("UIManager: Не удалось загрузить шрифт для Game Over")
	
	# Применяем стиль
	game_over_label.add_theme_font_size_override("font_size", int(game_over_font_size * font_size_multiplier))
	game_over_label.add_theme_color_override("font_color", game_over_color)
	game_over_label.add_theme_color_override("font_shadow_color", game_over_shadow_color)
	game_over_label.add_theme_constant_override("shadow_offset_x", game_over_shadow_offset.x)
	game_over_label.add_theme_constant_override("shadow_offset_y", game_over_shadow_offset.y)
	game_over_label.visible = false
	
	# Добавляем метку в центрирующий контейнер
	center_container.add_child(game_over_label)

	# Сохраняем ссылки для анимаций
	game_over_label.set_meta("center_container", center_container)

func _create_game_over_sound():
	game_over_sound = AudioStreamPlayer.new()
	game_over_sound.name = "GameOverSound"
	game_over_sound.stream = load("res://assets/sounds/explosion.wav")
	game_over_sound.volume_db = -5.0  # Немного тише, чтобы не оглушить игрока
	add_child(game_over_sound)

# === ПУБЛИЧНЫЕ МЕТОДЫ ===
func update_lives_display(lives: int):
	if lives_label:
		lives_label.text = "Lives: " + str(lives)
		
		# Меняем цвет в зависимости от количества жизней
		if lives <= 1:
			lives_label.add_theme_color_override("font_color", lives_low_color)
		elif lives == 2:
			lives_label.add_theme_color_override("font_color", lives_medium_color)
		else:
			lives_label.add_theme_color_override("font_color", lives_high_color)

func set_lives_visibility(visible: bool):
	show_lives_ui = visible
	if lives_label:
		# Не показываем счетчик жизней на главном экране в любом случае
		if is_on_main_menu():
			lives_label.visible = false
		else:
			lives_label.visible = visible

func show_game_over():
	if game_over_label:
		# Обновляем настройки текста перед показом
		game_over_label.text = game_over_text
		
		# Просто используем шрифт, выбранный в инспекторе через _select_game_over_font()
		var font_to_use = _select_game_over_font()
		if font_to_use:
			game_over_label.add_theme_font_override("font", font_to_use)
			print("UIManager: Применяем шрифт из инспектора: ", font_to_use.resource_path if font_to_use.resource_path else "Встроенный шрифт")
		
		# Обновляем размер шрифта и другие настройки
		game_over_label.add_theme_font_size_override("font_size", int(game_over_font_size * font_size_multiplier))
		game_over_label.add_theme_color_override("font_color", game_over_color)
		game_over_label.add_theme_color_override("font_shadow_color", game_over_shadow_color)
		
		# Получаем контейнер
		var center_container = game_over_label.get_meta("center_container")
		
		# Сначала скрываем лейбл, чтобы подготовить анимацию
		game_over_label.modulate = Color(1, 1, 1, 0)
		game_over_label.scale = Vector2(0.5, 0.5)
		game_over_label.visible = true
		
		# Сбрасываем смещение, если оно было установлено ранее
		if center_container:
			# Применяем пользовательское смещение только если оно отлично от нуля
			if game_over_offset_x != 0 or game_over_offset_y != 0:
				# Создаем Node2D для управления смещением
				var offset_node = Node2D.new()
				offset_node.name = "OffsetNode"
				offset_node.position = Vector2(game_over_offset_x, game_over_offset_y)
				# Перемещаем метку в этот узел
				game_over_label.reparent(offset_node)
				center_container.add_child(offset_node)
				# Обновляем ссылку на родительский узел для анимаций
				game_over_label.set_meta("parent_for_animations", offset_node)
			else:
				game_over_label.set_meta("parent_for_animations", center_container)
		
		# Показываем фон
		if game_over_bg:
			game_over_bg.modulate = Color(1, 1, 1, 0)
			game_over_bg.visible = true
			
			# Анимация фона
			var bg_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			bg_tween.tween_property(game_over_bg, "modulate", Color(1, 1, 1, 1), 0.3)
		
		# Создаем анимацию появления
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(game_over_label, "modulate", Color(1, 1, 1, 1), 0.5)
		tween.parallel().tween_property(game_over_label, "scale", Vector2(1, 1), 0.7)
		
		# Воспроизводим звук
		if game_over_sound:
			game_over_sound.play()
		
		# Запускаем мигание и тряску текста после появления
		tween.tween_callback(_start_flashing_game_over_text)
		tween.tween_callback(_start_shaking_game_over_text)

func _start_flashing_game_over_text():
	if not game_over_label or not game_over_label.visible:
		return
		
	# Создаем бесконечное мигание до скрытия лейбла
	var flash_tween = create_tween().set_loops()
	
	# Если есть массив цветов, переключаемся между ними
	if game_over_flash_colors.size() > 0:
		# Используем собственный цвет как основу для мигания
		var base_color = game_over_color
		for i in range(game_over_flash_colors.size()):
			var flash_color = base_color.lerp(game_over_flash_colors[i], 0.5)
			flash_tween.tween_callback(func(): 
				game_over_label.add_theme_color_override("font_color", flash_color)
			)
			flash_tween.tween_interval(flash_speed)
		
		# Возвращаем исходный цвет
		flash_tween.tween_callback(func(): 
			game_over_label.add_theme_color_override("font_color", base_color)
		)
		flash_tween.tween_interval(flash_speed)
	else:
		# Иначе просто мигаем между цветом и более темной версией
		var base_color = game_over_color
		var dark_color = base_color.darkened(0.3)
		
		flash_tween.tween_callback(func(): 
			game_over_label.add_theme_color_override("font_color", dark_color)
		)
		flash_tween.tween_interval(flash_speed)
		flash_tween.tween_callback(func(): 
			game_over_label.add_theme_color_override("font_color", base_color)
		)
		flash_tween.tween_interval(flash_speed)

func _start_shaking_game_over_text():
	if not game_over_label or not game_over_label.visible:
		return
		
	# Получаем нужный узел для применения тряски
	var parent_node = game_over_label.get_meta("parent_for_animations")
	if not parent_node:
		return
	
	# Создаем бесконечный shake эффект
	var shake_tween = create_tween().set_loops()
	
	# Запоминаем исходную позицию
	var original_pos = parent_node.position
	
	# Движение в случайные стороны для создания эффекта тряски
	for i in range(10): # Делаем 10 случайных движений в одном цикле
		var random_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		var new_pos = original_pos + random_offset
		
		shake_tween.tween_property(parent_node, "position",
			new_pos, shake_duration)
	
	# Возвращаем в исходную позицию после одного цикла тряски
	shake_tween.tween_property(parent_node, "position",
		original_pos, shake_duration)

func hide_game_over():
	if not game_over_label:
		return
		
	# Анимация исчезновения
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(game_over_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(game_over_label, "scale", Vector2(1.5, 0.5), 0.3)
	
	# Используем колбэк для правильного скрытия после завершения анимации
	tween.tween_callback(func():
		game_over_label.visible = false
		game_over_label.scale = Vector2(1, 1)  # Сбрасываем масштаб
	)
	
	# Скрываем фон
	if game_over_bg:
		var bg_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		bg_tween.tween_property(game_over_bg, "modulate", Color(1, 1, 1, 0), 0.3)
		
		# Не меняем масштаб фона, просто затухание
		bg_tween.tween_callback(func():
			game_over_bg.visible = false
			game_over_bg.scale = Vector2(1, 1)  # Сбрасываем масштаб
		)

func show_notification(text: String, duration: float = 2.0):
	if notification_panel and notification_label and notification_timer:
		notification_label.text = text
		
		# Обновляем шрифт при каждом показе уведомления
		var font_to_use = _select_notification_font()
		if font_to_use:
			notification_label.add_theme_font_override("font", font_to_use)
		
		notification_panel.visible = true
		notification_timer.start(duration)
		notification_shown.emit(text, duration)

func _on_notification_timer_timeout():
	if notification_panel:
		notification_panel.visible = false
		notification_hidden.emit()

# === УПРАВЛЕНИЕ UI СЛОЕМ ===
func add_to_ui_layer(control: Control):
	if ui_layer:
		ui_layer.add_child(control)
		return true
	return false

func get_ui_layer() -> CanvasLayer:
	return ui_layer 

# Выбирает шрифт для уведомлений
func _select_notification_font() -> Font:
	# Если указан шрифт в настройках, используем его с приоритетом
	if notification_font:
		return notification_font
	
	# Пробуем использовать шрифт PIXY из темы
	var pixy_font = load("res://themes/pixi.ttf")
	if pixy_font:
		return pixy_font
	
	# Пробуем использовать пиксельный шрифт по умолчанию
	var pixel_font = load("res://assets/fonts/Minecraft/Minecraft-Bold.otf")
	if pixel_font:
		return pixel_font
		
	# Запасной вариант
	pixel_font = load("res://assets/fonts/NbPixelFontBundle_v1_0/Bitfantasy.ttf")
	if pixel_font:
		return pixel_font
	
	# Последний запасной вариант - из стандартной темы
	return ThemeDB.get_default_theme().get_font("font", "Label")

# Выбирает шрифт для Game Over текста
func _select_game_over_font() -> Font:
	# Если указан шрифт в настройках через инспектор, используем его с приоритетом
	if game_over_font:
		print("UIManager: Используем шрифт из инспектора: ", game_over_font.resource_path if game_over_font.resource_path else "Встроенный шрифт")
		return game_over_font
	
	# Запасной вариант - пробуем загрузить PIXY шрифт напрямую
	var pixy_font = load("res://themes/pixi.ttf")
	if pixy_font:
		print("UIManager: Используем запасной шрифт PIXY")
		return pixy_font
	
	# Загружаем пиксельный шрифт по умолчанию
	var pixel_font = load("res://assets/fonts/Minecraft/Minecraft-Bold.otf")
	if pixel_font:
		print("UIManager: Используем запасной шрифт Minecraft-Bold")
		return pixel_font
		
	# Другой запасной вариант
	pixel_font = load("res://assets/fonts/NbPixelFontBundle_v1_0/Bitfantasy.ttf")
	if pixel_font:
		print("UIManager: Используем запасной шрифт Bitfantasy")
		return pixel_font
	
	# Выбираем первый доступный шрифт из альтернативных
	if game_over_alt_fonts and game_over_alt_fonts.size() > 0:
		for font in game_over_alt_fonts:
			if font:
				print("UIManager: Используем альтернативный шрифт")
				return font
	
	# Последний запасной вариант - из стандартной темы
	print("UIManager: Используем шрифт из стандартной темы")
	return ThemeDB.get_default_theme().get_font("font", "Label") 