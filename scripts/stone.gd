extends RigidBody2D

const IRON_RESOURCE_PATH = "res://resources/items/iron.tres"

@export var friction_reduction_factor: float = 0.1

var game_manager = null
var original_friction = 1.0
var can_be_pushed = false

func _ready():
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

func check_and_enable_push():
	if not game_manager:
		return

	var iron_resource = load(IRON_RESOURCE_PATH)
	if not iron_resource:
		can_be_pushed = false
		return
		
	var has_iron = false
	for item in game_manager.collected_items:
		if item.resource_path == iron_resource.resource_path or item.item_name == iron_resource.item_name:
			has_iron = true
			break
	
	var was_pushable = can_be_pushed 
	
	if has_iron:
		can_be_pushed = true
		if (not was_pushable or physics_material_override.friction != original_friction * friction_reduction_factor) and physics_material_override:
			physics_material_override.friction = original_friction * friction_reduction_factor
	else:
		can_be_pushed = false
		if was_pushable and physics_material_override:
			physics_material_override.friction = original_friction
			
func _on_player_collected_item(item_data: ItemData):
	check_and_enable_push()
