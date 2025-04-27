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
		if game_manager.collected_item_ids.has(item_data.resource_path):
			queue_free()
			return
	else:
		if name == "CarbonCrystal":
			item_data = load(EXPECTED_CARBON_RESOURCE_PATH)
	
	if item_data != null and not item_collected.is_connected(game_manager._on_item_collected):
		item_collected.connect(game_manager._on_item_collected)
	
	if game_manager and item_data and game_manager.collected_item_ids.has(self.name):
		visible = false
		var collision_shape = $CollisionShape2D as CollisionShape2D
		if collision_shape:
			collision_shape.disabled = true

func _on_body_entered(body):
	if not body.is_in_group("player") or item_data == null or not game_manager:
		return
		
	if item_data.resource_path == "res://resources/items/light_crystal.tres":
		var player_light = body.get_node_or_null("PlayerLight") 
		if player_light and player_light is Light2D:
			player_light.enabled = true
			
	item_collected.emit(item_data, self)
	visible = false
	
	var collision_shape = $CollisionShape2D as CollisionShape2D
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
