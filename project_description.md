**Всеобъемлющее Описание Проекта "Minerals Platformer" (в ответ на вопросы о практике)**

**1. Введение и База:**

*   **Игра:** "Minerals Platformer" – это 2D платформер, разрабатываемый на движке **Godot Engine 4**.
*   **Основа:** Игра построена на стандартной для Godot архитектуре сцен и узлов. Центральным элементом управления состоянием является скрипт `GameManager` (`scripts/game_manager.gd`), реализованный как **синглтон (Autoload)**. Он отслеживает ключевые параметры:
    *   Текущий уровень (`current_level`).
    *   Количество жизней (`lives`).
    *   Собранные уникальные предметы/минералы (словарь `collected_item_ids`, хранящий пути к ресурсам собранных предметов).
    *   Состояние специфических флагов (например, `is_player_light_active`).
*   **Структура Уровней:** Каждый уровень представляет собой отдельную сцену (`.tscn`), например, `level_0.tscn`, `level_1.tscn`, и т.д. Уровни содержат:
    *   `TileMap` для отрисовки геометрии (земля, платформы).
    *   Экземпляры сцен игрока (`player.tscn`), врагов (`slime.tscn`), собираемых предметов (`light_crystal_collectible.tscn`, `iron_collectible.tscn`, и т.д.), порталов (`portal.tscn`).
    *   Скрипты-контроллеры уровней (`level_controller.gd`, `level_0_controller.gd`), которые отвечают за специфичные для уровня настройки (например, видимость UI, проверка "темноты" уровня через метод `is_dark()`).

**2. Практическая Реализация Механик:**

*   **Управление Персонажем (`player.gd`, `player.tscn`):**
    *   Реализовано на базе `CharacterBody2D`.
    *   Физика обрабатывается в `_physics_process()` с использованием гравитации (`ProjectSettings.get_setting("physics/2d/default_gravity")`) и метода `move_and_slide()`.
    *   Управление движением (A/D, стрелки) через `Input.get_axis()`.
    *   Прыжок (Пробел) через `Input.is_action_just_pressed()` и установку `velocity.y`.
    *   Реализована механика **двойного прыжка**, которая активируется при входе в специальную зону (`JumpBoostZone`) и наличии у игрока Углерода (проверяется в `GameManager`).
*   **Анимации Персонажа:**
    *   Используется узел `AnimatedSprite2D` с ресурсом `SpriteFrames`.
    *   В `player.gd` (`_physics_process`) логика **динамически переключает анимации** (`idle`, `run`, `jump`) в зависимости от состояния игрока (направление движения, `is_on_floor()`, `velocity.y`). *Примечание: Анимация `fall` на данный момент не добавлена в `SpriteFrames`, что вызывает ошибку – это известная задача для доработки.*
    *   Реализована анимация смерти (`death`), запускаемая функцией `die()`.
*   **Сбор Предметов/Минералов (`coin.gd`, сцены минералов):**
    *   Каждый собираемый предмет – это сцена с `Area2D` и `CollisionShape2D`.
    *   Скрипт `coin.gd` прикреплен ко всем таким предметам.
    *   При входе игрока (`body_entered`), скрипт проверяет, что это игрок (`body.is_in_group("player")`).
    *   Предмет хранит ссылку на ресурс `ItemData` (`.tres` файл), содержащий имя, описание, иконку (`@export var item_data: ItemData`).
    *   При подборе **уникального** предмета (минерала):
        *   Испускается сигнал `coin_collected(item_data, self)`, который ловит `GameManager`.
        *   `GameManager` добавляет путь к ресурсу предмета (`item_data.resource_path`) в словарь `collected_item_ids`.
        *   `GameManager` также испускает сигнал `item_collected_signal(item_data)` для оповещения других систем (например, камня, который можно толкать).
        *   Сам узел предмета **скрывается** (`visible = false`, `collision_shape.disabled = true`).
    *   **Сохранение состояния сбора:** В `_ready()` скрипта `coin.gd` происходит проверка: если `item_data.resource_path` уже есть в `GameManager.collected_item_ids`, то узел предмета **сразу удаляется** (`queue_free()`), предотвращая повторное появление уже собранных уникальных предметов после смерти или перезагрузки уровня.
