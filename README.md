# KnightPlatformer

![Godot](https://img.shields.io/badge/Godot-4.4-blue?style=for-the-badge) ![Platformer](https://img.shields.io/badge/Genre-Platformer-green?style=for-the-badge)

**KnightPlatformer** is a simple 2D platformer created with **Godot 4.4** to learn the basics of game development. This project is designed for beginner developers exploring **GDScript** and platformer mechanics.

## 🎮 Features
✅ Simple and clean **GDScript** code  
✅ Basic physics and character controls  
✅ Enemies and environmental interactions  
✅ Animation and tilemap usage  
✅ Ideal for educational purposes  

## 📥 Download and Run
You can download the **release version** of the game [here](https://github.com/Hernandez712/KnightPlatformer/releases/tag/Build). Just extract the archive and run the executable file.

### 🔧 Godot
1. Install **[Godot Engine 4.4](https://godotengine.org/download)**
2. Clone the repository:
   ```sh
   git clone https://github.com/Hernandez712/KnightPlatformer.git
   ```

## 📷 Screenshots
![KnightPlatformer Screenshot](https://github.com/Hernandez712/KnightPlatformer/blob/main/Screenshot.png)

## 🤝 Contributing
If you want to improve the game or add new mechanics, feel free to contribute:
- Fork the repository
- Make your changes
- Submit a **Pull Request**

## 📜 License
This project is distributed under the **Unlicense** – you are free to use, modify, and distribute the code without restrictions. For more details, see the [LICENSE](https://unlicense.org/) file.

---
🚀 **Start learning Godot with KnightPlatformer!** If you have any questions, open an issue or join the discussion.

## 👨‍🔬 Добавление профессора на уровень 0
Для добавления персонажа профессора на уровень 0:

1. Откройте сцену `level_0.tscn` в редакторе Godot
2. В панели FileSystem найдите сцену `scenes/professor.tscn` 
3. Перетащите сцену профессора в дерево сцены уровня 0
4. Выберите добавленный узел профессора и в инспекторе свойств задайте следующую позицию:
   - Position X: 110
   - Position Y: 42
5. Сохраните сцену

Профессор предоставит квест игроку, который необходимо выполнить для прохождения игры.

Альтернативный способ - добавить контроллер уровня:

1. Откройте сцену `level_0.tscn`
2. Перетащите сцену `scenes/level_0_controller.tscn` в дерево сцены
3. Сохраните сцену

Контроллер автоматически добавит профессора при запуске уровня.

