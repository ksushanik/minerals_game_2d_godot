# confetti_effect.gd
extends GPUParticles2D # Наследуемся напрямую от GPUParticles2D, т.к. он корневой

# Получаем узел частиц. Теперь это сам узел, к которому прикреплен скрипт!
@onready var particles: GPUParticles2D = self

func _ready():
	# Убедимся, что узел частиц найден (теперь это self, всегда должен быть валиден в _ready)
	if not is_instance_valid(particles):
		print("ERROR: Self (GPUParticles2D) node is somehow invalid!")
		queue_free() # Удаляем, если что-то совсем не так
		return

	# Получаем или создаем материал
	var material: ParticleProcessMaterial
	if particles.process_material is ParticleProcessMaterial:
		material = particles.process_material
	else:
		print("Confetti: Process material not set or incorrect type. Creating new one.")
		material = ParticleProcessMaterial.new()
		particles.process_material = material

	# --- Настройка параметров материала ---
	
	# Общие параметры частиц
	particles.amount = 1500 # Оставляем много частиц
	particles.lifetime = 5.5 # Оставляем долгое время жизни
	particles.one_shot = true
	particles.explosiveness = 0.95 
	particles.randomness = 0.6   

	# Направление и разброс
	material.direction = Vector3(0, -1, 0) 
	material.spread = 180.0 

	# Начальная скорость (ЗНАЧИТЕЛЬНО УМЕНЬШАЕМ)
	material.initial_velocity_min = 100.0 # Чтобы не улетали слишком далеко
	material.initial_velocity_max = 200.0 

	# Гравитация (НЕМНОГО УВЕЛИЧИВАЕМ)
	material.gravity = Vector3(0, 250, 0) # Чтобы падали чуть быстрее

	# Угловая скорость (оставляем)
	material.angular_velocity_min = -180.0 
	material.angular_velocity_max = 180.0

	# Затухание (УВЕЛИЧИВАЕМ)
	material.damping_min = 15.0 # Чтобы быстрее замедлялись
	material.damping_max = 30.0
	material.damping_curve = null 

	# Цвет (оставляем как есть)
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0]) # Точки остановки
	gradient.colors = PackedColorArray([
		Color.YELLOW,    # Начальный цвет
		Color.RED,
		Color.BLUE,
		Color.GREEN,
		Color.MAGENTA    # Конечный цвет
	])
	
	# Создаем текстуру из градиента и назначаем ее
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# --- Конец настройки материала ---
	
	# Таймер самоуничтожения И ПЕРЕХОДА НА ГЛАВНЫЙ ЭКРАН
	var wait_time = particles.lifetime + 0.5
	print("Confetti effect: Waiting %.1f seconds before changing to main menu..." % wait_time)
	await get_tree().create_timer(wait_time).timeout
	print("Confetti effect timer finished. Changing scene to main menu.")
	# queue_free() # Больше не нужно, смена сцены удалит узел
	var err = get_tree().change_scene_to_file("res://scenes/main_title.tscn")
	if err != OK:
		print("ERROR: Failed to change scene to main_title.tscn. Error code: %d" % err)
