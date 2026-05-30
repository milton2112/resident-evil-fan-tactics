extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	main.start_battle()
	await process_frame
	quit()
