extends CharacterBody2D

const SPEED = 130.0
var JUMP_VELOCITY = -300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var point_light = $PointLight2D

var game_manager = null
var is_player_dead = false
var can_double_jump = false
var has_double_jumped = false
var input_enabled = true

var push_force_multiplier: float = 5000.0
@export_multiline var notification_stone_too_heavy: String = "Этот камень слишком тяжелый..."

# <<< ПЕРЕМЕННЫЕ ДЛЯ МЕРЦАНИЯ >>>
@onready var flash_timer = Timer.new()
var is_flashing = false
var original_modulate: Color = Color(1, 1, 1, 1)

# <<< Заменяем jump_boost_timer на общий ability_timer >>>
@onready var ability_timer = Timer.new()
const DEFAULT_JUMP_VELOCITY = -300.0
# <<< Переменная для хранения активного предмета >>>
var active_ability_item: ItemData = null
# <<< ФЛАГ АКТИВНОГО УСИЛЕНИЯ СИЛЫ >>>
var is_strength_boost_active: bool = false

func _ready():
	add_to_group("player")
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
	# <<< УДАЛЯЕМ АВТО-ВКЛЮЧЕНИЕ СВЕТА В _ready >>>
	# if game_manager and game_manager.is_player_light_active() and point_light:
	# 	point_light.enabled = true

	# <<< ИНИЦИАЛИЗАЦИЯ ТАЙМЕРА МЕРЦАНИЯ >>>
	flash_timer.wait_time = 0.07 # <<< Уменьшаем интервал для более частого мигания >>>
	flash_timer.one_shot = false
	flash_timer.timeout.connect(_on_flash_timer_timeout)
	add_child(flash_timer)

	# <<< Инициализация общего таймера способности >>>
	ability_timer.one_shot = true
	# wait_time будет устанавливаться при активации
	ability_timer.timeout.connect(_deactivate_current_ability)
	add_child(ability_timer)

func _physics_process(delta):
	if not is_instance_valid(game_manager):
		return

	var player_is_dead = game_manager.is_player_dead()
	if player_is_dead:
		return

	if not input_enabled:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if is_on_floor() and animated_sprite:
			animated_sprite.play("idle")
			
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_double_jumped = false

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif can_double_jump and not has_double_jumped:
			velocity.y = JUMP_VELOCITY
			has_double_jumped = true

	var direction = Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			# --- Логика камней --- 
			if collider and collider.is_in_group("pushable_stone"):
				# <<< ОТЛАДКА: Печатаем состояние камня при столкновении >>>
				print("Player collision with Stone: %s, can_be_pushed: %s" % [collider.name, collider.can_be_pushed])

				# Напрямую проверяем состояние камня
				if collider.can_be_pushed:
					# Проверяем направление для толчка
					if direction != 0 and sign(direction) == sign(collision.get_normal().x * -1):
						var push_direction = Vector2(direction, 0).normalized()
						collider.apply_central_impulse(push_direction * push_force_multiplier * delta)
				else:
					# Проверяем направление для показа уведомления
					if direction != 0 and sign(direction) == sign(collision.get_normal().x * -1):
						if game_manager and game_manager.has_method("show_notification"):
							game_manager.show_notification(notification_stone_too_heavy, 2.0)
			# --- Конец логики камней ---

	# <<< ОБРАБОТКА АКТИВАЦИИ СПОСОБНОСТИ >>>
	if Input.is_action_just_pressed("activate_ability"):
		activate_selected_item_ability()

func enable_light():
	if point_light:
		point_light.enabled = true

func disable_light():
	if point_light:
		point_light.enabled = false

func GameManager(_coin_node: Variant, _description: Variant) -> void:
	pass

func die():
	if is_player_dead:
		return
		
	is_player_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	await animated_sprite.animation_finished
	
	if game_manager and game_manager.has_method("_on_player_death"):
		game_manager._on_player_death()

func set_jump_velocity(new_velocity: float):
	JUMP_VELOCITY = new_velocity

func enable_double_jump(enable: bool):
	can_double_jump = enable
	if not enable:
		has_double_jumped = false

func set_input_enabled(enabled: bool):
	if input_enabled == enabled:
		return
		
	input_enabled = enabled
	
	if not enabled:
		velocity.x = 0
		
		if is_on_floor() and animated_sprite:
			animated_sprite.play("idle")
	
	if animated_sprite:
		var tween = create_tween()
		if enabled:
			tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.3)
		else:
			tween.tween_property(animated_sprite, "modulate", Color(0.8, 0.8, 0.8, 1), 0.3)

# <<< НОВЫЕ МЕТОДЫ ДЛЯ МЕРЦАНИЯ >>>
func start_flashing(duration: float = 0.8): # <<< Вернем длительность к 0.8с, т.к. перезагрузка все равно прервет >>>
	if is_flashing or not is_instance_valid(animated_sprite):
		return # Не запускать, если уже мерцает или спрайт невалиден
	
	print("Player: Starting flashing (red/invisible)")
	is_flashing = true
	# <<< Сохраняем текущий цвет перед началом >>>
	original_modulate = animated_sprite.modulate
	# <<< Начать с красного >>>
	animated_sprite.modulate = Color(1, 0.5, 0.5, 1)
	flash_timer.start()
	# Остановить мерцание через 'duration' секунд
	get_tree().create_timer(duration).timeout.connect(stop_flashing)

