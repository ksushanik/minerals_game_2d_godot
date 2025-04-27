extends CharacterBody2D

signal dialog_finished

# --- Физические константы (пока не используются для движения, но нужны для CharacterBody2D) ---
const SPEED = 0.0  # Профессор не будет двигаться сам
const JUMP_VELOCITY = 0.0 # Профессор не прыгает
# Получаем гравитацию из настроек проекта
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# -----------------------------------------------------------------------------------------

# Ссылка на ItemData с текстом диалога
@export var dialog_data: Resource # Будет использоваться ItemData
@export var success_dialog_data: Resource # Новый диалог (успех) - если назначен, показывается он
# @export var required_items: Array[Resource] = [] # УБИРАЕМ - проверка инвентаря не нужна

var game_manager = null
var player_in_range = false
var dialog_shown = false
var can_interact = true

# Новая переменная для ссылки на сцену диалога
var professor_dialog_scene = preload("res://scenes/professor_dialog.tscn")
var current_dialog = null
var current_dialog_to_show: Resource = null # Какой диалог показывать сейчас

# Загружаем сцену эффекта
var confetti_scene = preload("res://scenes/effects/confetti_effect.tscn")

@onready var interaction_hint = $InteractionHint

func _ready():
	if dialog_data and dialog_data.dialogue_pages.is_empty():
		var resource_path = dialog_data.resource_path
		if resource_path and not resource_path.is_empty():
			var reloaded_data = load(resource_path)
			if reloaded_data:
				dialog_data = reloaded_data
	
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not current_dialog:
			if success_dialog_data:
				current_dialog_to_show = success_dialog_data
			else:
				current_dialog_to_show = dialog_data
			show_dialog(current_dialog_to_show)

# ДОБАВЛЯЕМ обработку ввода через _input
func _input(event):
	# Только если взаимодействие возможно
	if player_in_range and can_interact and not dialog_shown:
		if event.is_action_pressed("ui_accept"):
			if success_dialog_data:
				current_dialog_to_show = success_dialog_data
			else:
				current_dialog_to_show = dialog_data
			show_dialog(current_dialog_to_show) # Используем выбранный диалог
			# Поглощаем событие здесь, чтобы оно точно никуда не прошло дальше
			get_viewport().set_input_as_handled()

# Возвращаем обработчики сигналов для DialogueArea
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		
		# Отображаем подсказку о взаимодействии
		if $InteractionHint:
			$InteractionHint.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		
		# Скрываем подсказку
		if $InteractionHint:
			$InteractionHint.visible = false

# Новая функция для обработки физики
func _physics_process(delta):
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Можно добавить небольшое трение или остановку, если бы он двигался
		velocity.x = move_toward(velocity.x, 0, SPEED) # Хотя SPEED = 0

	move_and_slide()

func show_dialog(dialog_resource: Resource):
	if not game_manager:
		return
		
	if not dialog_resource or dialog_resource.dialogue_pages.is_empty():
		return
		
	current_dialog = professor_dialog_scene.instantiate()
	
	if game_manager.ui_layer:
		game_manager.ui_layer.add_child(current_dialog)
		
		# Подключаемся к сигналу закрытия
		if not current_dialog.dialog_closed.is_connected(_on_dialog_closed):
			current_dialog.dialog_closed.connect(_on_dialog_closed)
			
		# Запускаем диалог, передавая массив страниц
		current_dialog.start_dialogue(dialog_resource.dialogue_pages)
		
		# Отмечаем, что диалог был показан
		dialog_shown = true
		can_interact = false

		# ВРЕМЕННО ОТКЛЮЧАЕМ ФИЗИКУ
		set_physics_process(false)

		# ТАКЖЕ ОТКЛЮЧАЕМ ОБЫЧНЫЙ ПРОЦЕСС (обработку ввода)
		set_process(false)

		# ОТКЛЮЧАЕМ ОБРАБОТКУ ВВОДА
		set_process_input(false)

		# Скрываем подсказку
		if $InteractionHint:
			$InteractionHint.visible = false

func _on_dialog_closed():
	dialog_finished.emit()

	# --- ПРОВЕРКА ДЛЯ КОНФЕТТИ (УПРОЩЕНА) ---
	# Запускаем конфетти, если для этого профессора НАЗНАЧЕН диалог успеха
	if success_dialog_data:
		if confetti_scene:
			var confetti_instance = confetti_scene.instantiate()
			if is_instance_valid(confetti_instance):
				confetti_instance.global_position = self.global_position + Vector2(0, -30)
				var parent_node = get_parent()
				if is_instance_valid(parent_node):
					parent_node.add_child(confetti_instance)
	# ----------------------------------------

	# ОТКЛАДЫВАЕМ включение физики и процесса на следующий кадр
	call_deferred("set_physics_process", true)
	call_deferred("set_process", true)
	# ОТКЛАДЫВАЕМ ВКЛЮЧЕНИЕ ОБРАБОТКИ ВВОДА
	call_deferred("set_process_input", true)
	# Откладываем сброс флагов (функция _reset_interaction_flags остается, но без флага)
	call_deferred("_reset_interaction_flags")

	var portal = get_tree().get_first_node_in_group("portal")
	if portal:
		if portal.has_node("Sprite2D"):
			var portal_sprite = portal.get_node("Sprite2D")
			# Добавляем подсветку к порталу
			if portal_sprite:
				var original_color = portal_sprite.modulate
				# Мигание порталом, чтобы указать что он активен
				var tween = portal.create_tween()
				tween.tween_property(portal_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.5)
				tween.tween_property(portal_sprite, "modulate", original_color, 0.5)
				tween.set_loops(3)  # Мигнуть 3 раза
		
		# Добавляем подсказку к порталу
		var hint = Label.new()
		hint.name = "PortalHint"
		hint.text = "Портал активирован! Идите к нему."
		hint.position = Vector2(0, -50)  # Позиционируем подсказку над порталом
		hint.horizontal_alignment = 1  # 1 = Center
		portal.add_child(hint)

# Новая функция для отложенного сброса флагов
func _reset_interaction_flags():
	dialog_shown = false
	can_interact = true

# НОВАЯ ФУНКЦИЯ: Проверяет инвентарь и устанавливает current_dialog_to_show
# --- УДАЛЯЕМ ВСЮ ФУНКЦИЮ check_quest_status --- 
# func check_quest_status():
# ... (код функции check_quest_status)

	
