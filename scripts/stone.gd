extends RigidBody2D

const IRON_RESOURCE_PATH = "res://resources/items/iron.tres"

@export var friction_reduction_factor: float = 0.1

var game_manager = null
var original_friction = 1.0
var can_be_pushed = false
var initial_position: Vector2  # Запоминаем начальную позицию
var is_position_saved: bool = false  # Флаг, что мы уже сохранили позицию
var persistent_id: String = ""  # Уникальный ID камня для сохранения состояния

func _ready():
	# Запоминаем начальную позицию
	initial_position = global_position
	
	# Создаем уникальный ID для камня на основе его позиции и имени
	persistent_id = "%s_%.1f_%.1f" % [name, initial_position.x, initial_position.y]
	
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if !game_manager.item_collected_signal.is_connected(_on_player_collected_item):
			game_manager.item_collected_signal.connect(_on_player_collected_item)
		
	if physics_material_override:
		original_friction = physics_material_override.friction
	else:
		var new_material = PhysicsMaterial.new()
		new_material.friction = 1.0
		new_material.rough = true
		physics_material_override = new_material
		original_friction = 1.0
	
	add_to_group("pushable_stone")
	check_and_enable_push()
	
	# Проверяем, нужно ли восстановить сохраненную позицию
	restore_stone_position()

# Восстановление сохраненной позиции
func restore_stone_position():
	if game_manager and game_manager.has_meta("stone_positions"):
		var stone_positions = game_manager.get_meta("stone_positions")
		
		if stone_positions.has(persistent_id):
			var saved_position = stone_positions[persistent_id]
			global_position = saved_position
			is_position_saved = true

func check_and_enable_push():
	if not game_manager:
		return

	var iron_resource = load(IRON_RESOURCE_PATH)
	if not iron_resource:
		can_be_pushed = false
		return
		
	var has_iron = false
	
	if game_manager.inventory_system:
		var inventory_items = game_manager.inventory_system.get_all_items()
		
		for item in inventory_items:
			if item.resource_path == iron_resource.resource_path or item.item_name == iron_resource.item_name:
				has_iron = true
				break
	else:
		# Каменьям не нужно логировать ошибки
		pass
	
	var was_pushable = can_be_pushed 
	
	if has_iron:
		can_be_pushed = true
		if (not was_pushable or physics_material_override.friction != original_friction * friction_reduction_factor) and physics_material_override:
			physics_material_override.friction = original_friction * friction_reduction_factor
	else:
		can_be_pushed = false
		if was_pushable and physics_material_override:
			physics_material_override.friction = original_friction
			
func _on_player_collected_item(_item_data: ItemData):
	check_and_enable_push()

# Проверяем движение камня и сохраняем позицию
func _integrate_forces(state):
	# Если камень двигается или только что остановился, сохраняем его позицию
	if (state.linear_velocity.length() > 0.1 or state.get_contact_count() > 0) and can_be_pushed:
		save_stone_position()

# Сохраняем позицию камня в GameManager
func save_stone_position():
	if not game_manager:
		return
		
	# Создаем словарь для хранения позиций, если его еще нет
	if not game_manager.has_meta("stone_positions"):
		game_manager.set_meta("stone_positions", {})
		
	var stone_positions = game_manager.get_meta("stone_positions")
	
	# Сохраняем текущую позицию камня
	stone_positions[persistent_id] = global_position
	
	# Обновляем словарь позиций
	game_manager.set_meta("stone_positions", stone_positions)
	is_position_saved = true