func _on_flash_timer_timeout():
	if not is_flashing or not is_instance_valid(animated_sprite):
		flash_timer.stop()
		return
	# <<< Переключать между красным и невидимым >>>
	if animated_sprite.modulate.a == 0:
		# Если был невидимым, сделать красным
		animated_sprite.modulate = Color(1, 0.5, 0.5, 1)
	else:
		# Если был видимым (красным), сделать невидимым
		animated_sprite.modulate.a = 0

func stop_flashing():
	if not is_flashing:
		return 
	print("Player: Stopping flashing")
	is_flashing = false
	flash_timer.stop()
	if is_instance_valid(animated_sprite):
		# <<< Вернуть исходный цвет и непрозрачность >>>
		animated_sprite.modulate = original_modulate
# <<< КОНЕЦ НОВЫХ МЕТОДОВ >>>

# Метод для сброса состояния игрока при перезапуске игры
func reset_state():
	print("Player: Resetting player state")
	is_player_dead = false
	input_enabled = true
	has_double_jumped = false
	
	# <<< Останавливаем таймер и деактивируем способность при ресете >>>
	if not ability_timer.is_stopped():
		ability_timer.stop()
	_deactivate_current_ability() # Сбрасываем эффекты (свет, прыжок, СИЛУ)
	
	# Сбрасываем скорость
	velocity = Vector2.ZERO
	# Сбрасываем силу прыжка (уже делается в _deactivate_current_ability, но для надежности)
	set_jump_velocity(DEFAULT_JUMP_VELOCITY)
	
	# Восстанавливаем коллизии
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# Проигрываем анимацию покоя
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.modulate = Color(1, 1, 1, 1)

# <<< Переименованная и измененная функция >>>
func activate_selected_item_ability():
	if not game_manager or not game_manager.inventory_facade:
		print("Player: Cannot activate ability - GameManager or InventoryFacade not found.")
		return
		
	# <<< Получаем ВЫБРАННЫЙ предмет >>>
	var selected_item: ItemData = game_manager.inventory_facade.get_selected_inventory_item()
	
	# <<< Проверяем, выбран ли предмет >>>
	if not selected_item:
		if game_manager.has_method("show_notification"):
			game_manager.show_notification("Предмет не выбран. Откройте инвентарь (I) и выберите предмет.", 2.0)
		return

	print("Player: Attempting to activate selected item: ", selected_item.item_name)

	# <<< Проверяем, активна ли уже другая способность >>>
	if active_ability_item != null and active_ability_item != selected_item:
		# Если активен другой предмет, сначала деактивируем его
		_deactivate_current_ability()
		# Останавливаем таймер, если он был запущен
		if not ability_timer.is_stopped():
			ability_timer.stop()
			
	# <<< ПРОВЕРКА ДЛИТЕЛЬНОСТИ >>>
	var is_timed_ability = selected_item.duration > 0.0
	var effect_applied = false

	# --- Применяем эффекты --- 
	if selected_item.resource_path == "res://resources/items/light_crystal.tres":
		# <<< ПРОВЕРЯЕМ, ЯВЛЯЕТСЯ ЛИ УРОВЕНЬ ТЕМНЫМ >>>
		var level_is_dark = false
		if game_manager and game_manager.level_system and game_manager.level_system.has_method("is_level_dark"):
			level_is_dark = game_manager.level_system.is_level_dark()
		
		if level_is_dark:
			if point_light and not point_light.enabled:
				enable_light()
				effect_applied = true
			else:
				# Если свет уже включен, сообщаем и не запускаем таймер
				if game_manager.has_method("show_notification"):
					game_manager.show_notification("Свет уже включен.", 1.5)
				is_timed_ability = false # Считаем, что таймер не нужен
		else:
			# <<< Уровень НЕ темный >>>
			if game_manager.has_method("show_notification"):
				game_manager.show_notification("Свет здесь не нужен.", 1.5)
			is_timed_ability = false # Таймер не нужен, эффект не применен
	
	elif selected_item.resource_path == "res://resources/items/carbon.tres":
		# <<< ПРОВЕРКА НАХОЖДЕНИЯ В ЗОНЕ УСИЛЕНИЯ ПРЫЖКА >>>
		if is_in_jump_boost_zone():
			var base_jump_velocity = DEFAULT_JUMP_VELOCITY
			var boost_factor = 1.8
			var boosted_jump_velocity = base_jump_velocity * boost_factor
			
			if abs(JUMP_VELOCITY - boosted_jump_velocity) > 0.1:
				set_jump_velocity(boosted_jump_velocity)
				effect_applied = true
			else:
				if game_manager.has_method("show_notification"):
					game_manager.show_notification("Прыжок уже усилен.", 1.5)
				is_timed_ability = false
		else:
			# <<< Игрок НЕ в зоне усиления >>>
			if game_manager.has_method("show_notification"):
				game_manager.show_notification("Углерод здесь бесполезен.", 1.5)
			is_timed_ability = false # Таймер не нужен, эффект не применен
	
	elif selected_item.resource_path == "res://resources/items/iron.tres":
		if not is_strength_boost_active:
			is_strength_boost_active = true
			effect_applied = true
			# Вызываем set_pushable(true) для всех камней
			_toggle_nearby_stones_pushable(true)
		else:
			# Если уже активно, сообщаем и не запускаем таймер
			if game_manager.has_method("show_notification"):
				game_manager.show_notification("Усиление силы уже активно.", 1.5)
			is_timed_ability = false # Считаем, что таймер не нужен
	
	else:
		# Предмет без эффекта
		if game_manager.has_method("show_notification"):
			game_manager.show_notification("Предмет '" + selected_item.item_name + "' не имеет активного эффекта.", 2.0)

	# --- Запускаем таймер и показываем уведомление, если нужно --- 
	if effect_applied:
		if is_timed_ability:
			# Сохраняем активный предмет
			active_ability_item = selected_item
			# Запускаем таймер с длительностью из предмета
			ability_timer.wait_time = selected_item.duration
			ability_timer.start()
			# Показываем уведомление с длительностью
			if game_manager.has_method("show_notification"):
				game_manager.show_notification("'" + selected_item.item_name + "' активирован! Эффект продлится " + str(selected_item.duration) + " сек.", 2.0)
		else:
			# Если эффект мгновенный/пассивный и был применен
			if game_manager.has_method("show_notification"):
				game_manager.show_notification("'" + selected_item.item_name + "' активирован!", 2.0)
			# Сбрасываем active_ability_item, так как эффект не временный
			active_ability_item = null 
			
