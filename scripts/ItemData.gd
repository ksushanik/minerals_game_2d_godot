extends Resource
class_name ItemData

## Имя предмета, отображаемое в инвентаре
@export var item_name: String = "Новый предмет"

## Подробное описание предмета (для простых предметов)
@export_multiline var item_description: String = ""

## Страницы диалога (для NPC)
@export var dialogue_pages: Array[String] = []

# Можно добавить другие свойства в будущем, например:
@export var item_icon: Texture2D
# @export var stackable: bool = false
# @export var value: int = 0 