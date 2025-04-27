extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_ui()

func hide_ui():
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.hide_ui()
		
		if game_manager.has_node("LivesLabel"):
			game_manager.get_node("LivesLabel").visible = false
		
		if is_instance_valid(game_manager.game_over_label):
			game_manager.game_over_label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.reset_game_state()
		game_manager.set_current_level(0)
		game_manager.show_ui()
	
	var mainScene = load("res://scenes/level_0.tscn")
	get_tree().change_scene_to_packed(mainScene)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
