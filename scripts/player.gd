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

func _ready():
	add_to_group("player")
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
	if game_manager and game_manager.is_player_light_active and point_light:
		point_light.enabled = true

func _physics_process(delta):
	if not is_instance_valid(game_manager):
		return

	var player_is_dead = game_manager.is_player_dead
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
			if collider and collider.is_in_group("pushable_stone"):
				if collider.has_method("check_and_enable_push"):
					if collider.can_be_pushed:
						if direction != 0 and sign(direction) == sign(collision.get_normal().x * -1):
							var push_direction = Vector2(direction, 0).normalized()
							collider.apply_central_impulse(push_direction * push_force_multiplier * delta)
					else:
						if direction != 0 and sign(direction) == sign(collision.get_normal().x * -1):
							if game_manager and game_manager.has_method("show_notification"):
								game_manager.show_notification(notification_stone_too_heavy, 2.0)

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
