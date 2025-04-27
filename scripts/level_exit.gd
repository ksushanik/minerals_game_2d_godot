extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

func _ready():
	print("LevelExit initialized!")
	# Подключаем сигнал body_entered явно
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	print("Signal connected!")

func _on_body_entered(body):
	print("Body entered: ", body.name)
	if body.is_in_group("player"):
		print("Player detected! Changing level...")
		if animation_player and animation_player.has_animation("activate"):
			animation_player.play("activate")
			await animation_player.animation_finished
		if game_manager:
			game_manager.next_level()
		else:
			print("ERROR: GameManager not found!")
	else:
		print("Not a player. Groups: ", body.get_groups()) 
