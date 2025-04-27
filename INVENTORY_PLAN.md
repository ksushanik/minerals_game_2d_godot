# План реализации Инвентаря и Описаний Предметов

Этот файл содержит план действий для добавления функционала описаний для собираемых предметов (монеток) и системы инвентаря.

## Шаги:

1.  **[ ] Модификация Монетки (`coin.gd` и `coin.tscn`):**
    *   [ ] Добавить `@export var description: String` в `coin.gd`.
    *   [ ] Изменить `_on_body_entered` в `coin.gd`:
        *   [ ] Вызвать показ всплывающего окна с `description`.
        *   [ ] Сообщить `GameManager` о добавлении `description` в инвентарь.
        *   [ ] Выполнить `queue_free()` и `GameManager.add_point()` *после* взаимодействия с окном/инвентарем.

2.  **[ ] Создание Окна Описания (`coin_popup.tscn` и `coin_popup.gd`):**
    *   [ ] Создать сцену `coin_popup.tscn` (Control/PanelContainer, Label, Button).
    *   [ ] Создать скрипт `coin_popup.gd`.
    *   [ ] Реализовать функцию `show_popup(text: String)` (установить текст, показать окно, `get_tree().paused = true`).
    *   [ ] Реализовать закрытие окна (скрыть окно, `get_tree().paused = false`, опционально - сигнал `popup_closed`).

3.  **[ ] Модификация `GameManager.gd`:**
    *   [ ] Добавить `var collected_descriptions: Array[String] = []`.
    *   [ ] Создать функцию `add_to_inventory(description: String)`.
    *   [ ] Создать функцию `get_collected_descriptions() -> Array[String]`.

4.  **[ ] Создание Интерфейса Инвентаря (`inventory_ui.tscn` и `inventory_ui.gd`):**
    *   [ ] Создать сцену `inventory_ui.tscn` (Control/PanelContainer, ScrollContainer, VBoxContainer, Label, Button).
    *   [ ] Создать скрипт `inventory_ui.gd`.
    *   [ ] Реализовать функцию `display_inventory(descriptions: Array[String])` (очистить VBox, создать Labels, показать панель, `get_tree().paused = true`).
    *   [ ] Реализовать закрытие инвентаря (скрыть панель, `get_tree().paused = false`).

5.  **[ ] Добавление Доступа к Инвентарю:**
    *   [ ] Выбрать способ открытия (кнопка на UI / клавиша).
    *   [ ] Реализовать логику открытия:
        *   [ ] Создать экземпляр `inventory_ui.tscn`.
        *   [ ] Добавить к дереву сцен.
        *   [ ] Получить описания из `GameManager`.
        *   [ ] Вызвать `inventory_instance.display_inventory(...)`.

## Статус:

*   План создан.

(Используйте `[x]` для отметки выполненных пунктов) 