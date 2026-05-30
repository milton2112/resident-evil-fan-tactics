extends Node2D

@onready var sprite: Sprite2D = $Sprite

func setup(texture_path: String) -> void:
	sprite.texture = load(texture_path)
