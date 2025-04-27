extends CharacterBody2D

signal dialog_finished

const SPEED = 0.0
const JUMP_VELOCITY = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var dialog_data: Resource
@export var interaction_key_hint: String = "Нажмите Enter"

var game_manager = null
var player_in_range = false
var dialog_shown = false
var can_interact = true

var diary_dialog_scene = preload("res://scenes/professor_dialog.tscn")
var current_dialog = null

@onready var interaction_hint = $InteractionHint

func _ready():
	add_to_group("diary")
	
	if interaction_hint:
		interaction_hint.text = interaction_key_hint
	
	ensure_dialog_resource_loaded()
	find_game_manager()

func find_game_manager():
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		return true
		
	if get_tree():
		var manager = get_tree().get_first_node_in_group("game_manager")
		if manager:
			game_manager = manager
			return true
	
	return false

func ensure_dialog_resource_loaded():
	if not dialog_data:
		return false
		
	if dialog_data.dialogue_pages.is_empty():
		var resource_path = dialog_data.resource_path
		if resource_path and not resource_path.is_empty():
			var reloaded_data = load(resource_path)
			if reloaded_data:
				dialog_data = reloaded_data
				return true
			else:
				return false
		else:
			return false
	
	return true

func _process(_delta):
	if not game_manager and Engine.get_process_frames() % 60 == 0:
		find_game_manager()

	if player_in_range and can_interact and not dialog_shown:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			show_dialog(dialog_data)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		
		if interaction_hint and can_interact and not dialog_shown:
			interaction_hint.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		
		if interaction_hint:
			interaction_hint.visible = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func show_dialog(dialog_resource: Resource):
	if dialog_shown:
		return
	
	if not game_manager:
		if not find_game_manager():
			return
	
	if not dialog_resource or not ensure_dialog_resource_loaded():
		return
	
	dialog_shown = true
	can_interact = false
	
	if game_manager and game_manager.has_method("set_dialog_active"):
		game_manager.set_dialog_active(true)
	
	if interaction_hint:
		interaction_hint.visible = false
		
	current_dialog = diary_dialog_scene.instantiate()
	
	if game_manager.ui_layer:
		game_manager.ui_layer.add_child(current_dialog)
		
		if not current_dialog.dialog_closed.is_connected(_on_dialog_closed):
			current_dialog.dialog_closed.connect(_on_dialog_closed)
			
		current_dialog.start_dialogue(dialog_resource.dialogue_pages)

		set_physics_process(false)
		set_process(false)
		set_process_input(false)
	else:
		dialog_shown = false
		can_interact = true
		current_dialog = null

func _on_dialog_closed():
	if not dialog_shown:
		return

	dialog_finished.emit()
	
	if game_manager and game_manager.has_method("set_dialog_active"):
		game_manager.set_dialog_active(false)

	call_deferred("_restore_after_dialog")

	var portal = get_tree().get_first_node_in_group("portal")
	if portal:
		if portal.has_node("Sprite2D"):
			var portal_sprite = portal.get_node("Sprite2D")
			if portal_sprite:
				var original_color = portal_sprite.modulate
				var tween = portal.create_tween()
				tween.tween_property(portal_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.5)
				tween.tween_property(portal_sprite, "modulate", original_color, 0.5)

func _restore_after_dialog():
	dialog_shown = false
	current_dialog = null
	
	set_physics_process(true)
	set_process(true)
	set_process_input(true)
	
	var interaction_cooldown_timer = get_tree().create_timer(0.3)
	await interaction_cooldown_timer.timeout
	
	can_interact = true
	
	if player_in_range and interaction_hint:
		interaction_hint.visible = true