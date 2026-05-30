extends Node2D

signal clicked(grid_position: Vector2i)

@export var grid_position := Vector2i.ZERO
@onready var sprite: Sprite2D = $Sprite

func setup(texture_path: String, position_in_grid: Vector2i) -> void:
	grid_position = position_in_grid
	sprite.texture = load(texture_path)

func _on_hit_button_pressed() -> void:
	clicked.emit(grid_position)
