extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	if animation_player:
		animation_player.play("MoveVertical")
	else:
		push_warning("Не найден узел AnimationPlayer!")