# <<< КОНЕЦ НОВОГО МЕТОДА >>>

# <<< НОВАЯ ОБЩАЯ ФУНКЦИЯ ДЛЯ СБРОСА ЭФФЕКТА >>>
func _deactivate_current_ability():
	if not active_ability_item:
		return

	print("Player: Deactivating ability for item: ", active_ability_item.item_name)
	var notification_text = "Эффект '" + active_ability_item.item_name + "' закончился."

	# Определяем, какой эффект сбросить
	if active_ability_item.resource_path == "res://resources/items/light_crystal.tres":
		if point_light and point_light.enabled:
			disable_light()
		else:
			notification_text = ""
			
	elif active_ability_item.resource_path == "res://resources/items/carbon.tres":
		var base_jump_velocity = DEFAULT_JUMP_VELOCITY
		var boost_factor = 1.8
		var boosted_jump_velocity = base_jump_velocity * boost_factor
		if abs(JUMP_VELOCITY - boosted_jump_velocity) < 0.1:
			set_jump_velocity(DEFAULT_JUMP_VELOCITY)
		else:
			notification_text = ""
			
	# <<< ДОБАВЛЯЕМ СБРОС УСИЛЕНИЯ СИЛЫ >>>
	elif active_ability_item.resource_path == "res://resources/items/iron.tres":
		if is_strength_boost_active:
			is_strength_boost_active = false
			# Вызываем set_pushable(false) для всех камней
			_toggle_nearby_stones_pushable(false)
		else:
			notification_text = "" # Не показываем уведомление, если и так неактивно
			
	else:
		notification_text = ""

	# Показываем уведомление, если оно есть
	if notification_text != "" and game_manager and game_manager.has_method("show_notification"):
		game_manager.show_notification(notification_text, 1.5)
		
	# Сбрасываем активный предмет
	active_ability_item = null

# <<< НОВЫЙ МЕТОД ДЛЯ ПЕРЕКЛЮЧЕНИЯ КАМНЕЙ >>>
func _toggle_nearby_stones_pushable(enable: bool):
	# Можно искать камни в определенном радиусе или просто все на уровне
	var stones = get_tree().get_nodes_in_group("pushable_stone")
	for stone in stones:
		if stone.has_method("set_pushable"):
			stone.set_pushable(enable)
			
# <<< КОНЕЦ НОВОГО МЕТОДА >>>

# <<< ИСПРАВЛЕННЫЙ МЕТОД ПРОВЕРКИ ЗОНЫ ПРЫЖКА >>>
func is_in_jump_boost_zone() -> bool:
	# Получаем все узлы зон усиления на сцене
	var boost_zones = get_tree().get_nodes_in_group("jump_boost_zone")
	for zone in boost_zones:
		# Проверяем, является ли узел Area2D и пересекает ли он тело игрока
		if zone is Area2D and zone.has_method("overlaps_body") and zone.overlaps_body(self):
			return true # Найдено пересечение с зоной усиления
	return false # Зон усиления, с которыми пересекается игрок, не найдено
