extends CharacterBody2D

signal dialog_finished

# Физические константы
const SPEED = 0.0
const JUMP_VELOCITY = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ресурсы диалогов
@export var dialog_data: Resource
@export var success_dialog_data: Resource

# Основные переменные
var game_manager = null
var player_in_range = false
var dialog_shown = false
var can_interact = true

# Ссылки на сцены
var professor_dialog_scene = preload("res://scenes/professor_dialog.tscn")
var confetti_scene = preload("res://scenes/effects/confetti_effect.tscn")
var current_dialog = null
var current_dialog_to_show: Resource = null

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

func _input(event):
	if player_in_range and can_interact and not dialog_shown:
		if event.is_action_pressed("ui_accept"):
			if success_dialog_data:
				current_dialog_to_show = success_dialog_data
			else:
				current_dialog_to_show = dialog_data
			show_dialog(current_dialog_to_show)
			get_viewport().set_input_as_handled()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if $InteractionHint:
			$InteractionHint.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if $InteractionHint:
			$InteractionHint.visible = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func show_dialog(dialog_resource: Resource):
	if not game_manager:
		return
		
	if not dialog_resource or dialog_resource.dialogue_pages.is_empty():
		return
		
	current_dialog = professor_dialog_scene.instantiate()
	
	if game_manager.get_ui_layer():
		game_manager.get_ui_layer().add_child(current_dialog)
		
		if not current_dialog.dialog_closed.is_connected(_on_dialog_closed):
			current_dialog.dialog_closed.connect(_on_dialog_closed)
			
		current_dialog.start_dialogue(dialog_resource.dialogue_pages)
		
		dialog_shown = true
		can_interact = false

		set_physics_process(false)
		set_process(false)
		set_process_input(false)

		if $InteractionHint:
			$InteractionHint.visible = false

func _on_dialog_closed():
	dialog_finished.emit()

	# Запускаем конфетти для профессора с диалогом успеха
	if success_dialog_data:
		if confetti_scene:
			var confetti_instance = confetti_scene.instantiate()
			if is_instance_valid(confetti_instance):
				confetti_instance.global_position = self.global_position + Vector2(0, -30)
				var parent_node = get_parent()
				if is_instance_valid(parent_node):
					parent_node.add_child(confetti_instance)

	# Откладываем включение процессов на следующий кадр
	call_deferred("set_physics_process", true)
	call_deferred("set_process", true)
	call_deferred("set_process_input", true)
	call_deferred("_reset_interaction_flags")

	# Активируем портал
	var portal = get_tree().get_first_node_in_group("portal")
	if portal:
		if portal.has_node("Sprite2D"):
			var portal_sprite = portal.get_node("Sprite2D")
			if portal_sprite:
				var original_color = portal_sprite.modulate
				var tween = portal.create_tween()
				tween.tween_property(portal_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.5)
				tween.tween_property(portal_sprite, "modulate", original_color, 0.5)
				tween.set_loops(3)
		
		# Добавляем подсказку к порталу
		var hint = Label.new()
		hint.name = "PortalHint"
		hint.text = "Портал активирован! Идите к нему."
		hint.position = Vector2(0, -50)
		hint.horizontal_alignment = 1
		portal.add_child(hint)

func _reset_interaction_flags():
	dialog_shown = false
	can_interact = true

	
