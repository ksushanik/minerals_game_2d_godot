extends Camera2D

# Путь к узлу игрока. Убедись, что он правильный!
# Можно сделать @export var player_path: NodePath, чтобы задать в инспекторе.
@export var player_path: NodePath = "../Player" 

# Плавность следования (0.0 - мгновенно, 1.0 - не двигается)
@export var smoothness: float = 0.1 

var player: Node2D = null
var game_manager = null # Ссылка

func _ready():
	# Находим узел игрока при запуске
	player = get_node_or_null(player_path)
	if not player:
		print("Camera Controller: ERROR - Player node not found at path: ", player_path)
		# Можно отключить камеру, если игрок не найден
		# set_process(false)
		
	# Находим GameManager
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("Camera Controller: ERROR - GameManager not found!")

func _process(_delta):
	# <<< ПРОВЕРКА НА СМЕРТЬ >>>
	if is_instance_valid(game_manager) and game_manager.is_player_dead:
		return # Прекращаем слежение за камерой
	# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	# Если игрок найден и валиден, плавно двигаем камеру к нему
	if is_instance_valid(player):
		global_position = global_position.lerp(player.global_position, 1.0 - smoothness)
	# Если игрок не валиден (например, удален после смерти), 
	# камера просто перестанет двигаться. 