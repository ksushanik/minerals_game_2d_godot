# Документация по модульной системе управления игрой

## Общий обзор
Система управления игрой разделена на 5 основных модулей:

1. **GameManager** - Основной координатор, который связывает все модули между собой
2. **UIManager** - Управляет отображением пользовательского интерфейса 
3. **InventorySystem** - Управляет инвентарем и предметами
4. **LevelSystem** - Отвечает за уровни и переходы между ними
5. **PlayerStateManager** - Управляет состоянием игрока (жизни, диалоги и т.д.)

## Как использовать GameManager

GameManager является центральным узлом системы. Он создает экземпляры всех остальных модулей и связывает их между собой.

### Добавление GameManager на уровень

```gdscript
# 1. Добавьте сцену GameManager в ваш уровень:
var game_manager_scene = load("res://scenes/game_manager.tscn")
var game_manager_instance = game_manager_scene.instantiate()
add_child(game_manager_instance)

# 2. Или найдите существующий GameManager:
var game_manager = get_tree().get_first_node_in_group("game_manager")
```

### Основные методы GameManager

```gdscript
# Управление жизнями
game_manager.decrease_lives()          # Уменьшить количество жизней
game_manager.set_lives_visibility(true) # Показать/скрыть счетчик жизней

# Управление уровнями
game_manager.go_to_level(2)            # Перейти на уровень 2
game_manager.request_next_level()      # Запросить переход на следующий уровень

# Управление инвентарем
game_manager.add_item_to_inventory(item_data) # Добавить предмет в инвентарь

# Управление диалогами
game_manager.set_dialog_active(true)   # Активировать режим диалога

# Уведомления
game_manager.show_notification("Сообщение", 3.0) # Показать уведомление на 3 секунды

# Сброс игры
game_manager.reset_game_state()        # Сбросить игру в начальное состояние
```

## Доступ к подсистемам напрямую

Вы также можете получить доступ к отдельным подсистемам напрямую через GameManager:

```gdscript
# Получение доступа к UI Manager
var ui = game_manager.ui_manager
ui.show_notification("Пример", 2.0)

# Получение доступа к Inventory System
var inventory = game_manager.inventory_system
var items = inventory.get_all_items()

# Получение доступа к Level System
var level_system = game_manager.level_system
level_system.go_to_next_level()

# Получение доступа к Player State Manager
var player_state = game_manager.player_state_manager
var current_lives = player_state.get_lives()
```

## Использование модуля UIManager

UIManager отвечает за все элементы пользовательского интерфейса.

### Основные методы UIManager

```gdscript
# Обновление отображения жизней
ui_manager.update_lives_display(3) # Показать 3 жизни

# Управление видимостью элементов UI
ui_manager.set_lives_visibility(false) # Скрыть счетчик жизней
ui_manager.show_game_over() # Показать надпись "Game Over"
ui_manager.hide_game_over() # Скрыть надпись "Game Over"

# Отображение уведомлений
ui_manager.show_notification("Новое уведомление", 2.5) # на 2.5 секунды
```

## Использование модуля InventorySystem

InventorySystem управляет предметами игрока.

### Основные методы InventorySystem

```gdscript
# Добавление предметов
inventory_system.add_item(item_data) # Добавить предмет в инвентарь

# Проверка наличия предметов
var has_crystal = inventory_system.has_item("res://resources/items/light_crystal.tres")

# Получение всех предметов
var all_items = inventory_system.get_all_items()

# Открытие/закрытие инвентаря
inventory_system.open_inventory()
inventory_system.close_inventory()

# Очистка инвентаря
inventory_system.clear_inventory()
```

## Использование модуля LevelSystem

LevelSystem отвечает за уровни и переходы между ними.

### Основные методы LevelSystem

```gdscript
# Переход на следующий/конкретный уровень
level_system.go_to_next_level()
level_system.go_to_level(3)

# Получение информации о текущем уровне
var current_level = level_system.get_current_level()
var is_dark = level_system.is_level_dark()

# Регистрация нестандартных путей к уровням
level_system.register_custom_level_path(5, "res://scenes/special_level.tscn")
```

