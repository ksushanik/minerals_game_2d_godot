extends Area2D

@onready var animation_player = $AnimationPlayer
var game_manager = null

# Сигнал, который этот предмет будет испускать при сборе
# Передаем ресурс ItemData и узел предмета
signal item_collected(item_data: ItemData, item_node: Node)

# Ссылка на ресурс данных предмета
@export var item_data: ItemData = null

# --- Добавляем константу с путем к ресурсу, который должен быть назначен --- 
const EXPECTED_CARBON_RESOURCE_PATH = "res://resources/items/carbon.tres"

func _ready():
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	else:
		return
	
	if item_data != null and item_data is Resource and item_data.resource_path:
		# Проверяем предмет через GameManager.collected_item_ids (для совместимости)
		if game_manager.get_collected_item_ids().has(item_data.resource_path):
			queue_free()
			return
			
		# Проверяем предмет через InventorySystem
		if game_manager.inventory_system and game_manager.inventory_system.has_item(item_data.resource_path):
			queue_free()
			return
	else:
		if name == "CarbonCrystal":
			item_data = load(EXPECTED_CARBON_RESOURCE_PATH)
	
	if item_data != null and not item_collected.is_connected(game_manager._on_item_collected):
		item_collected.connect(game_manager._on_item_collected)
	
	if game_manager and item_data and game_manager.get_collected_item_ids().has(self.name):
		visible = false
		var collision_shape = $CollisionShape2D as CollisionShape2D
		if collision_shape:
			collision_shape.disabled = true

# Проверка на наличие предмета в инвентаре при респауне игрока
func check_if_already_collected():
	if not game_manager or not item_data:
		return false
		
	# Проверяем через обе системы (и старую, и новую)
	var already_collected = false
	
	# Проверка через GameManager.collected_item_ids (для совместимости)
	if item_data.resource_path and game_manager.get_collected_item_ids().has(item_data.resource_path):
		already_collected = true
		
	# Проверка через InventorySystem
	if not already_collected and game_manager.inventory_system and item_data.resource_path:
		already_collected = game_manager.inventory_system.has_item(item_data.resource_path)
		
	if already_collected:
		queue_free()
		return true
		
	return false

func _on_body_entered(body):
	if not body.is_in_group("player") or item_data == null or not game_manager:
		return
		
	item_collected.emit(item_data, self)
	visible = false
	
	var collision_shape = $CollisionShape2D as CollisionShape2D
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