*   **Механики Взаимодействия на Основе Минералов:**
    *   **Свет (Светящийся Кристалл):**
        *   `GameManager.update_player_light_state()` проверяет наличие кристалла в `collected_item_ids` и флаг `is_dark()` текущего уровня (устанавливаемый в `level_controller.gd`).
        *   В зависимости от условий, вызываются методы `player.enable_light()` или `player.disable_light()`, которые включают/выключают узел `PointLight2D` у игрока.
        *   Эта проверка вызывается при загрузке уровня (из `_ready()` контроллера уровня).
    *   **Сила (Железо):**
        *   Скрипт толкаемого камня (`Stone`, судя по логам) подписывается на сигнал `GameManager.item_collected_signal`.
        *   При получении сигнала он проверяет, был ли собран предмет "Железо".
        *   Если да, камень меняет свои физические свойства (например, трение), позволяя игроку его толкать (`apply_central_impulse` в `player.gd` при коллизии с камнем).
    *   **Прыжок (Углерод):**
        *   Специальная зона (`JumpBoostZone`) проверяет наличие Углерода в `GameManager.collected_item_ids` при входе игрока.
        *   Если Углерод есть, зона временно увеличивает `player.JUMP_VELOCITY`. При выходе из зоны скорость прыжка восстанавливается.
*   **Порталы и Переходы (`portal.gd`):**
    *   Портал – сцена с `Area2D` и `CollisionShape2D`.
    *   Имеет опцию `@export var require_light_crystal: bool = false`.
    *   При входе игрока (`_on_body_entered`):
        *   Проверяется, установлен ли флаг `require_light_crystal`.
        *   Если да, проверяется наличие кристалла в `GameManager.collected_item_ids`.
        *   Если кристалла нет, выводится уведомление через `GameManager.show_notification()` и переход **прерывается**.
        *   Если проверка пройдена (или не требуется), портал вызывает функцию `GameManager.go_to_level(level_number, scene_path)`.
        *   `GameManager.go_to_level` обновляет `current_level` и вызывает `get_tree().change_scene_to_file()`.
    *   Реализована **анимация пульсации** портала при приближении игрока с использованием `Tween` и дополнительной `Area2D` (`ProximityDetector`).
*   **Взаимодействие с NPC/Предметами:**
    *   Реализован **Дневник Профессора (`diary.tscn`, `diary_dialog.tres`)**. Это `ItemData` ресурс, содержащий массив строк `dialogue_pages`. При взаимодействии с дневником (вероятно, через `Area2D`) запускается UI, отображающий эти страницы.
    *   На уровне 0 (`level_0_controller.gd`) программно создается и размещается **экземпляр Профессора** (`professor.tscn`). (Логика диалога с ним пока не детализирована в запросах).
*   **Коллизии и Хитбоксы:**
    *   Используется встроенная система физики и коллизий Godot.
    *   **Слои и Маски:** Настроены `collision_layer` и `collision_mask` для разных типов объектов (игрок, земля/платформы, предметы, враги, порталы, зоны), чтобы определить, кто с кем взаимодействует.
    *   **Типы тел:** `CharacterBody2D` для игрока (физика, `move_and_slide`), `Area2D` для триггеров (сбор предметов, порталы, зоны), `StaticBody2D` для неподвижных платформ (`TileMap`), `RigidBody2D` (вероятно, для толкаемого камня).
    *   **Хитбоксы:** Не отрисовываются вручную. Используются стандартные узлы `CollisionShape2D`, которым в редакторе назначаются стандартные формы (`RectangleShape2D`, `CircleShape2D`). Размеры и положение этих форм настраиваются визуально в редакторе Godot для соответствия спрайтам и геймплейным задачам.
*   **UI:**
    *   Реализовано отображение жизней и (ранее) очков через `Label` узлы.
    *   `GameManager` управляет видимостью этих элементов через сигналы и методы (`set_lives_visibility`, `set_score_visibility`).
    *   Система уведомлений (`GameManager.show_notification()`) используется для вывода подсказок и сообщений игроку.

**3. Заключение:**

Проект "Minerals Platformer" представляет собой **работающий прототип** 2D платформера с реализованным **ядром игрового процесса**. Практическая работа включает настройку физики и управления персонажем, систему сбора уникальных предметов с сохранением прогресса, реализацию **конкретных игровых механик**, зависящих от собранных предметов (свет, сила, прыжок), систему перехода между уровнями с условным доступом, базовое взаимодействие с окружением и NPC (дневник), настройку коллизий и использование стандартных инструментов Godot для создания хитбоксов. Анимации персонажа и объектов активно используются и подвязаны к игровым событиям и состояниям. Проект имеет четкую структуру с центральным `GameManager` и готов к дальнейшему расширению и полировке. 