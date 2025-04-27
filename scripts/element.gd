extends Area2D

@onready var animation_player = $AnimationPlayer
var game_manager = null

func _ready():
	# Получаем GameManager как синглтон
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		print("Element: Found GameManager singleton")
	else:
		print("Element: WARNING - GameManager singleton not found!")

func _on_body_entered(_body):
	if game_manager:
		game_manager.collect_element()
	else:
		# Если вдруг не нашли GameManager в _ready, попробуем снова
		if has_node("/root/GameManager"):
			game_manager = get_node("/root/GameManager")
			game_manager.collect_element()
		else:
			print("Element: Cannot collect element, GameManager not found")
	
	animation_player.play("pickup")
