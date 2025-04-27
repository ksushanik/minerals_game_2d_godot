@tool
extends EditorScript

func _run():
	# Загружаем ссылку на сцену контроллера
	var controller_scene = load("res://scenes/level_0_controller.tscn")
	
	# Загружаем сцену уровня 0
	var level_scene = load("res://scenes/level_0.tscn")
	var level_instance = level_scene.instantiate()
	
	# Проверяем, есть ли уже контроллер в сцене
	var existing_controller = level_instance.get_node_or_null("Level0Controller")
	if existing_controller:
		print("Controller already exists in scene")
		level_instance.queue_free()
		return
	
	# Создаем экземпляр контроллера
	var controller_instance = controller_scene.instantiate()
	
	# Добавляем контроллер в сцену
	level_instance.add_child(controller_instance)
	controller_instance.owner = level_instance
	
	# Сохраняем измененную сцену
	var packed_scene = PackedScene.new()
	packed_scene.pack(level_instance)
	ResourceSaver.save(packed_scene, "res://scenes/level_0.tscn")
	
	print("Level0Controller added to level_0.tscn")
	level_instance.queue_free() 
