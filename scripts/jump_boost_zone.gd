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
var original_jump_velocity = 0

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
		
		# Сохраняем оригинальную силу прыжка
		if player_ref.has_method("get") and player_ref.get("JUMP_VELOCITY") != null: # Добавим проверку на наличие свойства
			original_jump_velocity = player_ref.JUMP_VELOCITY
		else:
			print("JumpBoostZone: Warning - Player node does not have JUMP_VELOCITY property or it's null.")
			original_jump_velocity = -300.0 # Значение по умолчанию на всякий случай
		
		# Показываем уведомление
		if game_manager:
			game_manager.show_notification(notification_text, 5.0)
			
		# Проверяем наличие углерода в инвентаре
		check_and_apply_boost()

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("JumpBoostZone: Player exited the zone")
		player_in_zone = false
		
		# Восстанавливаем оригинальную силу прыжка
		if player_ref and original_jump_velocity != 0 and player_ref.has_method("set"):
			player_ref.JUMP_VELOCITY = original_jump_velocity
			print("JumpBoostZone: Restored original jump velocity: ", original_jump_velocity)
		
		player_ref = null

# Проверяет наличие углерода и применяет усиление прыжка
func check_and_apply_boost():
	if not game_manager or not player_ref:
		return
		
	# --- Загружаем ресурс через load --- 
	var carbon_resource = load(CARBON_RESOURCE_PATH)
	if not carbon_resource:
		print("JumpBoostZone: ERROR - Carbon resource not found at path: ", CARBON_RESOURCE_PATH)
		return
	# -----------------------------------
		
	# Проверяем, есть ли углерод в инвентаре
	var has_carbon = false
	
	# Используем inventory_system вместо прямого доступа к collected_items в GameManager
	if game_manager.inventory_system:
		# Получаем список предметов из inventory_system
		var inventory_items = game_manager.inventory_system.get_all_items()
		
		for item in inventory_items:
			if item.resource_path == carbon_resource.resource_path or item.item_name == carbon_resource.item_name:
				has_carbon = true
				break
	else:
		print("JumpBoostZone: ERROR - inventory_system not found in GameManager")
			
	if has_carbon:
		# Усиливаем прыжок
		if player_ref.has_method("set"):
			player_ref.JUMP_VELOCITY = original_jump_velocity * jump_boost_factor
			print("JumpBoostZone: Carbon found! Jump boosted to: ", player_ref.JUMP_VELOCITY)
		
		# Показываем уведомление об усилении
		if game_manager:
			game_manager.show_notification("Элемент Углерод активирован! Ваша прыгучесть временно увеличена.", 3.0)
	else:
		print("JumpBoostZone: Player doesn't have carbon element") 
