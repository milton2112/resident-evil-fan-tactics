extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow
@onready var hp_bg: ColorRect = $HpBg
@onready var hp_bar: ColorRect = $HpBar

const TARGET_HEIGHTS := {
	"chris.png": 118.0,
	"jill.png": 118.0,
	"leon.png": 118.0,
	"zombie.png": 116.0,
	"cerberus.png": 82.0,
	"licker.png": 92.0,
	"tyrant.png": 134.0
}
const GROUND_Y := 20.0
const BAR_WIDTH := 52.0

var unit_data := {}

func setup(data: Dictionary) -> void:
	unit_data = data
	var art_name := str(data.get("art", "chris.png"))
	sprite.texture = load("res://assets/painted/units/%s" % art_name)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fit_sprite_to_ground(art_name)
	update_hp()

func fit_sprite_to_ground(art_name: String) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	var target_height := float(TARGET_HEIGHTS.get(art_name, 112.0))
	var unit_scale: float = target_height / max(1.0, texture_size.y)
	sprite.centered = true
	sprite.scale = Vector2(unit_scale, unit_scale)
	sprite.position = Vector2(0, GROUND_Y - texture_size.y * unit_scale * 0.5)
	shadow.position = Vector2(0, GROUND_Y + 3.0)
	shadow.scale = Vector2(max(0.78, texture_size.x * unit_scale / 56.0), 0.28)
	hp_bg.position = Vector2(-BAR_WIDTH * 0.5, GROUND_Y + 17.0)
	hp_bg.size = Vector2(BAR_WIDTH, 5.0)
	hp_bar.position = hp_bg.position
	hp_bar.size = hp_bg.size

func update_hp() -> void:
	if unit_data.is_empty():
		return
	var max_hp: float = max(1.0, float(unit_data.get("max_hp", 1)))
	var hp: float = clamp(float(unit_data.get("hp", max_hp)) / max_hp, 0.0, 1.0)
	hp_bar.size.x = BAR_WIDTH * hp

func set_selected(value: bool) -> void:
	modulate = Color(1.18, 1.18, 0.82, 1.0) if value else Color.WHITE
