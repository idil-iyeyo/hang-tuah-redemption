# 🚀 Thruster Skins & Slots Guide

The player ship uses a dedicated **`THRUSTER_TEXTURES`** dictionary in `player.gd`, exactly like the ship skins dictionary!

---

### 📂 The 4 Thruster Slots:
| Key | Theme / Starship Match | File Path |
| :--- | :--- | :--- |
| **`"default"`** / **`"cyan"`** | **Wau Bulan (Standard)** | `res://assets/textures/thrusters/thruster_cyan.png` |
| **`"crimson"`** | **Keris Panglima (Raja Bersanding)** | `res://assets/textures/thrusters/thruster_crimson.png` |
| **`"void"`** | **Perahu Naga (Pendekar Bayang)** | `res://assets/textures/thrusters/thruster_void.png` |
| **`"gold"`** | **Tengkolok Diraja (Mahkota Sultan)** | `res://assets/textures/thrusters/thruster_gold.png` |

---

### 💡 How to Add or Replace Your Own Thruster Pixel Art:

#### Option 1: Overwrite Any of the 4 Slot Files
Directly drop your new PNG into any of the 4 slot files above (e.g. `thruster_cyan.png`, `thruster_crimson.png`, etc.).

#### Option 2: Code Dictionary Usage
In GDScript, switch thrusters at any time just like skins:
```gdscript
player.set_thruster_by_key("crimson") # Or "cyan", "void", "gold"
```

#### Option 3: Inspector / Custom Path
Set `custom_thruster_path` on the Player node in the Godot Inspector, or drop an image into:
`res://assets/textures/thrusters/thruster_custom.png`
