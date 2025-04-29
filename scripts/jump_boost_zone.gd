extends Area2D

# --- Возвращаем load для ресурса углерода --- 
const CARBON_RESOURCE_PATH = "res://resources/items/carbon.tres"
# --------------------------------------------

# Коэффициент усиления прыжка (можно настроить в редакторе)
@export var jump_boost_factor: float = 1.8

# Текст сообщения при входе в зону
@export_multiline var notification_text: String = "Перед вами высокая стена. Для её преодоления потребуется элемент Углерод, который усилит вашу прыгучесть."

# Ссылка на GameManager
var game_manager = null
var player_in_zone = false
var player_ref = null

func _ready():
	# Добавляем в группу для поиска
	add_to_group("jump_boost_zone")
	
	# Находим GameManager
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		print("JumpBoostZone: GameManager found")
	else:
		print("JumpBoostZone: ERROR - GameManager not found!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("JumpBoostZone: Player entered the zone")
		player_in_zone = true
		player_ref = body
		
		# Показываем уведомление
		if game_manager:
			game_manager.show_notification(notification_text, 5.0)

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("JumpBoostZone: Player exited the zone")
		player_in_zone = false
		
		player_ref = null
