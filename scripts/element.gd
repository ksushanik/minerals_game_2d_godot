extends Area2D

@onready var animation_player = $AnimationPlayer
var game_manager = null

func _ready():
	# Получаем GameManager через группу
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		game_manager = manager
		print("Element: Found GameManager")
	else:
		print("Element: WARNING - GameManager not found in scene!")

func _on_body_entered(_body):
	if game_manager:
		# Вызываем метод через нужный компонент
		if game_manager.has_method("collect_element"):
			game_manager.collect_element()
		elif game_manager.level_system and game_manager.level_system.has_method("collect_element"):
			game_manager.level_system.collect_element()
		else:
			print("Element: Cannot collect element, collect_element method not found")
	else:
		# Если вдруг не нашли GameManager в _ready, попробуем снова
		var manager = get_tree().get_first_node_in_group("game_manager")
		if manager:
			game_manager = manager
			if game_manager.has_method("collect_element"):
				game_manager.collect_element()
			else:
				print("Element: collect_element method not found")
		else:
			print("Element: Cannot collect element, GameManager not found")
	
	animation_player.play("pickup")