## Использование модуля PlayerStateManager

PlayerStateManager управляет состоянием игрока.

### Основные методы PlayerStateManager

```gdscript
# Управление жизнями
player_state_manager.decrease_lives()
var lives = player_state_manager.get_lives()

# Состояние игрока
var is_dead = player_state_manager.is_player_dead()

# Управление диалогами
player_state_manager.set_dialog_active(true)
var in_dialog = player_state_manager.get_dialog_active()

# Управление светом игрока
player_state_manager.update_player_light_state()
```

## Лучшие практики

1. **Используйте GameManager как единую точку входа** для большинства функций игры.
2. **Обращайтесь к подсистемам напрямую** только когда вам нужны специфические функции этих подсистем.
3. **Получайте GameManager через группу**: `get_tree().get_first_node_in_group("game_manager")`
4. **Проверяйте наличие компонентов** перед их использованием: `if game_manager and game_manager.ui_manager:`
5. **Подключайтесь к сигналам** для реакции на изменения в игре, а не проверяйте состояние каждый кадр. 

# Документация по модульной системе игры Minerals Platformer

## Обзор архитектуры
Игра построена на модульной архитектуре с четким разделением ответственности между компонентами. Каждый компонент отвечает за свою часть функциональности и взаимодействует с другими через определенные интерфейсы.

## Система контроллеров уровней

### Базовый контроллер уровня (BaseLevelController)
Базовый класс, содержащий общую функциональность для всех контроллеров уровней. Отвечает за:
- Настройку темного режима уровня
- Применение настроек UI
- Обновление состояния света игрока
- Предоставление публичных методов для уровней
- Управление состоянием уровня

**Основные методы:**
- `_level_specific_setup()` - виртуальный метод для переопределения в дочерних классах
- `apply_ui_settings()` - настройка UI для уровня
- `find_game_manager()` - получение ссылки на GameManager
- `set_dark_level(is_dark)` - установка темного режима
- `is_dark()` - проверка, является ли уровень темным

### Стандартный контроллер уровня (LevelController)
Стандартная реализация контроллера уровня, наследующаяся от BaseLevelController. Используется для большинства уровней, не требующих специфической логики.

### Специализированные контроллеры
Для уровней со специфической логикой созданы индивидуальные контроллеры:

#### Level0Controller
Контроллер для нулевого уровня (обучающий). Добавляет в сцену профессора и инициализирует начальные подсказки.

#### Level1Controller
Контроллер для первого уровня. Содержит логику для:
- Проверки наличия светящегося кристалла
- Отображения подсказок о темноте
- Управления темным режимом

#### Level2Controller
Контроллер для второго уровня. Содержит логику для:
- Подсчета собранных минералов
- Отображения подсказок о необходимости сбора минералов
- Специфичных механик уровня

#### Level3Controller
Контроллер для третьего уровня. Содержит логику для:
- Управления движущимися платформами
- Отображения подсказок после определенного времени
- Специализированных механик темного уровня

### Использование контроллеров

Каждый уровень должен содержать соответствующий контроллер как дочерний узел. Контроллеры можно добавить, выбрав сцену соответствующего контроллера:

- `scenes/level_controller.tscn` - для стандартных уровней
- `scenes/level_0_controller.tscn` - для нулевого уровня
- `scenes/level_1_controller.tscn` - для первого уровня
- `scenes/level_2_controller.tscn` - для второго уровня
- `scenes/level_3_controller.tscn` - для третьего уровня

Или можно вручную создать узел Node и назначить ему соответствующий скрипт контроллера.

### Настройки контроллеров

Все контроллеры имеют следующие настраиваемые параметры:
- `show_lives: bool` - показывать ли счетчик жизней на UI
- `is_dark_level: bool` - является ли уровень темным

Специализированные контроллеры могут иметь дополнительные параметры, специфичные для своей функциональности. 