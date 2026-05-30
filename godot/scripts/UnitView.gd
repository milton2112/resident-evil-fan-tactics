extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var hp_bar: ColorRect = $HpBar

var unit_data := {}

func setup(data: Dictionary) -> void:
	unit_data = data
	sprite.texture = load("res://assets/painted/units/%s" % data.get("art", "chris.png"))
	update_hp()

func update_hp() -> void:
	if unit_data.is_empty():
		return
	var max_hp: float = max(1.0, float(unit_data.get("max_hp", 1)))
	var hp: float = clamp(float(unit_data.get("hp", max_hp)) / max_hp, 0.0, 1.0)
	hp_bar.size.x = 44.0 * hp

func set_selected(value: bool) -> void:
	modulate = Color(1.18, 1.18, 0.82, 1.0) if value else Color.WHITE
